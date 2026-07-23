from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
OUTPUT_DIR = (
    ROOT
    / "output"
    / "hero_rig_rebuild"
    / "review_v04_solid"
)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.render.resolution_x = 640
scene.render.resolution_y = 640
scene.render.resolution_percentage = 100
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "SINGLE"
scene.display.shading.single_color = (0.62, 0.62, 0.62)
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.cavity_type = "WORLD"
scene.display.shading.background_type = "VIEWPORT"
scene.display.shading.background_color = (0.13, 0.13, 0.13)

armature = bpy.data.objects["STK_HERO_BaseBody_01_Armature"]
armature.animation_data_create()
armature.data.pose_position = "POSE"
armature.hide_render = True

cycles = {
    "walk": ("STK_WALK", (0, 3, 6, 9, 12, 15, 18, 21, 24)),
    "run": ("STK_RUN", (0, 2, 4, 6, 8, 10, 12, 14, 16)),
}

for cycle_name, (action_name, frames) in cycles.items():
    action = bpy.data.actions[action_name]
    armature.animation_data.action = action
    armature.animation_data.action_slot = action.slots[0]
    for frame in frames:
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        scene.render.filepath = str(
            OUTPUT_DIR
            / f"stk_{cycle_name}_v04_solid_frame_{frame:02d}.png"
        )
        bpy.ops.render.render(write_still=True)
        print(f"RENDER={scene.render.filepath}")
