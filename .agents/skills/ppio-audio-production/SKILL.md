---
name: ppio-audio-production
description: Original music/SFX production for PPIO — procedural synthesis, looping, buses, and gameplay event sync. Use when creating or integrating audio, adjusting the battle theme, SFX, stingers, or mixing.
---

# PPIO audio production

All combat audio is ORIGINAL, procedurally authored by `tools/build_audio.py` (numpy synthesis + ffmpeg libvorbis). Rebuild deterministically: `python3 tools/build_audio.py` → writes `assets/audio/*.ogg`. Never import third-party samples without a rights check (repo is public).

## Authoring conventions
- `env(n, attack, release, shape)` clamps attack/release to buffer length (longer releases crash broadcasting); `wrap_loop()` folds the tail into the head for click-free loops — required for combat theme (A minor, 140 BPM, 16 bars) and ambience (8s) so OGG `loop=true` stays seamless.
- Stingers: encounter (riser+hit), victory (rising triad), defeat (descending minor). ~29 SFX incl. ui_move/confirm/cancel/deny/open/close/target/party/pause + per-toy cues.

## Integration contract
- `scripts/audio_manager.gd` (Audio autoload): `SFX_PATHS`/`MUSIC` dicts — load only if `ResourceLoader.exists` (missing files never crash gameplay); pool of 10 UI/SFX 2D players + 10 3D players (unit_size 14); `ui()/sfx()/sfx_at()` fire-and-forget with pool steal; `play_music(key, fade)` dual-player crossfade; `start_ambience/stop_ambience`.
- Buses in `default_bus_layout.tres`: Master/Music/SFX/UI/Ambience; `game_settings.gd` applies volumes/mutes and persists user://settings.cfg.
- Sync: attack impact moments are fractions of each clip (battle_director IMPACT_AT) — when retiming an animation, update IMPACT_AT + ATTACK_SFX together so SFX/VFX stay on the impact, and keep rules.gd untouched (audio is presentation only).

## Untested
Physical listening test on speakers/headphones and 21:9 audio placement remain REPORTED-ONLY (docs/COMBAT_SLICE_REPORT.md).
