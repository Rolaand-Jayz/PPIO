class_name BattleCamera
extends Node3D
## Responsive battle camera: spring-follows a focus point, orbits with the
## right stick, zooms with LT/RT (+/- on keyboard), and shakes on impacts.
## Controller-first defaults with full keyboard parity.

var cam: Camera3D
var focus := Vector3(0, 0.6, 0)
var yaw := 0.55       # radians, orbit around focus
var pitch := 0.58
var distance := 8.6
var min_distance := 5.0
var max_distance := 14.0
var _shake := 0.0
var _target_yaw := 0.55
var _target_pitch := 0.58
var _target_distance := 8.6

const PITCH_MIN := 0.28
const PITCH_MAX := 1.15
const STICK_SPEED := 2.4     # rad/s
const ZOOM_SPEED := 7.0      # units/s
const FOLLOW := 6.0

func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	_update_transform(true)

func _process(delta: float) -> void:
	var orbit := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	_target_yaw -= orbit.x * STICK_SPEED * delta
	_target_pitch = clampf(_target_pitch + orbit.y * STICK_SPEED * 0.7 * delta, PITCH_MIN, PITCH_MAX)
	var zoom := Input.get_action_strength("cam_zoom_out") - Input.get_action_strength("cam_zoom_in")
	if absf(zoom) > 0.01:
		_target_distance = clampf(_target_distance + zoom * ZOOM_SPEED * delta, min_distance, max_distance)
	yaw = lerpf(yaw, _target_yaw, minf(1.0, 10.0 * delta))
	pitch = lerpf(pitch, _target_pitch, minf(1.0, 10.0 * delta))
	distance = lerpf(distance, _target_distance, minf(1.0, 8.0 * delta))
	_update_transform(false, delta)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.6)
		var s := _shake * _shake
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.22 * s
		cam.rotation.z = randf_range(-1, 1) * 0.02 * s

func _update_transform(snap: bool, delta := 0.016) -> void:
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	var target_pos := focus + offset
	if snap:
		global_position = target_pos
	else:
		global_position = global_position.lerp(target_pos, minf(1.0, FOLLOW * delta * 0.4 + 0.15))
	look_at(focus, Vector3.UP)

func focus_on(point: Vector3, snap := false) -> void:
	focus = Vector3(point.x, 0.55, point.z)
	if snap:
		_update_transform(true)

func focus_mid(a: Vector3, b: Vector3) -> void:
	focus_on((a + b) * 0.5)

func shake(amount: float) -> void:
	if not Settings.camera_shake:
		return
	_shake = minf(_shake + amount, 1.2)

func reset() -> void:
	yaw = 0.55
	pitch = 0.62
	_target_yaw = yaw
	_target_pitch = pitch
	distance = 8.6
	_target_distance = distance
	focus_on(Vector3(0, 0.55, 0), true)
