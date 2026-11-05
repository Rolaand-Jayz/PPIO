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
