extends Node3D
## Battle director — presentation orchestrator for the combat test slice.
## The deterministic rules (battle_rules.gd) remain the sole authority for
## state, timing decisions and damage. This node stages WHAT the player
## sees and hears: grid cursor, movement tweens, attack windows, impacts,
## telegraphs, VFX, SFX, camera framing and the whole battle loop.

const Rules = preload("res://scripts/battle_rules.gd")
const UnitViewScript = preload("res://scripts/unit_view.gd")

var rules: BattleRules
var hud: BattleHud
var stage: Node3D
var camera: BattleCamera
var views := {}            # id -> UnitView
var cursor: Node3D
var highlights: Array[MeshInstance3D] = []

var mode := "boot"         # boot|explore|move|command|target|resolve|enemy|result
var selected := "jayze"
var cursor_cell := Vector2i.ZERO
var pending_action := ""
var pending_target := ""
var moved_since_select := false
var input_enabled := true

# attack timing tables (fraction of clip where the impact lands)
const IMPACT_AT := {
	"attack": 0.45, "ability": 0.55, "ram": 0.5, "claw": 0.42,
	"pound": 0.5, "mend": 0.55, "screech": 0.35, "brace": 0.4,
	"interact": 0.3, "guard": 0.3, "cooperate": 0.55,
}
const ATTACK_SFX := {
	"jayze": {"attack": "jayze_attack", "ability": "jayze_ability", "melee": "jayze_attack", "technique": "jayze_ability"},
	"kip": {"attack": "kip_shoot", "ability": "kip_ram", "shoot": "projectile", "ram": "kip_ram"},
	"rallo": {"attack": "rallo_claw", "ability": "rallo_ability", "claw": "rallo_claw", "screech": "rallo_ability"},
	"jonnie": {"attack": "jonnie_attack", "ability": "jonnie_ability", "pound": "jonnie_attack", "mend": "jonnie_ability"},
}
const ACCENT := {
	"jayze": Color(0.89, 0.65, 0.23), "kip": Color(0.16, 0.73, 0.78),
	"rallo": Color(0.86, 0.38, 0.32), "jonnie": Color(0.53, 0.41, 0.73),
	"sprocket": Color(0.95, 0.72, 0.2), "clanker": Color(0.45, 0.5, 0.42),
	"gimbal": Color(0.95, 0.55, 0.15),
}
const RANGES := {"melee": 1, "technique": 1, "claw": 1, "screech": 1, "pound": 1, "shoot": 4, "ram": 2, "mend": 2, "cooperate": 3}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rules = Rules.new()
	_build_stage()
	_build_units()
	_build_cursor()
	hud = load("res://scripts/battle_hud.gd").new()
	add_child(hud)
	hud.action_chosen.connect(_on_action_chosen)
	hud.target_chosen.connect(_on_target_chosen)
	hud.menu_cancelled.connect(_on_menu_cancelled)
	hud.restart_requested.connect(reset_battle)
	camera.reset()
	Audio.start_ambience()
	_enter_explore()

# ------------------------------------------------------------- scene setup

func _build_stage() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2c3542")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.55
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 140, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.7, 0.75, 0.9)
	add_child(fill)
	var arena: Node3D = load("res://assets/characters/arena.glb").instantiate()
	add_child(arena)
	for mi in arena.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "Floor":
			for i in mi.get_surface_override_material_count():
				pass
			var mat: Material = mi.mesh.surface_get_material(0)
			if mat != null:
				mat.vertex_color_use_as_albedo = true
	camera = BattleCamera.new()
	add_child(camera)

func _build_units() -> void:
	for id in rules.units:
		var view: UnitView = UnitViewScript.new()
		view.name = id
		var scene: PackedScene = load("res://assets/characters/%s.glb" % id)
		view.max_hp = rules.units[id].max_hp
		view.setup(id, rules.units[id].label, ACCENT.get(id, Color.WHITE), scene)
		add_child(view)
		view.global_position = _world(rules.units[id].cell)
		views[id] = view
		view.set_bars(rules.units[id].hp, rules.units[id].max_hp)
		view.set_visible_state(true)
		view.play_clip("idle")
		if rules.units[id].player:
			view.face_towards(Vector3(1, 0, 0))
		else:
			view.face_towards(Vector3(-1, 0, 0))

