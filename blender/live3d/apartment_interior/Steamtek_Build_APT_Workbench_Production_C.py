"""Build Steamtek's finished modular apartment workbench.

The model is real 3D geometry. The Blender source is authoritative; the GLB
retains separately named components while the Godot wrapper owns collision,
the floor-center pivot, and live3d_meter_v1 sockets.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
TEXTURE = ROOT / "assets/environment/live3d/textures/apartment_interior/APT_Workbench_HandPaintedSteel_C.png"
GLB = ROOT / "assets/environment/live3d/models/apartment_interior/APT_Workbench_Production_C.glb"
BLEND = ROOT / "blender/live3d/apartment_interior/APT_Workbench_Production_C.blend"
PREVIEW = ROOT / "docs/reviews/APT_Workbench_Production_C_preview.png"


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, color, metallic, roughness, *, texture=None, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if texture:
        image = bpy.data.images.load(str(texture), check_existing=True)
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Linear"
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def finish(obj, bevel=0.018, uv=False):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("PaintedEdge", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if uv:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(65.0), island_margin=0.025)
        bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    return obj


def box(name, center, size, mat, bevel=0.018, uv=False, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    obj.data.materials.append(mat)
    return finish(obj, bevel, uv)


def cylinder(name, center, radius, depth, mat, rotation=(math.pi / 2.0, 0.0, 0.0), vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return finish(obj, radius * 0.12)


def pipe(name, p0, p1, radius, mat, vertices=18):
    a, b = Vector(p0), Vector(p1)
    delta = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    return finish(obj, radius * 0.12)


def sphere(name, center, radius, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=radius, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def bolt(name, x, y, z, mat, radius=0.021):
    return cylinder(name, (x, y, z), radius, 0.035, mat)


def drawer(prefix, x, z, steel, trim, recess):
    y = -0.407
    width, height = 0.43, 0.18
    box(prefix + "_Face", (x, y, z), (width, 0.045, height), steel, 0.012, True)
    for suffix, cx, cz, sx, sz in (
        ("Top", x, z + height * 0.5, width + 0.04, 0.032),
        ("Bottom", x, z - height * 0.5, width + 0.04, 0.032),
        ("Left", x - width * 0.5, z, 0.032, height),
        ("Right", x + width * 0.5, z, 0.032, height),
    ):
        box(prefix + "_Trim" + suffix, (cx, y - 0.03, cz), (sx, 0.035, sz), trim, 0.007)
    box(prefix + "_HandleRecess", (x, y - 0.055, z), (0.24, 0.04, 0.06), recess, 0.014)
    box(prefix + "_Handle", (x, y - 0.083, z), (0.16, 0.035, 0.026), trim, 0.009)
    bolt(prefix + "_BoltL", x - 0.17, y - 0.06, z + 0.055, trim, 0.014)
    bolt(prefix + "_BoltR", x + 0.17, y - 0.06, z + 0.055, trim, 0.014)


def vent(prefix, x, y, z, width, height, steel, trim, recess, slats=6):
    box(prefix + "_Frame", (x, y, z), (width, 0.065, height), trim, 0.016)
    box(prefix + "_Recess", (x, y - 0.04, z), (width - 0.09, 0.05, height - 0.09), recess, 0.01)
    for i in range(slats):
        zz = z - (height - 0.15) * 0.5 + i * (height - 0.15) / max(1, slats - 1)
        box(f"{prefix}_Slat_{i:02d}", (x, y - 0.075, zz), (width - 0.17, 0.028, 0.024), steel, 0.005)


def screen(prefix, x, z, steel, trim, recess, cyan, magenta):
    y = 0.17
    box(prefix + "_OuterFrame", (x, y, z), (0.65, 0.105, 0.46), trim, 0.026)
    box(prefix + "_InnerFrame", (x, y - 0.06, z), (0.56, 0.045, 0.37), recess, 0.018)
    box(prefix + "_Display", (x, y - 0.09, z + 0.025), (0.48, 0.024, 0.275), cyan, 0.026)
    for i in range(4):
        cylinder(f"{prefix}_Button_{i}", (x - 0.18 + i * 0.12, y - 0.112, z - 0.17), 0.022, 0.022, magenta)
    for sx in (-0.285, 0.285):
        for sz in (-0.185, 0.185):
            bolt(f"{prefix}_Bolt_{sx}_{sz}", x + sx, y - 0.12, z + sz, steel, 0.015)


def build_geometry():
    steel = material("STK_HandPainted_BlueBlackSteel", (0.16, 0.22, 0.25), 0.52, 0.60, texture=TEXTURE)
    trim = material("STK_PaintedSelectiveEdge", (0.13, 0.16, 0.17), 0.68, 0.46)
    recess = material("STK_PaintedDeepRecess", (0.018, 0.025, 0.032), 0.32, 0.76)
    copper = material("STK_FunctionalCopper", (0.44, 0.18, 0.065), 0.76, 0.37)
    copper_edge = material("STK_CopperEdge", (0.50, 0.22, 0.07), 0.72, 0.34)
    cyan = material("STK_CyanDisplay", (0.0, 0.14, 0.17), 0.10, 0.25, emission=(0.0, 0.60, 0.72), strength=1.35)
    magenta = material("STK_MagentaStatus", (0.18, 0.005, 0.065), 0.08, 0.25, emission=(0.88, 0.012, 0.28), strength=1.65)

    # Structural silhouette: 7 ft 10 in x 2 ft 8 in x 5 ft 10 in.
    box("WB_LeftCabinet_Carcass", (-0.88, 0.0, 0.39), (0.56, 0.72, 0.72), steel, 0.035, True)
    box("WB_RightCabinet_Carcass", (0.88, 0.0, 0.39), (0.56, 0.72, 0.72), steel, 0.035, True)
    box("WB_WorkSurface", (0.0, 0.0, 0.82), (2.40, 0.82, 0.14), steel, 0.038, True)
    box("WB_WorkSurface_FrontHighlight", (0.0, -0.438, 0.82), (2.44, 0.065, 0.10), trim, 0.018)
    box("WB_KneeWell_Back", (0.0, 0.31, 0.40), (1.14, 0.10, 0.68), steel, 0.025, True)
    box("WB_KneeWell_LowerBrace", (0.0, 0.27, 0.11), (1.20, 0.16, 0.13), trim, 0.025)

    for side, x in (("Left", -0.88), ("Right", 0.88)):
        drawer(f"WB_{side}Drawer_Upper", x, 0.59, steel, trim, recess)
        drawer(f"WB_{side}Drawer_Middle", x, 0.37, steel, trim, recess)
        vent(f"WB_{side}CabinetVent", x, -0.466, 0.16, 0.43, 0.22, steel, trim, recess, 5)
        pipe(f"WB_{side}CabinetPipe", (x + (-0.24 if side == 'Left' else 0.24), -0.475, 0.10), (x + (-0.24 if side == 'Left' else 0.24), -0.475, 0.69), 0.021, copper)

    # Thick modular backboard and readable panel families.
    box("WB_Backboard_Core", (0.0, 0.31, 1.32), (2.34, 0.16, 0.90), steel, 0.035, True)
    box("WB_Backboard_TopRail", (0.0, 0.20, 1.76), (2.40, 0.16, 0.09), trim, 0.02)
    box("WB_Backboard_BottomRail", (0.0, 0.20, 0.89), (2.40, 0.16, 0.09), trim, 0.02)
    box("WB_Backboard_LeftRail", (-1.16, 0.20, 1.325), (0.09, 0.16, 0.84), trim, 0.02)
    box("WB_Backboard_RightRail", (1.16, 0.20, 1.325), (0.09, 0.16, 0.84), trim, 0.02)
    vent("WB_BackboardVent", -0.91, 0.17, 1.43, 0.40, 0.46, steel, trim, recess, 7)
    screen("WB_Screen_Left", -0.33, 1.43, steel, trim, recess, cyan, magenta)
    screen("WB_Screen_Right", 0.43, 1.43, steel, trim, recess, cyan, magenta)

    # Real tool silhouettes and a detachable rack.
    box("WB_ToolRack_Back", (0.94, 0.17, 1.43), (0.37, 0.055, 0.49), recess, 0.015)
    for i in range(4):
        x = 0.82 + i * 0.085
        pipe(f"WB_Tool_{i}_Handle", (x, 0.135, 1.25), (x, 0.135, 1.53), 0.016, trim, 12)
        if i == 0:
            pipe("WB_Tool_0_JawA", (x, 0.135, 1.53), (x - 0.045, 0.135, 1.60), 0.014, trim, 12)
            pipe("WB_Tool_0_JawB", (x, 0.135, 1.53), (x + 0.045, 0.135, 1.60), 0.014, trim, 12)
        else:
            box(f"WB_Tool_{i}_Head", (x, 0.135, 1.58), (0.042, 0.042, 0.085), trim, 0.009, rotation=(0.0, 0.0, math.radians(i * 7.0)))

    # Functional copper service circuit, joints, and clamps.
    pipe("WB_Copper_TopLeft", (-1.02, 0.12, 1.68), (-0.12, 0.12, 1.68), 0.027, copper)
    pipe("WB_Copper_TopRight", (0.12, 0.12, 1.68), (1.02, 0.12, 1.68), 0.027, copper)
    pipe("WB_Copper_LeftDrop", (-1.02, 0.12, 1.08), (-1.02, 0.12, 1.68), 0.027, copper)
    pipe("WB_Copper_RightDrop", (1.02, 0.12, 1.10), (1.02, 0.12, 1.68), 0.027, copper)
    for i, p in enumerate(((-1.02, 0.12, 1.68), (1.02, 0.12, 1.68), (-1.02, 0.12, 1.08), (1.02, 0.12, 1.10))):
        sphere(f"WB_CopperJoint_{i}", p, 0.035, copper_edge)
    for i, x in enumerate((-0.82, -0.52, -0.22, 0.28, 0.58, 0.88)):
        cylinder(f"WB_CopperClamp_{i}", (x, 0.12, 1.68), 0.041, 0.025, trim, rotation=(0.0, math.pi / 2.0, 0.0), vertices=16)

    # Selective painted fastening rhythm, not photorealistic micro-noise.
    for x in (-1.12, -0.58, 0.0, 0.58, 1.12):
        bolt(f"WB_SurfaceBolt_{x}", x, -0.48, 0.85, trim, 0.016)
    for x in (-1.12, 1.12):
        for z in (0.93, 1.72):
            bolt(f"WB_BackboardCorner_{x}_{z}", x, 0.10, z, trim, 0.020)
    for i in range(3):
        cylinder(f"WB_Status_Right_{i}", (1.075, 0.10, 1.47 - i * 0.105), 0.023, 0.024, magenta)


def setup_preview():
    scene = bpy.context.scene
    bpy.ops.object.camera_add(location=(4.2, -5.3, 3.5))
    camera = bpy.context.object
    camera.name = "ReviewCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.3
    camera.rotation_euler = (Vector((0.0, 0.0, 0.9)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    for name, kind, location, energy, size, color in (
        ("ReviewKey", "AREA", (-2.8, -3.5, 4.5), 650.0, 4.0, (0.70, 0.82, 0.92)),
        ("ReviewWarmFill", "AREA", (2.8, -1.5, 2.2), 320.0, 2.0, (1.0, 0.42, 0.18)),
        ("ReviewCyanRim", "AREA", (0.0, 2.2, 2.5), 420.0, 2.5, (0.0, 0.58, 0.72)),
    ):
        bpy.ops.object.light_add(type=kind, location=location)
        lamp = bpy.context.object
        lamp.name = name
        lamp.data.energy = energy
        lamp.data.shape = "DISK"
        lamp.data.size = size
        lamp.data.color = color
        lamp.rotation_euler = (Vector((0.0, 0.0, 0.9)) - lamp.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1100
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(PREVIEW)
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 0.10


def main():
    for path in (GLB, BLEND, PREVIEW):
        path.parent.mkdir(parents=True, exist_ok=True)
    reset_scene()
    build_geometry()
    setup_preview()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND))
    bpy.ops.render.render(write_still=True)
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.name.startswith("Review")]
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.gltf(
        filepath=str(GLB), export_format="GLB", use_selection=True,
        export_apply=True, export_texcoords=True, export_normals=True,
        export_materials="EXPORT",
    )
    print(f"WORKBENCH_BLEND={BLEND}")
    print(f"WORKBENCH_GLB={GLB}")
    print(f"WORKBENCH_PREVIEW={PREVIEW}")
    print(f"WORKBENCH_OBJECTS={len(meshes)}")


if __name__ == "__main__":
    main()
