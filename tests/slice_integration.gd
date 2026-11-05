extends SceneTree

## Combat-slice integration test (headless).
## Boots the real encounter scene and drives a full battle through the
## director: begin combat -> move -> shoot -> enemy phase (staged) ->
## round 2 -> forced result -> restart. Verifies animation, staged enemy
## application, HUD wiring and state machine recovery.

const TIMEOUT := 45.0

var failures := 0

func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok — " + what)
	else:
		failures += 1
		printerr("  FAIL — " + what)

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	print("== slice integration ==")
	var scene: PackedScene = load("res://scenes/encounter.tscn")
	check(scene != null, "encounter scene loads")
	var director = scene.instantiate()
	root.add_child(director)
	await process_frame
	await process_frame
	check(director.rules != null, "rules instance present")
	check(director.views.size() == 7, "seven unit views (4 party + 3 foes)")
	for id in director.views:
		var v = director.views[id]
		check(v.anim != null, "%s has an AnimationPlayer" % id)
		check(v.anim.is_playing() or v.anim.current_animation == "idle", "%s is animating (idle)" % id)

	# ---- explore -> begin combat ----
	check(director.mode == "explore", "boots into explore")
	director._begin_combat()
	await _wait(director, func(): return director.mode == "move", 6.0)
	check(director.rules.phase == "player", "rules in player phase")
	check(director.rules.defer_enemy_phase, "enemy phase deferred for staged presentation")

	# ---- move + shoot (Kip, reach 4) ----
	check(director.rules.move_unit("kip", Vector2i(4, 4)), "kip steps toward foes")
	await director._tween_move("kip", 0.3)
	var hp_before: int = director.rules.units.sprocket.hp
	director._execute_action("kip", "shoot", "sprocket")
	await _wait(director, func(): return director.mode == "move" and director.input_enabled, 8.0)
	check(director.rules.units.sprocket.hp == hp_before - 2, "shot dealt deterministic 2 damage")
	var kip_view = director.views["kip"]
	check(kip_view.anim.current_animation == "idle" or kip_view.anim.is_playing(), "kip animation state healthy after action")
	check(director.views["sprocket"]._bar_fill != null, "sprocket hp bar updated pipeline exists")

	# ---- exhaust the round -> staged enemy phase ----
	for pid in director.rules.living_party_ids():
		if not director.rules.activated.has(pid):
			director.rules.activated.append(pid)
	director.rules.activations_left = 0
	director.rules.awaiting_enemy = true
	director._run_enemy_phase()
	await _wait(director, func(): return director.mode == "move" and director.rules.round_number == 2, 20.0)
	check(director.rules.round_number == 2, "staged enemy phase completed and round advanced")

	# ---- guard then force victory presentation path ----
	director.rules._damage("sprocket", 99)
	director.rules._damage("clanker", 99)
	director.rules._damage("gimbal", 99)
	check(director.rules.result == "victory", "rules declare victory when all foes fall")
	director._finish_battle("victory")
	await _wait(director, func(): return director.hud.is_result_open(), 6.0)
	check(director.hud.is_result_open(), "victory overlay is shown")

	# ---- restart restores opening state ----
	director.reset_battle()
	await _wait(director, func(): return director.mode == "move" and director.rules.round_number == 1, 8.0)
	check(director.rules.units.sprocket.hp == 9, "restart restores enemy hp")
	check(director.views["jayze"].global_position.distance_to(Vector3(-2.5, 0, -1.5)) < 0.01, "restart restores party positions")
	check(not director.hud.is_result_open(), "result overlay hidden after restart")

	# ---- pause menu safety ----
	director.hud.open_pause()
	check(director.hud.is_paused() and root.get_tree() != null and paused, "pause engages tree pause")
	director.hud.close_pause()
	check(not paused, "resume releases tree pause")

	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	if failures == 0:
		print("PASS integration (%.1fs): scene, units, animation, staged enemy phase, result, restart, pause" % secs)
	else:
		print("FAIL integration: %d checks failed" % failures)
	quit(1 if failures > 0 else 0)

func _wait(director, pred: Callable, timeout_s: float) -> void:
	var elapsed := 0.0
	while elapsed < timeout_s:
		if pred.call():
			return
		await create_timer(0.1).timeout
		elapsed += 0.1
