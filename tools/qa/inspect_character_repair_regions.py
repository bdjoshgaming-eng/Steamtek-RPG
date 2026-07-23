"""Inspect localized character repair regions and connected mesh components.

Usage:
    blender.exe --background --python inspect_character_repair_regions.py -- \
        input.glb [target_height_m]
"""

from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in objects
        for corner in obj.bound_box
    ]
    minimum = Vector(
        (
            min(corner.x for corner in corners),
            min(corner.y for corner in corners),
            min(corner.z for corner in corners),
        )
    )
    maximum = Vector(
        (
            max(corner.x for corner in corners),
            max(corner.y for corner in corners),
            max(corner.z for corner in corners),
        )
    )
    return minimum, maximum


def normalize(objects: list[bpy.types.Object], target_height: float) -> None:
    minimum, maximum = world_bounds(objects)
    scale_factor = target_height / (maximum.z - minimum.z)
    for obj in bpy.context.scene.objects:
        obj.scale *= scale_factor
    bpy.context.view_layer.update()
    minimum, maximum = world_bounds(objects)
    translation = Vector(
        (
            -(minimum.x + maximum.x) * 0.5,
            -(minimum.y + maximum.y) * 0.5,
            -minimum.z,
        )
    )
    for root in [obj for obj in bpy.context.scene.objects if obj.parent is None]:
        root.location += translation
    bpy.context.view_layer.update()


def mesh_components(obj: bpy.types.Object) -> list[dict]:
    mesh = obj.data
    neighbors: list[set[int]] = [set() for _ in mesh.vertices]
    for edge in mesh.edges:
        a, b = edge.vertices
        neighbors[a].add(b)
        neighbors[b].add(a)

    components: list[dict] = []
    unvisited = set(range(len(mesh.vertices)))
    while unvisited:
        start = next(iter(unvisited))
        queue = deque([start])
        indices: list[int] = []
        unvisited.remove(start)
        while queue:
            vertex_index = queue.popleft()
            indices.append(vertex_index)
            for neighbor in neighbors[vertex_index]:
                if neighbor in unvisited:
                    unvisited.remove(neighbor)
                    queue.append(neighbor)

        coordinates = [obj.matrix_world @ mesh.vertices[index].co for index in indices]
        minimum = Vector(
            (
                min(co.x for co in coordinates),
                min(co.y for co in coordinates),
                min(co.z for co in coordinates),
            )
        )
        maximum = Vector(
            (
                max(co.x for co in coordinates),
                max(co.y for co in coordinates),
                max(co.z for co in coordinates),
            )
        )
        index_set = set(indices)
        polygon_count = sum(
            1
            for polygon in mesh.polygons
            if all(index in index_set for index in polygon.vertices)
        )
        components.append(
            {
                "vertices": len(indices),
                "polygons": polygon_count,
                "minimum": [round(value, 6) for value in minimum],
                "maximum": [round(value, 6) for value in maximum],
                "size": [round(value, 6) for value in maximum - minimum],
            }
        )
    return sorted(components, key=lambda item: item["vertices"], reverse=True)


def region_stats(obj: bpy.types.Object, name: str, predicate) -> dict:
    mesh = obj.data
    world_coordinates = [obj.matrix_world @ vertex.co for vertex in mesh.vertices]
    vertex_indices = {
        index for index, coordinate in enumerate(world_coordinates) if predicate(coordinate)
    }
    edge_indices = [
        edge.index
        for edge in mesh.edges
        if edge.vertices[0] in vertex_indices and edge.vertices[1] in vertex_indices
    ]
    polygon_indices = [
        polygon.index
        for polygon in mesh.polygons
        if all(index in vertex_indices for index in polygon.vertices)
    ]
    edge_face_counts = {index: 0 for index in edge_indices}
    edge_lookup = {
        tuple(sorted(mesh.edges[index].vertices)): index for index in edge_indices
    }
    for polygon_index in polygon_indices:
        polygon = mesh.polygons[polygon_index]
        vertices = list(polygon.vertices)
        for offset, vertex_index in enumerate(vertices):
            key = tuple(sorted((vertex_index, vertices[(offset + 1) % len(vertices)])))
            if key in edge_lookup:
                edge_face_counts[edge_lookup[key]] += 1
    return {
        "name": name,
        "vertices": len(vertex_indices),
        "edges": len(edge_indices),
        "polygons": len(polygon_indices),
        "boundary_edges_within_region": sum(
            1 for count in edge_face_counts.values() if count < 2
        ),
        "overfull_edges_within_region": sum(
            1 for count in edge_face_counts.values() if count > 2
        ),
    }


