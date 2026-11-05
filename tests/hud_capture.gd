extends SceneTree

## Visual QA capture — runs the encounter scene in a real rendering context,
## drives the battle through meaningful states, and saves PNGs to artifacts/
## for presentation review (readability, HUD layout, silhouettes, telegraphs).
## Usage (requires a display):
##   godot --path . --script tests/hud_capture.gd
## Headless runs produce blank images and are not useful for review.

var frames := 0
var director = null
var step := 0

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/encounter.tscn")
	director = scene.instantiate()
	root.add_child(director)

func _process(_delta: float) -> bool:
	frames += 1
	match step:
		0:
			if frames == 30:
				_capture("01_explore")
				step = 1
		1:
			if frames == 32:
				director._begin_combat()
				step = 2
		2:
			if frames == 110:
				_capture("02_battle_framing")
				step = 3
		3:
			if frames == 112:
				director.rules.move_unit("kip", Vector2i(4, 4))
				director._tween_move("kip", 0.3)
				step = 4
		4:
			if frames == 140:
				director._open_command_menu()
				step = 5
		5:
			if frames == 170:
				_capture("03_command_menu")
				director._close_menus()
				director._execute_action("kip", "shoot", "sprocket")
				step = 6
		6:
			if frames == 220:
				_capture("04_attack_resolve")
				step = 7
		7:
			if frames == 222:
				for pid in director.rules.living_party_ids():
					if not director.rules.activated.has(pid):
						director.rules.activated.append(pid)
				director.rules.activations_left = 0
				director.rules.awaiting_enemy = true
				director._run_enemy_phase()
				step = 8
		8:
			if frames == 268:
				_capture("05_enemy_telegraph")
				step = 9
		9:
			if frames == 300:
				_capture("06_enemy_attack_impact")
				step = 10
		10:
			if frames == 302:
				director.rules._damage("sprocket", 99)
				director.rules._damage("clanker", 99)
				director.rules._damage("gimbal", 99)
				director._finish_battle("victory")
				step = 11
		11:
			if frames == 380:
				_capture("07_victory")
				step = 12
		12:
			if frames == 385:
				print("CAPTURED 7 frames")
				quit(0)
	return false

func _capture(label: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://artifacts/captures")
	img.save_png("res://artifacts/captures/%s.png" % label)
	print("CAPTURE ", label)
