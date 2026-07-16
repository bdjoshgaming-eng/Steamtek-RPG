"""Render neutral locked-camera reviews for Vesper's modular character branch."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
parser = argparse.ArgumentParser()
parser.add_argument("--output-dir", type=Path, required=True)
args = parser.parse_args(argv)


def look_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def material(name, color, metallic=0.0, roughness=0.7):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = next(node for node in mat.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.012, 0.016, 0.021)

    # Neutral floor and backdrop: no cyan/magenta art-direction contamination.
    bpy.ops.mesh.primitive_plane_add(size=18, location=(0, 0, -0.005))
    floor = bpy.context.object
    floor.name = "REVIEW_NeutralFloor"
    floor.data.materials.append(material("REVIEW_Floor", (0.055, 0.062, 0.068), 0.1, 0.78))

    bpy.ops.object.camera_add(location=(4.50, -7.79, 5.20))
    camera = bpy.context.object
    camera.name = "REVIEW_Locked60DegreeCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.65
    look_at(camera, (0, 0, 1.12))
    scene.camera = camera

    lights = [
        ((-3.8, -4.6, 6.4), 850.0, (1.0, 0.88, 0.72), 4.0),
        ((4.6, -1.0, 4.2), 520.0, (0.76, 0.86, 1.0), 3.0),
        ((0.0, 4.5, 5.0), 420.0, (1.0, 0.72, 0.50), 3.0),
    ]
    for index, (location, energy, color, size) in enumerate(lights):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = f"REVIEW_Light_{index}"
        light.data.energy = energy
        light.data.color = color
        light.data.shape = "DISK"
        light.data.size = size
        look_at(light, (0, 0, 1.0))


def set_state(state):
    for obj in bpy.data.objects:
        if obj.type != "MESH" or not obj.name.startswith(("VK_MB01_", "VK_SLOT_")):
            continue
        visible = True
        if state == "body_only":
            visible = obj.name.startswith("VK_MB01_")
        elif state == "mixed_loadout":
            # Demonstrates that torso/headgear slots can be removed independently.
            visible = not obj.name.startswith(("VK_SLOT_OUTER_TORSO_", "VK_SLOT_HEADGEAR_", "VK_SLOT_SHOULDERS_"))
        obj.hide_render = not visible
        obj.hide_set(not visible)


def render(state, filename, action_name="STK_IDLE", frame=1):
    set_state(state)
    scene = bpy.context.scene
    rig = bpy.data.objects.get("Armature")
    if rig and rig.animation_data and bpy.data.actions.get(action_name):
        rig.animation_data.action = bpy.data.actions[action_name]
    scene.render.filepath = str((args.output_dir / filename).resolve())
    scene.frame_set(frame)
    bpy.ops.render.render(write_still=True)
    print(f"VESPER_REVIEW={scene.render.filepath}")


args.output_dir.mkdir(parents=True, exist_ok=True)
setup_scene()
render("body_only", "Vesper_ModularBody_v01_locked60.png")
render("fully_equipped", "Vesper_DefaultOutfit_v01_locked60.png")
render("mixed_loadout", "Vesper_MixedLoadout_v01_locked60.png")
render("body_only", "Vesper_ModularBody_v01_walk_frame13.png", "STK_WALK", 13)
render("fully_equipped", "Vesper_DefaultOutfit_v01_walk_frame13.png", "STK_WALK", 13)
