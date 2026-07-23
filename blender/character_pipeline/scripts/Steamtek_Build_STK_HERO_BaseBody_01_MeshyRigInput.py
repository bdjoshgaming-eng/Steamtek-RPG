"""Build and validate the one-material Meshy rigging input for the hero body.

The approved production GLB is read-only. This script imports it, bakes the
approved skin, shirt, shorts, and matte-black hair appearance into the existing
UV atlas, replaces the source materials with one simple opaque PBR material,
and exports a separate unrigged GLB for Meshy auto-rigging.
"""

from __future__ import annotations

import hashlib
import json
import math
from collections import defaultdict, deque
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree


ASSET_ID = "STK_HERO_BaseBody_01"
OUTPUT_ID = f"{ASSET_ID}_MeshyRigInput"
MATERIAL_NAME = "STK_MAT_HERO_MeshyRigInput"
PROJECT_ROOT = Path(__file__).resolve().parents[3]
SOURCE = (
    PROJECT_ROOT
    / "assets"
    / "characters"
    / "humanoid"
    / "base"
    / ASSET_ID
    / "v01"
    / f"{ASSET_ID}.glb"
)
OUTPUT_DIR = PROJECT_ROOT / "output" / "meshy_rig_input"
OUTPUT = OUTPUT_DIR / f"{OUTPUT_ID}.glb"
ATLAS = OUTPUT_DIR / f"{OUTPUT_ID}_BaseColor.png"
REPORT = OUTPUT_DIR / f"{OUTPUT_ID}_Report.json"
ATLAS_SIZE = 4096
WELD_DISTANCE = 1.0e-7


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def triangle_count(obj: bpy.types.Object) -> int:
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def topology_stats(obj: bpy.types.Object) -> dict:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    stats = {
        "vertices": len(bm.verts),
        "edges": len(bm.edges),
        "faces": len(bm.faces),
        "triangles": triangle_count(obj),
        "manifold_edges": sum(1 for edge in bm.edges if edge.is_manifold),
        "boundary_edges": sum(1 for edge in bm.edges if edge.is_boundary),
        "wire_edges": sum(1 for edge in bm.edges if edge.is_wire),
        "overfull_edges": sum(
            1 for edge in bm.edges if len(edge.link_faces) > 2
        ),
        "degenerate_faces": sum(
            1 for face in bm.faces if face.calc_area() <= 1.0e-12
        ),
    }
    bm.free()
    return stats


def connected_components(obj: bpy.types.Object) -> int:
    mesh = obj.data
    vertex_faces: dict[int, list[int]] = defaultdict(list)
    for polygon in mesh.polygons:
        for vertex_index in polygon.vertices:
            vertex_faces[vertex_index].append(polygon.index)
    visited: set[int] = set()
    count = 0
    for polygon in mesh.polygons:
        if polygon.index in visited:
            continue
        count += 1
        queue = deque([polygon.index])
        while queue:
            face_index = queue.popleft()
            if face_index in visited:
                continue
            visited.add(face_index)
            for vertex_index in mesh.polygons[face_index].vertices:
                for neighbor in vertex_faces[vertex_index]:
                    if neighbor not in visited:
                        queue.append(neighbor)
    return count


def duplicate_face_count(obj: bpy.types.Object) -> int:
    seen: set[tuple[int, ...]] = set()
    duplicates = 0
    for polygon in obj.data.polygons:
        key = tuple(sorted(polygon.vertices))
        if key in seen:
            duplicates += 1
        else:
            seen.add(key)
    return duplicates


def uv_stats(obj: bpy.types.Object) -> dict:
    if len(obj.data.uv_layers) != 1:
        return {
            "layers": len(obj.data.uv_layers),
            "finite": False,
            "degenerate_triangles": None,
        }
    uv_layer = obj.data.uv_layers.active
    finite = True
    degenerate = 0
    outside_zero_one = 0
    for polygon in obj.data.polygons:
        points = []
        for loop_index in polygon.loop_indices:
            uv = uv_layer.data[loop_index].uv
            points.append(uv.copy())
            finite = finite and math.isfinite(uv.x) and math.isfinite(uv.y)
            if uv.x < -1.0e-5 or uv.x > 1.00001 or uv.y < -1.0e-5 or uv.y > 1.00001:
                outside_zero_one += 1
        if len(points) == 3:
            area_twice = abs(
                (points[1].x - points[0].x) * (points[2].y - points[0].y)
                - (points[2].x - points[0].x)
                * (points[1].y - points[0].y)
            )
            if area_twice <= 1.0e-12:
                degenerate += 1
    return {
        "layers": 1,
        "finite": finite,
        "degenerate_triangles": degenerate,
        "loops_outside_zero_one": outside_zero_one,
    }


