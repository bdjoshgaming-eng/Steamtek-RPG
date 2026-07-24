"""Read-only FBX inspection used by the Steamtek environment intake pipeline."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--source", action="append", default=[])
    parser.add_argument("--source-root")
    return parser.parse_args(argv)


def _rounded(values: Vector, digits: int = 6) -> list[float]:
    return [round(float(value), digits) for value in values]


def _object_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector(min(corner[i] for corner in corners) for i in range(3))
    maximum = Vector(max(corner[i] for corner in corners) for i in range(3))
    return minimum, maximum


def _local_object_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    corners = [Vector(corner) for corner in obj.bound_box]
    minimum = Vector(min(corner[i] for corner in corners) for i in range(3))
    maximum = Vector(max(corner[i] for corner in corners) for i in range(3))
    return minimum, maximum


def _probe(source: Path) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.fbx(
        filepath=str(source),
        use_custom_normals=True,
        use_image_search=False,
        use_anim=False,
        automatic_bone_orientation=False,
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender could not import {source}")

    meshes: list[dict] = []
    all_minimum: Vector | None = None
    all_maximum: Vector | None = None
    material_names: set[str] = set()
    image_paths: set[str] = set()

    for obj in sorted(bpy.context.scene.objects, key=lambda item: item.name.casefold()):
        if obj.type != "MESH":
            continue
        mesh = obj.data
        minimum, maximum = _object_bounds(obj)
        local_minimum, local_maximum = _local_object_bounds(obj)
        all_minimum = minimum.copy() if all_minimum is None else Vector(
            min(all_minimum[i], minimum[i]) for i in range(3)
        )
        all_maximum = maximum.copy() if all_maximum is None else Vector(
            max(all_maximum[i], maximum[i]) for i in range(3)
        )

        slots: list[str] = []
        for slot in obj.material_slots:
            if slot.material is None:
                slots.append("")
                continue
            slots.append(slot.material.name)
            material_names.add(slot.material.name)
            if slot.material.use_nodes and slot.material.node_tree:
                for node in slot.material.node_tree.nodes:
                    image = getattr(node, "image", None)
                    if image and image.filepath:
                        image_paths.add(bpy.path.abspath(image.filepath))

        meshes.append(
            {
                "name": obj.name,
                "mesh_name": mesh.name,
                "vertices": len(mesh.vertices),
                "triangles": sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons),
                "polygons": len(mesh.polygons),
                "material_slots": slots,
                "uv_layers": [layer.name for layer in mesh.uv_layers],
                "color_attributes": [attribute.name for attribute in mesh.color_attributes],
                "location": _rounded(obj.location),
                "rotation_euler_degrees": _rounded(
                    Vector(component * 57.29577951308232 for component in obj.rotation_euler)
                ),
                "scale": _rounded(obj.scale),
                "world_bounds_min": _rounded(minimum),
                "world_bounds_max": _rounded(maximum),
                "world_dimensions": _rounded(maximum - minimum),
                "local_bounds_min": _rounded(local_minimum),
                "local_bounds_max": _rounded(local_maximum),
                "local_dimensions": _rounded(local_maximum - local_minimum),
            }
        )

    if all_minimum is None or all_maximum is None:
        raise RuntimeError(f"No mesh objects were imported from {source}")

    return {
        "source": str(source),
        "source_bytes": source.stat().st_size,
        "objects_total": len(bpy.context.scene.objects),
        "mesh_objects": len(meshes),
        "meshes": meshes,
        "material_names": sorted(material_names, key=str.casefold),
        "referenced_images": sorted(image_paths, key=str.casefold),
        "bounds_min": _rounded(all_minimum),
        "bounds_max": _rounded(all_maximum),
        "dimensions_m": _rounded(all_maximum - all_minimum),
        "origin_to_bounds_min_m": _rounded(-all_minimum),
        "has_negative_scale": any(
            obj.type == "MESH" and any(value < 0.0 for value in obj.scale)
            for obj in bpy.context.scene.objects
        ),
    }


def main() -> int:
    args = _arguments()
    output = Path(args.output).resolve()
    sources = [Path(value).resolve() for value in args.source]
    if args.source_root:
        sources.extend(
            sorted(
                Path(args.source_root).resolve().rglob("*.fbx"),
                key=lambda value: str(value).casefold(),
            )
        )
    sources = list(dict.fromkeys(sources))
    if not sources:
        raise SystemExit("At least one --source or --source-root is required.")
    report = {
        "schema": "SteamtekBlenderSourceProbe-1",
        "blender_version": bpy.app.version_string,
        "assets": [],
        "errors": [],
    }
    for source in sources:
        try:
            report["assets"].append(_probe(source))
        except Exception as exc:  # Blender should finish the remaining probes.
            report["errors"].append({"source": str(source), "error": str(exc)})

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("STEAMTEK_PROBE_REPORT=" + str(output))
    print("STEAMTEK_PROBE_ASSETS=" + str(len(report["assets"])))
    print("STEAMTEK_PROBE_ERRORS=" + str(len(report["errors"])))
    return 1 if report["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
