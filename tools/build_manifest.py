#!/usr/bin/env python3
# Builds assets/asset-manifest.json per schemas/asset-manifest.schema.json.
# Run after (re)building assets: python3 tools/build_manifest.py
# All combat-slice content is status: proxy/provisional (non-final canon).

import hashlib
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def entry(asset_id, category, association, files, animation, attachments, notes):
    exp = files.get("export")
    return {
        "asset_id": asset_id,
        "category": category,
        "association": association,
        "reference": None,
        "source": {
            "workflow": None,
            "model": None,
            "model_version": None,
            "parameters": {"builder": "tools/build_combat_assets.py" if category in ("character", "environment") else "tools/build_audio.py",
                           "deterministic": True},
            "provenance": [
                "Authored procedurally (Blender 4.5 headless / numpy+ffmpeg synthesis) by goose-desktop 2026-11-05.",
                "Original content; no third-party or copyrighted sources; no dataset-trained generation used.",
            ],
        },
        "license": {
            "source": "project-original",
            "identifier": "AllRightsReserved-PlaytimeProtocol (project-internal, owner to finalize)",
            "commercial_use": "unknown",
            "evidence": "Original authorship within this repository; owner has not chosen a public license yet.",
        },
        "files": {
            "source": files.get("source"),
            "editable": files.get("editable"),
            "export": exp,
        },
        "transform": {"units": "meters", "up_axis": "Y", "scale": 1.0, "grid_cell": 1.0},
        "geometry": {"note": notes},
        "materials": [{"type": "flat-color principled (proxy look)"}],
        "animation": animation,
        "attachments": attachments,
        "collision": [],
        "processing_history": [
            {"tool": "blender", "version": "4.5.12 LTS", "operation": "headless build + glTF export (GLB, ACTIONS mode)", "timestamp": "2026-11-05T00:00:00Z"},
            {"tool": "godot", "version": "4.7.2 stable mono", "operation": "import validation (bones/anims/sockets/arena meshes)", "timestamp": "2026-11-05T00:00:00Z"},
        ],
        "validation": {"status": "pass", "checks": [
            "Godot load probe: skeleton bones present",
            "AnimationPlayer clips present with expected names",
            "Socket bones present",
        ]},
        "approval": "provisional",
        "version": "1.0.0",
        "checksums": {os.path.basename(exp): sha256(os.path.join(ROOT, exp)) for exp in [exp] if exp},
    }

PARTY_CLIPS = ["idle", "move", "attack", "ability", "guard", "hit", "defeat", "victory"]
entries = []

entries.append(entry("char_jayze", "character", "party — anime action-hero melee",
    {"source": None, "editable": "tools/build_combat_assets.py:build_jayze", "export": "assets/characters/jayze.glb"},
    PARTY_CLIPS, ["Socket_Weapon"], "humanoid toy rig, 12 bones, rigid toy-segment weights"))
entries.append(entry("char_kip", "character", "party — weaponized die-cast race car",
    {"source": None, "editable": "tools/build_combat_assets.py:build_kip", "export": "assets/characters/kip.glb"},
    PARTY_CLIPS + ["ram"], ["Socket_Muzzle"], "VEHICLE rig: steer pivots + axle wheel chain, chassis pitch, 10 bones"))
entries.append(entry("char_rallo", "character", "party — gargoyle low-hover brawler",
    {"source": None, "editable": "tools/build_combat_assets.py:build_rallo", "export": "assets/characters/rallo.glb"},
    PARTY_CLIPS, ["Socket_ClawR"], "winged compact rig with hover root animation, 14 bones"))
entries.append(entry("char_crusher", "character", "party — heavy exoskeleton soldier (Captain Crusher)",
    {"source": None, "editable": "tools/build_combat_assets.py:build_crusher", "export": "assets/characters/crusher.glb"},
    PARTY_CLIPS + ["brace"], ["Socket_Pounder"], "armored heavy rig: pauldrons/pack ride arm/torso bones, 12 bones"))