func _build_cursor() -> void:
	cursor = Node3D.new()
	add_child(cursor)
	var quad := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.94, 0.94)
	quad.mesh = q
	quad.rotation_degrees.x = -90
	quad.position = Vector3(0, 0.03, 0)
	quad.material_override = BattleVfx._unshaded(Color(1, 0.92, 0.5, 0.5))
	cursor.add_child(quad)
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.42
	t.outer_radius = 0.5
	ring.mesh = t
	ring.position = Vector3(0, 0.06, 0)
	ring.material_override = BattleVfx._unshaded(Color(1, 0.95, 0.6, 0.85))
	cursor.add_child(ring)
	for i in 16:
		var hi := MeshInstance3D.new()
		var hq := QuadMesh.new()
		hq.size = Vector2(0.8, 0.8)
		hi.mesh = hq
		hi.rotation_degrees.x = -90
		hi.position = Vector3(0, 0.025, 0)
		hi.material_override = BattleVfx._unshaded(Color(0.4, 0.85, 1.0, 0.22))
		hi.visible = false
		add_child(hi)
		highlights.append(hi)

func _world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x - 4.5, 0, cell.y - 3.5)

# ------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	Settings.note_input_device(event)
	if not input_enabled or get_tree().paused:
		return
	if mode == "result":
		if event.is_action_pressed("battle_confirm"):
			Audio.ui("ui_confirm")
			reset_battle()
		elif event.is_action_pressed("battle_cancel"):
			Audio.ui("ui_cancel")
			get_tree().quit(0)
		return
	if hud.is_menu_open():
		# menus consume input via Control focus; B still bubbles for cancel
		if event.is_action_pressed("battle_cancel"):
			Audio.ui("ui_cancel")
			_close_menus()
			_after_menu_cancelled()
		return
	if event.is_action_pressed("pause"):
		hud.open_pause()
		return
	match mode:
		"explore":
			_input_explore(event)
		"move":
			_input_move(event)
		_:
			pass

func _input_explore(event: InputEvent) -> void:
	if event.is_action_pressed("battle_menu"):
		Audio.ui("ui_confirm")
		_begin_combat()
	elif event.is_action_pressed("party_next"):
		_cycle_party(1)
	elif event.is_action_pressed("party_prev"):
		_cycle_party(-1)
	elif _try_step_move(event):
		pass

func _try_step_move(event: InputEvent) -> bool:
	var delta := Vector2i.ZERO
	if event.is_action_pressed("move_up"): delta = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"): delta = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"): delta = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"): delta = Vector2i(1, 0)
	else: return false
	if rules.move_unit(selected, rules.units[selected].cell + delta):
		Audio.sfx_at("ui_move", _world(rules.units[selected].cell), 1.4, -12.0)
		_tween_move(selected, 0.18)
	return true

func _cycle_party(dir: int) -> void:
	var living := rules.living_party_ids()
	if living.size() <= 1:
		return
	var idx := living.find(selected)
	selected = living[(idx + dir + living.size()) % living.size()]
	cursor_cell = rules.units[selected].cell
	Audio.ui("ui_party")
	camera.focus_on(_world(rules.units[selected].cell))
	_refresh_hud()

func _input_move(event: InputEvent) -> void:
	if event.is_action_pressed("party_next"):
		_cycle_party(1)
		return
	if event.is_action_pressed("party_prev"):
		_cycle_party(-1)
		return
	var reachable := rules.reachable_cells(selected)
	var delta := Vector2i.ZERO
	if event.is_action_pressed("move_up"): delta = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"): delta = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"): delta = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"): delta = Vector2i(1, 0)
	elif event.is_action_pressed("battle_confirm"):
		_confirm_cursor(reachable)
		return
	elif event.is_action_pressed("battle_cancel"):
		Audio.ui("ui_cancel")
		return
	elif event.is_action_pressed("battle_menu"):
		Audio.ui("ui_open")
		_open_command_menu()
		return
	else:
		return
	if delta != Vector2i.ZERO:
		_scan_cursor(delta, reachable)

