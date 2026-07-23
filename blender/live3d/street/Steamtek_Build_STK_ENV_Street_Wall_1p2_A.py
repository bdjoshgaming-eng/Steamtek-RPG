import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEXTURE_DIR = os.path.join(ROOT, "assets", "environment", "live3d", "textures", "street_kit", "STK_ENV_Street_Wall_1p2_A")
OUT_DIR = os.path.join(ROOT, "assets", "environment", "live3d", "models", "street_kit")
OUT_GLB = os.path.join(OUT_DIR, "STK_ENV_Street_Wall_1p2_A_Production_v15.glb")
OUT_BLEND = os.path.join(ROOT, "blender", "live3d", "street", "STK_ENV_Street_Wall_1p2_A.blend")
OUT_REVIEW = os.path.join(ROOT, "docs", "reviews", "street_kit", "STK_ENV_Street_Wall_1p2_A_Production_v15_Neutral.png")
OUT_DIM_REVIEW = os.path.join(ROOT, "docs", "reviews", "street_kit", "STK_ENV_Street_Wall_1p2_A_Production_v15_DimAlley.png")
OUT_ACCENT_REVIEW = os.path.join(ROOT, "docs", "reviews", "street_kit", "STK_ENV_Street_Wall_1p2_A_Production_v15_CyanMagenta.png")
OUT_THREE_WALL_REVIEW = os.path.join(ROOT, "docs", "reviews", "street_kit", "STK_ENV_Street_Wall_1p2_A_ThreeModule_v15.png")

WIDTH, HEIGHT, DEPTH = 1.20, 3.20, 0.16


def load_texture(filename, colorspace="sRGB"):
    image = bpy.data.images.load(os.path.join(TEXTURE_DIR, filename), check_existing=True)
    image.colorspace_settings.name = colorspace
    return image


def pbr_material(name, prefix, metallic, normal_strength=1.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Metallic"].default_value = metallic

    albedo = nodes.new("ShaderNodeTexImage")
    albedo.name = name + "_Albedo"
    albedo.image = load_texture(prefix + "_Albedo.png")
    links.new(albedo.outputs["Color"], bsdf.inputs["Base Color"])

    roughness = nodes.new("ShaderNodeTexImage")
    roughness.name = name + "_Roughness"
    roughness.image = load_texture(prefix + "_Roughness.png", "Non-Color")
    links.new(roughness.outputs["Color"], bsdf.inputs["Roughness"])

    normal_tex = nodes.new("ShaderNodeTexImage")
    normal_tex.name = name + "_Normal"
    normal_tex.image = load_texture(prefix + "_Normal.png", "Non-Color")
    normal = nodes.new("ShaderNodeNormalMap")
    normal.inputs["Strength"].default_value = normal_strength
    links.new(normal_tex.outputs["Color"], normal.inputs["Color"])
    links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])

    material["ao_texture"] = os.path.join(TEXTURE_DIR, prefix + "_AO.png")
    return material


