import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEXTURE_DIR = os.path.join(
    ROOT,
    "assets",
    "environment",
    "live3d",
    "textures",
    "street_kit",
    "STK_ENV_Street_Wall_1p2_A",
)
OUT_DIR = os.path.join(ROOT, "assets", "environment", "live3d", "models", "street_kit")
OUT_GLB = os.path.join(OUT_DIR, "STK_ENV_Street_Wall_2p4_A_Production.glb")
OUT_BLEND = os.path.join(ROOT, "blender", "live3d", "street", "STK_ENV_Street_Wall_2p4_A.blend")
REVIEW_DIR = os.path.join(ROOT, "docs", "reviews", "street_kit")
OUT_NEUTRAL = os.path.join(REVIEW_DIR, "STK_ENV_Street_Wall_2p4_A_Neutral.png")
OUT_DIM = os.path.join(REVIEW_DIR, "STK_ENV_Street_Wall_2p4_A_DimAlley.png")
OUT_ACCENT = os.path.join(REVIEW_DIR, "STK_ENV_Street_Wall_2p4_A_CyanMagenta.png")
OUT_ROW = os.path.join(REVIEW_DIR, "STK_ENV_Street_Wall_2p4_A_TwoModule.png")

WIDTH, HEIGHT, DEPTH = 2.40, 3.20, 0.16
BRICK_BOTTOM, BRICK_TOP = 0.700, 3.000
INNER_HALF_WIDTH = 1.050


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
    albedo.extension = "REPEAT"
    links.new(albedo.outputs["Color"], bsdf.inputs["Base Color"])

    roughness = nodes.new("ShaderNodeTexImage")
    roughness.name = name + "_Roughness"
    roughness.image = load_texture(prefix + "_Roughness.png", "Non-Color")
    roughness.extension = "REPEAT"
    links.new(roughness.outputs["Color"], bsdf.inputs["Roughness"])

    normal_tex = nodes.new("ShaderNodeTexImage")
    normal_tex.name = name + "_Normal"
    normal_tex.image = load_texture(prefix + "_Normal.png", "Non-Color")
    normal_tex.extension = "REPEAT"
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
    if bevel > 0.0:
        modifier = obj.modifiers.new("EdgeWearBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
    return obj


def brick_plane(name, parent, y, face_sign, material):
    x0, x1 = -INNER_HALF_WIDTH, INNER_HALF_WIDTH
    vertices = [
        (x0, y, BRICK_BOTTOM),
        (x1, y, BRICK_BOTTOM),
        (x1, y, BRICK_TOP),
        (x0, y, BRICK_TOP),
    ]
    face = (0, 3, 2, 1) if face_sign < 0 else (0, 1, 2, 3)
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], [face])
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    # The 1.2 m wall uses a 0.936 m visible brick field. Preserve that
    # world-space material scale instead of stretching one texture across 2.1 m.
    u_scale = (INNER_HALF_WIDTH * 2.0) / 0.936
    v_scale = (BRICK_TOP - BRICK_BOTTOM) / 2.355
    uv_values = (
        ((0, 0), (0, v_scale), (u_scale, v_scale), (u_scale, 0))
        if face_sign < 0
        else ((0, 0), (u_scale, 0), (u_scale, v_scale), (0, v_scale))
    )
    for loop, uv in zip(mesh.polygons[0].loop_indices, uv_values):
        uv_layer.data[loop].uv = uv
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(material)
    return obj


def rivet(name, parent, x, y, z, material):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8,
        radius=0.013,
        depth=0.008,
        location=(x, y, z),
        rotation=(math.pi / 2, 0, 0),
    )
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.data.materials.append(material)
    return obj


def maintenance_hatch(name, parent, face_sign, panel_material, vent_material, dark_material, steel_material):
    y_plate = face_sign * 0.069
    y_trim = face_sign * 0.076
    y_detail = face_sign * 0.079
    z = 0.350
    cube(name + "_Door", parent, (0, y_plate, z), (0.480, 0.008, 0.440), panel_material, 0.002)
    border = 0.018
    cube(name + "_Top", parent, (0, y_trim, z + 0.220 - border / 2), (0.480, 0.006, border), vent_material)
    cube(name + "_Bottom", parent, (0, y_trim, z - 0.220 + border / 2), (0.480, 0.006, border), vent_material)
    cube(name + "_Left", parent, (-0.240 + border / 2, y_trim, z), (border, 0.006, 0.440), vent_material)
    cube(name + "_Right", parent, (0.240 - border / 2, y_trim, z), (border, 0.006, 0.440), vent_material)
    cube(name + "_VentRecess", parent, (0, face_sign * 0.073, z + 0.015), (0.300, 0.007, 0.255), dark_material)
    for index in range(8):
        louver_z = z - 0.070 + index * 0.024
        cube(name + f"_Louver_{index:02d}", parent, (0, y_detail, louver_z), (0.250, 0.002, 0.011), vent_material)
    for index, (x, rz) in enumerate(((-0.205, 0.185), (0.205, 0.185), (-0.205, -0.185), (0.205, -0.185))):
        rivet(name + f"_Bolt_{index:02d}", parent, x, face_sign * 0.076, z + rz, steel_material)


