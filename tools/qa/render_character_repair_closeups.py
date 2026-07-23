"""Render localized head, hand, and foot inspection views from a character GLB.

Usage:
    blender.exe --background --python render_character_repair_closeups.py -- \
        input.glb output_directory [target_height_m]
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy
from mathutils import Vector


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


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
if len(arguments) < 2:
    raise SystemExit("Pass input GLB and output directory after --")

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
translation = Vector(
    (
        -(minimum.x + maximum.x) * 0.5,
        -(minimum.y + maximum.y) * 0.5,
        -minimum.z,
    )
)
for root in [obj for obj in bpy.context.scene.objects if obj.parent is None]:
    root.location += translation
bpy.context.view_layer.update()

world = bpy.data.worlds.new("SteamtekRepairReviewWorld")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (
    0.035,
    0.042,
    0.055,
    1.0,
)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.32

camera_data = bpy.data.cameras.new("RepairCamera")
camera = bpy.data.objects.new("RepairCamera", camera_data)
bpy.context.collection.objects.link(camera)
bpy.context.scene.camera = camera
camera_data.type = "ORTHO"

for name, energy, color, location in [
    ("Key", 900, (1.0, 0.92, 0.84), (-2.5, -3.5, 3.2)),
    ("Fill", 550, (0.35, 0.72, 1.0), (2.8, -1.0, 2.5)),
    ("Rim", 650, (1.0, 0.18, 0.5), (0.0, 3.0, 3.0)),
]:
    light_data = bpy.data.lights.new(name, "AREA")
    light_data.energy = energy
    light_data.color = color
    light_data.shape = "DISK"
    light_data.size = 2.0
    light = bpy.data.objects.new(name, light_data)
    bpy.context.collection.objects.link(light)
    light.location = Vector(location)
    look_at(light, Vector((0.0, 0.0, 1.15)))

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 768
scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"

shots = {
    "Hair_Front": (Vector((0.0, -2.2, 1.66)), Vector((0.0, 0.0, 1.66)), 0.48),
    "Hair_Left": (Vector((-2.2, 0.0, 1.66)), Vector((0.0, 0.0, 1.66)), 0.48),
    "Hair_Right": (Vector((2.2, 0.0, 1.66)), Vector((0.0, 0.0, 1.66)), 0.48),
    "Hands_Front": (Vector((0.0, -2.4, 1.0)), Vector((0.0, 0.0, 1.0)), 1.05),
    "LeftHand_Front": (
        Vector((-0.35, -2.0, 0.74)),
        Vector((-0.35, 0.0, 0.74)),
        0.38,
    ),
    "LeftHand_Back": (
        Vector((-0.35, 2.0, 0.74)),
        Vector((-0.35, 0.0, 0.74)),
        0.38,
    ),
    "LeftHand_Side": (
        Vector((-2.0, 0.0, 0.74)),
        Vector((-0.35, 0.0, 0.74)),
        0.38,
    ),
    "RightHand_Front": (
        Vector((0.35, -2.0, 0.74)),
        Vector((0.35, 0.0, 0.74)),
        0.38,
    ),
    "RightHand_Back": (
        Vector((0.35, 2.0, 0.74)),
        Vector((0.35, 0.0, 0.74)),
        0.38,
    ),
    "RightHand_Side": (
        Vector((2.0, 0.0, 0.74)),
        Vector((0.35, 0.0, 0.74)),
        0.38,
    ),
    "Feet_Front": (Vector((0.0, -2.4, 0.11)), Vector((0.0, 0.0, 0.11)), 0.9),
    "Feet_Back": (Vector((0.0, 2.4, 0.11)), Vector((0.0, 0.0, 0.11)), 0.9),
    "LeftFoot_Front": (
        Vector((-0.13, -2.0, 0.08)),
        Vector((-0.13, 0.0, 0.08)),
        0.32,
    ),
    "LeftFoot_Back": (
        Vector((-0.13, 2.0, 0.08)),
        Vector((-0.13, 0.0, 0.08)),
        0.32,
    ),
    "LeftFoot_Top": (
        Vector((-0.13, 0.0, 2.0)),
        Vector((-0.13, 0.0, 0.08)),
        0.32,
    ),
    "RightFoot_Front": (
        Vector((0.13, -2.0, 0.08)),
        Vector((0.13, 0.0, 0.08)),
        0.32,
    ),
    "RightFoot_Back": (
        Vector((0.13, 2.0, 0.08)),
        Vector((0.13, 0.0, 0.08)),
        0.32,
    ),
    "RightFoot_Top": (
        Vector((0.13, 0.0, 2.0)),
        Vector((0.13, 0.0, 0.08)),
        0.32,
    ),
}

for shot_name, (location, target, ortho_scale) in shots.items():
    camera.location = location
    camera_data.ortho_scale = ortho_scale
    look_at(camera, target)
    scene.render.filepath = str(output_directory / f"{source.stem}_{shot_name}.png")
    bpy.ops.render.render(write_still=True)

print(f"STEAMTEK_CHARACTER_REPAIR_CLOSEUPS={output_directory}")
