#!/usr/bin/env python3
"""Build the source-matched Steamtek Bookshelf A as a true 3D GLB candidate.

Run with Blender 4.5+:
    blender --background --python tools/live3d/build_bookshelf_a_true3d.py

The existing projected production asset is intentionally not modified. Outputs are
written to the intake candidate folder for visual approval before integration.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Bookshelf_A" / "true3d_candidate"
TEXTURE_DIR = OUTPUT_DIR / "textures"
PREVIEW_DIR = OUTPUT_DIR / "previews"
BLEND_PATH = OUTPUT_DIR / "STK_PROP_Bookshelf_A_True3D_Candidate.blend"
GLB_PATH = OUTPUT_DIR / "STK_PROP_Bookshelf_A_True3D_Candidate.glb"
REPORT_PATH = OUTPUT_DIR / "STK_PROP_Bookshelf_A_True3D_Report.json"
REFERENCE_SHEET = OUTPUT_DIR / "STK_PROP_Bookshelf_A_ApprovedReferenceSheet.png"

TARGET_WIDTH = 1.20
TARGET_DEPTH = 0.38
TARGET_HEIGHT = 2.00

MESH_OBJECTS: list[bpy.types.Object] = []
MATERIALS: dict[str, bpy.types.Material] = {}


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    for path in (OUTPUT_DIR, TEXTURE_DIR, PREVIEW_DIR):
        path.mkdir(parents=True, exist_ok=True)


def make_worn_texture(name: str, base: tuple[float, float, float], seed: int) -> bpy.types.Image:
    """Create a small seamless-looking hand-painted color texture."""
    rng = random.Random(seed)
    size = 256
    pixels: list[float] = []
    scratches = []
    for _ in range(22):
        scratches.append((rng.randrange(size), rng.randrange(size), rng.randrange(10, 52), rng.choice((-1, 1))))

    for y in range(size):
        for x in range(size):
            broad = 0.018 * math.sin(x * 0.071 + seed) + 0.014 * math.sin(y * 0.047 + seed * 0.3)
            grain = rng.uniform(-0.022, 0.022)
            scratch = 0.0
            for sx, sy, length, direction in scratches:
                dy = abs(y - sy)
                expected_x = sx + direction * (y - sy) * 0.6
                if dy < length and abs(x - expected_x) < 0.75:
                    scratch = 0.055
                    break
            shade = broad + grain + scratch
            pixels.extend((
                max(0.0, min(1.0, base[0] + shade)),
                max(0.0, min(1.0, base[1] + shade)),
                max(0.0, min(1.0, base[2] + shade)),
                1.0,
            ))

    image = bpy.data.images.new(name, width=size, height=size, alpha=True)
    image.pixels.foreach_set(pixels)
    image.file_format = "PNG"
    image.filepath_raw = str(TEXTURE_DIR / f"{name}.png")
    image.save()
    return image


def principled_input(node: bpy.types.Node, *names: str):
    for name in names:
        socket = node.inputs.get(name)
        if socket is not None:
            return socket
    raise KeyError(f"No Principled input found for {names}")


def make_material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float,
    metallic: float = 0.0,
    texture: bpy.types.Image | None = None,
    emission: tuple[float, float, float, float] | None = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    principled_input(bsdf, "Base Color").default_value = color
    principled_input(bsdf, "Metallic").default_value = metallic
    principled_input(bsdf, "Roughness").default_value = roughness
    if texture is not None:
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = f"{name}_BaseColor"
        tex.image = texture
        tex.interpolation = "Linear"
        links.new(tex.outputs["Color"], principled_input(bsdf, "Base Color"))
    if emission is not None:
        principled_input(bsdf, "Emission Color", "Emission").default_value = emission
        principled_input(bsdf, "Emission Strength").default_value = emission_strength
    MATERIALS[name] = mat
    return mat


def setup_materials() -> None:
    frame_tex = make_worn_texture("T_Bookshelf_FramePaint_Worn", (0.030, 0.045, 0.060), 11)
    shelf_tex = make_worn_texture("T_Bookshelf_ShelfPaint_Worn", (0.045, 0.055, 0.064), 23)
    structural_tex = make_worn_texture("T_Bookshelf_Structural_Worn", (0.027, 0.030, 0.033), 37)

    make_material("Frame_PaintedMetal", (0.030, 0.045, 0.060, 1), 0.70, 0.24, frame_tex)
    make_material("Shelf_PaintedMetal", (0.045, 0.055, 0.064, 1), 0.76, 0.16, shelf_tex)
    make_material("Structural_DarkMetal_Locked", (0.027, 0.030, 0.033, 1), 0.64, 0.46, structural_tex)
    make_material("EdgeWear_Locked", (0.045, 0.052, 0.056, 1), 0.78, 0.30)
    make_material("Copper_Hardware_Locked", (0.105, 0.050, 0.026, 1), 0.62, 0.65)
    make_material("Contents_Books_Brown_Locked", (0.050, 0.026, 0.018, 1), 0.88)
    make_material("Contents_Books_Olive_Locked", (0.032, 0.038, 0.023, 1), 0.90)
    make_material("Contents_Books_BlueBlack_Locked", (0.018, 0.030, 0.038, 1), 0.88)
    make_material("Contents_Props_Locked", (0.029, 0.032, 0.034, 1), 0.80, 0.22)
    make_material("Accent_Powered", (0.008, 0.18, 0.20, 1), 0.46, 0.10, emission=(0.02, 0.72, 0.86, 1), emission_strength=4.0)


def apply_bevel(obj: bpy.types.Object, width: float, segments: int, edge_material: bpy.types.Material | None) -> None:
    if width <= 0:
        return
    if edge_material is not None:
        obj.data.materials.append(edge_material)
    bevel = obj.modifiers.new("ProductionBevel", "BEVEL")
    bevel.width = width
    bevel.segments = segments
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(30)
    bevel.harden_normals = True
    if edge_material is not None:
        bevel.material = 1
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.select_set(False)


def add_box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    material: str,
    bevel: float = 0.003,
    segments: int = 2,
    rotation_z: float = 0.0,
    wear_edges: bool = True,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=(0.0, 0.0, rotation_z))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(MATERIALS[material])
    apply_bevel(obj, min(bevel, min(dimensions) * 0.22), segments, MATERIALS["EdgeWear_Locked"] if wear_edges else None)
    MESH_OBJECTS.append(obj)
    return obj


def add_cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    material: str,
    vertices: int = 24,
    bevel: float = 0.002,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(MATERIALS[material])
    apply_bevel(obj, bevel, 2, MATERIALS["EdgeWear_Locked"] if material != "Accent_Powered" else None)
    MESH_OBJECTS.append(obj)
    return obj


def add_book(
    name: str,
    x: float,
    z_bottom: float,
    width: float,
    height: float,
    depth: float,
    material: str,
    lean: float = 0.0,
    banded: bool = False,
) -> None:
    z = z_bottom + height * 0.5
    add_box(name, (x, -0.052, z), (width, depth, height), material, 0.0024, 2, lean)
    if banded:
        for suffix, dz in (("LowerBand", -height * 0.32), ("UpperBand", height * 0.32)):
            add_box(
                f"{name}_{suffix}",
                (x, -0.052 - depth * 0.505, z + dz),
                (width * 0.84, 0.006, 0.009),
                "Copper_Hardware_Locked",
                0.001,
                1,
                lean,
                False,
            )


def add_book_row(name: str, x_start: float, z_bottom: float, specs: list[tuple[float, float, str, float, bool]]) -> None:
    cursor = x_start
    for index, (width, height, material, lean, banded) in enumerate(specs):
        x = cursor + width * 0.5
        add_book(f"{name}_{index:02d}", x, z_bottom, width, height, 0.205, material, lean, banded)
        cursor += width + 0.006


def add_horizontal_stack(name: str, x: float, z_bottom: float, widths: list[float], material_cycle: list[str]) -> None:
    z = z_bottom
    for index, width in enumerate(widths):
        height = 0.030 + 0.004 * (index % 2)
        add_box(
            f"{name}_{index:02d}",
            (x + (index % 2) * 0.008, -0.050, z + height * 0.5),
            (width, 0.205, height),
            material_cycle[index % len(material_cycle)],
            0.002,
            2,
        )
        z += height + 0.005


def build_shell() -> None:
    frame = "Frame_PaintedMetal"
    shelves = "Shelf_PaintedMetal"
    structural = "Structural_DarkMetal_Locked"

    # Exact 1.20 x 0.38 x 2.00 m envelope.
    add_box("Frame_LeftFoot", (-0.55, 0.0, 0.07), (0.10, 0.38, 0.14), frame, 0.010, 3)
    add_box("Frame_RightFoot", (0.55, 0.0, 0.07), (0.10, 0.38, 0.14), frame, 0.010, 3)
    add_box("Frame_BottomRail", (0.0, 0.0, 0.095), (1.00, 0.36, 0.15), frame, 0.008, 3)
    add_box("Frame_LeftPost", (-0.55, 0.0, 1.00), (0.10, 0.36, 1.80), frame, 0.008, 3)
    add_box("Frame_RightPost", (0.55, 0.0, 1.00), (0.10, 0.36, 1.80), frame, 0.008, 3)
    add_box("Frame_LeftTopCap", (-0.55, 0.0, 1.935), (0.10, 0.38, 0.13), frame, 0.010, 3)
    add_box("Frame_RightTopCap", (0.55, 0.0, 1.935), (0.10, 0.38, 0.13), frame, 0.010, 3)
    add_box("Frame_TopRail", (0.0, 0.0, 1.935), (1.00, 0.36, 0.13), frame, 0.008, 3)
    add_box("Frame_TopInsetRail", (0.0, -0.137, 1.820), (0.98, 0.075, 0.055), structural, 0.005, 3)

    # Full closed side and rear panels: no side/back handles or openings.
    add_box("SolidSidePanel_Left", (-0.505, 0.012, 1.00), (0.070, 0.305, 1.68), frame, 0.005, 3)
    add_box("SolidSidePanel_Right", (0.505, 0.012, 1.00), (0.070, 0.305, 1.68), frame, 0.005, 3)
    add_box("FullClosedBackPanel", (0.0, 0.171, 1.00), (1.00, 0.038, 1.72), structural, 0.004, 2)
    add_box("Back_LeftFrame", (-0.505, 0.187, 1.01), (0.055, 0.006, 1.68), frame, 0.001, 1, wear_edges=False)
    add_box("Back_RightFrame", (0.505, 0.187, 1.01), (0.055, 0.006, 1.68), frame, 0.001, 1, wear_edges=False)
    add_box("Back_TopFrame", (0.0, 0.187, 1.825), (0.96, 0.006, 0.055), frame, 0.001, 1, wear_edges=False)
    add_box("Back_BottomInset", (0.0, 0.187, 0.245), (0.92, 0.006, 0.18), frame, 0.001, 1, wear_edges=False)

    # Open upper shelves and a closed lower cabinet.
    for index, z in enumerate((0.675, 0.985, 1.295, 1.605)):
        add_box(f"Shelf_{index + 1}", (0.0, -0.002, z), (0.99, 0.315, 0.045), shelves, 0.004, 3)
        add_box(f"Shelf_{index + 1}_FrontLip", (0.0, -0.173, z), (0.99, 0.034, 0.052), frame, 0.003, 2)

    add_box("Cabinet_Interior", (0.0, 0.004, 0.405), (0.98, 0.30, 0.50), structural, 0.006, 3)
    for side, x in (("Left", -0.247), ("Right", 0.247)):
        add_box(f"CabinetDoor_{side}", (x, -0.176, 0.412), (0.475, 0.028, 0.485), frame, 0.007, 3)
        # Raised rectangular panel borders.
        add_box(f"CabinetDoor_{side}_BorderTop", (x, -0.187, 0.615), (0.395, 0.006, 0.025), structural, 0.001, 1, wear_edges=False)
        add_box(f"CabinetDoor_{side}_BorderBottom", (x, -0.187, 0.209), (0.395, 0.006, 0.025), structural, 0.001, 1, wear_edges=False)
        edge_x = x - 0.185
        add_box(f"CabinetDoor_{side}_BorderOuter", (edge_x, -0.187, 0.412), (0.025, 0.006, 0.38), structural, 0.001, 1, wear_edges=False)
        add_box(f"CabinetDoor_{side}_BorderInner", (x + 0.185, -0.187, 0.412), (0.025, 0.006, 0.38), structural, 0.001, 1, wear_edges=False)

    for side, x in (("Left", -0.070), ("Right", 0.070)):
        add_box(f"CabinetHandle_{side}_Mount", (x, -0.182, 0.425), (0.045, 0.012, 0.205), structural, 0.004, 2)
        add_box(f"CabinetHandle_{side}_Grip", (x, -0.184, 0.425), (0.021, 0.012, 0.145), "Copper_Hardware_Locked", 0.003, 2)

    # Cyan source remains recessed inside the rectangular top footprint.
    add_box("PoweredAccent_TopHousing", (0.0, -0.172, 1.785), (0.77, 0.030, 0.040), structural, 0.004, 3)
    add_box("PoweredAccent_TopEmitter", (0.0, -0.187, 1.785), (0.69, 0.006, 0.016), "Accent_Powered", 0.002, 2, wear_edges=False)
    add_box("PoweredAccent_RightHousing", (0.445, -0.166, 1.563), (0.055, 0.040, 0.245), structural, 0.005, 3)
    add_box("PoweredAccent_RightEmitter", (0.445, -0.187, 1.563), (0.016, 0.006, 0.174), "Accent_Powered", 0.002, 2, wear_edges=False)


def build_contents() -> None:
    brown = "Contents_Books_Brown_Locked"
    olive = "Contents_Books_Olive_Locked"
    blue = "Contents_Books_BlueBlack_Locked"
    props = "Contents_Props_Locked"
    copper = "Copper_Hardware_Locked"
    structural = "Structural_DarkMetal_Locked"

    # Top shelf: upright books, a horizontal stack, and a restrained canister.
    add_book_row("TopShelfBooks", -0.440, 1.633, [
        (0.043, 0.155, brown, 0.00, True), (0.045, 0.168, olive, 0.00, False),
        (0.039, 0.148, blue, 0.00, True), (0.052, 0.174, brown, -0.055, False),
        (0.041, 0.140, olive, -0.095, False), (0.048, 0.166, blue, -0.080, True),
    ])
    add_horizontal_stack("TopShelfStack", -0.005, 1.633, [0.25, 0.22, 0.19], [blue, brown, olive])
    add_cylinder("TopShelfCanister", (0.315, -0.048, 1.708), 0.068, 0.142, props, 28, 0.003)
    add_cylinder("TopShelfCanisterTop", (0.315, -0.048, 1.786), 0.073, 0.014, copper, 28, 0.002)
    add_cylinder("TopShelfCanisterBottom", (0.315, -0.048, 1.630), 0.073, 0.014, "Structural_DarkMetal_Locked", 28, 0.002)

    # Second shelf: dense books plus two industrial containers, one powered.
    add_book_row("SecondShelfBooks", -0.445, 1.323, [
        (0.036, 0.218, blue, 0.00, False), (0.041, 0.229, brown, 0.00, True),
        (0.038, 0.210, olive, 0.00, False), (0.046, 0.224, brown, 0.00, False),
        (0.034, 0.206, blue, 0.00, True), (0.049, 0.222, olive, 0.00, False),
        (0.038, 0.199, brown, 0.00, False), (0.045, 0.216, blue, 0.035, True),
        (0.044, 0.203, olive, 0.070, False), (0.045, 0.190, brown, 0.105, False),
    ])
    add_cylinder("SecondShelfCanister", (0.258, -0.052, 1.425), 0.066, 0.198, props, 28, 0.003)
    add_cylinder("SecondShelfCanisterTop", (0.258, -0.052, 1.531), 0.071, 0.018, copper, 28, 0.002)
    add_cylinder("SecondShelfPoweredVialHousing", (0.385, -0.052, 1.430), 0.060, 0.210, props, 28, 0.003)
    add_cylinder("SecondShelfPoweredVial", (0.385, -0.166, 1.430), 0.018, 0.135, "Accent_Powered", 20, 0.002)
    add_cylinder("SecondShelfPoweredVialTop", (0.385, -0.052, 1.542), 0.064, 0.018, copper, 28, 0.002)

    # Third shelf: framed mechanical print and horizontal reference books.
    add_box("ThirdShelfFramedPrint", (-0.275, -0.075, 1.135), (0.285, 0.125, 0.205), props, 0.007, 3)
    add_box("ThirdShelfFramedPrintInset", (-0.275, -0.141, 1.135), (0.225, 0.008, 0.148), blue, 0.003, 2, wear_edges=False)
    add_box("ThirdShelfFramedPrintAxisH", (-0.275, -0.147, 1.135), (0.120, 0.006, 0.012), copper, 0.001, 1, wear_edges=False)
    add_box("ThirdShelfFramedPrintAxisV", (-0.275, -0.147, 1.135), (0.012, 0.006, 0.100), copper, 0.001, 1, wear_edges=False)
    add_horizontal_stack("ThirdShelfStack", 0.220, 1.013, [0.27, 0.24, 0.21, 0.17], [brown, blue, olive])

    # Bottom open shelf: two book groups around a compact built-in storage chest.
    add_book_row("BottomShelfBooksLeft", -0.445, 0.703, [
        (0.043, 0.225, olive, 0.00, True), (0.039, 0.215, blue, 0.00, False),
        (0.046, 0.230, brown, 0.00, True), (0.038, 0.205, olive, 0.00, False),
        (0.047, 0.218, blue, 0.00, False),
    ])
    add_box("BottomShelfStorageChest", (-0.070, -0.060, 0.795), (0.235, 0.205, 0.175), props, 0.009, 3)
    add_box("BottomShelfChestTop", (-0.070, -0.060, 0.892), (0.250, 0.215, 0.045), structural, 0.007, 3)
    add_box("BottomShelfChestBandLeft", (-0.152, -0.170, 0.795), (0.025, 0.008, 0.160), copper, 0.002, 2, wear_edges=False)
    add_box("BottomShelfChestBandRight", (0.012, -0.170, 0.795), (0.025, 0.008, 0.160), copper, 0.002, 2, wear_edges=False)
    add_box("BottomShelfChestLatch", (-0.070, -0.174, 0.803), (0.055, 0.010, 0.050), copper, 0.003, 2)
    add_book_row("BottomShelfBooksRight", 0.105, 0.703, [
        (0.041, 0.220, blue, 0.00, True), (0.045, 0.228, olive, 0.00, False),
        (0.038, 0.211, brown, 0.00, True), (0.047, 0.232, blue, 0.00, False),
        (0.040, 0.205, olive, 0.00, False), (0.044, 0.218, brown, 0.00, True),
    ])


def join_model() -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in MESH_OBJECTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = MESH_OBJECTS[0]
    bpy.ops.object.join()
    model = bpy.context.object
    model.name = "STK_PROP_Bookshelf_A"
    model.data.name = "STK_PROP_Bookshelf_A_Mesh"
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Triangulate explicitly so the budget reported here matches the GLB.
    triangulate = model.modifiers.new("ExportTriangulation", "TRIANGULATE")
    triangulate.quad_method = "BEAUTY"
    triangulate.ngon_method = "BEAUTY"
    bpy.context.view_layer.objects.active = model
    bpy.ops.object.modifier_apply(modifier=triangulate.name)

    # Set the object origin exactly at bottom center without moving geometry.
    cursor = bpy.context.scene.cursor
    cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR", center="MEDIAN")
    model.location = (0.0, 0.0, 0.0)
    model["asset_name"] = "STK_PROP_Bookshelf_A"
    model["asset_type"] = "Static environment prop"
    model["dimensions_m"] = "1.20 x 0.38 x 2.00"
    model["godot_forward"] = "+Z"
    model["recolor_profile"] = "steamtek_bookshelf_v1"
    model["recolor_regions"] = "Frame_PaintedMetal,Shelf_PaintedMetal,Accent_Powered"
    model["locked_regions"] = "structural metal,copper,books,paper,storage objects,wear,grime,baked shading"
    return model


def bounds_for(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return (
        Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners))),
        Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners))),
    )


def mesh_stats(obj: bpy.types.Object) -> dict:
    mesh = obj.data
    mesh.calc_loop_triangles()
    low, high = bounds_for(obj)
    dimensions = high - low
    return {
        "vertices": len(mesh.vertices),
        "edges": len(mesh.edges),
        "polygons": len(mesh.polygons),
        "triangles": len(mesh.loop_triangles),
        "materials": [slot.material.name for slot in obj.material_slots],
        "bounds_blender_m": {"min": list(low), "max": list(high)},
        "dimensions_m": list(dimensions),
        "pivot_world": list(obj.matrix_world.translation),
        "front_mapping": "Blender -Y exports as Godot +Z",
    }


def export_model(model: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    model.select_set(True)
    bpy.context.view_layer.objects.active = model
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_extras=True,
        export_materials="EXPORT",
        export_yup=True,
    )


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_preview_world() -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("QA_NeutralWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.055, 0.060, 0.067, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.42
    scene.world = world

    floor_mat = make_material("QA_Floor", (0.095, 0.100, 0.108, 1), 0.88)
    add_box("QA_Floor", (0.0, 0.0, -0.035), (4.5, 4.5, 0.06), "QA_Floor", 0.0, 1, wear_edges=False)
    MESH_OBJECTS.pop()  # QA floor must never be considered part of the asset.

    for name, location, energy, size, color in (
        ("QA_Key", (-2.6, -3.2, 3.5), 850.0, 3.0, (0.78, 0.90, 1.0)),
        ("QA_Fill", (2.8, -1.5, 2.3), 620.0, 2.5, (1.0, 0.72, 0.58)),
        ("QA_Rim", (0.0, 2.2, 3.0), 360.0, 2.0, (0.52, 0.70, 0.88)),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        look_at(light, (0.0, 0.0, 1.0))


def render_previews() -> None:
    setup_preview_world()
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "QA_Camera"
    camera.data.type = "ORTHO"
    camera.data.lens = 55
    scene = bpy.context.scene
    scene.camera = camera

    views = {
        "Front": ((0.0, -4.0, 1.02), (0.0, 0.0, 1.02), 2.25, (620, 900)),
        "Back": ((0.0, 4.0, 1.02), (0.0, 0.0, 1.02), 2.25, (620, 900)),
        "Left": ((-3.0, 0.0, 1.02), (0.0, 0.0, 1.02), 2.25, (620, 900)),
        "Right": ((3.0, 0.0, 1.02), (0.0, 0.0, 1.02), 2.25, (620, 900)),
        "Top": ((0.0, 0.0, 4.0), (0.0, 0.0, 0.9), 1.45, (900, 620)),
    }
    for name, (location, target, scale, resolution) in views.items():
        camera.data.type = "ORTHO"
        camera.location = location
        camera.data.ortho_scale = scale
        look_at(camera, target)
        scene.render.resolution_x, scene.render.resolution_y = resolution
        scene.render.filepath = str(PREVIEW_DIR / f"STK_PROP_Bookshelf_A_{name}.png")
        bpy.ops.render.render(write_still=True)

    camera.data.type = "PERSP"
    camera.data.lens = 60
    camera.location = (2.65, -3.25, 2.45)
    look_at(camera, (0.0, 0.0, 1.0))
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.filepath = str(PREVIEW_DIR / "STK_PROP_Bookshelf_A_ThreeQuarter.png")
    bpy.ops.render.render(write_still=True)


def validate_export_glb() -> dict:
    """Re-import the GLB into a clean Blender scene and report exported reality."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(GLB_PATH))
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objects:
        raise RuntimeError("Export validation failed: GLB contains no mesh objects")

    all_corners = [obj.matrix_world @ Vector(corner) for obj in mesh_objects for corner in obj.bound_box]
    low = Vector((min(v.x for v in all_corners), min(v.y for v in all_corners), min(v.z for v in all_corners)))
    high = Vector((max(v.x for v in all_corners), max(v.y for v in all_corners), max(v.z for v in all_corners)))
    triangles = 0
    vertices = 0
    boundary_edges = 0
    nonmanifold_edges = 0
    for obj in mesh_objects:
        mesh = obj.data
        mesh.validate(verbose=False, clean_customdata=False)
        mesh.calc_loop_triangles()
        triangles += len(mesh.loop_triangles)
        vertices += len(mesh.vertices)
        edge_face_count = [0] * len(mesh.edges)
        edge_lookup = {tuple(sorted(edge.vertices)): index for index, edge in enumerate(mesh.edges)}
        for polygon in mesh.polygons:
            verts = polygon.vertices
            for index in range(len(verts)):
                key = tuple(sorted((verts[index], verts[(index + 1) % len(verts)])))
                edge_face_count[edge_lookup[key]] += 1
        boundary_edges += sum(1 for count in edge_face_count if count == 1)
        nonmanifold_edges += sum(1 for count in edge_face_count if count != 2)

    materials = sorted({slot.material.name for obj in mesh_objects for slot in obj.material_slots if slot.material})
    cameras = [obj.name for obj in bpy.context.scene.objects if obj.type == "CAMERA"]
    lights = [obj.name for obj in bpy.context.scene.objects if obj.type == "LIGHT"]
    armatures = [obj.name for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    actions = [action.name for action in bpy.data.actions]
    dimensions = high - low
    tolerance = 0.0001
    dimensions_pass = (
        abs(dimensions.x - TARGET_WIDTH) <= tolerance
        and abs(dimensions.y - TARGET_DEPTH) <= tolerance
        and abs(dimensions.z - TARGET_HEIGHT) <= tolerance
    )
    grounded_pass = abs(low.z) <= tolerance
    triangle_budget_pass = 10000 <= triangles <= 22000
    return {
        "mesh_objects": len(mesh_objects),
        "vertices": vertices,
        "triangles": triangles,
        "bounds_blender_m": {"min": list(low), "max": list(high)},
        "dimensions_m": list(dimensions),
        "materials": materials,
        "boundary_edges": boundary_edges,
        "nonmanifold_edges": nonmanifold_edges,
        "cameras": cameras,
        "lights": lights,
        "armatures": armatures,
        "animations": actions,
        "checks": {
            "dimensions_pass": dimensions_pass,
            "ground_contact_pass": grounded_pass,
            "triangle_budget_pass": triangle_budget_pass,
            "no_camera_light_rig_animation_pass": not (cameras or lights or armatures or actions),
        },
        "overall_pass": dimensions_pass and grounded_pass and triangle_budget_pass and not (cameras or lights or armatures or actions),
    }


def main() -> None:
    reset_scene()
    setup_materials()
    build_shell()
    build_contents()
    model = join_model()
    stats = mesh_stats(model)

    # Save a clean editable source before adding QA cameras, lights, or floor.
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    export_model(model)

    report = {
        "asset": "STK_PROP_Bookshelf_A",
        "status": "true_3d_candidate_pending_visual_approval",
        "output_glb": str(GLB_PATH),
        "output_blend": str(BLEND_PATH),
        "reference_sheet": str(REFERENCE_SHEET),
        "target_dimensions_m": [TARGET_WIDTH, TARGET_DEPTH, TARGET_HEIGHT],
        "topology_target_triangles": {"preferred": [12000, 18000], "acceptable": [10000, 20000], "hard_max": 22000},
        "geometry": stats,
        "rules": {
            "solid_side_panels": True,
            "full_closed_back": True,
            "front_cabinet_doors": 2,
            "side_or_back_handles": 0,
            "cyan_within_rectangular_top_footprint": True,
        },
        "production_replacement_performed": False,
    }
    render_previews()
    report["glb_validation"] = validate_export_glb()
    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