func _scan_cursor(delta: Vector2i, reachable: Array[Vector2i]) -> void:
	var probe := cursor_cell
	for i in 12:
		probe += delta
		if probe.x < 0 or probe.x >= rules.GRID.x or probe.y < 0 or probe.y >= rules.GRID.y:
			break
		if probe in reachable or probe == rules.units[selected].cell:
			cursor_cell = probe
			Audio.ui("ui_move", 1.6, -14.0)
			camera.focus_on(_world(cursor_cell))
			_update_cursor_visuals(reachable)
			return

func _confirm_cursor(reachable: Array[Vector2i]) -> void:
	var own: Vector2i = rules.units[selected].cell
	if cursor_cell == own:
		Audio.ui("ui_open")
		_open_command_menu()
		return
	if cursor_cell in reachable and rules.move_unit(selected, cursor_cell):
		Audio.ui("ui_confirm")
		input_enabled = false
		var dist: int = rules._dist(own, cursor_cell)
		var view: UnitView = views[selected]
		view.play_clip("move", 1.4)
		view.set_moving(selected == "kip", dist / 0.36)
		camera.focus_on(_world(cursor_cell))
		await _tween_move(selected, 0.22 * dist)
		view.set_moving(false)
		view.play_clip("idle")
		moved_since_select = true
		input_enabled = true
		_open_command_menu()
	else:
		Audio.ui("ui_deny")

func _tween_move(id: String, dur: float) -> void:
	var view: UnitView = views[id]
	var target := _world(rules.units[id].cell)
	var dir := target - view.global_position
	if dir.length() > 0.01:
		view.face_towards(dir)
	var tw := create_tween()
	tw.tween_property(view, "global_position", target, dur)
	await tw.finished

# ------------------------------------------------------------- flow states

func _enter_explore() -> void:
	mode = "explore"
	selected = "jayze"
	cursor_cell = rules.units[selected].cell
	camera.reset()
	camera.focus_on(_world(cursor_cell), true)
	hud.set_prompt("[%s] move · [%s]/[%s] switch toy · [%s] begin combat · [%s] pause" %
		[Settings.glyph("move"), Settings.glyph("party_prev"), Settings.glyph("party_next"), Settings.glyph("menu"), Settings.glyph("pause")])
	_refresh_hud()

func _begin_combat() -> void:
	rules.begin_combat()
	rules.defer_enemy_phase = true
	mode = "move"
	Audio.play_music("encounter", 0.2)
	await get_tree().create_timer(0.7).timeout
	Audio.play_music("combat", 1.2)
	cursor_cell = rules.units[selected].cell
	hud.set_prompt("[%s] cursor · [%s] confirm move · [%s] actions · [%s]/[%s] switch · [%s] pause" %
		[Settings.glyph("move"), Settings.glyph("confirm"), Settings.glyph("menu"), Settings.glyph("party_prev"), Settings.glyph("party_next"), Settings.glyph("pause")])
	camera.focus_on(Vector3(0, 0.5, 0))
	_refresh_hud()

func _open_command_menu() -> void:
	var actions := rules.actions_for(selected)
	var costs := {}
	var availability := {}
	var u: Dictionary = rules.units[selected]
	for action in actions:
		match action:
			"ram":
				costs[action] = "2 momentum"
				availability[action] = u.momentum >= 2
			"mend":
				costs[action] = "heal 3"
				availability[action] = u.mend_cd == 0
			"cooperate":
				availability[action] = rules._can_act("jayze") and rules._can_act("kip") and rules.activations_left >= 2
			_:
				availability[action] = true
	hud.open_command_menu(selected, actions, costs, availability)
	mode = "command"
	camera.focus_on(_world(rules.units[selected].cell))

