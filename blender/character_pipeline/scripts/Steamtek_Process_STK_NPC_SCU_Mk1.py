"""Build the production Steamtek SCU Mk1 enemy from its Meshy GLB.

The source art remains untouched. This script creates a normalized, grounded,
shared-rig Blender source, three explicit LOD meshes, a Godot-ready GLB, and a
machine-readable production report.
"""

from __future__ import annotations

import bmesh
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ASSET_ID = "STK_NPC_SCU_Mk1"
PROJECT_ROOT = Path(__file__).resolve().parents[3]
SOURCE = PROJECT_ROOT / "incoming" / "meshy_enemy_npc" / f"{ASSET_ID}.glb"
C001_SOURCE = (
    PROJECT_ROOT
    / "assets"
    / "characters"
    / "humanoid"
    / "base"
    / "STK_C001_Protagonist"
    / "v01"
    / "STK_C001_Protagonist_RigAnim_v01.glb"
)
OUTPUT = (
    PROJECT_ROOT
    / "assets"
    / "characters"
    / "humanoid"
    / "base"
    / ASSET_ID
    / "v01"
    / f"{ASSET_ID}.glb"
)
BLEND_OUTPUT = (
    PROJECT_ROOT
    / "blender"
    / "character_pipeline"
    / "enemies"
    / f"{ASSET_ID}.blend"
)
REPORT_OUTPUT = (
    PROJECT_ROOT
    / "docs"
    / "reviews"
    / "characters"
    / ASSET_ID
    / f"{ASSET_ID}_Production_Report.json"
)

PHYSICAL_HEIGHT_METERS = 1.8288
C001_VISUAL_SCALE = 1.075765
INTERNAL_HEIGHT_METERS = PHYSICAL_HEIGHT_METERS / C001_VISUAL_SCALE
LOD_TARGETS = {
    "LOD0": 18000,
    "LOD1": 10000,
    "LOD2": 4500,
}
LOD_RANGES = {
    "LOD0": (16000, 20000),
    "LOD1": (8000, 12000),
    "LOD2": (3000, 6000),
}

BONE_ALIASES = {
    "head": ("head", "mixamorig:head"),
    "hand.L": ("hand.l", "lefthand", "left_hand", "mixamorig:lefthand"),
    "hand.R": ("hand.r", "righthand", "right_hand", "mixamorig:righthand"),
    "chest": (
        "chest",
        "spine1",
        "spine2",
        "spine01",
        "spine02",
        "mixamorig:spine1",
        "mixamorig:spine2",
    ),
}
SOCKETS = {
    "SOCKET_Head": "head",
    "SOCKET_Hand_R": "hand.R",
    "SOCKET_Hand_L": "hand.L",
    "SOCKET_Back": "chest",
}


def triangle_count(obj: bpy.types.Object) -> int:
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def object_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
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


def transform_source_to_contract(obj: bpy.types.Object) -> dict:
    minimum, maximum = object_bounds(obj)
    original_size = maximum - minimum
    scale_factor = INTERNAL_HEIGHT_METERS / original_size.z
    obj.scale *= scale_factor
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.select_set(False)

    minimum, maximum = object_bounds(obj)
    obj.location += Vector(
        (
            -(minimum.x + maximum.x) * 0.5,
            -(minimum.y + maximum.y) * 0.5,
            -minimum.z,
        )
    )
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    obj.select_set(False)
    minimum, maximum = object_bounds(obj)
    return {
        "source_size_m": [round(value, 6) for value in original_size],
        "internal_scale_factor": scale_factor,
        "internal_bounds_m": {
            "minimum": [round(value, 6) for value in minimum],
            "maximum": [round(value, 6) for value in maximum],
            "size": [round(value, 6) for value in maximum - minimum],
        },
        "physical_height_m": PHYSICAL_HEIGHT_METERS,
        "godot_visual_scale": C001_VISUAL_SCALE,
    }


