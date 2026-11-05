class_name BattleRules
extends RefCounted

## Deterministic combat rules — Playtime Protocol combat test slice.
## v2: full slice roster (Jayze, Kip, Rallo, Jonnie vs Sprocket, Clanker, Gimbal).
## All original v1 mechanics preserved: guard -2, Kip momentum, co-op strike,
## music box interact, sign-step enemy advance, round telegraphs.
## New: Rallo screech (stun), Jonnie pound (stagger) / mend (heal, cooldown) /
## brace (pair guard), Gimbal ranged pressure, staged enemy-phase planning so
## the presentation layer can animate attacks without changing outcomes.
## This class stays rules-only: no nodes, no randomness, no audio/visual calls.

const PARTY := ["jayze", "kip", "rallo", "jonnie"]
const FOES := ["sprocket", "clanker", "gimbal"]
const BLOCKED_CELLS := [Vector2i(3, 3), Vector2i(5, 1)]
const GRID := Vector2i(10, 8)
const MUSIC_BOX := Vector2i(5, 4)
const GUARD_REDUCTION := 2

# Enemy stat table (deterministic, provisional values).
const FOE_STATS := {
	"sprocket": {"damage": 3, "reach": 1},
	"clanker": {"damage": 4, "reach": 1},
	"gimbal": {"damage": 2, "reach": 3},
}

var units := {}
var phase := "exploration"          # exploration | player | enemy | finished
var round_number := 1
var activations_left := 4
var activated: Array[String] = []
var moved_this_activation: Array[String] = []
var pending_move := {}              # {id, from_cell, from_momentum} for cancel_move
var event := "WASD to move; C enters combat."
var result := ""                    # "" | "victory" | "defeat"
var defer_enemy_phase := false      # presentation hook: director stages the enemy turn
var awaiting_enemy := false

func _init() -> void:
	reset()

func reset() -> void:
	units = {
		"jayze": _unit("Jayze", Vector2i(2, 2), 12, true),
		"kip": _unit("Kip", Vector2i(2, 4), 10, true),
		"rallo": _unit("Rallo", Vector2i(1, 3), 11, true),
		"jonnie": _unit("Jonnie", Vector2i(2, 3), 14, true),
		"sprocket": _unit("Sprocket", Vector2i(7, 3), 9, false),
		"clanker": _unit("Clanker", Vector2i(7, 5), 11, false),
		"gimbal": _unit("Gimbal", Vector2i(8, 4), 8, false),
	}
	phase = "exploration"
	round_number = 1
	activations_left = PARTY.size()
	moved_this_activation.clear()
	activated.clear()
	pending_move.clear()
	defer_enemy_phase = false
	awaiting_enemy = false
	result = ""
	event = "Move a toy, then open the command menu to begin combat."

func _unit(label: String, cell: Vector2i, hp: int, player: bool) -> Dictionary:
	return {"label": label, "cell": cell, "hp": hp, "max_hp": hp, "player": player,
		"guard": false, "momentum": 0, "stunned": 0, "mend_cd": 0}

# ------------------------------------------------------------------ flow

func begin_combat() -> void:
	if phase == "exploration":
		phase = "player"
		activations_left = _living_party()
		event = "Round %d intentions: %s. Choose your first activation." % [round_number, ", ".join(_telegraphs())]

func move_unit(id: String, cell: Vector2i) -> bool:
	if not units.has(id) or not _alive(id) or cell.x < 0 or cell.x >= GRID.x or cell.y < 0 or cell.y >= GRID.y or BLOCKED_CELLS.has(cell) or _occupied(cell, id):
		return false
	var distance := _dist(units[id].cell, cell)
	if phase == "exploration":
		if not units[id].player or distance != 1: return false
		pending_move = {"id": id, "from_cell": units[id].cell, "from_momentum": units[id].momentum}
		units[id].cell = cell
		return true
	if phase != "player" or not _can_act(id) or moved_this_activation.has(id) or distance < 1 or distance > _move_range(id): return false
	pending_move = {"id": id, "from_cell": units[id].cell, "from_momentum": units[id].momentum}
	units[id].cell = cell
	moved_this_activation.append(id)
	if id == "kip":
		units[id].momentum = mini(3, units[id].momentum + distance)
	event = "%s moved; choose an action." % units[id].label
	return true

