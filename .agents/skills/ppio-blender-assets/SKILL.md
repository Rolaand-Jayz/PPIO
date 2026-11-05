---
name: ppio-blender-assets
description: Building/rigging/animating PPIO characters and props in headless Blender 4.5 and exporting GLB for Godot. Use when creating or editing assets, rigs, animations, sockets, or the deterministic asset factory.
---

# PPIO Blender assets

Headless Blender 4.5.12 LTS at `blender` (~/.local/bin/blender). The deterministic factory `tools/build_combat_assets.py` is the source of truth for the 7 combat characters + arena; it rebuilds everything identically (edit the script, rebuild, never hand-tweak exported GLBs). Rebuild + regenerate manifest:

```
blender --background --python tools/build_combat_assets.py   # writes assets/*.glb
python3 tools/build_manifest.py                              # refresh checksums/provenance
```

## Factory conventions (Rig class)
- Primitives: `rig.bone()`, `rig.mat()`, `rig.box()/cyl()/sphere()` appended as parts, each weighted 1.0 to one bone (toy-segment style). Vertex groups live on the OBJECT (`obj.vertex_groups`), not Mesh data.
- Animations: author in OBJECT mode (`animation()` enforces it); one action per clip + fake user + muted NLA track so the glTF exporter emits named clips.
- Export: `bpy.ops.export_scene.gltf(filepath=..., export_format='GLB', export_animation_mode='ACTIONS', use_selection=True)` — the `.glb` operator does NOT exist in this build; `addon_utils.enable('io_scene_gltf2')` first. Select BOTH armature and mesh or Godot imports meshes=0.
- Sockets: bones named `Socket_*` (Socket_Weapon, Socket_Muzzle, Socket_Pounder); Godot finds them via `find_children('*', 'Skeleton3D')` + `socket_pos()`.
- Mechanical rigs: Kip is a vehicle (wheels/steering/turret, wheel spin driven by real travel in `unit_view.gd`, circumference constant); Jonnie heavy exoskeleton; enemies get role-specific telegraph clips (wind-up Key, plate fists, gimbal ring).

## Godot import contract
GLB → inherited scene with Skeleton3D + AnimationPlayer; loop set in unit_view (LOOPING list); impact timing fractions live in `battle_director.gd IMPACT_AT`; SFX map `ATTACK_SFX`. After changing clips, verify names still match what director/unit_view reference.

## Additive (interactive) work — mcp-for-blender, currently UNTESTED/disabled
`mcp-for-blender` (PyPI; formerly blender-mcp) could add live-editor modeling for owner-supervised art sessions, but requires its addon + a running Blender GUI. Keep disabled for automated work; if enabled later, review its addon code first and keep PolyHaven/Hyper3D/other third-party services OFF. The scripted pipeline above remains authoritative and reproducible.
