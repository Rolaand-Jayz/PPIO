# Resource safety contract — CachyOS / RX 7900 GRE

**Hardware target:** RX 7900 GRE 16 GB VRAM, Ryzen 7 7800X3D, 32 GB system RAM, Linux KDE Plasma/Wayland, ROCm/HIP. These budgets are conservative initial operating targets, not a guarantee against GPU-driver failure.

## No GPU work before protections
Use existing Goose-local `tools/resmon.sh` and `tools/comfy_start.sh` **after they are imported and verified**. Their local presence is attested by the November 4 handoff, not by this GitHub commit. Never blindly run a script in this repository if it hasn't been imported.

**Active use:** aim to retain ≥4 GB free VRAM, ≥10 GB available RAM and ~4 logical threads worth of CPU headroom. Do not start new GPU-heavy work while the user is active unless explicitly approved. **Idle ≥5 minutes:** one queued GPU job at a time; aim for ≥3 GB free VRAM and ≥8 GB available RAM, ~2 logical threads of CPU headroom. Unknown idle detection means assume active; never record keystrokes or desktop content.

**Safety stop thresholds:** available RAM <6 GB, free VRAM <2 GB, high memory PSI (example ≥50%), sustained swap pressure or AMDGPU reset/OOM. Stop queuing immediately; cancel active ComfyUI job safely if possible; do not restart it repeatedly. The individual monitors must be light but **continue while a generation is running**. Preflight alone is not sufficient protection; if this cannot be verified, don't run the job unattended.

## Verified observation at Goose handoff
At the reported observation point: ~21.3 GB available RAM, ~140 MB swap used, memory PSI 0, ~14.4 GB free VRAM, 9% GPU busy, no relevant amdgpu faults/OOM in three days of journal. This is a historical snapshot, **not** a current-state guarantee.

## ComfyUI issue not resolved
The prior freeze involved progressive pressure and about 5.6 GiB swap. The report states DynamicVRAM default-on in ComfyUI v0.42.1 and a silent hard-freeze, while simultaneously describing `--disable-dynamic-vram` as contraindicated. This is **inconclusive evidence**, not proof of causality or of a safe workaround. Preserve the currently verified launch args (including `--reserve-vram 3` if present), collect existing evidence, and do not change flags speculatively. The reported current safety policy forbids `--gpu-only`, `--highvram`, `--disable-pinned-memory`; do not reverse that without measured evidence and approval.

## Validation sequence
Read-only memory snapshot → lightweight API startup only if allowed → one small default-batch SDXL job while runtime monitoring → verify VRAM/RAM recovery toward baseline → expand gradually only with evidence. Avoid active-use interference, long benchmarks, multiple workers and aggressive retry. Don't claim a sustained soak test passed when only a smoke test ran.
