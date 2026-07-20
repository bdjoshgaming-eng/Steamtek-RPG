#!/usr/bin/env python3
"""Build geometry-aware recolor masks for the staged Meshy bookshelf GLB.

Run with Blender so mesh positions and UV loops are read exactly as exported. Pillow
is loaded from the bundled Codex runtime to rasterize the source 4096 px atlas.
"""

from __future__ import annotations

import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Bookshelf_A" / "staged_pipeline"
SOURCE = STAGE / "STK_PROP_Bookshelf_A_ProductionCandidate.glb"
TEXTURES = STAGE / "textures"
REGIONS = STAGE / "STK_PROP_Bookshelf_A_MaskRegions.json"


def uv_polygon(mesh: bpy.types.Mesh, polygon: bpy.types.MeshPolygon):
    uv_layer = mesh.uv_layers.active
    if uv_layer is None:
        return None
    points = []
    for loop_index in polygon.loop_indices:
        uv = uv_layer.data[loop_index].uv
        points.append((round(uv.x, 8), round(1.0 - uv.y, 8)))
    return points if len(points) >= 3 else None


def classify_face(obj: bpy.types.Object, polygon: bpy.types.MeshPolygon) -> tuple[bool, bool]:
    center = obj.matrix_world @ polygon.center
    normal = (obj.matrix_world.to_3x3() @ polygon.normal).normalized()
    x, y, z = center

    # Actual display front is Blender -Y, which exports as Godot +Z.
    outer_side = abs(x) >= 0.455
    closed_back = y >= 0.085
    top_or_crown = z >= 1.815
    cabinet_and_plinth = z <= 0.665
    frame = outer_side or closed_back or top_or_crown or cabinet_and_plinth

    shelf_levels = (0.730, 1.030, 1.335, 1.645)
    horizontal_shelf = (
        abs(x) < 0.47
        and 0.66 < z < 1.82
        and abs(normal.z) >= 0.42
    )
    shelf_front_edge = (
        abs(x) < 0.47
        and y <= -0.055
        and any(abs(z - level) <= 0.050 for level in shelf_levels)
    )
    shelf = (horizontal_shelf or shelf_front_edge) and not frame
    return frame, shelf


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))

    face_counts = {"frame": 0, "shelf": 0, "locked": 0}
    regions: dict[str, list[list[tuple[float, float]]]] = {"frame": [], "shelf": []}
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        mesh = obj.data
        for polygon in mesh.polygons:
            points = uv_polygon(mesh, polygon)
            if not points:
                continue
            is_frame, is_shelf = classify_face(obj, polygon)
            if is_frame:
                regions["frame"].append(points)
                face_counts["frame"] += 1
            elif is_shelf:
                regions["shelf"].append(points)
                face_counts["shelf"] += 1
            else:
                face_counts["locked"] += 1

    REGIONS.write_text(json.dumps({"faces": face_counts, "regions": regions}), encoding="utf-8")
    print(f"Face classification: {face_counts}")
    print(f"Wrote normalized UV regions to {REGIONS}")


if __name__ == "__main__":
    main()
