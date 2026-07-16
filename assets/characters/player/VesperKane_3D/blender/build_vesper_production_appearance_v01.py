"""Build Vesper Production Appearance v1 from the approved Production Mesh v1.1."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
import numpy as np


SIZE = 512


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--textures", type=Path, required=True)
    return parser.parse_args(argv)


def smooth_periodic_noise(seed, size=SIZE, octaves=(4, 9, 19, 43)):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:size, 0:size]
    result = np.zeros((size, size), dtype=np.float32)
    weight_total = 0.0
    for index, frequency in enumerate(octaves):
        phase_x, phase_y = rng.random(2) * math.tau
        angle = rng.random() * math.tau
        weight = 1.0 / (1.0 + index * 0.72)
        wave = (
            np.sin((xx * math.cos(angle) + yy * math.sin(angle)) * math.tau * frequency / size + phase_x)
            + np.cos((xx * -math.sin(angle) + yy * math.cos(angle)) * math.tau * (frequency + 1) / size + phase_y)
        ) * 0.25 + 0.5
        result += wave.astype(np.float32) * weight
        weight_total += weight
    result /= weight_total
    random_detail = rng.random((size, size), dtype=np.float32)
    result = result * 0.82 + random_detail * 0.18
    result -= result.min()
    result /= max(result.max(), 1e-6)
    return result


def material_height(kind, seed):
    noise = smooth_periodic_noise(seed)
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    if kind == "fabric":
        weave_x = 0.5 + 0.5 * np.sin(xx * math.tau / 7.0)
        weave_y = 0.5 + 0.5 * np.sin(yy * math.tau / 7.0 + math.pi * 0.5)
        return np.clip(noise * 0.38 + weave_x * 0.32 + weave_y * 0.30, 0.0, 1.0)
    if kind == "leather":
        pores = np.power(noise, 2.6)
        return np.clip(noise * 0.56 + pores * 0.44, 0.0, 1.0)
    if kind == "metal":
        scratches = np.zeros_like(noise)
        rng = np.random.default_rng(seed + 91)
        for _ in range(85):
            y = int(rng.integers(0, SIZE))
            x0 = int(rng.integers(0, SIZE - 20))
            length = int(rng.integers(12, 120))
            scratches[y:y + 1, x0:min(SIZE, x0 + length)] = rng.uniform(0.4, 1.0)
        return np.clip(noise * 0.72 + scratches * 0.28, 0.0, 1.0)
    if kind == "skin":
        return np.clip(noise * 0.72 + smooth_periodic_noise(seed + 7, octaves=(3, 11, 31)) * 0.28, 0.0, 1.0)
    if kind == "rubber":
        stipple = np.power(noise, 3.0)
        return np.clip(noise * 0.35 + stipple * 0.65, 0.0, 1.0)
    return noise


def normal_from_height(height, strength):
    dx = np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)
    dy = np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack((nx / length, ny / length, nz / length), axis=-1) * 0.5 + 0.5


def linear_to_srgb(values):
    values = np.clip(values, 0.0, 1.0)
    return np.where(
        values <= 0.0031308,
        values * 12.92,
        1.055 * np.power(values, 1.0 / 2.4) - 0.055,
    ).astype(np.float32)


def save_image(name, pixels, output_dir, non_color=False):
    path = output_dir / f"{name}.png"
    rgba = np.ones((SIZE, SIZE, 4), dtype=np.float32)
    if pixels.ndim == 2:
        rgba[:, :, :3] = pixels[:, :, None]
    else:
        rgba[:, :, :3] = pixels
    image = bpy.data.images.get(name) or bpy.data.images.new(name, width=SIZE, height=SIZE, alpha=True, float_buffer=False)
    # Assign the data color space before writing pixels. Blender 4.5 can clear
    # an existing byte buffer when this property changes after pixel upload.
    if non_color:
        image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw = str(path.resolve())
    image.file_format = "PNG"
    image.save()
    image.pack()
    image["steamtek_pbr_map"] = name
    return image


def build_texture_set(key, base_color, metallic, roughness, kind, seed, normal_strength, output_dir):
    height = material_height(kind, seed)
    centered = height - 0.5
    base = np.empty((SIZE, SIZE, 3), dtype=np.float32)
    for channel, value in enumerate(base_color):
        base[:, :, channel] = np.clip(value * (1.0 + centered * 0.22), 0.0, 1.0)
    if key == "aged_brass":
        # Material oxidation, not environmental cyan/magenta lighting.
        tarnish = np.clip((height - 0.67) * 2.8, 0.0, 1.0)
        patina = np.array((0.075, 0.115, 0.080), dtype=np.float32)
        base = base * (1.0 - tarnish[:, :, None] * 0.22) + patina * tarnish[:, :, None] * 0.22
    rough = np.clip(roughness + centered * (0.16 if kind != "skin" else 0.08), 0.04, 0.96)
    metal = np.clip(np.full_like(height, metallic) + centered * (0.05 if metallic > 0.3 else 0.0), 0.0, 1.0)
    # At Steamtek's locked gameplay distance, micro-normal gradients must be
    # restrained or they overpower the silhouette and crush neutral lighting.
    normal = normal_from_height(height, normal_strength * 0.08)
    # Blender's color textures are tagged sRGB. Store encoded values so the
    # shader decodes back to the authored linear albedo instead of crushing it.
    base_srgb = linear_to_srgb(base)
    return {
        "base": save_image(f"VK_{key}_BaseColor", base_srgb, output_dir),
        "rough": save_image(f"VK_{key}_Roughness", rough, output_dir, non_color=True),
        "metal": save_image(f"VK_{key}_Metallic", metal, output_dir, non_color=True),
        "normal": save_image(f"VK_{key}_Normal", normal, output_dir, non_color=True),
    }


def image_node(nodes, name, image, location):
    node = nodes.new("ShaderNodeTexImage")
    node.name = name
    node.label = name
    node.image = image
    node.interpolation = "Linear"
    node.extension = "REPEAT"
    node.location = location
    return node


def apply_pbr(material, maps, normal_strength):
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (620, 40)
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.location = (320, 40)
    base = image_node(nodes, "BaseColor", maps["base"], (-520, 230))
    rough = image_node(nodes, "Roughness", maps["rough"], (-520, 50))
    metal = image_node(nodes, "Metallic", maps["metal"], (-520, -130))
    normal_tex = image_node(nodes, "Normal", maps["normal"], (-520, -320))
    normal = nodes.new("ShaderNodeNormalMap")
    normal.location = (60, -230)
    normal.inputs["Strength"].default_value = normal_strength
    links.new(base.outputs["Color"], shader.inputs["Base Color"])
    links.new(rough.outputs["Color"], shader.inputs["Roughness"])
    links.new(metal.outputs["Color"], shader.inputs["Metallic"])
    links.new(normal_tex.outputs["Color"], normal.inputs["Color"])
    links.new(normal.outputs["Normal"], shader.inputs["Normal"])
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    material["steamtek_appearance_stage"] = "production_appearance_v01"
    material["steamtek_runtime_lighting_only"] = True


def preserve_device_material(material):
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = (0.004, 0.055, 0.070, 1.0)
    shader.inputs["Metallic"].default_value = 0.28
    shader.inputs["Roughness"].default_value = 0.28
    shader.inputs["Emission Color"].default_value = (0.015, 0.55, 0.72, 1.0)
    shader.inputs["Emission Strength"].default_value = 0.85
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    material["steamtek_appearance_stage"] = "production_appearance_v01_functional_indicator"
    material["steamtek_baked_environment_color"] = False


def main():
    args = arguments()
    args.textures.resolve().mkdir(parents=True, exist_ok=True)
    configs = {
        "VK_PM01_Coat": ("coat_fabric", (0.030, 0.038, 0.046), 0.00, 0.72, "fabric", 101, 2.4),
        "VK_PM01_CoatEdge": ("coat_edge", (0.052, 0.061, 0.070), 0.12, 0.52, "fabric", 113, 1.8),
        "VK_PM01_Leather": ("black_leather", (0.038, 0.026, 0.021), 0.02, 0.60, "leather", 127, 1.5),
        "VK_PM01_Gunmetal": ("gunmetal", (0.075, 0.088, 0.098), 0.82, 0.34, "metal", 139, 2.2),
        "VK_PM01_DarkMetal": ("dark_steel", (0.038, 0.047, 0.054), 0.76, 0.39, "metal", 151, 2.0),
        "VK_PM01_AgedBrass": ("aged_brass", (0.29, 0.105, 0.022), 0.76, 0.43, "metal", 163, 2.0),
        "VK_PM01_Skin": ("skin", (0.31, 0.145, 0.078), 0.00, 0.58, "skin", 179, 0.55),
        "VK_PM01_Rubber": ("rubber", (0.018, 0.023, 0.027), 0.02, 0.78, "rubber", 191, 1.3),
    }
    generated = []
    for material_name, (key, base, metallic, roughness, kind, seed, normal_strength) in configs.items():
        material = bpy.data.materials[material_name]
        maps = build_texture_set(key, base, metallic, roughness, kind, seed, normal_strength, args.textures.resolve())
        apply_pbr(material, maps, min(0.28, normal_strength * 0.10))
        generated.extend(image.filepath_raw for image in maps.values())
    preserve_device_material(bpy.data.materials["VK_PM01_DeviceCyan"])

    collection = bpy.data.collections["COLLECTION_VesperKane_ProductionMesh_v11"]
    collection.name = "COLLECTION_VesperKane_ProductionAppearance_v01"
    collection["steamtek_stage"] = "production_appearance_v01_pbr_review"
    collection["source_mesh"] = "production_mesh_v11"
    collection["pbr_texture_count"] = len(generated)
    collection["baked_environment_color"] = False
    collection["mechanical_arm_side"] = "physical_left"
    collection["skeleton_changed"] = False
    collection["animation_changed"] = False
    collection["scale_changed"] = False
    bpy.context.scene["steamtek_character_status"] = "production_appearance_v01_ready_for_review"
    bpy.context.scene.frame_set(1)

    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"VESPER_APPEARANCE_BLEND={args.output.resolve()}")
    print(f"VESPER_APPEARANCE_TEXTURES={len(generated)}")
    print("VESPER_APPEARANCE_BAKED_ENVIRONMENT_COLOR=False")
    print("VESPER_APPEARANCE_MECHANICAL_ARM=physical_left")


if __name__ == "__main__":
    main()
