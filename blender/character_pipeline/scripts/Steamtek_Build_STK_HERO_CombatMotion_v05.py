"""Retarget Meshy combat motions onto the approved Steamtek hero rig.

The approved v04 Blender file and GLB remain unchanged. This script opens the
v04 Blender source, replaces only its hidden Meshy motion reference, retargets
the newly downloaded combat actions onto the clean meter-scale armature, adds
small derived combat actions, validates deformation bounds, renders review
frames, and saves a separate v05 Blender candidate.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix


ROOT = Path(__file__).resolve().parents[3]
BASE_BUILD_SCRIPT = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "scripts"
    / "Steamtek_Build_STK_HERO_BaseBody_01_CleanMeshyMotionRig.py"
)
BASE_BLEND = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "heroes"
    / "STK_HERO_BaseBody_01_Rigged_MeshyMotion_v04.blend"
)
MESHY_MOTIONS = (
    ROOT
    / "output"
    / "meshy_animation_source"
    / "downloaded"
    / "all_added_v03_20260723"
    / "Meshy_AI_STK_HERO_BaseBody_01__biped"
    / "Meshy_AI_STK_HERO_BaseBody_01__biped_Meshy_AI_Meshy_Merged_Animations.glb"
)
OUTPUT_BLEND = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "heroes"
    / "STK_HERO_BaseBody_01_Rigged_Combat_v05.blend"
)
OUTPUT_DIR = ROOT / "output" / "hero_combat_v05"
REPORT_JSON = OUTPUT_DIR / "STK_HERO_BaseBody_01_Rigged_Combat_v05_Report.json"
REPORT_MD = OUTPUT_DIR / "STK_HERO_BaseBody_01_Rigged_Combat_v05_Report.md"
REVIEW_DIR = OUTPUT_DIR / "review"

TARGET_ARMATURE_NAME = "STK_HERO_BaseBody_01_Armature"
TARGET_MESH_NAME = "STK_HERO_BaseBody_01_RiggedBody"

ACTION_NAMES = {
    "Crouch_Walk_Left_with_Gun_inplace": "STK_RIFLE_CROUCH_STRAFE_LEFT",
    "Dead": "STK_DEATH_FORWARD",
    "Elbow_Strike": "STK_RIFLE_BUTTSTROKE_BASE",
    "Gunshot_Reaction": "STK_HIT_REACT_STRONG",
    "Rifle_Aim_Turn_Right": "STK_RIFLE_TURN_RIGHT",
    "Rifle_Turn_Left": "STK_RIFLE_TURN_LEFT",
    "Standing_Reload": "STK_RIFLE_RELOAD",
}

FINAL_ACTION_NAMES = {
    "STK_WALK",
    "STK_RUN",
    "STK_RIFLE_IDLE",
    "STK_RIFLE_FIRE",
    "STK_RIFLE_RELOAD",
    "STK_RIFLE_TURN_LEFT",
    "STK_RIFLE_TURN_RIGHT",
    "STK_RIFLE_CROUCH_STRAFE_LEFT",
    "STK_RIFLE_CROUCH_STRAFE_RIGHT",
    "STK_RIFLE_BUTTSTROKE",
    "STK_HIT_REACT_STRONG",
    "STK_DEATH_FORWARD",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_base_builder():
    spec = importlib.util.spec_from_file_location(
        "steamtek_clean_meshy_motion_builder", BASE_BUILD_SCRIPT
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {BASE_BUILD_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def remove_old_motion_reference() -> None:
    collection = bpy.data.collections.get("SOURCE_Meshy_Reference")
    if collection:
        for obj in list(collection.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(collection)
    for action in list(bpy.data.actions):
        if action.name.startswith("SOURCE_Meshy_"):
            bpy.data.actions.remove(action, do_unlink=True)


def action_info(builder, action: bpy.types.Action) -> dict:
    frames = builder.action_frames(action)
    return {
        "action": action,
        "slot": action.slots[0],
        "frame_start": frames[0],
        "frame_end": frames[-1],
        "keyed_frames": len(frames),
        "key_times": frames,
    }


def create_action_info(builder, name: str, armature: bpy.types.Object) -> dict:
    action, slot, strip = builder.create_target_action(name, armature)
    return {
        "action": action,
        "slot": slot,
        "strip": strip,
        "frame_start": 0.0,
        "frame_end": 0.0,
        "keyed_frames": 0,
        "key_times": [],
    }


def key_current_pose(
    builder,
    armature: bpy.types.Object,
    info: dict,
    frame: float,
) -> None:
    strip = info["strip"]
    slot = info["slot"]
    for name in builder.BONE_ORDER:
        pose_bone = armature.pose.bones[name]
        pose_bone.rotation_mode = "QUATERNION"
        data_path = f'pose.bones["{name}"]'
        for index, value in enumerate(pose_bone.location):
            strip.key_insert(
                slot=slot,
                data_path=f"{data_path}.location",
                array_index=index,
                value=float(value),
                time=frame,
            )
        for index, value in enumerate(pose_bone.rotation_quaternion):
            strip.key_insert(
                slot=slot,
                data_path=f"{data_path}.rotation_quaternion",
                array_index=index,
                value=float(value),
                time=frame,
            )
        for index, value in enumerate(pose_bone.scale):
            strip.key_insert(
                slot=slot,
                data_path=f"{data_path}.scale",
                array_index=index,
                value=float(value),
                time=frame,
            )


def finish_custom_action(info: dict, frames: list[float]) -> None:
    channelbag = info["strip"].channelbag(info["slot"], ensure=False)
    for fcurve in channelbag.fcurves:
        for point in fcurve.keyframe_points:
            point.interpolation = "LINEAR"
    info["frame_start"] = frames[0]
    info["frame_end"] = frames[-1]
    info["keyed_frames"] = len(frames)
    info["key_times"] = frames


def create_trimmed_action(
    builder,
    armature: bpy.types.Object,
    source_info: dict,
    output_name: str,
    start_at: float,
) -> dict:
    """Copy an action from start_at onward and shift its first kept key to zero."""
    source_frames = [
        frame for frame in source_info["key_times"] if frame >= start_at
    ]
    if not source_frames:
        raise RuntimeError(
            f"No keys remain in {source_info['action'].name} after {start_at}"
        )

    output_info = create_action_info(builder, output_name, armature)
    first_frame = source_frames[0]
    output_frames = []
    for source_frame in source_frames:
        builder.assign_action(armature, source_info)
        builder.set_scene_frame(source_frame)
        basis = capture_basis(builder, armature)

        output_frame = round(source_frame - first_frame, 6)
        builder.assign_action(armature, output_info)
        builder.set_scene_frame(output_frame)
        reset_pose(armature)
        apply_basis(builder, armature, basis)
        key_current_pose(builder, armature, output_info, output_frame)
        output_frames.append(output_frame)

    finish_custom_action(output_info, output_frames)
    return output_info


def reset_pose(armature: bpy.types.Object) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.matrix_basis.identity()
        pose_bone.rotation_mode = "QUATERNION"
    bpy.context.view_layer.update()


def capture_basis(builder, armature: bpy.types.Object) -> dict[str, Matrix]:
    return {
        name: armature.pose.bones[name].matrix_basis.copy()
        for name in builder.BONE_ORDER
    }


def apply_basis(
    builder, armature: bpy.types.Object, basis: dict[str, Matrix]
) -> None:
    for name in builder.BONE_ORDER:
        armature.pose.bones[name].matrix_basis = basis[name]
    bpy.context.view_layer.update()


def create_rifle_idle(
    builder,
    armature: bpy.types.Object,
    turn_right: dict,
) -> tuple[dict, dict[str, Matrix]]:
    builder.assign_action(armature, turn_right)
    builder.set_scene_frame(turn_right["frame_start"])
    idle_basis = capture_basis(builder, armature)

    info = create_action_info(builder, "STK_RIFLE_IDLE", armature)
    builder.assign_action(armature, info)
    frames = [0.0, 24.0]
    for frame in frames:
        builder.set_scene_frame(frame)
        apply_basis(builder, armature, idle_basis)
        key_current_pose(builder, armature, info, frame)
    finish_custom_action(info, frames)
    return info, idle_basis


def rotate_pose_bone_world(
    armature: bpy.types.Object,
    bone_name: str,
    axis: str,
    angle_radians: float,
) -> None:
    pose_bone = armature.pose.bones[bone_name]
    current_world = armature.matrix_world @ pose_bone.matrix
    pivot = current_world.translation
    rotation = Matrix.Rotation(angle_radians, 4, axis)
    desired_world = (
        Matrix.Translation(pivot)
        @ rotation
        @ Matrix.Translation(-pivot)
        @ current_world
    )
    pose_bone.matrix = armature.matrix_world.inverted() @ desired_world
    bpy.context.view_layer.update()


def create_rifle_fire(
    builder,
    armature: bpy.types.Object,
    idle_basis: dict[str, Matrix],
) -> dict:
    info = create_action_info(builder, "STK_RIFLE_FIRE", armature)
    builder.assign_action(armature, info)
    recoil = {
        0.0: 0.0,
        2.0: math.radians(-4.0),
        4.0: math.radians(-1.5),
        6.0: 0.0,
    }
    frames = list(recoil)
    for frame, angle in recoil.items():
        builder.set_scene_frame(frame)
        apply_basis(builder, armature, idle_basis)
        if abs(angle) > 1.0e-8:
            rotate_pose_bone_world(armature, "Spine", "X", angle)
        key_current_pose(builder, armature, info, frame)
    finish_custom_action(info, frames)
    return info


def mirrored_bone_name(name: str) -> str:
    if name.startswith("Left"):
        return "Right" + name[4:]
    if name.startswith("Right"):
        return "Left" + name[5:]
    return name


def create_mirrored_action(
    builder,
    armature: bpy.types.Object,
    source_info: dict,
    target_name: str,
) -> dict:
    source_action = source_info["action"]
    rest_world = {
        name: builder.clean_matrix(
            armature.matrix_world @ armature.data.bones[name].matrix_local
        )
        for name in builder.BONE_ORDER
    }
    reflection = Matrix.Diagonal((-1.0, 1.0, 1.0, 1.0))
    info = create_action_info(builder, target_name, armature)
    frames = list(source_info["key_times"])

    for frame in frames:
        armature.animation_data_create()
        armature.animation_data.action = source_action
        armature.animation_data.action_slot = source_info["slot"]
        builder.set_scene_frame(frame)
        source_pose_world = {
            name: builder.clean_matrix(
                armature.matrix_world @ armature.pose.bones[name].matrix
            )
            for name in builder.BONE_ORDER
        }
        desired_world = {}
        for source_name in builder.BONE_ORDER:
            target_bone = mirrored_bone_name(source_name)
            delta = source_pose_world[source_name] @ rest_world[source_name].inverted()
            mirrored_delta = reflection @ delta @ reflection
            desired_world[target_bone] = mirrored_delta @ rest_world[target_bone]

        builder.assign_action(armature, info)
        builder.set_scene_frame(frame)
        reset_pose(armature)
        for name in builder.BONE_ORDER:
            armature.pose.bones[name].matrix = (
                armature.matrix_world.inverted() @ desired_world[name]
            )
            bpy.context.view_layer.update()
        key_current_pose(builder, armature, info, frame)

    finish_custom_action(info, frames)
    return info


def create_rifle_buttstroke(
    builder,
    armature: bpy.types.Object,
    base_info: dict,
    idle_info: dict,
) -> tuple[dict, list[float]]:
    builder.assign_action(armature, idle_info)
    builder.set_scene_frame(idle_info["frame_start"])
    right_idle_world = (
        armature.matrix_world @ armature.pose.bones["RightHand"].matrix
    )
    left_idle_world = (
        armature.matrix_world @ armature.pose.bones["LeftHand"].matrix
    )
    grip_offset = right_idle_world.inverted() @ left_idle_world

    target = bpy.data.objects.new("TEMP_STK_RifleGripTarget", None)
    bpy.context.scene.collection.objects.link(target)
    target.hide_render = True
    target.hide_set(True)

    forearm = armature.pose.bones["LeftForeArm"]
    constraint = forearm.constraints.new("IK")
    constraint.name = "TEMP_STK_RifleGripIK"
    constraint.target = target
    constraint.chain_count = 2
    constraint.use_tail = True
    constraint.use_stretch = False

    info = create_action_info(builder, "STK_RIFLE_BUTTSTROKE", armature)
    frames = list(base_info["key_times"])

    for frame in frames:
        builder.assign_action(armature, base_info)
        constraint.influence = 1.0
        builder.set_scene_frame(frame)

        right_world = armature.matrix_world @ armature.pose.bones["RightHand"].matrix
        desired_left_world = right_world @ grip_offset
        target.matrix_world = Matrix.Translation(desired_left_world.translation)
        bpy.context.view_layer.update()

        armature.pose.bones["LeftHand"].matrix = (
            armature.matrix_world.inverted() @ desired_left_world
        )
        bpy.context.view_layer.update()
        solved = {
            name: armature.pose.bones[name].matrix.copy()
            for name in builder.BONE_ORDER
        }

        constraint.influence = 0.0
        builder.assign_action(armature, info)
        builder.set_scene_frame(frame)
        reset_pose(armature)
        for name in builder.BONE_ORDER:
            armature.pose.bones[name].matrix = solved[name]
            bpy.context.view_layer.update()
        key_current_pose(builder, armature, info, frame)

    forearm.constraints.remove(constraint)
    bpy.data.objects.remove(target, do_unlink=True)
    finish_custom_action(info, frames)
    return info, list(grip_offset.translation)


def render_reviews(builder, armature: bpy.types.Object, body, actions: dict) -> dict:
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    camera = bpy.data.objects.get("STK_HeroRigReviewCamera")
    if camera is None:
        camera = builder.configure_review_stage()
    scene.camera = camera
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False

    armature.hide_render = True
    body.hide_render = False
    outputs = {}
    for action_name, info in sorted(actions.items()):
        builder.assign_action(armature, info)
        start = info["frame_start"]
        end = info["frame_end"]
        frames = sorted(
            {
                round(start + (end - start) * fraction, 3)
                for fraction in (0.0, 0.25, 0.5, 0.75, 1.0)
            }
        )
        action_outputs = []
        for index, frame in enumerate(frames):
            builder.set_scene_frame(frame)
            path = REVIEW_DIR / f"{action_name}_{index:02d}_{frame:.3f}.png"
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)
            action_outputs.append(str(path))
        outputs[action_name] = action_outputs
    return outputs


def write_reports(report: dict) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_JSON.write_text(json.dumps(report, indent=2), encoding="utf-8")
    lines = [
        "# STK_HERO_BaseBody_01 Combat Motion v05",
        "",
        "## Status",
        "",
        "**TECHNICAL CANDIDATE - rendered visual review required before promotion.**",
        "",
        "## Read-only sources",
        "",
        f"- Approved v04 Blender source: `{BASE_BLEND}`",
        f"- Meshy merged animation source: `{MESHY_MOTIONS}`",
        "",
        "## Output",
        "",
        f"- Blender candidate: `{OUTPUT_BLEND}`",
        "",
        "## Actions",
        "",
    ]
    lines.extend(f"- `{name}`" for name in sorted(report["actions"]))
    lines.extend(
        [
            "",
            "The v04 Blender source and production GLB were not overwritten.",
        ]
    )
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    for path in (BASE_BUILD_SCRIPT, BASE_BLEND, MESHY_MOTIONS):
        if not path.is_file():
            raise FileNotFoundError(path)

    builder = load_base_builder()
    bpy.ops.wm.open_mainfile(filepath=str(BASE_BLEND))
    scene = bpy.context.scene
    scene.render.fps = 24

    armature = bpy.data.objects[TARGET_ARMATURE_NAME]
    body = bpy.data.objects[TARGET_MESH_NAME]
    remove_old_motion_reference()

    builder.MESHY_MOTIONS = MESHY_MOTIONS
    builder.ACTION_NAMES = ACTION_NAMES
    source_armature, _source_mesh, source_actions = builder.import_meshy_reference()
    retargeted = builder.retarget_actions(
        source_armature, source_actions, armature
    )

    for imported_default in ("Running", "Walking"):
        action = bpy.data.actions.get(imported_default)
        if action:
            bpy.data.actions.remove(action, do_unlink=True)

    actions = {
        "STK_WALK": action_info(builder, bpy.data.actions["STK_WALK"]),
        "STK_RUN": action_info(builder, bpy.data.actions["STK_RUN"]),
    }
    actions.update(retargeted)

    untrimmed_death = retargeted["STK_DEATH_FORWARD"]
    untrimmed_death["action"].name = "STK_DEATH_FORWARD_UNTRIMMED"
    trimmed_death = create_trimmed_action(
        builder,
        armature,
        untrimmed_death,
        "STK_DEATH_FORWARD",
        18.0,
    )
    actions["STK_DEATH_FORWARD"] = trimmed_death
    retargeted["STK_DEATH_FORWARD"] = trimmed_death
    bpy.data.actions.remove(untrimmed_death["action"], do_unlink=True)

    idle_info, idle_basis = create_rifle_idle(
        builder, armature, retargeted["STK_RIFLE_TURN_RIGHT"]
    )
    actions["STK_RIFLE_IDLE"] = idle_info
    actions["STK_RIFLE_FIRE"] = create_rifle_fire(
        builder, armature, idle_basis
    )
    actions["STK_RIFLE_CROUCH_STRAFE_RIGHT"] = create_mirrored_action(
        builder,
        armature,
        retargeted["STK_RIFLE_CROUCH_STRAFE_LEFT"],
        "STK_RIFLE_CROUCH_STRAFE_RIGHT",
    )
    buttstroke_info, grip_offset = create_rifle_buttstroke(
        builder,
        armature,
        retargeted["STK_RIFLE_BUTTSTROKE_BASE"],
        idle_info,
    )
    actions["STK_RIFLE_BUTTSTROKE"] = buttstroke_info

    base_action = bpy.data.actions.get("STK_RIFLE_BUTTSTROKE_BASE")
    if base_action:
        bpy.data.actions.remove(base_action, do_unlink=True)
    actions.pop("STK_RIFLE_BUTTSTROKE_BASE", None)

    if set(actions) != FINAL_ACTION_NAMES:
        raise RuntimeError(
            f"Final action mismatch: {sorted(actions)} != "
            f"{sorted(FINAL_ACTION_NAMES)}"
        )

    validation = builder.validate_actions(body, armature, actions)
    review_outputs = render_reviews(builder, armature, body, actions)

    builder.assign_action(armature, actions["STK_RIFLE_IDLE"])
    builder.set_scene_frame(0.0)
    scene.frame_start = 0
    scene.frame_end = 24
    scene.use_preview_range = True
    scene.frame_preview_start = 0
    scene.frame_preview_end = 24
    armature["steamtek_schema"] = "SteamtekCombatMotionRig-5"
    armature["steamtek_combat_actions"] = sorted(FINAL_ACTION_NAMES)
    armature["steamtek_motion_source"] = str(MESHY_MOTIONS)
    armature["steamtek_motion_source_sha256"] = sha256(MESHY_MOTIONS)

    report = {
        "schema": "SteamtekCombatMotionRig-5",
        "status": "technical_candidate_visual_review_required",
        "base_blend": str(BASE_BLEND),
        "base_blend_sha256": sha256(BASE_BLEND),
        "meshy_motion_source": str(MESHY_MOTIONS),
        "meshy_motion_sha256": sha256(MESHY_MOTIONS),
        "output_blend": str(OUTPUT_BLEND),
        "bones": len(armature.data.bones),
        "triangles": builder.mesh_triangle_count(body),
        "rifle_grip_offset_right_to_left": grip_offset,
        "actions": {
            name: {
                key: value
                for key, value in info.items()
                if key not in ("action", "slot", "strip")
            }
            for name, info in sorted(actions.items())
        },
        "validation": validation,
        "review_outputs": review_outputs,
    }
    write_reports(report)
    OUTPUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_BLEND))

    print(f"OUTPUT_BLEND={OUTPUT_BLEND}")
    print(f"REPORT={REPORT_JSON}")
    print(f"BONES={report['bones']}")
    print(f"TRIANGLES={report['triangles']}")
    print("ACTIONS=" + ",".join(sorted(actions)))
    print("STATUS=TECHNICAL_CANDIDATE_VISUAL_REVIEW_REQUIRED")


if __name__ == "__main__":
    main()