func cancel_move(id: String) -> bool:
	## Undo the pending move of this activation (presentation convenience).
	## Invalid once an action has been committed this round for the mover.
	if pending_move.is_empty() or pending_move.id != id: return false
	if phase == "player" and not moved_this_activation.has(id): return false
	units[id].cell = pending_move.from_cell
	units[id].momentum = pending_move.from_momentum
	moved_this_activation.erase(id)
	pending_move.clear()
	event = "%s holds position." % units[id].label
	return true

func move_range(id: String) -> int:
	return _move_range(id) if units.has(id) else 0

func reachable_cells(id: String) -> Array[Vector2i]:
	## Deterministic reachable set for HUD highlight (distance-based, as in v1).
	var out: Array[Vector2i] = []
	if not units.has(id) or not _alive(id): return out
	var r := _move_range(id) if phase == "player" else 1
	for x in GRID.x:
		for y in GRID.y:
			var cell := Vector2i(x, y)
			var d := _dist(units[id].cell, cell)
			if d >= 1 and d <= r and not BLOCKED_CELLS.has(cell) and not _occupied(cell, id):
				out.append(cell)
	return out

func use_action(id: String, action: String, target: String = "") -> bool:
	if phase != "player" or not _can_act(id): return false
	match action:
		"guard":
			units[id].guard = true
			event = "%s guards (next hit reduced by %d)." % [units[id].label, GUARD_REDUCTION]
		"brace":
			if id != "jonnie": return false
			units[id].guard = true
			var buddy := _nearest_ally(id)
			if buddy != "" and _dist(units[id].cell, units[buddy].cell) <= 1:
				units[buddy].guard = true
				event = "%s braces %s: both guard the next hit." % [units[id].label, units[buddy].label]
			else:
				event = "%s braces (next hit reduced by %d)." % [units[id].label, GUARD_REDUCTION]
		"mend":
			if id != "jonnie" or units[id].mend_cd > 0: return false
			if not PARTY.has(target) or not _alive(target) or _dist(units[id].cell, units[target].cell) > 2: return false
			var healed := mini(3, units[target].max_hp - units[target].hp)
			units[target].hp += healed
			units[id].mend_cd = 3
			event = "%s mends %s for %d." % [units[id].label, units[target].label, healed]
		"cooperate":
			if not FOES.has(target) or not _alive(target) or _dist(units.jayze.cell, units.kip.cell) > 3 or (_dist(units.jayze.cell, units[target].cell) > 3 and _dist(units.kip.cell, units[target].cell) > 3) or not _can_act("jayze") or not _can_act("kip") or activations_left < 2: return false
			_damage(target, 5)
			activated.clear()
			activated.append("jayze")
			activated.append("kip")
			activations_left -= 2  # co-op spends both Jayze and Kip activations
			event = "Jayze and Kip coordinate for 5 damage."
			return _finish_activation("jayze")
		"interact":
			if _dist(units[id].cell, MUSIC_BOX) > 1: return false
			for foe in FOES:
				if _alive(foe) and _dist(units[foe].cell, MUSIC_BOX) <= 2: _damage(foe, 3)
			event = "The music box bursts; nearby enemies take 3 damage."
		"screech":
			if id != "rallo": return false
			if not FOES.has(target) or not _alive(target) or _dist(units[id].cell, units[target].cell) > 1: return false
			units[target].stunned = 1
			event = "%s screeches; %s is dazed and loses its next attack." % [units[id].label, units[target].label]
		_:
			if not FOES.has(target) or not _alive(target): return false
			var reach := 1
			var damage := 0
			var staggered := false
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
				"claw":
					if id != "rallo": return false
					damage = 3
				"pound":
					if id != "jonnie": return false
					damage = 4
					staggered = true
				_: return false
			if _dist(units[id].cell, units[target].cell) > reach: return false
			_damage(target, damage)
			if staggered and _alive(target): units[target].stunned = 1
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
		if defer_enemy_phase:
			awaiting_enemy = true
			phase = "player"
			event = "All toys have acted. The enemies move..."
		else:
			enemy_phase()
	return true

