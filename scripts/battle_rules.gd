class_name BattleRules
extends RefCounted

const PARTY := ["jayze", "kip"]
const FOES := ["sprocket", "clanker"]
const BLOCKED_CELLS := [Vector2i(3, 3), Vector2i(5, 1)]
var units := {}
var phase := "exploration"
var round_number := 1
var activations_left := 2
var activated: Array[String] = []
var moved_this_activation: Array[String] = []
var event := "WASD to move; C enters combat."
var result := ""

func _init() -> void:
	reset()

func reset() -> void:
	units = {"jayze": _unit("Jayze", Vector2i(2, 3), 12, true), "kip": _unit("Kip", Vector2i(2, 5), 10, true), "sprocket": _unit("Sprocket", Vector2i(7, 3), 9, false), "clanker": _unit("Clanker", Vector2i(7, 5), 11, false)}
	phase = "exploration"
	round_number = 1
	activations_left = 2
	moved_this_activation.clear()
	activated.clear()
	result = ""
	event = "WASD to move; C enters combat."

func _unit(label: String, cell: Vector2i, hp: int, player: bool) -> Dictionary:
	return {"label": label, "cell": cell, "hp": hp, "max_hp": hp, "player": player, "guard": false, "momentum": 0}

func begin_combat() -> void:
	if phase == "exploration":
		phase = "player"
		event = "Round 1 intentions: %s. Choose your first activation." % _telegraphs()

func move_unit(id: String, cell: Vector2i) -> bool:
	if not units.has(id) or not _alive(id) or cell.x < 0 or cell.x >= 10 or cell.y < 0 or cell.y >= 8 or BLOCKED_CELLS.has(cell) or _occupied(cell, id):
		return false
	var distance := _dist(units[id].cell, cell)
	if phase == "exploration":
		if not units[id].player or distance != 1: return false
		units[id].cell = cell
		return true
	if phase != "player" or not _can_act(id) or moved_this_activation.has(id) or distance < 1 or distance > (2 if id == "kip" else 1): return false
	units[id].cell = cell
	moved_this_activation.append(id)
	if id == "kip": units[id].momentum = mini(3, units[id].momentum + distance)
	event = "%s moved; choose an action." % units[id].label
	return true

func use_action(id: String, action: String, target: String = "") -> bool:
	if phase != "player" or not _can_act(id): return false
	if action == "guard":
		units[id].guard = true
		event = "%s guards (next hit reduced by 2)." % units[id].label
	elif action == "cooperate":
		if not FOES.has(target) or not _alive(target) or _dist(units.jayze.cell, units.kip.cell) > 3 or (_dist(units.jayze.cell, units[target].cell) > 3 and _dist(units.kip.cell, units[target].cell) > 3) or not _can_act("jayze") or not _can_act("kip") or activations_left < 2: return false
		_damage(target, 5)
		activated.clear()
		activated.append("jayze")
		activated.append("kip")
		activations_left = 0
		event = "Jayze and Kip coordinate for 5 damage."
		return _finish_activation("jayze")
	elif action == "interact":
		if _dist(units[id].cell, Vector2i(5, 4)) > 1: return false
		for foe in FOES:
			if _alive(foe) and _dist(units[foe].cell, Vector2i(5, 4)) <= 2: _damage(foe, 3)
		event = "The music box bursts; nearby enemies take 3 damage."
	else:
		if not FOES.has(target) or not _alive(target): return false
		var reach := 1
		var damage := 0
		match action:
			"melee":
				if id != "jayze": return false
				damage = 3
			"technique":
				if id != "jayze": return false
				damage = 5
			"shoot":
				if id != "kip": return false
				reach = 4
				damage = 2
			"ram":
				if id != "kip" or units[id].momentum < 2: return false
				reach = 2
				damage = 5
				units[id].momentum = 0
			_: return false
		if _dist(units[id].cell, units[target].cell) > reach: return false
		_damage(target, damage)
		event = "%s used %s for %d damage." % [units[id].label, action, damage]
	return _finish_activation(id)

func _finish_activation(actor: String) -> bool:
	if result != "":
		moved_this_activation.erase(actor)
		return true
	if not activated.has(actor):
		activated.append(actor)
		activations_left -= 1
	if activations_left <= 0:
		_enemy_phase()
	return true

func _enemy_phase() -> void:
	phase = "enemy"
	for foe in FOES:
		if not _alive(foe): continue
		var target := "jayze" if _alive("jayze") and (not _alive("kip") or _dist(units[foe].cell, units.jayze.cell) <= _dist(units[foe].cell, units.kip.cell)) else "kip"
		if _dist(units[foe].cell, units[target].cell) <= 1:
			var damage := 3
			if units[target].guard:
				damage = 1
				units[target].guard = false
			units[target].hp = maxi(0, units[target].hp - damage)
		else:
			var step := Vector2i(signi(units[target].cell.x - units[foe].cell.x), signi(units[target].cell.y - units[foe].cell.y))
			if not _occupied(units[foe].cell + step, foe): units[foe].cell += step
	if not _alive("jayze") and not _alive("kip"):
		result = "defeat"
		phase = "finished"
	elif not _alive("sprocket") and not _alive("clanker"):
		result = "victory"
		phase = "finished"
	else:
		round_number += 1
		phase = "player"
		activations_left = 2
		activated.clear()
		moved_this_activation.clear()
		event = "Round %d intentions: %s" % [round_number, _telegraphs()]

func _can_act(id: String) -> bool:
	return PARTY.has(id) and _alive(id) and not activated.has(id) and activations_left > 0

func _alive(id: String) -> bool:
	return units.has(id) and units[id].hp > 0

func _occupied(cell: Vector2i, except_id: String) -> bool:
	if BLOCKED_CELLS.has(cell):
		return true
	for id in units:
		if id != except_id and _alive(id) and units[id].cell == cell: return true
	return false

func _telegraphs() -> String:
	var intentions: Array[String] = []
	for foe in FOES:
		if not _alive(foe):
			continue
		var target := "jayze" if _alive("jayze") and (not _alive("kip") or _dist(units[foe].cell, units.jayze.cell) <= _dist(units[foe].cell, units.kip.cell)) else "kip"
		var intention := "attack" if _dist(units[foe].cell, units[target].cell) <= 1 else "advance"
		intentions.append("%s → %s: %s" % [units[foe].label, units[target].label, intention])
	return ", ".join(intentions) if not intentions.is_empty() else "no enemies"

func _dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _damage(target: String, amount: int) -> void:
	units[target].hp = maxi(0, units[target].hp - amount)
	if not _alive("sprocket") and not _alive("clanker"):
		result = "victory"
		phase = "finished"
