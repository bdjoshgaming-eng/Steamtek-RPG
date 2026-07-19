"""Rebuild the approved Steamtek rust couch against the wall-kit quality bar."""

from __future__ import annotations

import importlib.util
import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
BASE_PATH = Path(__file__).with_name("Steamtek_Build_ApartmentAssetLibrary_D.py")
MODEL_PATH = ROOT / "assets/environment/live3d/models/apartment_interior/library_d/APT_Couch_2Seat_Rust.glb"
BLEND_PATH = ROOT / "blender/live3d/apartment_interior/APT_Couch_2Seat_Rust_F.blend"
REVIEW_PATH = ROOT / "docs/reviews/apartment_library_d/APT_Couch_2Seat_Rust_F.png"
UPHOLSTERY_PATH = ROOT / "assets/environment/live3d/textures/apartment_interior/APT_Upholstery_RustLeather_A.png"
BAKED_UPHOLSTERY_PATH = ROOT / "assets/environment/live3d/textures/apartment_interior/APT_Couch_Oxblood_Painted_F.png"


spec = importlib.util.spec_from_file_location("apartment_library_d", BASE_PATH)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)


def source_upholstery_material():
    """Build the art-directed source shader used only to bake a Godot-safe albedo."""
    material = bpy.data.materials.new("STK_Couch_Oxblood_Source_F")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.88
    bsdf.inputs["Metallic"].default_value = 0.0

    image = bpy.data.images.load(str(UPHOLSTERY_PATH), check_existing=True)
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1])
    low = ramp.color_ramp.elements[0]
    low.position = 0.18
    low.color = (0.010, 0.003, 0.004, 1.0)
    middle = ramp.color_ramp.elements.new(0.52)
    middle.color = (0.105, 0.015, 0.014, 1.0)
    warm = ramp.color_ramp.elements.new(0.79)
    warm.color = (0.335, 0.050, 0.022, 1.0)
    high = ramp.color_ramp.elements.new(0.94)
    high.color = (0.54, 0.135, 0.045, 1.0)
    links.new(texture.outputs["Color"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def bake_upholstery_albedo():
    """Bake custom painted grading so the exact finish survives glTF export."""
    source = source_upholstery_material()
    bpy.ops.mesh.primitive_plane_add(size=2, location=(0, 0, -8))
    plane = bpy.context.object
    plane.name = "CouchF_UpholsteryBakeSurface"
    plane.data.materials.append(source)

    baked = bpy.data.images.new("APT_Couch_Oxblood_Painted_F", width=2048, height=2048, alpha=False)
    baked.colorspace_settings.name = "sRGB"
    target = source.node_tree.nodes.new("ShaderNodeTexImage")
    target.name = "BAKE_TARGET"
    target.image = baked
    source.node_tree.nodes.active = target

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    bpy.context.view_layer.objects.active = plane
    plane.select_set(True)
    bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, margin=16, use_clear=True)

    BAKED_UPHOLSTERY_PATH.parent.mkdir(parents=True, exist_ok=True)
    baked.filepath_raw = str(BAKED_UPHOLSTERY_PATH)
    baked.file_format = "PNG"
    baked.save()
    bpy.data.objects.remove(plane, do_unlink=True)
    return baked


def upholstery_material():
    baked = bake_upholstery_albedo()
    material = bpy.data.materials.new("STK_Couch_OxbloodPainted_F")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.88
    bsdf.inputs["Metallic"].default_value = 0.0
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = baked
    texture.interpolation = "Linear"
    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def simple_material(name, color, metallic=0.0, roughness=0.7, emission=None, strength=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return material


def rivet(name, x, y, z, material):
    return base.cylinder(name, (x, y, z), 0.016, 0.018, material, rotation=(math.pi / 2, 0, 0), vertices=12)


def build_couch():
    base.reset_scene()
    base.ACTIVE.clear()
    base.MATERIALS.clear()
    base.make_materials()

    steel = base.MATERIALS["steel"]
    deep = base.MATERIALS["steel_dark"]
    copper = base.MATERIALS["copper"]
    oxblood = upholstery_material()
    seam = simple_material("STK_Couch_LeatherEdge_F", (0.045, 0.009, 0.008), 0.0, 0.86)
    shadow = simple_material("STK_Couch_LeatherShadow_F", (0.010, 0.002, 0.003), 0.0, 0.96)
    dark_hardware = simple_material("STK_Couch_DarkHardware_F", (0.018, 0.023, 0.026), 0.72, 0.54)
    dark_copper = simple_material("STK_Couch_DarkCopper_F", (0.12, 0.037, 0.015), 0.68, 0.48)

    # Engineered plinth: wall-kit panel language carried into furniture scale.
    base.box("CouchE_BaseShell", (0, 0.02, 0.17), (2.18, 0.96, 0.30), steel, 0.045, True)
    base.box("CouchE_BaseShadow", (0, -0.475, 0.23), (2.02, 0.035, 0.16), deep, 0.012)
    for index, x in enumerate((-0.72, 0.0, 0.72)):
        width = 0.62 if index != 1 else 0.66
        base.box(f"CouchE_FrontPanel_{index}", (x, -0.505, 0.22), (width, 0.055, 0.17), steel, 0.018, True)
        base.box(f"CouchE_FrontInset_{index}", (x, -0.539, 0.22), (width - 0.10, 0.025, 0.10), deep, 0.010)
        for rx in (-width * 0.38, width * 0.38):
            rivet(f"CouchF_PanelRivet_{index}_{rx}", x + rx, -0.565, 0.22, dark_hardware)
    base.box("CouchF_BaseCopperReveal", (0, -0.555, 0.315), (1.88, 0.014, 0.014), dark_copper, 0.004)
    base.box("CouchF_MaintenancePlate", (0.82, -0.56, 0.18), (0.25, 0.028, 0.09), deep, 0.014)

    # Two independently readable seats with dark separation and controlled seams.
    for side, x in (("L", -0.47), ("R", 0.47)):
        base.box(f"CouchE_SeatShadow_{side}", (x, -0.075, 0.43), (0.91, 0.73, 0.17), shadow, 0.055)
        base.box(f"CouchE_Seat_{side}", (x, -0.09, 0.51), (0.88, 0.70, 0.25), oxblood, 0.075, True)
        base.box(f"CouchF_SeatFrontSeam_{side}", (x, -0.456, 0.535), (0.76, 0.012, 0.014), seam, 0.005)
        base.box(f"CouchE_BackShadow_{side}", (x, 0.34, 0.72), (0.91, 0.20, 0.52), shadow, 0.055, rotation=(math.radians(-6), 0, 0))
        base.box(f"CouchE_Back_{side}", (x, 0.31, 0.78), (0.88, 0.20, 0.53), oxblood, 0.075, True, rotation=(math.radians(-6), 0, 0))
        base.box(f"CouchF_BackTopSeam_{side}", (x, 0.236, 1.025), (0.76, 0.012, 0.012), seam, 0.004, rotation=(math.radians(-6), 0, 0))

    # Structural arms, padded hand rests, copper service rails, and side maintenance panels.
    for side, x in (("L", -1.01), ("R", 1.01)):
        base.box(f"CouchE_ArmShell_{side}", (x, 0.0, 0.58), (0.20, 0.94, 0.78), steel, 0.045, True)
        base.box(f"CouchE_ArmInset_{side}", (x + (-0.111 if x < 0 else 0.111), 0.06, 0.56), (0.025, 0.62, 0.42), deep, 0.012)
        base.box(f"CouchE_ArmPad_{side}", (x, -0.02, 0.94), (0.16, 0.82, 0.16), oxblood, 0.055, True)
        rail_x = x + (0.112 if x < 0 else -0.112)
        base.pipe(f"CouchF_CopperRail_{side}", (rail_x, -0.34, 0.40), (rail_x, -0.34, 0.84), 0.011, dark_copper, 12)
        base.box(f"CouchF_SideCapFront_{side}", (x, -0.43, 0.86), (0.22, 0.12, 0.18), dark_hardware, 0.025)
        outside_x = x + (-0.112 if x < 0 else 0.112)
        for slot_index, z in enumerate((0.48, 0.54, 0.60)):
            base.box(f"CouchF_SideVent_{side}_{slot_index}", (outside_x, 0.22, z), (0.014, 0.18, 0.025), deep, 0.004)
        base.box(f"CouchE_Foot_{side}", (x, -0.30, 0.055), (0.18, 0.18, 0.11), deep, 0.018)

    # Back support keeps the silhouette solid when viewed from the room edges.
    base.box("CouchE_BackFrame", (0, 0.44, 0.70), (1.86, 0.16, 0.68), steel, 0.035, True)
    base.box("CouchE_BackRecess", (0, 0.535, 0.70), (1.64, 0.035, 0.44), deep, 0.015)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in base.ACTIVE:
        obj.select_set(True)
        obj["steamtek_asset_id"] = "APT_Couch_2Seat_Rust"
        obj["quality_benchmark"] = "approved_apartment_walls"
        obj["world_mix"] = "40_cyberpunk_20_neoindustrial_20_practical_steampunk_20_arcane_color_treatment"
        obj["accent_rule"] = "cyan_only_for_actual_light_sources"
    bpy.context.view_layer.objects.active = base.ACTIVE[0]
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(MODEL_PATH), export_format="GLB", use_selection=True,
        export_apply=True, export_texcoords=True, export_normals=True,
        export_materials="EXPORT",
    )


def render_review():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1200
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.002, 0.003, 0.005)
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 0.20

    floor_mat = simple_material("ReviewFloor", (0.008, 0.011, 0.014), 0.05, 0.88)
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, -0.012))
    floor = bpy.context.object
    floor.name = "ReviewFloor"
    floor.data.materials.append(floor_mat)

    bpy.ops.object.camera_add(location=(4.2, -6.3, 3.8))
    camera = bpy.context.object
    camera.name = "CouchReviewCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.3
    target = Vector((0, 0, 0.52))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    for name, location, energy, size, color in (
        ("WallKitKey", (-3.5, -4.5, 6.0), 820, 5.0, (0.68, 0.74, 0.82)),
        ("ArcaneWarm", (4.0, -2.0, 3.5), 560, 4.0, (1.0, 0.28, 0.09)),
        ("CoolAmbient", (2.5, 4.0, 4.0), 280, 3.0, (0.10, 0.19, 0.24)),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()

    REVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(REVIEW_PATH)
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))


if __name__ == "__main__":
    build_couch()
    render_review()
    print(f"COUCH_MODEL={MODEL_PATH}")
    print(f"COUCH_BLEND={BLEND_PATH}")
    print(f"COUCH_REVIEW={REVIEW_PATH}")
