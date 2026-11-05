class_name UnitView
extends Node3D
## Per-unit battle presentation: imported GLB model, animation control with
## blending and interruption, sockets, status sprites, hit flash, and the
## small procedural bits (Kip wheel spin proportional to travel distance).
## Animation never decides gameplay — the battle director tells it what to
## show, and reports back when clips finish.

signal clip_finished(clip: String)

const LOOPING := ["idle", "move", "guard", "victory", "brace", "ram"]
const BONES := {  # procedural wheel bones (Kip)
	"kip": ["WheelFL", "WheelFR", "WheelBL", "WheelBR"],
}
const WHEEL_CIRCUMFERENCE := 1.07  # 2*pi*0.17 — tuned to the model

var unit_id := ""
var display_name := ""
var accent := Color.WHITE
var max_hp := 1
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var sockets := {}

var _bar_bg: Sprite3D
var _bar_fill: Sprite3D
var _status_sprite: Sprite3D
var _overlay: StandardMaterial3D
var _wheel_bones: PackedInt32Array = []
var _wheel_spin := 0.0
var _moving := false
var _move_rate := 0.0  # world units / second while moving
var _dead := false

const BAR_W := 0.72
const BAR_H := 0.09

func setup(id: String, name_label: String, color: Color, scene: PackedScene) -> void:
	unit_id = id
	display_name = name_label
	accent = color
	max_hp = 1
	model = scene.instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] if model.find_children("*", "Skeleton3D", true, false).size() > 0 else null
	for child in model.find_children("*", "AnimationPlayer", true, false):
		anim = child
	if anim == null:
		push_error("UnitView %s: imported scene has no AnimationPlayer" % id)
		return
	for clip_name in anim.get_animation_list():
		var a := anim.get_animation(clip_name)
		a.loop_mode = Animation.LOOP_LINEAR if clip_name in LOOPING else Animation.LOOP_NONE
	if skeleton != null:
		for i in skeleton.get_bone_count():
			var bname := skeleton.get_bone_name(i)
			if bname.begins_with("Socket_"):
				sockets[bname] = i
			if bname in BONES.get(id, []):
				_wheel_bones.append(i)
	_build_markers()

func _build_markers() -> void:
	# floating name + hp bar (billboards, readable at battle camera distance)
	var label := Label3D.new()
	label.text = display_name
	label.font_size = 52
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = accent.lightened(0.25)
	label.outline_size = 8
	label.position = Vector3(0, 1.62, 0)
	add_child(label)
	_bar_bg = _bar_sprite(Vector3(0, 1.45, 0))
	add_child(_bar_bg)
	_bar_fill = _bar_sprite(Vector3(0, 1.45, 0))
	add_child(_bar_fill)
	_status_sprite = _bar_sprite(Vector3(0, 1.3, 0))
	_status_sprite.position = Vector3(0, 1.32, 0)
	add_child(_status_sprite)
	set_status("")

func _bar_sprite(pos: Vector3) -> Sprite3D:
	var s := Sprite3D.new()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.pixel_size = 0.011
	s.position = pos
	s.texture = _bar_texture(1.0, Color(0.1, 0.12, 0.14), Color(0.3, 0.85, 0.4))
	return s

func _bar_texture(frac: float, bg: Color, fg: Color) -> ImageTexture:
	var w := 72
	var h := 10
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	var fill_w := int(round((w - 4) * clampf(frac, 0.0, 1.0)))
	img.fill_rect(Rect2i(2, 2, fill_w, h - 4), fg)
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------- state

func set_bars(hp: int, max_hp: int) -> void:
	var frac := 0.0 if max_hp <= 0 else float(hp) / float(max_hp)
	_bar_fill.texture = _bar_texture(frac, Color(0.1, 0.12, 0.14),
		Color(0.9, 0.25, 0.2) if frac < 0.34 else (Color(0.95, 0.8, 0.25) if frac < 0.67 else Color(0.3, 0.85, 0.4)))

func set_status(status: String) -> void:
	## "guard" | "stun" | "acted" | "" — color-coded, shape+text (not color-only)
	var img := Image.create(96, 26, false, Image.FORMAT_RGBA8)
	if status != "":
		img.fill(Color(0.08, 0.09, 0.12, 0.75))
	match status:
		"guard":
			img.fill_rect(Rect2i(6, 8, 10, 10), Color(0.45, 0.75, 1.0))
		"stun":
			img.fill_rect(Rect2i(6, 8, 10, 10), Color(1.0, 0.85, 0.2))
		"acted":
			img.fill_rect(Rect2i(6, 8, 10, 10), Color(0.5, 0.5, 0.55))
	_status_sprite.texture = ImageTexture.create_from_image(img) if status != "" else null

func set_visible_state(alive: bool, result_phase := "") -> void:
	_dead = not alive
	if not alive:
		_bar_bg.visible = false
		_bar_fill.visible = false
		_status_sprite.visible = false

func face_towards(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)

func face_cell(target_world: Vector3) -> void:
	face_towards(target_world - global_position)

# ------------------------------------------------------------- animation

func play_clip(clip: String, speed := 1.0, blend := 0.18) -> void:
	if anim == null:
		return
	if not anim.has_animation(clip):
		clip = "idle"
	anim.play(clip, blend, speed)

func play_then_idle(clip: String, speed := 1.0) -> void:
	play_clip(clip, speed)
	if anim == null or not anim.has_animation(clip):
		clip_finished.emit(clip)
		return
	anim.animation_finished.connect(func(_name: String) -> void:
		play_clip("idle")
		clip_finished.emit(clip),
	CONNECT_ONE_SHOT)

func await_clip(clip: String, speed := 1.0) -> void:
	play_then_idle(clip, speed)
	if anim != null and anim.has_animation(clip):
		await clip_finished

func clip_length(clip: String) -> float:
	if anim != null and anim.has_animation(clip):
		return anim.get_animation(clip).length / maxf(anim.speed_scale, 0.01)
	return 0.8

func flash_hit() -> void:
	if _overlay == null:
		_overlay = StandardMaterial3D.new()
		_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_overlay.albedo_color = Color(1, 0.4, 0.35, 0.4)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = _overlay
	var t := get_tree().create_timer(0.14)
	t.timeout.connect(func() -> void:
		if is_instance_valid(model):
			for mi in model.find_children("*", "MeshInstance3D", true, false):
				mi.material_overlay = null)

func socket_pos(name: String) -> Vector3:
	if skeleton != null and sockets.has(name):
		return skeleton.global_transform * (skeleton.get_bone_global_pose(sockets[name]).origin)
	return global_position + Vector3(0, 0.6, 0)

func set_moving(moving: bool, rate := 0.0) -> void:
	_moving = moving
	_move_rate = rate

func _process(delta: float) -> void:
	# Kip: wheel rotation derived from actual travel distance, not a canned loop.
	if _moving and _wheel_bones.size() > 0 and skeleton != null:
		_wheel_spin += (_move_rate / WHEEL_CIRCUMFERENCE) * TAU * delta
		for idx in _wheel_bones:
			var base := skeleton.get_bone_pose_rotation(idx)
			skeleton.set_bone_pose_rotation(idx, base * Quaternion(Vector3(0, 1, 0), _wheel_spin))
