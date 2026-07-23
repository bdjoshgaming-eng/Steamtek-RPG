from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
OUTPUT_DIR = ROOT / "output" / "hero_rig_rebuild" / "review_v02_walk_cycle"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

scene = bpy.context.scene
armature = bpy.data.objects["STK_HERO_BaseBody_01_Armature"]
armature.data.pose_position = "POSE"

cycles = {
    "STK_WALK": (0, 3, 6, 9, 12, 15, 18, 21, 24),
    "STK_RUN": (0, 2, 4, 6, 8, 10, 12, 14, 16),
}

armature.animation_data_create()
for action_name, frames in cycles.items():
    action = bpy.data.actions[action_name]
    armature.animation_data.action = action
    armature.animation_data.action_slot = action.slots[0]
    for frame in frames:
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        scene.render.filepath = str(
            OUTPUT_DIR / f"{action_name.lower()}_v02_frame_{frame:02d}.png"
        )
        bpy.ops.render.render(write_still=True)
        print(f"RENDER={scene.render.filepath}")
