"""Shared deterministic Blender render standard for Steamtek Modular v2 assets."""

from __future__ import annotations

from pathlib import Path

import bpy
from mathutils import Vector


RENDER_WIDTH = 1280
RENDER_HEIGHT = 1440
ORTHO_CAMERA_LOCATION = (-4.81, -6.08, 7.54)
ORTHO_CAMERA_TARGET = (0.0, 0.0, 1.25)
ORTHO_SCALE = 3.529

PROFILES = {
    "standard_surface": {
        "key": 900.0,
        "fill": 150.0,
        "rim": 500.0,
    },
    "narrow_trim": {
        # Narrow sprites need extra cool fill but restrained edge light so their
        # faces survive downsampling without turning into bright chevrons.
        "key": 980.0,
        "fill": 350.0,
        "rim": 145.0,
    },
    "horizontal_trim": {
        "key": 940.0,
        "fill": 220.0,
        "rim": 280.0,
    },
    "prop": {
        "key": 960.0,
        "fill": 240.0,
        "rim": 320.0,
    },
    "roof_surface": {
        "key": 850.0,
        "fill": 200.0,
        "rim": 350.0,
    },
    "foundation": {
        "key": 900.0,
        "fill": 230.0,
        "rim": 300.0,
    },
}


def material(name: str, color, metallic: float, roughness: float):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    return mat


def weathered_material(name: str, low_color, high_color, metallic: float, roughness: float):
    mat = material(name, high_color, metallic, roughness)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    principled = nodes.get("Principled BSDF")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "BroadSurfaceWear"
    noise.inputs["Scale"].default_value = 9.0
    noise.inputs["Detail"].default_value = 3.2
    noise.inputs["Roughness"].default_value = 0.60
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.name = "SteamtekMaterialColor"
    ramp.color_ramp.elements[0].color = low_color
    ramp.color_ramp.elements[1].color = high_color
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.018
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], principled.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], principled.inputs["Normal"])
    return mat


def narrow_trim_materials():
    """Approved role materials for columns, seams, posts, and small caps."""
    return {
        "core": material("STK_Narrow_Core", (0.021, 0.034, 0.050, 1.0), 0.48, 0.44),
        "face": weathered_material(
            "STK_Narrow_Face",
            (0.026, 0.041, 0.060, 1.0),
            (0.072, 0.100, 0.135, 1.0),
            0.40,
            0.47,
        ),
        "edge": material("STK_Narrow_Edge", (0.065, 0.088, 0.115, 1.0), 0.52, 0.38),
        "bolt": material("STK_Narrow_Bolt", (0.012, 0.018, 0.026, 1.0), 0.86, 0.20),
        "copper": material("STK_Narrow_Copper", (0.095, 0.029, 0.011, 1.0), 0.80, 0.40),
    }


def standard_surface_materials():
    """Approved W001 material roles for full wall bays and facade openings."""
    composite = material("STK_ConcreteComposite", (0.032, 0.045, 0.062, 1.0), 0.14, 0.43)
    nodes = composite.node_tree.nodes
    links = composite.node_tree.links
    principled = nodes.get("Principled BSDF")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "BroadSurfaceWear"
    noise.inputs["Scale"].default_value = 8.5
    noise.inputs["Detail"].default_value = 4.0
    noise.inputs["Roughness"].default_value = 0.58
    noise.inputs["Distortion"].default_value = 0.035
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.name = "SteamtekPanelColor"
    ramp.color_ramp.elements[0].position = 0.26
    ramp.color_ramp.elements[0].color = (0.010, 0.014, 0.021, 1.0)
    ramp.color_ramp.elements[1].position = 0.76
    ramp.color_ramp.elements[1].color = (0.034, 0.046, 0.061, 1.0)
    bump = nodes.new("ShaderNodeBump")
    bump.name = "MicroPitting"
    bump.inputs["Strength"].default_value = 0.10
    bump.inputs["Distance"].default_value = 0.028
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], principled.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], principled.inputs["Normal"])
    return {
        "composite": composite,
        "gunmetal": material("STK_Gunmetal", (0.018, 0.028, 0.042, 1.0), 0.82, 0.24),
        "black": material("STK_BlackSteel", (0.009, 0.013, 0.019, 1.0), 0.72, 0.31),
        "copper": material("STK_Copper", (0.22, 0.065, 0.018, 1.0), 0.88, 0.22),
        "edge": material("STK_PanelEdge", (0.034, 0.042, 0.052, 1.0), 0.62, 0.40),
        "cap": material("STK_WallCap", (0.014, 0.018, 0.023, 1.0), 0.24, 0.66),
    }


def point_at(obj, target=ORTHO_CAMERA_TARGET) -> None:
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def add_area_light(name, location, energy, size, color, target=ORTHO_CAMERA_TARGET):
    data = bpy.data.lights.new(name=name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    point_at(obj, target)
    return obj


def configure_render_scene(scene, render_path: Path, profile_name: str, target=ORTHO_CAMERA_TARGET) -> None:
    if profile_name not in PROFILES:
        raise ValueError(f"Unknown Steamtek render profile: {profile_name}")
    profile = PROFILES[profile_name]

    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = RENDER_WIDTH
    scene.render.resolution_y = RENDER_HEIGHT
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.image_settings.compression = 15
    scene.render.film_transparent = True
    scene.render.filepath = str(render_path)
    scene.view_settings.look = "AgX - Medium High Contrast"

    world = scene.world or bpy.data.worlds.new("SteamtekWorld")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.006, 0.010, 0.018, 1.0)
    background.inputs["Strength"].default_value = 0.18

    camera_data = bpy.data.cameras.new("SMV2_OrthoCamera")
    camera = bpy.data.objects.new("SMV2_OrthoCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = ORTHO_CAMERA_LOCATION
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = ORTHO_SCALE
    point_at(camera, target)
    scene.camera = camera

    add_area_light("Key_Cool", (4.5, -5.5, 7.5), profile["key"], 5.0, (0.64, 0.72, 0.84), target)
    add_area_light("Fill_Cyan", (-4.0, -2.0, 4.2), profile["fill"], 4.0, (0.22, 0.55, 0.70), target)
    add_area_light("Rim_Amber", (-2.5, 3.5, 5.5), profile["rim"], 3.0, (0.88, 0.30, 0.10), target)