func _on_action_chosen(action: String) -> void:
	if mode != "command":
		return
	pending_action = action
	hud.close_command_menu()
	if action == "begin_combat":
		_begin_combat()
		return
	if action in ["guard", "interact"]:
		_execute_action(selected, action, "")
		return
	# target selection: foes for attacks/screech/cooperate, allies for mend
	var options: Array = []
	if action == "mend":
		for ally in rules.living_party_ids():
			if _in_range(ally, action):
				options.append({"id": ally, "label": "%s (HP %d/%d)" % [rules.units[ally].label, rules.units[ally].hp, rules.units[ally].max_hp]})
		if options.is_empty():
			Audio.ui("ui_deny")
			_after_menu_cancelled()
			return
		hud.open_target_menu(options, "ally")
	else:
		for foe in rules.living_foe_ids():
			options.append({"id": foe, "label": "%s (HP %d/%d)%s" % [rules.units[foe].label, rules.units[foe].hp, rules.units[foe].max_hp,
				"" if _in_range(foe, action) else "  — out of range"]})
		if options.is_empty():
			Audio.ui("ui_deny")
			_after_menu_cancelled()
			return
		hud.open_target_menu(options, "foe")
	mode = "target"

func _in_range(id: String, action: String) -> bool:
	var reach: int = RANGES.get(action, 1)
	var from: Vector2i = rules.units[selected].cell
	if action == "cooperate":
		reach = 3
	var d := rules._dist(from, rules.units[id].cell)
	if action == "cooperate":
		d = mini(rules._dist(rules.units.jayze.cell, rules.units[id].cell), rules._dist(rules.units.kip.cell, rules.units[id].cell))
	return d <= reach

func _on_target_chosen(target_id: String) -> void:
	if mode != "target":
		return
	hud.close_target_menu()
	var action := pending_action
	pending_target = target_id
	if not _in_range(target_id, action):
		Audio.ui("ui_deny")
		_after_menu_cancelled()
		return
	_execute_action(selected, action, target_id)

func _on_menu_cancelled() -> void:
	pass  # handled by _unhandled_input path

func _close_menus() -> void:
	hud.close_command_menu()
	hud.close_target_menu()

func _after_menu_cancelled() -> void:
	mode = "move"
	_refresh_hud()

# ------------------------------------------------------------- player actions

func _execute_action(id: String, action: String, target: String) -> void:
	mode = "resolve"
	input_enabled = false
	hud.set_prompt("...")
	var target_view: UnitView = views[target] if target != "" else null
	var pre_hp: int = rules.units[target].hp if target != "" else -1
	var max_hp: int = rules.units[target].max_hp if target != "" else 1
	var ok: bool = rules.use_action(id, action, target)
	if not ok:
		Audio.ui("ui_deny")
		input_enabled = true
		_after_menu_cancelled()
		return
	_refresh_hud()
	var actor: UnitView = views[id]
	var impact_frac: float = IMPACT_AT.get(action, 0.45)
	var clip := _clip_for(action, id)
	# face the target
	if target != "" and target_view != null:
		actor.face_cell(target_view.global_position)
	if action == "cooperate":
		await _run_coop(id, target, target_view, pre_hp, max_hp)
		_wrap_up_action()
		return
	# windup: attack cue
	var windup_sfx: String = ATTACK_SFX.get(id, {}).get(action, ATTACK_SFX.get(id, {}).get("attack", ""))
	var clip_len: float = actor.clip_length(clip)
	actor.play_clip(clip)
	if windup_sfx != "":
		Audio.sfx_at(windup_sfx, actor.global_position)
	if action == "shoot":
		# projectile spawns early, impact timed to arrival
		var spawn_at: float = clip_len * 0.33
		await get_tree().create_timer(spawn_at).timeout
		if target_view != null:
			var from: Vector3 = actor.socket_pos("Socket_Muzzle")
			BattleVfx.projectile(self, from, target_view.global_position + Vector3(0, 0.5, 0), ACCENT[id], 0.24)
			await get_tree().create_timer(0.24).timeout
		await _apply_impact(action, id, target, target_view, pre_hp, max_hp)
	elif action in ["guard", "brace"]:
		await get_tree().create_timer(clip_len * impact_frac).timeout
		if action == "brace":
			BattleVfx.guard_flash(self, actor)
			Audio.sfx("jonnie_brace")
		else:
			Audio.sfx("guard_block", 1.0, -6.0)
		await get_tree().create_timer(maxf(0.1, clip_len * (1.0 - impact_frac))).timeout
	elif action == "mend":
		await get_tree().create_timer(clip_len * impact_frac).timeout
		if target_view != null:
			BattleVfx.heal_sparkles(self, target_view.global_position)
			Audio.sfx_at("heal", target_view.global_position)
			BattleVfx.floater(self, target_view.global_position, "+%d" % (rules.units[target].hp - pre_hp), Color(0.5, 1, 0.6))
		_refresh_hud()
		await get_tree().create_timer(maxf(0.1, clip_len * (1.0 - impact_frac))).timeout
	elif action == "screech":
		await get_tree().create_timer(clip_len * impact_frac).timeout
		if target_view != null:
			BattleVfx.pulse_ring(self, target_view.global_position, Color(1, 0.85, 0.2), 0.7)
			BattleVfx.floater(self, target_view.global_position, "DAZED", Color(1, 0.85, 0.2))
			Audio.sfx_at("stagger", target_view.global_position)
		await get_tree().create_timer(maxf(0.1, clip_len * (1.0 - impact_frac))).timeout
	else:
		# strike: impact at the timing mark
		await get_tree().create_timer(clip_len * impact_frac).timeout
		await _apply_impact(action, id, target, target_view, pre_hp, max_hp)
		await get_tree().create_timer(maxf(0.12, clip_len * (1.0 - impact_frac) * 0.8)).timeout
	_wrap_up_action()

