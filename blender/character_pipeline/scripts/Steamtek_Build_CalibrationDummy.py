"""Build a low-poly Steamtek humanoid calibration mesh and idle/walk actions."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


DUMMY_ID = "STK_CalibrationDummy_v1"
FRAME_COUNT = 8


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def material(name, color, metallic=0.0, roughness=0.5):
    existing = bpy.data.materials.get(name)
    if existing:
        return existing
    value = bpy.data.materials.new(name)
    value.diffuse_color = color
    value.use_nodes = True
    bsdf = value.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return value


def move_to_collection(obj, target):
    if target.objects.get(obj.name) is None:
        target.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != target:
            owner.objects.unlink(obj)


def bind_object(obj, rig, bone_name, ground_root, target_collection, mat):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True
    obj.parent = ground_root
    obj.data.materials.append(mat)
    obj["steamtek_calibration_part"] = True
    obj["steamtek_bound_bone"] = bone_name
    move_to_collection(obj, target_collection)
    obj.select_set(False)
    return obj


def cylinder_for_bone(rig, bone_name, radius, ground_root, collection, mat, scale=0.92):
    bone = rig.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError(f"Missing deform bone: {bone_name}")
    head = bone.head_local.copy()
    tail = bone.tail_local.copy()
    direction = tail - head
    length = max(direction.length * scale, 0.03)
    midpoint = (head + tail) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=length, location=midpoint)
    obj = bpy.context.object
    obj.name = f"CAL_{bone_name.replace('.', '_')}"
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    return bind_object(obj, rig, bone_name, ground_root, collection, mat)


def sphere_part(name, rig, bone_name, location, scale, ground_root, collection, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind_object(obj, rig, bone_name, ground_root, collection, mat)


def cube_part(name, rig, bone_name, location, scale, ground_root, collection, mat):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return bind_object(obj, rig, bone_name, ground_root, collection, mat)


def create_dummy_mesh(rig, ground_root):
    old = bpy.data.collections.get("COLLECTION_CalibrationDummy")
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)
    collection = bpy.data.collections.new("COLLECTION_CalibrationDummy")
    bpy.context.scene.collection.children.link(collection)

    coat = material("CAL_Coat", (0.025, 0.075, 0.13, 1.0), 0.28, 0.38)
    leather = material("CAL_Leather", (0.11, 0.035, 0.018, 1.0), 0.12, 0.58)
    metal = material("CAL_Metal", (0.03, 0.055, 0.08, 1.0), 0.82, 0.24)
    copper = material("CAL_Copper", (0.42, 0.10, 0.025, 1.0), 0.78, 0.25)
    skin = material("CAL_Skin", (0.38, 0.18, 0.105, 1.0), 0.0, 0.62)
    cyan = material("CAL_Cyan", (0.02, 0.55, 0.8, 1.0), 0.45, 0.2)

    parts = [
        ("DEF-spine", 0.16, leather),
        ("DEF-spine.001", 0.18, coat),
        ("DEF-spine.002", 0.20, coat),
        ("DEF-spine.003", 0.21, coat),
        ("DEF-spine.004", 0.19, coat),
        ("DEF-pelvis.L", 0.13, leather),
        ("DEF-pelvis.R", 0.13, leather),
        ("DEF-thigh.L", 0.105, leather),
        ("DEF-thigh.L.001", 0.10, leather),
        ("DEF-thigh.R", 0.105, leather),
        ("DEF-thigh.R.001", 0.10, leather),
        ("DEF-shin.L", 0.085, leather),
        ("DEF-shin.L.001", 0.078, leather),
        ("DEF-shin.R", 0.085, leather),
        ("DEF-shin.R.001", 0.078, leather),
        ("DEF-foot.L", 0.09, metal),
        ("DEF-toe.L", 0.095, metal),
        ("DEF-foot.R", 0.09, metal),
        ("DEF-toe.R", 0.095, metal),
        ("DEF-shoulder.L", 0.09, coat),
        ("DEF-shoulder.R", 0.09, coat),
        ("DEF-upper_arm.L", 0.078, coat),
        ("DEF-upper_arm.L.001", 0.073, coat),
        ("DEF-upper_arm.R", 0.078, coat),
        ("DEF-upper_arm.R.001", 0.073, coat),
        ("DEF-forearm.L", 0.062, leather),
        ("DEF-forearm.L.001", 0.058, leather),
        ("DEF-forearm.R", 0.062, leather),
        ("DEF-forearm.R.001", 0.058, leather),
        ("DEF-hand.L", 0.065, skin),
        ("DEF-hand.R", 0.065, skin),
    ]
    for bone_name, radius, mat in parts:
        cylinder_for_bone(rig, bone_name, radius, ground_root, collection, mat)

    head_bone = rig.data.bones["DEF-spine.006"]
    head_center = (head_bone.head_local + head_bone.tail_local) * 0.5 + Vector((0.0, -0.015, 0.035))
    sphere_part("CAL_Head", rig, "DEF-spine.006", head_center, (0.145, 0.13, 0.17), ground_root, collection, skin)
    cube_part("CAL_Visor", rig, "DEF-spine.006", head_center + Vector((0.0, -0.125, 0.025)), (0.11, 0.025, 0.035), ground_root, collection, cyan)

    forearm = rig.data.bones["DEF-forearm.L"]
    gauge_center = (forearm.head_local + forearm.tail_local) * 0.5 + Vector((0.0, -0.075, 0.03))
    sphere_part("CAL_AsymmetryGauge_L", rig, "DEF-forearm.L", gauge_center, (0.065, 0.035, 0.065), ground_root, collection, copper)

    for obj in collection.objects:
        obj.hide_render = False
    collection["steamtek_role"] = "rig_camera_animation_validation_only"
    return collection


def reset_pose(rig):
    for bone in rig.pose.bones:
        bone.matrix_basis.identity()
    for name in ("upper_arm_parent.L", "upper_arm_parent.R"):
        rig.pose.bones[name]["IK_FK"] = 1.0
    for name in ("thigh_parent.L", "thigh_parent.R"):
        rig.pose.bones[name]["IK_FK"] = 0.0
    bpy.context.view_layer.update()


def key_rotation(bone, frame, values):
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = values
    bone.keyframe_insert(data_path="rotation_euler", frame=frame)


def key_location(bone, frame, values):
    bone.location = values
    bone.keyframe_insert(data_path="location", frame=frame)


def prepare_action(rig, name, loop=True):
    existing = bpy.data.actions.get(name)
    if existing:
        bpy.data.actions.remove(existing)
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    action["steamtek_shared_action"] = True
    action["steamtek_loop"] = loop
    action["steamtek_frames"] = FRAME_COUNT
    rig.animation_data_create()
    rig.animation_data.action = action
    reset_pose(rig)
    return action


def key_switches(rig, frame):
    for name in ("upper_arm_parent.L", "upper_arm_parent.R"):
        bone = rig.pose.bones[name]
        bone["IK_FK"] = 1.0
        bone.keyframe_insert(data_path='["IK_FK"]', frame=frame)
    for name in ("thigh_parent.L", "thigh_parent.R"):
        bone = rig.pose.bones[name]
        bone["IK_FK"] = 0.0
        bone.keyframe_insert(data_path='["IK_FK"]', frame=frame)


def create_idle(rig):
    action = prepare_action(rig, "STK_IDLE")
    for frame in range(1, FRAME_COUNT + 1):
        phase = math.tau * (frame - 1) / FRAME_COUNT
        key_switches(rig, frame)
        key_rotation(rig.pose.bones["upper_arm_fk.L"], frame, (0.015 * math.sin(phase), 0.0, -0.72))
        key_rotation(rig.pose.bones["upper_arm_fk.R"], frame, (-0.015 * math.sin(phase), 0.0, 0.72))
        key_rotation(rig.pose.bones["forearm_fk.L"], frame, (0.0, -0.10, 0.0))
        key_rotation(rig.pose.bones["forearm_fk.R"], frame, (0.0, 0.10, 0.0))
        key_location(rig.pose.bones["hips"], frame, (0.0, 0.0, 0.006 * math.sin(phase)))
        key_rotation(rig.pose.bones["chest"], frame, (0.0, 0.0, 0.008 * math.sin(phase)))
        key_location(rig.pose.bones["foot_ik.L"], frame, (0.0, 0.0, 0.0))
        key_location(rig.pose.bones["foot_ik.R"], frame, (0.0, 0.0, 0.0))
    return action


def create_walk(rig):
    action = prepare_action(rig, "STK_WALK")
    forward = (-0.16, -0.08, 0.0, 0.08, 0.16, 0.08, 0.0, -0.08)
    lift = (0.0, 0.0, 0.0, 0.0, 0.0, 0.045, 0.09, 0.045)
    for frame in range(1, FRAME_COUNT + 1):
        index = frame - 1
        opposite = (index + 4) % FRAME_COUNT
        phase = math.tau * index / FRAME_COUNT
        key_switches(rig, frame)
        key_location(rig.pose.bones["foot_ik.L"], frame, (0.0, forward[index], lift[index]))
        key_location(rig.pose.bones["foot_ik.R"], frame, (0.0, forward[opposite], lift[opposite]))
        arm_swing = 0.28 * math.sin(phase)
        key_rotation(rig.pose.bones["upper_arm_fk.L"], frame, (arm_swing, 0.0, -0.72))
        key_rotation(rig.pose.bones["upper_arm_fk.R"], frame, (-arm_swing, 0.0, 0.72))
        key_rotation(rig.pose.bones["forearm_fk.L"], frame, (0.0, -0.16 - 0.05 * math.cos(phase), 0.0))
        key_rotation(rig.pose.bones["forearm_fk.R"], frame, (0.0, 0.16 + 0.05 * math.cos(phase), 0.0))
        key_location(rig.pose.bones["hips"], frame, (0.0, 0.0, 0.012 * (1.0 - math.cos(phase * 2.0))))
        key_rotation(rig.pose.bones["chest"], frame, (0.0, 0.0, -0.025 * math.sin(phase)))
    return action


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    ground_root = bpy.data.objects.get("ROOT_GroundContact")
    facing_root = bpy.data.objects.get("ROOT_CharacterFacing")
    if rig is None or rig.type != "ARMATURE" or ground_root is None or facing_root is None:
        raise RuntimeError("Open Steamtek_Character_Master.blend with Steamtek_HumanRig_v1 installed")
    if rig.get("steamtek_rig_id") != "Steamtek_HumanRig_v1":
        raise RuntimeError("Armature is not Steamtek_HumanRig_v1")

    create_dummy_mesh(rig, facing_root)
    create_idle(rig)
    walk = create_walk(rig)
    rig.animation_data.action = walk
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = FRAME_COUNT
    bpy.context.scene.frame_set(1)
    bpy.context.scene["steamtek_calibration_dummy"] = DUMMY_ID
    bpy.context.scene["steamtek_calibration_status"] = "approved_reference_fixture"
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"STEAMTEK_CALIBRATION_BLEND={args.output.resolve()}")
    print("STEAMTEK_ACTIONS=STK_IDLE,STK_WALK")


if __name__ == "__main__":
    main()