def aim_at(obj, target):
    obj.rotation_euler = ((Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler())


bpy.ops.wm.read_factory_settings(use_empty=True)

brick_material = pbr_material("MAT_STK_Wall_Brick_PBR", "STK_Wall_Brick", 0.0, 0.38)
steel_material = pbr_material("MAT_STK_Wall_BlackenedSteel_PBR", "STK_Wall_Steel", 0.72, 0.72)
panel_material = pbr_material("MAT_STK_Wall_MaintenancePanel_PBR", "STK_Wall_Panel", 0.62, 0.62)
vent_material = pbr_material("MAT_STK_Wall_VentSteel_PBR", "STK_Wall_VentSteel", 0.68, 0.68)
dark_material = bpy.data.materials.new("MAT_STK_Wall_VentInterior")
dark_material.use_nodes = True
dark_bsdf = dark_material.node_tree.nodes.get("Principled BSDF")
dark_bsdf.inputs["Base Color"].default_value = (0.012, 0.014, 0.016, 1)
dark_bsdf.inputs["Metallic"].default_value = 0.15
dark_bsdf.inputs["Roughness"].default_value = 0.92

root = empty("STK_ENV_Street_Wall_2p4_A_Visuals")
wall_body = empty("WallBody", root)
brick_surface = empty("BrickSurface", root)
steel_frame = empty("SteelFrame", root)
lower_trim = empty("LowerTrim", root)
maintenance = empty("MaintenanceHatch", root)

# Exact structural shell and mirrored brick faces. Blender -Y exports as Godot +Z.
cube("WallBodyShell", wall_body, (0, 0, HEIGHT / 2), (WIDTH, 0.104, HEIGHT), steel_material)
brick_plane("BrickField_Front_PBR", brick_surface, -0.061, -1, brick_material)
brick_plane("BrickField_Back_PBR", brick_surface, 0.061, 1, brick_material)

# Perimeter silhouette stays strictly inside +/-1.2 m, 0..3.2 m, and +/-0.08 m.
rail_width = 0.150
rail_x = WIDTH / 2.0 - rail_width / 2.0
cube("FrameRail_Left", steel_frame, (-rail_x, 0, HEIGHT / 2), (rail_width, 0.152, HEIGHT), steel_material, 0.003)
cube("FrameRail_Right", steel_frame, (rail_x, 0, HEIGHT / 2), (rail_width, 0.152, HEIGHT), steel_material, 0.003)
cube("Frame_TopCap", steel_frame, (0, 0, 3.160), (WIDTH, DEPTH, 0.080), steel_material, 0.003)
cube("Frame_TopBeam", steel_frame, (0, 0, 3.075), (2.10, 0.152, 0.150), steel_material, 0.003)
# Match the completed 1.2 m module's continuous 0.15 m bottom frame band.
# It spans only the opening between the side rails, keeping the 2.4 m outer
# silhouette, pivot, collision envelope, and modular boundaries unchanged.
cube("Frame_BottomCap", lower_trim, (0, 0, 0.075), (2.10, DEPTH, 0.150), steel_material, 0.003)
cube("Frame_LowerTrim", lower_trim, (0, 0, 0.670), (2.10, 0.152, 0.060), steel_material, 0.002)

# Permanent lower structural plate and its major seams.
cube("LowerStructuralPanel", lower_trim, (0, 0, 0.350), (2.10, 0.132, 0.580), panel_material, 0.002)
cube("LowerPanel_TopSeam", lower_trim, (0, 0, 0.640), (2.11, 0.142, 0.020), steel_material)
cube("LowerPanel_BottomSeam", lower_trim, (0, 0, 0.060), (2.11, 0.142, 0.020), steel_material)
for x in (-0.560, 0.560):
    cube(f"LowerPanel_VerticalSeam_{x:+.3f}", lower_trim, (x, 0, 0.350), (0.018, 0.142, 0.560), steel_material)

# One centered permanent hatch on each face, matching the supplied references.
for sign, face_name in ((-1, "Front"), (1, "Back")):
    maintenance_hatch(
        "MaintenanceHatch_" + face_name,
        maintenance,
        sign,
        panel_material,
        vent_material,
        dark_material,
        steel_material,
    )

    # Important construction fasteners only; micro-rivets remain texture detail.
    for side_name, x in (("L", -rail_x), ("R", rail_x)):
        for index, z in enumerate((0.18, 0.52, 0.90, 1.30, 1.70, 2.10, 2.50, 2.90, 3.08)):
            rivet(f"Rivet_{face_name}_{side_name}_{index:02d}", steel_frame, x, sign * 0.076, z, steel_material)
    for row_name, z in (("Top", 3.075), ("Lower", 0.640), ("Bottom", 0.070)):
        for index, x in enumerate((-0.88, -0.66, -0.33, 0.0, 0.33, 0.66, 0.88)):
            rivet(f"Rivet_{face_name}_{row_name}_{index:02d}", lower_trim if row_name != "Top" else steel_frame, x, sign * 0.076, z, steel_material)

# Bake low-cost bevels, preserve root transform, and calculate production triangles.
for obj in [item for item in bpy.context.scene.objects if item.type == "MESH"]:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.calc_loop_triangles()
    obj.select_set(False)

production_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
triangle_count = sum(len(obj.data.loop_triangles) for obj in production_meshes)
mins = Vector((float("inf"), float("inf"), float("inf")))
maxs = Vector((float("-inf"), float("-inf"), float("-inf")))
for obj in production_meshes:
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        mins.x, mins.y, mins.z = min(mins.x, point.x), min(mins.y, point.y), min(mins.z, point.z)
        maxs.x, maxs.y, maxs.z = max(maxs.x, point.x), max(maxs.y, point.y), max(maxs.z, point.z)

if triangle_count > 6000:
    raise RuntimeError(f"Triangle budget exceeded: {triangle_count}")
if mins.x < -1.20001 or maxs.x > 1.20001 or mins.y < -0.08001 or maxs.y > 0.08001 or mins.z < -0.00001 or maxs.z > 3.20001:
    raise RuntimeError(f"Production bounds exceeded: min={tuple(mins)}, max={tuple(maxs)}")

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
os.makedirs(REVIEW_DIR, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format="GLB",
    export_apply=True,
    export_yup=True,
    export_materials="EXPORT",
)

# Neutral, dim, and cyan/magenta renders validate readability; lights are not exported.
bpy.ops.object.camera_add(location=(0, -6.5, 1.60))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 3.65
camera.rotation_euler = (math.pi / 2, 0, 0)
bpy.context.scene.camera = camera

review_lights = []
for location, energy, size in (((2.4, -3.2, 4.5), 650, 3.4), ((-2.2, -2.4, 1.4), 280, 3.0)):
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.data.energy = energy
    light.data.size = size
    aim_at(light, (0, 0, 1.55))
    review_lights.append(light)

world = bpy.data.worlds.new("STK_Wall_2p4_ReviewWorld")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.36, 0.36, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
bpy.context.scene.world = world
bpy.context.scene.render.engine = "BLENDER_EEVEE_NEXT"
bpy.context.scene.view_settings.look = "AgX - Medium High Contrast"
bpy.context.scene.render.resolution_x = 900
bpy.context.scene.render.resolution_y = 1200
bpy.context.scene.render.resolution_percentage = 100
bpy.context.scene.render.image_settings.file_format = "PNG"
bpy.context.scene.view_settings.exposure = -0.30
bpy.context.scene.render.filepath = OUT_NEUTRAL
bpy.ops.render.render(write_still=True)

review_lights[0].data.energy = 220
review_lights[1].data.energy = 85
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.07, 0.075, 0.085, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.17
bpy.context.scene.view_settings.exposure = -1.0
bpy.context.scene.render.filepath = OUT_DIM
bpy.ops.render.render(write_still=True)

review_lights[0].data.energy = 430
review_lights[0].data.color = (0.05, 0.82, 1.0)
review_lights[1].data.energy = 350
review_lights[1].data.color = (1.0, 0.05, 0.48)
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.025, 0.028, 0.04, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.16
bpy.context.scene.view_settings.exposure = -0.62
bpy.context.scene.render.filepath = OUT_ACCENT
bpy.ops.render.render(write_still=True)

# Two 2.4 m modules at exact spacing prove the outer silhouette and trim rhythm.
for obj in production_meshes:
    duplicate = obj.copy()
    duplicate.data = obj.data
    duplicate.parent = None
    duplicate.matrix_world = obj.matrix_world.copy()
    duplicate.location.x += 2.4
    bpy.context.collection.objects.link(duplicate)
camera.data.ortho_scale = 5.25
camera.location = (1.2, -7.0, 1.60)
camera.rotation_euler = (math.pi / 2, 0, 0)
bpy.context.scene.render.resolution_x = 1600
bpy.context.scene.render.resolution_y = 1000
review_lights[0].data.energy = 650
review_lights[0].data.color = (1.0, 1.0, 1.0)
review_lights[1].data.energy = 280
review_lights[1].data.color = (1.0, 1.0, 1.0)
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.36, 0.36, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
bpy.context.scene.view_settings.exposure = -0.30
bpy.context.scene.render.filepath = OUT_ROW
bpy.ops.render.render(write_still=True)

print(f"WALL_EXPORT={OUT_GLB}")
print(f"WALL_BLEND={OUT_BLEND}")
print(f"WALL_NEUTRAL={OUT_NEUTRAL}")
print(f"WALL_DIM={OUT_DIM}")
print(f"WALL_ACCENT={OUT_ACCENT}")
print(f"WALL_ROW={OUT_ROW}")
print(f"TRIANGLE_COUNT={triangle_count}")
print(f"BOUNDS_MIN={mins.x:.6f},{mins.y:.6f},{mins.z:.6f}")
print(f"BOUNDS_MAX={maxs.x:.6f},{maxs.y:.6f},{maxs.z:.6f}")