func actions_for(id: String) -> Array[String]:
	## Deterministic action list for the command menu.
	var out: Array[String] = []
	match id:
		"jayze": out = ["melee", "technique", "guard", "cooperate", "interact"]
		"kip": out = ["shoot", "ram", "guard", "cooperate", "interact"]
		"rallo": out = ["claw", "screech", "guard", "interact"]
		"jonnie": out = ["pound", "mend", "brace", "guard", "interact"]
	return out

func action_needs_target(action: String) -> bool:
	return action in ["melee", "technique", "shoot", "ram", "claw", "pound", "screech", "cooperate"]

func action_range(id: String, action: String) -> int:
	match action:
		"melee", "technique", "claw", "screech", "pound": return 1
		"shoot": return 4
		"ram": return 2
		"mend": return 2
		"brace": return 1
		"cooperate": return 3
	return 1

# ------------------------------------------------- enemy phase planning
# The enemy phase is computed as a deterministic step plan first
# (so the battle director can telegraph and animate each foe), then
# applied with apply_enemy_phase(). plan_enemy_phase() never mutates state.

func plan_enemy_phase() -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	# Track planned positions so sequential foe moves cannot collide (matches
	# v1's inline occupancy checks during the enemy phase).
	var planned := {}
	for foe in FOES:
		if _alive(foe): planned[foe] = units[foe].cell
	for foe in FOES:
		if not _alive(foe): continue
		if units[foe].stunned > 0:
			steps.append({"foe": foe, "kind": "stunned"})
			continue
		var target := _nearest_party(foe)
		if target == "": continue
		var stat: Dictionary = FOE_STATS[foe]
		if _dist(units[foe].cell, units[target].cell) <= stat.reach:
			var damage: int = stat.damage
			var blocked := false
			if units[target].guard:
				damage = maxi(1, damage - GUARD_REDUCTION)
				blocked = true
			var kills: bool = units[target].hp - damage <= 0
			steps.append({"foe": foe, "kind": "attack", "target": target, "damage": damage, "blocked": blocked, "kills": kills})
		else:
			var step := Vector2i(signi(units[target].cell.x - units[foe].cell.x), signi(units[target].cell.y - units[foe].cell.y))
			var dest: Vector2i = units[foe].cell + step
			var occupied: bool = BLOCKED_CELLS.has(dest) or dest.x < 0 or dest.x >= GRID.x or dest.y < 0 or dest.y >= GRID.y
			for other in planned:
				if other != foe and _alive(other) and planned[other] == dest:
					occupied = true
			if not occupied:
				planned[foe] = dest
				steps.append({"foe": foe, "kind": "advance", "target": target, "dest": dest})
			else:
				steps.append({"foe": foe, "kind": "hold", "target": target})
	return steps

func apply_enemy_phase(steps: Array[Dictionary]) -> void:
	## Applies a plan produced by plan_enemy_phase(). Caller must pass the plan
	## for the current state; validation is deterministic (see smoke tests).
	phase = "enemy"
	for step in steps:
		apply_enemy_step(step)
	_unpost_round()

func apply_enemy_step(step: Dictionary) -> void:
	## Mutates state for ONE planned step (used by the staged presentation).
	var foe: String = step.foe
	if not _alive(foe): return
	match step.kind:
		"stunned":
			units[foe].stunned = 0
		"attack":
			var target: String = step.target
			# Damage was computed by the plan against this same state
			# (guard reduction included); apply it verbatim.
			var damage: int = step.damage
			if units[target].guard: units[target].guard = false
			units[target].hp = maxi(0, units[target].hp - damage)
		"advance":
			units[foe].cell = step.dest

