import bpy
import hashlib
import os
import struct
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BLEND_PATH = os.path.join(ROOT, "blender", "live3d", "street", "STK_ENV_Street_Wall_2p4_A.blend")
OUT_GLB = os.path.join(
    ROOT,
    "assets",
    "environment",
    "live3d",
    "models",
    "street_kit",
    "STK_ENV_Street_Wall_2p4_A_Production.glb",
)


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
        for uv_layer in obj.data.uv_layers:
            digest.update(uv_layer.name.encode("utf-8"))
            for loop in uv_layer.data:
                digest.update(struct.pack("<2f", loop.uv.x, loop.uv.y))
    return digest.hexdigest()


def triangle_count(meshes):
    count = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        count += len(obj.data.loop_triangles)
    return count


def world_bounds(meshes):
    mins = Vector((float("inf"), float("inf"), float("inf")))
    maxs = Vector((float("-inf"), float("-inf"), float("-inf")))
    for obj in meshes:
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            mins.x = min(mins.x, point.x)
            mins.y = min(mins.y, point.y)
            mins.z = min(mins.z, point.z)
            maxs.x = max(maxs.x, point.x)
            maxs.y = max(maxs.y, point.y)
            maxs.z = max(maxs.z, point.z)
    return mins, maxs


bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)
meshes_before = production_meshes()
digest_before = geometry_digest(meshes_before)
triangles_before = triangle_count(meshes_before)

bottom_frame = bpy.data.objects.get("Frame_BottomCap")
if bottom_frame is None or bottom_frame.type != "MESH":
    raise RuntimeError("Frame_BottomCap was not found in the production blend")

old_dimensions = tuple(bottom_frame.dimensions)
old_location = tuple(bottom_frame.location)

# Reuse the existing member rather than adding or replacing geometry. The band
# now matches the 1.2 m wall's 0.15 m height and stops at the inner rail edges.
bottom_frame.location.z = 0.075
bottom_frame.dimensions = (2.10, 0.16, 0.15)
bpy.context.view_layer.objects.active = bottom_frame
bottom_frame.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bottom_frame.select_set(False)

meshes_after = production_meshes()
digest_after = geometry_digest(meshes_after)
triangles_after = triangle_count(meshes_after)
mins, maxs = world_bounds(meshes_after)

if triangles_before != triangles_after:
    raise RuntimeError("Bottom-frame correction changed the production triangle count")
if (
    mins.x < -1.20001
    or maxs.x > 1.20001
    or mins.y < -0.08001
    or maxs.y > 0.08001
    or mins.z < -0.00001
    or maxs.z > 3.20001
):
    raise RuntimeError(f"Production bounds exceeded: min={tuple(mins)}, max={tuple(maxs)}")

bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format="GLB",
    export_apply=True,
    export_yup=True,
    export_materials="EXPORT",
)

print(f"BOTTOM_FRAME_OLD_LOCATION={old_location}")
print(f"BOTTOM_FRAME_OLD_DIMENSIONS={old_dimensions}")
print(f"BOTTOM_FRAME_NEW_LOCATION={tuple(bottom_frame.location)}")
print(f"BOTTOM_FRAME_NEW_DIMENSIONS={tuple(bottom_frame.dimensions)}")
print(f"GEOMETRY_DIGEST_BEFORE={digest_before}")
print(f"GEOMETRY_DIGEST_AFTER={digest_after}")
print(f"TRIANGLES_BEFORE={triangles_before}")
print(f"TRIANGLES_AFTER={triangles_after}")
print(f"BOUNDS_MIN={mins.x:.6f},{mins.y:.6f},{mins.z:.6f}")
print(f"BOUNDS_MAX={maxs.x:.6f},{maxs.y:.6f},{maxs.z:.6f}")
print(f"WALL_EXPORT={OUT_GLB}")
