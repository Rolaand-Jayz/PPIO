# PPIO Goose Toolchain — Specialization (2026-11-05)

Specialized harness for Playtime Protocol: Innocence Lost, per owner assignment
"GOOSE — SPECIALIZE YOURSELF FOR PLAYTIME PROTOCOL" and the canonical rules in
`.goosehints` / `AGENTS.md` / `CONTRIBUTING.md` / `docs/governance/`.

Status legend: VERIFIED = proven on real PPIO work this machine. UNTESTED = installed/
documented but not exercised. REJECTED = evaluated and declined (with reason).

## Components

| Component | Decision | Status |
|---|---|---|
| Goose Desktop/CLI 1.57.0 (existing) | reused; native dev/skills/summon/extension-mgr/chatrecall/memory in use, no new global extensions loaded by default | VERIFIED (daily use) |
| godot-editor-mcp **2026.10.20.1 stable** (`uv tool install`, pinned; beta 2026.11.04b2 declined — assignment says stable unless beta solves a proven 4.7.2 problem) | adopted; addon vendored at `addons/godot_mcp/` (MIT, zero external endpoints, only 127.0.0.1 bridge), plugin enabled in `project.godot` | VERIFIED: initialize + 24 gated tools (core+inspection); live scene list, project info (autoloads + all 17 PPIO InputMap actions), live scene tree via real editor; chain proven through goose itself (`goose run` → streamable_http → server → bridge → editor addon) |
| Shared godot-mcp server (`ops/goose/godot_mcp_server.sh`) | one long-lived HTTP-mode server: MCP at http://127.0.0.1:9006/mcp, addon bridge ws://127.0.0.1:9080; any number of editor instances (desktop or headless) attach by reconnect | VERIFIED: start/status idempotent; survived 9h; headless editor attach on first poll |
| `godot` extension in user config (`~/.config/goose/config.yaml`) | `type: streamable_http`, `enabled: false` — OFF by default so normal sessions load zero godot tools; workflows enable it via extension manager only while needed | VERIFIED (enabled→goose run→disabled cycle) |
| Skills ×6 (`.agents/skills/ppio-*`) | godot-development, blender-assets, comfy-production, audio-production, story-continuity, quality-and-originality — compact, linking authoritative docs; repo is source of truth | VERIFIED: `goose skills list` discovers all 6 (via per-machine symlinks into `~/.agents/skills/`, which are NOT committed) |
| Recipes ×5 (`recipes/ppio-*.yaml`) | build-feature, build-asset, combat-gameplay, quality-review (escalation model), checkpoint-resume; run via `goose run --recipe recipes/<file>.yaml` | VERIFIED: all 5 pass `goose recipe validate`; checkpoint-resume exercised live (see CHANGELOG) |
| Model routing | default `zai` / `glm-5.3-flash` (already the active provider+model); escalation `zai` / `glm-5.3` — BOTH verified with live one-shot calls; escalation used only in quality-review recipe settings; GLM-5.5 NOT automatic (owner decision) | VERIFIED |
| GitHub MCP | REJECTED — `gh` CLI authenticated (repo scope) + native git sufficient; duplicate tooling | n/a |
| Beads | REJECTED — ops/DECISIONS.md + ops/CHANGELOG.md remain the single source of truth | n/a |
| Comfy MCP (Comfy-Org/comfy-mcp) | REJECTED for now — it manages its own ComfyUI lifecycle, conflicting with tools/comfy.py + comfy_start.sh + comfy_guard.sh + DynamicVRAM policy; revisit only with owner approval | UNTESTED (by design) |
| Blender MCP (mcp-for-blender) | left disabled — headless scripted factory (tools/build_combat_assets.py) is authoritative + reproducible; mcp-for-blender kept as option for owner-supervised interactive art sessions (requires addon code review, third-party services OFF, GUI Blender) | UNTESTED (by design) |
| MCP Apps | deferred — optional, must not delay game dev | UNTESTED |

## godot-mcp operating notes
- Version pin is contractual: server 2026.10.20.1 ↔ addon 2026.10.20.1 (`addons/godot_mcp/`). Upgrade BOTH together, only with owner approval.
- Start server: `ops/goose/godot_mcp_server.sh start` (logs /tmp/ppio/godot_mcp_server.log). Stop: `... stop`.
- Editors: desktop or `--headless --editor`; addon reconnects automatically. NEVER force-kill a desktop editor that may hold unsaved work; headless test editors are safe to stop.
- Toolset gating: only core+inspection (24 tools) on by default; enable e.g. `scene_edit` per task, then disable. Undo/redo tools exist (`godot_undo`/`godot_redo`).
- Scene tree of the runtime-built battle shows only the scene-file root (children are built by battle_director.gd at runtime) — inspect scripts/tests for runtime structure, or run the game under the debug toolset.
- UNTESTED so far: scene_edit mutations, animation toolset reads, run/debug toolset (headless play), code analysis toolsets, screenshot/profile. Next real task should route through them and update this table.

## Model routing
- Everyday work: `zai` / `glm-5.3-flash` (session default). Verify: `GOOSE_PROVIDER=zai GOOSE_MODEL=glm-5.3-flash goose run --no-session -t ...`.
- Escalation (architecture, hard debugging, canon/safety reasoning): `zai` / `glm-5.3` — verified live. Recipes that need it declare `settings: {goose_provider: zai, goose_model: glm-5.3}`.
- Cost data: provider catalog in `~/.config/goose/custom_providers/custom_z.ai_coding_plan.json` (machine-local, contains costs; never commit).

## Rollback
- User config: `cp ~/.config/goose/config.yaml.bak-2026-11-05-pre-godot-mcp ~/.config/goose/config.yaml` (removes godot extension entry).
- Server/CLI: `uv tool uninstall godot-editor-mcp` + `ops/goose/godot_mcp_server.sh stop`.
- Project: revert the specialization commit(s) — addon dir, recipes/, skills, docs are all additive; `project.godot` change is the single modified tracked file (`[editor_plugins]` section only).
- Skills discovery: remove `~/.agents/skills/ppio-*` symlinks.
