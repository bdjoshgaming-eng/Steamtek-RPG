"""Build Vesper Kane rig-fit silhouette v0.1 on the proven Steamtek human rig.

This is deliberately a silhouette/rig-fit review asset, not the final sculpt.
It preserves the approved Armature, STK_IDLE, STK_WALK, roots, scale, and origin.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


CHARACTER_ID = "Steamtek_C001_VesperKane"
COLLECTION_NAME = "COLLECTION_VesperKane_RigFit_v01"


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--pipeline-scripts", type=Path, required=True)
    parser.add_argument("--concept", type=Path, required=True)
    return parser.parse_args(argv)


def remove_collection(name):
    collection = bpy.data.collections.get(name)
    if not collection:
        return
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(collection)


def material(name, base, metallic=0.0, roughness=0.5, emission=None, strength=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*base, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission and "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def bone_center(rig, name):
    bone = rig.data.bones[name]
    return (bone.head_local + bone.tail_local) * 0.5


def tapered_panel(name, rig, bone_name, center, top_half_width, bottom_half_width,
                  half_depth, height, facing_root, collection, mat):
    """Create a low-poly tapered coat panel, with -Y as the front."""
    z0 = center.z - height * 0.5
    z1 = center.z + height * 0.5
    y0 = center.y - half_depth
    y1 = center.y + half_depth
    verts = [
        (center.x - bottom_half_width, y0, z0),
        (center.x + bottom_half_width, y0, z0),
        (center.x + bottom_half_width, y1, z0),
        (center.x - bottom_half_width, y1, z0),
        (center.x - top_half_width, y0, z1),
        (center.x + top_half_width, y0, z1),
        (center.x + top_half_width, y1, z1),
        (center.x - top_half_width, y1, z1),
    ]
    faces = [
        (0, 1, 2, 3), (4, 7, 6, 5),
        (0, 4, 5, 1), (1, 5, 6, 2),
        (2, 6, 7, 3), (4, 0, 3, 7),
    ]
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    return bind_object(obj, rig, bone_name, facing_root, collection, mat)


def bind_object(obj, rig, bone_name, root, collection, mat):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    mod = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    mod.object = rig
    mod.use_deform_preserve_volume = True
    obj.parent = root
    obj.data.materials.append(mat)
    obj["steamtek_character_id"] = CHARACTER_ID
    obj["steamtek_bound_bone"] = bone_name
    obj["steamtek_stage"] = "rig_fit_v01"
    obj.select_set(False)
    return obj


def cylinder_for_bone(rig, bone_name, radius, root, collection, mat, scale=0.92, vertices=16):
    bone = rig.data.bones[bone_name]
    direction = bone.tail_local - bone.head_local
    length = max(direction.length * scale, 0.03)
    midpoint = (bone.head_local + bone.tail_local) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=length, location=midpoint)
    obj = bpy.context.object
    obj.name = f"VK_{bone_name.replace('.', '_')}"
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    return bind_object(obj, rig, bone_name, root, collection, mat)


def cube_part(name, rig, bone_name, location, scale, root, collection, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind_object(obj, rig, bone_name, root, collection, mat)


def sphere_part(name, rig, bone_name, location, scale, root, collection, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind_object(obj, rig, bone_name, root, collection, mat)


def cylinder_part(name, rig, bone_name, location, radius, depth, root, collection, mat,
                  vertices=24, scale_top=1.0):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius * scale_top,
                                   depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    return bind_object(obj, rig, bone_name, root, collection, mat)


def torus_part(name, rig, bone_name, location, major_radius, minor_radius, root, collection, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius, minor_radius=minor_radius,
                                    major_segments=28, minor_segments=8, location=location)
    obj = bpy.context.object
    obj.name = name
    return bind_object(obj, rig, bone_name, root, collection, mat)


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    facing_root = bpy.data.objects.get("ROOT_CharacterFacing")
    if not rig or not facing_root:
        raise RuntimeError("Approved Steamtek rig and facing root are required")

    # Preserve the rig/actions but remove all proof-character render geometry.
    remove_collection("COLLECTION_Steamtek_C002")
    remove_collection(COLLECTION_NAME)
    collection = bpy.data.collections.new(COLLECTION_NAME)
    bpy.context.scene.collection.children.link(collection)

    coat = material("VK_WeatheredBlackCoat", (0.018, 0.024, 0.030), 0.12, 0.58)
    coat_edge = material("VK_CoatEdge", (0.045, 0.055, 0.062), 0.20, 0.43)
    gunmetal = material("VK_Gunmetal", (0.060, 0.072, 0.080), 0.78, 0.30)
    brass = material("VK_AgedBrass", (0.28, 0.12, 0.035), 0.82, 0.31)
    leather = material("VK_BlackLeather", (0.025, 0.019, 0.017), 0.05, 0.48)
    skin = material("VK_Skin", (0.34, 0.16, 0.09), 0.0, 0.62)
    cyan = material("VK_CyanTech", (0.008, 0.14, 0.18), 0.45, 0.22,
                    emission=(0.01, 0.55, 0.82), strength=4.0)

    # Fitted rig-following body under the silhouette pieces.
    parts = [
        ("DEF-spine", 0.145, leather), ("DEF-spine.001", 0.165, coat),
        ("DEF-spine.002", 0.185, coat), ("DEF-spine.003", 0.195, coat),
        ("DEF-spine.004", 0.175, coat),
        ("DEF-pelvis.L", 0.112, leather), ("DEF-pelvis.R", 0.112, leather),
        ("DEF-thigh.L", 0.092, leather), ("DEF-thigh.L.001", 0.088, leather),
        ("DEF-thigh.R", 0.092, leather), ("DEF-thigh.R.001", 0.088, leather),
        ("DEF-shin.L", 0.075, leather), ("DEF-shin.L.001", 0.070, leather),
        ("DEF-shin.R", 0.075, leather), ("DEF-shin.R.001", 0.070, leather),
        ("DEF-foot.L", 0.098, gunmetal), ("DEF-toe.L", 0.105, gunmetal),
        ("DEF-foot.R", 0.098, gunmetal), ("DEF-toe.R", 0.105, gunmetal),
        ("DEF-shoulder.L", 0.095, coat_edge), ("DEF-shoulder.R", 0.095, coat_edge),
        # Mechanical arm is physical LEFT and remains mechanically distinct.
        ("DEF-upper_arm.L", 0.088, brass), ("DEF-upper_arm.L.001", 0.084, gunmetal),
        ("DEF-forearm.L", 0.092, brass), ("DEF-forearm.L.001", 0.088, gunmetal),
        ("DEF-hand.L", 0.076, brass),
        ("DEF-upper_arm.R", 0.073, coat), ("DEF-upper_arm.R.001", 0.070, coat),
        ("DEF-forearm.R", 0.060, leather), ("DEF-forearm.R.001", 0.057, leather),
        ("DEF-hand.R", 0.063, skin),
    ]
    for bone, radius, mat in parts:
        cylinder_for_bone(rig, bone, radius, facing_root, collection, mat)

    chest = bone_center(rig, "DEF-spine.003")
    abdomen = bone_center(rig, "DEF-spine.001")
    head = bone_center(rig, "DEF-spine.006") + Vector((0, -0.01, 0.04))
    left_forearm = bone_center(rig, "DEF-forearm.L")

    # High-collared long coat, split into thigh-following tails for walk compatibility.
    sphere_part("VK_CoatTorso", rig, "DEF-spine.003", chest + Vector((0, 0.01, -0.02)),
                (0.225, 0.135, 0.235), facing_root, collection, coat)
    cube_part("VK_CoatLapel_L", rig, "DEF-spine.003", chest + Vector((0.075, -0.145, 0.02)),
              (0.065, 0.016, 0.19), facing_root, collection, coat_edge, rotation=(0, 0.18, -0.18))
    cube_part("VK_CoatLapel_R", rig, "DEF-spine.003", chest + Vector((-0.075, -0.145, 0.02)),
              (0.065, 0.016, 0.19), facing_root, collection, coat_edge, rotation=(0, -0.18, 0.18))
    tapered_panel("VK_CoatTail_L", rig, "DEF-thigh.L", abdomen + Vector((0.115, 0.025, -0.34)),
                  0.105, 0.165, 0.075, 0.68, facing_root, collection, coat)
    tapered_panel("VK_CoatTail_R", rig, "DEF-thigh.R", abdomen + Vector((-0.115, 0.025, -0.34)),
                  0.105, 0.165, 0.075, 0.68, facing_root, collection, coat)
    tapered_panel("VK_CoatTail_Back", rig, "DEF-spine.001", abdomen + Vector((0, 0.105, -0.34)),
                  0.20, 0.27, 0.045, 0.70, facing_root, collection, coat)
    cube_part("VK_WaistBelt", rig, "DEF-spine.001", abdomen + Vector((0, -0.01, -0.08)),
              (0.245, 0.145, 0.034), facing_root, collection, leather)
    cube_part("VK_BeltBuckle", rig, "DEF-spine.001", abdomen + Vector((0, -0.16, -0.08)),
              (0.045, 0.012, 0.035), facing_root, collection, brass)

    # Head, scarf/high collar, signature top hat, and cyan monocle.
    sphere_part("VK_Head", rig, "DEF-spine.006", head, (0.132, 0.122, 0.16),
                facing_root, collection, skin)
    torus_part("VK_HighCollar", rig, "DEF-spine.005", head + Vector((0, 0, -0.16)),
               0.14, 0.035, facing_root, collection, coat_edge)
    cylinder_part("VK_HatBrim", rig, "DEF-spine.006", head + Vector((0, 0, 0.17)),
                  0.225, 0.035, facing_root, collection, gunmetal, vertices=32)
    cylinder_part("VK_HatCrown", rig, "DEF-spine.006", head + Vector((0, 0.015, 0.34)),
                  0.155, 0.34, facing_root, collection, coat, vertices=32, scale_top=0.88)
    cylinder_part("VK_HatBand", rig, "DEF-spine.006", head + Vector((0, 0.014, 0.215)),
                  0.162, 0.055, facing_root, collection, brass, vertices=32)
    sphere_part("VK_Monocle_Cyan", rig, "DEF-spine.006", head + Vector((-0.062, -0.121, 0.035)),
                (0.032, 0.013, 0.032), facing_root, collection, cyan)

    # Mechanical left arm construction and readable pressure gauge.
    cube_part("VK_MechShoulder_L", rig, "DEF-upper_arm.L", bone_center(rig, "DEF-upper_arm.L"),
              (0.115, 0.10, 0.12), facing_root, collection, gunmetal)
    cube_part("VK_MechForearmHousing_L", rig, "DEF-forearm.L", left_forearm + Vector((0, -0.055, 0)),
              (0.105, 0.075, 0.15), facing_root, collection, brass)
    for z in (-0.10, -0.035, 0.035, 0.10):
        cube_part(f"VK_MechArmBand_L_{z:+.3f}", rig, "DEF-forearm.L",
                  left_forearm + Vector((0, -0.13, z)), (0.11, 0.014, 0.012),
                  facing_root, collection, gunmetal)
    sphere_part("VK_PressureGauge_L", rig, "DEF-forearm.L", left_forearm + Vector((0, -0.15, 0.045)),
                (0.055, 0.022, 0.055), facing_root, collection, gunmetal)
    cube_part("VK_PressureGaugeGlow_L", rig, "DEF-forearm.L", left_forearm + Vector((0, -0.174, 0.045)),
              (0.023, 0.006, 0.013), facing_root, collection, cyan)

    # Asymmetrical hip rig and restrained cyan technology accents.
    cube_part("VK_HipRig_R", rig, "DEF-spine.001", abdomen + Vector((-0.27, -0.02, -0.13)),
              (0.065, 0.045, 0.105), facing_root, collection, gunmetal)
    cube_part("VK_HipRigGlow_R", rig, "DEF-spine.001", abdomen + Vector((-0.27, -0.068, -0.13)),
              (0.024, 0.006, 0.055), facing_root, collection, cyan)

    # Consistent surface treatment for the review pass.
    for obj in collection.objects:
        obj.hide_render = False
        if obj.type == "MESH":
            for poly in obj.data.polygons:
                poly.use_smooth = True
            bevel = obj.modifiers.new(name="VK_RigFitBevel", type="BEVEL")
            bevel.width = 0.004
            bevel.segments = 2
            bevel.limit_method = "ANGLE"

    collection["steamtek_character_id"] = CHARACTER_ID
    collection["steamtek_stage"] = "rig_fit_v01_silhouette_review"
    collection["mechanical_arm_side"] = "physical_left"
    bpy.context.scene["steamtek_character_id"] = CHARACTER_ID
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v01_ready_for_review"
    bpy.context.scene["steamtek_concept"] = str(args.concept.resolve())
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)

    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_PARTS={len(collection.objects)}")
    print("VESPER_MECHANICAL_ARM=physical_left")


if __name__ == "__main__":
    main()
