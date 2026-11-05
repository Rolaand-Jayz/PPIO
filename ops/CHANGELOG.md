# Source-document change log — Playtime Protocol

Append-only provenance for guideline/config documents, in the style of The Twentieth
Revision's `14_Source_Document_Change_Log.md`. Entries are never rewritten; corrections
are appended with a new entry. Confidence labels: VERIFIED / RECONSTRUCTED / APPROXIMATE.

Note: this repository had no Git history before 2026-11-04. Pre-handoff document states
are RECONSTRUCTED from OMP session artifacts under `~/.omp` and are preserved verbatim
where copied into `ops/sources/`.

---

- **2026-11-04 (RECONSTRUCTED, ~13:28–19:46)** — OMP sessions 01a1a837, 01a1a809 ("VRAM: Fix ComfyUI memory hogging") ran ComfyUI configurations A–D (see `ops/DYNAMICVRAM-EVIDENCE.md`); README.md gained and twice revised the "ComfyUI server launch (memory policy)" section; `scripts/encounter.gd` received an uncommitted HUD-wiring diff (9 assets, never run); `tests/hud_capture.gd` scaffold created (flagged for cleanup or exercise). Evidence: `ops/sources/vram-session-report-01a1a809-2026-11-04.md` (verbatim copy of OMP's source session report).

- **2026-11-04 (VERIFIED, 17:16)** — Contiguous SDXL checkpoint cache created at `/home/rolaandjayz/playtime-comfy-cache/checkpoints/` (6.9 GB, shared library untouched). Evidence: file mtime; `comfy_local_cache.yaml`.

- **2026-11-04 (VERIFIED, 19:41–20:10)** — OMP session 01a1a95e researched ComfyUI issue #13730 and attempted `--disable-dynamic-vram` restarts; machine silently froze ~20:10; reboot 20:14:51. Evidence: `~/.omp/logs/omp.2026-11-04.2365119.log` (session title, 19:42:13); session `18.bash.log`; kernel journal of previous boot (no OOM, no GPU fault).

- **2026-11-04 (VERIFIED, 20:23–21:07)** — OMP recovery session 01a1a984 updated README.md: `--disable-dynamic-vram` freeze warning added to the memory-policy section; session ended via SIGHUP with 0 pending tool calls. Evidence: README text; `~/.omp/logs/omp.2026-11-04.22447.log` (21:05:43 exit record).

- **2026-11-04 (VERIFIED, 21:57–22:31)** — Goose handoff. Created `ops/HANDOFF-2026-11-04.md` (inventory), `tools/resmon.sh` (on-demand snapshot + idle check; PSI avg60 parsing bug found and fixed during verification), `tools/comfy_start.sh` (preflight-gated launcher; preserves README launch arguments verbatim). No OMP-authored file was modified.

- **2026-11-04 (VERIFIED, 22:31–23:00)** — Goose continuation: (1) `tools/comfy_guard.sh` created — per-job lightweight monitor (15 s samples; RAM/VRAM/swap-trend/PSI + 1/min kernel-fault check) with graceful `POST /interrupt` on breach and incident logging to `ops/guard-events.log`; no-job and unreachable-server exit paths tested. (2) `ops/DYNAMICVRAM-EVIDENCE.md` created — DynamicVRAM reconciliation from primary evidence, including correction of goose's earlier HIGH_VRAM-selection inference. (3) `ops/DECISIONS.md` (D-001…D-011) and this change log created per the Twentieth Revision governance approach (D-010). (4) README.md appended with governance, monitoring, and evidence-note sections (OMP text preserved). (5) OMP's VramSession report copied verbatim to `ops/sources/vram-session-report-01a1a809-2026-11-04.md`.

- **2026-11-05 (VERIFIED, 23:24–00:59)** — Goose Desktop combat-slice session (owner-directed 2026-11-04 milestone). (1) Preservation commit of all OMP/Goose local work (resource tools, memory policy, ops ledgers; benchmark leftovers gitignored). (2) `scripts/battle_rules.gd` v2: roster extended to Jayze/Kip/Rallo/Jonnie vs Sprocket/Clanker/Gimbal; staged enemy phase (`plan_enemy_phase`/`apply_enemy_step`/`finish_enemy_phase`, `defer_enemy_phase`) so presentation cannot change deterministic outcomes; new mechanics screech/pound/mend/brace; `tests/battle_smoke.gd` keeps all v1 assertion intents (adapted to roster) plus v2 coverage — PASS on Godot 4.7.2 headless. (3) `tools/build_combat_assets.py`: deterministic Blender 4.5 headless builder; 4 party + 3 enemy rigs with toy-segment weights, sockets, named clips (exported ACTIONS mode), toy-scale arena (vertex-color grid, obstacles on BLOCKED_CELLS, music box on MUSIC_BOX); Godot load probe verifies bones/anims/sockets/meshes. (4) `tools/build_audio.py`: original procedural music/SFX (loopable 27.4s combat theme, encounter/victory/defeat stingers, ambience, ~29 cues); buses Master/Music/SFX/UI/Ambience via `default_bus_layout.tres`. (5) Full Godot runtime: `battle_director.gd` (battle loop + attack-window timing), `unit_view.gd` (animation control, sockets, distance-derived Kip wheel spin), `battle_camera.gd`, `battle_vfx.gd`, `battle_hud.gd` + `portrait_chip.gd` (controller-first HUD/menus/settings), `audio_manager.gd`, `game_settings.gd`, InputMap in `project.godot`; `scripts/encounter.gd` superseded and removed (preserved in git history). (6) `tests/slice_integration.gd` PASS (scene→battle→enemy phase→result→restart→pause; 0 script errors); `tests/hud_capture.gd` rewritten as rendered QA capture — 7 states saved to `artifacts/captures/` and reviewed. (7) `tools/build_manifest.py` → `assets/asset-manifest.json` (42 entries, checksums, license/provenance, approval: provisional). (8) Docs: `docs/COMBAT_SLICE_REPORT.md` (verified vs reported-only), `docs/CONTROLS.md`, README run/rebuild/verify sections. No GPU generation was run (user active per resmon). See `docs/design/03_COMBAT_TEST_SLICE.md` P0–P4 mapping.

## 2026-11-05 — Goose specialization session (goose-desktop)
- VERIFIED: godot-editor-mcp 2026.10.20.1 stable integrated end-to-end on real project data — shared HTTP server (ops/goose/godot_mcp_server.sh), vendored addon (addons/godot_mcp/), plugin enabled in project.godot; live scene/project inspection incl. all 17 PPIO InputMap actions; chain proven through goose itself (enable→run→disable cycle).
- VERIFIED: model identifiers — zai/glm-5.3-flash (default) and zai/glm-5.3 (escalation) both answered live one-shot calls.
- CREATED: 6 skills (.agents/skills/ppio-*) discovered by goose skills list; 5 recipes (recipes/ppio-*.yaml) all passing goose recipe validate; checkpoint-resume recipe exercised LIVE (checkpoint of the committed specialization state).
- CREATED: ops/GOOSE_TOOLCHAIN.md (component table, evidence, untested list, rollback paths).
- IMPORTED: canonical .goosehints/AGENTS.md/CONTRIBUTING.md + governing docs from origin/main ad430fdf (additive; local tree previously lacked them).
- REJECTED: GitHub MCP (gh sufficient), Beads (ledger duplication), comfy-mcp (lifecycle conflict, D-018); Blender MCP left disabled (D-019).
- TESTS: battle_smoke.gd PASS (rules v2) and slice_integration.gd PASS (3.1s) after project.godot plugin addition — combat slice unaffected.
- CORRECTION (same day): the checkpoint-resume recipe live exercise occurred AFTER the entry above was drafted; that line described intent and is now factual — see ops/checkpoints/CHECKPOINT-2026-11-05-1050.md. Drift it caught (missing docs/design 01-06 + templates) fixed by importing them additively from origin/main; battle_smoke + slice_integration re-run PASS before this entry.

## 2026-11-05 — Asset quality loop, iteration 1: generation pipeline live (goose-desktop)
- OWNER AUTHORIZED local GPU generation for combat-slice assets; safety rails held: resmon preflight, comfy_start.sh (GOOSE_FORCE_COMFY_START=1 per documented override), guard on every job, one job at a time, peak VRAM 9.2/16.3GB, zero pressure breaches, 6 successful jobs (5 concepts + 1 mesh).
- PIPELINE ESTABLISHED: SDXL concept (identity-gated, bounded iteration — 5 rejected candidates with recorded causes) -> Hunyuan3D v2.1 image-to-mesh -> tools/refine_generated_character.py (hole audit/fill, decimate 208k->52k tris, normalize to 1.1u, leg-cluster detection, heat weights, factory bone names + 8 clips verbatim, palette projection to 10 toy-panel materials) -> GLB -> Godot.
- DELIVERED: assets/characters/jayze.glb v2 (rigged Hunyuan mesh) replacing graybox; last-known-good preserved at assets/legacy-graybox/jayze.glb; provenance in assets/generated/jayze/PROVENANCE.json; manifest checksums refreshed.
- VERIFIED: battle_smoke PASS, slice_integration PASS (AnimationPlayer + idle animating on new rig), hud_capture 7 frames — new Jayze readable at gameplay distance.
- REJECTED per gates: v001 concept (glowing-armor mecha = hard reject), v002 (faceless mannequin), v003 (elderly cloth coat), v004 (child proportions), v005 (two-figure sheet).
- KNOWN LIMITS: 126 sub-mm crack-seam edges (Hunyuan multi-shell, invisible in engine); back/side colors stretched (front projection); remaining cast still graybox (loop continues: Kip, Rallo, Jonnie, Sprocket, Clanker, Gimbal).
- CANON (D-023): combat slot 4 is Captain Crusher (Jonnie story-only, never combat). Renamed id/display/audio/asset/test references; battle_smoke + slice_integration PASS; hud_capture verified party panel shows Crusher.
- Asset-loop refs: owner will supply starting images in assets/source/playtime/_owner-provided/; generated refs (SDXL v001-v006, pollinations flux) demoted to placeholders/provenance.
