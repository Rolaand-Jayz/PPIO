extends SceneTree

var frames := 0

func _initialize() -> void:
	root.add_child(load("res://scenes/encounter.tscn").instantiate())

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 45:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://artifacts/hud_live.png")
		print("CAPTURED")
		quit(0)
	return frames >= 45
