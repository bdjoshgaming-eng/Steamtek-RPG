"""Create Vesper Kane rig-fit v0.7 visual-refinement review.

The approved v0.6 rig, animation, scale, origin, and coat weights are preserved.
This pass improves material response and adds small silhouette/transition pieces
that remain readable under Steamtek's fixed orthographic camera.
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


def bone_center(rig, bone_name):
    bone = rig.data.bones[bone_name]
    return (bone.head_local + bone.tail_local) * 0.5


def bone_head(rig, bone_name):
    return rig.data.bones[bone_name].head_local.copy()


def principled(material):
    material.use_nodes = True
    return next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")


def set_material(material, color, metallic, roughness, emission=None, emission_strength=0.0):
    material.diffuse_color = (*color, 1.0)
    material.metallic = metallic
    material.roughness = roughness
    shader = principled(material)
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if "Coat Weight" in shader.inputs:
        shader.inputs["Coat Weight"].default_value = 0.08 if metallic > 0.4 else 0.02
    if emission is not None:
        shader.inputs["Emission Color"].default_value = (*emission, 1.0)
        shader.inputs["Emission Strength"].default_value = emission_strength
    material["steamtek_material_pass"] = "v07_runtime_lit"
    material["steamtek_baked_scene_lighting"] = False


def material(name, color, metallic, roughness, emission=None, emission_strength=0.0):
    result = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    set_material(result, color, metallic, roughness, emission, emission_strength)
    return result


def move_to_collection(obj, collection):
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)


def bind(obj, rig, bone_name, root, collection, mat, bevel=0.004, smooth=False):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    armature = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    armature.object = rig
    armature.use_deform_preserve_volume = True
    obj.parent = root
    obj.data.materials.append(mat)
    if smooth:
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    if bevel:
        modifier = obj.modifiers.new(name="VK_v07_RefinementBevel", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.limit_method = "ANGLE"
    obj["steamtek_stage"] = "rig_fit_v07_visual_refinement"
    obj["steamtek_bound_bone"] = bone_name
    move_to_collection(obj, collection)
    obj.select_set(False)
    return obj


def cube(name, rig, bone, location, scale, root, collection, mat, rotation=(0, 0, 0), bevel=0.004):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat, bevel=bevel)


def sphere(name, rig, bone, location, scale, root, collection, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind(obj, rig, bone, root, collection, mat, bevel=0, smooth=True)


def cylinder(name, rig, bone, location, radius, depth, root, collection, mat, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    return bind(obj, rig, bone, root, collection, mat, bevel=0.003, smooth=True)


def refine_existing_meshes():
    prefixes = (
        "VK_Coat", "VK_Hat", "VK_Head", "VK_HighCollar", "VK_DEF-hand",
        "VK_v02_BootToe", "VK_v03_BootSole", "VK_v02_KneePlate",
        "VK_v02_MechElbow", "VK_MechShoulder", "VK_v05_Coat", "VK_v06_Coat",
    )
    smooth_names = {
        "VK_CoatTorso", "VK_HatCrown", "VK_Head", "VK_DEF-hand_L", "VK_DEF-hand_R",
        "VK_MechShoulder_L", "VK_v02_MechElbow_L",
    }
    refined = []
    for obj in bpy.data.objects:
        if obj.type != "MESH" or not obj.name.startswith(prefixes):
            continue
        if obj.name in smooth_names:
            for polygon in obj.data.polygons:
                polygon.use_smooth = True
        if not any(modifier.type == "BEVEL" and modifier.name == "VK_v07_SurfaceBevel" for modifier in obj.modifiers):
            smallest = min(value for value in obj.dimensions if value > 1e-5)
            width = min(0.012, max(0.003, smallest * 0.055))
            modifier = obj.modifiers.new(name="VK_v07_SurfaceBevel", type="BEVEL")
            modifier.width = width
            modifier.segments = 3
            modifier.limit_method = "ANGLE"
        obj["steamtek_surface_refined_v07"] = True
        refined.append(obj.name)
    return refined


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    collection = bpy.data.collections.get("COLLECTION_VesperKane_RigFit_v06")
    if not rig or not root or not collection:
        raise RuntimeError("Open Vesper rig-fit v0.6 first")
    collection.name = "COLLECTION_VesperKane_RigFit_v07"

    # Physically meaningful material response. Cyan remains a restrained device
    # indicator; magenta/cyan scene coloration still comes from Godot lighting.
    coat = bpy.data.materials["VK_WeatheredBlackCoat"]
    coat_edge = bpy.data.materials["VK_CoatEdge"]
    leather = bpy.data.materials["VK_v02_BlackLeather"]
    gunmetal = bpy.data.materials["VK_v02_Gunmetal"]
    brass = bpy.data.materials["VK_v02_AgedBrass"]
    skin = bpy.data.materials["VK_Skin"]
    cyan = bpy.data.materials["VK_CyanTech"]
    set_material(coat, (0.026, 0.033, 0.040), 0.02, 0.72)
    set_material(coat_edge, (0.055, 0.068, 0.078), 0.16, 0.52)
    set_material(leather, (0.025, 0.020, 0.018), 0.04, 0.62)
    set_material(gunmetal, (0.072, 0.085, 0.095), 0.78, 0.34)
    set_material(brass, (0.30, 0.115, 0.028), 0.72, 0.41)
    set_material(skin, (0.30, 0.135, 0.072), 0.0, 0.58)
    set_material(cyan, (0.008, 0.11, 0.14), 0.30, 0.26, emission=(0.03, 0.72, 0.92), emission_strength=1.25)
    # Older duplicate materials remain on some v0.1 geometry.
    for name, values in {
        "VK_Gunmetal": ((0.062, 0.074, 0.083), 0.76, 0.36),
        "VK_AgedBrass": ((0.26, 0.10, 0.024), 0.70, 0.43),
        "VK_BlackLeather": ((0.022, 0.018, 0.016), 0.03, 0.64),
    }.items():
        if name in bpy.data.materials:
            set_material(bpy.data.materials[name], *values)

    rubber = material("VK_v07_RubberizedJoint", (0.018, 0.023, 0.027), 0.08, 0.66)
    dark_metal = material("VK_v07_DarkMachinedMetal", (0.045, 0.054, 0.061), 0.82, 0.30)
    refined = refine_existing_meshes()

    # Joint gaskets hide blocky limb seams without changing the armature.
    for side in ("L", "R"):
        elbow_bone = f"DEF-forearm.{side}"
        knee_bone = f"DEF-shin.{side}"
        sphere(
            f"VK_v07_ElbowGasket_{side}", rig, elbow_bone,
            bone_head(rig, elbow_bone), (0.072, 0.068, 0.064),
            root, collection, rubber,
        )
        sphere(
            f"VK_v07_KneeGasket_{side}", rig, knee_bone,
            bone_head(rig, knee_bone), (0.085, 0.075, 0.070),
            root, collection, rubber,
        )

    # Human right hand: glove structure and readable fingers at game distance.
    hand_r = bone_center(rig, "DEF-hand.R")
    cube("VK_v07_GlovePalm_R", rig, "DEF-hand.R", hand_r + Vector((0, -0.008, 0)),
         (0.074, 0.055, 0.052), root, collection, leather, bevel=0.008)
    for index, x in enumerate((-0.046, -0.015, 0.016, 0.047)):
        cube(f"VK_v07_GloveFinger_R_{index}", rig, "DEF-hand.R",
             hand_r + Vector((x, -0.042, -0.055)), (0.012, 0.038, 0.035),
             root, collection, leather, bevel=0.006)
    cube("VK_v07_GloveCuff_R", rig, "DEF-hand.R", hand_r + Vector((0, 0.012, 0.072)),
         (0.086, 0.065, 0.025), root, collection, coat_edge, bevel=0.006)

    # Mechanical left hand receives one compact knuckle housing rather than
    # additional decorative gears.
    hand_l = bone_center(rig, "DEF-hand.L")
    cube("VK_v07_MechKnuckleHousing_L", rig, "DEF-hand.L", hand_l + Vector((0, -0.060, 0.005)),
         (0.086, 0.032, 0.047), root, collection, dark_metal, bevel=0.006)

    # Boots gain a stable heel and ankle transition while preserving the
    # established ground-contact plane.
    for side in ("L", "R"):
        foot = bone_center(rig, f"DEF-foot.{side}")
        shin = bone_center(rig, f"DEF-shin.{side}")
        cube(f"VK_v07_BootHeel_{side}", rig, f"DEF-foot.{side}", foot + Vector((0, 0.090, -0.045)),
             (0.082, 0.060, 0.040), root, collection, dark_metal, bevel=0.006)
        cylinder(f"VK_v07_AnkleSeal_{side}", rig, f"DEF-shin.{side}", shin + Vector((0, 0, -0.145)),
                 0.082, 0.055, root, collection, rubber)

    # Face/hat refinement: a compact respirator and crown seams establish
    # identity without turning the silhouette into Victorian ornament.
    head = bone_center(rig, "DEF-spine.006")
    cube("VK_v07_LowerFaceRespirator", rig, "DEF-spine.006", head + Vector((0, -0.142, -0.050)),
         (0.096, 0.024, 0.055), root, collection, dark_metal, bevel=0.008)
    for x in (-0.068, 0.068):
        cylinder(f"VK_v07_RespiratorFilter_{x:+.3f}", rig, "DEF-spine.006",
                 head + Vector((x, -0.168, -0.055)), 0.022, 0.028,
                 root, collection, dark_metal, vertices=16)
    cube("VK_v07_RespiratorStatus", rig, "DEF-spine.006", head + Vector((0, -0.171, -0.048)),
         (0.010, 0.005, 0.024), root, collection, cyan, bevel=0.002)

    hat_center = head + Vector((0, 0, 0.315))
    # Keep the crown clean. The previous full-height side seams read as prongs
    # under the orthographic camera, so only the compact pressure vent remains.
    cylinder("VK_v07_HatPressureVent", rig, "DEF-spine.006",
             hat_center + Vector((0.0, 0.0, 0.170)), 0.032, 0.045,
             root, collection, dark_metal, vertices=20)

    collection["steamtek_stage"] = "rig_fit_v07_visual_refinement_review"
    collection["surface_refined_count"] = len(refined)
    collection["runtime_lighting_only"] = True
    collection["mechanical_arm_side"] = "physical_left"
    collection["height_scale_changed"] = False
    bpy.context.scene["steamtek_character_status"] = "rig_fit_v07_ready_for_engine_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)

    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_RIG_FIT_V07_BLEND={args.output.resolve()}")
    print(f"VESPER_RIG_FIT_V07_REFINED={len(refined)}")
    print(f"VESPER_RIG_FIT_V07_OBJECTS={len([obj for obj in bpy.data.objects if obj.name.startswith('VK_')])}")


if __name__ == "__main__":
    main()
