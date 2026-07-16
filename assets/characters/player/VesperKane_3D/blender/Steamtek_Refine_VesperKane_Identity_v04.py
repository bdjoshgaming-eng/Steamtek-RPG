"""Vesper Kane identity-detail pass v0.4 on the validated v0.3 rig fit."""

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


def move_to_collection(obj, collection):
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)


def bind(obj, rig, bone_name, root, collection, mat, bevel=0.0025):
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
        mod = obj.modifiers.new(name="VK_v04_IdentityBevel", type="BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
    obj["steamtek_character_id"] = CHARACTER_ID
    obj["steamtek_bound_bone"] = bone_name
    obj["steamtek_stage"] = "rig_fit_v04_identity"
    move_to_collection(obj, collection)
    obj.select_set(False)
    return obj


def cube(name, rig, bone, location, scale, root, collection, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat)


def cylinder(name, rig, bone, location, radius, depth, root, collection, mat,
             vertices=20, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    return bind(obj, rig, bone, root, collection, mat)


def sphere(name, rig, bone, location, scale, root, collection, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat, bevel=0.0)


def torus(name, rig, bone, location, major_radius, minor_radius, root, collection, mat,
          rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius, minor_radius=minor_radius,
                                    major_segments=28, minor_segments=8,
                                    location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    return bind(obj, rig, bone, root, collection, mat, bevel=0.0)


def hose(name, rig, bone, points, radius, root, collection, mat):
    curve = bpy.data.curves.new(name=f"{name}_Curve", type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, position in zip(spline.bezier_points, points):
        point.co = position
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return bind(obj, rig, bone, root, collection, mat, bevel=0.0)


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    collection = bpy.data.collections.get("COLLECTION_VesperKane_RigFit_v03")
    if not rig or not root or not collection:
        raise RuntimeError("Open Vesper rig-fit v0.3 first")
    collection.name = "COLLECTION_VesperKane_RigFit_v04"

    coat = bpy.data.materials["VK_WeatheredBlackCoat"]
    coat_edge = bpy.data.materials["VK_CoatEdge"]
    gunmetal = bpy.data.materials["VK_v02_Gunmetal"]
    brass = bpy.data.materials["VK_v02_AgedBrass"]
    leather = bpy.data.materials["VK_v02_BlackLeather"]
    cyan = bpy.data.materials["VK_CyanTech"]
    skin = bpy.data.materials["VK_Skin"]

    chest = center(rig, "DEF-spine.003")
    abdomen = center(rig, "DEF-spine.001")
    head = center(rig, "DEF-spine.006") + Vector((0, -0.01, 0.04))
    left_upper = center(rig, "DEF-upper_arm.L")
    left_forearm = center(rig, "DEF-forearm.L")
    right_hand = center(rig, "DEF-hand.R")

    # Make the coat intentionally asymmetric instead of uniformly split.
    right_tail = bpy.data.objects.get("VK_CoatTail_R")
    if right_tail:
        for vertex in right_tail.data.vertices:
            if vertex.co.z < abdomen.z - 0.34:
                vertex.co.z -= 0.10
            vertex.co.x -= 0.015
        right_tail.data.update()
    cube("VK_v04_CoatTailClasp_R", rig, "DEF-thigh.R",
         abdomen + Vector((-0.175, -0.075, -0.60)), (0.045, 0.016, 0.025),
         root, collection, brass)
    cube("VK_v04_CoatSideFlap_L", rig, "DEF-thigh.L",
         abdomen + Vector((0.265, 0.015, -0.42)), (0.060, 0.065, 0.245),
         root, collection, coat, rotation=(0.0, 0.0, -0.10))

    # Hair/scarf silhouette survives the locked camera without becoming a separate costume mass.
    for index, x in enumerate((-0.085, -0.030, 0.030, 0.085)):
        cube(f"VK_v04_HairBack_{index}", rig, "DEF-spine.006",
             head + Vector((x, 0.108, -0.025 - 0.018 * abs(index - 1.5))),
             (0.022, 0.018, 0.115), root, collection, leather,
             rotation=(0.06, 0.0, -0.05 * (index - 1.5)))
    cube("VK_v04_ScarfLongTail", rig, "DEF-spine.004",
         chest + Vector((-0.245, 0.105, -0.02)), (0.055, 0.025, 0.285),
         root, collection, coat_edge, rotation=(0.12, 0.0, -0.20))
    cube("VK_v04_ScarfTailTip", rig, "DEF-spine.003",
         chest + Vector((-0.285, 0.125, -0.28)), (0.068, 0.028, 0.065),
         root, collection, coat_edge, rotation=(0.12, 0.0, -0.32))

    # Signature monocle: frame, glass, bridge clip, and restrained chain.
    monocle_location = head + Vector((-0.062, -0.134, 0.035))
    torus("VK_v04_MonocleFrame", rig, "DEF-spine.006", monocle_location,
          0.040, 0.006, root, collection, brass, rotation=(math.pi / 2, 0, 0))
    cube("VK_v04_MonocleBridgeClip", rig, "DEF-spine.006",
         head + Vector((-0.020, -0.139, 0.040)), (0.022, 0.006, 0.007),
         root, collection, gunmetal)
    hose("VK_v04_MonocleChain", rig, "DEF-spine.006", [
        head + Vector((-0.092, -0.140, 0.008)),
        head + Vector((-0.125, -0.130, -0.060)),
        head + Vector((-0.105, -0.110, -0.145)),
    ], 0.004, root, collection, brass)

    # Mechanical-arm pressure system: shoulder cap, hose, elbow ring, and gauge bezel.
    torus("VK_v04_MechElbowRing_L", rig, "DEF-forearm.L",
          left_forearm + Vector((0, 0, 0.145)), 0.095, 0.012,
          root, collection, brass)
    hose("VK_v04_MechPressureHose_L", rig, "DEF-forearm.L", [
        left_forearm + Vector((0.080, 0.040, 0.135)),
        left_forearm + Vector((0.125, -0.020, 0.050)),
        left_forearm + Vector((0.115, -0.060, -0.115)),
    ], 0.012, root, collection, leather)
    torus("VK_v04_GaugeBezel_L", rig, "DEF-forearm.L",
          left_forearm + Vector((0, -0.172, 0.045)), 0.058, 0.007,
          root, collection, brass, rotation=(math.pi / 2, 0, 0))
    cube("VK_v04_ShoulderPressurePlate_L", rig, "DEF-upper_arm.L",
         left_upper + Vector((0.0, -0.110, 0.105)), (0.080, 0.018, 0.042),
         root, collection, brass)

    # Compact pneumatic sidearm and holster on the non-mechanical side.
    pistol_origin = abdomen + Vector((-0.325, -0.020, -0.20))
    cube("VK_v04_PistolReceiver_R", rig, "DEF-spine.001",
         pistol_origin + Vector((0, -0.050, 0.045)), (0.035, 0.040, 0.095),
         root, collection, gunmetal, rotation=(0.0, 0.0, -0.10))
    cylinder("VK_v04_PistolPressureChamber_R", rig, "DEF-spine.001",
             pistol_origin + Vector((0, -0.070, 0.125)), 0.024, 0.105,
             root, collection, brass, vertices=16)
    cube("VK_v04_PistolGrip_R", rig, "DEF-spine.001",
         pistol_origin + Vector((0.0, -0.020, -0.055)), (0.028, 0.030, 0.070),
         root, collection, leather, rotation=(0.0, 0.0, 0.14))
    cube("VK_v04_PistolCyanIndex_R", rig, "DEF-spine.001",
         pistol_origin + Vector((0, -0.093, 0.070)), (0.010, 0.005, 0.028),
         root, collection, cyan)

    # Right-hand glove keeps the living hand visually separate from the brass arm.
    cube("VK_v04_GloveBack_R", rig, "DEF-hand.R",
         right_hand + Vector((0, -0.055, 0.010)), (0.070, 0.020, 0.060),
         root, collection, leather)
    for index, x in enumerate((-0.045, -0.015, 0.015, 0.045)):
        cube(f"VK_v04_GloveKnuckle_R_{index}", rig, "DEF-hand.R",
             right_hand + Vector((x, -0.078, 0.015)), (0.010, 0.007, 0.014),
             root, collection, gunmetal)

    # A small neutral chest badge anchors the front silhouette without baked neon color.
    cube("VK_v04_ChestBadge", rig, "DEF-spine.003",
         chest + Vector((0.135, -0.158, 0.070)), (0.035, 0.008, 0.050),
         root, collection, gunmetal)
    cube("VK_v04_ChestBadgeTick", rig, "DEF-spine.003",
         chest + Vector((0.135, -0.168, 0.070)), (0.010, 0.004, 0.026),
         root, collection, cyan)

    collection["steamtek_stage"] = "rig_fit_v04_identity_detail"
    collection["identity_features"] = "asymmetric coat, monocle, physical-left mechanical arm, pneumatic sidearm"
    collection["mechanical_arm_side"] = "physical_left"
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v04_ready_for_engine_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_V04_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_V04_OBJECTS={len([o for o in bpy.data.objects if o.name.startswith('VK_')])}")


if __name__ == "__main__":
    main()