func _clip_for(action: String, id: String) -> String:
	match action:
		"melee": return "attack"
		"technique": return "ability"
		"shoot": return "attack"
		"ram": return "ram"
		"claw": return "attack"
		"screech": return "ability"
		"pound": return "attack"
		"mend": return "ability"
		"brace": return "brace"
		"guard": return "guard"
		"interact": return "attack"
	return "attack"

func _run_coop(id: String, target: String, target_view: UnitView, pre_hp: int, max_hp: int) -> void:
	# Jayze dash-slash + Kip bolt, one combined impact (rules already resolved).
	var jayze: UnitView = views["jayze"]
	var kip: UnitView = views["kip"]
	if target_view != null:
		jayze.face_cell(target_view.global_position)
		kip.face_cell(target_view.global_position)
	jayze.play_clip("ability")
	kip.play_clip("ram")
	Audio.sfx_at("jayze_ability", jayze.global_position)
	await get_tree().create_timer(0.35).timeout
	if target_view != null:
		BattleVfx.projectile(self, kip.socket_pos("Socket_Muzzle"), target_view.global_position + Vector3(0, 0.5, 0), ACCENT["kip"], 0.2)
		BattleVfx.slash(self, target_view.global_position, jayze.global_position - target_view.global_position)
	await get_tree().create_timer(0.2).timeout
	await _apply_impact("cooperate", "jayze", target, target_view, pre_hp, max_hp)
	await get_tree().create_timer(0.6).timeout
	kip.play_clip("idle")

func _apply_impact(action: String, _actor: String, target: String, target_view: UnitView, pre_hp: int, _max_hp: int) -> void:
	if target == "" or target_view == null:
		return
	var post_hp: int = rules.units[target].hp
	var damage: int = pre_hp - post_hp
	var heavy: bool = action in ["ram", "pound", "technique", "ability", "cooperate", "interact"]
	var pos: Vector3 = target_view.global_position + Vector3(0, 0.6, 0)
	if action == "interact":
		pos = _world(rules.MUSIC_BOX) + Vector3(0, 0.3, 0)
	BattleVfx.impact(self, pos, heavy)
	Audio.sfx_at("impact_heavy" if heavy else "impact_light", pos)
	camera.shake(0.5 if heavy else 0.3)
	if damage > 0:
		BattleVfx.floater(self, target_view.global_position, "-%d" % damage, Color(1, 0.85, 0.4) if target_view.unit_id in Rules.FOES else Color(1, 0.4, 0.35))
		target_view.flash_hit()
		target_view.set_bars(post_hp, target_view.max_hp if post_hp > 0 else target_view.max_hp)
		_refresh_hud()
		if post_hp <= 0:
			Audio.sfx_at("ko_down", pos)
			BattleVfx.floater(self, target_view.global_position, "DOWN!", Color(1, 0.5, 0.4))
			target_view.play_clip("defeat")
			target_view.set_visible_state(false)
			camera.shake(0.6)
		else:
			target_view.play_clip("hit" if post_hp > 0 else "defeat")
	elif action == "interact":
		_refresh_hud()