def clean_mesh(obj: bpy.types.Object) -> dict:
    mesh = obj.data
    before_vertices = len(mesh.vertices)
    before_edges = len(mesh.edges)
    before_faces = len(mesh.polygons)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.dissolve_degenerate(bm, dist=1.0e-7, edges=list(bm.edges))
    loose_vertices = [vertex for vertex in bm.verts if not vertex.link_faces]
    loose_count = len(loose_vertices)
    if loose_vertices:
        bmesh.ops.delete(bm, geom=loose_vertices, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    removed_by_validate = mesh.validate(verbose=False, clean_customdata=False)
    mesh.update(calc_edges=True)

    bm = bmesh.new()
    bm.from_mesh(mesh)
    non_manifold_edges = sum(1 for edge in bm.edges if not edge.is_manifold)
    boundary_edges = sum(1 for edge in bm.edges if edge.is_boundary)
    bm.free()
    return {
        "before": {
            "vertices": before_vertices,
            "edges": before_edges,
            "faces": before_faces,
        },
        "after": {
            "vertices": len(mesh.vertices),
            "edges": len(mesh.edges),
            "faces": len(mesh.polygons),
        },
        "loose_vertices_removed": loose_count,
        "mesh_validate_changed_data": bool(removed_by_validate),
        "non_manifold_edges_after": non_manifold_edges,
        "boundary_edges_after": boundary_edges,
        "normals_recalculated": True,
        "uv_seams_preserved": True,
        "merge_by_distance_skipped_to_preserve_uv_and_normal_seams": True,
    }


def prepare_material(obj: bpy.types.Object) -> dict:
    materials = [
        slot.material for slot in obj.material_slots if slot.material is not None
    ]
    if len(materials) != 1:
        raise RuntimeError(f"Expected one source material; found {len(materials)}")
    material = materials[0]
    material.name = "STK_MAT_SCU_BodyArmorEmissive"
    material["steamtek_surface"] = "matte_low_satin"

    if material.use_nodes and material.node_tree:
        for node in material.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            if "Roughness" in node.inputs:
                node.inputs["Roughness"].default_value = max(
                    float(node.inputs["Roughness"].default_value), 0.62
                )

    source_images = []
    for image in bpy.data.images:
        if image.name == "Render Result" or image.users == 0:
            continue
        source_images.append(image)
    texture_report = []
    for image in source_images:
        original_size = [int(image.size[0]), int(image.size[1])]
        if image.size[0] > 2048 or image.size[1] > 2048:
            image.scale(2048, 2048)
        image.name = f"{ASSET_ID}_{image.name.split('.')[0]}"
        image.pack()
        texture_report.append(
            {
                "name": image.name,
                "original_size": original_size,
                "production_size": [int(image.size[0]), int(image.size[1])],
                "packed": image.packed_file is not None,
            }
        )
    return {
        "material": material.name,
        "material_count": 1,
        "textures": texture_report,
        "roughness_floor": 0.62,
        "emission_preserved": any("emit" in image.name.lower() for image in source_images),
    }


def semantic_bone(armature: bpy.types.Object, semantic: str) -> str:
    lookup = {bone.name.lower(): bone.name for bone in armature.data.bones}
    for alias in BONE_ALIASES[semantic]:
        normalized = alias.lower()
        if normalized in lookup:
            return lookup[normalized]
        for candidate, original in lookup.items():
            suffix = candidate.rsplit(":", 1)[-1]
            if suffix == normalized or suffix.replace("_", "") == normalized.replace("_", ""):
                return original
    return ""


def transfer_shared_weights(
    target: bpy.types.Object,
    c001_body: bpy.types.Object,
    armature: bpy.types.Object,
) -> dict:
    for group in list(target.vertex_groups):
        target.vertex_groups.remove(group)
    for group in c001_body.vertex_groups:
        target.vertex_groups.new(name=group.name)

    modifier = target.modifiers.new("Steamtek_SharedRig_WeightTransfer", "DATA_TRANSFER")
    modifier.object = c001_body
    modifier.use_vert_data = True
    modifier.data_types_verts = {"VGROUP_WEIGHTS"}
    modifier.vert_mapping = "POLYINTERP_NEAREST"
    modifier.layers_vgroup_select_src = "ALL"
    modifier.layers_vgroup_select_dst = "NAME"
    bpy.context.view_layer.objects.active = target
    target.select_set(True)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    target.select_set(False)

    armature_modifier = target.modifiers.new("Steamtek_SharedHumanoidRig", "ARMATURE")
    armature_modifier.object = armature

    trimmed_influences = 0
    unweighted_vertices = 0
    maximum_influences = 0
    for vertex in target.data.vertices:
        influences = sorted(
            [
                (assignment.group, assignment.weight)
                for assignment in vertex.groups
                if assignment.weight > 1.0e-7
            ],
            key=lambda item: item[1],
            reverse=True,
        )
        if not influences:
            unweighted_vertices += 1
            continue
        maximum_influences = max(maximum_influences, len(influences))
        kept = influences[:4]
        for group_index, _weight in influences[4:]:
            target.vertex_groups[group_index].remove([vertex.index])
            trimmed_influences += 1
        total = sum(weight for _group_index, weight in kept)
        if total <= 1.0e-7:
            unweighted_vertices += 1
            continue
        for group_index, weight in kept:
            target.vertex_groups[group_index].add(
                [vertex.index], weight / total, "REPLACE"
            )
    return {
        "source_mesh": c001_body.name,
        "shared_armature": armature.name,
        "vertex_groups": len(target.vertex_groups),
        "unweighted_vertices": unweighted_vertices,
        "maximum_source_influences": maximum_influences,
        "influences_trimmed_above_four": trimmed_influences,
        "maximum_production_influences": min(maximum_influences, 4),
    }


def make_lod(source: bpy.types.Object, lod_name: str, target: int) -> bpy.types.Object:
    lod = source.copy()
    lod.data = source.data.copy()
    bpy.context.collection.objects.link(lod)
    lod.name = f"{ASSET_ID}_{lod_name}"
    lod.data.name = f"{ASSET_ID}_{lod_name}_Mesh"
    current = triangle_count(lod)
    modifier = lod.modifiers.new(f"Steamtek_{lod_name}_Reduction", "DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = min(1.0, target / current)
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = lod
    lod.select_set(True)
    bpy.ops.object.modifier_move_to_index(modifier=modifier.name, index=0)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    lod.select_set(False)
    for vertex in lod.data.vertices:
        influences = sorted(
            [
                (assignment.group, assignment.weight)
                for assignment in vertex.groups
                if assignment.weight > 1.0e-7
            ],
            key=lambda item: item[1],
            reverse=True,
        )
        kept = influences[:4]
        for group_index, _weight in influences[4:]:
            lod.vertex_groups[group_index].remove([vertex.index])
        total = sum(weight for _group_index, weight in kept)
        if total > 1.0e-7:
            for group_index, weight in kept:
                lod.vertex_groups[group_index].add(
                    [vertex.index], weight / total, "REPLACE"
                )
    lod["steamtek_lod"] = lod_name
    lod["steamtek_triangle_target"] = target
    return lod


def create_socket(
    armature: bpy.types.Object, socket_name: str, semantic: str
) -> bpy.types.Object:
    existing = bpy.data.objects.get(socket_name)
    if existing is not None:
        existing["steamtek_socket"] = True
        return existing
    bone_name = semantic_bone(armature, semantic)
    if not bone_name:
        raise RuntimeError(f"Shared armature is missing {semantic} for {socket_name}")
    socket = bpy.data.objects.new(socket_name, None)
    bpy.context.collection.objects.link(socket)
    socket.empty_display_type = "ARROWS"
    socket.empty_display_size = 0.12
    socket.parent = armature
    socket.parent_type = "BONE"
    socket.parent_bone = bone_name
    socket.matrix_parent_inverse = armature.matrix_world.inverted()
    socket["steamtek_socket"] = True
    return socket


def import_objects(path: Path) -> list[bpy.types.Object]:
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    return [obj for obj in bpy.context.scene.objects if obj not in before]


def main() -> None:
    if SOURCE.read_bytes()[:4] != b"glTF":
        raise RuntimeError(f"Source is not a standard GLB: {SOURCE}")
    if C001_SOURCE.read_bytes()[:4] != b"glTF":
        raise RuntimeError(f"C001 shared-rig source is not a standard GLB: {C001_SOURCE}")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    source_objects = import_objects(SOURCE)
    source_meshes = [obj for obj in source_objects if obj.type == "MESH"]
    if len(source_meshes) != 1:
        raise RuntimeError(f"Expected one SCU source mesh; found {len(source_meshes)}")
    source_mesh = source_meshes[0]
    source_triangle_count = triangle_count(source_mesh)
    transform_report = transform_source_to_contract(source_mesh)
    cleanup_report = clean_mesh(source_mesh)
    material_report = prepare_material(source_mesh)

    c001_objects = import_objects(C001_SOURCE)
    armatures = [obj for obj in c001_objects if obj.type == "ARMATURE"]
    if len(armatures) != 1:
        raise RuntimeError(f"Expected one C001 armature; found {len(armatures)}")
    armature = armatures[0]
    c001_meshes = [
        obj
        for obj in c001_objects
        if obj.type == "MESH"
        and any(
            modifier.type == "ARMATURE" and modifier.object == armature
            for modifier in obj.modifiers
        )
    ]
    if len(c001_meshes) != 1:
        raise RuntimeError(f"Expected one weighted C001 body; found {len(c001_meshes)}")
    c001_body = c001_meshes[0]
    weight_report = transfer_shared_weights(source_mesh, c001_body, armature)

    source_mesh.parent = c001_body.parent
    lods = {
        name: make_lod(source_mesh, name, target)
        for name, target in LOD_TARGETS.items()
    }
    for lod in lods.values():
        lod.parent = c001_body.parent

    root_candidates = [
        obj for obj in c001_objects if obj.type == "EMPTY" and obj.parent is None
    ]
    for obj in [source_mesh] + [
        obj for obj in c001_objects if obj.type == "MESH"
    ]:
        if obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    production_lods = set(lods.values())
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj not in production_lods:
            bpy.data.objects.remove(obj, do_unlink=True)

    armature.name = f"{ASSET_ID}_Rig"
    armature.data.name = f"{ASSET_ID}_Skeleton"
    armature.scale = Vector((1.0, 1.0, 1.0))
    if root_candidates:

        root = root_candidates[0]
        root.name = ASSET_ID
    else:
        root = bpy.data.objects.new(ASSET_ID, None)
        bpy.context.collection.objects.link(root)
        armature.parent = root
        for lod in lods.values():
            if lod.parent is None:
                lod.parent = root
    root["steamtek_asset_id"] = ASSET_ID
    root["steamtek_character_class"] = "regular_enemy"
    root["steamtek_physical_height_m"] = PHYSICAL_HEIGHT_METERS
    root["steamtek_godot_visual_scale"] = C001_VISUAL_SCALE
    root["steamtek_forward"] = "-Z in Godot / -Y in Blender"

    socket_objects = [
        create_socket(armature, name, semantic)
        for name, semantic in SOCKETS.items()
    ]

    lod_counts = {name: triangle_count(obj) for name, obj in lods.items()}
    animations = sorted(action.name for action in bpy.data.actions)
    required_animations = {"STK_IDLE", "STK_WALK", "STK_RUN"}
    missing_animations = sorted(required_animations.difference(animations))
    lod_errors = [
        f"{name} has {lod_counts[name]} triangles outside {minimum}-{maximum}"
        for name, (minimum, maximum) in LOD_RANGES.items()
        if not minimum <= lod_counts[name] <= maximum
    ]

    report = {
        "schema": "SteamtekRegularEnemyProduction-1",
        "asset_id": ASSET_ID,
        "source": str(SOURCE),
        "shared_rig_source": str(C001_SOURCE),
        "source_triangle_count": source_triangle_count,
        "lod_triangle_counts": lod_counts,
        "lod_targets": LOD_TARGETS,
        "material": material_report,
        "scale_and_grounding": transform_report,
        "geometry_cleanup": cleanup_report,
        "rigging": weight_report,
        "animations": animations,
        "sockets": [socket.name for socket in socket_objects],
        "forward_orientation": "-Z in Godot / -Y in Blender",
        "root_scale": [1.0, 1.0, 1.0],
        "output_glb": str(OUTPUT),
        "output_blend": str(BLEND_OUTPUT),
        "errors": lod_errors
        + ([f"Missing required locomotion animations: {missing_animations}"] if missing_animations else [])
        + (
            [f"Weight transfer left {weight_report['unweighted_vertices']} unweighted vertices"]
            if weight_report["unweighted_vertices"]
            else []
        ),
    }
    report["passed"] = not report["errors"]
    if not report["passed"]:
        REPORT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        REPORT_OUTPUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
        raise RuntimeError("Production checks failed: " + "; ".join(report["errors"]))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    BLEND_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    REPORT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUTPUT))
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT),
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=True,
        export_yup=True,
        export_apply=False,
        export_extras=True,
    )
    report["output_glb_bytes"] = OUTPUT.stat().st_size
    report["exported"] = OUTPUT.is_file()
    REPORT_OUTPUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("STEAMTEK_SCU_PRODUCTION=" + json.dumps(report))


if __name__ == "__main__":
    main()
