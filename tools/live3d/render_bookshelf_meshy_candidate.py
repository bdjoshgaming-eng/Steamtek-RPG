#!/usr/bin/env python3
"""Render and extract textures from the staged Meshy bookshelf candidate."""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Bookshelf_A" / "staged_pipeline"
SOURCE = STAGE / "STK_PROP_Bookshelf_A_ProductionCandidate.glb"
PREVIEWS = STAGE / "previews"
TEXTURES = STAGE / "textures"


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    TEXTURES.mkdir(parents=True, exist_ok=True)


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def extract_textures() -> None:
    for image in bpy.data.images:
        if image.name == "Render Result" or image.size[0] == 0:
            continue
        lower = image.name.lower()
        if "basecolor" in lower:
            stem = "STK_PROP_Bookshelf_A_ProductionCandidate_Baked_BaseColor"
        elif "metallicroughness" in lower:
            stem = "STK_PROP_Bookshelf_A_ProductionCandidate_Baked_MetallicRoughness"
        elif "emit" in lower:
            stem = "STK_PROP_Bookshelf_A_ProductionCandidate_Baked_Emit"
        else:
            continue
        image.file_format = "PNG"
        image.filepath_raw = str(TEXTURES / f"{stem}.png")
        image.save()


def matte_preview_materials() -> None:
    """Apply only non-destructive preview clamps; source textures stay intact."""
    for material in bpy.data.materials:
        if not material.use_nodes or not material.node_tree:
            continue
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        if bsdf is None:
            continue
        if bsdf.inputs.get("Specular IOR Level"):
            bsdf.inputs["Specular IOR Level"].default_value = 0.20
        elif bsdf.inputs.get("Specular"):
            bsdf.inputs["Specular"].default_value = 0.20

        mr_node = next(
            (
                node
                for node in material.node_tree.nodes
                if node.type == "TEX_IMAGE"
                and node.image
                and "metallicroughness" in node.image.name.lower()
            ),
            None,
        )
        if mr_node is not None:
            separate = material.node_tree.nodes.new("ShaderNodeSeparateColor")
            multiply = material.node_tree.nodes.new("ShaderNodeMath")
            floor = material.node_tree.nodes.new("ShaderNodeMath")
            multiply.operation = "MULTIPLY"
            multiply.inputs[1].default_value = 1.25
            floor.operation = "MAXIMUM"
            floor.inputs[1].default_value = 0.72
            material.node_tree.links.new(mr_node.outputs["Color"], separate.inputs["Color"])
            material.node_tree.links.new(separate.outputs["Green"], multiply.inputs[0])
            material.node_tree.links.new(multiply.outputs[0], floor.inputs[0])
            material.node_tree.links.new(floor.outputs[0], bsdf.inputs["Roughness"])


def add_area(name: str, location, energy: float, size: float, color) -> None:
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.name = name
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    light.data.color = color
    look_at(light, (0.0, 0.0, 1.0))


def setup_scene() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.image_settings.color_mode = "RGBA"
    world = bpy.data.worlds.new("Steamtek_QA_World")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.025, 0.030, 0.038, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.32
    scene.world = world

    floor_mat = bpy.data.materials.new("QA_Floor")
    floor_mat.diffuse_color = (0.07, 0.075, 0.085, 1)
    floor_mat.roughness = 0.90
    bpy.ops.mesh.primitive_plane_add(size=6.0, location=(0.0, 0.0, -0.002))
    floor = bpy.context.object
    floor.name = "QA_Floor"
    floor.data.materials.append(floor_mat)

    add_area("Warm_Key", (2.8, 3.5, 3.6), 720.0, 3.0, (1.0, 0.70, 0.52))
    add_area("Cool_Fill", (-2.8, 2.1, 2.4), 520.0, 2.6, (0.38, 0.72, 1.0))
    add_area("Rear_Rim", (0.0, -2.5, 3.0), 460.0, 2.2, (0.28, 0.58, 0.82))

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "QA_Camera"
    scene.camera = camera
    return camera


def render_views(camera: bpy.types.Object) -> None:
    scene = bpy.context.scene
    views = {
        "Front": ((0.0, -4.0, 1.02), (0.0, 0.0, 1.02), 2.26, (620, 900)),
        "Back": ((0.0, 4.0, 1.02), (0.0, 0.0, 1.02), 2.26, (620, 900)),
        "Left": ((-3.0, 0.0, 1.02), (0.0, 0.0, 1.02), 2.26, (620, 900)),
        "Right": ((3.0, 0.0, 1.02), (0.0, 0.0, 1.02), 2.26, (620, 900)),
        "Top": ((0.0, 0.0, 4.0), (0.0, 0.0, 0.85), 1.46, (900, 620)),
    }
    for name, (location, target, ortho_scale, resolution) in views.items():
        camera.data.type = "ORTHO"
        camera.data.ortho_scale = ortho_scale
        camera.location = location
        look_at(camera, target)
        scene.render.resolution_x, scene.render.resolution_y = resolution
        scene.render.filepath = str(PREVIEWS / f"STK_PROP_Bookshelf_A_Candidate_{name}.png")
        bpy.ops.render.render(write_still=True)

    camera.data.type = "PERSP"
    camera.data.lens = 62
    camera.location = (2.55, -3.25, 2.45)
    look_at(camera, (0.0, 0.0, 1.0))
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.filepath = str(PREVIEWS / "STK_PROP_Bookshelf_A_Candidate_ThreeQuarter.png")
    bpy.ops.render.render(write_still=True)


def main() -> None:
    reset()
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    extract_textures()
    matte_preview_materials()
    camera = setup_scene()
    render_views(camera)
    print(f"Rendered previews to {PREVIEWS}")


if __name__ == "__main__":
    main()
