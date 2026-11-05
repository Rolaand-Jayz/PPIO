---
name: ppio-comfy-production
description: Safe ComfyUI generation policy and tooling for PPIO — preflight, controlled launch, guard, provenance. Use before any image/asset generation task (requires explicit owner authorization while the user is active).
---

# PPIO ComfyUI production

## Hard rules (never bypass)
1. NO GPU-heavy job while the user is active without explicit authorization. Check `tools/resmon.sh` first (`user_state` must allow it).
2. One ComfyUI job at a time; server on port 8188 only; never start a second/competing instance.
3. Approved launch policy: dynamic VRAM + `--reserve-vram 3`. FORBIDDEN flags: `--gpu-only`, `--highvram`, `--disable-async-offload`, `--disable-dynamic-vram`, `--disable-pinned-memory` (the hard-freeze family). See ops/DECISIONS.md D-001..D-015 and tools/comfy_guard.sh header.
4. Launch only via `tools/comfy_start.sh`; run jobs through `tools/comfy.py`; guard with `tools/comfy_guard.sh`. Do NOT toggle flags or versions casually.
5. No paid cloud generation, no duplicate model downloads, no second installation. `comfy-mcp` (Comfy-Org) was evaluated 2026-11-05 and REJECTED for now: it manages its own ComfyUI lifecycle, which conflicts with the controlled launcher + guard; revisit only with owner approval.

## Workflows + provenance
Existing workflows live in `workflows/` (SDXL concept/mesh/API variants). Assets produced here are PROVISIONAL: record prompt, seed, model, workflow, and output path in the run log; run `python3 tools/build_manifest.py` so assets/asset-manifest.json carries checksums + provenance (`status: provisional`, license 'project-original ... owner to finalize'). Third-party/licensed inputs need an explicit rights check before entering the repo (PPIO is public).

## Status
Guard no-job/error paths verified 2026-11-05; live interrupt path under GPU pressure NOT validated — treat as untested. Escalate memory-pressure symptoms (stutter, hard-freeze evidence) to the owner immediately and stop.
