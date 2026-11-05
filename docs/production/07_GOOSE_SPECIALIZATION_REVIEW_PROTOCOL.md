# Goose specialization — fast, practical decision model

**STATUS:** Plan only. Goose does not begin until the combat vertical slice is finished **and the owner sends the separate start prompt**.

**Local workspace:** `/mnt/workdrive/playtime-protocol-godot-comfy-blender` (verify Git root/remotes).  
**Canonical repo:** `https://github.com/Rolaand-Jayz/PPIO.git`, branch `main`.

## Who does what
**Owner + ChatGPT:** Reason together about major architecture, creative direction, safety trade-offs and the final preferred setup. ChatGPT advises; the owner decides. We do **not** have to approve every small technical choice or watch each test.

**Goose:** Builds and tests. Has room to choose tools, implement project-local skills/recipes, correct bugs, validate improvements through the actual game tasks they enable, and keep useful improvements **without waiting for a committee meeting**. Bring us only consequential decisions: global/security/cost changes, major architecture swaps, unresolved canon, unsafe hardware work or trade-offs that meaningfully change the project.

Review reports and GitHub files when the owner brings them to ChatGPT. There is no automatic live ChatGPT-to-Goose channel.

## Guiding strategy
**Speed through small working changes, not paperwork.** Start with the smallest integrated Goose setup. Add a skill, extension, recipe or hook only when it solves a concrete friction point. Reuse existing Godot Editor/CLI, Blender Python, guarded ComfyUI scripts, audio/Git/QA tools. Avoid building a complex agent organization before the simple path is working.

**Model default:** GLM-5.3 Flash for the vast majority of coding, file edits, project scripts, asset metadata, integration and ordinary debugging. Selectively use GLM-5.3 for hard architecture, safety/complex failures, gameplay/canon conflicts or originality reviews. Verify actual provider IDs and cost before routing. No double-model review on every edit. GLM-5.5 is only a future candidate; test it when it actually becomes available, never switch blindly.

## Test in the work, not beside the work
There is **no separate benchmark project, mandatory test matrix, or artificial trial campaign**. Optimization happens when Goose is building a real Playtime Protocol feature:

1. Notice an actual point of friction while editing a Godot scene, exporting a Blender rig, invoking the existing ComfyUI pipeline, managing original sound, or checking canon.
2. Make a single small reversible improvement to the relevant skill, recipe, adapter, extension or model-routing decision.
3. Use the improvement **on that same real feature**. Verify the actual feature's usual acceptance: Godot import, runtime state, animation and socket playback, audio event, controller behavior, continuity, or other relevant outcome.
4. If it makes the work more reliable or faster without new costs or resource risk, keep it. If not, revert and use the proven method.
5. Record a short note on what changed and whether it worked. Do not stop development to assemble metrics or a formal scorecard.

Necessary precautions are **not optional**: before a risky new adapter, ensure reversible files and safe process boundaries; before GPU work, preserve the resource/idle checks; before an unsafe/global/paid operation, obtain authorization. These are safeguards, not a detached test program.

Example: while making Kip's combat rig, Goose can improve the Blender → GLB → Godot recipe and confirm it from Kip's real imported animation. No extra dummy rig is required. Likewise, when a genuine task needs an audio cue, confirm it actually plays on the game event; when ComfyUI is used, validate that specific authorized asset job and memory recovery rather than running a gratuitous model benchmark.

A capability not yet invoked in real work remains **NOT TESTED**, not a defect and not a license to manufacture work. The owner and ChatGPT review consequential decisions and actual outputs as they arise, not routine improvements.

## Three nonnegotiable resilience laws
**R1 — Preserve work and follow repo rules.** No destructive Git/filesystem shortcuts, leaked secrets, fake canon approval or loss of functioning assets.
**R2 — Don't crash the system or get in the user's way.** Keep user activity/memory pressure ahead of agent throughput; one heavy GPU job at a time, gated by existing controls.
**R3 — Get it done.** If blocked, use existing tools, narrower scope, Blender/Godot/procedural methods, or a resumable checkpoint; no endless identical retries or unauthorized workarounds.

**Quality is not expendable for speed.** Keep the distinctive design and production quality gates: no generic/samey party members, enemies, animation, HUD, audio or encounters. Prove important differences through actual mechanisms, silhouettes, movement, behavior and sounds. Only owner approves artistic direction, but Goose can build and refine candidates autonomously.

## What to send back after the optimization
Keep it short: **what you changed, why it helped, real work outcomes, what you rejected, what still needs owner input, and how to undo the changes.** Provide actual working commands and paths. We review the overall setup together and adjust the handful of choices that matter.

Don't start another campaign-wide design task or lock game length/encounter frequency without approval. Do not begin specialization until the owner prompts you after combat completion.
