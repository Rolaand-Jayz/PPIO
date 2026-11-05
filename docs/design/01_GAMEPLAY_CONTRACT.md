# Gameplay and implementation contract

**Direction:** story-driven JRPG, not a 1942 top-down vertically scrolling SHMUP. Adventure through toy-scale 3D household spaces and meaningful RPG combat/party progression. Formal combat mechanics remain under development; preserve existing runnable prototype behavior until inspected and intentionally revised.

## System and design priorities
- Four mechanically distinct heroes: Jayze (melee weapon/offense), Kip (car movement, physical tactics, ranged device), Rallo (adaptable/hover), Jonnie (heavy defensive/assist support).
- Up to four characters exist in the mature story party; do not assume all four are playable in the opening scene.
- Encounter design should force meaningful positional, timing, partnership and ability decisions. Do not invent final stat values or complete skill trees without approval.
- Explore and battle using actual toy-scale readability; maintain legible telegraphs, character silhouettes, collision and environmental traversal.
- Gameplay must tell the same story as dialogue: trust, separation, rescue and return payoffs arise from genuine player actions.
- Existing local Godot 4.7.2 deterministic battle rules and smoke tests are **reported implemented** by Goose; import them, run them, and preserve working behavior.

## Engine interface
Godot 4.7.2 with GDScript initially. Asset-generation tools deliver replaceable visuals; Godot-side scenes own gameplay logic, collision, interactables, damage, camera, hit windows, accessibility and input. The current combat prototype's exact architecture is not claimed until source inspection.

## Acceptance
Prototype success is demonstrated via reproducible tests and playable movement/battle, not merely screenshots or generated meshes. Any mechanic asserted complete must include reproducible evidence, limitations and a versioned decision.