def empty(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def cube(name, parent, location, dimensions, material, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if bevel > 0:
        modifier = obj.modifiers.new("EdgeWearBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
    return obj


def brick_plane(name, parent, y, z_bottom, z_top, face_sign, material):
    half_width = 0.468
    vertices = [
        (-half_width, y, z_bottom),
        (half_width, y, z_bottom),
        (half_width, y, z_top),
        (-half_width, y, z_top),
    ]
    face = (0, 3, 2, 1) if face_sign < 0 else (0, 1, 2, 3)
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], [face])
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    uv_values = ((0, 0), (0, 1), (1, 1), (1, 0)) if face_sign < 0 else ((0, 0), (1, 0), (1, 1), (0, 1))
    for loop, uv in zip(mesh.polygons[0].loop_indices, uv_values):
        uv_layer.data[loop].uv = uv
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(material)
    return obj


def rivet(name, parent, x, y, z, face_sign):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.013, depth=0.008, location=(x, y, z), rotation=(math.pi / 2, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.data.materials.append(steel_material)
    # Cylinder remains fully inside the authoritative +/-0.08 m depth.
    return obj


def vent(name, parent, x, z, face_sign):
    y_back = face_sign * 0.069
    y_front = face_sign * 0.077
    cube(name + "_Recess", parent, (x, y_back, z), (0.205, 0.008, 0.185), dark_material)
    border = 0.016
    cube(name + "_Top", parent, (x, y_front, z + 0.0925 - border / 2), (0.205, 0.006, border), vent_material)
    cube(name + "_Bottom", parent, (x, y_front, z - 0.0925 + border / 2), (0.205, 0.006, border), vent_material)
    cube(name + "_Left", parent, (x - 0.1025 + border / 2, y_front, z), (border, 0.006, 0.185), vent_material)
    cube(name + "_Right", parent, (x + 0.1025 - border / 2, y_front, z), (border, 0.006, 0.185), vent_material)
    for index in range(6):
        louver_z = z - 0.058 + index * 0.023
        cube(name + f"_Louver_{index:02d}", parent, (x, face_sign * 0.079, louver_z), (0.150, 0.002, 0.010), vent_material)


bpy.ops.wm.read_factory_settings(use_empty=True)

brick_material = pbr_material("MAT_STK_Wall_Brick_PBR", "STK_Wall_Brick", metallic=0.0, normal_strength=0.38)
steel_material = pbr_material("MAT_STK_Wall_BlackenedSteel_PBR", "STK_Wall_Steel", metallic=0.72, normal_strength=0.72)
panel_material = pbr_material("MAT_STK_Wall_MaintenancePanel_PBR", "STK_Wall_Panel", metallic=0.62, normal_strength=0.62)
vent_material = pbr_material("MAT_STK_Wall_VentSteel_PBR", "STK_Wall_VentSteel", metallic=0.68, normal_strength=0.68)
dark_material = bpy.data.materials.new("MAT_STK_Wall_VentInterior")
dark_material.diffuse_color = (0.012, 0.014, 0.016, 1)
dark_material.use_nodes = True
dark_bsdf = dark_material.node_tree.nodes.get("Principled BSDF")
dark_bsdf.inputs["Base Color"].default_value = (0.012, 0.014, 0.016, 1)
dark_bsdf.inputs["Metallic"].default_value = 0.15
dark_bsdf.inputs["Roughness"].default_value = 0.92

root = empty("STK_ENV_Street_Wall_1p2_A_Visuals")
wall_body = empty("WallBody", root)
brick_surface = empty("BrickSurface", root)
steel_frame = empty("SteelFrame", root)
maintenance = empty("LowerMaintenancePanel", root)
vents = empty("VentGrilles", root)

# Exact rectangular structural shell. The visible front is Blender -Y, which
# maps to Godot +Z through glTF export. The opposite face is physically identical.
cube("WallBodyShell", wall_body, (0, 0, HEIGHT / 2), (WIDTH, 0.104, HEIGHT), steel_material)

brick_bottom = 0.690
brick_top = 3.045
brick_plane("BrickField_Front_PBR", brick_surface, -0.061, brick_bottom, brick_top, -1, brick_material)
brick_plane("BrickField_Back_PBR", brick_surface, 0.061, brick_bottom, brick_top, 1, brick_material)

# Structural frame pieces define the exact silhouette and remain inside bounds.
rail_width = 0.120
frame_depth = 0.152
cube("FrameRail_Left", steel_frame, (-0.540, 0, HEIGHT / 2), (rail_width, frame_depth, HEIGHT), steel_material, 0.003)
cube("FrameRail_Right", steel_frame, (0.540, 0, HEIGHT / 2), (rail_width, frame_depth, HEIGHT), steel_material, 0.003)
cube("Frame_Top", steel_frame, (0, 0, 3.125), (0.960, frame_depth, 0.150), steel_material, 0.003)
cube("Frame_Bottom", steel_frame, (0, 0, 0.075), (0.960, frame_depth, 0.150), steel_material, 0.003)
cube("Frame_LowerTrim", steel_frame, (0, 0, 0.655), (0.960, frame_depth, 0.058), steel_material, 0.002)

# Major corner reinforcement plates, modeled on both faces via full-depth boxes.
for side, x in (("Left", -0.540), ("Right", 0.540)):
    cube(f"CornerPlate_{side}_Top", steel_frame, (x, 0, 3.130), (0.098, 0.156, 0.125), steel_material, 0.002)
    cube(f"CornerPlate_{side}_Bottom", steel_frame, (x, 0, 0.070), (0.098, 0.156, 0.125), steel_material, 0.002)

# Recessed lower service plate, trim seams, and identical front/back vent sets.
cube("MaintenancePanel", maintenance, (0, 0, 0.385), (0.912, 0.132, 0.410), panel_material, 0.002)
cube("MaintenancePanel_TopSeam", maintenance, (0, 0, 0.590), (0.920, 0.142, 0.022), steel_material)
cube("MaintenancePanel_BottomSeam", maintenance, (0, 0, 0.180), (0.920, 0.142, 0.022), steel_material)

for sign, face_name in ((-1, "Front"), (1, "Back")):
    vent(f"Vent_{face_name}_Left", vents, -0.250, 0.385, sign)
    vent(f"Vent_{face_name}_Right", vents, 0.250, 0.385, sign)

    # Low-sided modeled rivets supply silhouette and construction cues while
    # surface micro-wear remains texture-driven.
    for side, x in (("L", -0.540), ("R", 0.540)):
        for index, z in enumerate((0.19, 0.52, 0.92, 1.32, 1.72, 2.12, 2.52, 2.92)):
            rivet(f"Rivet_{face_name}_{side}_{index:02d}", steel_frame, x, sign * 0.076, z, sign)
    for row_name, z in (("Top", 3.125), ("Bottom", 0.075)):
        for index, x in enumerate((-0.36, -0.18, 0.0, 0.18, 0.36)):
            rivet(f"Rivet_{face_name}_{row_name}_{index:02d}", steel_frame, x, sign * 0.076, z, sign)

# Apply bevels and transforms before production export.
for obj in [item for item in bpy.context.scene.objects if item.type == "MESH"]:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.select_set(False)

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format="GLB",
    export_apply=True,
    export_yup=True,
    export_materials="EXPORT",
)

# Lighting-validation renders. Camera/lights are added only after export and
# therefore cannot affect production geometry, hierarchy, transforms, or GLB data.
bpy.ops.object.camera_add(location=(0, -6.0, 1.60))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 3.55
camera.rotation_euler = (math.pi / 2, 0, 0)
bpy.context.scene.camera = camera

review_lights = []
for location, energy, size, color in (
    ((1.8, -3.0, 4.3), 520, 3.2, (1.0, 1.0, 1.0)),
    ((-1.7, -2.2, 1.4), 230, 2.8, (1.0, 1.0, 1.0)),
):
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.data.energy = energy
    light.data.size = size
    light.data.color = color
    light.rotation_euler = ((Vector((0, 0, 1.55)) - light.location).to_track_quat("-Z", "Y").to_euler())
    review_lights.append(light)

world = bpy.data.worlds.new("WallProductionReviewWorld")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.36, 0.36, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
bpy.context.scene.world = world
bpy.context.scene.render.engine = "BLENDER_EEVEE_NEXT"
bpy.context.scene.view_settings.look = "AgX - Medium High Contrast"
bpy.context.scene.view_settings.exposure = -0.35
bpy.context.scene.render.resolution_x = 720
bpy.context.scene.render.resolution_y = 1440
bpy.context.scene.render.resolution_percentage = 100
bpy.context.scene.render.image_settings.file_format = "PNG"
bpy.context.scene.render.filepath = OUT_REVIEW
os.makedirs(os.path.dirname(OUT_REVIEW), exist_ok=True)
bpy.ops.render.render(write_still=True)

# Dim neutral alley test: intentionally low exposure with soft white sources.
review_lights[0].data.energy = 190
review_lights[1].data.energy = 70
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.08, 0.085, 0.09, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.18
bpy.context.scene.view_settings.exposure = -1.05
bpy.context.scene.render.filepath = OUT_DIM_REVIEW
bpy.ops.render.render(write_still=True)

# Cyberpunk accent test: colored lights validate form readability without adding
# emissive material or permanent colored lighting to the production asset.
review_lights[0].data.energy = 360
review_lights[0].data.color = (0.05, 0.82, 1.0)
review_lights[1].data.energy = 300
review_lights[1].data.color = (1.0, 0.05, 0.48)
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.025, 0.028, 0.04, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.16
bpy.context.scene.view_settings.exposure = -0.65
bpy.context.scene.render.filepath = OUT_ACCENT_REVIEW
bpy.ops.render.render(write_still=True)

# Three-module seam/rhythm QA. Instances share the same mesh/material data and
# are centered exactly 1.2 m apart.
production_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
for offset in (-1.2, 1.2):
    for obj in production_meshes:
        duplicate = obj.copy()
        duplicate.data = obj.data
        duplicate.parent = None
        duplicate.matrix_world = obj.matrix_world.copy()
        duplicate.location.x += offset
        bpy.context.collection.objects.link(duplicate)
camera.data.ortho_scale = 4.15
camera.location = (0, -6.0, 1.60)
camera.rotation_euler = (math.pi / 2, 0, 0)
bpy.context.scene.render.resolution_x = 1600
bpy.context.scene.render.resolution_y = 900
# Restore neutral lighting for the modular seam/rhythm validation.
review_lights[0].data.energy = 520
review_lights[0].data.color = (1.0, 1.0, 1.0)
review_lights[1].data.energy = 230
review_lights[1].data.color = (1.0, 1.0, 1.0)
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.36, 0.36, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
bpy.context.scene.view_settings.exposure = -0.35
bpy.context.scene.render.filepath = OUT_THREE_WALL_REVIEW
bpy.ops.render.render(write_still=True)

print(f"WALL_EXPORT={OUT_GLB}")
print(f"WALL_BLEND={OUT_BLEND}")
print(f"WALL_REVIEW={OUT_REVIEW}")
print(f"WALL_DIM_REVIEW={OUT_DIM_REVIEW}")
print(f"WALL_ACCENT_REVIEW={OUT_ACCENT_REVIEW}")
print(f"WALL_THREE_MODULE_REVIEW={OUT_THREE_WALL_REVIEW}")
