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
