# DynamicVRAM evidence reconciliation — 2026-11-04

Answers: *which configuration actually failed?* Compiled from primary evidence only
(OMP session artifacts, ComfyUI's own logs, kernel journal, source code). No freeze was
reproduced. Confidence labels follow the governance standard in `ops/DECISIONS.md`.

## Failure matrix (all observed runs, 2026-11-04)

| # | Time (local) | Configuration | DynamicVRAM | Outcome | Failure class | Evidence |
|---|---|---|---|---|---|---|
| A | afternoon | `--gpu-only --disable-async-offload --disable-fast-disk` | OFF (forced) | `Set vram state to: HIGH_VRAM`, `Enabled pinned memory 14836` → 12.5 GB swap, desktop nearly frozen; killed | **machine-threatening** | `ops/sources/vram-session-report-01a1a809-2026-11-04.md` §2; README launch-policy section |
| B | afternoon | DynamicVRAM on, `--disable-pinned-memory` | ON | Stalled >10 min at `SDXLClipModel prepared for dynamic VRAM loading. 1560MB Staged.`; peak RAM 9.6 GB / VRAM 2.7 GB — desktop healthy | recoverable job stall | same report §2 |
| C | afternoon | DynamicVRAM on, pinned on | ON | Same load-stage stall; zero outputs | recoverable job stall | same report §2 |
| D | afternoon | `--disable-dynamic-vram --reserve-vram 3` | OFF | Loaded and executed, but GPU-starved: python 250% CPU (kernel compile), GPU 7–10%, VRAM flat 4196 MiB, `Model storage policy: fast_disk=True`; killed at 13m53s | job stall (GPU starvation) | same report §1–2 |
| E | 19:41–20:10 | `--disable-dynamic-vram` variants (incl. `--disable-all-custom-nodes` probe) | OFF | "In some runs, system RAM, VRAM, and swap continue filling until the Linux desktop freezes"; silent hard freeze ~20:10; 5.6 GiB swap in use; reboot 20:14:51 | **machine-threatening** | OMP log `omp.2026-11-04.2365119.log` (session title "Add --disable-dynamic-vram and restart ComfyUI", 19:42:13); session `01a1a95e` notes (`18.bash.log`); kernel journal of previous boot: **no OOM, no GPU fault, silence**; README |

## Findings

1. **VERIFIED — The machine-threatening freezes happened only with DynamicVRAM *disabled***
   (or forced-HIGH_VRAM flags). Every DynamicVRAM-*enabled* run left the desktop healthy
   with modest peaks; its failures were recoverable job stalls, not system freezes.
   The README policy (DynamicVRAM enabled + `--reserve-vram 3` + pinned memory on) is the
   only configuration family that has never frozen the machine. `--disable-dynamic-vram`
   is empirically falsified on this machine as a fix, despite upstream issue #13730
   (RX 7900 + ROCm load stalls) recommending the disable family.
2. **VERIFIED — No configuration has completed a job yet.** Runs B/C stalled at the
   dynamic-VRAM load stage; run D stalled GPU-starved; the evening runs froze the machine.
   The first successful generation is still pending; the validation job remains gated.
3. **APPROXIMATE (inference, clearly separated) — freeze mechanism.** This build sets
   HIGH_VRAM only from explicit flags (`comfy/model_management.py:578-580`), so run E's
   freeze is *not* classic HIGH_VRAM selection. Observed fill-to-freeze pattern co-occurs
   with: first MIOpen kernel compile >14 min (250% CPU, GPU 7–10%) and `fast_disk` mmap
   re-reads (~26.4 GB observed). A single conclusive allocator-level cause is not proven
   and must not be reproduced. DynamicVRAM-disabled operation stays forbidden until any
   job completes successfully under it — which is not planned.
4. **Open, single-change candidates (in priority order, from OMP's own analysis, never
   to be combined):**
   - `--disable-fast-disk` added to the README baseline — avoids mmap streaming from the
     slow shared-model disk (OMP measured disk reads and was mid-verification at cutoff).
   - MIOpen first-compile mitigation (investigate only if stalls persist after #1).
   Each requires: user idle or explicit authorization, guard active, one change vs the
   README baseline, rollback = revert to README baseline.

## Correction record

An earlier goose report implied `--disable-dynamic-vram` might auto-select HIGH_VRAM on
this hardware. That is incorrect for this build (see finding 3). The README's flag
warnings stand as written; this document records *why* with primary evidence.
