#!/usr/bin/env python3
# Rig a generated (ComfyUI/Hunyuan3D) GLB with the FACTORY skeleton + clips for a
# character, so bone names, clip names and scale match the runtime exactly.
# Usage: blender --background --python tools/rig_generated_with_factory.py -- \
#   --char jayze --glb IN.glb --ref REFIMAGE.png --out OUT.glb [--render DIR]
import bpy, sys, os, json
import numpy as np
from mathutils import Vector
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools"))

def argval(f, d=None):
    a = sys.argv
    return a[a.index(f) + 1] if f in a else d

CHAR = argval('--char'); IN = argval('--glb'); OUT = argval('--out')
REF = argval('--ref'); RENDER_DIR = argval('--render')
sys.path.insert(0, os.path.abspath('tools'))
import build_combat_assets as F

def wipe():
    bpy.ops.object.select_all(action='DESELECT')
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

# 1) factory rig: skeleton + clips + canonical bbox
wipe()
builder = getattr(F, f"build_{CHAR}")
rig = builder()
rig.finish()  # builds factory mesh (for bbox + material slots only, deleted after)
bpy.context.scene.frame_set(0)
bb = [rig.mesh_obj.matrix_world @ Vector(c) for c in rig.mesh_obj.bound_box]
dims = [(max(p[i] for p in bb) - min(p[i] for p in bb)) for i in range(3)]
zmin = min(p.z for p in bb)
print(f"FACTORY[{CHAR}] dims(x,y,z)={tuple(round(d,3) for d in dims)} zmin={round(zmin,3)}")
bpy.data.objects.remove(rig.mesh_obj, do_unlink=True)   # keep armature + actions
amo = rig.obj

# 2) import generated mesh
wipe_keep = [amo]
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.import_scene.gltf(filepath=IN)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o not in wipe_keep]
for m in meshes:
    m.parent = None
bpy.ops.object.select_all(action='DESELECT')
for m in meshes:
    m.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
mo = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# hole audit + repair
import bmesh
def audit(tag):
    bm = bmesh.new(); bm.from_mesh(mo.data)
    b = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    mu = sum(1 for e in bm.edges if len(e.link_faces) > 2)
    print(f"AUDIT[{tag}] verts={len(bm.verts)} tris={len(bm.faces)} boundary={b} multi_face={mu}")
    bm.free(); return b
audit('as_imported')
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.mesh.dissolve_degenerate()
bpy.ops.object.mode_set(mode='OBJECT')
dec = mo.modifiers.new("Decimate", 'DECIMATE')
target = 55000
dec.ratio = max(0.05, min(1.0, target / max(1, len(mo.data.polygons))))
bpy.ops.object.modifier_apply(modifier="Decimate")
bm = bmesh.new(); bm.from_mesh(mo.data)
bmesh.ops.holes_fill(bm, edges=[e for e in bm.edges if len(e.link_faces) == 1], sides=0)
bm.to_mesh(mo.data); bm.free()
holes = audit('after_repair')
if holes > 500:
    print("WARNING_HOLES_REMAIN", holes)

# normalize to factory bbox: scale by matching max dim, ground z, center xy
bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
mo.location = (0, 0, mo.location.z)
bpy.ops.object.transform_apply(location=True)
gb = [mo.matrix_world @ Vector(c) for c in mo.bound_box]
gdims = [(max(p[i] for p in gb) - min(p[i] for p in gb)) for i in range(3)]
s = max(dims) / max(gdims)
mo.scale = (s, s, s)
bpy.ops.object.transform_apply(scale=True)
gb = [mo.matrix_world @ Vector(c) for c in mo.bound_box]
mo.location.z -= min(p.z for p in gb) - zmin
bpy.ops.object.transform_apply(location=True)
print(f"NORMALIZED scale={round(s,4)} ground aligned to factory zmin={round(zmin,3)}")

# colorize from reference (palette projection, front view)
if REF:
    img = bpy.data.images.load(REF)
    iw, ih = img.size
    px = np.array(img.pixels[:]).reshape(ih, iw, 4)
    bbv = np.array([tuple(mo.matrix_world @ v.co) for v in mo.data.vertices])
    x0, x1 = bbv[:, 0].min(), bbv[:, 0].max()
    z0, z1 = bbv[:, 2].min(), bbv[:, 2].max()
    bm = bmesh.new(); bm.from_mesh(mo.data)
    samples = []
    for f in bm.faces:
        c = mo.matrix_world @ f.calc_center_median()
        u = int(min(1, max(0, (c.x - x0) / (x1 - x0))) * (iw - 1))
        v = int(min(1, max(0, (c.z - z0) / (z1 - z0))) * (ih - 1))
        samples.append(px[v, u][:3])
    S = np.array(samples)
    q = (S * 6).astype(int)
    keys = q[:, 0] * 36 + q[:, 1] * 6 + q[:, 2]
    uniq, counts = np.unique(keys, return_counts=True)
    top = uniq[np.argsort(counts)[::-1][:10]]
    pal = np.array([[(k // 36) / 5.999, ((k // 6) % 6) / 5.999, (k % 6) / 5.999] for k in top])
    asg = ((S[:, None, :] - pal[None, :, :]) ** 2).sum(-1).argmin(1)
    mo.data.materials.clear()
    for mi, col in enumerate(pal):
        m = bpy.data.materials.new(f"p_{CHAR}_{mi}")
        m.use_nodes = True
        bsdf = m.node_tree.nodes["Principled BSDF"]
        mask = asg == mi
        rgb = (S[mask].mean(0).tolist() if mask.any() else pal[mi].tolist()) + [1.0]
        bsdf.inputs["Base Color"].default_value = rgb
        bsdf.inputs["Roughness"].default_value = 0.6
        mo.data.materials.append(m)
    bm2 = bmesh.new(); bm2.from_mesh(mo.data)
    for i, f in enumerate(bm2.faces):
        f.material_index = int(asg[i])
    bm2.to_mesh(mo.data); bm2.free()
    bm.free()
    bpy.data.images.remove(img)
    print(f"COLORIZED palette={len(pal)}")

# auto weights
mo.select_set(True); amo.select_set(True)
bpy.context.view_layer.objects.active = amo
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
print("VERTEX_GROUPS", sorted(v.name for v in mo.vertex_groups)[:20])

# QA render
if RENDER_DIR:
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_WORKBENCH'
    scn.display.shading.color_type = 'MATERIAL'
    scn.render.resolution_x = scn.render.resolution_y = 512
    H = max(dims)
    for tag, (x, y, z) in {"front": (0, -2.4, 0.55), "threeq": (1.7, -1.7, 0.7)}.items():
        cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("c", cam)
        scn.collection.objects.link(co); scn.camera = co
        cz = zmin + 0.55 * dims[2]
        co.location = (x * (0.6 + H), y * (0.6 + H), cz)
        d = Vector((0, 0, cz)) - co.location
        co.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        cam.lens = 50
        scn.render.filepath = f"{RENDER_DIR}/{CHAR}_{tag}.png"
        bpy.ops.render.render(write_still=True)
        print("RENDER", scn.render.filepath)

# export (armature carries the factory clips; ACTIONS mode emits them)
bpy.ops.object.select_all(action='DESELECT')
amo.select_set(True); mo.select_set(True)
bpy.context.view_layer.objects.active = amo
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True,
                          export_animation_mode='ACTIONS', export_yup=True)
print("EXPORTED", OUT)
