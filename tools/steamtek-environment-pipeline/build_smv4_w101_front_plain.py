"""Build Steamtek's first high-fidelity snap-safe environment wall.

The wall is modeled on the locked SMV4 construction basis.  Geometry,
projection, anchors, and alpha remain authoritative; material detail can be
iterated without moving the snap contract.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
CAMERA_BLENDER = ROOT / "camera_pipeline" / "blender"
sys.path.insert(0, str(CAMERA_BLENDER))

from steamtek_offaxis60_camera import (  # noqa: E402
    CAMERA_FORWARD,
    FRONT_BAY_STEP,
    FRONT_WORLD_STEP,
    PROFILE_ID,
    STOREY_RISE,
    configure_camera,
    configure_render,
)


MODULE_ID = "SMV4_W101_FrontPlain"
CONTRACT_ID = "environment_off_axis_60_v4"
RENDER_WIDTH = 640
RENDER_HEIGHT = 512
# Orthographic scale is locked against render width so rectangular production
# canvases preserve the same horizontal snap delta as the square calibration.
# World +Z projects into screen Y by the camera's horizontal-plane component.
VERTICAL_SCREEN_FACTOR = math.sqrt(1.0 - CAMERA_FORWARD.z * CAMERA_FORWARD.z)
STOREY_HEIGHT_BU = abs(STOREY_RISE.y) / (181.01933598375618 * VERTICAL_SCREEN_FACTOR)
WALL_THICKNESS = 0.14


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--blend", required=True)
    parser.add_argument("--godot", required=True)
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(argv)


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.materials, bpy.data.curves, bpy.data.meshes, bpy.data.cameras, bpy.data.lights):
        pass


def principled_material(name, base_color, metallic, roughness):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def weathered_metal_material(name, dark_color, light_color, metallic=0.9, roughness=0.3):
    """Portable procedural metal with small-scale age and surface breakup."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    for node in list(nodes):
        nodes.remove(node)

    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    noise = nodes.new("ShaderNodeTexNoise")
    ramp = nodes.new("ShaderNodeValToRGB")
    bump = nodes.new("ShaderNodeBump")

    noise.inputs["Scale"].default_value = 38.0
    noise.inputs["Detail"].default_value = 7.0
    noise.inputs["Roughness"].default_value = 0.72
    ramp.color_ramp.elements[0].position = 0.27
    ramp.color_ramp.elements[0].color = (*dark_color, 1.0)
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = (*light_color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bump.inputs["Strength"].default_value = 0.16
    bump.inputs["Distance"].default_value = 0.018

    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def textured_panel_material():
    mat = bpy.data.materials.new("STK_MasonryPanel")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    for node in list(nodes):
        nodes.remove(node)

    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    noise = nodes.new("ShaderNodeTexNoise")
    fine_noise = nodes.new("ShaderNodeTexNoise")
    mix = nodes.new("ShaderNodeMixRGB")
    ramp = nodes.new("ShaderNodeValToRGB")
    bump = nodes.new("ShaderNodeBump")

    # Dense, wet, cast-stone surface.  This stays procedural so the master
    # remains portable between machines and never depends on missing textures.
    noise.inputs["Scale"].default_value = 6.5
    noise.inputs["Detail"].default_value = 9.0
    noise.inputs["Roughness"].default_value = 0.78
    noise.inputs["Distortion"].default_value = 0.34
    ramp.color_ramp.elements[0].position = 0.20
    fine_noise.inputs["Scale"].default_value = 92.0
    fine_noise.inputs["Detail"].default_value = 4.0
    fine_noise.inputs["Roughness"].default_value = 0.82
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.42
    ramp.color_ramp.elements[0].color = (0.010, 0.012, 0.017, 1.0)
    ramp.color_ramp.elements[1].position = 0.82
    ramp.color_ramp.elements[1].color = (0.075, 0.080, 0.095, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.24
    bsdf.inputs["Roughness"].default_value = 0.34
    bump.inputs["Strength"].default_value = 0.48
    bump.inputs["Distance"].default_value = 0.035

    links.new(noise.outputs["Fac"], mix.inputs[1])
    links.new(fine_noise.outputs["Fac"], mix.inputs[2])
    links.new(mix.outputs["Color"], ramp.inputs["Fac"])
    links.new(fine_noise.outputs["Fac"], bump.inputs["Height"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def emission_material(name, color, strength):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.15
    bsdf.inputs["Roughness"].default_value = 0.2
    bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def add_box(name, center, dimensions, rotation_z, material, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=center, rotation=(0.0, 0.0, rotation_z))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("MicroBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(material)
    return obj


def add_cylinder_between(name, p0, p1, radius, material, vertices=24):
    p0 = Vector(p0)
    p1 = Vector(p1)
    delta = p1 - p0
    midpoint = (p0 + p1) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("EdgeSoftening", "BEVEL")
    bevel.width = radius * 0.16
    bevel.segments = 2
    return obj


def add_uv_sphere(name, center, radius, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=radius, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return obj


def project_pixel(scene, camera, point):
    co = world_to_camera_view(scene, camera, Vector(point))
    return [co.x * scene.render.resolution_x, (1.0 - co.y) * scene.render.resolution_y]


def write_godot_scene(path, texture_name, anchor_left):
    x = -anchor_left[0]
    y = -anchor_left[1]
    text = f'''[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/modular_v4/production/{texture_name}" id="1_tex"]\n\n[node name="{MODULE_ID}_HD" type="Node2D"]\nmetadata/contract_id = "{CONTRACT_ID}"\nmetadata/camera_profile = "{PROFILE_ID}"\nmetadata/module_id = "{MODULE_ID}"\nmetadata/bay_step_front = Vector2({FRONT_BAY_STEP.x:.3f}, {FRONT_BAY_STEP.y:.3f})\nmetadata/storey_rise = Vector2({STOREY_RISE.x:.3f}, {STOREY_RISE.y:.3f})\n\n[node name="Visual" type="Sprite2D" parent="."]\ntexture = ExtResource("1_tex")\ncentered = false\nposition = Vector2({x:.3f}, {y:.3f})\ntexture_filter = 1\n\n[node name="Snap_Left" type="Marker2D" parent="."]\nposition = Vector2(0, 0)\n\n[node name="Snap_Right" type="Marker2D" parent="."]\nposition = Vector2({FRONT_BAY_STEP.x:.3f}, {FRONT_BAY_STEP.y:.3f})\n\n[node name="Snap_TopLeft" type="Marker2D" parent="."]\nposition = Vector2({STOREY_RISE.x:.3f}, {STOREY_RISE.y:.3f})\n\n[node name="Snap_TopRight" type="Marker2D" parent="."]\nposition = Vector2({FRONT_BAY_STEP.x + STOREY_RISE.x:.3f}, {FRONT_BAY_STEP.y + STOREY_RISE.y:.3f})\n'''
    Path(path).write_text(text, encoding="utf-8")


def main():
    args = parse_args()
    output = Path(args.output).resolve()
    metadata_path = Path(args.metadata).resolve()
    blend_path = Path(args.blend).resolve()
    godot_path = Path(args.godot).resolve()
    for path in (output, metadata_path, blend_path, godot_path):
        path.parent.mkdir(parents=True, exist_ok=True)

    reset_scene()
    scene = bpy.context.scene
    configure_render(scene, RENDER_WIDTH, RENDER_HEIGHT, output)
    scene.render.image_settings.color_depth = "16"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.compression = 10
    scene.render.resolution_percentage = 100
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 0.18

    world = bpy.data.worlds.new("SteamtekWorld") if not scene.world else scene.world
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.010, 0.014, 0.025, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.20

    masonry = textured_panel_material()
    backing_mat = weathered_metal_material("STK_Backing", (0.008, 0.011, 0.017), (0.030, 0.038, 0.052), 0.72, 0.36)
    frame_mat = weathered_metal_material("STK_GunmetalFrame", (0.018, 0.022, 0.030), (0.085, 0.095, 0.115), 0.94, 0.25)
    copper = weathered_metal_material("STK_Copper", (0.075, 0.018, 0.006), (0.48, 0.14, 0.025), 0.91, 0.28)
    fastener = weathered_metal_material("STK_Fastener", (0.035, 0.040, 0.050), (0.20, 0.22, 0.26), 0.96, 0.18)
    cyan = emission_material("STK_CyanEmitter", (0.0, 0.32, 0.68), 6.0)
    magenta = emission_material("STK_MagentaEmitter", (0.60, 0.004, 0.22), 5.0)

    u = FRONT_WORLD_STEP.normalized()
    n = Vector((u.y, -u.x, 0.0))
    angle = math.atan2(u.y, u.x)
    width = FRONT_WORLD_STEP.length
    height = STOREY_HEIGHT_BU

    wall_center = u * (width * 0.5) + Vector((0.0, 0.0, height * 0.5))
    add_box("WallBacking", wall_center, (width, WALL_THICKNESS, height), angle, backing_mat, 0.018)

    face_offset = n * (WALL_THICKNESS * 0.5 + 0.018)
    cols = 4
    rows = 4
    gap_x = 0.025
    gap_z = 0.025
    border_x = 0.055
    border_z = 0.05
    panel_w = (width - border_x * 2.0 - gap_x * (cols - 1)) / cols
    panel_h = (height - border_z * 2.0 - gap_z * (rows - 1)) / rows
    for row in range(rows):
        for col in range(cols):
            x = border_x + panel_w * 0.5 + col * (panel_w + gap_x)
            z = border_z + panel_h * 0.5 + row * (panel_h + gap_z)
            center = u * x + Vector((0.0, 0.0, z)) + face_offset
            add_box(f"Panel_{row}_{col}", center, (panel_w, 0.032, panel_h), angle, masonry, 0.018)
            # Small corner rivets make each cast panel read as manufactured
            # infrastructure rather than a single clean painted slab.
            for dx in (-panel_w * 0.40, panel_w * 0.40):
                for dz in (-panel_h * 0.34, panel_h * 0.34):
                    rivet = center + u * dx + Vector((0.0, 0.0, dz)) + n * 0.030
                    add_uv_sphere(f"PanelRivet_{row}_{col}_{dx}_{dz}", rivet, 0.008, fastener)

    frame_depth = 0.045
    frame_offset = n * (WALL_THICKNESS * 0.5 + frame_depth * 0.5 + 0.045)
    add_box("FrameBottom", u * (width * 0.5) + Vector((0, 0, 0.035)) + frame_offset, (width, frame_depth, 0.065), angle, frame_mat, 0.012)
    add_box("FrameTop", u * (width * 0.5) + Vector((0, 0, height - 0.035)) + frame_offset, (width, frame_depth, 0.065), angle, frame_mat, 0.012)
    add_box("FrameLeft", Vector((0, 0, height * 0.5)) + frame_offset, (0.065, frame_depth, height), angle, frame_mat, 0.012)
    add_box("FrameRight", u * width + Vector((0, 0, height * 0.5)) + frame_offset, (0.065, frame_depth, height), angle, frame_mat, 0.012)

    pipe_offset = n * (WALL_THICKNESS * 0.5 + 0.102)
    for index, z in enumerate((0.48, 0.63)):
        p0 = u * 0.28 + Vector((0, 0, z)) + pipe_offset
        p1 = u * 1.72 + Vector((0, 0, z)) + pipe_offset
        add_cylinder_between(f"CopperPipe_{index}", p0, p1, 0.026, copper)
        for x in (0.48, 1.0, 1.52):
            c = u * x + Vector((0, 0, z)) + pipe_offset
            add_cylinder_between(f"PipeCollar_{index}_{x}", c - u * 0.025, c + u * 0.025, 0.038, frame_mat)

    # Functional service plates and conduit clamps add the dense, believable
    # infrastructure language from the approved Steamtek references without
    # changing the module outline or any snap point.
    service_offset = n * (WALL_THICKNESS * 0.5 + 0.105)
    for index, x in enumerate((0.34, 1.66)):
        plate_center = u * x + Vector((0, 0, 0.77)) + service_offset
        add_box(f"ServicePlate_{index}", plate_center, (0.18, 0.045, 0.22), angle, frame_mat, 0.014)
        for dz in (-0.065, 0.065):
            for dx in (-0.052, 0.052):
                bolt = plate_center + u * dx + Vector((0, 0, dz)) + n * 0.03
                add_uv_sphere(f"ServiceBolt_{index}_{dx}_{dz}", bolt, 0.012, fastener)

    light_center = u * 1.0 + Vector((0, 0, 0.95)) + n * (WALL_THICKNESS * 0.5 + 0.11)
    add_box("CyanLightHousing", light_center, (0.74, 0.055, 0.105), angle, frame_mat, 0.018)
    add_box("CyanLight", light_center + n * 0.035, (0.62, 0.028, 0.035), angle, cyan, 0.008)
    badge_center = u * 0.16 + Vector((0, 0, 0.20)) + n * (WALL_THICKNESS * 0.5 + 0.11)
    add_box("MagentaServiceBadge", badge_center, (0.10, 0.04, 0.16), angle, frame_mat, 0.012)
    add_box("MagentaEmitter", badge_center + n * 0.028, (0.03, 0.025, 0.10), angle, magenta, 0.005)

    for x in (0.06, width - 0.06):
        for z in (0.07, height - 0.07):
            center = u * x + Vector((0, 0, z)) + n * (WALL_THICKNESS * 0.5 + 0.093)
            add_uv_sphere(f"Fastener_{x}_{z}", center, 0.017, fastener)

    bpy.ops.object.light_add(type="AREA", location=(4.2, -5.0, 6.0))
    key = bpy.context.object
    key.name = "Key_Cool"
    key.data.energy = 880
    key.data.shape = "DISK"
    key.data.size = 4.0
    key.data.color = (0.64, 0.72, 0.92)
    key.rotation_euler = ((wall_center - key.location).to_track_quat("-Z", "Y").to_euler())

    bpy.ops.object.light_add(type="AREA", location=(-3.0, 2.0, 3.5))
    fill = bpy.context.object
    fill.name = "Fill_Warm"
    fill.data.energy = 720
    fill.data.size = 3.0
    fill.data.color = (1.0, 0.31, 0.10)
    fill.rotation_euler = ((wall_center - fill.location).to_track_quat("-Z", "Y").to_euler())

    bpy.ops.object.light_add(type="AREA", location=(1.0, 1.0, 4.5))
    rim = bpy.context.object
    rim.name = "Rim_Cyan"
    rim.data.energy = 390
    rim.data.size = 2.0
    rim.data.color = (0.0, 0.75, 1.0)
    rim.rotation_euler = ((wall_center - rim.location).to_track_quat("-Z", "Y").to_euler())

    bpy.ops.object.light_add(type="AREA", location=(0.4, -1.6, 1.1))
    low_fill = bpy.context.object
    low_fill.name = "Low_WetBounce"
    low_fill.data.energy = 260
    low_fill.data.size = 1.8
    low_fill.data.color = (0.30, 0.62, 1.0)
    low_fill.rotation_euler = ((wall_center - low_fill.location).to_track_quat("-Z", "Y").to_euler())

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "Camera_Environment_OffAxis60"
    target = wall_center + Vector((0.0, 0.0, 0.02))
    configure_camera(camera, target, RENDER_WIDTH)
    scene.camera = camera
    scene.render.filepath = str(output)
    bpy.context.view_layer.update()

    anchors_world = {
        "left": Vector((0.0, 0.0, 0.0)),
        "right": FRONT_WORLD_STEP.copy(),
        "top_left": Vector((0.0, 0.0, height)),
        "top_right": FRONT_WORLD_STEP + Vector((0.0, 0.0, height)),
    }
    anchors_pixels = {name: project_pixel(scene, camera, point) for name, point in anchors_world.items()}
    front_delta = [anchors_pixels["right"][i] - anchors_pixels["left"][i] for i in range(2)]
    storey_delta = [anchors_pixels["top_left"][i] - anchors_pixels["left"][i] for i in range(2)]

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.render.render(write_still=True)

    metadata = {
        "module_id": MODULE_ID,
        "contract_id": CONTRACT_ID,
        "camera_profile": PROFILE_ID,
        "render_size": [RENDER_WIDTH, RENDER_HEIGHT],
        "transparent": True,
        "construction_world_step_front": [round(v, 6) for v in FRONT_WORLD_STEP],
        "storey_height_blender_units": round(height, 9),
        "anchors_pixels_y_down": {k: [round(v[0], 3), round(v[1], 3)] for k, v in anchors_pixels.items()},
        "measured_front_delta": [round(v, 3) for v in front_delta],
        "measured_storey_delta": [round(v, 3) for v in storey_delta],
        "contract_front_delta": [FRONT_BAY_STEP.x, FRONT_BAY_STEP.y],
        "contract_storey_delta": [STOREY_RISE.x, STOREY_RISE.y],
        "art_direction": {
            "style": "neo-industrial neo-punk",
            "materials": ["dark textured masonry", "gunmetal", "copper"],
            "accents": ["cyan", "magenta"],
            "victorian_ornament": False,
        },
        "godot_scene": godot_path.name,
    }
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    write_godot_scene(godot_path, output.name, anchors_pixels["left"])
    print("STEAMTEK_W101_BUILD_COMPLETE")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
