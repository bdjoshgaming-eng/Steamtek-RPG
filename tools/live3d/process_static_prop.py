"""Validate, normalize, and export a static Meshy prop for Steamtek live 3D.

Run with Blender in background mode. Blender owns all mesh and GLB operations;
the generated Godot wrapper owns simplified box collision and snap metadata.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--qa", required=True)
    parser.add_argument("--wrapper", required=True)
    parser.add_argument("--asset-name", required=True)
    parser.add_argument("--target-width", type=float, required=True)
    parser.add_argument("--target-depth", type=float, required=True)
    parser.add_argument("--target-height", type=float, required=True)
    parser.add_argument("--source-triangle-target", type=int, default=0)
    return parser.parse_args(argv)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.cameras,
        bpy.data.lights,
        bpy.data.armatures,
        bpy.data.materials,
        bpy.data.images,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def mesh_triangles(obj: bpy.types.Object) -> int:
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points: list[Vector] = []
    for obj in objects:
        points.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    if not points:
        raise RuntimeError("No mesh bounds were available")
    minimum = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maximum = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return minimum, maximum


def dimensions(objects: list[bpy.types.Object]) -> Vector:
    minimum, maximum = world_bounds(objects)
    return maximum - minimum


def vec(values: Vector | tuple[float, float, float]) -> list[float]:
    return [round(float(v), 6) for v in values]


def material_snapshot(objects: list[bpy.types.Object]) -> dict:
    materials: dict[str, dict] = {}
    images: dict[str, dict] = {}
    uv_layers = 0
    for obj in objects:
        uv_layers += len(obj.data.uv_layers)
        for slot in obj.material_slots:
            material = slot.material
            if not material:
                continue
            entry = materials.setdefault(material.name, {"uses_nodes": material.use_nodes, "images": []})
            if material.use_nodes and material.node_tree:
                for node in material.node_tree.nodes:
                    image = getattr(node, "image", None)
                    if not image:
                        continue
                    if image.name not in entry["images"]:
                        entry["images"].append(image.name)
                    images[image.name] = {
                        "size": [int(image.size[0]), int(image.size[1])],
                        "packed": bool(image.packed_file),
                        "source": image.source,
                        "filepath": image.filepath,
                    }
    return {
        "materials": materials,
        "images": images,
        "uv_layer_count": uv_layers,
    }


def detach_and_apply_world_transforms(objects: list[bpy.types.Object]) -> None:
    for obj in objects:
        matrix = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = matrix
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def join_meshes(objects: list[bpy.types.Object], asset_name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = max(objects, key=mesh_triangles)
    if len(objects) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = asset_name
    obj.data.name = f"{asset_name}_Mesh"
    return obj


def connected_face_components(bm: bmesh.types.BMesh) -> list[list[bmesh.types.BMFace]]:
    remaining = set(bm.faces)
    components: list[list[bmesh.types.BMFace]] = []
    while remaining:
        seed = remaining.pop()
        component = [seed]
        stack = [seed]
        while stack:
            face = stack.pop()
            for edge in face.edges:
                for neighbor in edge.link_faces:
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        component.append(neighbor)
                        stack.append(neighbor)
        components.append(component)
    return components


def clean_mesh(obj: bpy.types.Object) -> dict:
    mesh = obj.data
    before_vertices = len(mesh.vertices)
    before_edges = len(mesh.edges)
    before_faces = len(mesh.polygons)
    before_triangles = mesh_triangles(obj)

    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    bm.faces.ensure_lookup_table()

    max_dimension = max(float(v) for v in obj.dimensions)
    merge_distance = max(max_dimension * 1.0e-7, 1.0e-8)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=merge_distance)

    loose_edges = [edge for edge in bm.edges if not edge.link_faces]
    loose_vertices = [vert for vert in bm.verts if not vert.link_edges and not vert.link_faces]
    loose_edge_count = len(loose_edges)
    loose_vertex_count = len(loose_vertices)
    if loose_edges:
        bmesh.ops.delete(bm, geom=loose_edges, context="EDGES")
    if loose_vertices:
        bmesh.ops.delete(bm, geom=loose_vertices, context="VERTS")

    bm.faces.ensure_lookup_table()
    components_before = connected_face_components(bm)
    total_area = sum(face.calc_area() for face in bm.faces)
    removed_components = 0
    removed_component_faces = 0
    # Only eliminate microscopic islands. Larger disconnected pieces may be
    # intentional hard-surface trim and are preserved for visual fidelity.
    for component in components_before:
        area = sum(face.calc_area() for face in component)
        if len(component) <= 2 and area <= max(total_area * 1.0e-7, 1.0e-10):
            removed_components += 1
            removed_component_faces += len(component)
            bmesh.ops.delete(bm, geom=component, context="FACES")

    bm.faces.ensure_lookup_table()
    if bm.faces:
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))

    boundary_edges = sum(1 for edge in bm.edges if len(edge.link_faces) == 1)
    nonmanifold_edges = sum(1 for edge in bm.edges if len(edge.link_faces) != 2)
    zero_area_faces = sum(1 for face in bm.faces if face.calc_area() <= 1.0e-12)
    components_after = connected_face_components(bm)

    bm.to_mesh(mesh)
    bm.free()
    mesh.update(calc_edges=True)

    return {
        "before": {
            "vertices": before_vertices,
            "edges": before_edges,
            "faces": before_faces,
            "triangles": before_triangles,
        },
        "after": {
            "vertices": len(mesh.vertices),
            "edges": len(mesh.edges),
            "faces": len(mesh.polygons),
            "triangles": mesh_triangles(obj),
        },
        "merge_distance_m": merge_distance,
        "merged_vertices": before_vertices - len(mesh.vertices),
        "removed_loose_vertices": loose_vertex_count,
        "removed_loose_edges": loose_edge_count,
        "components_before": len(components_before),
        "components_after": len(components_after),
        "removed_microscopic_components": removed_components,
        "removed_microscopic_faces": removed_component_faces,
        "boundary_edges": boundary_edges,
        "nonmanifold_edges": nonmanifold_edges,
        "zero_area_faces": zero_area_faces,
    }


def scale_to_target(obj: bpy.types.Object, target: Vector) -> dict:
    current = dimensions([obj])
    if min(current) <= 0:
        raise RuntimeError(f"Invalid source dimensions: {vec(current)}")
    factors = Vector((target.x / current.x, target.y / current.y, target.z / current.z))
    obj.scale = factors
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return {"source_dimensions": vec(current), "scale_factors": vec(factors)}


def set_bottom_center_origin(obj: bpy.types.Object) -> dict:
    minimum, maximum = world_bounds([obj])
    center = Vector(((minimum.x + maximum.x) / 2, (minimum.y + maximum.y) / 2, minimum.z))
    obj.data.transform(Matrix.Translation(-center))
    obj.location = (0, 0, 0)
    obj.rotation_euler = (0, 0, 0)
    obj.scale = (1, 1, 1)
    obj.data.update()
    final_minimum, final_maximum = world_bounds([obj])
    return {
        "source_bottom_center": vec(center),
        "final_minimum": vec(final_minimum),
        "final_maximum": vec(final_maximum),
        "origin": vec(obj.location),
    }


def remove_animation_and_rig_data() -> dict:
    armatures = [obj.name for obj in bpy.data.objects if obj.type == "ARMATURE"]
    actions = [action.name for action in bpy.data.actions]
    for obj in bpy.data.objects:
        obj.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for obj in list(bpy.data.objects):
        if obj.type == "ARMATURE":
            bpy.data.objects.remove(obj, do_unlink=True)
    return {"removed_armatures": armatures, "removed_actions": actions}


def export_glb(obj: bpy.types.Object, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_tangents=True,
        export_materials="EXPORT",
        export_animations=False,
        export_skins=False,
        export_morph=False,
        export_yup=True,
    )


def validate_export(output: Path) -> dict:
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(output))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Exported GLB did not contain a mesh")
    snapshot = material_snapshot(meshes)
    minimum, maximum = world_bounds(meshes)
    armatures = [obj.name for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    return {
        "mesh_objects": len(meshes),
        "dimensions_m_blender_xyz": vec(maximum - minimum),
        "minimum_m_blender_xyz": vec(minimum),
        "maximum_m_blender_xyz": vec(maximum),
        "triangles": sum(mesh_triangles(obj) for obj in meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "materials": sorted(snapshot["materials"]),
        "images": snapshot["images"],
        "uv_layer_count": snapshot["uv_layer_count"],
        "armatures": armatures,
        "actions": [action.name for action in bpy.data.actions],
        "object_transforms": {
            obj.name: {
                "location": vec(obj.location),
                "rotation_euler": vec(obj.rotation_euler),
                "scale": vec(obj.scale),
            }
            for obj in meshes
        },
    }


def godot_float(value: float) -> str:
    if abs(value) < 1.0e-8:
        return "0"
    return f"{value:.6f}".rstrip("0").rstrip(".")


def godot_vec(x: float, y: float, z: float) -> str:
    return f"Vector3({godot_float(x)}, {godot_float(y)}, {godot_float(z)})"


def res_path(path: Path) -> str:
    root = Path.cwd().resolve()
    return "res://" + path.resolve().relative_to(root).as_posix()


def write_wrapper(path: Path, model: Path, asset_name: str, width: float, depth: float, height: float) -> None:
    arm_width = min(0.24, width * 0.12)
    back_depth = min(0.20, depth * 0.24)
    base_height = min(0.46, height * 0.52)
    upper_height = height - base_height
    back_z = -depth / 2 + back_depth / 2
    arm_x = width / 2 - arm_width / 2
    upper_y = base_height + upper_height / 2
    text = f'''[gd_scene load_steps=5 format=3]

[ext_resource type="PackedScene" path="{res_path(model)}" id="1_model"]

[sub_resource type="BoxShape3D" id="BaseShape"]
size = {godot_vec(width, base_height, depth)}

[sub_resource type="BoxShape3D" id="BackShape"]
size = {godot_vec(width, upper_height, back_depth)}

[sub_resource type="BoxShape3D" id="ArmShape"]
size = {godot_vec(arm_width, upper_height, depth)}

[node name="{asset_name}" type="Node3D" groups=["steamtek_live3d_modular"]]
metadata/module_system = "live3d_meter_v1"
metadata/module_family = "static_environment_prop_furniture"
metadata/module_variant = "{asset_name}"
metadata/module_dimensions_m = {godot_vec(width, height, depth)}
metadata/contact_pivot = "floor_center"
metadata/front_axis = "+Z_toward_room_and_c001"
metadata/scale_contract = "1_godot_unit_equals_1_meter"
metadata/collision_contract = "four_simplified_box_shapes_not_render_mesh"

[node name="Visual" parent="." instance=ExtResource("1_model")]

[node name="StaticBody" type="StaticBody3D" parent="."]
collision_layer = 1
collision_mask = 0

[node name="BaseCollision" type="CollisionShape3D" parent="StaticBody"]
position = {godot_vec(0, base_height / 2, 0)}
shape = SubResource("BaseShape")

[node name="BackCollision" type="CollisionShape3D" parent="StaticBody"]
position = {godot_vec(0, upper_y, back_z)}
shape = SubResource("BackShape")

[node name="LeftArmCollision" type="CollisionShape3D" parent="StaticBody"]
position = {godot_vec(-arm_x, upper_y, 0)}
shape = SubResource("ArmShape")

[node name="RightArmCollision" type="CollisionShape3D" parent="StaticBody"]
position = {godot_vec(arm_x, upper_y, 0)}
shape = SubResource("ArmShape")

[node name="Sockets" type="Node3D" parent="."]

[node name="LeftFurniture" type="Marker3D" parent="Sockets" groups=["steamtek_live3d_snap"]]
position = {godot_vec(-width / 2, 0, 0)}
metadata/socket_role = "furniture_chain"

[node name="RightFurniture" type="Marker3D" parent="Sockets" groups=["steamtek_live3d_snap"]]
position = {godot_vec(width / 2, 0, 0)}
metadata/socket_role = "furniture_chain"
'''
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def markdown_report(report: dict) -> str:
    source = report["source"]
    cleanup = report["cleanup"]
    final = report["export_validation"]
    checks = report["checks"]
    lines = [
        f'# {report["asset_name"]} QA',
        "",
        "## Result",
        "",
        f'**{report["result"]}**',
        "",
        f'- Source: `{source["path"]}`',
        f'- Production GLB: `{report["output"]}`',
        f'- Godot collision wrapper: `{report["wrapper"]}`',
        '- Scale contract: `1 Godot unit = 1 meter`',
        '- Pivot contract: bottom center, floor contact at ground level',
        "",
        "## Dimensions",
        "",
        "Blender uses X width, Y depth, Z height. Godot imports this as X width, Z depth, Y height.",
        "",
        f'- Source bounds: `{source["dimensions_m_blender_xyz"]}`',
        f'- Target bounds: `{report["target_dimensions_m_blender_xyz"]}`',
        f'- Exported bounds: `{final["dimensions_m_blender_xyz"]}`',
        f'- Exported minimum: `{final["minimum_m_blender_xyz"]}`',
        f'- Applied axis scale factors: `{report["scaling"]["scale_factors"]}`',
        "",
        "## Geometry",
        "",
        f'- Source mesh objects: `{source["mesh_objects"]}`',
        f'- Source vertices: `{source["vertices"]}`',
        f'- Source triangles: `{source["triangles"]}`',
        f'- Exported mesh objects: `{final["mesh_objects"]}`',
        f'- Exported vertices: `{final["vertices"]}`',
        f'- Exported triangles: `{final["triangles"]}`',
        f'- Vertices merged at tolerance: `{cleanup["merged_vertices"]}`',
        f'- Loose vertices removed: `{cleanup["removed_loose_vertices"]}`',
        f'- Loose edges removed: `{cleanup["removed_loose_edges"]}`',
        f'- Microscopic disconnected components removed: `{cleanup["removed_microscopic_components"]}`',
        f'- Connected components preserved: `{cleanup["components_after"]}`',
        f'- Boundary edges after cleanup: `{cleanup["boundary_edges"]}`',
        f'- Non-manifold edges after cleanup: `{cleanup["nonmanifold_edges"]}`',
        f'- Zero-area faces after cleanup: `{cleanup["zero_area_faces"]}`',
        "",
        "Disconnected components larger than the microscopic threshold were preserved because they may be intentional hard-surface frame details.",
        "",
        "## Materials and UVs",
        "",
        f'- Source materials: `{", ".join(source["materials"]) or "none"}`',
        f'- Exported materials: `{", ".join(final["materials"]) or "none"}`',
        f'- Source UV layers: `{source["uv_layer_count"]}`',
        f'- Exported UV layers: `{final["uv_layer_count"]}`',
        f'- Exported embedded/referenced images: `{len(final["images"])}`',
        "",
        "## Rig and animation",
        "",
        f'- Source armatures removed: `{len(report["rig_animation"]["removed_armatures"])}`',
        f'- Source actions removed: `{len(report["rig_animation"]["removed_actions"])}`',
        f'- Exported armatures: `{len(final["armatures"])}`',
        f'- Exported actions: `{len(final["actions"])}`',
        "",
        "## Collision",
        "",
        "The production GLB contains render geometry only. The companion Godot wrapper implements four simplified box shapes:",
        "",
        "- One full footprint/base box",
        "- One rear/backrest box",
        "- One left arm box",
        "- One right arm box",
        "",
        "The detailed render mesh is not used for physics collision.",
        "",
        "## Validation checks",
        "",
    ]
    for name, check in checks.items():
        lines.append(f'- {"PASS" if check["passed"] else "FAIL"}: {name} — {check["detail"]}')
    lines.extend(["", "## Warnings", ""])
    if report["warnings"]:
        lines.extend(f"- {warning}" for warning in report["warnings"])
    else:
        lines.append("- None.")
    lines.extend([
        "",
        "## Notes",
        "",
        "- Normals were recalculated consistently after conservative cleanup.",
        "- Existing material assignments, texture-node references, and UV layers were retained through Blender import/export.",
        "- The pipeline deliberately avoided aggressive decimation or automatic removal of meaningful disconnected trim pieces.",
        "- Blender successfully re-imported the finished GLB. A normal Godot editor import remains a separate approval gate.",
        "- Visual approval must still occur in the normal Godot editor/gameplay camera.",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    source_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()
    qa_path = Path(args.qa).resolve()
    wrapper_path = Path(args.wrapper).resolve()
    target = Vector((args.target_width, args.target_depth, args.target_height))

    if not source_path.is_file():
        raise FileNotFoundError(source_path)

    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(source_path))
    all_objects = list(bpy.context.scene.objects)
    meshes = [obj for obj in all_objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Source GLB contains no mesh objects")

    source_snapshot = material_snapshot(meshes)
    source_dimensions = dimensions(meshes)
    source_info = {
        "path": str(source_path),
        "file_size_bytes": source_path.stat().st_size,
        "mesh_objects": len(meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": sum(mesh_triangles(obj) for obj in meshes),
        "dimensions_m_blender_xyz": vec(source_dimensions),
        "materials": sorted(source_snapshot["materials"]),
        "images": source_snapshot["images"],
        "uv_layer_count": source_snapshot["uv_layer_count"],
        "armatures": [obj.name for obj in all_objects if obj.type == "ARMATURE"],
        "actions": [action.name for action in bpy.data.actions],
    }

    rig_animation = remove_animation_and_rig_data()
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    detach_and_apply_world_transforms(meshes)
    obj = join_meshes(meshes, args.asset_name)
    scaling = scale_to_target(obj, target)
    cleanup = clean_mesh(obj)
    pivot = set_bottom_center_origin(obj)
    obj["steamtek_asset_id"] = args.asset_name
    obj["asset_type"] = "static_environment_prop_furniture"
    obj["unit_contract"] = "1_godot_unit_equals_1_meter"
    obj["contact_pivot"] = "bottom_center"
    obj["front_axis"] = "+Y_in_blender_maps_to_+Z_in_godot"

    export_glb(obj, output_path)
    if not output_path.is_file():
        raise RuntimeError("Blender export did not create the production GLB")
    write_wrapper(wrapper_path, output_path, args.asset_name, args.target_width, args.target_depth, args.target_height)
    exported = validate_export(output_path)

    tolerance = 0.002
    exported_dimensions = Vector(exported["dimensions_m_blender_xyz"])
    transform_values = list(exported["object_transforms"].values())
    checks = {
        "Production GLB exists": {
            "passed": output_path.is_file() and output_path.stat().st_size > 0,
            "detail": f"{output_path.stat().st_size} bytes",
        },
        "Dimensions match target within 2 mm": {
            "passed": all(abs(exported_dimensions[i] - target[i]) <= tolerance for i in range(3)),
            "detail": f"target {vec(target)}, exported {vec(exported_dimensions)}",
        },
        "Bottom-center pivot and ground contact": {
            "passed": abs(exported["minimum_m_blender_xyz"][2]) <= 0.0001,
            "detail": f"exported minimum Z {exported['minimum_m_blender_xyz'][2]} m",
        },
        "Applied object transforms": {
            "passed": all(
                max(abs(v) for v in values["location"]) <= 0.0001
                and max(abs(v) for v in values["rotation_euler"]) <= 0.0001
                and max(abs(values["scale"][i] - 1.0) for i in range(3)) <= 0.0001
                for values in transform_values
            ),
            "detail": json.dumps(exported["object_transforms"], sort_keys=True),
        },
        "No rig or animation": {
            "passed": not exported["armatures"] and not exported["actions"],
            "detail": f"armatures {exported['armatures']}, actions {exported['actions']}",
        },
        "Material assignments preserved": {
            "passed": bool(exported["materials"]) and len(source_info["materials"]) == len(exported["materials"]),
            "detail": f"source slots {source_info['materials']}, exported slots {exported['materials']}",
        },
        "Embedded texture payload preserved": {
            "passed": (
                len(source_info["images"]) == len(exported["images"])
                and sorted(tuple(image["size"]) for image in source_info["images"].values())
                == sorted(tuple(image["size"]) for image in exported["images"].values())
            ),
            "detail": f"source images {source_info['images']}, exported images {exported['images']}",
        },
        "UVs preserved": {
            "passed": source_info["uv_layer_count"] > 0 and exported["uv_layer_count"] > 0,
            "detail": f"source {source_info['uv_layer_count']}, exported {exported['uv_layer_count']}",
        },
        "Triangle count remains near source": {
            "passed": abs(exported["triangles"] - source_info["triangles"]) <= max(32, math.ceil(source_info["triangles"] * 0.01)),
            "detail": f"source {source_info['triangles']}, exported {exported['triangles']}",
        },
        "Zero-area faces removed": {
            "passed": cleanup["zero_area_faces"] == 0,
            "detail": f"{cleanup['zero_area_faces']} zero-area faces",
        },
        "Simplified collision wrapper exists": {
            "passed": wrapper_path.is_file() and "four_simplified_box_shapes" in wrapper_path.read_text(encoding="utf-8"),
            "detail": str(wrapper_path),
        },
    }
    if args.source_triangle_target:
        checks["Requested triangle budget"] = {
            "passed": abs(exported["triangles"] - args.source_triangle_target) <= max(250, math.ceil(args.source_triangle_target * 0.05)),
            "detail": f"requested approximately {args.source_triangle_target}, exported {exported['triangles']}",
        }

    warnings: list[str] = []
    if cleanup["nonmanifold_edges"]:
        warnings.append(
            f'{cleanup["nonmanifold_edges"]} non-manifold edges remain after conservative repair. '
            "They were preserved because automatic filling could alter visible frame openings, UVs, or silhouette."
        )
    if cleanup["boundary_edges"]:
        warnings.append(
            f'{cleanup["boundary_edges"]} boundary edges remain; review the production mesh visually before final promotion.'
        )
    if cleanup["components_after"] > 1:
        warnings.append(
            f'{cleanup["components_after"]} connected mesh components remain. '
            "No microscopic floating component met the safe-removal threshold; disconnected hard-surface details were retained."
        )
    passed = all(check["passed"] for check in checks.values())
    report = {
        "asset_name": args.asset_name,
        "result": "PASS WITH WARNINGS" if passed and warnings else ("PASS" if passed else "FAIL"),
        "source": source_info,
        "target_dimensions_m_blender_xyz": vec(target),
        "scaling": scaling,
        "cleanup": cleanup,
        "pivot": pivot,
        "rig_animation": rig_animation,
        "output": str(output_path),
        "wrapper": str(wrapper_path),
        "export_validation": exported,
        "checks": checks,
        "warnings": warnings,
    }
    qa_path.parent.mkdir(parents=True, exist_ok=True)
    qa_path.write_text(markdown_report(report), encoding="utf-8", newline="\n")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if passed else 2


if __name__ == "__main__":
    raise SystemExit(main())
