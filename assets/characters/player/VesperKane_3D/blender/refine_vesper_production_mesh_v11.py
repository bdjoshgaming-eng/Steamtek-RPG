"""Refine Vesper Production Mesh v1 into the v1.1 silhouette approval branch."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def clamp(value, low=0.0, high=1.0):
    return max(low, min(high, value))


def smart_uv(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)


def bind_new(obj, rig, root, collection, material, bone_name, bevel=0.003, subdiv=1):
    obj.data.materials.append(material)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    armature = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    armature.object = rig
    armature.use_deform_preserve_volume = True
    if bevel:
        modifier = obj.modifiers.new(name="ProductionEdgeSoftening", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
    if subdiv:
        modifier = obj.modifiers.new(name="ProductionSubdivision", type="SUBSURF")
        modifier.levels = subdiv
        modifier.render_levels = subdiv
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.parent = root
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)
    obj["steamtek_stage"] = "production_mesh_v11_silhouette"
    smart_uv(obj)
    return obj


def ellipsoid(name, center, scale, bone_name, rig, root, collection, material, front_bias=0.0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.0, location=center)
    obj = bpy.context.object
    obj.name = name
    for vertex in obj.data.vertices:
        co = vertex.co
        co.x *= scale.x
        co.y *= scale.y
        co.z *= scale.z
        if front_bias and co.y < 0.0:
            co.y *= 1.0 + front_bias
    return bind_new(obj, rig, root, collection, material, bone_name)


def torus(name, center, major, minor, bone_name, rig, root, collection, material, scale_y=1.0, align_to_bone=False):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major, minor_radius=minor,
        major_segments=28, minor_segments=8, location=center,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale.y = scale_y
    if align_to_bone:
        bone = rig.data.bones[bone_name]
        direction = (bone.tail_local - bone.head_local).normalized()
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    return bind_new(obj, rig, root, collection, material, bone_name, bevel=0.002, subdiv=0)


def wedge(name, center, half_width, depth, height, bone_name, rig, root, collection, material):
    x0, x1 = center.x - half_width, center.x + half_width
    y_back, y_front = center.y + depth * 0.28, center.y - depth * 0.72
    z0, z1 = center.z - height * 0.5, center.z + height * 0.5
    verts = [
        (x0, y_back, z0), (x1, y_back, z0), (x1, y_front, z0), (x0, y_front, z0),
        (x0 * 0.985, y_back, z1), (x1 * 0.985, y_back, z1),
        (x1 * 0.94, y_front, z1 - height * 0.14), (x0 * 0.94, y_front, z1 - height * 0.14),
    ]
    faces = [
        (0, 3, 2, 1), (4, 5, 6, 7),
        (0, 1, 5, 4), (1, 2, 6, 5),
        (2, 3, 7, 6), (3, 0, 4, 7),
    ]
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    return bind_new(obj, rig, root, collection, material, bone_name, bevel=0.006, subdiv=1)


def refine_coat_torso():
    obj = bpy.data.objects["VK_PM01_CoatTorso"]
    for vertex in obj.data.vertices:
        co = vertex.co
        chest = clamp((co.z - 1.22) / 0.43)
        shoulder = clamp((co.z - 1.48) / 0.16)
        co.y *= 1.10 + chest * 0.07
        co.x *= 0.985 + shoulder * 0.055
    obj.data.update()
    smart_uv(obj)


def refine_pelvis():
    obj = bpy.data.objects["VK_PM01_UndersuitPelvis"]
    for vertex in obj.data.vertices:
        vertex.co.y *= 1.10
    obj.data.update()
    smart_uv(obj)


def refine_coat_panels():
    for obj in [item for item in bpy.data.objects if item.name.startswith("VK_PM01_CoatFront_") or item.name.startswith("VK_PM01_CoatBack_")]:
        side = 1.0 if obj.name.endswith("_L") else -1.0
        is_back = "CoatBack" in obj.name
        for vertex in obj.data.vertices:
            co = vertex.co
            t = clamp((1.14 - co.z) / 0.52)
            # Extend past the knee and create an actual coat flare rather than shorts.
            co.z -= 0.135 * (t ** 1.45)
            co.x += side * (0.020 * t + 0.026 * t * t)
            co.y *= 1.10 if is_back else 1.12
            if not is_back:
                # Keep a readable front opening down the center line.
                inner_distance = abs(co.x)
                if inner_distance < 0.075:
                    co.x = side * max(inner_distance, 0.030 + 0.025 * t)
            else:
                co.x += side * 0.012 * t
        obj.data.update()
        smart_uv(obj)


def refine_boots():
    for side, center_x in (("L", 0.098), ("R", -0.098)):
        obj = bpy.data.objects[f"VK_PM01_Boot_{side}"]
        for vertex in obj.data.vertices:
            co = vertex.co
            co.x = center_x + (co.x - center_x) * 0.86
            if co.y < 0.0:
                co.y *= 0.88
            co.z = 0.018 + (co.z - 0.018) * 0.88
        obj.data.update()
        smart_uv(obj)


def refine_head_and_mask():
    head = bpy.data.objects["VK_PM01_Head"]
    for vertex in head.data.vertices:
        co = vertex.co
        co.y *= 1.10
        if co.z < -0.025:
            co.x *= 0.92
            if co.y < 0.0:
                co.y *= 1.06
    head.data.update()
    smart_uv(head)
    respirator = bpy.data.objects["VK_PM01_Respirator"]
    respirator.location.y -= 0.028
    respirator.scale.y *= 1.30
    status = bpy.data.objects["VK_PM01_RespiratorStatus"]
    status.location.y -= 0.038


def refine_glove():
    glove = bpy.data.objects["VK_PM01_Glove_R"]
    for vertex in glove.data.vertices:
        co = vertex.co
        if co.z < 0:
            co.x *= 0.88
        if co.y < 0:
            co.y *= 1.08
    glove.data.update()
    smart_uv(glove)


def main():
    args = arguments()
    rig = bpy.data.objects["Armature"]
    root = bpy.data.objects["ROOT_CharacterFacing"]
    collection = bpy.data.collections["COLLECTION_VesperKane_ProductionMesh_v01"]
    collection.name = "COLLECTION_VesperKane_ProductionMesh_v11"

    refine_coat_torso()
    refine_pelvis()
    refine_coat_panels()
    refine_boots()
    refine_head_and_mask()
    refine_glove()

    coat_edge = bpy.data.materials["VK_PM01_CoatEdge"]
    leather = bpy.data.materials["VK_PM01_Leather"]
    dark_metal = bpy.data.materials["VK_PM01_DarkMetal"]

    # Rounded shoulder transitions cover the sleeve/torso junctions cleanly.
    for side in ("L", "R"):
        bone_name = f"DEF-upper_arm.{side}"
        center = rig.data.bones[bone_name].head_local + Vector((0, 0.002, 0.006))
        cap_scale = Vector((0.105, 0.094, 0.092)) if side == "L" else Vector((0.090, 0.082, 0.078))
        cap = ellipsoid(
            f"VK_PM11_ShoulderCap_{side}", center,
            cap_scale, bone_name,
            rig, root, collection, dark_metal if side == "L" else coat_edge,
        )
        cap["steamtek_transition_role"] = "shoulder_sleeve_bridge"

    # A glove cuff and thumb break the mitten silhouette without excess pieces.
    hand = (rig.data.bones["DEF-hand.R"].head_local + rig.data.bones["DEF-hand.R"].tail_local) * 0.5
    torus(
        "VK_PM11_GloveCuff_R", hand + Vector((0, 0.010, 0.070)),
        0.056, 0.011, "DEF-hand.R", rig, root, collection, coat_edge,
        scale_y=0.88, align_to_bone=True,
    )
    ellipsoid(
        "VK_PM11_GloveThumb_R", hand + Vector((-0.058, -0.018, -0.012)),
        Vector((0.026, 0.030, 0.048)), "DEF-hand.R",
        rig, root, collection, leather, front_bias=0.08,
    )

    # A small chin guard gives the respirator a legible profile at the locked camera.
    head_center = (rig.data.bones["DEF-spine.006"].head_local + rig.data.bones["DEF-spine.006"].tail_local) * 0.5 + Vector((0, -0.014, 0.040))
    wedge(
        "VK_PM11_ChinGuard", head_center + Vector((0, -0.132, -0.082)),
        0.070, 0.052, 0.060, "DEF-spine.006",
        rig, root, collection, dark_metal,
    )

    collection["steamtek_stage"] = "production_mesh_v11_silhouette_approval"
    collection["source_production_mesh"] = "v01"
    collection["mechanical_arm_side"] = "physical_left"
    collection["skeleton_changed"] = False
    collection["animation_changed"] = False
    collection["scale_changed"] = False
    collection["uv_ready"] = True
    bpy.context.scene["steamtek_character_status"] = "production_mesh_v11_ready_for_review"
    bpy.context.scene.frame_set(1)

    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    meshes = [obj for obj in collection.objects if obj.type == "MESH"]
    print(f"VESPER_PRODUCTION_V11_BLEND={args.output.resolve()}")
    print(f"VESPER_PRODUCTION_V11_MESHES={len(meshes)}")
    print(f"VESPER_PRODUCTION_V11_VERTICES={sum(len(obj.data.vertices) for obj in meshes)}")
    print("VESPER_PRODUCTION_V11_MECHANICAL_ARM=physical_left")


if __name__ == "__main__":
    main()
