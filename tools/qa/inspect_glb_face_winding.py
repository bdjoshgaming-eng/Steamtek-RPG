"""Inspect positional-welded face winding in a GLB."""

from __future__ import annotations

import sys

import bmesh
import bpy


source = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source)
obj = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
bm = bmesh.new()
bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1.0e-7)


def edge_direction(face, edge) -> int:
    vertices = list(face.verts)
    for index, vertex in enumerate(vertices):
        following = vertices[(index + 1) % len(vertices)]
        if vertex == edge.verts[0] and following == edge.verts[1]:
            return 1
        if vertex == edge.verts[1] and following == edge.verts[0]:
            return -1
    raise RuntimeError("Face does not traverse linked edge")


def inconsistent_edges() -> int:
    return sum(
        1
        for edge in bm.edges
        if len(edge.link_faces) == 2
        and edge_direction(edge.link_faces[0], edge)
        == edge_direction(edge.link_faces[1], edge)
    )


print(f"WINDING_INCONSISTENT_BEFORE={inconsistent_edges()}")
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
print(f"WINDING_INCONSISTENT_AFTER={inconsistent_edges()}")
print(f"MANIFOLD_EDGES={sum(1 for edge in bm.edges if edge.is_manifold)}")
print(f"BOUNDARY_EDGES={sum(1 for edge in bm.edges if edge.is_boundary)}")
bm.free()
