"""Build Steamtek C002's production in-place walk cycle.

This version replaces the continuous sine-wave proof motion with authored
contact, down, passing, and up poses.  Feet travel at a constant rate while
planted, lift only during swing, and return to the exact opening pose at frame
25.  Godot remains authoritative for root movement.
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
FRAME_END = 25
FPS = 24
POSE_FRAMES = (1, 4, 7, 10, 13, 16, 19, 22, 25)


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


def key_rotation(
    bone: bpy.types.PoseBone,
    frame: int,
    values: tuple[float, float, float],
) -> None:
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = values
    bone.keyframe_insert(data_path="rotation_euler", frame=frame)


def key_location(
    bone: bpy.types.PoseBone,
    frame: int,
    values: tuple[float, float, float],
) -> None:
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


def configure_interpolation(action: bpy.types.Action) -> None:
    """Keep planted travel linear and soften lifted/body motion."""
    for fcurve in action.fcurves:
        is_switch = "IK_FK" in fcurve.data_path
        is_foot_y = "foot_ik" in fcurve.data_path and fcurve.array_index == 1
        for keyframe in fcurve.keyframe_points:
            if is_switch:
                keyframe.interpolation = "CONSTANT"
            elif is_foot_y:
                keyframe.interpolation = "LINEAR"
            else:
                keyframe.interpolation = "BEZIER"
                keyframe.handle_left_type = "AUTO_CLAMPED"
                keyframe.handle_right_type = "AUTO_CLAMPED"


def pose_values() -> dict[str, tuple[float, ...]]:
    return {
        # A planted foot moves evenly beneath the body.  The returning foot
        # follows a lifted swing arc instead of skating across the floor.
        "left_y": (-0.18, -0.09, 0.00, 0.09, 0.18, 0.10, 0.00, -0.10, -0.18),
        "left_z": (0.00, 0.00, 0.00, 0.00, 0.00, 0.06, 0.12, 0.08, 0.00),
        "right_y": (0.18, 0.10, 0.00, -0.10, -0.18, -0.09, 0.00, 0.09, 0.18),
        "right_z": (0.00, 0.06, 0.12, 0.08, 0.00, 0.00, 0.00, 0.00, 0.00),
        # Positive pitch is a light heel strike; negative pitch is toe-off.
        "left_pitch": (0.14, 0.04, 0.00, -0.05, -0.14, -0.10, 0.02, 0.10, 0.14),
        "right_pitch": (-0.14, -0.10, 0.02, 0.10, 0.14, 0.04, 0.00, -0.05, -0.14),
        # Arms oppose their matching legs.  The right/mechanical side remains
        # slightly restrained to preserve C002's asymmetric silhouette.
        "arm_phase": (1.00, 0.70, 0.00, -0.70, -1.00, -0.70, 0.00, 0.70, 1.00),
        "hips_x": (-0.010, -0.006, 0.000, 0.006, 0.010, 0.006, 0.000, -0.006, -0.010),
        "hips_z": (0.000, -0.007, 0.004, 0.012, 0.000, -0.007, 0.004, 0.012, 0.000),
    }


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
    action["steamtek_frames"] = FRAME_END
    action["steamtek_fps"] = FPS
    action["steamtek_motion"] = "planted_contact_pass_lift_walk_v3"

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
    values = pose_values()

    for index, frame in enumerate(POSE_FRAMES):
        key_switches(rig, frame)

        key_location(left_foot, frame, (0.0, values["left_y"][index], values["left_z"][index]))
        key_location(right_foot, frame, (0.0, values["right_y"][index], values["right_z"][index]))
        key_rotation(left_foot, frame, (values["left_pitch"][index], 0.0, 0.0))
        key_rotation(right_foot, frame, (values["right_pitch"][index], 0.0, 0.0))

        arm_phase = values["arm_phase"][index]
        key_rotation(left_upper_arm, frame, (0.28 * arm_phase, 0.0, -0.72))
        key_rotation(right_upper_arm, frame, (-0.22 * arm_phase, 0.0, 0.72))
        key_rotation(left_forearm, frame, (0.0, -0.17 - 0.035 * arm_phase, 0.0))
        key_rotation(right_forearm, frame, (0.0, 0.17 - 0.030 * arm_phase, 0.0))

        key_location(hips, frame, (values["hips_x"][index], 0.0, values["hips_z"][index]))
        key_rotation(chest, frame, (0.0, 0.0, -0.040 * arm_phase))

    configure_interpolation(action)
    rig.animation_data.action = action
    return action


def loop_delta(action: bpy.types.Action) -> dict[str, float]:
    """Return maximum first/last value differences for authored curves."""
    maximum = 0.0
    curve_count = 0
    for fcurve in action.fcurves:
        first = fcurve.evaluate(FRAME_START)
        last = fcurve.evaluate(FRAME_END)
        maximum = max(maximum, abs(first - last))
        curve_count += 1
    return {"curve_count": curve_count, "max_first_last_delta": maximum}


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
    loop_check = loop_delta(action)
    if loop_check["max_first_last_delta"] > 1e-6:
        raise RuntimeError(f"Walk loop does not close: {loop_check}")

    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_START
    scene.frame_end = FRAME_END
    scene.frame_set(FRAME_START)
    scene["steamtek_c002_walk_version"] = "v3_planted_gait"
    scene["steamtek_c002_walk_frames"] = FRAME_END
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
        "pose_frames": list(POSE_FRAMES),
        "timeline_frames": FRAME_END,
        "loop_intervals": FRAME_END - FRAME_START,
        "fps": FPS,
        "duration_seconds": (FRAME_END - FRAME_START) / FPS,
        "root_motion": False,
        "geometry_changed": False,
        "materials_changed": False,
        "loop_validation": loop_check,
        "gait_contract": {
            "contact_and_passing_poses": True,
            "planted_foot_travel": "linear",
            "swing_foot_lift": "bezier_auto_clamped",
            "opening_pose_equals_closing_pose": True,
        },
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"STEAMTEK_C002_WALK_V3={output_blend}")
    print(f"STEAMTEK_C002_WALK_RANGE={action.frame_range[0]}-{action.frame_range[1]}")
    print(f"STEAMTEK_C002_LOOP_DELTA={loop_check['max_first_last_delta']}")


if __name__ == "__main__":
    main()