func _wrap_up_action() -> void:
	_close_menus()
	_refresh_hud()
	if rules.result != "":
		_finish_battle(rules.result)
		return
	if rules.awaiting_enemy:
		_run_enemy_phase()
		return
	mode = "move"
	moved_since_select = false
	# advance selection to the next un-acted party member
	for pid in rules.living_party_ids():
		if not rules.activated.has(pid):
			selected = pid
			break
	cursor_cell = rules.units[selected].cell
	camera.focus_on(_world(cursor_cell))
	input_enabled = true
	hud.set_prompt("[%s] cursor · [%s] confirm move · [%s] actions · [%s]/[%s] switch · [%s] pause" %
		[Settings.glyph("move"), Settings.glyph("confirm"), Settings.glyph("menu"), Settings.glyph("party_prev"), Settings.glyph("party_next"), Settings.glyph("pause")])
	_refresh_hud()

# ------------------------------------------------------------- enemy phase

func _run_enemy_phase() -> void:
	mode = "enemy"
	input_enabled = false
	hud.set_prompt("The enemies move...")
	_close_menus()
	var plan := rules.plan_enemy_phase()
	for step in plan:
		if rules.result != "":
			break
		await _present_enemy_step(step)
		_refresh_hud()
	rules.finish_enemy_phase()
	_refresh_hud()
	if rules.result != "":
		_finish_battle(rules.result)
		return
	mode = "move"
	moved_since_select = false
	for pid in rules.living_party_ids():
		if not rules.activated.has(pid):
			selected = pid
			break
	cursor_cell = rules.units[selected].cell
	camera.focus_on(_world(cursor_cell))
	input_enabled = true
	hud.set_prompt("[%s] cursor · [%s] confirm move · [%s] actions · [%s]/[%s] switch · [%s] pause" %
		[Settings.glyph("move"), Settings.glyph("confirm"), Settings.glyph("menu"), Settings.glyph("party_prev"), Settings.glyph("party_next"), Settings.glyph("pause")])

func _present_enemy_step(step: Dictionary) -> void:
	var foe: UnitView = views[step.foe]
	match step.kind:
		"stunned":
			BattleVfx.floater(self, foe.global_position, "dazed — loses its attack", Color(1, 0.85, 0.2))
			Audio.sfx_at("stagger", foe.global_position, 0.9)
			await get_tree().create_timer(0.5).timeout
		"attack":
			var target_view: UnitView = views[step.target]
			var pre_hp: int = rules.units[step.target].hp
			camera.focus_mid(foe.global_position, target_view.global_position)
			# telegraph: warning + ring under the target
			Audio.sfx_at("telegraph_warn", foe.global_position)
			BattleVfx.floater(self, foe.global_position, "!", Color(1, 0.35, 0.3))
			foe.play_clip("telegraph")
			await get_tree().create_timer(0.75).timeout
			var ring := BattleVfx.telegraph_ring(self, target_view.global_position)
			foe.face_cell(target_view.global_position)
			foe.play_clip("attack")
			await get_tree().create_timer(0.32).timeout
			# impact moment — apply the planned step now
			rules.apply_enemy_step(step)
			ring.queue_free()
			var pos: Vector3 = target_view.global_position + Vector3(0, 0.6, 0)
			if step.blocked:
				Audio.sfx_at("guard_block", pos)
				BattleVfx.guard_flash(self, target_view)
				BattleVfx.floater(self, target_view.global_position, "BLOCKED", Color(0.5, 0.8, 1))
			else:
				BattleVfx.impact(self, pos, step.foe == "clanker")
				Audio.sfx_at("impact_heavy" if step.foe == "clanker" else "impact_light", pos)
				camera.shake(0.45)
			target_view.set_bars(rules.units[step.target].hp, rules.units[step.target].max_hp)
			var post: int = rules.units[step.target].hp
			if post <= 0:
				Audio.sfx_at("ko_down", pos)
				BattleVfx.floater(self, target_view.global_position, "DOWN!", Color(1, 0.5, 0.4))
				target_view.play_clip("defeat")
				target_view.set_visible_state(false)
			elif not step.blocked:
				target_view.flash_hit()
				target_view.play_clip("hit")
				BattleVfx.floater(self, target_view.global_position, "-%d" % (pre_hp - post), Color(1, 0.4, 0.35))
			_refresh_hud()
			await get_tree().create_timer(0.55).timeout
		"advance":
			camera.focus_on(foe.global_position)
			foe.play_clip("move")
			await _tween_move(step.foe, 0.4)
			foe.play_clip("idle")
		"hold":
			await get_tree().create_timer(0.15).timeout

