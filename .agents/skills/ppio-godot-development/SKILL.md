---
name: ppio-godot-development
description: Working on the Playtime Protocol Godot 4.7.2 project — scenes, GDScript, controller InputMap, HUD, battle runtime, and validation. Use when editing scripts/scenes, debugging the combat slice, or running project tests.
---

# PPIO Godot development

Engine: Godot 4.7.2 mono at `$GODOT` = /home/rolaandjayz/tools/godot-4.7.2-mono/Godot_v4.7.2-stable_mono_linux_x86_64/Godot_v4.7.2-stable_mono_linux.x86_64. Project root: this repository. Never create a replacement project.

## Authority and rules
- Read `.goosehints`, `AGENTS.md`, `CONTRIBUTING.md` first. Ordered rules: (1) non-destructive/repo rules, (2) user/machine first, (3) get it done (never overrides 1-2).
- `scripts/battle_rules.gd` (BattleRules, RefCounted) is the ONLY combat authority. Presentation scripts (battle_director/unit_view/battle_hud) must never change outcomes; enemy turns are planned (`plan_enemy_phase`) then applied stepwise (`apply_enemy_step`) at the visual impact moment.

## Layout (combat slice)
- `scripts/battle_rules.gd` rules; `scripts/battle_director.gd` scene orchestrator/modes; `scripts/unit_view.gd` rigs+animation+sockets; `scripts/battle_hud.gd` controller UI; `scripts/battle_camera.gd`; `scripts/battle_vfx.gd`; `scripts/audio_manager.gd` (Audio autoload); `scripts/game_settings.gd` (Settings autoload); `scenes/encounter.tscn` (main).
- InputMap lives in `project.godot` (`battle_confirm`, `battle_cancel`, `battle_menu`, `battle_ability`, `party_next/prev`, `pause`, `move_*`, `cam_*`, `cam_zoom_*`). Controller-first; keyboard fully supported. See docs/CONTROLS.md.

## Editor integration (godot-mcp)
- Shared server: run `ops/goose/godot_mcp_server.sh start`, then enable the `godot` extension (streamable_http → http://127.0.0.1:9006/mcp) via extension manager only while needed; disable afterwards. Server version must stay 2026.10.20.1 to match `addons/godot_mcp/`.
- Inspection toolset is on by default (scene tree, project info incl. InputMap + autoloads). Enable more toolsets (e.g. scene_edit) only for the task at hand, and preserve unsaved editor work — never force-kill a desktop editor that may hold changes; headless editors (`--headless --editor`) are safe to stop.

## Validation (run after any change)
```
$GODOT --headless --path . --script tests/battle_smoke.gd      # deterministic rules
$GODOT --headless --path . --script tests/slice_integration.gd  # full battle loop
```
Rendered UI captures (needs display): tests/hud_capture.gd → artifacts/captures/. Keep docs/COMBAT_SLICE_REPORT.md truthful: mark VERIFIED vs REPORTED-ONLY explicitly.

## GDScript pitfalls in this codebase
Type-inference from Dictionary access fails under strict checks — annotate explicitly (`var dmg: int`, `var dest: Vector2i`). CanvasLayer has no `theme`; assign the shared Theme to each root Control. Await `unit_view.await_clip()`/`play_then_idle` for animation sync; do not invent parallel timers for the same event.
