extends SceneTree

const Rules = preload("res://scripts/battle_rules.gd")

func _initialize() -> void:
	var rules = Rules.new()
	assert(not rules.move_unit("kip", Vector2i(9, 5)), "exploration movement is one tile only")
	rules.begin_combat()
	assert(not rules.move_unit("jayze", Vector2i(3, 3)), "cover/obstacle cell blocks movement")
	assert(not rules.use_action("kip", "shoot", "sprocket"), "shot beyond range must fail")
	assert(rules.move_unit("kip", Vector2i(4, 5)), "Kip can move two cells with momentum")
	assert(not rules.move_unit("kip", Vector2i(5, 5)), "one move per activation")
	assert(rules.use_action("kip", "shoot", "clanker"), "Kip shot within range succeeds")
	assert(rules.units.clanker.hp == 9, "shot deals deterministic 2 damage")
	assert(rules.activations_left == 1, "one player activation is consumed")
	assert(not rules.use_action("kip", "guard"), "same character cannot activate twice in one round")
	var combo = Rules.new()
	combo.begin_combat()
	combo.units.sprocket.cell = Vector2i(4, 3)
	combo.units.sprocket.hp = 5
	assert(combo.use_action("jayze", "cooperate", "sprocket"), "co-op consumes both activations")
	assert(combo.units.sprocket.hp == 0, "co-op deals deterministic 5 damage")
	combo.units.clanker.cell = Vector2i(3, 5)
	combo.units.clanker.hp = 5
	assert(combo.use_action("jayze", "cooperate", "clanker"), "co-op is available next round")
	assert(combo.result == "victory", "defeating the final enemy ends combat")
	var guard = Rules.new()
	guard.begin_combat()
	guard.units.sprocket.cell = Vector2i(3, 3)
	guard.units.clanker.cell = Vector2i(3, 5)
	assert(guard.use_action("jayze", "guard"), "Jayze can guard")
	assert(guard.use_action("kip", "guard"), "Kip can guard")
	assert(guard.units.jayze.hp == 11 and guard.units.kip.hp == 9, "guard reduces each enemy hit by two")
	var defeat = Rules.new()
	defeat.begin_combat()
	defeat.units.sprocket.cell = Vector2i(3, 3)
	defeat.units.clanker.cell = Vector2i(3, 5)
	defeat.units.jayze.hp = 3
	defeat.units.kip.hp = 2
	assert(defeat.use_action("jayze", "melee", "sprocket"), "melee resolves")
	assert(defeat.use_action("kip", "shoot", "clanker"), "ranged shot resolves")
	assert(defeat.result == "defeat", "both party members reaching zero ends combat")
	print("PASS: obstacles, movement, ranges, damage, activations, guard, co-op, victory, defeat")
	quit(0)
