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
