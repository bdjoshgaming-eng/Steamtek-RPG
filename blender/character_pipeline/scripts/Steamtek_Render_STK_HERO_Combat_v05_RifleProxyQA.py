"""Render combat v05 actions with a simple rifle proxy attached to RightHand."""

from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
BLEND = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "heroes"
    / "STK_HERO_BaseBody_01_Rigged_Combat_v05.blend"
)
OUTPUT_DIR = ROOT / "output" / "hero_combat_v05" / "rifle_proxy_review"

ARMATURE_NAME = "STK_HERO_BaseBody_01_Armature"
BODY_NAME = "STK_HERO_BaseBody_01_RiggedBody"
ACTION_NAMES = (
    "STK_RIFLE_IDLE",
    "STK_RIFLE_FIRE",
    "STK_RIFLE_RELOAD",
    "STK_RIFLE_TURN_LEFT",
    "STK_RIFLE_TURN_RIGHT",
    "STK_RIFLE_CROUCH_STRAFE_LEFT",
    "STK_RIFLE_CROUCH_STRAFE_RIGHT",
    "STK_RIFLE_BUTTSTROKE",
)


def set_frame(frame: float) -> None:
    integer = int(frame)
    bpy.context.scene.frame_set(integer, subframe=frame - integer)
    bpy.context.view_layer.update()


def assign_action(armature, action) -> None:
    armature.animation_data_create()
    armature.animation_data.action = action
    armature.animation_data.action_slot = action.slots[0]


bpy.ops.wm.open_mainfile(filepath=str(BLEND))
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

scene = bpy.context.scene
armature = bpy.data.objects[ARMATURE_NAME]
body = bpy.data.objects[BODY_NAME]
camera = bpy.data.objects["STK_HeroRigReviewCamera"]
scene.camera = camera
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"

idle = bpy.data.actions["STK_RIFLE_IDLE"]
assign_action(armature, idle)
set_frame(0.0)
right_world = armature.matrix_world @ armature.pose.bones["RightHand"].matrix
left_world = armature.matrix_world @ armature.pose.bones["LeftHand"].matrix
right_position = right_world.translation
left_position = left_world.translation
direction = (left_position - right_position).normalized()

bpy.ops.mesh.primitive_cube_add(size=2.0)
rifle = bpy.context.object
rifle.name = "QA_STK_RifleProxy"
rifle.dimensions = (0.075, 0.93, 0.105)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
rifle.rotation_mode = "QUATERNION"
rifle.rotation_quaternion = direction.to_track_quat("Y", "Z")
rifle.location = right_position + direction * 0.185
bpy.context.view_layer.update()

material = bpy.data.materials.new("QA_STK_RifleProxy_Material")
material.diffuse_color = (0.055, 0.07, 0.075, 1.0)
material.metallic = 0.4
material.roughness = 0.38
rifle.data.materials.append(material)

right_to_rifle = right_world.inverted() @ rifle.matrix_world

armature.hide_render = True
body.hide_render = False
rifle.hide_render = False

for action_name in ACTION_NAMES:
    action = bpy.data.actions[action_name]
    assign_action(armature, action)
    start, end = action.frame_range
    frames = sorted(
        {
            round(start + (end - start) * fraction, 3)
            for fraction in (0.0, 0.25, 0.5, 0.75, 1.0)
        }
    )
    for index, frame in enumerate(frames):
        set_frame(frame)
        current_right_world = (
            armature.matrix_world @ armature.pose.bones["RightHand"].matrix
        )
        rifle.matrix_world = current_right_world @ right_to_rifle
        bpy.context.view_layer.update()
        output = OUTPUT_DIR / f"{action_name}_{index:02d}_{frame:.3f}.png"
        scene.render.filepath = str(output)
        bpy.ops.render.render(write_still=True)

print(f"OUTPUT_DIR={OUTPUT_DIR}")
