# Combat-slice asset factory — builds every battle character, the arena,
# and exports Godot-ready GLB. Runs headless:
#   blender --background --python tools/build_combat_assets.py -- --out assets
#
# Design rules:
# - Toy-segment skinning: each mesh part is weighted 1.0 to the bone that
#   articulates it (correct for manufactured toys; stable at extreme poses).
# - Every playable character gets an appropriate rig (Jayze humanoid, Kip
#   vehicle with steer+axle wheel chain, Rallo winged hover, Captain Crusher armored
#   heavy), enemies rigged for their role (no uniform skeletons).
# - Named clips per character, exported as separate glTF animations.
# - Deterministic: no random values; rebuild from scratch every run.
# All output is non-final proxy content (approval: provisional).

import bpy
import math
import sys
import os
from mathutils import Vector

FPS = 24

# ---------------------------------------------------------------- utilities

def reset_scene():
    bpy.ops.wm.read_homefile(use_empty=True)

def material(name, color, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.get(name)
    if mat:
        bpy.data.materials.remove(mat)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

class Rig:
    """Armature + single skinned mesh assembled from primitive parts."""

    def __init__(self, name):
        self.name = name
        arm = bpy.data.armatures.new(name + "_arm")
        self.obj = bpy.data.objects.new(name, arm)
        bpy.context.scene.collection.objects.link(self.obj)
        bpy.context.view_layer.objects.active = self.obj
        bpy.ops.object.mode_set(mode='EDIT')
        self.edit = arm
        self.bones = {}
        self.parts = []      # (verts_in_armature_space, faces, material, bone)
        self.mats = {}

    def bone(self, name, head, tail, parent=None):
        eb = self.edit.edit_bones.new(name)
        eb.head = head
        eb.tail = tail
        if parent:
            eb.parent = self.edit.edit_bones[parent]
        self.bones[name] = (Vector(head), Vector(tail))
        return eb

    def mat(self, name, color, metallic=0.0, roughness=0.55):
        if name not in self.mats:
            self.mats[name] = material("%s_%s" % (self.name, name), color, metallic, roughness)
        return self.mats[name]

    # ---- part builders (vertices in armature space) ----

    def _add(self, verts, faces, mat, bone):
        self.parts.append((verts, faces, mat, bone))

    def box(self, center, size, mat, bone, rot=0.0, axis='z'):
        cx, cy, cz = center
        sx, sy, sz = size
        hx, hy, hz = sx / 2.0, sy / 2.0, sz / 2.0
        v = [(cx - hx, cy - hy, cz - hz), (cx + hx, cy - hy, cz - hz),
             (cx + hx, cy + hy, cz - hz), (cx - hx, cy + hy, cz - hz),
             (cx - hx, cy - hy, cz + hz), (cx + hx, cy - hy, cz + hz),
             (cx + hx, cy + hy, cz + hz), (cx - hx, cy + hy, cz + hz)]
        if rot:
            ca, sa = math.cos(rot), math.sin(rot)
            rv = []
            for p in v:
                dx, dy = p[0] - cx, p[1] - cy
                if axis == 'z':
                    rv.append((cx + dx * ca - dy * sa, cy + dx * sa + dy * ca, p[2]))
                else:
                    rv.append((cx + dx * ca - p[2] * sa, p[1], cy + dx * sa + p[2] * ca))
            v = rv
        f = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
        self._add(v, f, mat, bone)

    def cyl(self, center, radius, height, mat, bone, axis='x', seg=12):
        cx, cy, cz = center
        v, f = [], []
        for i in range(seg):
            a = 2.0 * math.pi * i / seg
            if axis == 'x':
                v += [(cx, cy + radius * math.cos(a), cz + radius * math.sin(a)),
                      (cx + height, cy + radius * math.cos(a), cz + radius * math.sin(a))]
            elif axis == 'z':
                v += [(cx + radius * math.cos(a), cy + radius * math.sin(a), cz),
                      (cx + radius * math.cos(a), cy + radius * math.sin(a), cz + height)]
            else:
                v += [(cx + radius * math.cos(a), cy, cz + radius * math.sin(a)),
                      (cx + radius * math.cos(a), cy + height, cz + radius * math.sin(a))]
        for i in range(seg):
            j = (i + 1) % seg
            f.append((2 * i, 2 * j, 2 * j + 1, 2 * i + 1))
        f.append(tuple(range(seg - 1, -1, -1)))
        f.append(tuple(range(seg, 2 * seg)))
        self._add(v, f, mat, bone)

    def sphere(self, center, radius, mat, bone, seg=10, ring=6):
        cx, cy, cz = center
        v, f = [], []
        for r in range(ring + 1):
            phi = math.pi * r / ring
            for s in range(seg):
                th = 2.0 * math.pi * s / seg
                v.append((cx + radius * math.sin(phi) * math.cos(th),
                          cy + radius * math.sin(phi) * math.sin(th),
                          cz + radius * math.cos(phi)))
        for r in range(ring):
            for s in range(seg):
                a = r * seg + s
                b = r * seg + (s + 1) % seg
                c = (r + 1) * seg + (s + 1) % seg
                d = (r + 1) * seg + s
                f.append((a, b, c, d))
        self._add(v, f, mat, bone)

    # ---- finalize ----

    def finish(self):
        bpy.ops.object.mode_set(mode='OBJECT')
        mesh = bpy.data.meshes.new(self.name + "_mesh")
        verts, faces, groups = [], [], {}
        for pv, pf, mat, bone in self.parts:
            base = len(verts)
            verts += pv
            for face in pf:
                faces.append(tuple(i + base for i in face))
            groups.setdefault(bone, []).extend(range(base, base + len(pv)))
        mesh.from_pydata(verts, [], faces)
        mesh.validate()
        obj = bpy.data.objects.new(self.name + "_mesh", mesh)
        bpy.context.scene.collection.objects.link(obj)
        for bone, idxs in groups.items():
            vg = obj.vertex_groups.new(name=bone)
            vg.add(idxs, 1.0, 'REPLACE')
        obj.parent = self.obj
        mod = obj.modifiers.new("Armature", 'ARMATURE')
        mod.object = self.obj
        for mat in self.mats.values():
            mesh.materials.append(mat)
        # face material assignment follows part order (parts appended in order)
        idx_by_short = {short: i for i, short in enumerate(self.mats.keys())}
        fi = 0
        for pv, pf, mat, bone in self.parts:
            for k in range(len(pf)):
                mesh.polygons[fi].material_index = idx_by_short[mat]
                fi += 1
        self.mesh_obj = obj
        return obj

    # ---- animation ----

    def animation(self, clip, keys, length_s, non_loop=False):
        """keys: {bone: {'rot': [(frame,(x,y,z))...], 'loc': [(frame,(x,y,z))...]}}
        Creates an action, fake-users it, and stores it on an NLA track so the
        glTF exporter emits it as a named animation."""
        if self.obj.mode != 'OBJECT':
            bpy.ops.object.mode_set(mode='OBJECT')
        ad = self.obj.animation_data_create()
        prev = ad.action
        act = bpy.data.actions.new(clip)
        act.use_fake_user = True
        ad.action = act
        pose = self.obj.pose
        for bname, chans in keys.items():
            pb = pose.bones[bname]
            for frame, rot in chans.get('rot', []):
                pb.rotation_euler = rot
                pb.keyframe_insert("rotation_euler", frame=frame)
            for frame, loc in chans.get('loc', []):
                pb.location = loc
                pb.keyframe_insert("location", frame=frame)
        track = ad.nla_tracks.new()
        track.name = clip
        start, end = act.frame_range
        track.strips.new(clip, int(start), act)
        track.mute = True
        ad.action = prev
        return act

def export_glb(rig, path, extras=()):
    bpy.ops.object.select_all(action='DESELECT')
    rig.obj.select_set(True)
    if getattr(rig, "mesh_obj", None):
        rig.mesh_obj.select_set(True)
    for e in extras:
        e.select_set(True)
    bpy.context.view_layer.objects.active = rig.obj
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True,
                              export_animation_mode='ACTIONS', export_yup=True)
    print("EXPORTED", path)

# ---------------------------------------------------------------- characters
# Grid: one cell = 1 world unit. Characters authored facing -Y (exports to
# Godot +Z facing) at origin, feet at z=0 (Blender) -> y=0 (Godot).

