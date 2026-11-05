# Goose Desktop — canonical repository handoff and acceptance gates

**Owner instruction (2026-11-04):** The entire Playtime Protocol: Innocence Lost project uses **Rolaand-Jayz/PPIO** as its **only canonical GitHub monorepo**. Goose Desktop is the **primary implementation harness**, not OMP. The exact remote is:

`https://github.com/Rolaand-Jayz/PPIO.git`

Canonical branch: `main`. **The `archive/showcase-2026-11-04` branch is solely the historic six-page website, never the game implementation target.**

## Immediate Goose action: establish location, not a new project
1. Identify the current working directory and its nearest Git root. Inspect `git rev-parse --show-toplevel`, `git status --short`, `git remote -v`, `git branch -vv`, and `git log -1 --oneline`, using read-only operations first.
2. Determine whether local Godot/ComfyUI/ops files are in the same Git working tree as PPIO, a different Git repository, or an unversioned folder. Record the exact verified relationship.
3. Fetch the PPIO remote and read `AGENTS.md`, `.goosehints`, this handoff, `docs/00_START_HERE.md`, and the resource safety contract. Do not assume older Goose sessions loaded the updated instructions; local hints are loaded with a new Goose session in the appropriate root.
4. Protect local uncommitted changes before branch switching, merging or relocating. Use a backup/worktree/snapshot suitable to their present Git state; do not discard any local artifact.
5. If the existing prototype is in a different repository, preserve that origin/history and integrate into PPIO with a traceable import, not a blind replacement or `git init` over the source. Never force-push or repoint an existing origin without establishing the existing history.
6. Keep working relative paths stable until headless Godot/Python tests pass; do not create dummy replacement files for source code that already exists. Before writing, map each existing path to its intended monorepo location and record duplicate conflicts.

## Public repository boundary
PPIO is **public at this handoff**. Before any push, inspect assets for licenses, private notes, full machine paths, identifying data, API keys/tokens, model weights, generated output size and legal restrictions. Do not push raw GPU forensics, ops logs, local caches or user data. Where publication is uncertain, keep work local and request privacy decision rather than making the repository public with sensitive material. The old site is archived, but actual GitHub Pages shutdown may still require an administrative Settings change.

## Local implementation already reported by Goose (do not recreate)
- Working Godot 4.7.2 deterministic combat prototype, scenes, tests, asset registry and manifest.
- `tools/comfy.py` supporting ComfyUI API submit/wait/cancel/upload/parameter overrides; `tools/blender_process.py` GLB smoke-tested.
- Five existing API-format workflows: SDXL for Kip/Jayze/HUD, Flux2-Klein Kip, Hunyuan3D Kip; models already in a shared library and a 6.9 GB contiguous SDXL cache copy.
- `tools/resmon.sh`, `tools/comfy_start.sh`, `tools/comfy_guard.sh`.
- `ops/HANDOFF-2026-11-04.md`, `ops/DYNAMICVRAM-EVIDENCE.md`, `ops/DECISIONS.md`, `ops/CHANGELOG.md`, preserved OMP forensic report.

This list comes from **Goose's supplied November 4 local report**, not files inspected in this GitHub commit. Confirm each one exists before marking imported. Preserve Goose's existing local decision ledger and change log without replacing them with this monorepo's documentation ledgers; reconcile and keep both provenances.

## Freeze forensics and present safety posture
Reported five-run matrix: DynamicVRAM **enabled** produced recoverable load-stage stalls (B/C) with the desktop responsive; **disabled** was associated with machine-threatening freezes (D/E) and growing swap. This favors preserving DynamicVRAM enabled and current `--reserve-vram 3`, with pinned memory enabled. It does NOT prove a successful or safe complete generation; **none has completed yet**. The hypothesized `--disable-fast-disk` single-change test (D-011) remains an unverified candidate; do not combine with other flags or test while user active.

The added `comfy_guard.sh` reportedly samples every 15 seconds and uses `POST /interrupt` on breach. Its syntax, no-job and unreachable-server paths were validated; **the live breach-to-interrupt path has not been**. A 15-second sample cannot catch all rapid VRAM spikes, and an interrupt cannot guarantee rescue from an already-stuck GPU kernel. Keep failure expectations realistic and stop at the first warning.

## Acceptance gates: retain Goose if these pass
**G0 — Repository:** PPIO remote and branch identified; local sources preserved; source/conflict map documented. No public leakage.
**G1 — Documentation:** Existing local canon, continuity, governance and pipeline docs reconciled into PPIO, with explicit owner decisions and provenance. Historical SHMUP not promoted.
**G2 — Headless:** Existing Godot and Python tests run without regression; no GPU stress test.
**G3 — Safe execution:** After user authorization or verified idle ≥5 min, one small SDXL job completes under live guard; complete recorded resource trace; no freeze, growing memory pressure or missing outputs; VRAM/RAM recover to observed baseline.
**G4 — Asset chain:** Existing `comfy.py` output → Blender .glb processing → Godot import, scenes and gameplay-camera checks succeeds with provenance/rights evidence.
**G5 — Repeatable work:** A second independent small job, on another session if practical, completes with correct caching, cleanup, handoff and documented rollback. No duplicates, unbounded retries or loss of user responsiveness.

**Decision rule:** Goose remains preferred while it reports accurately, preserves prior work and makes safe measurable progress. Escalate to a different harness only if repeated reproducible harness-level failures remain *after* separating GPU/ROCm/ComfyUI faults from agent execution faults. A model or ComfyUI hardware limit is not evidence that Goose itself needs replacing.

## Reporting
Give the owner a concise evidence-based report with: confirmed working Git root + remote + branch; local-to-PPIO source mapping; files migrated and skipped; privacy status; resource guard test status; each gate's PASS / BLOCKED / NOT TESTED; exact next safe action. Never represent a proposed operation, or an unrun model, as verified.

## Current owner-directed milestone — playable combat test (2026-11-04)
Before work, read [combat test slice specification](../design/03_COMBAT_TEST_SLICE.md) and [controller, HUD, UI and sound](../design/04_CONTROLLER_HUD_UI_AUDIO.md). Build **production-quality implementation with non-final proxy assets**, not final canon art, using existing prototype and workflow resources. This includes a full battle loop; four distinct party proxies; 2–3 noncanonical enemies; compact arena; responsive controller-first battle HUD, all menus, targeting and restart; original **combat music, SFX, UI cues and mix controls**; and keyboard/mouse parity. Real test controller is Xbox/XInput-style; Steam Controller/Steam Input is eventual release requirement. FF7 Rebirth is a controller/combat UX benchmark, not a mandate to import its battle mechanics or protected designs. Treat gamepad/audio acceptance as a **blocking milestone**, not an optional feature. Keep idle gating and no unsafe parallel ComfyUI jobs.
