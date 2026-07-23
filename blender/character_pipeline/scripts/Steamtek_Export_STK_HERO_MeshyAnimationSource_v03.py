"""Export a seamless original-proportion proxy for Meshy animation generation.

The output is deliberately not a production character. Meshy may auto-rig it
and generate motion clips; those clips are then retargeted onto the approved
Steamtek hero rig. A voxel-remeshed proxy avoids the many disconnected source
shells that caused Meshy's earlier auto-rigging fracture.

Run with Blender:
    blender.exe --background SOURCE.blend --python this_script.py
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
SOURCE_BLEND = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "heroes"
    / "STK_HERO_BaseBody_01_Rigged_MeshyMotion_v04.blend"
)
OUTPUT_DIR = ROOT / "output" / "meshy_animation_source"
OUTPUT_GLB = (
    OUTPUT_DIR
    / "STK_HERO_BaseBody_01_MeshyAnimationSource_NeutralPose_v03.glb"
)
OUTPUT_REPORT = OUTPUT_GLB.with_suffix(".validation.json")
BODY_NAME = "STK_HERO_BaseBody_01_RiggedBody"
ARMATURE_NAME = "STK_HERO_BaseBody_01_Armature"
PROXY_NAME = "STK_HERO_BaseBody_01_MeshyAnimationSource_NeutralPose_v03"
VOXEL_SIZE = 0.012
MAX_MESHY_TRIANGLES = 300_000


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def triangle_count(mesh: bpy.types.Mesh) -> int:
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def connected_components(mesh: bpy.types.Mesh) -> int:
    bm = bmesh.new()
    bm.from_mesh(mesh)
    remaining = set(bm.verts)
    count = 0
    while remaining:
        count += 1
        seed = remaining.pop()
        stack = [seed]
        while stack:
            vertex = stack.pop()
            for edge in vertex.link_edges:
                neighbor = edge.other_vert(vertex)
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    stack.append(neighbor)
    bm.free()
    return count


def topology_stats(mesh: bpy.types.Mesh) -> dict[str, int | float]:
    bm = bmesh.new()
    bm.from_mesh(mesh)
    stats: dict[str, int | float] = {
        "vertices": len(bm.verts),
        "edges": len(bm.edges),
        "faces": len(bm.faces),
        "triangles": triangle_count(mesh),
        "components": connected_components(mesh),
        "boundary_edges": sum(
            1 for edge in bm.edges if len(edge.link_faces) == 1
        ),
        "overfull_edges": sum(
            1 for edge in bm.edges if len(edge.link_faces) > 2
        ),
        "wire_edges": sum(
            1 for edge in bm.edges if len(edge.link_faces) == 0
        ),
        "degenerate_faces": sum(
            1 for face in bm.faces if face.calc_area() <= 1.0e-12
        ),
    }
    bm.free()
    return stats


def object_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [
        obj.matrix_world @ vertex.co for vertex in obj.data.vertices
    ]
    minimum = Vector(
        (
            min(point.x for point in points),
            min(point.y for point in points),
            min(point.z for point in points),
        )
    )
    maximum = Vector(
        (
            max(point.x for point in points),
            max(point.y for point in points),
            max(point.z for point in points),
        )
    )
    return minimum, maximum


def local_vertex_bounds(mesh: bpy.types.Mesh) -> tuple[Vector, Vector]:
    points = [vertex.co for vertex in mesh.vertices]
    minimum = Vector(
        (
            min(point.x for point in points),
            min(point.y for point in points),
            min(point.z for point in points),
        )
    )
    maximum = Vector(
        (
            max(point.x for point in points),
            max(point.y for point in points),
            max(point.z for point in points),
        )
    )
    return minimum, maximum


def set_original_neutral_pose(armature: bpy.types.Object) -> None:
    """Clear motion while preserving the approved neutral proportions."""
    armature.animation_data_clear()
    armature.data.pose_position = "POSE"
    for pose_bone in armature.pose.bones:
        pose_bone.matrix_basis.identity()
    bpy.context.view_layer.update()


def make_seamless_proxy(
    body: bpy.types.Object, armature: bpy.types.Object
) -> bpy.types.Object:
    rest_positions = [vertex.co.copy() for vertex in body.data.vertices]
    set_original_neutral_pose(armature)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated_body = body.evaluated_get(depsgraph)
    proxy_mesh = bpy.data.meshes.new_from_object(
        evaluated_body,
        preserve_all_data_layers=False,
        depsgraph=depsgraph,
    )
    if len(proxy_mesh.vertices) != len(rest_positions):
        raise RuntimeError(
            "Armature evaluation unexpectedly changed the mesh vertex count"
        )

    maximum_rest_error = max(
        (vertex.co - rest_position).length
        for vertex, rest_position in zip(proxy_mesh.vertices, rest_positions)
    )
    if maximum_rest_error > 1.0e-5:
        raise RuntimeError(
            "Neutral evaluation changed the approved proportions: "
            f"max error {maximum_rest_error}"
        )
    proxy_mesh.update()

    proxy = bpy.data.objects.new(PROXY_NAME, proxy_mesh)
    bpy.context.scene.collection.objects.link(proxy)
    proxy.matrix_world = body.matrix_world.copy()

    bpy.ops.object.select_all(action="DESELECT")
    proxy.select_set(True)
    bpy.context.view_layer.objects.active = proxy
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    while proxy.data.materials:
        proxy.data.materials.pop(index=0)
    while proxy.data.uv_layers:
        proxy.data.uv_layers.remove(proxy.data.uv_layers[0])
    while proxy.vertex_groups:
        proxy.vertex_groups.remove(proxy.vertex_groups[0])

    bm = bmesh.new()
    bm.from_mesh(proxy.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1.0e-6)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(proxy.data)
    bm.free()
    proxy.data.update()

    proxy.data.remesh_voxel_size = VOXEL_SIZE
    proxy.data.remesh_voxel_adaptivity = 0.0
    bpy.ops.object.voxel_remesh()

    bm = bmesh.new()
    bm.from_mesh(proxy.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(proxy.data)
    bm.free()
    proxy.data.update()

    minimum, maximum = local_vertex_bounds(proxy.data)
    offset = Vector(
        (
            -(minimum.x + maximum.x) * 0.5,
            -(minimum.y + maximum.y) * 0.5,
            -minimum.z,
        )
    )
    for vertex in proxy.data.vertices:
        vertex.co += offset
    proxy.data.update()

    material = bpy.data.materials.new("STK_MAT_MeshyAnimationSource_Neutral")
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (0.52, 0.56, 0.62, 1.0)
    principled.inputs["Metallic"].default_value = 0.0
    principled.inputs["Roughness"].default_value = 0.82
    proxy.data.materials.append(material)
    for polygon in proxy.data.polygons:
        polygon.material_index = 0
        polygon.use_smooth = True

    proxy["steamtek_purpose"] = (
        "Meshy animation-generation proxy; never use as the production hero"
    )
    proxy["steamtek_source_blend"] = SOURCE_BLEND.name
    proxy["steamtek_source_sha256"] = sha256(SOURCE_BLEND)
    proxy["steamtek_pose"] = "Original neutral pose"
    proxy["steamtek_front_blender"] = "-Y"
    proxy["steamtek_front_gltf"] = "+Z"
    proxy["steamtek_voxel_size_m"] = VOXEL_SIZE
    return proxy


def validate_proxy(proxy: bpy.types.Object, stage: str) -> dict:
    stats = topology_stats(proxy.data)
    minimum, maximum = object_bounds(proxy)
    dimensions = maximum - minimum
    stats["bounds_minimum"] = [float(value) for value in minimum]
    stats["bounds_maximum"] = [float(value) for value in maximum]
    stats["dimensions"] = [float(value) for value in dimensions]

    if stats["vertices"] < 1_000:
        raise RuntimeError(f"{stage}: proxy has too few vertices")
    if stats["triangles"] >= MAX_MESHY_TRIANGLES:
        raise RuntimeError(
            f"{stage}: {stats['triangles']} triangles exceeds Meshy's limit"
        )
    for key in ("boundary_edges", "overfull_edges", "wire_edges", "degenerate_faces"):
        if stats[key] != 0:
            raise RuntimeError(f"{stage}: {key}={stats[key]}")
    if stats["components"] > 8:
        raise RuntimeError(
            f"{stage}: expected at most 8 connected components, "
            f"found {stats['components']}"
        )
    if not (1.60 <= dimensions.z <= 2.00):
        raise RuntimeError(f"{stage}: implausible height {dimensions.z}")
    if dimensions.x <= 0.55:
        raise RuntimeError(
            f"{stage}: neutral-pose width is too narrow ({dimensions.x})"
        )
    if abs(minimum.z) > 1.0e-3:
        raise RuntimeError(f"{stage}: feet are not grounded ({minimum.z})")
    x_center = (minimum.x + maximum.x) * 0.5
    y_center = (minimum.y + maximum.y) * 0.5
    if abs(x_center) > 1.0e-3:
        raise RuntimeError(
            f"{stage}: model is not centered on X ({x_center})"
        )
    if abs(y_center) > 1.0e-3:
        raise RuntimeError(
            f"{stage}: model is not centered on Y ({y_center})"
        )
    return stats


def export_proxy(proxy: bpy.types.Object) -> dict:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    proxy.select_set(True)
    bpy.context.view_layer.objects.active = proxy
    requested = {
        "filepath": str(OUTPUT_GLB),
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": False,
        "export_yup": True,
        "export_materials": "EXPORT",
        "export_image_format": "AUTO",
        "export_cameras": False,
        "export_lights": False,
        "export_animations": False,
        "export_skins": False,
        "export_morph": False,
        "export_attributes": False,
        "export_extras": True,
        "export_texcoords": False,
        "export_normals": True,
        "export_tangents": False,
    }
    supported = {
        prop.identifier for prop in bpy.ops.export_scene.gltf.get_rna_type().properties
    }
    options = {
        key: value for key, value in requested.items() if key in supported
    }
    bpy.ops.export_scene.gltf(**options)
    if not OUTPUT_GLB.is_file():
        raise RuntimeError(f"Export was not created: {OUTPUT_GLB}")
    return options


def reimport_and_validate() -> tuple[bpy.types.Object, dict]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUTPUT_GLB))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    armatures = [
        obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"
    ]
    if len(meshes) != 1:
        raise RuntimeError(f"Reimport: expected one mesh, found {len(meshes)}")
    if armatures:
        raise RuntimeError(f"Reimport: found {len(armatures)} armatures")
    if bpy.data.actions:
        raise RuntimeError(f"Reimport: found {len(bpy.data.actions)} animations")
    mesh = meshes[0]
    if len([material for material in mesh.data.materials if material]) != 1:
        raise RuntimeError("Reimport: expected one neutral material")
    if mesh.data.uv_layers:
        raise RuntimeError("Reimport: neutral motion proxy should not contain UVs")
    return mesh, validate_proxy(mesh, "Reimport")


def main() -> None:
    if Path(bpy.data.filepath).resolve() != SOURCE_BLEND.resolve():
        raise RuntimeError(
            f"Open the approved v04 source blend before running: {SOURCE_BLEND}"
        )

    body = bpy.data.objects[BODY_NAME]
    armature = bpy.data.objects[ARMATURE_NAME]
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action, do_unlink=True)

    proxy = make_seamless_proxy(body, armature)
    pre_export_stats = validate_proxy(proxy, "Pre-export")
    export_options = export_proxy(proxy)
    _reimported, reimport_stats = reimport_and_validate()

    report = {
        "schema": "SteamtekMeshyAnimationSourceValidation-3",
        "status": "pass",
        "purpose": (
            "Seamless original-proportion proxy for Meshy motion generation only"
        ),
        "warning": (
            "Do not use this proxy as the production hero. Retarget downloaded "
            "Meshy motion onto the approved v04 rig."
        ),
        "source_blend": str(SOURCE_BLEND),
        "source_sha256": sha256(SOURCE_BLEND),
        "output_glb": str(OUTPUT_GLB),
        "output_sha256": sha256(OUTPUT_GLB),
        "bytes": OUTPUT_GLB.stat().st_size,
        "pose": "Original neutral pose",
        "front_axis_gltf": "+Z",
        "voxel_size_m": VOXEL_SIZE,
        "animations": [],
        "armatures": 0,
        "uv_layers": 0,
        "pre_export": pre_export_stats,
        "reimport": reimport_stats,
        "export_options": export_options,
        "meshy_upload_setting": "Keep Original Texture and UV = OFF",
    }
    OUTPUT_REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print("STATUS=PASSED")
    print(f"OUTPUT_GLB={OUTPUT_GLB}")
    print(f"OUTPUT_REPORT={OUTPUT_REPORT}")
    print(f"SHA256={report['output_sha256']}")
    print(f"BYTES={report['bytes']}")
    print(f"VERTICES={reimport_stats['vertices']}")
    print(f"TRIANGLES={reimport_stats['triangles']}")
    print(f"COMPONENTS={reimport_stats['components']}")
    print(f"DIMENSIONS={reimport_stats['dimensions']}")
    print("ARMATURES=0")
    print("ANIMATIONS=0")
    print("UV_LAYERS=0")
    print("MESHY_KEEP_ORIGINAL_TEXTURE_AND_UV=OFF")


main()