def build_jayze():
    r = Rig("Jayze")
    G, S, K = (0.89, 0.65, 0.23), (0.94, 0.77, 0.53), (0.17, 0.21, 0.25)
    B, W = (0.85, 0.89, 0.91), (0.75, 0.16, 0.14)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Hips", (0, 0, 0.42), (0, 0, 0.52), "Root")
    r.bone("Torso", (0, 0, 0.52), (0, 0, 0.82), "Hips")
    r.bone("Head", (0, 0, 0.84), (0, 0, 1.1), "Torso")
    r.bone("ArmL", (-0.24, 0, 0.78), (-0.24, 0, 0.56), "Torso")
    r.bone("ForearmL", (-0.24, 0, 0.56), (-0.24, 0, 0.36), "ArmL")
    r.bone("ArmR", (0.24, 0, 0.78), (0.24, 0, 0.56), "Torso")
    r.bone("ForearmR", (0.24, 0, 0.56), (0.24, 0, 0.36), "ArmR")
    r.bone("HandR", (0.24, 0, 0.36), (0.24, 0, 0.28), "ForearmR")
    r.bone("Socket_Weapon", (0.24, -0.3, 0.3), (0.24, -0.3, 0.4), "HandR")
    r.bone("LegL", (-0.1, 0, 0.42), (-0.1, 0, 0.22), "Hips")
    r.bone("LegR", (0.1, 0, 0.42), (0.1, 0, 0.22), "Hips")
    r.mat("suit", G, roughness=0.4); r.mat("skin", S); r.mat("dark", K)
    r.mat("blade", B, metallic=0.8, roughness=0.25); r.mat("accent", W)
    r.box((0, 0, 0.66), (0.3, 0.18, 0.3), "suit", "Torso")                # chest
    r.box((0, -0.12, 0.72), (0.2, 0.1, 0.16), "accent", "Torso")          # chest emblem
    r.box((0, 0, 0.47), (0.24, 0.16, 0.14), "dark", "Hips")               # pelvis
    r.sphere((0, -0.01, 1.0), 0.13, "skin", "Head")                       # head
    r.box((0, -0.11, 1.02), (0.18, 0.06, 0.05), "dark", "Head")           # visor
    r.box((0, 0.09, 1.03), (0.16, 0.06, 0.03), "accent", "Head")          # headband
    r.box((-0.3, 0, 0.7), (0.09, 0.12, 0.1), "accent", "ArmL")            # pauldron L
    r.box((0.3, 0, 0.7), (0.09, 0.12, 0.1), "accent", "ArmR")             # pauldron R
    r.box((-0.24, 0, 0.67), (0.08, 0.08, 0.2), "suit", "ArmL")
    r.box((-0.24, 0, 0.46), (0.07, 0.07, 0.2), "skin", "ForearmL")
    r.box((0.24, 0, 0.67), (0.08, 0.08, 0.2), "suit", "ArmR")
    r.box((0.24, 0, 0.46), (0.07, 0.07, 0.2), "skin", "ForearmR")
    r.box((0.24, 0, 0.33), (0.08, 0.08, 0.08), "dark", "HandR")           # hand
    r.box((-0.1, 0, 0.32), (0.09, 0.09, 0.22), "dark", "LegL")
    r.box((0.1, 0, 0.32), (0.09, 0.09, 0.22), "dark", "LegR")
    r.box((-0.1, -0.02, 0.04), (0.11, 0.16, 0.08), "accent", "LegL")      # boot L
    r.box((0.1, -0.02, 0.04), (0.11, 0.16, 0.08), "accent", "LegR")       # boot R
    # sword in right hand, blade pointing forward (-Y), socket at tip
    r.box((0.24, 0, 0.28), (0.05, 0.05, 0.1), "dark", "HandR")            # grip
    r.box((0.24, -0.06, 0.28), (0.16, 0.03, 0.03), "accent", "HandR")     # guard
    r.box((0.24, -0.35, 0.28), (0.05, 0.55, 0.02), "blade", "HandR")      # blade
    D = lambda d: d * FPS
    r.animation("idle", {
        "Torso": {'rot': [(0, (0, 0, 0)), (D(1.0), (0.05, 0, 0)), (D(2.0), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(1.0), (-0.04, 0, 0)), (D(2.0), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0.15, 0, 0.1)), (D(1.0), (0.22, 0, 0.14)), (D(2.0), (0.15, 0, 0.1))]},
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(1.0), (0.12, 0, -0.1)), (D(2.0), (0.2, 0, -0.15))]},
    }, 2.0)
    r.animation("move", {
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.25), (0.6, 0, 0)), (D(0.5), (0, 0, 0)), (D(0.75), (-0.6, 0, 0)), (D(1.0), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.25), (-0.6, 0, 0)), (D(0.5), (0, 0, 0)), (D(0.75), (0.6, 0, 0)), (D(1.0), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0.15, 0, 0.1)), (D(0.5), (0.5, 0, 0.05)), (D(1.0), (0.15, 0, 0.1))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.25), (0.06, 0, 0.05)), (D(0.75), (0.06, 0, -0.05)), (D(1.0), (0, 0, 0))]},
    }, 1.0)
    r.animation("attack", {   # slash: windup -> strike -> recover
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.35), (0.12, 0, 0.55)), (D(0.5), (-0.08, 0, -0.7)), (D(1.2), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(0.35), (0.6, 0, -1.6)), (D(0.5), (-0.9, 0, 0.9)), (D(1.2), (0.2, 0, -0.15))]},
        "HandR": {'rot': [(0, (0, 0, 0)), (D(0.35), (0, 1.2, 0)), (D(0.5), (0, -1.4, 0)), (D(1.2), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0.15, 0, 0.1)), (D(0.35), (0.3, 0, 0.5)), (D(0.6), (0.1, 0, 0)), (D(1.2), (0.15, 0, 0.1))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.3, 0, 0)), (D(1.2), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.3, 0, 0)), (D(1.2), (0, 0, 0))]},
    }, 1.2)
    r.animation("ability", {  # technique: leap and overhead smash
        "Root": {'loc': [(0, (0, 0, 0)), (D(0.5), (0, 0, 0.5)), (D(0.75), (0, 0, 0)), (D(1.6), (0, 0, 0))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.4), (-0.35, 0, 0)), (D(0.72), (0.55, 0, 0)), (D(1.6), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(0.4), (-2.6, 0, -0.2)), (D(0.72), (0.7, 0, 0)), (D(1.6), (0.2, 0, -0.15))]},
        "HandR": {'rot': [(0, (0, 0, 0)), (D(0.4), (0, 0.8, 0)), (D(0.72), (0, -1.5, 0)), (D(1.6), (0, 0, 0))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.7, 0, 0)), (D(0.75), (0.2, 0, 0)), (D(1.6), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.5, 0, 0)), (D(0.75), (-0.2, 0, 0)), (D(1.6), (0, 0, 0))]},
    }, 1.6)
    r.animation("guard", {
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.15, 0, 0)), (D(0.8), (0.15, 0, 0))]},
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(0.3), (1.5, 0, -0.3)), (D(0.8), (1.5, 0, -0.3))]},
        "HandR": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, 1.2, 0)), (D(0.8), (0, 1.2, 0))]},
        "ArmL": {'rot': [(0, (0.15, 0, 0.1)), (D(0.3), (1.2, 0, 0.4)), (D(0.8), (1.2, 0, 0.4))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.3), (-0.25, 0, 0)), (D(0.8), (-0.25, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.25, 0, 0)), (D(0.8), (0.25, 0, 0))]},
    }, 0.8)
    r.animation("hit", {
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.1), (-0.3, 0, 0.2)), (D(0.5), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.1), (0.3, 0, -0.2)), (D(0.5), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(0.1), (0.6, 0, -0.8)), (D(0.5), (0.2, 0, -0.15))]},
    }, 0.5)
    r.animation("defeat", {
        "Root": {'loc': [(0, (0, 0, 0)), (D(0.9), (0, 0.3, -0.34)), (D(1.5), (0, 0.3, -0.34))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.9), (-1.2, 0, 0)), (D(1.5), (-1.25, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.9), (0.5, 0, 0)), (D(1.5), (0.5, 0, 0))]},
        "ArmL": {'rot': [(0, (0.15, 0, 0.1)), (D(0.9), (0.2, 0, 1.2)), (D(1.5), (0.2, 0, 1.2))]},
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(0.9), (0.2, 0, -1.2)), (D(1.5), (0.2, 0, -1.2))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.9), (0.8, 0, 0)), (D(1.5), (0.8, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.9), (0.4, 0, 0)), (D(1.5), (0.4, 0, 0))]},
    }, 1.5, non_loop=True)
    r.animation("victory", {
        "ArmR": {'rot': [(0, (0.2, 0, -0.15)), (D(0.4), (-2.7, 0, -0.2)), (D(1.2), (-2.6, 0, -0.1)), (D(2.0), (0.2, 0, -0.15))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.4), (-0.1, 0, 0)), (D(1.2), (0.06, 0, 0.1)), (D(2.0), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.6), (-0.15, 0, 0.1)), (D(2.0), (0, 0, 0))]},
    }, 2.0)
    return r

