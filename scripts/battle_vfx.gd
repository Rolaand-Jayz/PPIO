class_name BattleVfx
extends Object
## Combat visual effects — telegraphs, impacts, projectiles, guard flashes,
## heal sparkles and damage floaters. All effects are spawn-and-forget nodes
## that clean themselves up; none of them touch gameplay state.

static func _unshaded(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	return mat

static func burst(parent: Node, pos: Vector3, color: Color, count := 18, speed := 3.2, lifetime := 0.45, size := 0.07) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = count
	p.lifetime = lifetime
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -7, 0)
	p.mesh = _quad(size, color)
	parent.add_child(p)
	p.global_position = pos
	_cleanup_later(p, lifetime + 0.8)

static func impact(parent: Node, pos: Vector3, heavy := false) -> void:
	var color := Color(1.0, 0.82, 0.35) if heavy else Color(1.0, 0.95, 0.75)
	burst(parent, pos, color, 26 if heavy else 16, 4.5 if heavy else 3.0, 0.5, 0.09 if heavy else 0.06)
	# brief flash quad
	var flash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.9 if heavy else 0.55, 0.9 if heavy else 0.55)
	flash.mesh = quad
	flash.material_override = _unshaded(Color(1, 1, 1, 0.85))
	parent.add_child(flash)
	flash.global_position = pos + Vector3(0, 0.05, 0)
	var tw := flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector3.ONE * (1.8 if heavy else 1.3), 0.16)
	tw.tween_property(flash.material_override, "albedo_color:a", 0.0, 0.16)
	tw.chain().tween_callback(flash.queue_free)

static func slash(parent: Node, pos: Vector3, facing := Vector3.FORWARD, color := Color(0.85, 0.95, 1.0)) -> void:
	var arc := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.15, 0.3)
	arc.mesh = quad
	arc.material_override = _unshaded(color)
	parent.add_child(arc)
	arc.global_position = pos + Vector3(0, 0.6, 0)
	arc.rotation.y = atan2(facing.x, facing.z)
	arc.rotation.z = -0.5
	var tw := arc.create_tween()
	tw.set_parallel(true)
	tw.tween_property(arc, "rotation:z", 0.6, 0.22)
	tw.tween_property(arc.material_override, "albedo_color:a", 0.0, 0.22)
	tw.chain().tween_callback(arc.queue_free)

static func telegraph_ring(parent: Node, pos: Vector3, color := Color(1.0, 0.3, 0.2), radius := 0.45) -> Node3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.04
	torus.outer_radius = radius + 0.04
	torus.rings = 24
	ring.mesh = torus
	ring.material_override = _unshaded(color)
	parent.add_child(ring)
	ring.global_position = pos + Vector3(0, 0.05, 0)
	return ring

static func pulse_ring(parent: Node, pos: Vector3, color := Color(1.0, 0.35, 0.25), radius := 0.5, dur := 0.7) -> void:
	var ring := telegraph_ring(parent, pos, color, radius * 0.4)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * (radius / 0.44), dur)
	tw.tween_property(ring.material_override, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(ring.queue_free)

static func projectile(parent: Node, from: Vector3, to: Vector3, color := Color(1.0, 0.9, 0.3), dur := 0.28) -> void:
	var shot := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	shot.mesh = sphere
	shot.material_override = _unshaded(color)
	parent.add_child(shot)
	shot.global_position = from
	var trail := CPUParticles3D.new()
	trail.amount = 14
	trail.lifetime = 0.22
	trail.mesh = _quad(0.05, color)
	trail.emitting = true
	shot.add_child(trail)
	var tw := shot.create_tween()
	tw.tween_property(shot, "global_position", to, dur)
	tw.tween_callback(func():
		shot.queue_free())

static func guard_flash(parent: Node, unit_root: Node3D) -> void:
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.62
	sphere.height = 1.0
	dome.mesh = sphere
	dome.material_override = _unshaded(Color(0.45, 0.75, 1.0, 0.35))
	parent.add_child(dome)
	dome.global_position = unit_root.global_position + Vector3(0, 0.5, 0)
	var tw := dome.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dome.material_override, "albedo_color:a", 0.0, 0.4)
	tw.tween_property(dome, "scale", Vector3.ONE * 1.35, 0.4)
	tw.chain().tween_callback(dome.queue_free)

static func heal_sparkles(parent: Node, pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 22
	p.lifetime = 0.9
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, 0.6, 0)
	p.mesh = _quad(0.055, Color(0.45, 1.0, 0.6))
	parent.add_child(p)
	p.global_position = pos + Vector3(0, 0.2, 0)
	_cleanup_later(p, 1.6)

static func floater(parent: Node, pos: Vector3, text: String, color := Color(1, 0.9, 0.4)) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.outline_size = 10
	parent.add_child(label)
	label.global_position = pos + Vector3(0, 1.15, 0)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "global_position", label.global_position + Vector3(0, 0.7, 0), 0.8)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)

static func _quad(size: float, color: Color) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = _unshaded(color)
	return quad

static func _cleanup_later(node: Node, delay: float) -> void:
	var timer := node.get_tree().create_timer(delay)
	timer.timeout.connect(node.queue_free)
