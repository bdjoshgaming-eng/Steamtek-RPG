"""Correct Vesper Kane's thin side profile while preserving rig height and origin."""

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


def deepen_mesh(name, factor):
    obj = bpy.data.objects.get(name)
    if not obj or obj.type != "MESH" or not obj.data.vertices:
        return False
    pivot = sum(vertex.co.y for vertex in obj.data.vertices) / len(obj.data.vertices)
    for vertex in obj.data.vertices:
        vertex.co.y = pivot + (vertex.co.y - pivot) * factor
    obj.data.update()
    obj["steamtek_depth_factor_v05"] = factor
    return True


def move_to_collection(obj, collection):
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)


def bind(obj, rig, bone_name, root, collection, mat, bevel=0.003):
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
    if bevel > 0:
        mod = obj.modifiers.new(name="VK_v05_VolumeBevel", type="BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
    obj["steamtek_stage"] = "rig_fit_v05_volume"
    obj["steamtek_bound_bone"] = bone_name
    move_to_collection(obj, collection)
    obj.select_set(False)
    return obj


def cube(name, rig, bone, location, scale, root, collection, mat):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat)


def cylinder(name, rig, bone, location, radius, depth, root, collection, mat, vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    return bind(obj, rig, bone, root, collection, mat)


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    collection = bpy.data.collections.get("COLLECTION_VesperKane_RigFit_v04")
    if not rig or not root or not collection:
        raise RuntimeError("Open Vesper rig-fit v0.4 first")
    collection.name = "COLLECTION_VesperKane_RigFit_v05"

    # Increase front-to-back volume only; do not alter height, width, boots contact, or rig scale.
    depth_targets = {
        "VK_CoatTorso": 1.34,
        "VK_CoatTail_L": 1.42,
        "VK_CoatTail_R": 1.42,
        "VK_CoatTail_Back": 1.30,
        "VK_v02_ShoulderCape": 1.22,
        "VK_Head": 1.10,
        "VK_HatCrown": 1.10,
        "VK_HatBrim": 1.08,
        "VK_v02_BootToeCap_L": 1.14,
        "VK_v02_BootToeCap_R": 1.14,
        "VK_v03_BootSole_L": 1.12,
        "VK_v03_BootSole_R": 1.12,
    }
    adjusted = [name for name, factor in depth_targets.items() if deepen_mesh(name, factor)]

    coat = bpy.data.materials["VK_WeatheredBlackCoat"]
    coat_edge = bpy.data.materials["VK_CoatEdge"]
    gunmetal = bpy.data.materials["VK_v02_Gunmetal"]
    brass = bpy.data.materials["VK_v02_AgedBrass"]
    leather = bpy.data.materials["VK_v02_BlackLeather"]
    cyan = bpy.data.materials["VK_CyanTech"]

    chest = center(rig, "DEF-spine.003")
    abdomen = center(rig, "DEF-spine.001")

    # Side gussets make the long coat read as constructed clothing, not a flat card.
    for side, x in (("L", 0.225), ("R", -0.225)):
        cube(f"VK_v05_CoatSideGusset_{side}", rig, "DEF-spine.003",
             chest + Vector((x, 0.015, -0.055)), (0.022, 0.145, 0.205),
             root, collection, coat_edge)
        cube(f"VK_v05_CoatSideTail_{side}", rig, f"DEF-thigh.{side}",
             abdomen + Vector((x, 0.040, -0.405)), (0.030, 0.105, 0.275),
             root, collection, coat)

    # Compact back regulator provides believable profile mass without becoming a backpack silhouette.
    cube("VK_v05_BackRegulatorBody", rig, "DEF-spine.003",
         chest + Vector((0, 0.215, 0.015)), (0.145, 0.055, 0.155),
         root, collection, gunmetal)
    for x in (-0.082, 0.082):
        cylinder(f"VK_v05_BackPressureCell_{x:+.3f}", rig, "DEF-spine.003",
                 chest + Vector((x, 0.285, 0.015)), 0.042, 0.245,
                 root, collection, brass, vertices=20)
    cube("VK_v05_BackRegulatorFrameTop", rig, "DEF-spine.003",
         chest + Vector((0, 0.275, 0.165)), (0.175, 0.020, 0.018),
         root, collection, gunmetal)
    cube("VK_v05_BackRegulatorFrameBottom", rig, "DEF-spine.003",
         chest + Vector((0, 0.275, -0.145)), (0.175, 0.020, 0.018),
         root, collection, gunmetal)
    cube("VK_v05_BackRegulatorStatus", rig, "DEF-spine.003",
         chest + Vector((0, 0.333, 0.015)), (0.020, 0.006, 0.060),
         root, collection, cyan)

    # Front placket and belt depth balance the regulator from the side.
    cube("VK_v05_CoatFrontPlacket", rig, "DEF-spine.003",
         chest + Vector((0.015, -0.178, -0.050)), (0.050, 0.018, 0.205),
         root, collection, leather)
    cube("VK_v05_BeltDepth", rig, "DEF-spine.001",
         abdomen + Vector((0, -0.168, -0.080)), (0.225, 0.020, 0.036),
         root, collection, leather)

    collection["steamtek_stage"] = "rig_fit_v05_profile_volume"
    collection["depth_adjusted_objects"] = ",".join(adjusted)
    collection["height_scale_changed"] = False
    collection["mechanical_arm_side"] = "physical_left"
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v05_ready_for_engine_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_V05_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_V05_DEPTH_ADJUSTED={len(adjusted)}")
    print(f"VESPER_RIG_FIT_V05_OBJECTS={len([o for o in bpy.data.objects if o.name.startswith('VK_')])}")


if __name__ == "__main__":
    main()
