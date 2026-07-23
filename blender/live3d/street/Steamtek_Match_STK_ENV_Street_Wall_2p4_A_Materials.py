import bpy
import hashlib
import math
import os
import struct
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BLEND_PATH = os.path.join(ROOT, "blender", "live3d", "street", "STK_ENV_Street_Wall_2p4_A.blend")
OUT_GLB = os.path.join(ROOT, "assets", "environment", "live3d", "models", "street_kit", "STK_ENV_Street_Wall_2p4_A_Production.glb")
WALL_1P2_GLB = os.path.join(ROOT, "assets", "environment", "live3d", "models", "street_kit", "STK_ENV_Street_Wall_1p2_A_Production_v15.glb")
REVIEW_DIR = os.path.join(ROOT, "docs", "reviews", "street_kit")
OUT_NEUTRAL = os.path.join(REVIEW_DIR, "STK_ENV_Street_Walls_1p2_2p4_MaterialMatch_Neutral.png")
OUT_DIM = os.path.join(REVIEW_DIR, "STK_ENV_Street_Walls_1p2_2p4_MaterialMatch_DimAlley.png")
OUT_ACCENT = os.path.join(REVIEW_DIR, "STK_ENV_Street_Walls_1p2_2p4_MaterialMatch_CyanMagenta.png")


def production_meshes():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def geometry_digest(meshes):
    digest = hashlib.sha256()
    for obj in sorted(meshes, key=lambda item: item.name):
        digest.update(obj.name.encode("utf-8"))
        digest.update(struct.pack("<16f", *[value for row in obj.matrix_world for value in row]))
        for vertex in obj.data.vertices:
            digest.update(struct.pack("<3f", vertex.co.x, vertex.co.y, vertex.co.z))
        for polygon in obj.data.polygons:
            digest.update(struct.pack("<I", len(polygon.vertices)))
            for index in polygon.vertices:
                digest.update(struct.pack("<I", index))
    return digest.hexdigest()


def triangle_count(meshes):
    count = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        count += len(obj.data.loop_triangles)
    return count


def insert_midtone_match(material_name, value):
    material = bpy.data.materials.get(material_name)
    if material is None or not material.use_nodes:
        raise RuntimeError(f"Missing production material: {material_name}")
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    base_input = bsdf.inputs["Base Color"]
    node = nodes.get("STK_2p4_MidtoneMatch")
    if node is None:
        if not base_input.is_linked:
            raise RuntimeError(f"{material_name} has no linked albedo texture")
        source_socket = base_input.links[0].from_socket
        node = nodes.new("ShaderNodeHueSaturation")
        node.name = "STK_2p4_MidtoneMatch"
        node.label = "2.4m Match to STK_ENV_Street_Wall_1p2_A"
        node.location = (source_socket.node.location.x + 210, source_socket.node.location.y)
        links.remove(base_input.links[0])
        links.new(source_socket, node.inputs["Color"])
        links.new(node.outputs["Color"], base_input)
    node.inputs["Hue"].default_value = 0.5
    node.inputs["Saturation"].default_value = 1.0
    node.inputs["Value"].default_value = value
    node.inputs["Fac"].default_value = 1.0


def aim_at(obj, target):
    obj.rotation_euler = ((Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler())


bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)
meshes_before = production_meshes()
digest_before = geometry_digest(meshes_before)
triangles_before = triangle_count(meshes_before)

# Compensate for the wider asset reading darker while leaving PBR roughness,
# metallic values, textures, texture scale, UVs, and geometry untouched.
insert_midtone_match("MAT_STK_Wall_Brick_PBR", 1.08)
insert_midtone_match("MAT_STK_Wall_BlackenedSteel_PBR", 1.10)
insert_midtone_match("MAT_STK_Wall_MaintenancePanel_PBR", 1.14)
insert_midtone_match("MAT_STK_Wall_VentSteel_PBR", 1.12)
dark_material = bpy.data.materials.get("MAT_STK_Wall_VentInterior")
dark_bsdf = dark_material.node_tree.nodes.get("Principled BSDF")
dark_bsdf.inputs["Base Color"].default_value = (0.017, 0.019, 0.022, 1)

meshes_after = production_meshes()
digest_after = geometry_digest(meshes_after)
triangles_after = triangle_count(meshes_after)
if digest_before != digest_after or triangles_before != triangles_after:
    raise RuntimeError("Material pass changed production geometry or topology")

bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format="GLB",
    export_apply=True,
    export_yup=True,
    export_materials="EXPORT",
)

# Shared-light side-by-side validation. Move the 2.4 m root to the right, then
# import the unchanged 1.2 m production GLB on the left with an exact X seam.
top_level_2p4 = [obj for obj in bpy.context.scene.objects if obj.parent is None]
for obj in top_level_2p4:
    obj.location.x += 0.6

existing_names = set(bpy.context.scene.objects.keys())
bpy.ops.import_scene.gltf(filepath=WALL_1P2_GLB)
imported = [obj for obj in bpy.context.scene.objects if obj.name not in existing_names]
imported_set = set(imported)
imported_roots = [obj for obj in imported if obj.parent not in imported_set]
for obj in imported_roots:
    obj.location.x -= 1.2

bpy.ops.object.camera_add(location=(0, -6.6, 1.60))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 3.65
camera.rotation_euler = (math.pi / 2, 0, 0)
bpy.context.scene.camera = camera

lights = []
for location, energy, size in (((2.4, -3.2, 4.5), 650, 3.4), ((-2.2, -2.4, 1.4), 280, 3.0)):
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.data.energy = energy
    light.data.size = size
    aim_at(light, (0, 0, 1.55))
    lights.append(light)

world = bpy.data.worlds.new("STK_Wall_MaterialMatch_ReviewWorld")
world.use_nodes = True
bpy.context.scene.world = world
bpy.context.scene.render.engine = "BLENDER_EEVEE_NEXT"
bpy.context.scene.view_settings.look = "AgX - Medium High Contrast"
bpy.context.scene.render.resolution_x = 1200
bpy.context.scene.render.resolution_y = 1000
bpy.context.scene.render.resolution_percentage = 100
bpy.context.scene.render.image_settings.file_format = "PNG"

world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.36, 0.36, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
bpy.context.scene.view_settings.exposure = -0.30
bpy.context.scene.render.filepath = OUT_NEUTRAL
bpy.ops.render.render(write_still=True)

lights[0].data.energy = 220
lights[1].data.energy = 85
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.07, 0.075, 0.085, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.17
bpy.context.scene.view_settings.exposure = -1.0
bpy.context.scene.render.filepath = OUT_DIM
bpy.ops.render.render(write_still=True)

lights[0].data.energy = 430
lights[0].data.color = (0.05, 0.82, 1.0)
lights[1].data.energy = 350
lights[1].data.color = (1.0, 0.05, 0.48)
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.025, 0.028, 0.04, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.16
bpy.context.scene.view_settings.exposure = -0.62
bpy.context.scene.render.filepath = OUT_ACCENT
bpy.ops.render.render(write_still=True)

print(f"GEOMETRY_DIGEST_BEFORE={digest_before}")
print(f"GEOMETRY_DIGEST_AFTER={digest_after}")
print(f"TRIANGLES_BEFORE={triangles_before}")
print(f"TRIANGLES_AFTER={triangles_after}")
print(f"MATERIAL_MATCH_NEUTRAL={OUT_NEUTRAL}")
print(f"MATERIAL_MATCH_DIM={OUT_DIM}")
print(f"MATERIAL_MATCH_ACCENT={OUT_ACCENT}")