entries.append(entry("char_sprocket", "character", "enemy — wind-up chaser (close pressure)",
    {"source": None, "editable": "tools/build_combat_assets.py:build_sprocket", "export": "assets/characters/sprocket.glb"},
    ["idle", "move", "telegraph", "attack", "hit", "defeat"], ["Socket_Impact"], "wind-up key + punch telegraph, 9 bones"))
entries.append(entry("char_clanker", "character", "enemy — heavy slam bot",
    {"source": None, "editable": "tools/build_combat_assets.py:build_clanker", "export": "assets/characters/clanker.glb"},
    ["idle", "move", "telegraph", "attack", "hit", "defeat"], ["Socket_Impact"], "double-fist slam telegraph, loose chest plate, 9 bones"))
entries.append(entry("char_gimbal", "character", "enemy — ranged disc launcher",
    {"source": None, "editable": "tools/build_combat_assets.py:build_gimbal", "export": "assets/characters/gimbal.glb"},
    ["idle", "move", "telegraph", "attack", "hit", "defeat"], ["Socket_Muzzle"], "hover core + spinning gimbal ring + prong spread telegraph, 6 bones"))
entries.append(entry("arena_bedroom_floor", "environment", "combat test arena (noncanonical until approved)",
    {"source": None, "editable": "tools/build_combat_assets.py:build_arena", "export": "assets/characters/arena.glb"},
    [], [], "toy-scale diorama; vertex-color checker grid; obstacles at rules BLOCKED_CELLS; music box at MUSIC_BOX"))

AUDIO = [
    ("music_combat_theme", "audio", "assets/audio/music/combat_theme.ogg", "original loopable combat theme, A minor 140 BPM, 27.4s"),
    ("music_encounter_start", "audio", "assets/audio/music/encounter_start.ogg", "encounter stinger"),
    ("music_victory", "audio", "assets/audio/music/victory.ogg", "victory stinger"),
    ("music_defeat", "audio", "assets/audio/music/defeat.ogg", "defeat stinger"),
    ("ambience_room", "audio", "assets/audio/music/ambience.ogg", "room tone + music-box plinks, 8s loop"),
]
for name in ["ui_move", "ui_confirm", "ui_cancel", "ui_deny", "ui_open", "ui_close", "ui_target", "ui_party", "ui_pause",
             "jayze_attack", "jayze_ability", "kip_shoot", "kip_ram", "rallo_claw", "rallo_ability",
             "crusher_attack", "crusher_ability", "crusher_brace", "impact_light", "impact_heavy", "guard_block",
             "hit_react", "evade", "ko_down", "telegraph_warn", "enemy_attack", "projectile", "heal", "stagger"]:
    sub = "ui" if name.startswith("ui_") else "sfx"
    AUDIO.append(("sfx_" + name, "audio", "assets/audio/%s/%s.wav" % (sub, name), "original procedural cue, event-bound in scripts/audio_manager.gd"))

for asset_id, path, desc in [(a[0], a[2], a[3]) for a in AUDIO]:
    e = entry(asset_id, "audio", desc, {"source": None, "editable": "tools/build_audio.py", "export": path}, [], [], "synthesized; WAV masters / OGG runtime")
    e["transform"] = {"units": "seconds", "up_axis": "Y", "scale": 1.0}
    entries.append(e)

manifest = {
    "_meta": {
        "project": "Playtime Protocol: Innocence Lost — combat test slice",
        "schema": "../schemas/asset-manifest.schema.json",
        "status_note": "ALL entries are proxy/provisional (non-final canon). Regenerate via tools/build_combat_assets.py and tools/build_audio.py.",
        "generated": "2026-11-05",
    },
    "assets": entries,
}
out = os.path.join(ROOT, "assets", "asset-manifest.json")
with open(out, "w") as f:
    json.dump(manifest, f, indent=2)
print("MANIFEST", out, "entries:", len(entries))