def build_kip():
    r = Rig("Kip")
    T, D, G = (0.16, 0.73, 0.78), (0.15, 0.19, 0.23), (0.75, 0.78, 0.3)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Body", (0, 0, 0.22), (0, 0, 0.4), "Root")          # chassis bone
    r.bone("Turret", (0, -0.05, 0.42), (0, -0.05, 0.58), "Body")
    r.bone("Socket_Muzzle", (0, -0.42, 0.55), (0, -0.42, 0.65), "Turret")
    r.bone("SteerFL", (-0.3, -0.28, 0.17), (-0.3, -0.28, 0.27), "Body")
    r.bone("SteerFR", (0.3, -0.28, 0.17), (0.3, -0.28, 0.27), "Body")
    r.bone("WheelFL", (-0.3, -0.28, 0.17), (-0.14, -0.28, 0.17), "SteerFL")
    r.bone("WheelFR", (0.3, -0.28, 0.17), (0.14, -0.28, 0.17), "SteerFR")
    r.bone("WheelBL", (-0.3, 0.28, 0.17), (-0.14, 0.28, 0.17), "Body")
    r.bone("WheelBR", (0.3, 0.28, 0.17), (0.14, 0.28, 0.17), "Body")
    r.mat("paint", T, roughness=0.35); r.mat("wheel", D, roughness=0.8)
    r.mat("chrome", G, metallic=0.7, roughness=0.3); r.mat("dark", D)
    r.box((0, 0, 0.22), (0.44, 0.95, 0.16), "paint", "Body")           # chassis
    r.box((0, -0.18, 0.34), (0.34, 0.5, 0.14), "paint", "Body")         # hood (-Y front)
    r.box((0, 0.14, 0.37), (0.3, 0.34, 0.2), "chrome", "Body")        # canopy (rear deck)
    r.box((0, 0.48, 0.3), (0.4, 0.08, 0.1), "paint", "Body")          # spoiler (rear +Y)
    r.box((0, -0.5, 0.2), (0.5, 0.1, 0.14), "chrome", "Body")           # ram bumper (front -Y)
    r.cyl((0, -0.28, 0.34), 0.05, 0.26, "dark", "Turret")              # barrel (-Y fwd)
    r.sphere((0, -0.05, 0.42), 0.09, "paint", "Turret")                # turret base
    for pos, bone in [((-0.3, -0.28), "WheelFL"), ((0.3, -0.28), "WheelFR"),
                      ((-0.3, 0.28), "WheelBL"), ((0.3, 0.28), "WheelBR")]:
        r.cyl((pos[0], pos[1], 0.17), 0.17, 0.12, "wheel", bone, axis='x')
        r.cyl((pos[0], pos[1], 0.17), 0.09, 0.14, "chrome", bone, axis='x')
    D = lambda d: d * FPS
    r.animation("idle", {
        "Body": {'loc': [(0, (0, 0, 0)), (D(0.6), (0, 0, -0.012)), (D(1.4), (0, 0, 0.006)), (D(2.0), (0, 0, 0))]},
        "Turret": {'rot': [(0, (0, 0, 0)), (D(1.0), (0, 0.15, 0)), (D(2.0), (0, 0, 0))]},
    }, 2.0)
    r.animation("move", {     # drive: bounce + suspension; wheels spin procedurally too
        "Body": {'loc': [(0, (0, 0, 0)), (D(0.15), (0, 0, 0.02)), (D(0.3), (0, 0, -0.01)), (D(0.45), (0, 0, 0.018)), (D(0.6), (0, 0, -0.008)), (D(0.8), (0, 0, 0.012)), (D(1.0), (0, 0, 0))]},
        "WheelFL": {'rot': [(0, (0, 0, 0)), (D(1.0), (0, -math.pi * 2, 0))]},
        "WheelFR": {'rot': [(0, (0, 0, 0)), (D(1.0), (0, -math.pi * 2, 0))]},
        "WheelBL": {'rot': [(0, (0, 0, 0)), (D(1.0), (0, -math.pi * 2, 0))]},
        "WheelBR": {'rot': [(0, (0, 0, 0)), (D(1.0), (0, -math.pi * 2, 0))]},
    }, 1.0)
    r.animation("attack", {   # turret shot with recoil
        "Turret": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, -0.25, 0)), (D(0.4), (0, 0.35, 0)), (D(0.9), (0, 0.1, 0)), (D(1.2), (0, 0, 0))]},
        "Body": {'loc': [(0, (0, 0, 0)), (D(0.4), (0, 0.05, 0)), (D(0.7), (0, 0, 0)), (D(1.2), (0, 0, 0))]},
    }, 1.2)
    r.animation("ram", {      # charge lunge
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.18, 0, 0)), (D(0.55), (-0.22, 0, 0)), (D(0.8), (0.1, 0, 0)), (D(1.4), (0, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.55), (0, -0.16, 0)), (D(0.8), (0, 0, 0)), (D(1.4), (0, 0, 0))]},
        "SteerFL": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, 0, 0.3)), (D(0.6), (0, 0, -0.35)), (D(1.4), (0, 0, 0))]},
        "SteerFR": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, 0, 0.3)), (D(0.6), (0, 0, -0.35)), (D(1.4), (0, 0, 0))]},
        "WheelFL": {'rot': [(0, (0, 0, 0)), (D(0.55), (0, -math.pi * 3, 0)), (D(1.4), (0, -math.pi * 3.4, 0))]},
        "WheelFR": {'rot': [(0, (0, 0, 0)), (D(0.55), (0, -math.pi * 3, 0)), (D(1.4), (0, -math.pi * 3.4, 0))]},
        "WheelBL": {'rot': [(0, (0, 0, 0)), (D(0.55), (0, -math.pi * 3, 0)), (D(1.4), (0, -math.pi * 3.4, 0))]},
        "WheelBR": {'rot': [(0, (0, 0, 0)), (D(0.55), (0, -math.pi * 3, 0)), (D(1.4), (0, -math.pi * 3.4, 0))]},
    }, 1.4)
    r.animation("guard", {
        "Body": {'loc': [(0, (0, 0, 0)), (D(0.3), (0, 0, -0.03)), (D(0.8), (0, 0, -0.03))]},
        "SteerFL": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, 0, 0.4)), (D(0.8), (0, 0, 0.4))]},
        "SteerFR": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, 0, -0.4)), (D(0.8), (0, 0, -0.4))]},
    }, 0.8)
    r.animation("hit", {
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.1), (0.15, 0, 0.1)), (D(0.15), (-0.1, 0, -0.08)), (D(0.5), (0, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.1), (0, 0, 0.02)), (D(0.5), (0, 0, 0))]},
    }, 0.5)
    r.animation("defeat", {   # rolls onto its roof, wheels up
        "Root": {'rot': [(0, (0, 0, 0)), (D(0.5), (0, 0, 0.6)), (D(1.1), (math.pi, 0, 0.8)), (D(1.6), (math.pi, 0, 0.8))],
                 'loc': [(0, (0, 0, 0)), (D(1.1), (0, 0.1, 0.28)), (D(1.6), (0, 0.1, 0.28))]},
    }, 1.6, non_loop=True)
    r.animation("victory", {
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.4), (-0.35, 0, 0)), (D(1.0), (-0.3, 0, 0)), (D(1.4), (0, 0, 0)), (D(2.0), (0, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.7), (0, 0, 0.04)), (D(1.1), (0, 0, 0)), (D(2.0), (0, 0, 0))]},
    }, 2.0)
    return r

