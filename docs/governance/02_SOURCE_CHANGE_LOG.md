# Append-only source document change log

**Rule:** Never silently revise or erase older entries. Corrections append a new linked entry. This log establishes provenance, not source authority.

## PP-CHG-0001 — 2026-11-04
**Confidence:** VERIFIED for repository action; RECONSTRUCTED for older creative decisions summarized from prior discussions and handoff report.

**Trigger:** Owner designated PPIO as canonical monorepo for the whole Playtime Protocol project, authorized removal of the public concept site and transition to Goose primary implementation.

**Changes:** Replaced root README; added AGENTS.md, story/character/arc/POV/geography documents, gameplay and visual specs, asset-factory and resource-safety rules, migration plan, continuity ledger and approval standard; preserved earlier concept-site commit on `archive/showcase-2026-11-04` and removed static site files from `main`.

**Authority:** Prior explicitly approved JRPG decisions govern. No new final character art, Unknown design, room map, exact combat data or resolved stability hypothesis is claimed.

**Downstream:** Goose must migrate file-verified local implementation without duplication; review local documentation for more recent approvals; stop website deployment administratively; protect public repo from confidential asset/data inclusion.

**Intentionally unchanged:** Preexisting Godot/ComfyUI files in the local working tree (not accessible in this GitHub transaction); original website remains on archive branch and in history. No Godot/ROCm/ComfyUI dependency versions were upgraded. The future owner approval of final assets is not implied.

**Verification:** Inspect tree and commit after publication; admin Pages disable may require manual settings.

## PP-CHG-0002 — 2026-11-04
**Confidence:** VERIFIED for this GitHub documentation update; USER-SUPPLIED/REPORTED for Goose local tool behavior and forensic findings, pending local file and execution checks.

**Trigger:** Owner required Goose to know exactly which monorepo to use and requested a determination of whether Goose is suitable to finish the work, forwarding its second detailed handoff.

**Changes:** Added a concise repository-local `.goosehints` and the explicit `docs/production/04_GOOSE_REPO_HANDOFF.md`; linked both from the root README and authority/agent index; updated resource safety with the corrected five-run DynamicVRAM matrix and the current untested-live guard limitation; appended reported local handoff status; recorded the canonical branch and validation boundary in the living ledger.

**Downstream:** Goose must switch its working directory to the checked-out PPIO root, fetch updated instructions, protect existing OMP/Goose local work, reconcile/import source instead of recreating it, verify privacy before push, then pass staged headless and monitored asset-pipeline acceptance gates.

**Intentionally unchanged:** No local ComfyUI/Godot program files or settings have been touched by this remote documentation commit. No GPU workload, live interrupt or asset generation has been run; no claim of freeze resolution. The old website remains archived. Making PPIO private and administratively disabling GitHub Pages remain separate account settings actions.

## PP-CHG-0003 — 2026-11-04
**Confidence:** VERIFIED for repository changes and explicit owner direction; implementation and hardware tests NOT YET PERFORMED.

**Trigger:** Owner requested Goose produce everything needed for a polished, complete combat test with production-grade engineering using non-final assets; explicitly clarified that controller (Xbox-style test now; Steam Controller at release), full HUD/UI, and **music + sound effects** belong in scope. Final Fantasy VII Rebirth is cited as interaction/polish reference.

**Changes:** Added `docs/design/03_COMBAT_TEST_SLICE.md` and `docs/design/04_CONTROLLER_HUD_UI_AUDIO.md`; revised gameplay contract, production pipeline guide, Goose agent/handoff hints, root README, authority index and living decisions to make controller-first whole-loop play and integrated sound non-optional. No final art canon, complete combat model or finished audio composition is implied.

**Downstream:** Goose should inspect and reuse OMP's local prototype, build a controller-only playable battle early, then deliver coherent playable proxies, responsive menus/HUD, SFX, original battle music, audio buses and input parity with documented validation. Use resource-safe/rights-checked pipelines and don't block on unproven ComfyUI runs.

**Intentionally unchanged:** Existing runtime code, ComfyUI, ROCm, drivers, model caches and safety scripts; no actual generation, controller playtest or audio listening test was conducted by this GitHub documentation update.

## PP-CHG-0004 — 2026-11-04
**Confidence:** VERIFIED owner request and documentation change; in-engine implementation NOT YET VERIFIED.

**Trigger:** Owner explicitly required rigging and animation to be included in the production-quality non-final combat test.

**Changes:** Added docs/design/05_RIGGING_AND_ANIMATION.md and strengthened combat test, asset factory and Goose hints to require proper character-specific rigs, editable sources, real Godot animations/state transitions, attack/hit/audio/visual synchronization and validation. No final artistic canon or campaign-wide contributor/pacing rules established; no runtime, driver or safety changes made.

## PP-CHG-0005 — 2026-11-04
**Confidence:** VERIFIED owner-supplied local path, explicit post-slice optimization directive, and GitHub document change; local tool/config state NOT inspected by this remote update.

**Trigger:** Owner requested Goose specialize itself using available extensions, skills, recipes, agents, apps and underlying controls after finishing combat slice, and identified the local project folder as `/mnt/workdrive/playtime-protocol-godot-comfy-blender`.

