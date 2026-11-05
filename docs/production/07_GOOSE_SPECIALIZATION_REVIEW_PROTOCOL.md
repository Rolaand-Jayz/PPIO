# Goose specialization — fast, practical decision model

**STATUS:** Plan only. Goose does not begin until the combat vertical slice is finished **and the owner sends the separate start prompt**.

**Local workspace:** `/mnt/workdrive/playtime-protocol-godot-comfy-blender` (verify Git root/remotes).  
**Canonical repo:** `https://github.com/Rolaand-Jayz/PPIO.git`, branch `main`.

## Who does what
**Owner + ChatGPT:** Reason together about major architecture, creative direction, safety trade-offs and the final preferred setup. ChatGPT advises; the owner decides. We do **not** have to approve every small technical choice or watch each test.

**Goose:** Builds and tests. Has room to choose tools, implement project-local skills/recipes, correct bugs, run small benchmarks, and keep useful improvements **without waiting for a committee meeting**. Bring us only consequential decisions: global/security/cost changes, major architecture swaps, unresolved canon, unsafe hardware work or trade-offs that meaningfully change the project.

Review reports and GitHub files when the owner brings them to ChatGPT. There is no automatic live ChatGPT-to-Goose channel.

## Guiding strategy
**Speed through small working changes, not paperwork.** Start with the smallest integrated Goose setup. Add a skill, extension, recipe or hook only when it solves a concrete friction point. Reuse existing Godot Editor/CLI, Blender Python, guarded ComfyUI scripts, audio/Git/QA tools. Avoid building a complex agent organization before the simple path is working.

**Model default:** GLM-5.3 Flash for the vast majority of coding, file edits, project scripts, asset metadata, integration and ordinary debugging. Selectively use GLM-5.3 for hard architecture, safety/complex failures, gameplay/canon conflicts or originality reviews. Verify actual provider IDs and cost before routing. No double-model review on every edit. GLM-5.5 is only a future candidate; test it when it actually becomes available, never switch blindly.

## Build-and-check loop
1. **Inspect:** In the installed Goose version, see which relevant extensions/skills/recipes/hooks already exist and what works with this project. Identify the one or two biggest bottlenecks; no inventory project for its own sake.
2. **Make one reversible improvement:** Project-scoped configuration, a small recipe, a skill or a tool adapter; preserve the working baseline.
3. **Prove it on a real small task:** Use an appropriate fixture from the project and a clear pass/fail condition. Collect just enough evidence to show it works; note latency/resource usage if meaningful.
4. **Keep or revert:** If it saves repeated effort or improves reliability without new risks, keep it. If it adds overhead, confuses tools, breaks editor integration or increases crash risk, remove the change cleanly.
5. **Move to the next useful improvement:** No giant test campaign before delivering value.

## Small practical test set
Choose tests that match what changed, **not all tests for every extension**:

| Improvement | Quick test |
| --- | --- |
| Godot Editor / code adapter | Inspect a real scene and run a safe isolated edit + headless import without touching the user's open unsaved scene |
| Blender rig/animation bridge | Export a small rig/animated fixture to GLB and verify its Godot import and playback |
| ComfyUI API integration | Health/schema/provenance/cancel-path check; no heavy generation while active |
| Controller/UI/audio workflow | Narrow InputMap, menu focus and audio event test, with real controller/listening marked untested unless performed |
| Canon/continuity skill | Catch a deliberately invalid CJ POV or house-geometry reference |
| Originality/quality checker | Reject a recolor-only or copy-paste enemy while explaining the structural similarity |
| Checkpoint/recovery | Interrupt a harmless fixture and resume without redoing completed outputs |
| Resource guard | Simulate ACTIVE/pressure conditions; refuse unsafe heavy tasks without actual GPU stress |

One successful targeted test plus sensible failure handling usually suffices for a small improvement. Require more only if the risk warrants it. Don't manufacture an aggregate scorecard.

## Three nonnegotiable resilience laws
**R1 — Preserve work and follow repo rules.** No destructive Git/filesystem shortcuts, leaked secrets, fake canon approval or loss of functioning assets.
**R2 — Don't crash the system or get in the user's way.** Keep user activity/memory pressure ahead of agent throughput; one heavy GPU job at a time, gated by existing controls.
**R3 — Get it done.** If blocked, use existing tools, narrower scope, Blender/Godot/procedural methods, or a resumable checkpoint; no endless identical retries or unauthorized workarounds.

**Quality is not expendable for speed.** Keep the distinctive design and production quality gates: no generic/samey party members, enemies, animation, HUD, audio or encounters. Prove important differences through actual mechanisms, silhouettes, movement, behavior and sounds. Only owner approves artistic direction, but Goose can build and refine candidates autonomously.

## What to send back after the optimization
Keep it short: **what you changed, why it helped, a few test outcomes, what you rejected, what still needs owner input, and how to undo the changes.** Provide actual working commands and paths. We review the overall setup together and adjust the handful of choices that matter.

Don't start another campaign-wide design task or lock game length/encounter frequency without approval. Do not begin specialization until the owner prompts you after combat completion.