def build_rallo():
    r = Rig("Rallo")
    R, D, M = (0.86, 0.38, 0.32), (0.2, 0.14, 0.12), (0.93, 0.9, 0.82)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Spine", (0, 0, 0.3), (0, 0, 0.5), "Root")
    r.bone("Chest", (0, 0, 0.5), (0, 0, 0.62), "Spine")
    r.bone("Head", (0, 0, 0.64), (0, 0, 0.86), "Chest")
    r.bone("WingL", (-0.16, 0.02, 0.58), (-0.42, 0.05, 0.72), "Chest")
    r.bone("WingL2", (-0.42, 0.05, 0.72), (-0.62, 0.08, 0.78), "WingL")
    r.bone("WingR", (0.16, 0.02, 0.58), (0.42, 0.05, 0.72), "Chest")
    r.bone("WingR2", (0.42, 0.05, 0.72), (0.62, 0.08, 0.78), "WingR")
    r.bone("ArmL", (-0.15, -0.02, 0.5), (-0.15, -0.02, 0.32), "Chest")
    r.bone("ArmR", (0.15, -0.02, 0.5), (0.15, -0.02, 0.32), "Chest")
    r.bone("Socket_ClawR", (0.15, -0.14, 0.3), (0.15, -0.14, 0.4), "ArmR")
    r.bone("LegL", (-0.09, 0, 0.3), (-0.09, 0, 0.12), "Spine")
    r.bone("LegR", (0.09, 0, 0.3), (0.09, 0, 0.12), "Spine")
    r.bone("Tail", (0, 0.1, 0.32), (0, 0.32, 0.36), "Spine")
    r.mat("hide", R, roughness=0.6); r.mat("dark", D); r.mat("membrane", M, roughness=0.7)
    r.box((0, 0, 0.55), (0.3, 0.2, 0.28), "hide", "Chest")             # chunky torso
    r.box((0, 0, 0.34), (0.22, 0.16, 0.16), "hide", "Spine")           # belly
    r.sphere((0, -0.02, 0.78), 0.15, "hide", "Head")                   # big head
    r.box((0, -0.13, 0.82), (0.2, 0.06, 0.05), "dark", "Head")         # brow
    r.box((0, -0.14, 0.72), (0.1, 0.05, 0.04), "dark", "Head")         # muzzle
    r.cone_horns = True
    r.box((-0.09, -0.04, 0.94), (0.05, 0.05, 0.12), "dark", "Head", rot=0.4)   # horn L
    r.box((0.09, -0.04, 0.94), (0.05, 0.05, 0.12), "dark", "Head", rot=-0.4)   # horn R
    r.box((-0.16, 0.02, 0.62), (0.3, 0.34, 0.03), "membrane", "WingL", rot=0.5)   # wing L
    r.box((0.16, 0.02, 0.62), (0.3, 0.34, 0.03), "membrane", "WingR", rot=-0.5)   # wing R
    r.box((-0.15, -0.02, 0.41), (0.09, 0.09, 0.2), "hide", "ArmL")
    r.box((0.15, -0.02, 0.41), (0.09, 0.09, 0.2), "hide", "ArmR")
    r.box((-0.15, -0.06, 0.31), (0.1, 0.1, 0.08), "dark", "ArmL")      # claw L
    r.box((0.15, -0.06, 0.31), (0.1, 0.1, 0.08), "dark", "ArmR")       # claw R
    r.box((-0.09, 0, 0.21), (0.08, 0.08, 0.18), "dark", "LegL")
    r.box((0.09, 0, 0.21), (0.08, 0.08, 0.18), "dark", "LegR")
    r.box((-0.09, -0.03, 0.05), (0.1, 0.14, 0.07), "dark", "LegL")     # foot L
    r.box((0.09, -0.03, 0.05), (0.1, 0.14, 0.07), "dark", "LegR")      # foot R
    r.box((0, 0.22, 0.35), (0.08, 0.28, 0.08), "hide", "Tail")         # tail
    D = lambda d: d * FPS
    flap = lambda a, b, c: [(0, a), (D(0.45), b), (D(0.9), c), (D(1.8), b), (D(2.7), c), (D(3.6), a)]
    r.animation("idle", {
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(1.2), (0, 0, 0.2)), (D(2.4), (0, 0, 0.14))]},   # low hover
        "WingL": {'rot': flap((0, 0, 0.5), (0, 0, -0.5), (0, 0, 0.5))},
        "WingR": {'rot': flap((0, 0, -0.5), (0, 0, 0.5), (0, 0, -0.5))},
        "Tail": {'rot': [(0, (0.2, 0, 0)), (D(1.2), (0.35, 0, 0)), (D(2.4), (0.2, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(1.2), (0.08, 0, 0.06)), (D(2.4), (0, 0, 0))]},
    }, 2.4)
    r.animation("move", {     # low flutter-glide
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.3), (0, 0, 0.2)), (D(0.6), (0, 0, 0.13)), (D(0.9), (0, 0, 0.19)), (D(1.2), (0, 0, 0.14))]},
        "WingL": {'rot': [(0, (0, 0, 0.4)), (D(0.3), (0, 0, -0.7)), (D(0.6), (0, 0, 0.4)), (D(0.9), (0, 0, -0.7)), (D(1.2), (0, 0, 0.4))]},
        "WingR": {'rot': [(0, (0, 0, -0.4)), (D(0.3), (0, 0, 0.7)), (D(0.6), (0, 0, -0.4)), (D(0.9), (0, 0, 0.7)), (D(1.2), (0, 0, -0.4))]},
        "LegL": {'rot': [(0, (0.5, 0, 0)), (D(1.2), (0.5, 0, 0))]},   # legs tuck while gliding
        "LegR": {'rot': [(0, (0.5, 0, 0)), (D(1.2), (0.5, 0, 0))]},
    }, 1.2)
    r.animation("attack", {   # claw swipe R -> L
        "Chest": {'rot': [(0, (0, 0, 0)), (D(0.3), (0, 0, -0.4)), (D(0.45), (0, 0, 0.5)), (D(1.1), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0.3, 0, 0)), (D(0.3), (1.2, 0, 0.6)), (D(0.45), (-0.6, 0, -0.9)), (D(1.1), (0.3, 0, 0))]},
        "ArmL": {'rot': [(0, (0.3, 0, 0)), (D(0.3), (0.5, 0, -0.3)), (D(0.6), (0.3, 0, 0)), (D(1.1), (0.3, 0, 0))]},
        "WingL": {'rot': [(0, (0, 0, 0.5)), (D(0.3), (0, 0, -0.9)), (D(1.1), (0, 0, 0.5))]},
        "WingR": {'rot': [(0, (0, 0, -0.5)), (D(0.3), (0, 0, 0.9)), (D(1.1), (0, 0, -0.5))]},
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.45), (0, -0.1, 0.16)), (D(1.1), (0, 0, 0.14))]},
    }, 1.1)
    r.animation("ability", {  # screech: flare wings and lean back
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.4), (0, 0, 0.3)), (D(1.2), (0, 0, 0.28)), (D(1.8), (0, 0, 0.14))]},
        "Chest": {'rot': [(0, (0, 0, 0)), (D(0.4), (0.3, 0, 0)), (D(1.2), (0.28, 0, 0)), (D(1.8), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.4), (0.5, 0, 0)), (D(0.6), (0.4, 0, 0)), (D(1.8), (0, 0, 0))]},
        "WingL": {'rot': [(0, (0, 0, 0.5)), (D(0.4), (0, 0, -1.5)), (D(1.2), (0, 0, -1.4)), (D(1.8), (0, 0, 0.5))]},
        "WingR": {'rot': [(0, (0, 0, -0.5)), (D(0.4), (0, 0, 1.5)), (D(1.2), (0, 0, 1.4)), (D(1.8), (0, 0, -0.5))]},
        "ArmL": {'rot': [(0, (0.3, 0, 0)), (D(0.4), (1.0, 0, 0.8)), (D(1.8), (0.3, 0, 0))]},
        "ArmR": {'rot': [(0, (0.3, 0, 0)), (D(0.4), (1.0, 0, -0.8)), (D(1.8), (0.3, 0, 0))]},
    }, 1.8)
    r.animation("guard", {
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.3), (0, 0, 0.04)), (D(0.8), (0, 0, 0.04))]},   # lands to brace
        "ArmL": {'rot': [(0, (0.3, 0, 0)), (D(0.3), (1.6, 0, 0.3)), (D(0.8), (1.6, 0, 0.3))]},
        "ArmR": {'rot': [(0, (0.3, 0, 0)), (D(0.3), (1.6, 0, -0.3)), (D(0.8), (1.6, 0, -0.3))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.3, 0, 0)), (D(0.8), (0.3, 0, 0))]},
        "WingL": {'rot': [(0, (0, 0, 0.5)), (D(0.3), (0.8, 0, 0)), (D(0.8), (0.8, 0, 0))]},
        "WingR": {'rot': [(0, (0, 0, -0.5)), (D(0.3), (0.8, 0, 0)), (D(0.8), (0.8, 0, 0))]},
    }, 0.8)
    r.animation("hit", {
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.1), (0, 0.08, 0.18)), (D(0.5), (0, 0, 0.14))]},
        "Chest": {'rot': [(0, (0, 0, 0)), (D(0.1), (-0.4, 0, 0.15)), (D(0.5), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.1), (0.35, 0, -0.2)), (D(0.5), (0, 0, 0))]},
    }, 0.5)
    r.animation("defeat", {   # falls out of hover, wings droop
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.5), (0, 0.05, 0.22)), (D(0.9), (0, 0.2, 0.02)), (D(1.4), (0, 0.2, 0.02))]},
        "Chest": {'rot': [(0, (0, 0, 0)), (D(0.9), (-1.1, 0, 0)), (D(1.4), (-1.15, 0, 0))]},
        "WingL": {'rot': [(0, (0, 0, 0.5)), (D(0.9), (1.3, 0, 0)), (D(1.4), (1.3, 0, 0))]},
        "WingR": {'rot': [(0, (0, 0, -0.5)), (D(0.9), (1.3, 0, 0)), (D(1.4), (1.3, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.9), (0.6, 0, 0)), (D(1.4), (0.6, 0, 0))]},
    }, 1.4, non_loop=True)
    r.animation("victory", {
        "WingL": {'rot': [(0, (0, 0, 0.5)), (D(0.5), (0, 0, -1.6)), (D(1.2), (0, 0, -1.5)), (D(1.8), (0, 0, -1.6)), (D(2.4), (0, 0, 0.5))]},
        "WingR": {'rot': [(0, (0, 0, -0.5)), (D(0.5), (0, 0, 1.6)), (D(1.2), (0, 0, 1.5)), (D(1.8), (0, 0, 1.6)), (D(2.4), (0, 0, -0.5))]},
        "Root": {'loc': [(0, (0, 0, 0.14)), (D(0.5), (0, 0, 0.3)), (D(1.2), (0, 0, 0.26)), (D(2.4), (0, 0, 0.14))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.25, 0, 0)), (D(2.4), (0, 0, 0))]},
    }, 2.4)
    return r