def topology_stats(obj: bpy.types.Object) -> dict:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.edges.ensure_lookup_table()
    boundary_edges = [edge for edge in bm.edges if edge.is_boundary]
    wire_edges = [edge for edge in bm.edges if edge.is_wire]
    overfull_edges = [edge for edge in bm.edges if len(edge.link_faces) > 2]
    boundary_centers = [
        obj.matrix_world @ ((edge.verts[0].co + edge.verts[1].co) * 0.5)
        for edge in boundary_edges
    ]
    overfull_centers = [
        obj.matrix_world @ ((edge.verts[0].co + edge.verts[1].co) * 0.5)
        for edge in overfull_edges
    ]
    seen_face_keys = {}
    duplicate_faces = []
    for face in bm.faces:
        key = tuple(sorted(vertex.index for vertex in face.verts))
        if key in seen_face_keys:
            duplicate_faces.append(face.index)
        else:
            seen_face_keys[key] = face.index
    result = {
        "manifold_edges": sum(1 for edge in bm.edges if edge.is_manifold),
        "boundary_edges": len(boundary_edges),
        "boundary_edge_centers": [
            [round(value, 6) for value in center]
            for center in boundary_centers[:50]
        ],
        "wire_edges": len(wire_edges),
        "overfull_edges": len(overfull_edges),
        "duplicate_faces": len(duplicate_faces),
        "duplicate_face_indices": duplicate_faces[:50],
        "overfull_edge_centers": [
            [round(value, 6) for value in center]
            for center in overfull_centers[:50]
        ],
        "degenerate_faces": sum(
            1 for face in bm.faces if face.calc_area() <= 1.0e-12
        ),
    }
    bm.free()
    return result


arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
if not arguments:
    raise SystemExit("Pass an input GLB after --")

source = Path(arguments[0]).resolve()
target_height = float(arguments[1]) if len(arguments) > 1 else 1.83
weld_exact_duplicates = len(arguments) > 2 and arguments[2] == "weld"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
normalize(meshes, target_height)
if weld_exact_duplicates:
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.remove_doubles(threshold=0.000001)
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        obj.select_set(False)

report = {
    "source": str(source),
    "target_height_m": target_height,
    "weld_exact_duplicates": weld_exact_duplicates,
    "objects": [],
}
for obj in meshes:
    components = mesh_components(obj)
    report["objects"].append(
        {
            "name": obj.name,
            "vertices": len(obj.data.vertices),
            "polygons": len(obj.data.polygons),
            "uv_layers": len(obj.data.uv_layers),
            "component_count": len(components),
            "components": components[:20],
            "small_components_under_20_vertices": sum(
                1 for component in components if component["vertices"] < 20
            ),
            "topology": topology_stats(obj),
            "regions": [
                region_stats(
                    obj,
                    "hair_and_head",
                    lambda co: co.z > 1.52,
                ),
                region_stats(
                    obj,
                    "left_hand",
                    lambda co: co.x < -0.27 and 0.55 < co.z < 0.95,
                ),
                region_stats(
                    obj,
                    "right_hand",
                    lambda co: co.x > 0.27 and 0.55 < co.z < 0.95,
                ),
                region_stats(
                    obj,
                    "left_foot",
                    lambda co: co.x < -0.035 and co.z < 0.20,
                ),
                region_stats(
                    obj,
                    "right_foot",
                    lambda co: co.x > 0.035 and co.z < 0.20,
                ),
            ],
        }
    )

print("STEAMTEK_CHARACTER_REPAIR_REGIONS=" + json.dumps(report, indent=2))
