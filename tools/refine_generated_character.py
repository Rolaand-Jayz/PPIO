#!/usr/bin/env python3
# Blender headless: fine-tune + rig a ComfyUI/Hunyuan3D generated GLB into a
# PPIO combat-slice character. Usage:
#   blender --background --python tools/refine_generated_character.py -- \
#     --glb IN.glb --out OUT.glb --name Jayze --height 1.1 --char jayze [--render DIR]
# Keeps factory bone names + clip names so scripts/unit_view.gd and
# scripts/battle_director.gd work unchanged. Preserves input; writes only --out.
import bpy, sys, math, json, os
import numpy as np
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def argval(flag, default=None):
    a = sys.argv
    return a[a.index(flag) + 1] if flag in a else default

IN = argval('--glb'); OUT = argval('--out'); NAME = argval('--name', 'Char')
HEIGHT = float(argval('--height', '1.1')); CHAR = argval('--char', 'jayze')
RENDER_DIR = argval('--render')

# ---------------------------------------------------------------- clean scene
bpy.ops.object.select_all(action='DESELECT')
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

# ---------------------------------------------------------------- import
bpy.ops.import_scene.gltf(filepath=IN)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
print(f"IMPORTED {IN}: {len(meshes)} mesh objects")
bpy.ops.object.select_all(action='DESELECT')
for m in meshes:
    m.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
mo = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# ---------------------------------------------------------------- audit + repair
def audit(tag):
    if bpy.context.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    import bmesh
    bm = bmesh.new(); bm.from_mesh(mo.data)
    boundary = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    multi = sum(1 for e in bm.edges if len(e.link_faces) > 2)
    verts, tris = len(bm.verts), len(bm.faces)
    bm.free()
    print(f"AUDIT[{tag}] verts={verts} tris={tris} "
          f"boundary(hole)_edges={boundary} multi_face_edges={multi}")
    return boundary

audit('as_imported')

# targeted repair: merge, degenerate cleanup, decimate, then fill small holes
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.mesh.dissolve_degenerate()
bpy.ops.object.mode_set(mode='OBJECT')
dec = mo.modifiers.new("Decimate", 'DECIMATE')
dec.ratio = 0.25
bpy.ops.object.modifier_apply(modifier="Decimate")
print("DECIMATED to", len(mo.data.polygons), "tris")
bpy.ops.object.mode_set(mode='OBJECT')
# authoritative hole fill via bmesh (any size), then report
import bmesh
bm = bmesh.new(); bm.from_mesh(mo.data)
hole_edges = [e for e in bm.edges if len(e.link_faces) == 1]
bmesh.ops.holes_fill(bm, edges=hole_edges, sides=0)
bm.to_mesh(mo.data); bm.free()
if audit('after_repair') > 500:
    print("WARNING_HOLES_REMAIN see audit above")

# ---------------------------------------------------------------- normalize
bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
mo.location = (0, 0, mo.location.z)          # center x/y at origin
bpy.ops.object.transform_apply(location=True)
bb = [mo.matrix_world @ Vector(cor) for cor in mo.bound_box]
zs = [p.z for p in bb]
h = max(zs) - min(zs)
s = HEIGHT / h
mo.scale = (s, s, s)                          # scale about current origin
bpy.ops.object.transform_apply(scale=True)
bb = [mo.matrix_world @ Vector(cor) for cor in mo.bound_box]
zs = [p.z for p in bb]
mo.location.z -= min(zs)                      # feet on z=0
bpy.ops.object.transform_apply(location=True)
print(f"NORMALIZED height={HEIGHT} feet=0 center xy=0")

# ---------------------------------------------------------------- leg centers (numpy slice)
me = mo.data
V = np.array([[v.co.x, v.co.z] for v in me.vertices])  # x, height
H = HEIGHT
band = V[(V[:, 1] > 0.10 * H) & (V[:, 1] < 0.28 * H) & (abs(V[:, 0]) < 0.25 * H)]
hist, edges = np.histogram(band[:, 0], bins=40, range=(-0.25 * H, 0.25 * H))
# central clusters: prefer smallest |x|, keep separated picks
centers = []
idx = np.argsort(hist)[::-1]
for i in idx:
    if hist[i] < max(hist.max() * 0.2, 5):
        break
    cx = (edges[i] + edges[i + 1]) / 2
    if all(abs(cx - c2) > 0.06 * H for c2 in centers):
        centers.append(cx)
