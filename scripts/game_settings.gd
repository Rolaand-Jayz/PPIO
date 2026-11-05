extends Node
## Persistent game settings (autoload: Settings) — audio buses, mutes,
## camera shake, input profile. Persisted to user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
const BUS_ORDER := ["Master", "Music", "SFX", "UI", "Ambience"]

var volumes := {"Master": 0.9, "Music": 0.75, "SFX": 0.9, "UI": 0.8, "Ambience": 0.6}
var mutes := {"Master": false, "Music": false, "SFX": false, "UI": false, "Ambience": false}
var camera_shake := true
var last_input_device := "pad"  # "pad" | "kbm" — drives on-screen glyphs

func _ready() -> void:
	load_settings()
	apply_audio()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for bus in BUS_ORDER:
		volumes[bus] = clampf(cfg.get_value("audio", "volume_" + bus, volumes[bus]), 0.0, 1.0)
		mutes[bus] = bool(cfg.get_value("audio", "mute_" + bus, mutes[bus]))
	camera_shake = bool(cfg.get_value("game", "camera_shake", true))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for bus in BUS_ORDER:
		cfg.set_value("audio", "volume_" + bus, volumes[bus])
		cfg.set_value("audio", "mute_" + bus, mutes[bus])
	cfg.set_value("game", "camera_shake", camera_shake)
	cfg.save(PATH)

func apply_audio() -> void:
	for bus in BUS_ORDER:
		var idx := AudioServer.get_bus_index(bus)
		if idx < 0:
			continue
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volumes[bus], 0.0001)))
		AudioServer.set_bus_mute(idx, mutes[bus])
	changed.emit()

func set_volume(bus: String, v: float) -> void:
	volumes[bus] = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()

func toggle_mute(bus: String) -> void:
	mutes[bus] = not mutes[bus]
	apply_audio()
	save_settings()

func note_input_device(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if last_input_device != "pad":
			last_input_device = "pad"
			changed.emit()
	elif event is InputEventKey or event is InputEventMouseButton:
		if last_input_device != "kbm":
			last_input_device = "kbm"
			changed.emit()

func glyph(action: String) -> String:
	## Contextual button-prompt glyph for the current input profile.
	if last_input_device == "kbm":
		return SettingsKeyboard.LABELS.get(action, "?")
	return SettingsPad.LABELS.get(action, "?")

class SettingsPad:
	const LABELS := {
		"confirm": "A", "cancel": "B", "menu": "Y", "ability": "X",
		"party_next": "RB", "party_prev": "LB", "target_next": "RB",
		"target_prev": "LB", "pause": "Start", "camera": "RS",
		"zoom": "LT/RT", "move": "L-Stick/D-Pad",
	}

class SettingsKeyboard:
	const LABELS := {
		"confirm": "Enter", "cancel": "Esc", "menu": "Tab", "ability": "Q",
		"party_next": "E", "party_prev": "Q", "target_next": "E",
		"target_prev": "Q", "pause": "P", "camera": "Arrows",
		"zoom": "+/-", "move": "WASD",
	}
