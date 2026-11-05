class_name BattleHud
extends CanvasLayer
## Controller-first combat HUD: party status, enemy intel, command menu,
## targeting, contextual prompts, pause/settings/controls, result overlay.
## Every interactive element is reachable with the pad alone; keyboard/mouse
## have full parity through the same Godot InputMap actions.

signal action_chosen(action: String)
signal target_chosen(target_id: String)
signal menu_cancelled
signal restart_requested
signal begin_combat_requested

var party_rows := {}        # id -> Dictionary of row controls
var enemy_rows := {}        # id -> Dictionary of row controls
var menu_panel: PanelContainer
var menu_list: VBoxContainer
var target_panel: PanelContainer
var target_list: VBoxContainer
var event_label: Label
var round_label: Label
var prompt_label: Label
var pause_root: Control
var result_root: Control
var log_lines: Array[String] = []

var _menu_open := false
var _pause_open := false
var _result_open := false
var _theme: Theme
var _result_title: Label
var _result_subtitle: Label
var _result_prompt: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var theme := Theme.new()
	theme.default_font_size = 17
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.09, 0.13, 0.82)
	panel_style.border_color = Color(0.85, 0.75, 0.45, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.95, 0.8, 0.35, 0.22)
	focus_style.border_color = Color(0.98, 0.86, 0.45)
	focus_style.set_border_width_all(3)
	focus_style.set_corner_radius_all(4)
	focus_style.set_content_margin_all(6)
	theme.set_stylebox("focus", "Button", focus_style)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.13, 0.16, 0.22, 0.9)
	btn_style.set_content_margin_all(6)
	btn_style.set_corner_radius_all(4)
	theme.set_stylebox("normal", "Button", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.25, 0.34, 0.95)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_color("font_color", "Button", Color(0.92, 0.93, 0.95))
	theme.set_color("font_focus_color", "Button", Color(1, 0.95, 0.8))
	var slider_style := StyleBoxFlat.new()
	slider_style.bg_color = Color(0.2, 0.24, 0.32)
	slider_style.set_corner_radius_all(3)
	theme.set_stylebox("slider", "HSlider", slider_style)
	_theme = theme
	_build_static_ui()

# ------------------------------------------------------------- static layout

func _build_static_ui() -> void:
	# top bar: round info + event log
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.position = Vector2(14, 12)
	top.custom_minimum_size = Vector2(430, 84)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.theme = _theme
	add_child(top)
	var top_v := VBoxContainer.new()
	top.add_child(top_v)
	round_label = Label.new()
	round_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	top_v.add_child(round_label)
	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size = Vector2(410, 0)
	top_v.add_child(event_label)

	# party panel (bottom-left)
	var party_panel := PanelContainer.new()
	party_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	party_panel.position = Vector2(14, -282)
	party_panel.custom_minimum_size = Vector2(360, 200)
	party_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	party_panel.theme = _theme
	add_child(party_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 4)
	party_panel.add_child(pv)
	var head := Label.new()
	head.text = "PARTY"
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	pv.add_child(head)
	for id in ["jayze", "kip", "rallo", "jonnie"]:
		var row := _party_row(id)
		pv.add_child(row)

	# enemy intel (right side)
	var enemy_panel := PanelContainer.new()
	enemy_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	enemy_panel.position = Vector2(-250, -140)
	enemy_panel.custom_minimum_size = Vector2(236, 210)
	enemy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_panel.theme = _theme
	add_child(enemy_panel)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 4)
	enemy_panel.add_child(ev)
	var ehead := Label.new()
	ehead.text = "OPPONENTS"
	ehead.add_theme_font_size_override("font_size", 14)
	ehead.add_theme_color_override("font_color", Color(0.95, 0.6, 0.55))
	ev.add_child(ehead)
	for id in ["sprocket", "clanker", "gimbal"]:
		var row := _enemy_row(id)
		ev.add_child(row)

	# contextual prompts (bottom-right)
	var prompt_panel := PanelContainer.new()
	prompt_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	prompt_panel.position = Vector2(-680, -70)
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.theme = _theme
	add_child(prompt_panel)
	prompt_label = Label.new()
	prompt_label.custom_minimum_size = Vector2(640, 0)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	prompt_panel.add_child(prompt_label)

	# command menu + targeting overlays (centered, non-modal until opened)
	menu_panel = PanelContainer.new()
	menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	menu_panel.position = Vector2(-160, 40)
	menu_panel.visible = false
	menu_panel.theme = _theme
	add_child(menu_panel)
	menu_list = VBoxContainer.new()
	menu_list.add_theme_constant_override("separation", 6)
	menu_panel.add_child(menu_list)
	target_panel = PanelContainer.new()
	target_panel.set_anchors_preset(Control.PRESET_CENTER)
	target_panel.position = Vector2(60, 60)
	target_panel.visible = false
	target_panel.theme = _theme
	add_child(target_panel)
	target_list = VBoxContainer.new()
	target_list.add_theme_constant_override("separation", 6)
	target_panel.add_child(target_list)

	_build_pause()
	_build_result()