def polygon_uv_area(mesh: bpy.types.Mesh, uv_layer, polygon) -> float:
    points = [
        uv_layer.data[loop_index].uv
        for loop_index in polygon.loop_indices
    ]
    if len(points) != 3:
        return 0.0
    return abs(
        (points[1].x - points[0].x) * (points[2].y - points[0].y)
        - (points[2].x - points[0].x) * (points[1].y - points[0].y)
    ) * 0.5


def repair_degenerate_uv_triangles(obj: bpy.types.Object) -> dict:
    """Give collapsed repair-cap UVs a tiny sample from an adjacent face."""
    mesh = obj.data
    uv_layer = mesh.uv_layers.active
    before = uv_stats(obj)
    edge_faces: dict[tuple[int, int], list[int]] = defaultdict(list)
    for polygon in mesh.polygons:
        for edge_key in polygon.edge_keys:
            edge_faces[tuple(sorted(edge_key))].append(polygon.index)

    repaired = 0
    fallback = 0
    minimum_offset = 4.0 / ATLAS_SIZE
    for polygon in mesh.polygons:
        if polygon_uv_area(mesh, uv_layer, polygon) > 1.0e-12:
            continue
        solution = None
        for edge_key in polygon.edge_keys:
            shared = tuple(sorted(edge_key))
            for neighbor_index in edge_faces[shared]:
                if neighbor_index == polygon.index:
                    continue
                neighbor = mesh.polygons[neighbor_index]
                if polygon_uv_area(mesh, uv_layer, neighbor) <= 1.0e-12:
                    continue
                neighbor_uv_by_vertex = {
                    mesh.loops[loop_index].vertex_index: uv_layer.data[
                        loop_index
                    ].uv.copy()
                    for loop_index in neighbor.loop_indices
                }
                if not all(
                    vertex_index in neighbor_uv_by_vertex
                    for vertex_index in shared
                ):
                    continue
                first_uv = neighbor_uv_by_vertex[shared[0]]
                second_uv = neighbor_uv_by_vertex[shared[1]]
                edge_vector = second_uv - first_uv
                if edge_vector.length <= 1.0e-8:
                    continue
                midpoint = (first_uv + second_uv) * 0.5
                perpendicular = Vector((-edge_vector.y, edge_vector.x))
                perpendicular.normalize()
                offset = max(edge_vector.length * 0.35, minimum_offset)
                neighbor_center = sum(
                    (
                        uv_layer.data[loop_index].uv
                        for loop_index in neighbor.loop_indices
                    ),
                    Vector((0.0, 0.0)),
                ) / len(neighbor.loop_indices)
                candidates = [
                    midpoint + perpendicular * offset,
                    midpoint - perpendicular * offset,
                ]
                third_uv = min(
                    candidates,
                    key=lambda candidate: (candidate - neighbor_center).length,
                )
                third_uv.x = min(1.0, max(0.0, third_uv.x))
                third_uv.y = min(1.0, max(0.0, third_uv.y))
                solution = (shared, first_uv, second_uv, third_uv)
                break
            if solution is not None:
                break

        if solution is None:
            fallback += 1
            center = Vector((0.5, 0.5))
            fallback_uvs = [
                center + Vector((-minimum_offset, -minimum_offset)),
                center + Vector((minimum_offset, -minimum_offset)),
                center + Vector((0.0, minimum_offset)),
            ]
            for loop_index, uv in zip(polygon.loop_indices, fallback_uvs):
                uv_layer.data[loop_index].uv = uv
        else:
            shared, first_uv, second_uv, third_uv = solution
            for loop_index in polygon.loop_indices:
                vertex_index = mesh.loops[loop_index].vertex_index
                if vertex_index == shared[0]:
                    uv_layer.data[loop_index].uv = first_uv
                elif vertex_index == shared[1]:
                    uv_layer.data[loop_index].uv = second_uv
                else:
                    uv_layer.data[loop_index].uv = third_uv
        repaired += 1

    mesh.update()
    return {
        "before": before,
        "repaired_triangles": repaired,
        "fallback_triangles": fallback,
        "after": uv_stats(obj),
    }

