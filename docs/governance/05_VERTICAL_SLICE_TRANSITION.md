# Non-destructive adoption of new governance for the current combat slice

**Purpose:** Let the existing Goose/OMP combat test evolve into compliance *without resetting, renaming or recreating working sources*.

**At next safe checkpoint, not mid-generation:**
1. Inventory the actual local folder `/mnt/workdrive/playtime-protocol-godot-comfy-blender`, Git root/remote/branch, current Godot scene and input/audio/asset tests. Compare with PPIO without assuming they share history.
2. Preserve a recoverable baseline. Record hashes/paths of functioning scenes, rigs, model sources, animations, workflows, UI, sounds, tools and manifests. Do not alter OMP's original forensic logs.
3. Create a small **conformance matrix** with columns: requirement/source, current file/feature, VERIFIED / NEEDS ADAPTATION / NOT TESTED / OWNER DECISION, proposed smallest change, test/evidence, rollback.
4. Apply **immediate mandatory rules** during all ongoing operations: no destructive file/git actions, no unsafe GPU work, no privacy/rights violations, no silent canon mutation, no false PASS.
5. Adapt **incrementally**, not all at once: map existing player and enemy IDs, add missing input/rig/animation/audio event contracts, migrate data only when Godot imports and scene references remain valid, and run narrow regression tests. Use lightweight metadata adapters rather than renaming every artifact.
6. Do not hold the combat slice hostage to unapproved total-game pacing or section-size numbers. Its compact test arena and encounter are explicitly noncanonical; they can be tested/tuned empirically for feel without imposing campaign quotas.
7. Run the **existing acceptance** for combat loop, 4 party rigs and 2–3 enemy rigs, Xbox-style controller navigation, HUD/UI, audio, VFX, editor import and restart. Mark physical-controller and listening checks NOT TESTED until actually performed.
8. Log conformance and adaptations in proper provenance. Escalate true canon/design approvals only, not doc-placement preferences.

**Never grandfather a destructive action, machine crash risk, unlicensed material or hidden failure.** “Grandfathered” protects legitimate progress from rework, not quality gates.

**Separate phase:** Goose's extension/recipe/skills specialization and resilience implementation runs only after slice completion and a separate owner prompt. This document does not trigger it.
