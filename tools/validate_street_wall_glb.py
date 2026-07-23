import bpy
import json
import sys

source = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
points = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
mins = [min(v[i] for v in points) for i in range(3)]
maxs = [max(v[i] for v in points) for i in range(3)]
source = next((len(o.data.polygons) for o in meshes if o.name == "WallSource_BrickAndVents"), 0)
result = {
    "mesh_objects": len(meshes),
    "source_faces": source,
    "total_triangles": sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes),
    "dimensions_xyz": [round(maxs[i] - mins[i], 6) for i in range(3)],
    "bounds_min": [round(v, 6) for v in mins],
    "bounds_max": [round(v, 6) for v in maxs],
    "materials": sorted({slot.material.name for o in meshes for slot in o.material_slots if slot.material}),
}
print("WALL_VALIDATION=" + json.dumps(result, sort_keys=True))