func _party_row(id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var chip := PortraitChip.new()
	chip.unit_id = id
	chip.custom_minimum_size = Vector2(34, 34)
	row.add_child(chip)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var name_line := HBoxContainer.new()
	col.add_child(name_line)
	var name_label := Label.new()
	name_label.text = id.capitalize()
	name_label.custom_minimum_size = Vector2(86, 0)
	name_line.add_child(name_label)
	var status_label := Label.new()
	status_label.add_theme_font_size_override("font_size", 13)
	name_line.add_child(status_label)
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 14)
	hp_bar.show_percentage = false
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.16)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.4, 0.85, 0.45)
	fg.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.add_theme_stylebox_override("fill", fg)
	col.add_child(hp_bar)
	var meta := Label.new()
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	col.add_child(meta)
	party_rows[id] = {"row": row, "chip": chip, "hp": hp_bar, "meta": meta, "status": status_label}
	return row

func _enemy_row(id: String) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var name_line := HBoxContainer.new()
	row.add_child(name_line)
	var name_label := Label.new()
	name_label.text = id.capitalize()
	name_label.custom_minimum_size = Vector2(96, 0)
	name_line.add_child(name_label)
	var intent_label := Label.new()
	intent_label.add_theme_font_size_override("font_size", 13)
	intent_label.add_theme_color_override("font_color", Color(1, 0.55, 0.4))
	name_line.add_child(intent_label)
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 12)
	hp_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.16)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.9, 0.4, 0.3)
	fg.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.add_theme_stylebox_override("fill", fg)
	row.add_child(hp_bar)
	var meta := Label.new()
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	row.add_child(meta)
	enemy_rows[id] = {"row": row, "hp": hp_bar, "meta": meta, "intent": intent_label}
	return row

# ------------------------------------------------------------- pause/settings

