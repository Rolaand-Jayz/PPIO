# Mandatory rigging and animation — combat test

**Approved scope:** Production-quality, mechanically valid rigs and animations for the complete combat test, using expressly NON-FINAL visual designs. No new canon, campaign pacing or contributor policy is authorized here.

## Every character and enemy needs a working rig
For all four party members and each of the 2–3 test enemies, reuse an existing functional rig if present; otherwise deliver a character-appropriate articulated rig, rather than one generic auto-rig. Export editable Blender source (.blend), valid Godot-ready glTF/.glb with correctly named bones/parts, reasonable deform weights, sockets, applied transforms, pivots, materials and required clips. Preserve all source and rig/clip mapping metadata for controlled asset replacement.

**Jayze:** humanoid toy-action-figure joints, weapon hand/tip/impact origin, agile legible melee movement.
**Kip:** VEHICLE rig, not humanoid; separate body root, wheels, steering axle, chassis pitch/suspension and mounted weapon sockets. Wheel rotation corresponds to distance travelled.
**Rallo:** compact gargoyle rig, wings and limbs as needed, limited hover/landing and lower-body clearance.
**Captain Crusher/Jonnie:** heavy articulated soldier figure, properly constrained exoskeleton joints/plates, appropriate guard/assist/strike sockets. No drifting armor pieces.
**Enemies:** fitting toy/proxy rigs with clear distinct melee/ranged/pressure attack tells. These are not canonical Unknown designs.

## Required animation coverage
Party: idle/ready; locomotion/turn/stop; basic attack with readable windup, active strike and recovery; one representative class-defining move; guard/defense (evade where implemented); hit/stagger; downed/defeat; victory/return; relevant entrance/switch transitions. Enemies: idle, move when needed, telegraphed attack, hit/stagger, defeat and any role-specific ability. Mechanically driven/procedural movement is appropriate for Kip, hovering and armor parts.

Use animation state machines / Godot AnimationPlayer and AnimationTree (or the existing equivalent), blend transitions and handle cancel/interruption/repeated attacks. Connect attacks to existing deterministic combat events; gameplay state remains authoritative for damage and timing. Create reliable timing markers or equivalent signals for telegraph, active/hit, projectile/spawn, impact, VFX, SFX and recovery. No duplicate hits on blends/loops. Test root motion versus authored movement, collision, foot/wheel contacts, scale and camera-distance readability.

## Asset and pipeline QA — must pass
R0: rig hierarchy, required joints/sockets, rest pose and hierarchy valid; sources and export repeatable.
R1: deform weights and toy mechanical joints are stable at extreme poses; no detached plates, wheel sliding or overdeformation.
R2: all necessary clips and procedural motions run inside real Godot combat transitions, not only Blender.
R3: interrupts, blend, party switch, rapid input and repeated actions work without freezing in rest/T-pose or losing hit/SFX cues.
R4: attack tell, hit frame, active damage event, VFX and sound agree with combat logic; silhouettes remain legible with HUD on.
R5: proxy can be replaced without destroying Godot controllers, battle rules, sockets or animation mappings; retain source provenance.

**Not complete:** static beautiful meshes; animation previews that never trigger in combat; automatic rigging without deformation QA; broken Godot exports; unsynchronized attack/audio/hit feedback.

## Tooling and safety
Prefer existing Blender and ComfyUI tooling, reuse already-created work; rig deterministically in Blender or animate procedurally when that is more appropriate than generation. If ComfyUI is unstable, continue non-GPU rigging/animation. Observe existing memory guards, active-user idle policy, public-repo asset-license/privacy restrictions. Work on the combat slice only; broad campaign standards remain a separate owner discussion.