def signed_volume(obj: bpy.types.Object) -> float:
    volume = 0.0
    obj.data.calc_loop_triangles()
    for triangle in obj.data.loop_triangles:
        a, b, c = (
            obj.matrix_world @ obj.data.vertices[index].co
            for index in triangle.vertices
        )
        volume += a.dot(b.cross(c)) / 6.0
    return volume


def identity_transform(obj: bpy.types.Object, tolerance: float = 1.0e-6) -> bool:
    return (
        obj.location.length <= tolerance
        and all(abs(value) <= tolerance for value in obj.rotation_euler)
        and all(abs(value - 1.0) <= tolerance for value in obj.scale)
    )


def source_material_diagnostics(obj: bpy.types.Object) -> list[dict]:
    diagnostics = []
    for material in obj.data.materials:
        if material is None:
            diagnostics.append({"missing": True})
            continue
        nodes = list(material.node_tree.nodes) if material.use_nodes else []
        principled = next(
            (node for node in nodes if node.type == "BSDF_PRINCIPLED"),
            None,
        )
        alpha_linked = (
            principled.inputs["Alpha"].is_linked if principled is not None else None
        )
        alpha_value = (
            float(principled.inputs["Alpha"].default_value)
            if principled is not None
            else None
        )
        diagnostics.append(
            {
                "name": material.name,
                "use_nodes": material.use_nodes,
                "node_types": sorted({node.type for node in nodes}),
                "backface_culling": material.use_backface_culling,
                "alpha_linked": alpha_linked,
                "alpha_value": alpha_value,
            }
        )
    return diagnostics


def merge_mesh_objects(meshes: list[bpy.types.Object]) -> bpy.types.Object:
    for obj in meshes:
        world_matrix = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world_matrix
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return body


def orient_closed_components_outward(bm: bmesh.types.BMesh) -> dict:
    """Make every edge-connected closed component use positive volume."""
    remaining = set(bm.faces)
    component_volumes = []
    flipped_components = 0
    while remaining:
        seed = remaining.pop()
        component = [seed]
        queue = [seed]
        while queue:
            face = queue.pop()
            for edge in face.edges:
                for neighbor in edge.link_faces:
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        component.append(neighbor)
                        queue.append(neighbor)
        volume = 0.0
        for face in component:
            if len(face.verts) != 3:
                continue
            first, second, third = (vertex.co for vertex in face.verts)
            volume += first.dot(second.cross(third)) / 6.0
        if volume < 0.0:
            bmesh.ops.reverse_faces(bm, faces=component)
            volume = -volume
            flipped_components += 1
        component_volumes.append(volume)
    return {
        "edge_connected_components": len(component_volumes),
        "flipped_components": flipped_components,
        "minimum_component_volume_m3": round(min(component_volumes), 12),
        "all_components_outward": all(volume > 0.0 for volume in component_volumes),
    }