**Changes:** Added `docs/production/05_POST_SLICE_GOOSE_OPTIMIZATION.md`; linked deferred task from `.goosehints`, root `AGENTS.md`, README, authority index and Goose repo handoff. Reinforced that local workspace and PPIO remote are separate identifiers until verified and reconciled.

**Scope/constraints:** Audit actual installed Goose build; add scoped validated capabilities only after combat-test completion, with resource safety and no new costs/privacy exposure. Contributor governance, total game length, section and encounter pacing, final story/asset approvals remain reserved for owner discussion. No code generation, driver/config changes, local files or GPU work were executed here.

## PP-CHG-0006 — 2026-11-04
**Confidence:** VERIFIED for explicit owner mandates and GitHub document updates; local run, hardware, editor and subjective review still NOT TESTED.

**Trigger:** Owner approved three ordered contributor resilience laws: (R1) no destruction/always follow repo-level rules; (R2) never crash the workstation or interfere with the user; (R3) persist and get the approved goal done without violating R1/R2. Owner required future Goose specialization to use Godot Editor, Blender, ComfyUI and relevant tools, plus concrete guards against generic, homogenized and low-quality AI design. Owner will send the specialization prompt separately after combat completion.

**Changes:** Added root CONTRIBUTING.md, governance laws and non-destructive current-slice transition, campaign scope/pacing framework (approval process only, numeric targets open), integrated toolchain contract, distinctive-design quality gates, identity/review and section templates, PR checklist, bounded Markdown governance checker and CI workflow. Linked relevant documents from agent instructions, README, specs and authority index; recorded owner decisions. Revised deferred Goose specialization to explicitly honor existing rules, actual editor/Blender/ComfyUI/audio operation and separate start authorization.

**Immediate effect:** Contributors must preserve existing work, protect the user/system, pursue safe alternatives, and reject structurally samey or technically broken game assets and encounters. Current combat slice adapts incrementally rather than being rebuilt or automatically failed for new paperwork. Owner review is required for design identity acceptance.

**Intentionally unchanged:** Godot code and running editor, Blender, ComfyUI flags/models, machine settings, local project files and remote configuration. No driver/GPU tests, actual skill/recipe installations, complete controller playthrough or art/audio subjective acceptance were performed by this documentation change. No campaign length/section/encounter minute quotas were invented. CI verifies file presence/links only; cannot judge art or runtime correctness.

## PP-CHG-0007 — 2026-11-04
**Confidence:** VERIFIED owner instruction for collaborative decision rights and preferred model roles; GitHub documents updated. Installed Goose version, provider IDs, quotas, tool routing and real execution still NOT TESTED.

**Trigger:** Owner clarified ChatGPT is a reasoning partner **with** the owner, Goose is the implementation/test harness; user and ChatGPT should jointly decide the final specialization after reviewing measured evidence. GLM-5.3-Flash will be predominant for speed/cost, selective GLM-5.3 for demanding reasoning, with no assumed GLM-5.5 availability.

**Changes:** Added `docs/production/07_GOOSE_SPECIALIZATION_REVIEW_PROTOCOL.md`; updated queued optimization task, repo/agent hints, authority index and decisions to define joint D0–D3 review gates, scoped paired tests, hard safety/quality gates, model escalation and future GLM-5.5 evaluation. No model/provider was actually switched in this commit. The owner's separate post-combat start prompt is still required.

**Operational boundary:** ChatGPT does not automatically receive Goose's local live state or decisions; owner supplies the report or requests a fresh PPIO GitHub review. No autonomous approval, hidden background work or unsupported data access is claimed.

## PP-CHG-0008 — 2026-11-05
**Confidence:** VERIFIED for owner feedback and GitHub documentation change. No local Goose configuration or model setting changed.

**Trigger:** Owner rejected excessive process and benchmarking bureaucracy, emphasizing speed and recent success building quickly while retaining quality and safety.

**Changes:** Simplified the deferred Goose optimization plan and decision/testing protocol. Goose now has autonomy to make small safe project-local changes and use targeted tests instead of four formal review stages and a full ten-test matrix. Owner and ChatGPT remain reasoning partners for consequential design, safety and final setup choices. GLM-5.3 Flash remains the intended default, with selective GLM-5.3 escalation.

**Unchanged:** R1 non-destruction/repo rules, R2 system/user protection, R3 persistent safe delivery; actual Godot/Blender/ComfyUI/audio integration, originality and technical quality requirements; separate post-combat owner start prompt. No gameplay, assets, workflows or runtime modified.

## PP-CHG-0009 — 2026-11-05
**Confidence:** VERIFIED owner clarification and GitHub documentation change; no Goose runtime or model configuration changed.

**Trigger:** Owner clarified that testing is part of development work itself, not a separate benchmark or artificial test exercise.

**Changes:** Updated deferred Goose specialization and joint decision protocol to use real Playtime Protocol tasks as integration tests, recording concise pass/fail evidence and retaining only essential non-destructive/safety preflights. Removed standalone fixture and benchmarking requirements for routine optimization.

**Unchanged:** The three resilience laws, safety resource gates, real gameplay/import/audio/rig/continuity acceptance, owner review of creative direction, and the separate post-combat owner prompt. Untested capabilities must be labeled NOT TESTED rather than manufactured as passing.
