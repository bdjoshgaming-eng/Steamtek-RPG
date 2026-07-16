"""Refine Vesper Kane rig-fit v0.1 into the v0.2 silhouette/detail review."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


CHARACTER_ID = "Steamtek_C001_VesperKane"


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def center(rig, bone_name):
    bone = rig.data.bones[bone_name]
    return (bone.head_local + bone.tail_local) * 0.5


def move_to_collection(obj, target):
    if target.objects.get(obj.name) is None:
        target.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != target:
            owner.objects.unlink(obj)


def bind(obj, rig, bone_name, root, collection, mat, bevel=0.003):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    mod = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    mod.object = rig
    mod.use_deform_preserve_volume = True
    obj.parent = root
    if mat:
        obj.data.materials.append(mat)
    obj["steamtek_character_id"] = CHARACTER_ID
    obj["steamtek_bound_bone"] = bone_name
    obj["steamtek_stage"] = "rig_fit_v02"
    if bevel > 0:
        bevel_mod = obj.modifiers.new(name="VK_v02_SurfaceBevel", type="BEVEL")
        bevel_mod.width = bevel
        bevel_mod.segments = 2
        bevel_mod.limit_method = "ANGLE"
    move_to_collection(obj, collection)
    obj.select_set(False)
    return obj


def cube(name, rig, bone, location, scale, root, collection, mat, rotation=(0, 0, 0), bevel=0.003):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat, bevel)


def sphere(name, rig, bone, location, scale, root, collection, mat, bevel=0.0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat, bevel)


def cylinder(name, rig, bone, location, radius, depth, root, collection, mat,
             vertices=20, rotation=(0, 0, 0), bevel=0.002):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    return bind(obj, rig, bone, root, collection, mat, bevel)


def edge_wear_material(name, base, metallic, roughness):
    mat = bpy.data.materials.get(name)
    if not mat:
        mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*base, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = 0.12
    bsdf.inputs["Coat Roughness"].default_value = min(roughness + 0.1, 1.0)
    return mat


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    collection = bpy.data.collections.get("COLLECTION_VesperKane_RigFit_v01")
    if not rig or not root or not collection:
        raise RuntimeError("Open the Vesper rig-fit v0.1 blend first")
    collection.name = "COLLECTION_VesperKane_RigFit_v02"

    coat = bpy.data.materials.get("VK_WeatheredBlackCoat")
    coat_edge = bpy.data.materials.get("VK_CoatEdge")
    gunmetal = edge_wear_material("VK_v02_Gunmetal", (0.052, 0.062, 0.070), 0.82, 0.31)
    brass = edge_wear_material("VK_v02_AgedBrass", (0.25, 0.095, 0.025), 0.84, 0.34)
    leather = edge_wear_material("VK_v02_BlackLeather", (0.020, 0.016, 0.015), 0.03, 0.51)
    cyan = bpy.data.materials.get("VK_CyanTech")
    skin = bpy.data.materials.get("VK_Skin")

    chest = center(rig, "DEF-spine.003")
    abdomen = center(rig, "DEF-spine.001")
    head = center(rig, "DEF-spine.006") + Vector((0, -0.01, 0.04))
    left_upper = center(rig, "DEF-upper_arm.L")
    left_forearm = center(rig, "DEF-forearm.L")
    left_hand = center(rig, "DEF-hand.L")

    # Refine the hat from a smooth cylinder into a more readable engineered silhouette.
    crown = bpy.data.objects.get("VK_HatCrown")
    if crown:
        for vert in crown.data.vertices:
            vert.co.z *= 0.90
        crown.data.update()
    cylinder("VK_v02_HatTopPlate", rig, "DEF-spine.006", head + Vector((0, 0.015, 0.485)),
             0.145, 0.024, root, collection, gunmetal, vertices=32)
    cube("VK_v02_HatBandClasp", rig, "DEF-spine.006", head + Vector((0.105, -0.112, 0.215)),
         (0.025, 0.012, 0.032), root, collection, brass)
    for x in (-0.09, 0.09):
        cube(f"VK_v02_HatVent_{x:+.2f}", rig, "DEF-spine.006",
             head + Vector((x, -0.147, 0.34)), (0.025, 0.008, 0.050),
             root, collection, gunmetal)

    # Face and scarf read at the locked camera distance without becoming ornate.
    cube("VK_v02_FaceShadow", rig, "DEF-spine.006", head + Vector((0, -0.116, -0.015)),
         (0.082, 0.012, 0.073), root, collection, leather)
    cube("VK_v02_NoseBridge", rig, "DEF-spine.006", head + Vector((0, -0.132, 0.025)),
         (0.018, 0.010, 0.038), root, collection, skin)
    cube("VK_v02_ScarfFront", rig, "DEF-spine.005", head + Vector((0, -0.132, -0.13)),
         (0.145, 0.026, 0.075), root, collection, coat_edge)
    cube("VK_v02_ScarfTail_R", rig, "DEF-spine.004", chest + Vector((-0.19, 0.08, 0.11)),
         (0.060, 0.025, 0.22), root, collection, coat_edge, rotation=(0.10, 0.0, -0.20))

    # Coat structure: shoulder cape, seams, closures, asymmetric hem hardware.
    cube("VK_v02_ShoulderCape", rig, "DEF-spine.004", chest + Vector((0, 0.02, 0.16)),
         (0.27, 0.15, 0.055), root, collection, coat)
    for x in (-0.185, 0.185):
        sphere(f"VK_v02_ShoulderCap_{x:+.3f}", rig, "DEF-spine.004",
               chest + Vector((x, 0.0, 0.13)), (0.115, 0.105, 0.085),
               root, collection, coat_edge)
    for z in (0.13, 0.03, -0.07, -0.17):
        cylinder(f"VK_v02_CoatButton_{z:+.2f}", rig, "DEF-spine.003",
                 chest + Vector((0.045, -0.154, z)), 0.018, 0.012,
                 root, collection, brass, vertices=16, rotation=(math.pi / 2, 0, 0), bevel=0.001)
    cube("VK_v02_CoatHem_L", rig, "DEF-thigh.L", abdomen + Vector((0.115, -0.065, -0.655)),
         (0.165, 0.018, 0.026), root, collection, coat_edge, rotation=(0, 0, -0.08))
    cube("VK_v02_CoatHem_R", rig, "DEF-thigh.R", abdomen + Vector((-0.115, -0.065, -0.655)),
         (0.165, 0.018, 0.026), root, collection, coat_edge, rotation=(0, 0, 0.08))
    cube("VK_v02_CoatSideBuckle_R", rig, "DEF-spine.001", abdomen + Vector((-0.245, -0.10, -0.12)),
         (0.040, 0.020, 0.050), root, collection, brass)

    # Mechanical arm: readable joints, piston, cable, wrist and finger plates.
    sphere("VK_v02_MechElbow_L", rig, "DEF-forearm.L", left_forearm + Vector((0, 0, 0.145)),
           (0.105, 0.095, 0.105), root, collection, gunmetal)
    cylinder("VK_v02_Piston_L", rig, "DEF-forearm.L", left_forearm + Vector((0.070, -0.080, 0)),
             0.020, 0.235, root, collection, brass, vertices=16)
    cylinder("VK_v02_PistonRod_L", rig, "DEF-forearm.L", left_forearm + Vector((0.070, -0.101, 0)),
             0.010, 0.255, root, collection, gunmetal, vertices=12)
    cube("VK_v02_WristHousing_L", rig, "DEF-hand.L", left_hand + Vector((0, 0, 0.015)),
         (0.085, 0.070, 0.060), root, collection, gunmetal)
    for index, x in enumerate((-0.060, -0.020, 0.020, 0.060)):
        cube(f"VK_v02_FingerPlate_L_{index}", rig, "DEF-hand.L",
             left_hand + Vector((x, -0.060, -0.075)), (0.015, 0.018, 0.050),
             root, collection, brass)
    cube("VK_v02_ArmStatus_L", rig, "DEF-upper_arm.L", left_upper + Vector((0, -0.105, 0.035)),
         (0.018, 0.008, 0.055), root, collection, cyan)

    # Boots and lower-body straps improve contact and preserve a practical runner silhouette.
    for side, sign in (("L", 1.0), ("R", -1.0)):
        shin = center(rig, f"DEF-shin.{side}")
        foot = center(rig, f"DEF-foot.{side}")
        cube(f"VK_v02_KneePlate_{side}", rig, f"DEF-shin.{side}",
             shin + Vector((0, -0.080, 0.075)), (0.085, 0.030, 0.070),
             root, collection, gunmetal)
        for z in (-0.075, 0.035):
            cube(f"VK_v02_BootStrap_{side}_{z:+.3f}", rig, f"DEF-shin.{side}",
                 shin + Vector((0, -0.070, z)), (0.080, 0.018, 0.018),
                 root, collection, leather)
        cube(f"VK_v02_BootToeCap_{side}", rig, f"DEF-foot.{side}",
             foot + Vector((0, -0.095, -0.020)), (0.100, 0.070, 0.042),
             root, collection, gunmetal)

    # Compact utility details, deliberately less decorative than Victorian steampunk.
    cube("VK_v02_Holster_R", rig, "DEF-spine.001", abdomen + Vector((-0.32, 0.015, -0.19)),
         (0.050, 0.040, 0.145), root, collection, leather)
    cube("VK_v02_PressureCell_R", rig, "DEF-spine.001", abdomen + Vector((-0.30, -0.065, -0.02)),
         (0.035, 0.028, 0.080), root, collection, brass)
    cube("VK_v02_PressureCellGlow_R", rig, "DEF-spine.001", abdomen + Vector((-0.30, -0.096, -0.02)),
         (0.012, 0.005, 0.040), root, collection, cyan)

    collection["steamtek_stage"] = "rig_fit_v02_refined_silhouette"
    collection["mechanical_arm_side"] = "physical_left"
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v02_ready_for_engine_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_V02_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_V02_OBJECTS={len([o for o in bpy.data.objects if o.name.startswith('VK_')])}")


if __name__ == "__main__":
    main()
