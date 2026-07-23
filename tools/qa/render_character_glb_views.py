"""Render neutral inspection views of a GLB in Blender.

Usage:
    blender.exe --background --python render_character_glb_views.py -- \
        input.glb output_directory [target_height_m]
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def look_at(camera: bpy.types.Object, target: Vector) -> None:
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()


def mesh_objects() -> list[bpy.types.Object]:
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in objects
        for corner in obj.bound_box
    ]
    minimum = Vector(
        (
            min(corner.x for corner in corners),
            min(corner.y for corner in corners),
            min(corner.z for corner in corners),
        )
    )
    maximum = Vector(
        (
            max(corner.x for corner in corners),
            max(corner.y for corner in corners),
            max(corner.z for corner in corners),
        )
    )
    return minimum, maximum


arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
source = Path(arguments[0]).resolve()
output_directory = Path(arguments[1]).resolve()
target_height = float(arguments[2]) if len(arguments) > 2 else 1.83
output_directory.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = mesh_objects()
minimum, maximum = bounds(meshes)
scale_factor = target_height / (maximum.z - minimum.z)
for obj in bpy.context.scene.objects:
    obj.scale *= scale_factor
bpy.context.view_layer.update()
minimum, maximum = bounds(meshes)
translation = Vector((-(minimum.x + maximum.x) * 0.5, -(minimum.y + maximum.y) * 0.5, -minimum.z))
for root in [obj for obj in bpy.context.scene.objects if obj.parent is None]:
    root.location += translation
bpy.context.view_layer.update()
minimum, maximum = bounds(meshes)
center = (minimum + maximum) * 0.5

world = bpy.data.worlds.new("SteamtekReviewWorld")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.055, 0.065, 0.08, 1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.28

camera_data = bpy.data.cameras.new("ReviewCamera")
camera = bpy.data.objects.new("ReviewCamera", camera_data)
bpy.context.collection.objects.link(camera)
bpy.context.scene.camera = camera
camera_data.type = "ORTHO"
camera_data.ortho_scale = max(target_height * 1.25, 2.25)

key_data = bpy.data.lights.new("Key", "AREA")
key_data.energy = 850
key_data.shape = "DISK"
key_data.size = 4.0
key = bpy.data.objects.new("Key", key_data)
bpy.context.collection.objects.link(key)
key.location = Vector((-3.5, -4.0, 4.5))
look_at(key, center)

fill_data = bpy.data.lights.new("Fill", "AREA")
fill_data.energy = 500
fill_data.color = (0.35, 0.75, 1.0)
fill_data.size = 3.0
fill = bpy.data.objects.new("Fill", fill_data)
bpy.context.collection.objects.link(fill)
fill.location = Vector((3.0, 1.5, 2.8))
look_at(fill, center)

rim_data = bpy.data.lights.new("Rim", "AREA")
rim_data.energy = 600
rim_data.color = (1.0, 0.2, 0.55)
rim_data.size = 2.5
rim = bpy.data.objects.new("Rim", rim_data)
bpy.context.collection.objects.link(rim)
rim.location = Vector((0.0, 3.5, 3.2))
look_at(rim, center)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 640
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
scene.render.resolution_percentage = 100
scene.render.image_settings.color_mode = "RGBA"

views = {
    "Front": Vector((0.0, -4.5, center.z)),
    "Back": Vector((0.0, 4.5, center.z)),
    "Left": Vector((-4.5, 0.0, center.z)),
    "Right": Vector((4.5, 0.0, center.z)),
}
for name, location in views.items():
    camera.location = location
    look_at(camera, center)
    scene.render.filepath = str(output_directory / f"{source.stem}_{name}.png")
    bpy.ops.render.render(write_still=True)

print(f"STEAMTEK_CHARACTER_VIEWS={output_directory}")