centers.sort(key=abs)
legx = sorted(centers[:2]) if len(centers) >= 2 else [-0.075 * H, 0.075 * H]
print(f"LEG_CENTERS x={legx}")

# ---------------------------------------------------------------- color quantization
REF = argval('--refimage')
if REF:
    import bmesh
    img = bpy.data.images.load(REF)
    iw, ih = img.size
    px = np.array(img.pixels[:]).reshape(ih, iw, 4)  # rgba, bottom-up
    me = mo.data
    bm = bmesh.new(); bm.from_mesh(me)
    bbv = np.array([tuple(mo.matrix_world @ v.co) for v in bm.verts])
    x0, x1 = bbv[:, 0].min(), bbv[:, 0].max()
    z0, z1 = bbv[:, 2].min(), bbv[:, 2].max()
    samples = []
    for f in bm.faces:
        c = f.calc_center_median()
        wx, wz = (mo.matrix_world @ c).x, (mo.matrix_world @ c).z
        # 3/4 front reference: project x,z; nudge u by depth toward view axis
        u = int((wx - x0) / (x1 - x0) * (iw - 1))
        v = int((wz - z0) / (z1 - z0) * (ih - 1))
        samples.append(px[v, u][:3])
    bm.free()
    S = np.array(samples)
    # palette: top bins of quantized colors
    q = (S * 6).astype(int)
    keys = q[:, 0] * 36 + q[:, 1] * 6 + q[:, 2]
    uniq, counts = np.unique(keys, return_counts=True)
    top = uniq[np.argsort(counts)[::-1][:10]]
    pal = np.array([[(k // 36) / 5.999, ((k // 6) % 6) / 5.999, (k % 6) / 5.999] for k in top])
    dist = ((S[:, None, :] - pal[None, :, :]) ** 2).sum(-1)
    asg = dist.argmin(1)
    me.materials.clear()
    slot_of = {}
    for mi, col in enumerate(pal):
        m = bpy.data.materials.new(f"p_{mi}")
        m.use_nodes = True
        bsdf = m.node_tree.nodes["Principled BSDF"]
        rgb = pal[mi].tolist() + [1.0]
        # sample average real color of the bin (pre-quantization mean)
        mask = asg == mi
        if mask.any():
            rgb = S[mask].mean(0).tolist() + [1.0]
        bsdf.inputs["Base Color"].default_value = rgb
        bsdf.inputs["Roughness"].default_value = 0.6
        me.materials.append(m)
        slot_of[mi] = mi
    # per-face material index via bmesh order (faces iterate same order)
    bm = bmesh.new(); bm.from_mesh(me)
    for i, f in enumerate(bm.faces):
        f.material_index = int(asg[i])
    bm.to_mesh(me); bm.free()
    print(f"COLORIZED palette={len(pal)} from {REF}")
    bpy.data.images.remove(img)

# ---------------------------------------------------------------- skeleton (factory names)
def bone(amd, name, head, tail, parent=None, roll=0.0):
    b = amd.edit_bones.new(name)
    b.head, b.tail, b.roll = head, tail, roll
    if parent:
        b.parent = amd.edit_bones[parent]
        b.use_connect = False
    return b

bpy.ops.object.armature_add()
amo = bpy.context.view_layer.objects.active
amo.name = NAME + "_rig"
amo.display_type = 'WIRE'
bpy.ops.object.mode_set(mode='EDIT')
amd = amo.data
amd.edit_bones.clear() if False else None
for b in list(amd.edit_bones):
    amd.edit_bones.remove(b)
S, E, W, P, K = 0.78 * H, 0.60 * H, 0.46 * H, 0.50 * H, 0.26 * H
SX = 0.16 * H
bone(amd, "Root", (0, 0, 0), (0, 0, 0.1 * H))
bone(amd, "Hips", (0, 0, 0.42 * H), (0, 0, 0.52 * H), "Root")
bone(amd, "Torso", (0, 0, 0.52 * H), (0, 0, 0.80 * H), "Hips")
bone(amd, "Head", (0, 0, 0.86 * H), (0, 0, 1.02 * H), "Torso")
bone(amd, "ArmL", (-SX, 0, S), (-SX, 0, E), "Torso")
bone(amd, "ForearmL", (-SX, 0, E), (-SX, 0, W), "ArmL")
bone(amd, "ArmR", (SX, 0, S), (SX, 0, E), "Torso")
bone(amd, "ForearmR", (SX, 0, E), (SX, 0, W), "ArmR")
bone(amd, "HandR", (SX, 0, W), (SX, 0, W - 0.07 * H), "ForearmR")
bone(amd, "Socket_Weapon", (SX, -0.28 * H, W - 0.02 * H), (SX, -0.28 * H, W + 0.08 * H), "HandR")
bone(amd, "LegL", (legx[0], 0, 0.42 * H), (legx[0], 0, 0.22 * H), "Hips")
bone(amd, "LegR", (legx[1], 0, 0.42 * H), (legx[1], 0, 0.22 * H), "Hips")
bpy.ops.object.mode_set(mode='OBJECT')

# ---------------------------------------------------------------- heat weights
mo.select_set(True)
amo.select_set(True)
bpy.context.view_layer.objects.active = amo
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
vg = sorted(v.name for v in mo.vertex_groups)
print("VERTEX_GROUPS", vg)

# ---------------------------------------------------------------- clips (factory-portable)
FPS = bpy.context.scene.render.fps
def animation(rig, clip, keys, length_s, non_loop=False):
    if rig.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    ad = rig.animation_data_create()
    prev = ad.action
    act = bpy.data.actions.new(clip); act.use_fake_user = True
    ad.action = act
    for bname, chans in keys.items():
        pb = rig.pose.bones[bname]
        for f, rot in chans.get('rot', []):
            pb.rotation_euler = rot; pb.keyframe_insert("rotation_euler", frame=f)
        for f, loc in chans.get('loc', []):
            pb.location = loc; pb.keyframe_insert("location", frame=f)
    tr = ad.nla_tracks.new(); tr.name = clip
    tr.strips.new(clip, int(act.frame_range[0]), act); tr.mute = True
    ad.action = prev
D = lambda d: max(2, round(d * FPS))
Kip = None
if CHAR == 'jayze':
    from build_clips_jayze import CLIPS
    for name, spec in CLIPS.items():
        animation(amo, name, {b: {k: [(D(f), v) for f, v in fs] for k, fs in ch.items()}
                              for b, ch in spec['keys'].items()},
                  spec['len'], spec.get('non_loop', False))
    print("CLIPS", [a.name for a in bpy.data.actions if a.use_fake_user])

# ---------------------------------------------------------------- QA renders
if RENDER_DIR:
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_WORKBENCH'
    scn.display.shading.light = 'STUDIO'; scn.display.shading.color_type = 'TEXTURE'
    scn.render.resolution_x = scn.render.resolution_y = 512
    scn.render.film_transparent = False
    w = bpy.data.worlds.new("w"); scn.world = w
    for tag, (x, y, z) in {"front": (0, -2.4, 0.55), "threeq": (1.7, -1.7, 0.7)}.items():
        cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("c", cam)
        scn.collection.objects.link(co); scn.camera = co
        co.location = (x, y, z * H + 0.05)
        d = Vector((0, 0, 0.55 * H)) - co.location
        co.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        cam.lens = 45
        scn.render.filepath = f"{RENDER_DIR}/{NAME.lower()}_{tag}.png"
        bpy.ops.render.render(write_still=True)
        print("RENDER", scn.render.filepath)

# ---------------------------------------------------------------- export
bpy.ops.object.select_all(action='DESELECT')
amo.select_set(True); mo.select_set(True)
bpy.context.view_layer.objects.active = amo
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True,
                          export_animation_mode='ACTIONS', export_yup=True)
print("EXPORTED", OUT)
