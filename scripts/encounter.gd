extends Node3D

const Rules = preload("res://scripts/battle_rules.gd")
var rules = Rules.new()
var visuals := {}
var selection := "jayze"
var info: Label
var status: Label
var hud: VBoxContainer
var materials := {}
var portraits := {}
var portrait_view: TextureRect

const HUD_ICONS := {
	"jayze_select": "res://assets/hud/icon_sword.png",
	"kip_select": "res://assets/hud/icon_bolt.png",
	"combat": "res://assets/hud/icon_ram.png",
	"guard": "res://assets/hud/icon_shield.png",
	"interact": "res://assets/hud/icon_note.png",
	"cooperate": "res://assets/hud/icon_star.png",
}

func _hud_texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null

func _ready() -> void:
	_build_world()
	_build_hud()
	_refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			rules.begin_combat()
		elif event.keycode == KEY_1:
			selection = "jayze"
		elif event.keycode == KEY_2:
			selection = "kip"
		elif event.keycode == KEY_TAB:
			selection = "kip" if selection == "jayze" else "jayze"
		elif event.keycode == KEY_R and rules.phase == "finished":
			rules.reset()
			selection = "jayze"
		elif event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
			var delta := Vector2i.ZERO
			match event.keycode:
				KEY_W: delta.y = -1
				KEY_S: delta.y = 1
				KEY_A: delta.x = -1
				KEY_D: delta.x = 1
			rules.move_unit(selection, rules.units[selection].cell + delta)
		_refresh()

func _build_world() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 8.2, 9.4)
	camera.fov = 58.0
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	add_child(light)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("33404e")
	world.environment = environment
	add_child(world)
	_add_box("Floor", Vector3(0, -0.2, 0), Vector3(11, 0.35, 9), Color("c5b894"))
	_add_box("Cover toy block", Vector3(0.5, 0.2, -2), Vector3(1.4, 0.65, 0.8), Color("416c7a"))
	_add_box("Positioning obstacle", Vector3(-1.5, 0.28, -0.5), Vector3(0.75, 0.9, 0.75), Color("927351"))
	_add_box("Music box", Vector3(0.5, 0.2, 0), Vector3(0.65, 0.4, 0.6), Color("b68e45"))
	for id in rules.units:
		var root := Node3D.new()
		root.name = id
		add_child(root)
		visuals[id] = root
		var color := Color("e3a53a") if id == "jayze" else Color("29b9c6") if id == "kip" else Color("db6152") if id == "sprocket" else Color("8768ba")
		var body := MeshInstance3D.new()
		var mesh: Mesh
		if id == "jayze":
			mesh = CapsuleMesh.new()
			mesh.height = 1.25
			mesh.radius = 0.28
		else:
			mesh = BoxMesh.new()
			mesh.size = Vector3(0.85, 0.42, 0.55) if id == "kip" else Vector3(0.68, 0.62, 0.65)
		body.mesh = mesh
		body.position.y = 0.55 if id == "jayze" else 0.25
		body.material_override = _material(color)
		root.add_child(body)
		if id == "jayze":
			var head := MeshInstance3D.new()
			var head_mesh := SphereMesh.new()
			head_mesh.radius = 0.2
			head_mesh.height = 0.4
			head.mesh = head_mesh
			head.position = Vector3(0, 1.22, 0)
			head.material_override = _material(Color("f0c488"))
			root.add_child(head)
			var weapon := MeshInstance3D.new()
			var blade := BoxMesh.new()
			blade.size = Vector3(0.12, 0.65, 0.12)
			weapon.mesh = blade
			weapon.position = Vector3(0.43, 0.68, 0)
			weapon.material_override = _material(Color("d9e2e5"))
			root.add_child(weapon)
		elif id == "kip":
			for side in [-1.0, 1.0]:
				for axle in [-1.0, 1.0]:
					var wheel := MeshInstance3D.new()
					var wheel_mesh := CylinderMesh.new()
					wheel_mesh.top_radius = 0.16
					wheel_mesh.bottom_radius = 0.16
					wheel_mesh.height = 0.13
					wheel.mesh = wheel_mesh
					wheel.position = Vector3(side * 0.4, 0.17, axle * 0.22)
					wheel.rotation.z = PI / 2
					wheel.material_override = _material(Color("27313a"))
					root.add_child(wheel)
		var label := Label3D.new()
		label.text = rules.units[id].label
		label.position.y = 1.2
		root.add_child(label)
	_add_box("Desk leg landmark", Vector3(-3.2, 0.55, 2.6), Vector3(0.5, 1.5, 0.5), Color("756550"))

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := TextureRect.new()
	panel.texture = _hud_texture("res://assets/hud/hud_panel.png")
	if panel.texture:
		panel.position = Vector2(8, 6)
		panel.size = Vector2(500, 430)
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.stretch_mode = TextureRect.STRETCH_SCALE
		panel.modulate = Color(1, 1, 1, 0.9)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(panel)
	hud = VBoxContainer.new()
	hud.position = Vector2(18, 14)
	hud.add_theme_constant_override("separation", 6)
	layer.add_child(hud)
	for id in ["jayze", "kip"]:
		portraits[id] = _hud_texture("res://assets/portraits/%s.png" % id)
	var title := Label.new()
	title.text = "PLAYTIME PROTOCOL  /  BEAT SYSTEM PROTOTYPE"
	hud.add_child(title)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 8)
	hud.add_child(identity)
	portrait_view = TextureRect.new()
	portrait_view.custom_minimum_size = Vector2(96, 96)
	portrait_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	identity.add_child(portrait_view)
	info = Label.new()
	identity.add_child(info)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(status)
	var controls := HBoxContainer.new()
	hud.add_child(controls)
	_add_button(controls, "Jayze [1]", func(): selection = "jayze"; _refresh(), "jayze_select")
	_add_button(controls, "Kip [2]", func(): selection = "kip"; _refresh(), "kip_select")
	_add_button(controls, "Enter combat [C]", func(): rules.begin_combat(); _refresh(), "combat")
	_add_button(controls, "Guard", func(): _act("guard"); _refresh(), "guard")
	_add_button(controls, "Music box", func(): _act("interact"); _refresh(), "interact")
	_add_button(controls, "Co-op", func(): _target("cooperate"); _refresh(), "cooperate")
	var moves := Label.new()
	moves.text = "WASD move  •  Tab switches toy  •  In combat: move, then choose an action.  Targets are selected below."
	hud.add_child(moves)
	var targets := HBoxContainer.new()
	hud.add_child(targets)
	_add_button(targets, "Jayze melee", func(): _target("melee"))
	_add_button(targets, "Jayze technique", func(): _target("technique"))
	_add_button(targets, "Kip shot", func(): _target("shoot"))
	_add_button(targets, "Kip ram", func(): _target("ram"))
	_add_button(targets, "Target Sprocket", func(): _set_target("sprocket"))
	_add_button(targets, "Target Clanker", func(): _set_target("clanker"))

