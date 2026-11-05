# Combat test slice — production-quality execution with non-final assets

**Owner direction (2026-11-04):** Build the complete playable combat test, not just art samples. The visual assets are **not final character or world designs**, but their implementation, integration, readability and presentation must meet a production-quality standard. **Controller-first HUD, complete UI, functioning sound effects and original combat music are required**, not later optional polish.

**Execution harness:** Goose Desktop; **canonical repository:** `https://github.com/Rolaand-Jayz/PPIO.git` branch `main`. Read `.goosehints`, `AGENTS.md`, existing local prototype and [resource safety](../production/02_RESOURCE_SAFETY.md) before modifying code or launching models.

## Distinguish three quality standards
- **Production-grade engineering:** maintainable, deterministic where required, clean scene boundaries, replaceable content, tested gamepad controls, tested audio routing/mixing, preserved assets and provenance.
- **Production-grade presentation target:** coherent art direction, responsive UI, action readability, impactful VFX/SFX, consistent toy-scale environment; no unstyled debug-only player experience.
- **Not production-final canon:** meshes, textures, character costumes, environments, audio motifs and skill effects are provisional and replaceable. Mark them `proxy`, `test_slice` or `concept_only`; keep unresolved lore and final visual design uncommitted.

## Complete slice scope
1. One compact, cohesive toy-scale 3D arena. Must support battle framing, target readability and tactical space; the chosen house room is noncanonical until approved.
2. Four visually distinct, well-articulated **proxy** characters: Jayze, Kip (actual wheeled toy car, no humanoid rig), Rallo (small gargoyle low-hover), Captain Crusher/Jonnie (heavy exoskeleton).
3. Two or three neutral **noncanonical** enemy prototypes, mechanically distinct (close, ranged, pressure/support) without defining the Unknown's appearance.
4. Existing Godot combat rules remain the starting point. Preserve implemented deterministic state/turn/ability logic until inspected, tested and explicitly reconciled with the intended controller-driven presentation. Don't silently replace battle mechanics with Final Fantasy's ATB.
5. A complete start → encounter → understandable input/action selection → damage/defense/status feedback → victory/defeat → replay/restart loop. Player can accomplish **every action with a gamepad alone**.
6. Controller-first HUD/UI including command menus, party/status displays, selection and targeting, on-screen prompts, focus movement, pause/settings, result screen and restart. Mouse/keyboard have full feature parity but are secondary for UX decisions.
7. Original/rights-cleared music, functional SFX, UI audio, impact and ability sounds, toy/material cues, environmental ambience and functional mixing controls. Sound must be heard correctly at runtime, not merely exist as files.
8. **Full character-specific rigging and actual in-engine animations** for all party and enemy proxies: articulated toy skeletons/mechanical pivots, weights, sockets, editable Blender rigs, named clips, Godot animation states and event synchronization. Engine-side gameplay remains authoritative for timing/damage/targeting. See [mandatory rig/animation contract](05_RIGGING_AND_ANIMATION.md).
9. Validated, reversible asset pipeline and build/run instructions; tests, captures, manifest, licenses, provenance and known non-final decisions.

## Originality and finish standard
**Mandatory:** follow [distinctive-design and quality gates](07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md) and [current-slice adaptation](../governance/05_VERTICAL_SLICE_TRANSITION.md). Each major character/enemy/arena/UI/audio family must communicate an internally distinct toy-world identity in silhouette, physical construction, motion, combat function, and sound. Do not use generic AI defaults, 3 recolored enemies, copy-paste animations or generic fantasy/UI motifs. Produce a bounded identity/contrast comparison and owner review for **ACCEPTED FOR SLICE**, not final art approval. Preserve previous good artifacts and remedy deficiencies incrementally; reducing scope is preferable to passing low-quality assets, but the four-party / 2–3 enemy acceptance minimum is not waived.

## Scope protections
- No full campaign, overworld, story cutscene production, finalized Unknown designs, or final character likeness.
- Don't reinvent OMP's existing Godot scene, ComfyUI wrappers, graph templates, Blender exporters, safety tools or asset registry. First map/check/reuse what exists.
- If ComfyUI cannot safely complete generation, build convincing **Blender/Godot-authored** proxies and sound using lightweight, deterministic tools. Do not block the whole slice on the generative pipeline.
- No copyrighted FF7 music, character designs, fonts, UI assets, sounds or recorded clips. Final Fantasy VII Rebirth is **interaction/presentation reference only**.
- No unbounded GPU retries; preserve the approved launch and per-job safety guard. Stop on sustained memory pressure or driver faults.

## Implementation order
**P0 — Inventory and vertical contract:** Verify actual PPIO checkout vs existing local working tree; snapshot existing state; inspect combat prototype and input/audio/asset plumbing. Map existing functionality against this brief and list the minimum missing pieces. No GPU job.

**P1 — Controller-first playable graybox:** Finish battle flow and a usable XInput-compatible controller mapping, UI focus, menu and combat feedback using authored geometry and lightweight temporary sounds. Test a complete controller-only battle now; don't defer input until after generated art.

**P2 — Production-quality, fully rigged/animated proxies:** Integrate character-specific skeletons/mechanisms and editable source, four party and 2–3 enemy meshes, runtime clips and procedural motion connected to real battle state, one arena, readable effects and coherent HUD style. Use existing ComfyUI only if safe; otherwise preserve the animation/asset interfaces and proceed via Blender/Godot.

**P3 — Audio integration:** Build and mix original battle loop + entry/result stingers; cover action selection, attacks, impacts, blocks/evades, enemy feedback, victory/defeat, toy-material ambience; install per-bus controls, cue events and audio QC. No reliance on pending external paid generators.

**P4 — QA and delivery:** Play full controller-driven encounter; keyboard/mouse parity; validate 16:9 and 21:9 screen composition where available; audio cue alignment and volume/looping; input-focus, unplug/reconnect and pause tests; relevant headless state tests; package reversible sources and a concise evidence report.

## Acceptance — mandatory
- Godot project opens/runs from the PPIO checkout or a documented linked local tree with traceable source.
- The whole encounter, HUD, command selections, pause/settings, victory/defeat and restart are navigable **without a mouse or keyboard** on the currently available Xbox/XInput-compatible controller.
- Keyboard/mouse can perform all essential tasks; both work through Godot InputMap actions, not divergent gameplay logic.
- Every visible button prompt matches the current input profile; UI focus cannot silently disappear; no mouse-only tooltips or buttons.
- All four party models and 2–3 enemies are coherent **rigged and animated** proxies, with validated Blender/GLB source, joints/weights/sockets, playable Godot transitions, synchronized telegraphs/impact/VFX/SFX and no T-pose/rest-pose glitches.
- Sound exists **in-engine**: original battle loop/music transitions, combat impact/ability effects, navigational confirmation/cancel cues, result cues, reasonable ambience, pause behavior and adjustable bus mix. Silent audio must be a deliberate user setting, not missing implementation.
- Visual and audio assets have source/provenance, editable/reimportable formats, appropriate commercial-license tracking and `proxy` status.
- Repeated encounter play (without GPU model generation) exhibits no broken state/focus, major runtime errors or resource creep in the game itself.
- A handoff report distinguishes **verified** gameplay tests from **unverified** ComfyUI or controller-specific compatibility. No final art/canon decision is implied.

See [controller, HUD, UI and audio specification](04_CONTROLLER_HUD_UI_AUDIO.md).

Rigging and animation acceptance is mandatory: [detailed specification](05_RIGGING_AND_ANIMATION.md).
