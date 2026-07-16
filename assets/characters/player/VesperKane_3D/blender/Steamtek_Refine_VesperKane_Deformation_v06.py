"""Create Vesper Kane rig-fit v0.6 with production-minded coat deformation.

This pass keeps the approved v0.5 silhouette and animation library.  It replaces
single-bone coat-tail weighting with a controlled hip-to-leg blend so the coat
does not split into rigid boards during the walk cycle.
"""

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


def armature_modifier(obj, rig):
    modifier = next((item for item in obj.modifiers if item.type == "ARMATURE"), None)
    if modifier is None:
        modifier = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True


def replace_weights(obj, rig, weight_function):
    """Replace all weights on an isolated garment piece.

    weight_function receives normalized height (0 bottom, 1 top) and returns a
    mapping of deform-bone name to normalized weight.
    """
    if obj is None or obj.type != "MESH" or not obj.data.vertices:
        raise RuntimeError(f"Missing deformable garment mesh: {getattr(obj, 'name', None)}")

    obj.vertex_groups.clear()
    z_values = [vertex.co.z for vertex in obj.data.vertices]
    z_min = min(z_values)
    z_span = max(max(z_values) - z_min, 1e-6)
    groups = {}

    for vertex in obj.data.vertices:
        height = (vertex.co.z - z_min) / z_span
        weights = weight_function(height)
        total = sum(max(0.0, value) for value in weights.values())
        if total <= 0:
            raise RuntimeError(f"Zero garment weight on {obj.name} vertex {vertex.index}")
        for bone_name, value in weights.items():
            if value <= 0:
                continue
            group = groups.get(bone_name)
            if group is None:
                group = obj.vertex_groups.new(name=bone_name)
                groups[bone_name] = group
            group.add([vertex.index], value / total, "REPLACE")

    armature_modifier(obj, rig)
    obj["steamtek_stage"] = "rig_fit_v06_deformation"
    obj["steamtek_weight_profile"] = "hip_to_leg_gradient"
    return len(obj.data.vertices)


def side_tail_weights(side):
    thigh = f"DEF-thigh.{side}"

    def weights(height):
        # Top stays anchored to the hips.  The lower third gradually follows
        # its neighboring leg, creating motion without tearing the waist seam.
        thigh_weight = 0.18 + (1.0 - height) * 0.48
        return {"DEF-spine.001": 1.0 - thigh_weight, thigh: thigh_weight}

    return weights


def back_tail_weights(height):
    leg_total = 0.12 + (1.0 - height) * 0.26
    return {
        "DEF-spine.001": 1.0 - leg_total,
        "DEF-thigh.L": leg_total * 0.5,
        "DEF-thigh.R": leg_total * 0.5,
    }


def move_to_collection(obj, collection):
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)


def bind_rigid(obj, rig, bone_name, root, collection, material, bevel=0.003):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    armature_modifier(obj, rig)
    obj.parent = root
    obj.data.materials.append(material)
    if bevel:
        modifier = obj.modifiers.new(name="VK_v06_DeformationBevel", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
    obj["steamtek_stage"] = "rig_fit_v06_deformation"
    obj["steamtek_bound_bone"] = bone_name
    move_to_collection(obj, collection)
    obj.select_set(False)
    return obj


def cube(name, rig, bone, location, scale, root, collection, material):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind_rigid(obj, rig, bone, root, collection, material)


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    collection = bpy.data.collections.get("COLLECTION_VesperKane_RigFit_v05")
    if not rig or not root or not collection:
        raise RuntimeError("Open Vesper rig-fit v0.5 first")
    collection.name = "COLLECTION_VesperKane_RigFit_v06"

    weighted_vertices = {}
    for name, profile in (
        ("VK_CoatTail_L", side_tail_weights("L")),
        ("VK_CoatTail_R", side_tail_weights("R")),
        ("VK_CoatTail_Back", back_tail_weights),
        ("VK_v05_CoatSideTail_L", side_tail_weights("L")),
        ("VK_v05_CoatSideTail_R", side_tail_weights("R")),
    ):
        weighted_vertices[name] = replace_weights(bpy.data.objects.get(name), rig, profile)

    coat = bpy.data.materials["VK_WeatheredBlackCoat"]
    coat_edge = bpy.data.materials["VK_CoatEdge"]
    leather = bpy.data.materials["VK_v02_BlackLeather"]
    abdomen = center(rig, "DEF-spine.001")

    # These overlapping under-panels keep the hip seam covered when the two
    # front tails move apart.  They are intentionally subtle and spine-bound.
    cube(
        "VK_v06_CoatWaistUnderlay",
        rig,
        "DEF-spine.001",
        abdomen + Vector((0.0, 0.025, -0.205)),
        (0.205, 0.118, 0.115),
        root,
        collection,
        coat,
    )
    for side, x in (("L", 0.205), ("R", -0.205)):
        cube(
            f"VK_v06_CoatHipSeam_{side}",
            rig,
            "DEF-spine.001",
            abdomen + Vector((x, 0.010, -0.205)),
            (0.018, 0.132, 0.125),
            root,
            collection,
            coat_edge,
        )
    cube(
        "VK_v06_WaistFlexBand",
        rig,
        "DEF-spine.001",
        abdomen + Vector((0.0, -0.012, -0.092)),
        (0.238, 0.158, 0.025),
        root,
        collection,
        leather,
    )

    collection["steamtek_stage"] = "rig_fit_v06_deformation_review"
    collection["weighted_garments"] = ",".join(weighted_vertices.keys())
    collection["mechanical_arm_side"] = "physical_left"
    collection["height_scale_changed"] = False
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v06_ready_for_walk_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)

    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_V06_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_V06_WEIGHTED={weighted_vertices}")
    print(f"VESPER_RIG_FIT_V06_OBJECTS={len([o for o in bpy.data.objects if o.name.startswith('VK_')])}")


if __name__ == "__main__":
    main()
