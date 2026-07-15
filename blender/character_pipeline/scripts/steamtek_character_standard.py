"""Locked Blender render standard for Steamtek animated characters."""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


FRAME_WIDTH = 512
FRAME_HEIGHT = 512
TARGET_VISIBLE_WORLD_HEIGHT = 100.0
TARGET_SOURCE_HEIGHT = 400
ORTHO_SCALE = 2.30
CAMERA_TARGET = (0.0, 0.0, 0.90)

# Keep the same viewing direction as the approved Steamtek environment standard.
_ENV_CAMERA = Vector((-4.81, -6.08, 7.54))
_ENV_TARGET = Vector((0.0, 0.0, 1.25))
_VIEW_DIRECTION = (_ENV_CAMERA - _ENV_TARGET).normalized()
CAMERA_LOCATION = Vector(CAMERA_TARGET) + (_VIEW_DIRECTION * 10.0)

DIRECTIONS = (
    ("south", 0.0),
    ("south_west", -45.0),
    ("west", -90.0),
    ("north_west", -135.0),
    ("north", 180.0),
    ("north_east", 135.0),
    ("east", 90.0),
    ("south_east", 45.0),
)


def point_at(obj: bpy.types.Object, target=CAMERA_TARGET) -> None:
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def configure_scene(scene: bpy.types.Scene, output_path: Path | None = None) -> None:
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = FRAME_WIDTH
    scene.render.resolution_y = FRAME_HEIGHT
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.image_settings.compression = 15
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    if output_path is not None:
        scene.render.filepath = str(output_path)

    world = scene.world or bpy.data.worlds.new("SteamtekCharacterWorld")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.004, 0.008, 0.014, 1.0)
    background.inputs["Strength"].default_value = 0.12


def create_camera(scene: bpy.types.Scene) -> bpy.types.Object:
    old = bpy.data.objects.get("STK_CharacterCamera")
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    data = bpy.data.cameras.new("STK_CharacterCamera")
    camera = bpy.data.objects.new("STK_CharacterCamera", data)
    bpy.context.collection.objects.link(camera)
    camera.location = CAMERA_LOCATION
    data.type = "ORTHO"
    data.ortho_scale = ORTHO_SCALE
    point_at(camera)
    scene.camera = camera
    return camera


def _area_light(name: str, location, energy: float, size: float, color) -> bpy.types.Object:
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    data = bpy.data.lights.new(name=name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    point_at(obj)
    return obj


def create_lights() -> None:
    # Match the locked standard_surface profile in steamtek_render_standard.py.
    _area_light("STK_Key_Cool", (4.5, -5.5, 7.5), 900.0, 5.0, (0.64, 0.72, 0.84))
    _area_light("STK_Fill_Cyan", (-4.0, -2.0, 4.2), 150.0, 4.0, (0.22, 0.55, 0.70))
    _area_light("STK_Rim_Amber", (-2.5, 3.5, 5.5), 500.0, 3.0, (0.88, 0.30, 0.10))


def configure_character_stage(scene: bpy.types.Scene, output_path: Path | None = None) -> None:
    configure_scene(scene, output_path)
    create_camera(scene)
    create_lights()


def direction_radians(name: str) -> float:
    for direction, degrees in DIRECTIONS:
        if direction == name:
            return math.radians(degrees)
    raise ValueError(f"Unknown direction: {name}")
