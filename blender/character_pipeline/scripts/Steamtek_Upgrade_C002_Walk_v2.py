"""Upgrade Steamtek C002's proof walk to a smooth 24-frame in-place cycle.

Run this against the approved C002 source blend.  The script intentionally
changes only STK_WALK and scene timing; geometry, materials, rig structure,
STK_IDLE, object origins, and export paths remain untouched.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy


ACTION_NAME = "STK_WALK"
FRAME_START = 1
FRAME_COUNT = 24
FPS = 24


def arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-blend", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    return parser.parse_args(argv)


def require_bones(rig: bpy.types.Object, names: tuple[str, ...]) -> None:
    missing = [name for name in names if rig.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError(f"C002 rig is missing required bones: {missing}")


def reset_pose(rig: bpy.types.Object) -> None:
    for bone in rig.pose.bones:
        bone.matrix_basis.identity()
    for name in ("upper_arm_parent.L", "upper_arm_parent.R"):
        rig.pose.bones[name]["IK_FK"] = 1.0
    for name in ("thigh_parent.L", "thigh_parent.R"):
        rig.pose.bones[name]["IK_FK"] = 0.0
    bpy.context.view_layer.update()


def key_rotation(bone: bpy.types.PoseBone, frame: int, values: tuple[float, float, float]) -> None:
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = values
    bone.keyframe_insert(data_path="rotation_euler", frame=frame)


def key_location(bone: bpy.types.PoseBone, frame: int, values: tuple[float, float, float]) -> None:
    bone.location = values
    bone.keyframe_insert(data_path="location", frame=frame)


def key_switches(rig: bpy.types.Object, frame: int) -> None:
    for name in ("upper_arm_parent.L", "upper_arm_parent.R"):
        bone = rig.pose.bones[name]
        bone["IK_FK"] = 1.0
        bone.keyframe_insert(data_path='["IK_FK"]', frame=frame)
    for name in ("thigh_parent.L", "thigh_parent.R"):
        bone = rig.pose.bones[name]
        bone["IK_FK"] = 0.0
        bone.keyframe_insert(data_path='["IK_FK"]', frame=frame)


def set_linear_interpolation(action: bpy.types.Action) -> None:
    # Blender 4.5 still exposes legacy fcurves for actions created this way.
    for fcurve in action.fcurves:
        for keyframe in fcurve.keyframe_points:
            keyframe.interpolation = "LINEAR"


def build_walk(rig: bpy.types.Object) -> bpy.types.Action:
    old_action = bpy.data.actions.get(ACTION_NAME)
    if old_action is not None:
        if rig.animation_data and rig.animation_data.action == old_action:
            rig.animation_data.action = None
        bpy.data.actions.remove(old_action)

    action = bpy.data.actions.new(ACTION_NAME)
    action.use_fake_user = True
    action["steamtek_shared_action"] = True
    action["steamtek_loop"] = True
    action["steamtek_frames"] = FRAME_COUNT
    action["steamtek_fps"] = FPS
    action["steamtek_motion"] = "smooth_in_place_skeletal_walk_v2"

    rig.animation_data_create()
    rig.animation_data.action = action
    reset_pose(rig)

    left_foot = rig.pose.bones["foot_ik.L"]
    right_foot = rig.pose.bones["foot_ik.R"]
    left_upper_arm = rig.pose.bones["upper_arm_fk.L"]
    right_upper_arm = rig.pose.bones["upper_arm_fk.R"]
    left_forearm = rig.pose.bones["forearm_fk.L"]
    right_forearm = rig.pose.bones["forearm_fk.R"]
    hips = rig.pose.bones["hips"]
    chest = rig.pose.bones["chest"]

    for index in range(FRAME_COUNT):
        frame = FRAME_START + index
        phase = math.tau * index / FRAME_COUNT
        right_phase = phase + math.pi

        key_switches(rig, frame)

        # Preserve the proven forward axis from the original C002 proof cycle.
        left_stride = -0.16 * math.cos(phase)
        right_stride = -0.16 * math.cos(right_phase)
        left_lift = 0.09 * max(0.0, -math.sin(phase))
        right_lift = 0.09 * max(0.0, -math.sin(right_phase))
        key_location(left_foot, frame, (0.0, left_stride, left_lift))
        key_location(right_foot, frame, (0.0, right_stride, right_lift))

        # Counter-swing the arms.  The mechanical side is slightly restrained
        # so C002's asymmetric silhouette remains readable.
        arm_swing = math.sin(phase)
        key_rotation(left_upper_arm, frame, (0.30 * arm_swing, 0.0, -0.72))
        key_rotation(right_upper_arm, frame, (-0.24 * arm_swing, 0.0, 0.72))
        key_rotation(left_forearm, frame, (0.0, -0.16 - 0.055 * math.cos(phase), 0.0))
        key_rotation(right_forearm, frame, (0.0, 0.16 + 0.045 * math.cos(phase), 0.0))

        # Subtle weight transfer and double-step rise.  There is deliberately
        # no forward root motion; Godot remains authoritative for movement.
        lateral_shift = 0.010 * math.sin(phase)
        vertical_bob = 0.010 * (1.0 - math.cos(phase * 2.0))
        key_location(hips, frame, (lateral_shift, 0.0, vertical_bob))
        key_rotation(chest, frame, (0.0, 0.0, -0.035 * math.sin(phase)))

    set_linear_interpolation(action)
    rig.animation_data.action = action
    return action


def main() -> None:
    args = arguments()
    output_blend = args.output_blend.resolve()
    report_path = args.report.resolve()
    output_blend.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    rig = bpy.data.objects.get("Armature")
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError("Production armature 'Armature' was not found")

    required = (
        "upper_arm_parent.L",
        "upper_arm_parent.R",
        "thigh_parent.L",
        "thigh_parent.R",
        "upper_arm_fk.L",
        "upper_arm_fk.R",
        "forearm_fk.L",
        "forearm_fk.R",
        "foot_ik.L",
        "foot_ik.R",
        "hips",
        "chest",
    )
    require_bones(rig, required)

    old_range = None
    old_action = bpy.data.actions.get(ACTION_NAME)
    if old_action is not None:
        old_range = [float(old_action.frame_range[0]), float(old_action.frame_range[1])]

    action = build_walk(rig)
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_START
    scene.frame_end = FRAME_COUNT
    scene.frame_set(FRAME_START)
    scene["steamtek_c002_walk_version"] = "v2_24fps"
    scene["steamtek_c002_walk_frames"] = FRAME_COUNT
    scene["steamtek_c002_walk_in_place"] = True

    bpy.ops.wm.save_as_mainfile(filepath=str(output_blend), check_existing=False)

    report = {
        "source_blend": bpy.data.filepath,
        "output_blend": str(output_blend),
        "armature": rig.name,
        "bone_count": len(rig.data.bones),
        "mesh_count": sum(1 for obj in bpy.context.scene.objects if obj.type == "MESH"),
        "action": ACTION_NAME,
        "previous_frame_range": old_range,
        "frame_range": [float(action.frame_range[0]), float(action.frame_range[1])],
        "frame_count": FRAME_COUNT,
        "fps": FPS,
        "duration_seconds": FRAME_COUNT / FPS,
        "root_motion": False,
        "geometry_changed": False,
        "materials_changed": False,
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"STEAMTEK_C002_WALK_UPGRADED={output_blend}")
    print(f"STEAMTEK_C002_WALK_RANGE={action.frame_range[0]}-{action.frame_range[1]}")


if __name__ == "__main__":
    main()