def build_crusher():
    r = Rig("Captain Crusher")
    A, P, D, V = (0.53, 0.41, 0.73), (0.3, 0.32, 0.4), (0.16, 0.17, 0.2), (0.4, 0.9, 0.85)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Hips", (0, 0, 0.46), (0, 0, 0.58), "Root")
    r.bone("Torso", (0, 0, 0.58), (0, 0, 0.95), "Hips")
    r.bone("Head", (0, 0, 0.98), (0, 0, 1.24), "Torso")
    r.bone("Pack", (0, 0.16, 0.8), (0, 0.28, 0.8), "Torso")
    r.bone("ArmL", (-0.3, 0, 0.9), (-0.3, 0, 0.62), "Torso")
    r.bone("ForearmL", (-0.3, 0, 0.62), (-0.3, 0, 0.4), "ArmL")
    r.bone("ArmR", (0.3, 0, 0.9), (0.3, 0, 0.62), "Torso")
    r.bone("ForearmR", (0.3, 0, 0.62), (0.3, 0, 0.4), "ArmR")
    r.bone("Socket_Pounder", (0.3, -0.14, 0.36), (0.3, -0.14, 0.46), "ForearmR")
    r.bone("LegL", (-0.12, 0, 0.46), (-0.12, 0, 0.2), "Hips")
    r.bone("LegR", (0.12, 0, 0.46), (0.12, 0, 0.2), "Hips")
    r.mat("armor", A, metallic=0.45, roughness=0.45); r.mat("plate", P, metallic=0.6, roughness=0.4)
    r.mat("dark", D, roughness=0.7); r.mat("visor", V, metallic=0.2, roughness=0.2)
    r.box((0, 0, 0.78), (0.42, 0.26, 0.4), "armor", "Torso")           # heavy chest
    r.box((0, -0.15, 0.72), (0.3, 0.06, 0.18), "plate", "Torso")       # chest plate
    r.box((0, 0, 0.52), (0.34, 0.22, 0.16), "plate", "Hips")           # pelvis girdle
    r.box((0, 0, 1.14), (0.2, 0.2, 0.2), "armor", "Head")              # helmet
    r.box((0, -0.12, 1.13), (0.16, 0.05, 0.07), "visor", "Head")       # visor
    r.box((0, 0.1, 1.16), (0.22, 0.06, 0.1), "plate", "Head")          # helmet crest
    r.box((0, 0.24, 0.8), (0.26, 0.16, 0.4), "plate", "Pack")          # power pack
    r.box((-0.38, 0, 0.86), (0.16, 0.2, 0.14), "plate", "ArmL")        # big pauldron L
    r.box((0.38, 0, 0.86), (0.16, 0.2, 0.14), "plate", "ArmR")         # big pauldron R
    r.box((-0.3, 0, 0.76), (0.12, 0.12, 0.26), "armor", "ArmL")
    r.box((-0.3, 0, 0.51), (0.11, 0.11, 0.22), "plate", "ForearmL")
    r.box((0.3, 0, 0.76), (0.12, 0.12, 0.26), "armor", "ArmR")
    r.box((0.3, 0, 0.51), (0.12, 0.12, 0.22), "plate", "ForearmR")
    r.box((0.3, -0.08, 0.38), (0.16, 0.16, 0.16), "dark", "ForearmR")  # pounder fist
    r.box((-0.12, 0, 0.33), (0.14, 0.14, 0.26), "armor", "LegL")
    r.box((0.12, 0, 0.33), (0.14, 0.14, 0.26), "armor", "LegR")
    r.box((-0.12, -0.03, 0.05), (0.17, 0.2, 0.1), "dark", "LegL")      # heavy boot L
    r.box((0.12, -0.03, 0.05), (0.17, 0.2, 0.1), "dark", "LegR")       # heavy boot R
    D = lambda d: d * FPS
    r.animation("idle", {
        "Torso": {'rot': [(0, (0, 0, 0)), (D(1.2), (0.03, 0, 0)), (D(2.4), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(1.2), (-0.05, 0, 0.08)), (D(2.4), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(1.2), (0.18, 0, 0.1)), (D(2.4), (0.12, 0, 0.08))]},
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(1.2), (0.06, 0, -0.1)), (D(2.4), (0.12, 0, -0.08))]},
    }, 2.4)
    r.animation("move", {     # heavy stomp
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.5, 0, 0)), (D(0.6), (0, 0, 0)), (D(0.9), (-0.5, 0, 0)), (D(1.2), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.3), (-0.5, 0, 0)), (D(0.6), (0, 0, 0)), (D(0.9), (0.5, 0, 0)), (D(1.2), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(0.6), (0.4, 0, 0.05)), (D(1.2), (0.12, 0, 0.08))]},
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(0.6), (0.4, 0, -0.05)), (D(1.2), (0.12, 0, -0.08))]},
        "Torso": {'rot': [(0, (0.05, 0, 0)), (D(0.3), (0.08, 0, 0.03)), (D(0.9), (0.08, 0, -0.03)), (D(1.2), (0.05, 0, 0))]},
    }, 1.2)
    r.animation("attack", {   # pound: overhead -> slam
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.4), (-0.3, 0, 0)), (D(0.6), (0.5, 0, 0)), (D(1.3), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(0.4), (-2.4, 0, -0.3)), (D(0.6), (0.9, 0, 0)), (D(1.3), (0.12, 0, -0.08))]},
        "ForearmR": {'rot': [(0, (0, 0, 0)), (D(0.4), (0.3, 0, 0)), (D(0.6), (-0.3, 0, 0)), (D(1.3), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(0.4), (0.5, 0, 0.4)), (D(0.7), (0.1, 0, 0.2)), (D(1.3), (0.12, 0, 0.08))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.6), (-0.3, 0, 0)), (D(1.3), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.3, 0, 0)), (D(1.3), (0, 0, 0))]},
        "Root": {'loc': [(0, (0, 0, 0)), (D(0.6), (0, -0.06, -0.05)), (D(1.3), (0, 0, 0))]},
    }, 1.3)
    r.animation("ability", {  # mend: emitter arm rises, gentle pulse
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(0.5), (-1.8, 0, 0.25)), (D(1.0), (-1.7, 0, 0.2)), (D(1.6), (0.12, 0, 0.08))]},
        "ForearmL": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.4, 0, 0)), (D(1.0), (0.35, 0, 0)), (D(1.6), (0, 0, 0))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.1, 0, 0.08)), (D(1.6), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.2, 0, 0.1)), (D(1.6), (0, 0, 0))]},
    }, 1.6)
    r.animation("brace", {    # crouch, arms out wide
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.35), (0.2, 0, 0)), (D(0.9), (0.2, 0, 0))]},
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(0.35), (1.3, 0, 0.7)), (D(0.9), (1.3, 0, 0.7))]},
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(0.35), (1.3, 0, -0.7)), (D(0.9), (1.3, 0, -0.7))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.35), (-0.35, 0, 0)), (D(0.9), (-0.35, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.35), (0.35, 0, 0)), (D(0.9), (0.35, 0, 0))]},
        "Root": {'loc': [(0, (0, 0, 0)), (D(0.35), (0, 0, -0.08)), (D(0.9), (0, 0, -0.08))]},
    }, 0.9)
    r.animation("guard", {
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.15, 0, 0)), (D(0.8), (0.15, 0, 0))]},
        "ForearmR": {'rot': [(0, (0, 0, 0)), (D(0.3), (1.7, 0, 0)), (D(0.8), (1.7, 0, 0))]},
        "ForearmL": {'rot': [(0, (0, 0, 0)), (D(0.3), (1.7, 0, 0)), (D(0.8), (1.7, 0, 0))]},
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(0.3), (0.9, 0, -0.25)), (D(0.8), (0.9, 0, -0.25))]},
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(0.3), (0.9, 0, 0.25)), (D(0.8), (0.9, 0, 0.25))]},
    }, 0.8)
    r.animation("hit", {
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.12), (-0.22, 0, 0.1)), (D(0.55), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.12), (0.2, 0, -0.12)), (D(0.55), (0, 0, 0))]},
        "Root": {'loc': [(0, (0, 0, 0)), (D(0.12), (0, 0.04, 0)), (D(0.55), (0, 0, 0))]},
    }, 0.55)
    r.animation("defeat", {   # kneels, then slumps forward
        "Root": {'loc': [(0, (0, 0, 0)), (D(0.6), (0, 0, -0.2)), (D(1.2), (0, 0.15, -0.3)), (D(1.8), (0, 0.15, -0.3))]},
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.6), (1.4, 0, 0)), (D(1.8), (1.4, 0, 0))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(1.2), (0.7, 0, 0)), (D(1.8), (0.75, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(1.2), (0.6, 0, 0)), (D(1.8), (0.6, 0, 0))]},
        "ArmL": {'rot': [(0, (0.12, 0, 0.08)), (D(1.2), (0.3, 0, 0.5)), (D(1.8), (0.3, 0, 0.5))]},
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(1.2), (0.3, 0, -0.5)), (D(1.8), (0.3, 0, -0.5))]},
    }, 1.8, non_loop=True)
    r.animation("victory", {
        "ArmR": {'rot': [(0, (0.12, 0, -0.08)), (D(0.5), (-2.5, 0, -0.3)), (D(1.4), (-2.4, 0, -0.2)), (D(2.2), (0.12, 0, -0.08))]},
        "Torso": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.12, 0, 0)), (D(1.4), (0.05, 0, 0.06)), (D(2.2), (0, 0, 0))]},
    }, 2.2)
    return r

