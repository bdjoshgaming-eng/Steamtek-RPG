"""Headless Meshy -> Steamtek humanoid intake processor.

Run with Blender 4.5 or newer:
    blender.exe --background --python process_meshy_character.py -- \
        --input character.glb --output character.glb --report character.intake.json

The production GLB is written only when every required acceptance check passes.
The JSON report is always written.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy


ANIMATION_ALIASES = {
    "idle": "STK_IDLE",
    "walking": "STK_WALK",
    "walk": "STK_WALK",
    "running": "STK_RUN",
    "run": "STK_RUN",
    "pistol": "STK_ATTACK_PISTOL",
    "rifle": "STK_ATTACK_RIFLE",
    "shoot": "STK_ATTACK_PISTOL",
    "melee": "STK_ATTACK_MELEE",
    "attack": "STK_ATTACK",
    "cast": "STK_CAST",
    "jump": "STK_JUMP",
    "hurt": "STK_HURT",
    "hit": "STK_HURT",
    "death": "STK_DEATH",
    "die": "STK_DEATH",
}

BONE_ALIASES = {
    "hips": ("hips", "pelvis", "mixamorig:hips", "root"),
    "spine": ("spine", "mixamorig:spine"),
    "chest": ("chest", "spine1", "spine2", "mixamorig:spine1", "mixamorig:spine2"),
    "neck": ("neck", "mixamorig:neck"),
    "head": ("head", "mixamorig:head"),
    "hand.L": ("hand.l", "lefthand", "left_hand", "mixamorig:lefthand"),
    "hand.R": ("hand.r", "righthand", "right_hand", "mixamorig:righthand"),
    "foot.L": ("foot.l", "leftfoot", "left_foot", "mixamorig:leftfoot"),
    "foot.R": ("foot.r", "rightfoot", "right_foot", "mixamorig:rightfoot"),
}

SOCKET_MAP = {
    "SOCKET_Head": "head",
    "SOCKET_Hand_R": "hand.R",
    "SOCKET_Hand_L": "hand.L",
    "SOCKET_Back": "chest",
}


def source_signature(source: Path) -> dict:
    """Return enough header data to distinguish a real binary glTF from wrappers."""
    header = source.read_bytes()[:16]
    return {
        "hex": header.hex(" ").upper(),
        "ascii": "".join(chr(value) if 32 <= value <= 126 else "." for value in header),
        "is_standard_glb": header[:4] == b"glTF",
        "is_meshy_wrapped": header[:8] == b"MESHY.AI",
    }


def import_source(source: Path) -> None:
    """Import a supported Meshy export with the matching Blender importer."""
    suffix = source.suffix.lower()
    if suffix in {".glb", ".gltf"}:
        bpy.ops.import_scene.gltf(filepath=str(source))
        return
    if suffix == ".fbx":
        # Blender 4.5 exposes the newer FBX importer through wm.fbx_import.
        # Keep the legacy fallback so the same tool remains usable on 4.x builds.
        if hasattr(bpy.ops.wm, "fbx_import"):
            bpy.ops.wm.fbx_import(filepath=str(source))
        else:
            bpy.ops.import_scene.fbx(filepath=str(source))
        return
    raise ValueError(
        f"Unsupported source extension '{suffix}'. Use a standard FBX, GLB, or glTF export."
    )


def write_report(report_path: Path, report: dict) -> None:
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("STEAMTEK_INTAKE_RESULT=" + json.dumps(report))


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--blend-output")
    return parser.parse_args(argv)


def normalized_name(name: str) -> str:
    lower = name.lower().replace("-", "_").replace(" ", "_")
    for alias in ANIMATION_ALIASES:
        if alias in lower:
            return ANIMATION_ALIASES[alias]
    return ""


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


def triangle_count(obj: bpy.types.Object) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def mesh_weight_report(obj: bpy.types.Object) -> dict:
    unweighted = 0
    max_influences = 0
    for vertex in obj.data.vertices:
        influences = sum(1 for group in vertex.groups if group.weight > 1.0e-6)
        max_influences = max(max_influences, influences)
        if influences == 0:
            unweighted += 1
    return {
        "vertex_count": len(obj.data.vertices),
        "unweighted_vertices": unweighted,
        "max_influences_per_vertex": max_influences,
    }


def image_report() -> list[dict]:
    result = []
    for image in bpy.data.images:
        if image.name == "Render Result":
            continue
        result.append(
            {
                "name": image.name,
                "width": int(image.size[0]),
                "height": int(image.size[1]),
                "source": image.source,
                "packed": image.packed_file is not None,
                "filepath": image.filepath,
            }
        )
    return result


def create_socket(armature: bpy.types.Object, socket_name: str, semantic: str) -> bool:
    bone_name = semantic_bone(armature, semantic)
    if not bone_name:
        return False
    existing = bpy.data.objects.get(socket_name)
    if existing:
        return True
    empty = bpy.data.objects.new(socket_name, None)
    bpy.context.collection.objects.link(empty)
    empty.empty_display_type = "ARROWS"
    empty.empty_display_size = 0.12
    empty.parent = armature
    empty.parent_type = "BONE"
    empty.parent_bone = bone_name
    empty.matrix_parent_inverse = armature.matrix_world.inverted()
    empty["steamtek_socket"] = True
    return True


def main() -> int:
    args = parse_args()
    source = Path(args.input).resolve()
    output = Path(args.output).resolve()
    report_path = Path(args.report).resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)

    report = {
        "schema": "SteamtekMeshyAcceptance-1",
        "source": str(source),
        "output": str(output),
        "standard": {
            "triangle_target": [15000, 18000],
            "lod1_target": [8000, 10000],
            "lod2_target": [3000, 5000],
            "material_maximum": 5,
            "texture_target": [2048, 2048],
            "required_animations": ["STK_IDLE", "STK_WALK"],
        },
        "armatures": [],
        "meshes": [],
        "materials": [],
        "textures": [],
        "animations": [],
        "sockets": [],
        "errors": [],
        "warnings": [],
        "passed": False,
        "exported": False,
    }

    if not source.is_file():
        report["errors"].append("Input file does not exist")
        write_report(report_path, report)
        return 2

    report["file_size_bytes"] = source.stat().st_size
    report["file_signature"] = source_signature(source)
    if source.suffix.lower() == ".glb" and not report["file_signature"]["is_standard_glb"]:
        if report["file_signature"]["is_meshy_wrapped"]:
            report["errors"].append(
                "The .glb begins with MESHY.AI instead of the required glTF header. "
                "This is a Meshy-wrapped/protected payload, not a standard GLB that Blender or Godot can import. "
                "Download or export the model from Meshy as a standard GLB, FBX, or glTF file."
            )
        else:
            report["errors"].append(
                "The .glb does not contain the required glTF binary header and cannot be imported. "
                "Re-download or re-export a standard GLB, FBX, or glTF file."
            )
        write_report(report_path, report)
        return 2

    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        import_source(source)
    except Exception as exc:
        report["errors"].append(f"Blender could not import the source model: {exc}")
        write_report(report_path, report)
        return 2

    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    skinned = [
        obj
        for obj in meshes
        if any(mod.type == "ARMATURE" and mod.object for mod in obj.modifiers)
    ]

    if len(armatures) != 1:
        report["errors"].append(f"Expected exactly one shared armature; found {len(armatures)}")
    if not skinned:
        report["errors"].append("No skinned mesh with a valid Armature modifier was found")

    canonical = max(armatures, key=lambda obj: len(obj.data.bones)) if armatures else None
    for armature in armatures:
        semantics = {key: semantic_bone(armature, key) for key in BONE_ALIASES}
        missing = [key for key, value in semantics.items() if not value]
        report["armatures"].append(
            {
                "name": armature.name,
                "bone_count": len(armature.data.bones),
                "semantic_bones": semantics,
                "missing_semantics": missing,
                "scale": list(armature.scale),
            }
        )
        if armature == canonical and missing:
            report["errors"].append(f"Canonical armature is missing required bones: {missing}")

    total_triangles = 0
    unique_materials = set()
    for mesh in meshes:
        triangles = triangle_count(mesh)
        total_triangles += triangles
        weights = mesh_weight_report(mesh) if mesh in skinned else None
        material_names = [slot.material.name for slot in mesh.material_slots if slot.material]
        unique_materials.update(material_names)
        report["meshes"].append(
            {
                "name": mesh.name,
                "triangles": triangles,
                "materials": material_names,
                "vertex_groups": len(mesh.vertex_groups),
                "skinned": mesh in skinned,
                "weights": weights,
                "scale": list(mesh.scale),
            }
        )
        if weights and weights["unweighted_vertices"]:
            report["errors"].append(
                f"{mesh.name} has {weights['unweighted_vertices']} unweighted vertices"
            )
        if weights and weights["max_influences_per_vertex"] > 4:
            report["warnings"].append(
                f"{mesh.name} uses up to {weights['max_influences_per_vertex']} bone influences per vertex"
            )

    report["triangle_count"] = total_triangles
    if not 15000 <= total_triangles <= 18000:
        report["errors"].append(
            f"LOD0 triangle count {total_triangles} is outside the 15,000-18,000 Steamtek target"
        )

    report["materials"] = sorted(unique_materials)
    if len(unique_materials) > 5:
        report["errors"].append(
            f"Character uses {len(unique_materials)} materials; Steamtek maximum is 5"
        )

    report["textures"] = image_report()
    undersized = [
        image["name"]
        for image in report["textures"]
        if image["width"] and image["height"] and (image["width"] < 2048 or image["height"] < 2048)
    ]
    if undersized:
        report["warnings"].append(f"Textures below 2048x2048: {undersized}")

    occupied = {action.name for action in bpy.data.actions}
    renamed = {}
    for action in bpy.data.actions:
        target = normalized_name(action.name)
        if target and target != action.name:
            candidate = target
            suffix = 2
            while candidate in occupied:
                candidate = f"{target}_{suffix:02d}"
                suffix += 1
            occupied.discard(action.name)
            occupied.add(candidate)
            renamed[action.name] = candidate
            action.name = candidate

    animation_names = sorted(action.name for action in bpy.data.actions)
    report["animations"] = [
        {
            "name": action.name,
            "frame_start": float(action.frame_range[0]),
            "frame_end": float(action.frame_range[1]),
        }
        for action in bpy.data.actions
    ]
    report["renamed_animations"] = renamed
    missing_animations = [name for name in ("STK_IDLE", "STK_WALK") if name not in animation_names]
    if missing_animations:
        report["errors"].append(f"Missing first-pass animations: {missing_animations}")

    if canonical:
        report["sockets"] = [
            name for name, semantic in SOCKET_MAP.items() if create_socket(canonical, name, semantic)
        ]
        if len(report["sockets"]) != len(SOCKET_MAP):
            report["errors"].append("Could not create all required equipment sockets")

    report["passed"] = not report["errors"]

    if args.blend_output:
        blend_output = Path(args.blend_output).resolve()
        blend_output.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(blend_output))
        report["blend_output"] = str(blend_output)

    if report["passed"]:
        output.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=str(output),
            export_format="GLB",
            export_animations=True,
            export_skins=True,
            export_morph=True,
            export_yup=True,
            export_apply=False,
        )
        report["exported"] = output.is_file()
        if not report["exported"]:
            report["passed"] = False
            report["errors"].append("Blender export completed without producing the output GLB")

    write_report(report_path, report)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
