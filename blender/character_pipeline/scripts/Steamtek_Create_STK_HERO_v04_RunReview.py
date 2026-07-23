import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
OUTPUT = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "heroes"
    / "STK_HERO_BaseBody_01_Rigged_MeshyMotion_v04_RUN_REVIEW.blend"
)

scene = bpy.context.scene
armature = bpy.data.objects["STK_HERO_BaseBody_01_Armature"]
body = bpy.data.objects["STK_HERO_BaseBody_01_RiggedBody"]
action = bpy.data.actions["STK_RUN"]

armature.animation_data_create()
armature.animation_data.action = action
armature.animation_data.action_slot = action.slots[0]
armature.data.pose_position = "POSE"

frame_start, frame_end = action.frame_range
scene.frame_start = math.floor(frame_start)
scene.frame_end = math.ceil(frame_end)
scene.use_preview_range = True
scene.frame_preview_start = scene.frame_start
scene.frame_preview_end = scene.frame_end
scene.frame_set(scene.frame_start)

bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body

bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))
print(f"OUTPUT={OUTPUT}")
print(f"ACTION={action.name}")
print(f"FRAME_START={scene.frame_start}")
print(f"FRAME_END={scene.frame_end}")