def build_sprocket():
    r = Rig("Sprocket")
    Y, D, M = (0.95, 0.72, 0.2), (0.2, 0.2, 0.22), (0.85, 0.3, 0.25)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Body", (0, 0, 0.3), (0, 0, 0.45), "Root")
    r.bone("Key", (0, 0.22, 0.42), (0.0, 0.34, 0.42), "Body")       # wind-up key axle
    r.bone("Head", (0, -0.02, 0.55), (0, -0.02, 0.75), "Body")
    r.bone("ArmR", (0.18, -0.04, 0.44), (0.18, -0.04, 0.28), "Body")
    r.bone("ArmL", (-0.18, -0.04, 0.44), (-0.18, -0.04, 0.28), "Body")
    r.bone("LegL", (-0.09, 0, 0.3), (-0.09, 0, 0.12), "Body")
    r.bone("LegR", (0.09, 0, 0.3), (0.09, 0, 0.12), "Body")
    r.bone("Socket_Impact", (0.18, -0.2, 0.3), (0.18, -0.2, 0.4), "ArmR")
    r.mat("shell", Y, roughness=0.4); r.mat("dark", D); r.mat("metal", M, metallic=0.6, roughness=0.35)
    r.box((0, 0, 0.38), (0.28, 0.24, 0.3), "shell", "Body")           # barrel body
    r.cyl((0, 0.24, 0.42), 0.12, 0.03, "metal", "Key", axis='y')      # key disk
    r.box((0, 0.26, 0.42), (0.24, 0.04, 0.05), "metal", "Key")        # key wing
    r.sphere((0, -0.02, 0.62), 0.13, "shell", "Head")                 # head
    r.box((0, -0.13, 0.63), (0.16, 0.05, 0.05), "dark", "Head")       # eyes strip
    r.box((0.18, -0.04, 0.36), (0.08, 0.08, 0.18), "dark", "ArmR")
    r.box((-0.18, -0.04, 0.36), (0.08, 0.08, 0.18), "dark", "ArmL")
    r.box((0.18, -0.08, 0.26), (0.1, 0.1, 0.08), "metal", "ArmR")     # glove R
    r.box((-0.18, -0.08, 0.26), (0.1, 0.1, 0.08), "metal", "ArmL")    # glove L
    r.box((-0.09, 0, 0.21), (0.08, 0.08, 0.18), "dark", "LegL")
    r.box((0.09, 0, 0.21), (0.08, 0.08, 0.18), "dark", "LegR")
    r.box((-0.09, -0.03, 0.05), (0.1, 0.14, 0.07), "dark", "LegL")
    r.box((0.09, -0.03, 0.05), (0.1, 0.14, 0.07), "dark", "LegR")
    D = lambda d: d * FPS
    r.animation("idle", {
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.06, 0, 0.04)), (D(1.2), (0, 0, 0)), (D(1.8), (0.06, 0, -0.04)), (D(2.4), (0, 0, 0))]},
        "Key": {'rot': [(0, (0, 0, 0)), (D(2.4), (0, 0.8, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(1.2), (0, 0, 0.12)), (D(2.4), (0, 0, 0))]},
    }, 2.4)
    r.animation("move", {
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.25), (0.7, 0, 0)), (D(0.5), (0, 0, 0)), (D(0.75), (-0.7, 0, 0)), (D(1.0), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.25), (-0.7, 0, 0)), (D(0.5), (0, 0, 0)), (D(0.75), (0.7, 0, 0)), (D(1.0), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.6, 0, 0)), (D(1.0), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.4, 0, 0)), (D(1.0), (0, 0, 0))]},
        "Key": {'rot': [(0, (0, 0, 0)), (D(1.0), (0, 2.5, 0))]},
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.25), (0.08, 0, 0.05)), (D(0.75), (0.08, 0, -0.05)), (D(1.0), (0, 0, 0))]},
    }, 1.0)
    r.animation("telegraph", {   # winds up: key spins fast, leans back, arm raises
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.3, 0, 0)), (D(0.9), (-0.32, 0, 0))]},
        "Key": {'rot': [(0, (0, 0, 0)), (D(0.5), (0, 4.5, 0)), (D(0.9), (0, 7.5, 0))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.5), (-2.2, 0, -0.3)), (D(0.9), (-2.3, 0, -0.3))]},
    }, 0.9)
    r.animation("attack", {      # lunge punch
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.15), (0.35, 0, 0)), (D(0.4), (-0.15, 0, 0)), (D(0.8), (0, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.4), (0, -0.12, 0)), (D(0.8), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.15), (-2.4, 0, -0.3)), (D(0.4), (1.5, 0, 0)), (D(0.8), (0, 0, 0))]},
    }, 0.8)
    r.animation("hit", {
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.1), (-0.35, 0, 0.2)), (D(0.5), (0, 0, 0))]},
        "Key": {'rot': [(0, (0, 0, 0)), (D(0.15), (0, -1.2, 0)), (D(0.5), (0, 0, 0))]},
    }, 0.5)
    r.animation("defeat", {      # key pops off, slumps
        "Key": {'loc': [(0, (0, 0, 0)), (D(0.4), (0, 0.3, 0.25)), (D(0.5), (0, 0.3, 0.0)), (D(1.2), (0, 0.3, 0.0))],
                'rot': [(0, (0, 0, 0)), (D(0.4), (0, 1.5, 0)), (D(1.2), (0, 1.8, 0))]},
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.8), (0.9, 0, 0)), (D(1.2), (0.95, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.8), (0, 0.1, -0.12)), (D(1.2), (0, 0.1, -0.12))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.8), (0.5, 0, 0.2)), (D(1.2), (0.5, 0, 0.2))]},
    }, 1.2, non_loop=True)
    return r

