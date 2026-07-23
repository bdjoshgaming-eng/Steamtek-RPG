"""Inspect one or more character GLB files in Blender without modifying them.

Run with Blender:
    blender.exe --background --python inspect_character_glb.py -- model.glb [...]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def triangle_count(mesh: bpy.types.Mesh) -> int:
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def world_bounds(objects: list[bpy.types.Object]) -> dict[str, list[float] | float]:
    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in objects
        if obj.type == "MESH"
        for corner in obj.bound_box
    ]
    if not corners:
        return {}
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
    size = maximum - minimum
    return {
        "minimum": [round(value, 6) for value in minimum],
        "maximum": [round(value, 6) for value in maximum],
        "size": [round(value, 6) for value in size],
        "height_m": round(size.z, 6),
    }


def inspect(path: Path) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))

    objects = list(bpy.context.scene.objects)
    meshes = [obj for obj in objects if obj.type == "MESH"]
    armatures = [obj for obj in objects if obj.type == "ARMATURE"]
    materials = sorted(
        {
            slot.material.name
            for obj in meshes
            for slot in obj.material_slots
            if slot.material is not None
        }
    )

    result = {
        "path": str(path),
        "file_size_bytes": path.stat().st_size,
        "bounds_blender_world": world_bounds(meshes),
        "object_count": len(objects),
        "mesh_count": len(meshes),
        "total_vertices": sum(len(obj.data.vertices) for obj in meshes),
        "total_triangles": sum(triangle_count(obj.data) for obj in meshes),
        "material_count": len(materials),
        "materials": materials,
        "images": [
            {
                "name": image.name,
                "size": [int(image.size[0]), int(image.size[1])],
                "packed": image.packed_file is not None,
                "filepath": image.filepath,
            }
            for image in bpy.data.images
            if image.name != "Render Result"
        ],
        "armatures": [
            {
                "name": armature.name,
                "bones": len(armature.data.bones),
                "scale": [round(value, 6) for value in armature.scale],
            }
            for armature in armatures
        ],
        "actions": [
            {
                "name": action.name,
                "frame_range": [
                    round(float(action.frame_range[0]), 3),
                    round(float(action.frame_range[1]), 3),
                ],
            }
            for action in bpy.data.actions
        ],
        "meshes": [],
    }

    for obj in meshes:
        result["meshes"].append(
            {
                "name": obj.name,
                "vertices": len(obj.data.vertices),
                "triangles": triangle_count(obj.data),
                "uv_layers": len(obj.data.uv_layers),
                "materials": [
                    slot.material.name
                    for slot in obj.material_slots
                    if slot.material is not None
                ],
                "vertex_groups": len(obj.vertex_groups),
                "armature_modifiers": [
                    modifier.object.name
                    for modifier in obj.modifiers
                    if modifier.type == "ARMATURE" and modifier.object is not None
                ],
                "location": [round(value, 6) for value in obj.location],
                "rotation_euler": [round(value, 6) for value in obj.rotation_euler],
                "scale": [round(value, 6) for value in obj.scale],
            }
        )
    return result


def main() -> int:
    arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    if not arguments:
        raise SystemExit("Pass at least one GLB path after --")
    reports = [inspect(Path(argument).resolve()) for argument in arguments]
    print("STEAMTEK_CHARACTER_INSPECTION=" + json.dumps(reports, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
