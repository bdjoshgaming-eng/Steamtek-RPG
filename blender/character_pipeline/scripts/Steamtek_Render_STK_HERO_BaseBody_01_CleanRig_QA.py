"""Render multi-angle deformation checks from the clean hero rig candidate."""

from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "output" / "hero_rig_rebuild" / "review_v02_angles"
ARMATURE_NAME = "STK_HERO_BaseBody_01_Armature"
CAMERA_NAME = "STK_HeroRigReviewCamera"


def assign_action(armature, action_name):
    action = bpy.data.actions[action_name]
    armature.animation_data_create()
    armature.animation_data.action = action
    armature.animation_data.action_slot = action.slots[0]


def point_camera(camera, location):
    target = Vector((0.0, 0.0, 0.95))
    camera.location = location
    camera.rotation_euler = (target - camera.location).to_track_quat(
        "-Z", "Y"
    ).to_euler()


OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
armature = bpy.data.objects[ARMATURE_NAME]
camera = bpy.data.objects[CAMERA_NAME]
scene.camera = camera
camera.data.type = "ORTHO"
camera.data.ortho_scale = 2.35
armature.data.pose_position = "POSE"

angles = {
    "front": Vector((0.0, -6.0, 1.7)),
    "back": Vector((0.0, 6.0, 1.7)),
    "left": Vector((-6.0, 0.0, 1.7)),
    "right": Vector((6.0, 0.0, 1.7)),
}

for action_name, frame in (("STK_WALK", 6.0), ("STK_RUN", 10.0)):
    assign_action(armature, action_name)
    scene.frame_set(int(frame), subframe=frame - int(frame))
    bpy.context.view_layer.update()
    for angle_name, location in angles.items():
        point_camera(camera, location)
        path = OUT / f"STK_HERO_BaseBody_01_CleanRig_{action_name}_{angle_name}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        print(f"RENDER={path}")
