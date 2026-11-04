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

No existing user project files or global OMP settings were changed. No generated asset, workflow, or model license is claimed.