func _add_button(parent: Node, text: String, callback: Callable, icon_key := "") -> void:
	var button := Button.new()
	button.text = text
	if icon_key != "" and HUD_ICONS.has(icon_key):
		var icon := _hud_texture(HUD_ICONS[icon_key])
		if icon:
			button.icon = icon
			button.expand_icon = true
	button.pressed.connect(callback)
	parent.add_child(button)

var target_id := "sprocket"
func _set_target(id: String) -> void:
	target_id = id
	_refresh()

func _target(action: String) -> void:
	if action == "cooperate": rules.use_action(selection, action, target_id)
	else: rules.use_action(selection, action, target_id)
	_refresh()

func _act(action: String) -> void:
	rules.use_action(selection, action)

func _refresh() -> void:
	if not is_inside_tree(): return
	for id in visuals:
		var unit: Dictionary = rules.units[id]
		visuals[id].position = Vector3(unit.cell.x - 4.5, 0, unit.cell.y - 3.5)
		visuals[id].visible = unit.hp > 0
	info.text = "Round %d  |  Phase: %s  |  Activations: %d  |  Selected: %s  |  Target: %s" % [rules.round_number, rules.phase, rules.activations_left, selection.capitalize(), target_id.capitalize()]
	if portraits.has(selection):
		portrait_view.texture = portraits[selection]
	var health := "Jayze %d/%d    Kip %d/%d    Sprocket %d/%d    Clanker %d/%d" % [rules.units.jayze.hp, rules.units.jayze.max_hp, rules.units.kip.hp, rules.units.kip.max_hp, rules.units.sprocket.hp, rules.units.sprocket.max_hp, rules.units.clanker.hp, rules.units.clanker.max_hp]
	status.text = "%s\n%s\n%s" % [health, rules.event, "RESULT: " + rules.result.to_upper() + " (R retries)" if rules.result != "" else ""]

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material

func _add_box(label: String, location: Vector3, size: Vector3, color: Color) -> void:
	var box := MeshInstance3D.new()
	box.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.position = location
	box.material_override = _material(color)
	add_child(box)