func _build_pause() -> void:
	pause_root = Control.new()
	pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.visible = false
	pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_root.theme = _theme
	add_child(pause_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.add_child(center)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(360, 0)
	center.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	var title := Label.new()
	title.text = "— PAUSED —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_pause_menu_box = v

func _pause_option(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(cb)
	b.focus_entered.connect(func() -> void: Audio.ui("ui_move"))
	_pause_menu_box.add_child(b)
	return b

var _pause_menu_box: VBoxContainer
var _settings_box: VBoxContainer

func open_pause() -> void:
	if _pause_open or _result_open:
		return
	_pause_open = true
	pause_root.visible = true
	Audio.ui("ui_pause")
	_rebuild_pause_home()
	get_tree().paused = true

func _rebuild_pause_home() -> void:
	for c in _pause_menu_box.get_children():
		if c is Label and c.text.begins_with("—"):
			continue
		c.queue_free()
	var resume := _pause_option("Resume", func() -> void: close_pause())
	resume.call_deferred("grab_focus")
	_pause_option("Settings", func() -> void: _open_settings())
	_pause_option("Controls", func() -> void: _open_controls())
	_pause_option("Restart Battle", func() -> void:
		close_pause()
		restart_requested.emit())
	_pause_option("Quit to Test Entry", func() -> void:
		close_pause()
		get_tree().quit(0))

func close_pause() -> void:
	_pause_open = false
	pause_root.visible = false
	Audio.ui("ui_close")
	get_tree().paused = false

func is_paused() -> bool:
	return _pause_open

func _open_settings() -> void:
	Audio.ui("ui_open")
	for c in _pause_menu_box.get_children():
		if c is Label and c.text.begins_with("—"):
			continue
		c.queue_free()
	var back := Button.new()
	back.text = "← Back"
	back.pressed.connect(func() -> void:
		Audio.ui("ui_cancel")
		_rebuild_pause_home())
	back.focus_entered.connect(func() -> void: Audio.ui("ui_move"))
	_pause_menu_box.add_child(back)
	back.call_deferred("grab_focus")
	var sliders := {}
	for bus in ["Master", "Music", "SFX", "UI", "Ambience"]:
		var row := HBoxContainer.new()
		_pause_menu_box.add_child(row)
		var lab := Label.new()
		lab.text = bus
		lab.custom_minimum_size = Vector2(96, 0)
		row.add_child(lab)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Settings.volumes[bus]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(v: float) -> void:
			Settings.set_volume(bus, v)
			if bus != "Master" and bus != "Music":
				Audio.ui("ui_move", 1.0))
		slider.focus_entered.connect(func() -> void: Audio.ui("ui_move"))
		row.add_child(slider)
		sliders[bus] = slider
		var mute := Button.new()
		mute.toggle_mode = true
		mute.text = "M"
		mute.button_pressed = Settings.mutes[bus]
		mute.custom_minimum_size = Vector2(34, 0)
		mute.toggled.connect(func(on: bool) -> void:
			Settings.toggle_mute(bus)
			mute.button_pressed = Settings.mutes[bus])
		row.add_child(mute)
	var shake_btn := Button.new()
	shake_btn.toggle_mode = true
	shake_btn.text = "Camera shake"
	shake_btn.button_pressed = Settings.camera_shake
	shake_btn.toggled.connect(func(on: bool) -> void:
		Settings.camera_shake = on
		Settings.save_settings())
	_pause_menu_box.add_child(shake_btn)
	# keep first slider focused for pad flow
	sliders["Master"].call_deferred("grab_focus")

func _open_controls() -> void:
	Audio.ui("ui_open")
	for c in _pause_menu_box.get_children():
		if c is Label and c.text.begins_with("—"):
			continue
		c.queue_free()
	var grid := GridContainer.new()
	grid.columns = 2
	_pause_menu_box.add_child(grid)
	var pad_pairs := [
		["Move / cursor", "Left stick · D-pad · WASD"],
		["Camera orbit", "Right stick · Arrow keys"],
		["Zoom", "LT / RT · - and ="],
		["Confirm", "A · Enter"],
		["Cancel / back", "B · Esc"],
		["Command menu", "Y · Tab"],
		["Switch party member", "LB / RB · Q / E"],
		["Target select", "LB / RB · Q / E"],
		["Pause", "Start · P"],
		["Begin combat (explore)", "Y · Tab"],
	]
	for pair in pad_pairs:
		var a := Label.new()
		a.text = pair[0]
		a.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
		grid.add_child(a)
		var b := Label.new()
		b.text = pair[1]
		grid.add_child(b)
	var back := Button.new()
	back.text = "← Back"
	back.pressed.connect(func() -> void:
		Audio.ui("ui_cancel")
		_rebuild_pause_home())
	_pause_menu_box.add_child(back)
	back.call_deferred("grab_focus")

# ------------------------------------------------------------- result

func _build_result() -> void:
	result_root = Control.new()
	result_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_root.visible = false
	result_root.process_mode = Node.PROCESS_MODE_ALWAYS
	result_root.theme = _theme
	add_child(result_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_root.add_child(center)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(430, 200)
	center.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	_result_title = Label.new()
	_result_title.add_theme_font_size_override("font_size", 34)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_result_title)
	_result_subtitle = Label.new()
	_result_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_subtitle.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	v.add_child(_result_subtitle)
	_result_prompt = Label.new()
	_result_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_prompt.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	v.add_child(_result_prompt)

func show_result(victory: bool, rounds: int, survivors: int) -> void:
	_result_open = true
	result_root.visible = true
	_result_title.text = "VICTORY!" if victory else "DEFEAT"
	_result_title.add_theme_color_override("font_color", Color(0.5, 1, 0.6) if victory else Color(1, 0.45, 0.4))
	_result_subtitle.text = "Battle finished in %d rounds · %d toy%s still standing" % [rounds, survivors, "" if survivors == 1 else "s"]
	_result_prompt.text = "[%s] Rematch    [%s] Quit" % [Settings.glyph("confirm"), Settings.glyph("cancel")]

func is_result_open() -> bool:
	return _result_open

func hide_result() -> void:
	_result_open = false
	result_root.visible = false

# ------------------------------------------------------------- live data

func update_state(rules, director_state: String, selected: String, target: String, active: bool) -> void:
	round_label.text = "ROUND %d   ·   %s" % [rules.round_number, director_state.to_upper()]
	event_label.text = rules.event
	for id in party_rows:
		var u: Dictionary = rules.units[id]
		var row: Dictionary = party_rows[id]
		row.hp.value = 100.0 * float(u.hp) / float(u.max_hp)
		var tags: Array[String] = []
		if u.guard: tags.append("GUARD")
		if u.stunned > 0: tags.append("DAZED")
		if rules.activated.has(id) and rules.phase == "player": tags.append("ACTED")
		if id == "kip" and u.momentum >= 2: tags.append("RAM READY")
		if id == "jonnie" and u.mend_cd > 0: tags.append("MEND %d" % u.mend_cd)
		row.status.text = "  ".join(tags)
		row.status.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
		if u.hp <= 0:
			row.status.text = "DOWN"
			row.status.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3))
		row.meta.text = "HP %d/%d" % [u.hp, u.max_hp]
		var chip: PortraitChip = row.chip
		chip.active = id == selected
		chip.act_state = "down" if u.hp <= 0 else ("acted" if (rules.activated.has(id) and rules.phase == "player") else "ready")
		chip.queue_redraw()
	for id in enemy_rows:
		var e: Dictionary = rules.units[id]
		var erow: Dictionary = enemy_rows[id]
		if e.hp <= 0:
			erow.hp.value = 0
			erow.meta.text = "down"
			erow.intent.text = "✕"
			continue
		erow.hp.value = 100.0 * float(e.hp) / float(e.max_hp)
		erow.meta.text = "HP %d/%d" % [e.hp, e.max_hp]
		var intent: String = rules.foe_intents().get(id, "")
		erow.intent.text = {"attack": "⚔ attack", "advance": "» advance", "dazed": "~ dazed"}.get(intent, "")