# ------------------------------------------------------------- result / reset

func _finish_battle(result: String) -> void:
	mode = "result"
	input_enabled = false
	Audio.stop_music(1.2)
	await get_tree().create_timer(0.9).timeout
	Audio.play_music("victory" if result == "victory" else "defeat", 0.1)
	var survivors := rules.living_party_ids().size()
	hud.show_result(result == "victory", rules.round_number, survivors)
	hud.set_prompt("")
	BattleVfx.pulse_ring(self, Vector3.ZERO, Color(0.5, 1, 0.6) if result == "victory" else Color(1, 0.4, 0.35), 4.0, 1.2)

func reset_battle() -> void:
	_close_menus()
	hud.hide_result()
	rules.reset()
	rules.defer_enemy_phase = true
	Audio.stop_music(0.4)
	for id in views:
		var view: UnitView = views[id]
		view.global_position = _world(rules.units[id].cell)
		view.set_bars(rules.units[id].hp, rules.units[id].max_hp)
		view.set_visible_state(true)
		view.play_clip("idle")
		if rules.units[id].player:
			view.face_towards(Vector3(1, 0, 0))
		else:
			view.face_towards(Vector3(-1, 0, 0))
	mode = "move"
	moved_since_select = false
	selected = "jayze"
	cursor_cell = rules.units[selected].cell
	camera.reset()
	camera.focus_on(Vector3(0, 0.5, 0))
	input_enabled = true
	Audio.play_music("encounter", 0.2)
	await get_tree().create_timer(0.6).timeout
	Audio.play_music("combat", 1.0)
	_refresh_hud()
	hud.set_prompt("[%s] cursor · [%s] confirm move · [%s] actions · [%s]/[%s] switch · [%s] pause" %
		[Settings.glyph("move"), Settings.glyph("confirm"), Settings.glyph("menu"), Settings.glyph("party_prev"), Settings.glyph("party_next"), Settings.glyph("pause")])

# ------------------------------------------------------------- HUD refresh

func _refresh_hud() -> void:
	var state_names := {
		"explore": "explore", "move": "choose move & action", "command": "command",
		"target": "targeting", "resolve": "resolving", "enemy": "enemy turn",
		"result": "finished",
	}
	hud.update_state(rules, state_names.get(mode, mode), selected, pending_target, mode == "move")
	_update_cursor_visuals(rules.reachable_cells(selected))
	_update_target_markers()

func _update_cursor_visuals(reachable: Array[Vector2i]) -> void:
	cursor.visible = mode == "move"
	cursor.global_position = _world(cursor_cell)
	for i in highlights.size():
		if mode == "move" and i < reachable.size():
			highlights[i].visible = true
			highlights[i].global_position = _world(reachable[i])
		else:
			highlights[i].visible = false

var _target_rings := {}
func _update_target_markers() -> void:
	# persist highlight rings on enemies while targeting
	if mode != "target":
		for id in _target_rings:
			_target_rings[id].visible = false
		return
	for foe in rules.living_foe_ids():
		var in_range: bool = _in_range(foe, pending_action)
		if not _target_rings.has(foe):
			_target_rings[foe] = BattleVfx.telegraph_ring(self, Vector3.ZERO,
				Color(1, 0.5, 0.3, 0.9) if in_range else Color(0.6, 0.6, 0.6, 0.5), 0.5)
		var ring: MeshInstance3D = _target_rings[foe]
		ring.visible = true
		ring.global_position = _world(rules.units[foe].cell) + Vector3(0, 0.05, 0)
		ring.material_override.albedo_color = Color(1, 0.5, 0.3, 0.9) if in_range else Color(0.6, 0.6, 0.6, 0.5)
