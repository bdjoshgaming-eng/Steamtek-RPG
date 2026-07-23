import json
from collections import deque
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
OUTPUT = (
    ROOT
    / "output"
    / "hero_rig_rebuild"
    / "STK_HERO_BaseBody_01_Mesh_Components.json"
)

body = bpy.data.objects["STK_HERO_BaseBody_01_RiggedBody"]
mesh = body.data

adjacency = [[] for _vertex in mesh.vertices]
for edge in mesh.edges:
    left, right = edge.vertices
    adjacency[left].append(right)
    adjacency[right].append(left)

component_of = [-1] * len(mesh.vertices)
components = []

for start in range(len(mesh.vertices)):
    if component_of[start] != -1:
        continue
    component_index = len(components)
    queue = deque([start])
    component_of[start] = component_index
    indices = []
    while queue:
        vertex_index = queue.popleft()
        indices.append(vertex_index)
        for neighbor in adjacency[vertex_index]:
            if component_of[neighbor] == -1:
                component_of[neighbor] = component_index
                queue.append(neighbor)
    components.append(indices)

component_faces = [[] for _component in components]
component_materials = [set() for _component in components]
for polygon in mesh.polygons:
    component_index = component_of[polygon.vertices[0]]
    component_faces[component_index].append(polygon.index)
    component_materials[component_index].add(polygon.material_index)

records = []
for component_index, indices in enumerate(components):
    minimum = [float("inf")] * 3
    maximum = [float("-inf")] * 3
    for vertex_index in indices:
        coordinate = mesh.vertices[vertex_index].co
        for axis in range(3):
            minimum[axis] = min(minimum[axis], coordinate[axis])
            maximum[axis] = max(maximum[axis], coordinate[axis])

    material_names = [
        mesh.materials[index].name
        for index in sorted(component_materials[component_index])
        if index < len(mesh.materials) and mesh.materials[index]
    ]
    records.append(
        {
            "component": component_index,
            "vertices": len(indices),
            "faces": len(component_faces[component_index]),
            "minimum": minimum,
            "maximum": maximum,
            "dimensions": [
                maximum[axis] - minimum[axis] for axis in range(3)
            ],
            "materials": material_names,
            "vertex_indices": indices,
        }
    )

records.sort(key=lambda record: record["vertices"], reverse=True)
OUTPUT.write_text(json.dumps(records, indent=2), encoding="utf-8")

print(f"COMPONENTS={len(records)}")
for record in records[:30]:
    print(
        "COMPONENT",
        record["component"],
        "VERTICES",
        record["vertices"],
        "FACES",
        record["faces"],
        "MIN",
        tuple(round(value, 4) for value in record["minimum"]),
        "MAX",
        tuple(round(value, 4) for value in record["maximum"]),
    )
print(f"OUTPUT={OUTPUT}")