func set_prompt(text: String) -> void:
	prompt_label.text = text

func push_log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 4:
		log_lines.pop_front()

# ------------------------------------------------------------- menus

func open_command_menu(unit_id: String, actions: Array, costs: Dictionary, availability: Dictionary) -> void:
	_menu_open = true
	menu_panel.visible = true
	for c in menu_list.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "%s — choose an action" % unit_id.capitalize()
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	menu_list.add_child(title)
	var first: Button = null
	for action in actions:
		var b := Button.new()
		var label: String = COMMAND_LABELS.get(action, action.capitalize())
		var cost: String = costs.get(action, "")
		b.text = label + ("" if cost == "" else "   [%s]" % cost)
		var ok: bool = availability.get(action, true)
		b.disabled = not ok
		b.pressed.connect(func() -> void:
			Audio.ui("ui_confirm")
			action_chosen.emit(action))
		b.focus_entered.connect(func() -> void: Audio.ui("ui_move"))
		menu_list.add_child(b)
		if first == null and ok:
			first = b
	var hint := Label.new()
	hint.text = "[%s] confirm    [%s] back" % [Settings.glyph("confirm"), Settings.glyph("cancel")]
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	menu_list.add_child(hint)
	if first != null:
		first.call_deferred("grab_focus")

func close_command_menu() -> void:
	_menu_open = false
	menu_panel.visible = false

func is_menu_open() -> bool:
	return _menu_open

func open_target_menu(options: Array, kind: String) -> void:
	_menu_open = true
	target_panel.visible = true
	for c in target_list.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "Select target" if kind == "foe" else "Select ally"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	target_list.add_child(title)
	var first: Button = null
	for opt in options:
		var b := Button.new()
		b.text = opt.label
		b.pressed.connect(func() -> void:
			Audio.ui("ui_target")
			target_chosen.emit(opt.id))
		b.focus_entered.connect(func() -> void: Audio.ui("ui_move"))
		target_list.add_child(b)
		if first == null:
			first = b
	var hint := Label.new()
	hint.text = "[%s] confirm    [%s] back" % [Settings.glyph("confirm"), Settings.glyph("cancel")]
	hint.add_theme_font_size_override("font_size", 13)
	target_list.add_child(hint)
	if first != null:
		first.call_deferred("grab_focus")

func close_target_menu() -> void:
	_menu_open = false
	target_panel.visible = false

const COMMAND_LABELS := {
	"melee": "Attack", "technique": "Technique (5 dmg)", "claw": "Claw",
	"pound": "Pound (stagger)", "shoot": "Bolt shot", "ram": "Ram (needs 2 momentum)",
	"screech": "Screech (daze)", "mend": "Mend (heal 3)", "brace": "Brace (pair guard)",
	"guard": "Guard (-2 next hit)", "cooperate": "Co-op strike (Jayze+Kip)",
	"interact": "Smash music box", "begin_combat": "Begin combat!",
}

func _input(event: InputEvent) -> void:
	Settings.note_input_device(event)
