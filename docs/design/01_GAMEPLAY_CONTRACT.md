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

## Approved combat-test presentation and input standard (2026-11-04)
The entire combat-test slice includes HUD, menu UI, controller support and **integrated music/SFX**, not isolated assets or gameplay-only tests. Default design target is controller-first, with the owner's available Xbox/XInput-compatible controller for testing on Linux; mouse+keyboard are secondary but fully capable. Steam Controller/Steam Input support is intended for release and must be architecturally possible, not fully tested now. Final Fantasy VII Rebirth is a reference for polished controller-native combat presentation and quickly accessible tactical command choices, **not an authorization to copy its ATB system, menus, effects or audio**. Preserve and validate existing deterministic battle rules before changing mechanics.

Read [the full combat slice spec](03_COMBAT_TEST_SLICE.md) and [gamepad/HUD/UI/audio contract](04_CONTROLLER_HUD_UI_AUDIO.md). This milestone is not complete until the player can enter, play, adjust sound, finish and restart an encounter using **only the controller**, with original music, interactive combat sound and UI feedback actually audible in-game. All graphical and audio identities may remain explicitly non-final; their implementation must be production-grade.