func finish_enemy_phase() -> void:
	## Round bookkeeping after every planned step has been applied.
	_unpost_round()

func enemy_phase() -> void:
	## Convenience one-shot path identical to plan+apply (used by tests).
	apply_enemy_phase(plan_enemy_phase())

func _unpost_round() -> void:
	if result == "":
		if not _any_party_alive():
			result = "defeat"
			phase = "finished"
		elif not _any_foe_alive():
			result = "victory"
			phase = "finished"
		else:
			round_number += 1
			phase = "player"
			activations_left = _living_party()
			activated.clear()
			moved_this_activation.clear()
			pending_move.clear()
			awaiting_enemy = false
			for id in PARTY:
				if units[id].mend_cd > 0: units[id].mend_cd -= 1
			event = "Round %d intentions: %s" % [round_number, ", ".join(_telegraphs())]

# ------------------------------------------------------------------ info

func telegraphs() -> Array[String]:
	return _telegraphs()

func foe_intents() -> Dictionary:
	## Read-only per-foe intent for HUD markers ("attack"/"advance"/"dazed").
	var out := {}
	for foe in FOES:
		if not _alive(foe):
			continue
		if units[foe].stunned > 0:
			out[foe] = "dazed"
			continue
		var target := _nearest_party(foe)
		if target == "":
			continue
		var stat: Dictionary = FOE_STATS[foe]
		out[foe] = "attack" if _dist(units[foe].cell, units[target].cell) <= stat.reach else "advance"
	return out

func living_party_ids() -> Array[String]:
	var out: Array[String] = []
	for id in PARTY:
		if _alive(id): out.append(id)
	return out

func living_foe_ids() -> Array[String]:
	var out: Array[String] = []
	for id in FOES:
		if _alive(id): out.append(id)
	return out

func _telegraphs() -> Array[String]:
	var intentions: Array[String] = []
	for foe in FOES:
		if not _alive(foe):
			continue
		if units[foe].stunned > 0:
			intentions.append("%s: dazed" % units[foe].label)
			continue
		var target := _nearest_party(foe)
		if target == "": continue
		var stat: Dictionary = FOE_STATS[foe]
		var intention := "attack" if _dist(units[foe].cell, units[target].cell) <= stat.reach else "advance"
		intentions.append("%s → %s: %s" % [units[foe].label, units[target].label, intention])
	return intentions

func _move_range(id: String) -> int:
	return 2 if id == "kip" or id == "rallo" else 1

func _can_act(id: String) -> bool:
	return PARTY.has(id) and _alive(id) and not activated.has(id) and activations_left > 0

func _alive(id: String) -> bool:
	return units.has(id) and units[id].hp > 0

func _living_party() -> int:
	var n := 0
	for id in PARTY:
		if _alive(id): n += 1
	return n

func _any_party_alive() -> bool:
	for id in PARTY:
		if _alive(id): return true
	return false

func _any_foe_alive() -> bool:
	for id in FOES:
		if _alive(id): return true
	return false

func _occupied(cell: Vector2i, except_id: String) -> bool:
	if BLOCKED_CELLS.has(cell):
		return true
	for id in units:
		if id != except_id and _alive(id) and units[id].cell == cell: return true
	return false

func _nearest_party(foe: String) -> String:
	## Deterministic nearest living party target, tie-break by PARTY order.
	var best := ""
	var best_d := 999999
	for id in PARTY:
		if not _alive(id): continue
		var d := _dist(units[foe].cell, units[id].cell)
		if d < best_d:
			best_d = d
			best = id
	return best

func _nearest_ally(id: String) -> String:
	var best := ""
	var best_d := 999999
	for other in PARTY:
		if other == id or not _alive(other): continue
		var d := _dist(units[id].cell, units[other].cell)
		if d < best_d:
			best_d = d
			best = other
	return best

func _dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _damage(target: String, amount: int) -> void:
	units[target].hp = maxi(0, units[target].hp - amount)
	if result == "" and not _any_foe_alive():
		result = "victory"
		phase = "finished"
