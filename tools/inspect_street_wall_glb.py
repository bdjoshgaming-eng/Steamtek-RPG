import bpy
import json
import sys

source = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source)

rows = []
for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        continue
    mesh = obj.data
    world_corners = [obj.matrix_world @ v.co for v in mesh.vertices]
    mins = [min(v[i] for v in world_corners) for i in range(3)]
    maxs = [max(v[i] for v in world_corners) for i in range(3)]
    rows.append({
        "name": obj.name,
        "vertices": len(mesh.vertices),
        "edges": len(mesh.edges),
        "polygons": len(mesh.polygons),
        "triangles": sum(len(p.vertices) - 2 for p in mesh.polygons),
        "bounds_min": mins,
        "bounds_max": maxs,
        "dimensions": [maxs[i] - mins[i] for i in range(3)],
        "materials": [slot.material.name if slot.material else None for slot in obj.material_slots],
    })

print("WALL_INSPECTION=" + json.dumps(rows, indent=2))