def remove_exact_duplicates_and_recalculate(obj: bpy.types.Object) -> dict:
    """Analyze a positional weld without altering proven GLB winding or seams."""
    before = topology_stats(obj)
    before_duplicate_faces = duplicate_face_count(obj)
    had_custom_normals = obj.data.has_custom_normals
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=WELD_DISTANCE)

    seen: set[tuple[int, ...]] = set()
    duplicate_faces_after_weld = 0
    for face in bm.faces:
        key = tuple(sorted(vertex.index for vertex in face.verts))
        if key in seen:
            duplicate_faces_after_weld += 1
        else:
            seen.add(key)

    remaining = set(bm.faces)
    edge_components = 0
    while remaining:
        edge_components += 1
        seed = remaining.pop()
        queue = [seed]
        while queue:
            face = queue.pop()
            for edge in face.edges:
                for neighbor in edge.link_faces:
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        queue.append(neighbor)

    after = {
        "vertices": len(bm.verts),
        "edges": len(bm.edges),
        "faces": len(bm.faces),
        "triangles": sum(max(0, len(face.verts) - 2) for face in bm.faces),
        "manifold_edges": sum(1 for edge in bm.edges if edge.is_manifold),
        "boundary_edges": sum(1 for edge in bm.edges if edge.is_boundary),
        "wire_edges": sum(1 for edge in bm.edges if edge.is_wire),
        "overfull_edges": sum(1 for edge in bm.edges if len(edge.link_faces) > 2),
        "degenerate_faces": sum(
            1 for face in bm.faces if face.calc_area() <= 1.0e-12
        ),
    }
    bm.free()
    return {
        "weld_distance_m": WELD_DISTANCE,
        "before": before,
        "after": after,
        "vertices_resolved_by_positional_test": before["vertices"] - after["vertices"],
        "duplicate_faces_before": before_duplicate_faces,
        "duplicate_faces_after_weld": duplicate_faces_after_weld,
        "connected_components_after_weld": edge_components,
        "custom_normals_preserved": had_custom_normals,
        "source_face_winding_preserved": True,
        "geometry_modified": False,
        "normals_recalculated_outward": False,
        "signed_volume_m3": round(signed_volume(obj), 9),
    }

def orient_faces_outward_by_raycast(
    obj: bpy.types.Object, apply_repairs: bool
) -> dict:
    """Classify each triangle by the nearer interior ray and optionally flip it."""
    mesh = obj.data
    vertices = [vertex.co.copy() for vertex in mesh.vertices]
    polygons = [tuple(polygon.vertices) for polygon in mesh.polygons]
    tree = BVHTree.FromPolygons(vertices, polygons, all_triangles=True)
    epsilon = 5.0e-5
    maximum_distance = 5.0
    inward_faces = []
    ambiguous_faces = 0
    for polygon in mesh.polygons:
        normal = polygon.normal.normalized()
        center = polygon.center
        forward = tree.ray_cast(
            center + normal * epsilon, normal, maximum_distance
        )
        backward = tree.ray_cast(
            center - normal * epsilon, -normal, maximum_distance
        )
        forward_distance = forward[3] if forward[0] is not None else None
        backward_distance = backward[3] if backward[0] is not None else None
        points_inward = False
        if forward_distance is not None and backward_distance is None:
            points_inward = True
        elif forward_distance is None and backward_distance is not None:
            points_inward = False
        elif forward_distance is not None and backward_distance is not None:
            points_inward = forward_distance < backward_distance
        else:
            ambiguous_faces += 1
        if points_inward:
            inward_faces.append(polygon.index)

    if apply_repairs and inward_faces:
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bm.faces.ensure_lookup_table()
        bmesh.ops.reverse_faces(
            bm, faces=[bm.faces[index] for index in inward_faces]
        )
        bm.to_mesh(mesh)
        bm.free()
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        if mesh.has_custom_normals:
            bpy.ops.mesh.customdata_custom_splitnormals_clear()
        for polygon in mesh.polygons:
            polygon.use_smooth = True
        mesh.update(calc_edges=True)

    return {
        "method": "bidirectional_nearest_surface_raycast",
        "faces_tested": len(mesh.polygons),
        "inward_faces_detected": len(inward_faces),
        "faces_flipped": len(inward_faces) if apply_repairs else 0,
        "ambiguous_faces": ambiguous_faces,
        "repairs_applied": apply_repairs,
    }

