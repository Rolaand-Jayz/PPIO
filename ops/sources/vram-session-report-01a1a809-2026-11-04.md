## Source session report: `01a1a809-2f93` — "🧠 VRAM: Fix ComfyUI memory hogging" (project `/mnt/workdrive/playtime-protocol-godot-comfy-blender`)

No nested agent histories (`history://` listing empty); the fork transcript above is the complete source. All claims below cite tool results from that transcript; `[INFERENCE]` marks deduction.

### 1. What the session was actively doing when interrupted

Two user turns: **(a)** "fix the issue you caused" (VRAM/RAM hogging), then **(b)** "well finish the task" — i.e., finish the in-flight HUD asset generation that the killed ComfyUI server had been serving.

At the moment of interruption the session was **diagnosing why the third consecutive ComfyUI relaunch still couldn't generate an image**. Exact last actions (tool results returned "outcome is unknown" — session cut mid-flight):

- `proc://playtime-comfy-safe/kill` — stopping the 4th server instance (PID 1784970, up 13m53s)
- `df -T` + two `dd if=...sd_xl_base_1.0.safetensors of=/dev/null bs=1M count=1500/skip=3000` — measuring sequential read speed of the model disk

Evidence prompting that: run D (`--disable-dynamic-vram --reserve-vram 3`) produced **python 250.3% CPU, GPU busy 7–10%, VRAM flat at 4196 MiB**, log stuck after `Model storage policy: fast_disk=True`. `[INFERENCE]` Working hypothesis at cutoff: `fast_disk` mmap-streams weights from a slow model disk (`/home/rolaandjayz/ComfyUI-Shared/models`), starving the GPU; intended fix was relaunching with `--disable-fast-disk` + `--reserve-vram 3`.

Files touched: `README.md` (launch-policy section, edited twice), `tests/hud_capture.gd` (created, temp), `/tmp/gen_hud.py` + `/tmp/post_hud.py` (throwaway driver/post-processor), `comfy_extra_paths.yaml` (read-only). `scripts/encounter.gd` was modified in an *earlier* session (uncommitted diff wiring 9 HUD assets into the Godot HUD); this session did not edit it.

### 2. What was completed and verified

**Memory hog killed and verified released** (turn 1):
- Culprit process found and terminated: PID 1716292 running `--disable-all-custom-nodes --gpu-only --disable-async-offload --disable-fast-disk --extra-model-paths-config ...` — log: `Set vram state to: HIGH_VRAM`, **`Enabled pinned memory 14836`** (14.8 GB page-locked RAM ceiling on a 30 GB box; desktop shoved into 12.5 GB swap)
- 8 stale omp services killed via `proc://.../kill`: `playtime-comfyui-gpuonly`, `comfyui`, `hud-batch`, `playtime-comfyui`, `playtime-final`, `playtime-comfyui-dynamic`, `playtime-comfyui-vram`, `playtime-godot`
- Post-kill verification observed: RAM 9.8 GB used / **20 GB available**, swap draining (4.2→3.4 GB), VRAM **2399 MiB** (desktop baseline) on the RX 7900 GRE. Only user-owned `blender-mcp` (32 MB) remained
- `README.md` gained "ComfyUI server launch (memory policy)" section documenting: never `--gpu-only`/`--highvram`/`--disable-async-offload`; correct launch = `--extra-model-paths-config ... --output-directory assets/source --reserve-vram 3` (final revision). **Note: README does not yet document `--disable-dynamic-vram`** — that discovery postdates the last edit

**Verified facts about the environment:** ComfyUI 0.42.1, torch 2.12.0+rocm7.14.0, gfx1100, 16368 MB VRAM / 31221 MB RAM; CLI flags confirmed in `comfy/cli_args.py` (`--reserve-vram` L175, `--disable-dynamic-vram` L181, `enables_dynamic_vram()` L334-337; pinned-memory ceiling formula `model_management.py:1643`).

**Generation attempts — none succeeded.** `assets/hud/` stayed empty; `assets/portraits/` never created. Three launches, each timing out the first job (icon_sword) at 600 s:
- Run B `+--disable-pinned-memory`: stalled at `SDXLClipModel prepared for dynamic VRAM loading. 1560MB Staged.` (peak VRAM 2734 MiB, RAM 9625 MiB)
- Run C (pinned on, dynamic on): same stall, zero outputs
- Run D `+--disable-dynamic-vram`: executed (peak VRAM 4202 MiB, peak RAM 14,577 MiB — healthy budget) but GPU-starved per §1

### 3. What remained unfinished / very next intended action

Todo state at cutoff: ~~server start~~ done; **Generate 9 HUD assets (panel, 6 icons, 2 portraits)** in progress; **post-process** into `assets/hud/` + `assets/portraits/`; **Godot verify** (headless import, `tests/battle_smoke.gd`, windowed screenshot via `tests/hud_capture.gd` → `artifacts/hud_live.png`); **cleanup + memory report** — all pending.

Next intended action chain: read the `dd`/`df` results → if disk slow, relaunch ComfyUI with `--disable-fast-disk --reserve-vram 3` (classic load-to-memory path) → rerun `/tmp/gen_hud.py` (9 jobs, seeds 20261111–119, prompts incl. canonical Jayze/Kip concept text) → `/tmp/post_hud.py` (flood-key icons→96², panel→500×430, portraits→256²) → Godot import/smoke/screenshot → delete `tests/hud_capture.gd` scaffold → report with sampler evidence (`/tmp/hud_mem.log`).

`tests/hud_capture.gd` is a leftover scaffold that must be removed or exercised per cleanup rules. Uncommitted `scripts/encounter.gd` HUD diff (pre-existing) is wired to load all 9 assets but was never run against them.

### 4. User corrections/preferences

1. **Never assume the machine's memory is all the agent's** — 32 GB RAM / 16 GB VRAM must be shared with the live desktop stack (KDE Wayland, browser, Steam, Discord, Home Assistant all observed running). "Use just a little thought about what you are doing and the environment you are doing it in."
2. **Finish what was started** — "well finish the task" means complete the HUD generation end-to-end, not stop at the memory fix.
3. `[INFERENCE]` Implied: report memory evidence, keep ComfyUI server restarts minimal and justified — relaunching heavy services unasked was the original offense.