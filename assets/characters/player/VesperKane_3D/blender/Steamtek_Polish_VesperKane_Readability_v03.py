"""Gameplay-distance readability pass for Vesper Kane rig-fit v0.3."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def center(rig, bone_name):
    bone = rig.data.bones[bone_name]
    return (bone.head_local + bone.tail_local) * 0.5


def set_principled(mat_name, base, metallic, roughness, emission=None, strength=0.0):
    mat = bpy.data.materials.get(mat_name)
    if not mat:
        raise RuntimeError(f"Missing material: {mat_name}")
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


def move_to_collection(obj, collection):
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)


def cube(name, rig, bone_name, location, scale, root, collection, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    arm = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    arm.object = rig
    arm.use_deform_preserve_volume = True
    obj.parent = root
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new(name="VK_v03_ReadabilityBevel", type="BEVEL")
    bevel.width = 0.003
    bevel.segments = 2
    bevel.limit_method = "ANGLE"
    obj["steamtek_stage"] = "rig_fit_v03_readability"
    obj["steamtek_bound_bone"] = bone_name
    move_to_collection(obj, collection)
    obj.select_set(False)
    return obj


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    collection = bpy.data.collections.get("COLLECTION_VesperKane_RigFit_v02")
    if not rig or not root or not collection:
        raise RuntimeError("Open Vesper rig-fit v0.2 first")
    collection.name = "COLLECTION_VesperKane_RigFit_v03"

    # Lift only neutral reflectance. Cyan/magenta environmental color remains runtime lighting.
    coat = set_principled("VK_WeatheredBlackCoat", (0.032, 0.040, 0.047), 0.10, 0.57)
    coat_edge = set_principled("VK_CoatEdge", (0.080, 0.095, 0.105), 0.28, 0.42)
    gunmetal = set_principled("VK_v02_Gunmetal", (0.095, 0.110, 0.120), 0.84, 0.29)
    brass = set_principled("VK_v02_AgedBrass", (0.40, 0.16, 0.040), 0.84, 0.32)
    leather = set_principled("VK_v02_BlackLeather", (0.034, 0.028, 0.026), 0.03, 0.50)
    cyan = set_principled("VK_CyanTech", (0.010, 0.18, 0.23), 0.48, 0.20,
                          emission=(0.01, 0.62, 0.88), strength=5.0)

    chest = center(rig, "DEF-spine.003")
    abdomen = center(rig, "DEF-spine.001")
    head = center(rig, "DEF-spine.006") + Vector((0, -0.01, 0.04))
    left_upper = center(rig, "DEF-upper_arm.L")
    left_forearm = center(rig, "DEF-forearm.L")

    # Hat silhouette: visible front ribs and crown edge at the locked 30-degree elevation.
    cube("VK_v03_HatCrownFront", rig, "DEF-spine.006",
         head + Vector((0, -0.126, 0.34)), (0.108, 0.007, 0.118),
         root, collection, coat_edge)
    cube("VK_v03_HatFrontTopEdge", rig, "DEF-spine.006",
         head + Vector((0, -0.120, 0.475)), (0.125, 0.010, 0.012),
         root, collection, gunmetal)
    cube("VK_v03_HatBrimFrontEdge", rig, "DEF-spine.006",
         head + Vector((0, -0.205, 0.170)), (0.205, 0.012, 0.014),
         root, collection, gunmetal)

    # Coat outline: broad, neutral edge strips that catch runtime light without baked neon.
    for x in (-0.205, 0.205):
        cube(f"VK_v03_CoatTorsoEdge_{x:+.3f}", rig, "DEF-spine.003",
             chest + Vector((x, -0.125, -0.035)), (0.014, 0.014, 0.225),
             root, collection, coat_edge)
    cube("VK_v03_CoatShoulderLine", rig, "DEF-spine.004",
         chest + Vector((0, -0.125, 0.195)), (0.245, 0.014, 0.016),
         root, collection, coat_edge)
    for side, x in (("L", 0.135), ("R", -0.135)):
        cube(f"VK_v03_CoatTailOuter_{side}", rig, f"DEF-thigh.{side}",
             abdomen + Vector((x, -0.064, -0.40)), (0.018, 0.014, 0.285),
             root, collection, coat_edge)
    cube("VK_v03_BeltUpperEdge", rig, "DEF-spine.001",
         abdomen + Vector((0, -0.155, -0.055)), (0.235, 0.010, 0.010),
         root, collection, brass)

    # Mechanical arm reads as a separate material mass under cool or magenta lights.
    cube("VK_v03_MechUpperArmPlate_L", rig, "DEF-upper_arm.L",
         left_upper + Vector((0, -0.095, 0.015)), (0.090, 0.020, 0.145),
         root, collection, brass)
    cube("VK_v03_MechForearmSpine_L", rig, "DEF-forearm.L",
         left_forearm + Vector((0, -0.135, 0.0)), (0.022, 0.018, 0.145),
         root, collection, gunmetal)
    cube("VK_v03_MechArmCyanTick_L", rig, "DEF-forearm.L",
         left_forearm + Vector((0, -0.158, -0.065)), (0.014, 0.006, 0.038),
         root, collection, cyan)

    # Readable boot contact and separation from the coat tails.
    for side in ("L", "R"):
        foot = center(rig, f"DEF-foot.{side}")
        cube(f"VK_v03_BootSole_{side}", rig, f"DEF-foot.{side}",
             foot + Vector((0, -0.010, -0.080)), (0.105, 0.125, 0.020),
             root, collection, gunmetal)
        cube(f"VK_v03_BootFrontEdge_{side}", rig, f"DEF-foot.{side}",
             foot + Vector((0, -0.125, -0.025)), (0.090, 0.012, 0.038),
             root, collection, brass)

    collection["steamtek_stage"] = "rig_fit_v03_gameplay_readability"
    collection["lighting_policy"] = "neutral materials; cyan/magenta supplied by runtime lights"
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v03_ready_for_engine_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_V03_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_V03_OBJECTS={len([o for o in bpy.data.objects if o.name.startswith('VK_')])}")


if __name__ == "__main__":
    main()