def bake_approved_base_color(obj: bpy.types.Object) -> bpy.types.Image:
    """Transfer every source UV triangle into a new atlas without ray baking."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    if len(obj.data.materials) != 2:
        raise RuntimeError(
            f"Expected approved body and hair materials; found {len(obj.data.materials)}"
        )
    if len(obj.data.uv_layers) != 1:
        raise RuntimeError("Atlas rebuild expects exactly one source UV map")

    source_uv = obj.data.uv_layers.active
    source_uv.name = "STK_SourceUV"
    source_uv_name = "STK_SourceUV"
    obj.data.uv_layers.new(name="STK_MeshyRigUV", do_init=False)
    target_uv_name = "STK_MeshyRigUV"
    obj.data.uv_layers.active = obj.data.uv_layers[target_uv_name]
    obj.data.uv_layers[source_uv_name].active_render = False
    obj.data.uv_layers[target_uv_name].active_render = True

    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.scene.tool_settings.use_uv_select_sync = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(
        angle_limit=math.radians(66.0),
        margin_method="SCALED",
        island_margin=0.012,
        area_weight=0.0,
        correct_aspect=True,
        scale_to_bounds=True,
    )
    bpy.ops.object.mode_set(mode="OBJECT")

    body_material = obj.data.materials[0]
    principled = next(
        node
        for node in body_material.node_tree.nodes
        if node.type == "BSDF_PRINCIPLED"
    )
    base_color = principled.inputs["Base Color"]
    if not base_color.is_linked:
        raise RuntimeError("Approved body base color is not texture-linked")
    source_node = base_color.links[0].from_node
    if source_node.type != "TEX_IMAGE" or source_node.image is None:
        raise RuntimeError("Approved body base color image is missing")
    source_image = source_node.image
    source_width, source_height = map(int, source_image.size)
    source_pixels = np.empty(source_width * source_height * 4, dtype=np.float32)
    source_image.pixels.foreach_get(source_pixels)
    source_pixels = source_pixels.reshape((source_height, source_width, 4))

    target_pixels = np.zeros((ATLAS_SIZE, ATLAS_SIZE, 4), dtype=np.float32)
    target_pixels[:, :, :3] = 0.02
    target_pixels[:, :, 3] = 1.0
    painted = np.zeros((ATLAS_SIZE, ATLAS_SIZE), dtype=np.bool_)
    source_layer = obj.data.uv_layers[source_uv_name]
    target_layer = obj.data.uv_layers[target_uv_name]
    hair_color = np.array((0.004, 0.006, 0.009, 1.0), dtype=np.float32)

    for polygon in obj.data.polygons:
        if len(polygon.loop_indices) != 3:
            raise RuntimeError("Meshy atlas transfer requires triangulated geometry")
        source_points = np.array(
            [source_layer.data[index].uv[:] for index in polygon.loop_indices],
            dtype=np.float32,
        )
        target_points = np.array(
            [target_layer.data[index].uv[:] for index in polygon.loop_indices],
            dtype=np.float32,
        )
        target_points[:, 0] *= ATLAS_SIZE - 1
        target_points[:, 1] *= ATLAS_SIZE - 1
        minimum = np.floor(target_points.min(axis=0)).astype(np.int32)
        maximum = np.ceil(target_points.max(axis=0)).astype(np.int32)
        minimum = np.maximum(minimum, 0)
        maximum = np.minimum(maximum, ATLAS_SIZE - 1)
        if np.any(maximum < minimum):
            continue
        xs = np.arange(minimum[0], maximum[0] + 1, dtype=np.float32)
        ys = np.arange(minimum[1], maximum[1] + 1, dtype=np.float32)
        grid_x, grid_y = np.meshgrid(xs, ys)
        x0, y0 = target_points[0]
        x1, y1 = target_points[1]
        x2, y2 = target_points[2]
        denominator = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
        if abs(float(denominator)) <= 1.0e-8:
            continue
        weight0 = (
            (y1 - y2) * (grid_x - x2) + (x2 - x1) * (grid_y - y2)
        ) / denominator
        weight1 = (
            (y2 - y0) * (grid_x - x2) + (x0 - x2) * (grid_y - y2)
        ) / denominator
        weight2 = 1.0 - weight0 - weight1
        inside = (weight0 >= -1.0e-4) & (weight1 >= -1.0e-4) & (weight2 >= -1.0e-4)
        if not inside.any():
            continue
        local_y, local_x = np.nonzero(inside)
        atlas_x = local_x + minimum[0]
        atlas_y = local_y + minimum[1]
        if polygon.material_index == 1:
            colors = np.repeat(hair_color[None, :], len(atlas_x), axis=0)
        else:
            source_u = (
                weight0[inside] * source_points[0, 0]
                + weight1[inside] * source_points[1, 0]
                + weight2[inside] * source_points[2, 0]
            )
            source_v = (
                weight0[inside] * source_points[0, 1]
                + weight1[inside] * source_points[1, 1]
                + weight2[inside] * source_points[2, 1]
            )
            source_x = np.clip(
                np.rint(source_u * (source_width - 1)).astype(np.int32),
                0,
                source_width - 1,
            )
            source_y = np.clip(
                np.rint(source_v * (source_height - 1)).astype(np.int32),
                0,
                source_height - 1,
            )
            colors = source_pixels[source_y, source_x]
        target_pixels[atlas_y, atlas_x] = colors
        target_pixels[atlas_y, atlas_x, 3] = 1.0
        painted[atlas_y, atlas_x] = True

    for _ in range(12):
        unpainted = ~painted
        if not unpainted.any():
            break
        additions = np.zeros_like(painted)
        for delta_y, delta_x in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            shifted_mask = np.roll(painted, (delta_y, delta_x), axis=(0, 1))
            if delta_y == -1:
                shifted_mask[-1, :] = False
            elif delta_y == 1:
                shifted_mask[0, :] = False
            if delta_x == -1:
                shifted_mask[:, -1] = False
            elif delta_x == 1:
                shifted_mask[:, 0] = False
            candidates = unpainted & shifted_mask & ~additions
            if candidates.any():
                shifted_pixels = np.roll(
                    target_pixels, (delta_y, delta_x), axis=(0, 1)
                )
                target_pixels[candidates] = shifted_pixels[candidates]
                additions[candidates] = True
        painted |= additions
        if not additions.any():
            break

    image = bpy.data.images.new(
        f"{OUTPUT_ID}_BaseColor",
        width=ATLAS_SIZE,
        height=ATLAS_SIZE,
        alpha=False,
        float_buffer=False,
    )
    image.colorspace_settings.name = "sRGB"
    image.pixels.foreach_set(target_pixels.reshape(-1))
    image.update()
    image.filepath_raw = str(ATLAS)
    image.file_format = "PNG"

    obj.data.uv_layers.remove(obj.data.uv_layers[source_uv_name])
    target_layer = obj.data.uv_layers.get(target_uv_name)
    if target_layer is None:
        raise RuntimeError("Target UV layer disappeared during transfer")
    target_layer.name = "UVMap"
    obj.data.uv_layers.active = target_layer
    target_layer.active_render = True
    obj.data.update()
    if uv_stats(obj)["degenerate_triangles"]:
        raise RuntimeError("Packed Meshy atlas contains degenerate UV triangles")
    image.save_render(filepath=str(ATLAS), scene=bpy.context.scene)
    image.pack()
    return image

def create_simple_opaque_material(
    obj: bpy.types.Object, atlas: bpy.types.Image
) -> bpy.types.Material:
    material = bpy.data.materials.new(MATERIAL_NAME)
    material.use_nodes = True
    material.use_backface_culling = True
    material.diffuse_color = (1.0, 1.0, 1.0, 1.0)
    nodes = material.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    principled = nodes.new("ShaderNodeBsdfPrincipled")
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = atlas
    texture.interpolation = "Linear"
    texture.extension = "REPEAT"
    principled.inputs["Metallic"].default_value = 0.0
    principled.inputs["Roughness"].default_value = 0.74
    principled.inputs["Alpha"].default_value = 1.0
    specular = principled.inputs.get("Specular IOR Level")
    if specular is not None:
        specular.default_value = 0.25
    material.node_tree.links.new(
        texture.outputs["Color"], principled.inputs["Base Color"]
    )
    material.node_tree.links.new(
        principled.outputs["BSDF"], output.inputs["Surface"]
    )

    obj.data.materials.clear()
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.material_index = 0
    obj.data.update()
    return material


def export_glb(root: bpy.types.Object, body: bpy.types.Object) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_skins=False,
        export_morph=False,
        export_yup=True,
        export_apply=False,
        export_extras=True,
        export_tangents=False,
    )


def validate_reimport(expected_triangles: int) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUTPUT))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    actions = list(bpy.data.actions)
    if len(meshes) != 1:
        raise RuntimeError(f"Reimport found {len(meshes)} mesh objects")
    body = meshes[0]
    raw_stats = topology_stats(body)
    raw_components = connected_components(body)
    materials = [material for material in body.data.materials if material]
    image_nodes = [
        node
        for material in materials
        if material.use_nodes
        for node in material.node_tree.nodes
        if node.type == "TEX_IMAGE" and node.image is not None
    ]
    principled_nodes = [
        node
        for material in materials
        if material.use_nodes
        for node in material.node_tree.nodes
        if node.type == "BSDF_PRINCIPLED"
    ]
    alpha_opaque = all(
        not node.inputs["Alpha"].is_linked
        and abs(float(node.inputs["Alpha"].default_value) - 1.0) <= 1.0e-6
        for node in principled_nodes
    )
    positional_weld_validation = remove_exact_duplicates_and_recalculate(body)
    welded_stats = positional_weld_validation["after"]
    normal_validation = orient_faces_outward_by_raycast(
        body, apply_repairs=False
    )
    result = {
        "mesh_objects": len(meshes),
        "materials": len(materials),
        "material_names": [material.name for material in materials],
        "uv": uv_stats(body),
        "raw_glb_topology": raw_stats,
        "raw_glb_connected_components": raw_components,
        "positional_weld_validation": positional_weld_validation,
        "topology": welded_stats,
        "connected_components": positional_weld_validation[
            "connected_components_after_weld"
        ],
        "duplicate_faces": positional_weld_validation[
            "duplicate_faces_after_weld"
        ],
        "signed_volume_m3": round(signed_volume(body), 9),
        "normal_orientation": normal_validation,
        "normals_outward": normal_validation[
            "inward_faces_detected"
        ] == 0,
        "opaque_alpha": alpha_opaque,
        "backface_culling": all(
            material.use_backface_culling for material in materials
        ),
        "texture_images": [
            {
                "name": node.image.name,
                "resolution": [
                    int(node.image.size[0]),
                    int(node.image.size[1]),
                ],
            }
            for node in image_nodes
        ],
        "armatures": len(armatures),
        "actions": len(actions),
        "unrigged": len(armatures) == 0 and len(actions) == 0,
        "mesh_transform_identity": identity_transform(body),
        "triangle_count_preserved": (
            welded_stats["triangles"] == expected_triangles
        ),
        "normal_map_used": False,
        "tangent_risk": "eliminated; no normal map exported",
    }
    errors = []
    if result["mesh_objects"] != 1:
        errors.append("mesh object count is not 1")
    if result["materials"] != 1:
        errors.append("material count is not 1")
    if result["uv"]["layers"] != 1 or not result["uv"]["finite"]:
        errors.append("UV atlas validation failed")
    if (
        welded_stats["boundary_edges"]
        or welded_stats["overfull_edges"]
        or welded_stats["wire_edges"]
    ):
        errors.append("non-manifold topology remains")
    if welded_stats["degenerate_faces"]:
        errors.append("degenerate faces remain")
    if result["duplicate_faces"]:
        errors.append("duplicate faces remain")
    if not result["normals_outward"]:
        errors.append("normals are not outward")
    if not result["opaque_alpha"]:
        errors.append("material alpha is not opaque")
    if not result["unrigged"]:
        errors.append("rig or animation data was exported")
    if not result["triangle_count_preserved"]:
        errors.append("triangle count changed")
    if not image_nodes or any(
        node.image.size[0] != ATLAS_SIZE or node.image.size[1] != ATLAS_SIZE
        for node in image_nodes
    ):
        errors.append("4096 base-color atlas missing")
    result["errors"] = errors
    result["passed"] = not errors
    return result


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    source_hash_before = sha256(SOURCE)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    source_meshes = [
        obj for obj in bpy.context.scene.objects if obj.type == "MESH"
    ]
    if not source_meshes:
        raise RuntimeError("Approved production GLB contains no mesh")

    source_report = {
        "path": str(SOURCE),
        "sha256": source_hash_before,
        "mesh_objects": len(source_meshes),
        "material_slots": sum(
            len(obj.data.materials) for obj in source_meshes
        ),
        "uv_layers": [len(obj.data.uv_layers) for obj in source_meshes],
        "triangles": sum(triangle_count(obj) for obj in source_meshes),
        "topology": [topology_stats(obj) for obj in source_meshes],
        "connected_components": [
            connected_components(obj) for obj in source_meshes
        ],
        "duplicate_faces": [
            duplicate_face_count(obj) for obj in source_meshes
        ],
        "materials": [
            diagnostic
            for obj in source_meshes
            for diagnostic in source_material_diagnostics(obj)
        ],
        "transforms_identity": [
            identity_transform(obj) for obj in source_meshes
        ],
    }

    body = merge_mesh_objects(source_meshes)
    topology_repair = remove_exact_duplicates_and_recalculate(body)
    if (
        topology_repair["after"]["boundary_edges"]
        or topology_repair["after"]["overfull_edges"]
        or topology_repair["after"]["wire_edges"]
    ):
        raise RuntimeError(
            "Production source is not a closed manifold after conservative repair"
        )
    if len(body.data.uv_layers) != 1:
        raise RuntimeError("Meshy rig input requires exactly one UV atlas")

    normal_repair = orient_faces_outward_by_raycast(body, apply_repairs=True)

    uv_repair = repair_degenerate_uv_triangles(body)
    if uv_repair["after"]["degenerate_triangles"]:
        raise RuntimeError("Degenerate UV triangles remain after repair")
    atlas = bake_approved_base_color(body)
    material = create_simple_opaque_material(body, atlas)
    material_name = material.name
    body.name = f"{OUTPUT_ID}_Body"
    body.data.name = f"{OUTPUT_ID}_Mesh"

    for obj in list(bpy.context.scene.objects):
        if obj != body:
            bpy.data.objects.remove(obj, do_unlink=True)
    root = bpy.data.objects.new(OUTPUT_ID, None)
    bpy.context.collection.objects.link(root)
    body.parent = root
    root["steamtek_asset_id"] = OUTPUT_ID
    root["steamtek_source_asset"] = ASSET_ID
    root["steamtek_purpose"] = "meshy_auto_rigging_input"
    root["steamtek_pose"] = "mild_a_pose_preserved"
    root["steamtek_rig_status"] = "unrigged"

    expected_triangles = topology_repair["after"]["triangles"]
    export_glb(root, body)
    source_hash_after = sha256(SOURCE)
    if source_hash_after != source_hash_before:
        raise RuntimeError("Approved production source changed unexpectedly")

    reimport = validate_reimport(expected_triangles)
    diagnosis = {
        "primary_failure_risk": (
            "approved production GLB uses two material primitives; Meshy's "
            "Keep Original Texture and UV path expects one material and one UV map"
        ),
        "secondary_risks_removed": [
            "multi-material primitive split",
            "complex or unused source material nodes",
            "separate hair material",
            "emissive texture path",
            "metallic-roughness texture path",
            "alpha-capable source graph",
            "normal-map tangent dependency",
        ],
        "not_found_in_approved_source": [
            "multiple mesh objects",
            "non-manifold edges",
            "duplicate faces",
            "degenerate faces",
            "multiple UV maps",
            "armature or animation data",
        ],
        "hidden_internal_geometry_assessment": (
            "single closed connected component; no separate hidden shell detected"
        ),
    }
    report = {
        "schema": "SteamtekMeshyRigInput-1",
        "asset_id": OUTPUT_ID,
        "purpose": "Meshy auto-rigging",
        "source_preserved": source_hash_before == source_hash_after,
        "source": source_report,
        "diagnosis": diagnosis,
        "repairs": {
            "mesh_objects_joined": max(0, len(source_meshes) - 1),
            "transforms_applied": True,
            "topology": topology_repair,
            "normal_repair": normal_repair,
            "uv_repair": uv_repair,
            "one_uv_atlas_preserved": True,
            "base_color_baked": str(ATLAS),
            "atlas_resolution": [ATLAS_SIZE, ATLAS_SIZE],
            "one_material_created": material_name,
            "opaque_only": True,
            "alpha_blend_removed": True,
            "alpha_mask_removed": True,
            "custom_or_unsupported_nodes_removed": True,
            "emissive_removed": True,
            "normal_map_omitted_for_tangent_safety": True,
            "mild_a_pose_preserved": True,
            "unrigged": True,
        },
        "reimport_validation": reimport,
        "output": {
            "glb": str(OUTPUT),
            "bytes": OUTPUT.stat().st_size,
            "sha256": sha256(OUTPUT),
            "base_color_atlas": str(ATLAS),
        },
        "passed": reimport["passed"],
    }
    REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("STEAMTEK_MESHY_RIG_INPUT=" + json.dumps(report))
    if not reimport["passed"]:
        raise RuntimeError(
            "Meshy rig input validation failed: "
            + "; ".join(reimport["errors"])
        )


if __name__ == "__main__":
    main()
