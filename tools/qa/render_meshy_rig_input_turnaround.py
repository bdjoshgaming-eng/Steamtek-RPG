"""Render eight neutral validation angles from an exported Meshy rig-input GLB.

Usage:
    blender.exe --background --python render_meshy_rig_input_turnaround.py -- \
        input.glb output_directory
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
if len(arguments) not in (2, 3):
    raise SystemExit(
        "Pass input GLB, output directory, and optional double_sided after --"
    )
source = Path(arguments[0]).resolve()
output_directory = Path(arguments[1]).resolve()
double_sided = len(arguments) == 3 and arguments[2] == "double_sided"
output_directory.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if len(meshes) != 1:
    raise RuntimeError(f"Expected one mesh; found {len(meshes)}")
body = meshes[0]
if double_sided:
    for material in body.data.materials:
        if material is not None:
            material.use_backface_culling = False
corners = [body.matrix_world @ Vector(corner) for corner in body.bound_box]
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
center = (minimum + maximum) * 0.5
height = maximum.z - minimum.z

world = bpy.data.worlds.new("MeshyRigInputReviewWorld")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (
    0.018,
    0.022,
    0.028,
    1.0,
)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35

camera_data = bpy.data.cameras.new("TurnaroundCamera")
camera = bpy.data.objects.new("TurnaroundCamera", camera_data)
bpy.context.collection.objects.link(camera)
bpy.context.scene.camera = camera
camera_data.type = "ORTHO"
camera_data.ortho_scale = height * 1.18

for name, energy, location in [
    ("Key", 700.0, Vector((-3.0, -4.0, 4.2))),
    ("Fill", 350.0, Vector((3.2, -2.0, 2.8))),
    ("Rim", 450.0, Vector((0.0, 3.5, 3.5))),
]:
    light_data = bpy.data.lights.new(name, "AREA")
    light_data.energy = energy
    light_data.color = (1.0, 1.0, 1.0)
    light_data.shape = "DISK"
    light_data.size = 3.0
    light = bpy.data.objects.new(name, light_data)
    bpy.context.collection.objects.link(light)
    light.location = location
    look_at(light, center)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 720
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGB"
scene.render.film_transparent = False
scene.render.image_settings.color_depth = "8"

views = [
    ("Front", 0.0),
    ("FrontRight", 45.0),
    ("Right", 90.0),
    ("BackRight", 135.0),
    ("Back", 180.0),
    ("BackLeft", 225.0),
    ("Left", 270.0),
    ("FrontLeft", 315.0),
]
radius = 4.5
for name, degrees in views:
    radians = math.radians(degrees)
    camera.location = Vector(
        (
            math.sin(radians) * radius,
            -math.cos(radians) * radius,
            center.z,
        )
    )
    look_at(camera, center)
    scene.render.filepath = str(output_directory / f"{source.stem}_{name}.png")
    bpy.ops.render.render(write_still=True)

print(f"STEAMTEK_MESHY_RIG_INPUT_TURNAROUND={output_directory}")