def build_clanker():
    r = Rig("Clanker")
    G, R, D = (0.45, 0.5, 0.42), (0.7, 0.25, 0.2), (0.18, 0.2, 0.22)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Body", (0, 0, 0.4), (0, 0, 0.7), "Root")
    r.bone("Plate", (0, -0.14, 0.62), (0, -0.2, 0.62), "Body")      # loose chest plate
    r.bone("Head", (0, -0.02, 0.82), (0, -0.02, 1.0), "Body")
    r.bone("ArmL", (-0.28, 0, 0.72), (-0.28, 0, 0.4), "Body")
    r.bone("ArmR", (0.28, 0, 0.72), (0.28, 0, 0.4), "Body")
    r.bone("LegL", (-0.13, 0, 0.4), (-0.13, 0, 0.14), "Root")
    r.bone("LegR", (0.13, 0, 0.4), (0.13, 0, 0.14), "Root")
    r.bone("Socket_Impact", (0, -0.3, 0.42), (0, -0.3, 0.52), "Body")
    r.mat("can", G, roughness=0.5, metallic=0.3); r.mat("rust", R, roughness=0.7); r.mat("dark", D)
    r.box((0, 0, 0.55), (0.4, 0.3, 0.45), "can", "Body")              # barrel chest
    r.box((0, -0.17, 0.6), (0.3, 0.05, 0.2), "rust", "Plate")         # chest plate
    r.box((0, -0.02, 0.9), (0.22, 0.18, 0.18), "can", "Head")         # blocky head
    r.box((0, -0.11, 0.9), (0.18, 0.04, 0.05), "dark", "Head")        # eye strip
    r.box((0, -0.12, 0.84), (0.1, 0.04, 0.04), "dark", "Head")        # mouth
    r.box((-0.28, 0, 0.56), (0.14, 0.14, 0.3), "rust", "ArmL")
    r.box((0.28, 0, 0.56), (0.14, 0.14, 0.3), "rust", "ArmR")
    r.box((-0.28, -0.05, 0.36), (0.18, 0.18, 0.18), "dark", "ArmL")   # fist L
    r.box((0.28, -0.05, 0.36), (0.18, 0.18, 0.18), "dark", "ArmR")    # fist R
    r.box((-0.13, 0, 0.27), (0.12, 0.12, 0.26), "dark", "LegL")
    r.box((0.13, 0, 0.27), (0.12, 0.12, 0.26), "dark", "LegR")
    r.box((-0.13, -0.02, 0.06), (0.15, 0.18, 0.08), "dark", "LegL")
    r.box((0.13, -0.02, 0.06), (0.15, 0.18, 0.08), "dark", "LegR")
    D = lambda d: d * FPS
    r.animation("idle", {
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.7), (0.04, 0, 0)), (D(1.4), (0, 0, 0)), (D(2.1), (0.04, 0, 0)), (D(2.8), (0, 0, 0))]},
        "Plate": {'rot': [(0, (0, 0, 0)), (D(0.7), (0.08, 0, 0)), (D(2.8), (0, 0, 0))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(1.4), (0, 0, 0.1)), (D(2.8), (0, 0, 0))]},
    }, 2.8)
    r.animation("move", {
        "LegL": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.55, 0, 0)), (D(0.6), (0, 0, 0)), (D(0.9), (-0.55, 0, 0)), (D(1.2), (0, 0, 0))]},
        "LegR": {'rot': [(0, (0, 0, 0)), (D(0.3), (-0.55, 0, 0)), (D(0.6), (0, 0, 0)), (D(0.9), (0.55, 0, 0)), (D(1.2), (0, 0, 0))]},
        "ArmL": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.5, 0, 0)), (D(1.2), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.5, 0, 0)), (D(1.2), (0, 0, 0))]},
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.3), (0.06, 0, 0.04)), (D(0.9), (0.06, 0, -0.04)), (D(1.2), (0, 0, 0))]},
    }, 1.2)
    r.animation("telegraph", {   # raises both fists overhead
        "ArmL": {'rot': [(0, (0, 0, 0)), (D(0.5), (-2.4, 0, 0.4)), (D(0.9), (-2.5, 0, 0.4))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.5), (-2.4, 0, -0.4)), (D(0.9), (-2.5, 0, -0.4))]},
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.25, 0, 0)), (D(0.9), (-0.27, 0, 0))]},
        "Plate": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.15, 0, 0)), (D(0.9), (0.15, 0, 0))]},
    }, 0.9)
    r.animation("attack", {      # double-fist slam
        "ArmL": {'rot': [(0, (0, 0, 0)), (D(0.15), (0.9, 0, 0.2)), (D(0.45), (0, 0, 0)), (D(0.9), (0, 0, 0))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.15), (0.9, 0, -0.2)), (D(0.45), (0, 0, 0)), (D(0.9), (0, 0, 0))]},
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.45), (0.45, 0, 0)), (D(0.9), (0, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.45), (0, -0.1, -0.1)), (D(0.9), (0, 0, 0))]},
    }, 0.9)
    r.animation("hit", {
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.1), (-0.3, 0, 0.15)), (D(0.15), (0.15, 0, -0.1)), (D(0.55), (0, 0, 0))]},
        "Plate": {'rot': [(0, (0, 0, 0)), (D(0.1), (0.4, 0, 0)), (D(0.55), (0, 0, 0))]},
    }, 0.55)
    r.animation("defeat", {      # slams down, head droops
        "Body": {'rot': [(0, (0, 0, 0)), (D(0.6), (1.2, 0, 0)), (D(1.4), (1.25, 0, 0))],
                 'loc': [(0, (0, 0, 0)), (D(0.6), (0, 0.15, -0.28)), (D(1.4), (0, 0.15, -0.28))]},
        "Head": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.6, 0, 0)), (D(1.4), (0.6, 0, 0))]},
        "ArmL": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.4, 0, 0.8)), (D(1.4), (0.4, 0, 0.8))]},
        "ArmR": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.4, 0, -0.8)), (D(1.4), (0.4, 0, -0.8))]},
        "Plate": {'rot': [(0, (0, 0, 0)), (D(0.6), (0.5, 0, 0)), (D(1.4), (0.5, 0, 0))]},
    }, 1.4, non_loop=True)
    return r

def build_gimbal():
    r = Rig("Gimbal")
    O, M, D = (0.95, 0.55, 0.15), (0.7, 0.72, 0.75), (0.2, 0.2, 0.24)
    r.bone("Root", (0, 0, 0), (0, 0, 0.1))
    r.bone("Core", (0, 0, 0.4), (0, 0, 0.55), "Root")               # hover core
    r.bone("Ring", (0, 0, 0.46), (0.22, 0, 0.46), "Core")           # spinning ring
    r.bone("ProngL", (-0.1, -0.06, 0.55), (-0.16, -0.24, 0.6), "Core")
    r.bone("ProngR", (0.1, -0.06, 0.55), (0.16, -0.24, 0.6), "Core")
    r.bone("Socket_Muzzle", (0, -0.26, 0.58), (0, -0.26, 0.66), "Core")
    r.mat("core", O, metallic=0.3, roughness=0.35); r.mat("ring", M, metallic=0.7, roughness=0.3); r.mat("dark", D)
    r.sphere((0, 0, 0.46), 0.14, "core", "Core")                      # eye core
    r.sphere((0, -0.1, 0.46), 0.07, "dark", "Core")                   # lens
    r.box((0, 0, 0.46), (0.5, 0.5, 0.03), "ring", "Ring")             # gimbal ring (flat torus-ish)
    r.box((-0.12, -0.14, 0.57), (0.06, 0.2, 0.05), "dark", "ProngL")  # launcher prong L
    r.box((0.12, -0.14, 0.57), (0.06, 0.2, 0.05), "dark", "ProngR")   # launcher prong R
    r.box((0, -0.2, 0.55), (0.1, 0.08, 0.08), "core", "Core")         # muzzle block
    D = lambda d: d * FPS
    r.animation("idle", {
        "Root": {'loc': [(0, (0, 0, 0.16)), (D(1.0), (0, 0, 0.22)), (D(2.0), (0, 0, 0.16))]},
        "Ring": {'rot': [(0, (0, 0, 0)), (D(2.0), (0, 0, 3.14))]},
        "ProngL": {'rot': [(0, (0, 0, 0)), (D(1.0), (0.15, 0, 0)), (D(2.0), (0, 0, 0))]},
        "ProngR": {'rot': [(0, (0, 0, 0)), (D(1.0), (0.15, 0, 0)), (D(2.0), (0, 0, 0))]},
    }, 2.0)
    r.animation("move", {
        "Root": {'loc': [(0, (0, 0, 0.16)), (D(0.3), (0, 0, 0.22)), (D(0.6), (0, 0, 0.15)), (D(0.9), (0, 0, 0.21)), (D(1.2), (0, 0, 0.16))]},
        "Ring": {'rot': [(0, (0, 0, 0)), (D(1.2), (0, 0, 4.7))]},
    }, 1.2)
    r.animation("telegraph", {   # prongs split wide, core charges
        "ProngL": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.5, 0, 0.7)), (D(0.9), (-0.55, 0, 0.7))]},
        "ProngR": {'rot': [(0, (0, 0, 0)), (D(0.5), (-0.5, 0, -0.7)), (D(0.9), (-0.55, 0, -0.7))]},
        "Core": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.25, 0, 0)), (D(0.9), (0.27, 0, 0))]},
    }, 0.9)
    r.animation("attack", {      # launch: prongs snap closed, recoil
        "ProngL": {'rot': [(0, (0, 0, 0)), (D(0.15), (0.6, 0, -0.8)), (D(0.5), (0, 0, 0)), (D(0.9), (0, 0, 0))]},
        "ProngR": {'rot': [(0, (0, 0, 0)), (D(0.15), (0.6, 0, 0.8)), (D(0.5), (0, 0, 0)), (D(0.9), (0, 0, 0))]},
        "Core": {'rot': [(0, (0, 0, 0)), (D(0.15), (-0.4, 0, 0)), (D(0.5), (0.3, 0, 0)), (D(0.9), (0, 0, 0))]},
        "Root": {'loc': [(0, (0, 0, 0.16)), (D(0.15), (0, 0.06, 0.16)), (D(0.9), (0, 0, 0.16))]},
    }, 0.9)
    r.animation("hit", {
        "Core": {'rot': [(0, (0, 0, 0)), (D(0.1), (-0.4, 0, 0.2)), (D(0.5), (0, 0, 0))]},
        "Ring": {'rot': [(0, (0, 0, 0)), (D(0.1), (0.3, 0, 0.25)), (D(0.25), (-0.2, 0, -0.2)), (D(0.5), (0, 0, 0))]},
        "Root": {'loc': [(0, (0, 0, 0.16)), (D(0.1), (0, 0.08, 0.2)), (D(0.5), (0, 0, 0.16))]},
    }, 0.5)
    r.animation("defeat", {      # ring stops, core sinks and cracks down
        "Ring": {'rot': [(0, (0, 0, 0)), (D(0.5), (0.8, 0, 0.6)), (D(1.2), (0.9, 0, 0.7))]},
        "Core": {'rot': [(0, (0, 0, 0)), (D(1.0), (0.4, 0, 0)), (D(1.4), (0.4, 0, 0))]},
        "Root": {'loc': [(0, (0, 0, 0.16)), (D(0.8), (0, 0.05, -0.3)), (D(1.4), (0, 0.05, -0.3))]},
        "ProngL": {'rot': [(0, (0, 0, 0)), (D(1.0), (1.2, 0, 0.2)), (D(1.4), (1.2, 0, 0.2))]},
        "ProngR": {'rot': [(0, (0, 0, 0)), (D(1.0), (1.2, 0, -0.2)), (D(1.4), (1.2, 0, -0.2))]},
    }, 1.4, non_loop=True)
    return r

