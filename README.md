# Playtime Protocol — combat prototype

This directory was initially empty and had no Git metadata. It now contains a Godot 4.7.2 project with a procedural toy-scale encounter and isolated deterministic combat rules. All character forms and room props are provisional primitive proxies; no approved designs or canonical dimensions were available.

## Run

```sh
godot-mono --path .
```

Controls: WASD moves the selected toy one cell while exploring; C or **Enter combat** starts the Beat System; Tab or keys 1/2 selects a toy. In combat, WASD moves once per activation (Kip can move up to two cells); use action buttons and choose a target. Two activations are available each round. Guard, the nearby music-box interaction, and the cooperative strike are available in the HUD. Press R after a result to restart. Cover and obstacle cells block movement; character forms remain provisional proxies.

## Verify

```sh
godot-mono --headless --path . --editor --quit
godot-mono --headless --path . --script res://tests/battle_smoke.gd
godot-mono --headless --path . --quit-after 5
```

The smoke script covers blocked cells, movement limits, attack ranges, deterministic damage, activation counts, guard reduction, cooperative costs, and victory/defeat transitions. `artifacts/encounter.png` is a screenshot captured from the running Godot window; it shows the prototype proxies, not approved visual assets.

## Environment inventory

- **Verified installed:** Godot 4.7.2 Mono; Blender 4.5.12 LTS; OMP 18.14.2.
- **Verified running:** `blender-mcp` Python process. Its MCP registration with this OMP project was not verified.
- **Verified OMP routes:** project roles map default→GLM-5.3, smol→GLM-5.3-Flash, slow/plan→Codex GPT-6 Luna. Short prompts succeeded through both Z.AI model routes (`ROUTE_OK`, `FLASH_OK`); Codex Plus is the active authenticated session and GPT-6 Luna is listed in the catalog. Existing subscriptions only; no separate API key or paid endpoint configured.
- **Unavailable in this run:** No ComfyUI process responded on `127.0.0.1:8188`; no Godot editor MCP or Ziva installation was confirmed. The workspace had no narrative, approved art references, workflows, checkpoints, assets, or branch history.
- **Implemented but not connected to ComfyUI:** `tools/comfy.py` submits local API-format workflows, polls bounded completion, downloads image/gif outputs, and requests interruption. No graph/model discovery or real generation was possible without a running backend.
- **Blender integration:** `tools/blender_process.py` validates selected meshes and required named Empty attachment points, exports GLB, and reports geometry/material warnings. A temporary Blender cube+attachment smoke run exported a non-empty GLB; it is not a character asset.
- **Asset contract:** `schemas/asset-manifest.schema.json` defines metadata and licensing/provenance fields. No manifest has been filled for an actual generated asset.
- **Not completed:** Ziva/editor MCP registration, workflow discovery/reuse and generation, generated character integration, artistic review, production skills, and a full interactive combat playthrough.

## Local pipeline utilities

```sh
python3 tools/comfy.py submit workflow_api.json
python3 tools/comfy.py wait <prompt_id> --timeout 900 --output artifacts/comfy
python3 tools/comfy.py cancel
blender --background scene.blend --python tools/blender_process.py -- --output assets/processed/asset.glb --attachment weapon_mount
```

The ComfyUI workflow must be in API prompt format. `cancel` interrupts the currently executing local job; it does not remove an arbitrary queued job. Blender exports only selected meshes and checks attachments by Empty name; no coordinate normalization or artistic approval is implied.

## ComfyUI server launch (memory policy)

This machine has 30 GB RAM / 16 GB VRAM shared with a live KDE desktop, browser, Steam, Discord, and Home Assistant. ComfyUI must not assume it owns either pool. Do **not** launch with `--gpu-only`, `--highvram`, or `--disable-async-offload`: on this build that forces `HIGH_VRAM` (all weights resident in VRAM) and page-locks up to ~14.8 GB of host RAM (`Enabled pinned memory 14836`), which pushes the desktop into swap. Observed consequence: 12.5 GB swap in use with the machine nearly frozen. Do **not** launch with `--disable-dynamic-vram` either: it turns off the weight streaming this policy depends on. On 2026-11-04 the running server had it set minutes before the desktop thrashed into swap (5.6 GiB in use) and hard-froze; the kernel journal recorded no OOM and no GPU fault, just silence — the same silent-hang signature as the HIGH_VRAM failure above.

Correct launch — dynamic VRAM management (weights stream and unload; VRAM returns to the ~2.4 GB desktop baseline after each job), 3 GB VRAM held back for the OS/Blender/Godot:

```sh
"/home/rolaandjayz/ComfyUI-Installs/ComfyUI (1) (1)/standalone-env/bin/python" \
  "/home/rolaandjayz/ComfyUI-Installs/ComfyUI (1) (1)/ComfyUI/main.py" \
  --extra-model-paths-config /mnt/workdrive/playtime-protocol-godot-comfy-blender/comfy_extra_paths.yaml \
  --output-directory /mnt/workdrive/playtime-protocol-godot-comfy-blender/assets/source \
  --reserve-vram 3
```

Do **not** add `--disable-pinned-memory` either: on this ROCm build it stalls dynamic-VRAM staging entirely (a 512px, 8-step SDXL job hung >10 min at "prepared for dynamic VRAM loading"). Pinned memory is a *ceiling* (~14.8 GB max); under `NORMAL_VRAM` only the live working set (~7–9 GB for SDXL fp16) is pinned during a job and released afterward. The safety comes from `NORMAL_VRAM` + `--reserve-vram`, not from disabling pinning.

One server at a time on port 8188; verify with `tools/comfy.py` before starting another. After generation, VRAM should fall back near the ~2.4 GB desktop baseline; if it stays high, the wrong flags were used.

No existing user project files or global OMP settings were changed. No generated asset, workflow, or model license is claimed.

## Governance and ledgers (2026-11-04)

Repository governance follows the continuity-controlled approach established for
*The Twentieth Revision*: decisions and established state live in [`ops/DECISIONS.md`](ops/DECISIONS.md);
document provenance lives in the append-only [`ops/CHANGELOG.md`](ops/CHANGELOG.md); corrections
are appended, never silently rewritten; evidence is kept separate from interpretation.
`README.md` remains the Level-1 operational policy. The DynamicVRAM reconciliation
(which configuration actually failed, with the full failure matrix and primary-evidence
citations) is in [`ops/DYNAMICVRAM-EVIDENCE.md`](ops/DYNAMICVRAM-EVIDENCE.md). Status as of
2026-11-04: no configuration has completed a generation yet; the first successful job is
the pending validation step, gated on idle or explicit authorization.

## In-job resource monitoring (2026-11-04)

Launch generation jobs under the guard — it samples RAM/VRAM/swap-trend/PSI every 15 s,
checks kernel GPU-fault signatures once per minute, and on breach performs ComfyUI's
graceful `POST /interrupt`, logs to `ops/guard-events.log`, and exits. It is per-job,
not a daemon:

```sh
python3 tools/comfy.py submit workflows/kip_concept_sdxl_api.json
tools/comfy_guard.sh --max-minutes 45
python3 tools/comfy.py wait <prompt_id> --timeout 900 --output artifacts/comfy
```

Manual cancellation remains `python3 tools/comfy.py cancel`. The guard never queues,
retries, or restarts work; on a breach, do not queue new work until `tools/resmon.sh`
passes.