extends SceneTree

## Deterministic combat rules tests — combat slice v2.
## Original v1 assertion intents preserved (adapted to the 4-party/3-foe
## roster), plus new coverage: Rallo screech stun, Captain Crusher pound/mend/brace,
## Gimbal ranged pressure, staged enemy-phase plan/apply consistency,
## deferred enemy phase, and move cancellation.

const Rules = preload("res://scripts/battle_rules.gd")

func _initialize() -> void:
	# ---- movement, ranges, activations (v1 intents preserved) ----
	var rules = Rules.new()
	assert(rules.PARTY.size() == 4 and rules.FOES.size() == 3, "slice roster present")
	assert(not rules.move_unit("kip", Vector2i(9, 5)), "exploration movement is one tile only")
	rules.begin_combat()
	assert(rules.phase == "player" and rules.activations_left == 4, "one activation per living party member")
	assert(not rules.move_unit("jayze", Vector2i(3, 3)), "cover/obstacle cell blocks movement")
	assert(not rules.use_action("kip", "shoot", "sprocket"), "shot beyond range must fail")
	assert(rules.move_unit("kip", Vector2i(4, 4)), "Kip can move two cells with momentum")
	assert(not rules.move_unit("kip", Vector2i(5, 4)), "one move per activation")
	assert(rules.cancel_move("kip"), "pending move can be cancelled")
	assert(rules.units.kip.cell == Vector2i(2, 4) and rules.units.kip.momentum == 0, "cancel restores position and momentum")
	assert(rules.move_unit("kip", Vector2i(4, 4)), "Kip can move again after cancelling")
	assert(not rules.move_unit("kip", Vector2i(5, 4)), "one move per activation (still)")
	assert(rules.use_action("kip", "shoot", "clanker"), "Kip shot within range succeeds")
	assert(rules.units.clanker.hp == 9, "shot deals deterministic 2 damage")
	assert(rules.activations_left == 3, "one player activation is consumed")
	assert(not rules.use_action("kip", "guard"), "same character cannot activate twice in one round")

	# ---- co-op path through a full round (v1 intent preserved) ----
	var combo = Rules.new()
	combo.begin_combat()
	combo.units.sprocket.cell = Vector2i(4, 3)
	combo.units.sprocket.hp = 5
	assert(combo.use_action("jayze", "cooperate", "sprocket"), "co-op consumes both activations")
	assert(combo.units.sprocket.hp == 0 and combo.activations_left == 2, "co-op deals deterministic 5 damage")
	combo.units.clanker.cell = Vector2i(1, 4)
	combo.units.clanker.hp = 5
	combo.units.gimbal.cell = Vector2i(3, 3)
	combo.units.gimbal.hp = 5
	assert(combo.use_action("jayze", "melee", "clanker") == false, "activated actor cannot act again")
	assert(combo.use_action("rallo", "claw", "clanker"), "Rallo claw resolves")
	assert(combo.units.clanker.hp == 2, "claw deals deterministic 3 damage")
	assert(combo.use_action("crusher", "pound", "gimbal"), "Captain Crusher pound resolves at reach 1")
	assert(combo.units.gimbal.hp == 1, "pound deals 4 and staggers")
	assert(combo.round_number == 2 and combo.units.kip.hp == 6, "enemy phase ran after the fourth activation")
	assert(combo.units.gimbal.stunned == 0, "stagger is consumed by the imminent enemy phase")
	assert(combo.use_action("kip", "shoot", "gimbal"), "Kip finishes Gimbal next round")
	assert(combo.units.gimbal.hp == 0, "shot kills the staggered Gimbal")
	assert(combo.use_action("rallo", "claw", "clanker"), "Rallo finishes Clanker")
	assert(combo.result == "victory", "defeating the final enemy ends combat")

	# ---- guard vs all three foes (v1 intent, v2 numbers) ----
	var guard = Rules.new()
	guard.begin_combat()
	guard.units.sprocket.cell = Vector2i(3, 2)
	guard.units.clanker.cell = Vector2i(3, 4)
	guard.units.gimbal.cell = Vector2i(3, 3)
	guard.units.rallo.hp = 0
	guard.units.crusher.hp = 0
	assert(guard.use_action("jayze", "guard"), "Jayze can guard")
	assert(guard.use_action("kip", "guard"), "Kip can guard")
	guard.enemy_phase()
	assert(guard.units.jayze.hp == 10, "Jayze: Sprocket 3->1 and Gimbal 2->1 under guard")
	assert(guard.units.kip.hp == 8, "Kip: Clanker 4->2 under guard")

	# ---- party wipe is defeat ----
	var defeat = Rules.new()
	defeat.units.rallo.hp = 0
	defeat.units.crusher.hp = 0
	defeat.begin_combat()
	defeat.units.sprocket.cell = Vector2i(3, 2)
	defeat.units.clanker.cell = Vector2i(3, 4)
	defeat.units.gimbal.cell = Vector2i(3, 3)
	defeat.units.jayze.hp = 3
	defeat.units.kip.hp = 2
	assert(defeat.use_action("jayze", "melee", "sprocket"), "melee resolves")
	assert(defeat.use_action("kip", "shoot", "clanker"), "ranged shot resolves")
	assert(defeat.result == "defeat", "all party members reaching zero ends combat")

	# ---- Captain Crusher mend + cooldown; brace pair guard ----
	var support = Rules.new()
	support.begin_combat()
	support.units.jayze.hp = 6
	assert(support.use_action("crusher", "mend", "jayze"), "Captain Crusher mends Jayze")
	assert(support.units.jayze.hp == 9 and support.units.crusher.mend_cd == 3, "mend heals 3 and starts cooldown")
	support.units.rallo.cell = Vector2i(6, 3)
	assert(support.use_action("rallo", "claw", "sprocket"), "Rallo acts while mend cooldown ticks")
	assert(support.use_action("kip", "mend", "kip") == false, "only Captain Crusher can mend")
	var brace = Rules.new()
	brace.begin_combat()
	brace.units.jayze.hp = 0
	brace.units.kip.hp = 0
	brace.units.rallo.cell = Vector2i(2, 4)
	assert(brace.use_action("crusher", "brace"), "Captain Crusher braces")
	assert(brace.units.crusher.guard and brace.units.rallo.guard, "brace grants guard to Captain Crusher and nearest living ally")

	# ---- Rallo screech: stun skips exactly one enemy attack ----
	var screech = Rules.new()
	screech.begin_combat()
	screech.units.sprocket.cell = Vector2i(3, 2)
	screech.units.rallo.cell = Vector2i(3, 3)
	assert(screech.use_action("rallo", "screech", "sprocket"), "Rallo screeches adjacent foe")
	assert(screech.units.sprocket.stunned == 1, "screech stuns for one enemy attack")
	screech.use_action("jayze", "guard")
	screech.enemy_phase()
	assert(screech.units.jayze.hp == 12 and screech.units.sprocket.stunned == 0, "stunned foe skips its attack once, stun clears")

	# ---- Gimbal: ranged pressure at reach 3 ----
	var gimbal = Rules.new()
	gimbal.begin_combat()
	gimbal.units.gimbal.cell = Vector2i(5, 2)
	gimbal.units.rallo.hp = 0
	gimbal.units.kip.hp = 0
	gimbal.units.crusher.hp = 0
	gimbal.enemy_phase()
	assert(gimbal.units.jayze.hp == 10, "Gimbal deals deterministic 2 damage at range 3")

	# ---- deferred enemy phase keeps the presentation in control ----
	var deferred = Rules.new()
	deferred.begin_combat()
	deferred.defer_enemy_phase = true
	for i in 4:
		var actor := ""
		for pid in deferred.living_party_ids():
			if not deferred.activated.has(pid):
				actor = pid
				break
		assert(deferred.use_action(actor, "guard"), "activation %d resolves" % (i + 1))
	assert(deferred.awaiting_enemy and deferred.phase == "player", "enemy phase is staged, not auto-run")
	var plan: Array[Dictionary] = deferred.plan_enemy_phase()
	assert(plan.size() == 3, "plan covers every living foe")
	deferred.apply_enemy_phase(plan)
	assert(deferred.round_number == 2 and deferred.phase == "player" and not deferred.awaiting_enemy, "apply finishes the round")

	# ---- plan/apply hp consistency ----
	var staged = Rules.new()
	staged.begin_combat()
	var snapshot_hp := {}
	for id in staged.units:
		snapshot_hp[id] = staged.units[id].hp
	var staged_plan: Array[Dictionary] = staged.plan_enemy_phase()
	staged.enemy_phase()
	for id in staged.units:
		assert(staged.units[id].hp == snapshot_hp[id] - _expected_hp_loss(staged_plan, id), "plan/apply hp consistency for %s" % id)

	# ---- music box interact (v1 intent preserved) ----
	var box = Rules.new()
	box.begin_combat()
	box.units.rallo.cell = Vector2i(5, 4)
	box.units.sprocket.cell = Vector2i(6, 4)
	box.units.gimbal.cell = Vector2i(2, 2)
	assert(box.use_action("rallo", "interact"), "interact triggers near the music box")
	assert(box.units.sprocket.hp == 6 and box.units.gimbal.hp == 8, "music box burst hits foes within 2 cells only")

	# ---- reset restores the full opening state ----
	var re = Rules.new()
	re.begin_combat()
	re.use_action("jayze", "melee", "sprocket")
	re.reset()
	assert(re.units.jayze.hp == 12 and re.phase == "exploration" and re.round_number == 1, "reset restores opening state")

	print("PASS: roster, obstacles, movement, cancel, ranges, damage, activations, guard, co-op, screech, pound, mend, brace, gimbal, deferred phase, plan/apply, interact, victory, defeat, reset")
	quit(0)

func _expected_hp_loss(plan: Array[Dictionary], id: String) -> int:
	var loss := 0
	for step in plan:
		if step.kind == "attack" and step.target == id:
			loss += step.damage
	return loss
