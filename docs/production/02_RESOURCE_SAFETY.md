# Resource safety contract — CachyOS / RX 7900 GRE

**Hardware target:** RX 7900 GRE 16 GB VRAM, Ryzen 7 7800X3D, 32 GB system RAM, Linux KDE Plasma/Wayland, ROCm/HIP. These budgets are conservative initial operating targets, not a guarantee against GPU-driver failure.

## No GPU work before protections
Use existing Goose-local `tools/resmon.sh` and `tools/comfy_start.sh` **after they are imported and verified**. Their local presence is attested by the November 4 handoff, not by this GitHub commit. Never blindly run a script in this repository if it hasn't been imported.

**Active use:** aim to retain ≥4 GB free VRAM, ≥10 GB available RAM and ~4 logical threads worth of CPU headroom. Do not start new GPU-heavy work while the user is active unless explicitly approved. **Idle ≥5 minutes:** one queued GPU job at a time; aim for ≥3 GB free VRAM and ≥8 GB available RAM, ~2 logical threads of CPU headroom. Unknown idle detection means assume active; never record keystrokes or desktop content.

**Safety stop thresholds:** available RAM <6 GB, free VRAM <2 GB, high memory PSI (example ≥50%), sustained swap pressure or AMDGPU reset/OOM. Stop queuing immediately; cancel active ComfyUI job safely if possible; do not restart it repeatedly. The individual monitors must be light but **continue while a generation is running**. Preflight alone is not sufficient protection; if this cannot be verified, don't run the job unattended.

## Verified observation at Goose handoff
At the reported observation point: ~21.3 GB available RAM, ~140 MB swap used, memory PSI 0, ~14.4 GB free VRAM, 9% GPU busy, no relevant amdgpu faults/OOM in three days of journal. This is a historical snapshot, **not** a current-state guarantee.

## Corrected DynamicVRAM evidence (Goose report, 2026-11-04)

The local forensic source is reported at `ops/DYNAMICVRAM-EVIDENCE.md` (not yet independently inspected in PPIO). Five-run matrix as supplied:

- **DynamicVRAM enabled** — runs B/C: recoverable ComfyUI load-stage stalls; desktop remained responsive, reported peaks ~9.6 GB system RAM and 2.7 GB VRAM.
- **DynamicVRAM disabled** — run D and later E: GPU-starved and machine-threatening hangs, including growing RAM/VRAM and approximately 5.6 GiB swap at the ~20:10 freeze. No OOM/GPU fault was recorded in journal. The temporal association strongly disfavors the disabled setting on this configuration but is **not** proof of the mechanism.
- Goose corrected the assumption that disabling DynamicVRAM automatically enables HIGH_VRAM: the reported `model_management.py` logic says HIGH_VRAM requires explicit flags.
- Reported co-factors were an MIOpen first-compile taking over 14 minutes and `fast_disk` mmap re-reads. These are **hypotheses**, not a confirmed root cause.
- **No configuration has yet completed a ComfyUI generation.** Preserve the currently verified launch policy: DynamicVRAM enabled, `--reserve-vram 3`, pinned memory on. Do not use `--disable-dynamic-vram`, `--gpu-only`, `--highvram` or `--disable-pinned-memory` without new evidence and approval.
- `--disable-fast-disk` (local decision candidate D-011) is only a **single-change hypothesis** to evaluate deliberately when the user is idle/authorizes and monitoring exists. Do not mix it with simultaneous memory setting changes.

## Runtime guard: reported implemented, not stress-validated

Goose's local `tools/comfy_guard.sh` reportedly samples available RAM, VRAM, swap trend and memory PSI every 15 seconds; scans bounded GPU kernel-fault patterns at about one-minute intervals; and on a pressure breach sends one graceful ComfyUI `POST /interrupt` then exits 2. It logs incidents without restarting or re-queuing. Its syntax, no-job and unreachable-server paths were reported checked. **A real workload's threshold-to-interrupt path has NOT been validated.**

The guard must be coupled to each actual job, with job/process lifetime and failure codes accounted for. Never report a missing/unresponsive guard as successful monitoring. A 15-second polling interval can miss abrupt memory spikes, and `POST /interrupt` may not stop an already hung GPU kernel or prevent a machine freeze. Treat this guard as risk reduction rather than an enforceable VRAM cap.

## Validation sequence
Read-only memory snapshot → lightweight API startup only if allowed → one small default-batch SDXL job while runtime monitoring → verify VRAM/RAM recovery toward baseline → expand gradually only with evidence. Avoid active-use interference, long benchmarks, multiple workers and aggressive retry. Don't claim a sustained soak test passed when only a smoke test ran.