# ---------------------------------------------------------------- arena

def build_arena(out_dir):
    """Toy-scale bedroom-floor diorama. Cell (x,y) -> world (x-4.5, 0, y-3.5).
    Floor carries a vertex-color checker so the tactical grid stays readable."""
    cell = lambda c: Vector((c.x - 4.5, c.y - 3.5, 0))
    parts = []

    def add(name, verts, faces, mat, colors=None):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        mesh.validate()
        if colors:
            ca = mesh.color_attributes.new(name="Col", type='FLOAT_COLOR', domain='POINT')
            for i, col in enumerate(colors):
                ca.data[i].color = (col[0], col[1], col[2], 1.0)
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        parts.append(obj)
        return obj

    mat_floor = material("arena_floor", (1, 1, 1), roughness=0.8)
    mat_plank = material("arena_wood", (0.76, 0.63, 0.45), roughness=0.75)
    mat_rug = material("arena_rug", (0.6, 0.2, 0.18), roughness=0.85)
    mat_block1 = material("arena_block_teal", (0.25, 0.5, 0.55), roughness=0.5)
    mat_block2 = material("arena_block_wood", (0.62, 0.45, 0.3), roughness=0.6)
    mat_box = material("arena_musicbox", (0.75, 0.6, 0.3), metallic=0.2, roughness=0.4)
    mat_wall = material("arena_wall", (0.82, 0.76, 0.66), roughness=0.85)
    mat_bed = material("arena_bed", (0.85, 0.83, 0.78), roughness=0.8)
    mat_blanket = material("arena_blanket", (0.35, 0.45, 0.65), roughness=0.8)
    mat_leg = material("arena_deskleg", (0.45, 0.38, 0.3), roughness=0.6)
    mat_skirt = material("arena_skirting", (0.9, 0.88, 0.82), roughness=0.9)

    # floor with checker vertex colors (grid readability)
    verts, faces, colors = [], [], []
    W, H = 12, 10
    for gx in range(W):
        for gy in range(H):
            x0 = gx - W / 2.0 + 0.5
            y0 = gy - H / 2.0 + 0.5
            base = len(verts)
            verts += [(x0 - 0.5, y0 - 0.5, 0), (x0 + 0.5, y0 - 0.5, 0),
                      (x0 + 0.5, y0 + 0.5, 0), (x0 - 0.5, y0 + 0.5, 0)]
            faces.append((base, base + 1, base + 2, base + 3))
            tone = 0.8 if (gx + gy) % 2 == 0 else 0.7
            warm = (0.82, 0.74, 0.58)
            for _ in range(4):
                colors.append((warm[0] * tone, warm[1] * tone, warm[2] * tone))
    add("Floor", verts, faces, mat_floor, colors)

    def slab(name, center, size, mat):
        cx, cy, cz = center
        sx, sy, sz = size
        v = [(cx - sx/2, cy - sy/2, cz - sz/2), (cx + sx/2, cy - sy/2, cz - sz/2),
             (cx + sx/2, cy + sy/2, cz - sz/2), (cx - sx/2, cy + sy/2, cz - sz/2),
             (cx - sx/2, cy - sy/2, cz + sz/2), (cx + sx/2, cy - sy/2, cz + sz/2),
             (cx + sx/2, cy + sy/2, cz + sz/2), (cx - sx/2, cy + sy/2, cz + sz/2)]
        f = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
        return add(name, v, f, mat)

    slab("Rug", (0, 0, 0.008), (5.0, 4.2, 0.016), mat_rug)
    slab("BedBase", (-5.6, -3.6, 0.35), (2.2, 3.4, 0.7), mat_bed)
    slab("BedBlanket", (-5.6, -2.9, 0.72), (2.2, 2.0, 0.08), mat_blanket)
    slab("DeskLeg", (-5.4, 2.6, 0.6), (0.5, 0.5, 1.2), mat_leg)
    slab("WallBack", (0, -5.3, 1.2), (12, 0.4, 2.4), mat_wall)
    slab("WallLeft", (-6.3, 0, 1.2), (0.4, 10, 2.4), mat_wall)
    slab("SkirtingBack", (0, -5.05, 0.18), (12, 0.12, 0.36), mat_skirt)
    # blocked-cell obstacles (cell (3,3) and (5,1)) and the music box (5,4)
    slab("CoverBlock", tuple(cell(Vector((3, 3))) + Vector((0, 0, 0.33))), (0.86, 0.86, 0.66), mat_block1)
    slab("StackObstacle", tuple(cell(Vector((5, 1))) + Vector((0, 0, 0.3))), (0.7, 0.7, 0.6), mat_block2)
    slab("MusicBoxBase", tuple(cell(Vector((5, 4))) + Vector((0, 0, 0.14))), (0.55, 0.55, 0.28), mat_box)
    slab("MusicBoxLid", tuple(cell(Vector((5, 4))) + Vector((0, 0, 0.32))), (0.4, 0.4, 0.1), mat_box)
    slab("Crayon1", (3.6, 2.2, 0.06), (0.12, 0.12, 0.35), mat_blanket)
    slab("Marble", (3.2, -1.8, 0.08), (0.16, 0.16, 0.16), mat_box)
    return parts

# ---------------------------------------------------------------- main

def main():
    argv = sys.argv
    out_dir = "assets/characters"
    if "--" in argv:
        opts = argv[argv.index("--") + 1:]
        if "--out" in opts:
            out_dir = opts[opts.index("--out") + 1]
    os.makedirs(out_dir, exist_ok=True)
    import addon_utils
    addon_utils.enable("io_scene_gltf2", default_set=True, persistent=True)

    builders = [
        ("jayze", build_jayze), ("kip", build_kip), ("rallo", build_rallo),
        ("crusher", build_crusher), ("sprocket", build_sprocket),
        ("clanker", build_clanker), ("gimbal", build_gimbal),
    ]
    for name, fn in builders:
        reset_scene()
        rig = fn()
        rig.finish()
        export_glb(rig, os.path.join(out_dir, name + ".glb"))

    reset_scene()
    arena = build_arena(out_dir)
    bpy.ops.object.select_all(action='DESELECT')
    for p in arena:
        p.select_set(True)
    bpy.context.view_layer.objects.active = arena[0]
    bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "arena.glb"),
                              export_format='GLB', use_selection=True, export_yup=True)
    print("EXPORTED", os.path.join(out_dir, "arena.glb"))

main()
