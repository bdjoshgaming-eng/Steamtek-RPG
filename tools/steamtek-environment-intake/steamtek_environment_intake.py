#!/usr/bin/env python3
"""Permanent, source-safe Steamtek environment asset intake pipeline."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


PIPELINE_VERSION = "1.0.3"
REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = (
    REPO_ROOT
    / "assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Tools/intake_config.json"
)
MATERIAL_BINDER = (
    REPO_ROOT
    / "tools/steamtek-environment-intake/godot/steamtek_material_binding.gd"
)
PILOT_REVIEW_SCRIPT = (
    REPO_ROOT
    / "tools/steamtek-environment-intake/godot/steamtek_intake_pilot_review.gd"
)
GODOT_SOURCE_PROBE = (
    REPO_ROOT
    / "tools/steamtek-environment-intake/godot/probe_environment_sources.gd"
)
PILOT_VALIDATOR = (
    REPO_ROOT
    / "tools/steamtek-environment-intake/godot/validate_environment_intake_pilot.gd"
)

MUTABLE_SOURCE_METADATA_EXTENSIONS = {".import"}
TEXTURE_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".tga",
    ".webp",
    ".tif",
    ".tiff",
    ".exr",
    ".hdr",
    ".dds",
}
CHAIN_SOCKET_ROLES = {
    "facade_horizontal",
    "floor_horizontal",
    "street_road_chain",
    "street_sidewalk_chain",
    "street_curb_chain",
    "street_fence_chain",
    "wall_service_chain",
}
MAP_PATTERNS = (
    ("base_color", re.compile(r"_basecolor$", re.IGNORECASE)),
    ("normal", re.compile(r"_(?:opengl_)?normal$", re.IGNORECASE)),
    ("roughness", re.compile(r"_roughness$", re.IGNORECASE)),
    ("metallic", re.compile(r"_metallic$", re.IGNORECASE)),
    ("ao", re.compile(r"_ambientocclusion$", re.IGNORECASE)),
    ("emission", re.compile(r"_emission$", re.IGNORECASE)),
    ("alpha", re.compile(r"_alpha$", re.IGNORECASE)),
    (
        "packed_orm",
        re.compile(
            r"_(?:orm|occlusionroughnessmetallic)$", re.IGNORECASE
        ),
    ),
    ("packed_rma", re.compile(r"_(?:rma|roughnessmetallicao)$", re.IGNORECASE)),
    ("height", re.compile(r"_height$", re.IGNORECASE)),
)


@dataclass(frozen=True)
class Context:
    config_path: Path
    config: dict[str, Any]
    pack_root: Path
    source_geometry_root: Path
    source_texture_root: Path
    output_root: Path
    reports_root: Path
    materials_root: Path
    scenes_root: Path
    probe_path: Path
    godot_probe_path: Path


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalized(value: str) -> str:
    text = re.sub(r"\.\d{3}$", "", value.strip().lower())
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return " ".join(text.split())


def slug(value: str) -> str:
    text = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_")
    return re.sub(r"_+", "_", text)


def posix_relative(path: Path, base: Path = REPO_ROOT) -> str:
    return path.resolve().relative_to(base.resolve()).as_posix()


def res_path(path: Path) -> str:
    return "res://" + posix_relative(path)


def resolved_child(
    parent: Path,
    configured_path: str | Path,
    label: str,
    *,
    allow_parent: bool = False,
) -> Path:
    parent = parent.resolve()
    candidate = (parent / configured_path).resolve()
    if candidate == parent:
        if allow_parent:
            return candidate
        raise ValueError(f"{label} must be a child of {parent}")
    if parent not in candidate.parents:
        raise ValueError(f"{label} escapes its allowed root {parent}: {candidate}")
    return candidate


def load_context(config_path: Path) -> Context:
    config_path = config_path.resolve()
    config = json.loads(config_path.read_text(encoding="utf-8"))
    if config.get("schema") != "SteamtekEnvironmentIntakeConfig-1":
        raise ValueError(f"Unsupported config schema in {config_path}")
    pack_root = resolved_child(REPO_ROOT, config["pack_root"], "pack_root")
    source_geometry_root = resolved_child(
        pack_root, config["source_geometry_root"], "source_geometry_root"
    )
    source_texture_root = resolved_child(
        pack_root, config["source_texture_root"], "source_texture_root"
    )
    output_root = resolved_child(pack_root, config["output_root"], "output_root")
    reserved_output_root = (pack_root / "Steamtek").resolve()
    if output_root != reserved_output_root:
        raise ValueError(
            "output_root must resolve exactly to the pack's reserved Steamtek "
            f"directory: {reserved_output_root}"
        )
    for label, source_root in (
        ("source_geometry_root", source_geometry_root),
        ("source_texture_root", source_texture_root),
    ):
        if source_root == output_root or output_root in source_root.parents:
            raise ValueError(f"{label} cannot be inside output_root: {source_root}")
        if not source_root.is_dir():
            raise FileNotFoundError(f"{label} directory not found: {source_root}")
    for category, defaults in config.get("category_defaults", {}).items():
        resolved_child(
            output_root,
            defaults["output"],
            f"category_defaults[{category!r}].output",
        )
        resolved_child(
            output_root,
            defaults["scene_output"],
            f"category_defaults[{category!r}].scene_output",
        )
    reports_root = output_root / "Reports"
    probe_path = resolved_child(
        pack_root, config["tools"]["full_probe_report"], "tools.full_probe_report"
    )
    blender_probe_path = resolved_child(
        pack_root, config["tools"]["blender_probe"], "tools.blender_probe"
    )
    for label, tool_path in (
        ("tools.full_probe_report", probe_path),
        ("tools.blender_probe", blender_probe_path),
    ):
        if output_root not in tool_path.parents:
            raise ValueError(f"{label} must remain inside output_root: {tool_path}")
    return Context(
        config_path=config_path,
        config=config,
        pack_root=pack_root,
        source_geometry_root=source_geometry_root,
        source_texture_root=source_texture_root,
        output_root=output_root,
        reports_root=reports_root,
        materials_root=output_root / "Materials/Source_Reconstructed",
        scenes_root=output_root / "Scenes",
        probe_path=probe_path,
        godot_probe_path=reports_root / "Godot_Full_Source_Probe.json",
    )


def write_if_changed(path: Path, data: bytes, force: bool = False) -> str:
    if path.exists() and not force and path.read_bytes() == data:
        return "unchanged"
    state = "changed" if path.exists() else "created"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return state


def write_text_if_changed(path: Path, text: str, force: bool = False) -> str:
    return write_if_changed(path, text.encode("utf-8"), force=force)


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def classify_texture_map(path: Path) -> str:
    for map_type, expression in MAP_PATTERNS:
        if expression.search(path.stem):
            return map_type
    return "unclassified"


def discover_texture_families(ctx: Context) -> dict[str, dict[str, Any]]:
    families: dict[str, dict[str, Any]] = {}
    for directory in sorted(
        (path for path in ctx.source_texture_root.rglob("*") if path.is_dir()),
        key=lambda value: str(value).casefold(),
    ):
        textures = sorted(
            (
                path
                for path in directory.iterdir()
                if path.is_file() and path.suffix.lower() in TEXTURE_EXTENSIONS
            ),
            key=lambda value: value.name.casefold(),
        )
        if not textures:
            continue
        family = directory.relative_to(ctx.source_texture_root).as_posix()
        maps: dict[str, str] = {}
        duplicates: dict[str, list[str]] = {}
        for texture in textures:
            map_type = classify_texture_map(texture)
            relative = posix_relative(texture)
            if map_type in maps:
                duplicates.setdefault(map_type, [maps[map_type]]).append(relative)
            else:
                maps[map_type] = relative
        families[family] = {
            "family": family,
            "maps": maps,
            "duplicates": duplicates,
            "source_files": [posix_relative(path) for path in textures],
        }
    return families


def load_probe(ctx: Context) -> dict[str, Any]:
    if not ctx.probe_path.exists():
        raise FileNotFoundError(
            f"Missing {ctx.probe_path}. Run the probe command before inventory/build."
        )
    probe = json.loads(ctx.probe_path.read_text(encoding="utf-8"))
    if probe.get("errors"):
        raise RuntimeError(f"Source probe contains errors: {probe['errors']}")
    return probe


def probe_by_relative_source(ctx: Context, probe: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for asset in probe["assets"]:
        source = Path(asset["source"]).resolve()
        result[source.relative_to(ctx.pack_root).as_posix()] = asset
    return result


def godot_probe_by_relative_source(ctx: Context) -> dict[str, dict[str, Any]]:
    if not ctx.godot_probe_path.exists():
        return {}
    report = json.loads(ctx.godot_probe_path.read_text(encoding="utf-8"))
    if report.get("errors"):
        raise RuntimeError(f"Godot source probe contains errors: {report['errors']}")
    result: dict[str, dict[str, Any]] = {}
    prefix = "res://" + posix_relative(ctx.pack_root) + "/"
    for asset in report.get("assets", []):
        source = str(asset["source"])
        if source.startswith(prefix):
            result[source.removeprefix(prefix)] = asset
    return result


def resolve_material_family(
    material_name: str,
    families: dict[str, dict[str, Any]],
    aliases: dict[str, str],
) -> tuple[str | None, str]:
    if material_name in aliases:
        family = aliases[material_name]
        return (family, "explicit_alias") if family in families else (None, "alias_missing")
    normalized_material = normalized(material_name)
    exact = [
        family
        for family in families
        if normalized(PurePosixPath(family).name) == normalized_material
        or normalized(family) == normalized_material
    ]
    if len(exact) == 1:
        return exact[0], "normalized_exact"
    material_tokens = set(normalized_material.split())
    scored: list[tuple[int, float, str]] = []
    for family in families:
        family_tokens = set(normalized(PurePosixPath(family).name).split())
        overlap = material_tokens & family_tokens
        if not overlap:
            continue
        score = len(overlap)
        ratio = score / max(len(material_tokens | family_tokens), 1)
        scored.append((score, ratio, family))
    scored.sort(key=lambda item: (-item[0], -item[1], item[2].casefold()))
    if scored and (len(scored) == 1 or scored[0][:2] > scored[1][:2]):
        return scored[0][2], "token_match"
    return None, "unresolved"


def source_material_map(
    ctx: Context,
    probe: dict[str, Any],
    families: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    aliases = ctx.config.get("material_aliases", {})
    rows: list[dict[str, Any]] = []
    for source_relative, asset in sorted(
        probe_by_relative_source(ctx, probe).items(),
        key=lambda item: item[0].casefold(),
    ):
        category = PurePosixPath(source_relative).parts[1]
        for material_name in asset["material_names"]:
            family, method = resolve_material_family(material_name, families, aliases)
            family_maps = families.get(family or "", {}).get("maps", {})
            rows.append(
                {
                    "source": source_relative,
                    "category": category,
                    "mesh": asset["meshes"][0]["name"],
                    "source_material": material_name,
                    "texture_family": family,
                    "resolution_method": method,
                    "maps": family_maps,
                    "resolved": family is not None,
                }
            )
    return rows


def vendor_source_files(ctx: Context) -> list[Path]:
    output_resolved = ctx.output_root.resolve()
    return sorted(
        (
            path
            for path in ctx.pack_root.rglob("*")
            if path.is_file()
            and path.suffix.lower() not in MUTABLE_SOURCE_METADATA_EXTENSIONS
            and output_resolved not in path.resolve().parents
        ),
        key=lambda value: str(value).casefold(),
    )


def hash_manifest(ctx: Context) -> dict[str, Any]:
    files = vendor_source_files(ctx)
    with ThreadPoolExecutor(max_workers=4) as executor:
        hashes = list(executor.map(sha256_file, files))
    entries = [
        {
            "path": path.relative_to(ctx.pack_root).as_posix(),
            "bytes": path.stat().st_size,
            "sha256": digest,
        }
        for path, digest in zip(files, hashes, strict=True)
    ]
    return {
        "schema": "SteamtekVendorSourceHashManifest-1",
        "pack_id": ctx.config["pack_id"],
        "generated_utc": utc_now(),
        "excludes": ["Steamtek/**", "**/*.import"],
        "file_count": len(entries),
        "total_bytes": sum(entry["bytes"] for entry in entries),
        "files": entries,
    }


def verify_or_create_vendor_baseline(
    ctx: Context,
    force: bool = False,
    *,
    create_if_missing: bool = False,
) -> tuple[dict[str, Any], str]:
    current = hash_manifest(ctx)
    baseline_path = ctx.reports_root / "Vendor_Source_Baseline_SHA256.json"
    if not baseline_path.exists():
        if not create_if_missing:
            report = {
                "schema": "SteamtekVendorSourceVerification-1",
                "generated_utc": utc_now(),
                "baseline_created": False,
                "baseline_missing": True,
                "passed": False,
                "added": [],
                "removed": [],
                "changed": [],
                "file_count": current["file_count"],
            }
            state = write_if_changed(
                ctx.reports_root / "Vendor_Source_Verification.json",
                json_bytes(report),
                force=force,
            )
            return report, state
        state = write_if_changed(baseline_path, json_bytes(current), force=force)
        return {
            "schema": "SteamtekVendorSourceVerification-1",
            "generated_utc": utc_now(),
            "baseline_created": True,
            "baseline_missing": False,
            "passed": True,
            "added": [],
            "removed": [],
            "changed": [],
            "file_count": current["file_count"],
        }, state
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    old = {entry["path"]: entry for entry in baseline["files"]}
    new = {entry["path"]: entry for entry in current["files"]}
    added = sorted(set(new) - set(old))
    removed = sorted(set(old) - set(new))
    changed = sorted(
        path
        for path in set(old) & set(new)
        if old[path]["sha256"] != new[path]["sha256"]
        or old[path]["bytes"] != new[path]["bytes"]
    )
    report = {
        "schema": "SteamtekVendorSourceVerification-1",
        "generated_utc": utc_now(),
        "baseline_created": False,
        "passed": not added and not removed and not changed,
        "added": added,
        "removed": removed,
        "changed": changed,
        "file_count": current["file_count"],
    }
    state = write_if_changed(
        ctx.reports_root / "Vendor_Source_Verification.json",
        json_bytes(report),
        force=force,
    )
    return report, state


def godot_executable(ctx: Context) -> Path:
    executable = Path(ctx.config["tools"]["godot_47"])
    if not executable.exists():
        raise FileNotFoundError(f"Godot 4.7 not found: {executable}")
    return executable


def run_godot_script(
    ctx: Context, script: Path, user_arguments: Iterable[str]
) -> int:
    command = [
        str(godot_executable(ctx)),
        "--editor",
        "--path",
        str(REPO_ROOT),
        "--script",
        str(script),
        "--",
        *user_arguments,
    ]
    completed = subprocess.run(command, cwd=REPO_ROOT, check=False)
    return completed.returncode


def run_probe(ctx: Context) -> int:
    blender = Path(ctx.config["tools"]["blender_45"])
    probe_script = ctx.pack_root / ctx.config["tools"]["blender_probe"]
    if not blender.exists():
        raise FileNotFoundError(f"Blender 4.5 not found: {blender}")
    blender_command = [
        str(blender),
        "--background",
        "--factory-startup",
        "--python",
        str(probe_script),
        "--",
        "--output",
        str(ctx.probe_path),
        "--source-root",
        str(ctx.source_geometry_root),
    ]
    blender_result = subprocess.run(
        blender_command, cwd=REPO_ROOT, check=False
    )
    if blender_result.returncode != 0:
        return blender_result.returncode
    return run_godot_script(
        ctx,
        GODOT_SOURCE_PROBE,
        [
            f"--source-root={res_path(ctx.source_geometry_root)}",
            f"--report={res_path(ctx.godot_probe_path)}",
        ],
    )


def run_pilot_validation(ctx: Context) -> int:
    return run_godot_script(
        ctx,
        PILOT_VALIDATOR,
        [
            f"--manifest={res_path(ctx.reports_root / 'Pilot_Manifest.json')}",
            f"--report={res_path(ctx.reports_root / 'Pilot_Godot_Validation.json')}",
        ],
    )


def run_full_validation(ctx: Context) -> int:
    return run_godot_script(
        ctx,
        PILOT_VALIDATOR,
        [
            f"--manifest={res_path(ctx.reports_root / 'Full_Manifest.json')}",
            f"--report={res_path(ctx.reports_root / 'Full_Godot_Validation.json')}",
        ],
    )


def open_pilot_review(ctx: Context) -> dict[str, Any]:
    scene_path = pilot_scene_path(ctx)
    if not scene_path.exists():
        raise FileNotFoundError(
            f"Missing pilot scene: {scene_path}. Run the pilot build first."
        )
    command = [
        str(godot_executable(ctx)),
        "--editor",
        "--path",
        str(REPO_ROOT),
        str(scene_path),
    ]
    process = subprocess.Popen(command, cwd=REPO_ROOT)
    return {
        "schema": "SteamtekEnvironmentPilotReviewLaunch-1",
        "process_id": process.pid,
        "scene": res_path(scene_path),
        "instruction": "Use F6 in the normal Godot editor; visual approval is never automated.",
    }

def inventory_report(
    ctx: Context,
    probe: dict[str, Any],
    families: dict[str, dict[str, Any]],
    material_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    pack_files = [path for path in ctx.pack_root.rglob("*") if path.is_file()]
    source_files = [
        path for path in pack_files if ctx.output_root not in path.parents
    ]
    generated_files = [
        path for path in pack_files if ctx.output_root in path.parents
    ]

    def extension_counts(paths: list[Path]) -> dict[str, int]:
        counts: dict[str, int] = {}
        for path in paths:
            extension = path.suffix.lower() or "<none>"
            counts[extension] = counts.get(extension, 0) + 1
        return dict(sorted(counts.items()))

    immutable_source_files = [
        path
        for path in source_files
        if path.suffix.lower() not in MUTABLE_SOURCE_METADATA_EXTENSIONS
    ]
    assets = probe["assets"]
    material_names = sorted(
        {name for asset in assets for name in asset["material_names"]},
        key=str.casefold,
    )
    unresolved = [row for row in material_rows if not row["resolved"]]
    texture_map_counts: dict[str, int] = {}
    for family in families.values():
        for map_type in family["maps"]:
            texture_map_counts[map_type] = texture_map_counts.get(map_type, 0) + 1
    category_counts: dict[str, int] = {}
    for asset in assets:
        category = Path(asset["source"]).parent.name
        category_counts[category] = category_counts.get(category, 0) + 1
    animation_issue = ctx.config.get("import_policy", {}).get(
        "animation_contamination", {}
    )
    source_names = [Path(asset["source"]).stem for asset in assets]
    lod_assets = sorted(
        name
        for name in source_names
        if re.search(r"(?:^|[_-])lod[_-]?\d+(?:[_-]|$)", name, re.IGNORECASE)
    )
    collision_assets = sorted(
        name
        for name in source_names
        if re.search(
            r"(?:^|[_-])(?:ucx|ubx|usp|collision|collider|col)(?:[_-]|$)",
            name,
            re.IGNORECASE,
        )
    )
    decal_assets = sorted(
        name for name in source_names if "decal" in name.casefold()
    )
    transparent_families = sorted(
        family for family, data in families.items() if "alpha" in data["maps"]
    )
    emissive_families = sorted(
        family for family, data in families.items() if "emission" in data["maps"]
    )
    return {
        "schema": "SteamtekEnvironmentAssetInventory-1",
        "generated_utc": utc_now(),
        "pack_id": ctx.config["pack_id"],
        "source_format": ctx.config["source_format"],
        "file_count": len(source_files),
        "extension_counts": extension_counts(source_files),
        "immutable_source_file_count": len(immutable_source_files),
        "generated_output_file_count": len(generated_files),
        "generated_output_extension_counts": extension_counts(generated_files),
        "pack_file_count_including_generated_output": len(pack_files),
        "fbx_assets": len(assets),
        "fbx_categories": dict(sorted(category_counts.items())),
        "mesh_objects": sum(asset["mesh_objects"] for asset in assets),
        "vertices": sum(
            mesh["vertices"] for asset in assets for mesh in asset["meshes"]
        ),
        "triangles": sum(
            mesh["triangles"] for asset in assets for mesh in asset["meshes"]
        ),
        "material_names": material_names,
        "material_name_count": len(material_names),
        "multi_material_assets": [
            Path(asset["source"]).name
            for asset in assets
            if len(asset["material_names"]) > 1
        ],
        "texture_family_count": len(families),
        "texture_map_counts": dict(sorted(texture_map_counts.items())),
        "unresolved_materials": unresolved,
        "source_lods": len(lod_assets),
        "source_lod_assets": lod_assets,
        "source_collision_meshes": len(collision_assets),
        "source_collision_assets": collision_assets,
        "possible_decal_assets": decal_assets,
        "transparent_texture_families": transparent_families,
        "emissive_texture_families": emissive_families,
        "animation_import_policy": {
            "enabled": not bool(
                ctx.config.get("import_policy", {}).get("static_geometry", False)
            ),
            "reason": animation_issue.get("reason", "pack_configured_policy"),
            "affected_categories": animation_issue.get("categories", []),
            "affected_asset_count": int(animation_issue.get("asset_count", 0)),
        },
        "import_metadata_classification": "mutable_godot_generated_not_vendor_source",
    }


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> str:
    buffer = io.StringIO(newline="")
    writer = csv.DictWriter(buffer, fieldnames=fieldnames, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow({key: row.get(key, "") for key in fieldnames})
    return write_text_if_changed(path, buffer.getvalue())


def write_inventory_outputs(
    ctx: Context,
    force: bool = False,
) -> tuple[dict[str, Any], dict[str, dict[str, Any]], list[dict[str, Any]], dict[str, str]]:
    probe = load_probe(ctx)
    families = discover_texture_families(ctx)
    material_rows = source_material_map(ctx, probe, families)
    report = inventory_report(ctx, probe, families, material_rows)
    states = {
        "asset_inventory": write_if_changed(
            ctx.reports_root / "Asset_Inventory.json",
            json_bytes(report),
            force=force,
        ),
        "material_texture_map": write_if_changed(
            ctx.reports_root / "Material_Texture_Map.json",
            json_bytes(
                {
                    "schema": "SteamtekMaterialTextureMap-1",
                    "generated_utc": utc_now(),
                    "families": families,
                    "source_material_rows": material_rows,
                }
            ),
            force=force,
        ),
    }
    flat_rows = []
    for row in material_rows:
        flat_rows.append(
            {
                "source": row["source"],
                "category": row["category"],
                "mesh": row["mesh"],
                "source_material": row["source_material"],
                "texture_family": row["texture_family"] or "",
                "resolution_method": row["resolution_method"],
                "base_color": row["maps"].get("base_color", ""),
                "normal": row["maps"].get("normal", ""),
                "roughness": row["maps"].get("roughness", ""),
                "metallic": row["maps"].get("metallic", ""),
                "ao": row["maps"].get("ao", ""),
                "emission": row["maps"].get("emission", ""),
                "alpha": row["maps"].get("alpha", ""),
            }
        )
    states["source_material_csv"] = write_csv(
        ctx.reports_root / "Source_Material_Texture_Map.csv",
        flat_rows,
        [
            "source",
            "category",
            "mesh",
            "source_material",
            "texture_family",
            "resolution_method",
            "base_color",
            "normal",
            "roughness",
            "metallic",
            "ao",
            "emission",
            "alpha",
        ],
    )
    return probe, families, material_rows, states


def modular_contract(category: str, source_relative: PurePosixPath, dimensions: list[float]) -> dict[str, Any]:
    name = source_relative.stem
    horizontal = {"x": dimensions[0], "z": dimensions[2]}
    horizontal_axis = max(horizontal, key=horizontal.get)
    horizontal_ratio = max(horizontal.values()) / max(min(horizontal.values()), 0.000001)
    ordered = sorted([("x", dimensions[0]), ("y", dimensions[1]), ("z", dimensions[2])], key=lambda item: item[1], reverse=True)
    dominant_axis, dominant_size = ordered[0]
    dominant_ratio = dominant_size / max(ordered[1][1], 0.000001)
    contract = {"classification": "non_modular", "primary_socket_role": "", "snap_axis": "", "rejected_modular_candidate": False, "rejection_reason": "", "builder_profile": "small_props"}
    if category == "Walls":
        if "Corner" in name or (horizontal_ratio < 2.5 and "Pillar" not in name):
            contract.update({"classification": "rejected_modular_candidate", "rejected_modular_candidate": True, "rejection_reason": "ambiguous_or_corner_wall_endpoints_require_authored_topology", "builder_profile": "exterior_structure"})
        else:
            contract.update({"classification": "structural_modular", "primary_socket_role": "facade_horizontal", "snap_axis": "x" if "Pillar" in name else horizontal_axis, "builder_profile": "exterior_structure"})
    elif category == "Road":
        if dimensions[1] >= 0.5:
            contract.update({"classification": "rejected_modular_candidate", "rejected_modular_candidate": True, "rejection_reason": "sloped_road_requires_authored_endpoint_elevations", "builder_profile": "exterior_structure"})
        else:
            contract.update({"classification": "structural_modular", "primary_socket_role": "street_road_chain", "snap_axis": "z", "builder_profile": "exterior_structure"})
    elif category == "Floor":
        contract.update({"classification": "structural_modular", "primary_socket_role": "street_curb_chain" if "Curb" in name else "street_sidewalk_chain", "snap_axis": horizontal_axis, "builder_profile": "exterior_structure"})
    elif category == "Railings":
        contract.update({"classification": "structural_modular", "primary_socket_role": "street_fence_chain", "snap_axis": horizontal_axis, "builder_profile": "exterior_structure"})
    elif category == "Platform":
        contract.update({"classification": "structural_modular", "primary_socket_role": "floor_horizontal", "snap_axis": horizontal_axis, "builder_profile": "exterior_structure"})
    elif category == "Trims":
        if "Corner" in name or horizontal_ratio < 2.5:
            contract.update({"classification": "rejected_modular_candidate", "rejected_modular_candidate": True, "rejection_reason": "trim_endpoints_or_corner_topology_not_unambiguous", "builder_profile": "exterior_structure"})
        else:
            contract.update({"classification": "structural_modular", "primary_socket_role": "wall_service_chain", "snap_axis": horizontal_axis, "builder_profile": "exterior_structure"})
    elif category == "Pipes":
        if "Caged" in name or dominant_ratio < 3.0:
            contract.update({"classification": "rejected_modular_candidate", "rejected_modular_candidate": True, "rejection_reason": "compound_or_bent_pipe_requires_authored_endpoints", "builder_profile": "exterior_structure"})
        else:
            contract.update({"classification": "structural_modular", "primary_socket_role": "wall_service_chain", "snap_axis": dominant_axis, "builder_profile": "exterior_structure"})
    elif category == "Steps":
        contract.update({"classification": "rejected_modular_candidate", "rejected_modular_candidate": True, "rejection_reason": "stair_travel_direction_and_endpoint_elevation_not_proven", "builder_profile": "exterior_structure"})
    elif category in {"Props", "Signs", "Wall Props", "Metal Panels", "Metal Sheets", "Windows"}:
        contract.update({"classification": "attachment_compatible", "primary_socket_role": "prop_anchor", "builder_profile": "small_props"})
    return contract

def asset_plan_from_source(
    ctx: Context,
    source_relative: str,
    probe_asset: dict[str, Any],
    configured: dict[str, Any] | None = None,
    godot_asset: dict[str, Any] | None = None,
) -> dict[str, Any]:
    source_path = PurePosixPath(source_relative)
    category = source_path.parts[1]
    defaults = ctx.config["category_defaults"][category]
    pivot_policy = (
        configured.get("pivot", defaults["pivot"])
        if configured
        else defaults["pivot"]
    )
    if pivot_policy != "bottom_center":
        raise ValueError(
            f"Unsupported pivot policy {pivot_policy!r} for {source_relative}; "
            "add a tested reversible transform policy before generating this asset."
        )
    source_stem = source_path.stem
    source_tail = re.sub(r"^SM_3DT_", "", source_stem)
    production_name = (
        configured.get("production_name")
        if configured
        else f"{defaults['prefix']}_{slug(source_tail)}"
    )
    material_overrides = (
        configured.get("material_overrides", {}) if configured else {}
    )
    if not material_overrides:
        aliases = ctx.config.get("material_aliases", {})
        families = discover_texture_families(ctx)
        for material_name in probe_asset["material_names"]:
            family, _ = resolve_material_family(material_name, families, aliases)
            if family:
                material_overrides[material_name] = family
    scene_directory = resolved_child(
        ctx.output_root,
        defaults["scene_output"],
        f"category_defaults[{category!r}].scene_output",
    )
    configured_scene_path = resolved_child(
        scene_directory,
        f"{production_name}.tscn",
        f"scene path for {source_relative}",
    )
    scene_relative = PurePosixPath(
        configured_scene_path.relative_to(ctx.pack_root).as_posix()
    )
    mesh = probe_asset["meshes"][0]
    minimum = [float(value) for value in mesh["local_bounds_min"]]
    maximum = [float(value) for value in mesh["local_bounds_max"]]
    if godot_asset:
        godot_minimum = [float(value) for value in godot_asset["bounds_position"]]
        dimensions = [float(value) for value in godot_asset["bounds_size"]]
        godot_maximum = [
            godot_minimum[index] + dimensions[index] for index in range(3)
        ]
    else:
        godot_minimum = [minimum[0], minimum[2], -maximum[1]]
        godot_maximum = [maximum[0], maximum[2], -minimum[1]]
        dimensions = [
            godot_maximum[index] - godot_minimum[index] for index in range(3)
        ]
    godot_minimum = [round(value, 6) for value in godot_minimum]
    godot_maximum = [round(value, 6) for value in godot_maximum]
    dimensions = [round(value, 6) for value in dimensions]
    center = [
        (godot_minimum[index] + godot_maximum[index]) * 0.5 for index in range(3)
    ]
    visual_offset = [-center[0], -godot_minimum[1], -center[2]]
    plan = {
        "source": source_relative,
        "category": category,
        "production_name": production_name,
        "scene_relative": scene_relative.as_posix(),
        "scene_path": configured_scene_path,
        "material_overrides": material_overrides,
        "pivot": pivot_policy,
        "collision": (
            configured.get("collision", defaults["collision"])
            if configured
            else defaults["collision"]
        ),
        "socket_role": "",
        "pilot_position": configured.get("pilot_position", [0.0, 0.0, 0.0])
        if configured
        else [0.0, 0.0, 0.0],
        "dimensions_m": dimensions,
        "source_bounds_min_m": godot_minimum,
        "source_bounds_max_m": godot_maximum,
        "visual_offset_m": visual_offset,
        "triangles": sum(item["triangles"] for item in probe_asset["meshes"]),
        "vertices": sum(item["vertices"] for item in probe_asset["meshes"]),
        "source_sha256": sha256_file(ctx.pack_root / source_relative),
    }
    contract = modular_contract(category, source_path, dimensions)
    plan["modular_contract"] = contract
    plan["socket_role"] = contract["primary_socket_role"]
    return plan


def select_plans(
    ctx: Context,
    probe: dict[str, Any],
    scope: str,
    asset_filter: str | None,
    category_filter: str | None,
) -> list[dict[str, Any]]:
    probe_index = probe_by_relative_source(ctx, probe)
    godot_index = godot_probe_by_relative_source(ctx)
    configured = {
        item["source"]: item for item in ctx.config.get("pilot_assets", [])
    }
    if scope == "pilot":
        sources = list(configured)
    else:
        sources = sorted(probe_index, key=str.casefold)
    if asset_filter:
        normalized_filter = asset_filter.replace("\\", "/").casefold()
        sources = [
            source
            for source in sources
            if normalized_filter in source.casefold()
            or normalized_filter in PurePosixPath(source).name.casefold()
        ]
    if category_filter:
        sources = [
            source
            for source in sources
            if PurePosixPath(source).parts[1].casefold() == category_filter.casefold()
        ]
    plans = [
        asset_plan_from_source(
            ctx,
            source,
            probe_index[source],
            configured.get(source),
            godot_index.get(source),
        )
        for source in sources
    ]
    if not plans:
        raise ValueError("No assets matched the requested scope/filter.")
    return plans


def material_path(ctx: Context, family: str) -> Path:
    return ctx.materials_root / f"STK_MAT_{slug(family)}.tres"


def derived_alpha_path(ctx: Context, family: str) -> Path:
    return (
        ctx.output_root
        / "Materials/Derived_Textures"
        / f"STK_TEX_{slug(family)}_BaseColorAlpha.png"
    )


def material_profile(ctx: Context, family: str) -> dict[str, Any]:
    configured = ctx.config.get("material_profiles", {}).get(family, {})
    if not isinstance(configured, dict):
        raise ValueError(f"material_profiles[{family!r}] must be an object")
    return configured


def remap_alpha_image(alpha: Any, settings: dict[str, Any], family: str) -> Any:
    if not settings:
        return alpha
    source_min = float(settings.get("source_min", 0.0))
    source_max = float(settings.get("source_max", 255.0))
    target_min = float(settings.get("target_min", 0.0))
    target_max = float(settings.get("target_max", 255.0))
    curve = str(settings.get("curve", "linear")).lower()
    if not 0.0 <= source_min < source_max <= 255.0:
        raise ValueError(f"Invalid alpha source range for {family}: {settings}")
    if not 0.0 <= target_min <= target_max <= 255.0:
        raise ValueError(f"Invalid alpha target range for {family}: {settings}")
    if curve not in {"linear", "smoothstep"}:
        raise ValueError(f"Unsupported alpha remap curve for {family}: {curve}")
    lookup: list[int] = []
    for value in range(256):
        amount = max(0.0, min(1.0, (value - source_min) / (source_max - source_min)))
        if curve == "smoothstep":
            amount = amount * amount * (3.0 - 2.0 * amount)
        remapped = target_min + (target_max - target_min) * amount
        lookup.append(max(0, min(255, round(remapped))))
    return alpha.point(lookup)


def create_alpha_derivative(
    ctx: Context, family: str, family_data: dict[str, Any], force: bool
) -> tuple[Path, str]:
    try:
        from PIL import Image
    except ImportError as exc:
        raise RuntimeError(
            "Pillow is required for separate-alpha material families. "
            "Install dependencies from tools/steamtek-environment-intake/requirements.txt."
        ) from exc
    maps = family_data["maps"]
    base_path = REPO_ROOT / maps["base_color"]
    alpha_path = REPO_ROOT / maps["alpha"]
    profile = material_profile(ctx, family)
    with Image.open(base_path) as base_image, Image.open(alpha_path) as alpha_image:
        rgba = base_image.convert("RGBA")
        alpha = alpha_image.convert("L")
        if rgba.size != alpha.size:
            raise ValueError(f"Alpha dimensions do not match BaseColor for {family}")
        alpha = remap_alpha_image(
            alpha,
            profile.get("alpha_remap", {}),
            family,
        )
        rgba.putalpha(alpha)
        buffer = io.BytesIO()
        rgba.save(buffer, format="PNG", optimize=False)
    output = derived_alpha_path(ctx, family)
    state = write_if_changed(output, buffer.getvalue(), force=force)
    return output, state


def godot_material_text(
    ctx: Context,
    family: str,
    family_data: dict[str, Any],
    albedo_path: Path,
) -> str:
    maps = family_data["maps"]
    profile = material_profile(ctx, family)
    textures: list[tuple[str, Path]] = [("albedo", albedo_path)]
    for map_type in ("metallic", "roughness", "normal", "ao", "emission"):
        if map_type in maps:
            textures.append((map_type, REPO_ROOT / maps[map_type]))
    ext_lines = [
        f'[ext_resource type="Texture2D" path="{res_path(path)}" id="{index}_{kind}"]'
        for index, (kind, path) in enumerate(textures, start=1)
    ]
    ids = {
        kind: f"{index}_{kind}"
        for index, (kind, _) in enumerate(textures, start=1)
    }
    resource_lines = [
        f'resource_name = "STK_MAT_{slug(family)}"',
        "albedo_color = Color(1, 1, 1, 1)",
        f'albedo_texture = ExtResource("{ids["albedo"]}")',
    ]
    if "metallic" in ids:
        resource_lines.extend(
            [
                "metallic = 1.0",
                f'metallic_texture = ExtResource("{ids["metallic"]}")',
                "metallic_texture_channel = 0",
            ]
        )
    else:
        resource_lines.append("metallic = 0.0")
    if "roughness" in ids:
        resource_lines.extend(
            [
                "roughness = 1.0",
                f'roughness_texture = ExtResource("{ids["roughness"]}")',
                "roughness_texture_channel = 0",
            ]
        )
    else:
        resource_lines.append("roughness = 0.75")
    if "normal" in ids:
        resource_lines.extend(
            [
                "normal_enabled = true",
                f'normal_texture = ExtResource("{ids["normal"]}")',
                "normal_scale = 1.0",
            ]
        )
    if "ao" in ids:
        resource_lines.extend(
            [
                "ao_enabled = true",
                f'ao_texture = ExtResource("{ids["ao"]}")',
                "ao_texture_channel = 0",
                "ao_light_affect = 0.65",
            ]
        )
    if "emission" in ids:
        emission_operator_name = str(
            profile.get("emission_operator", "multiply")
        ).lower()
        emission_operators = {"add": 0, "multiply": 1}
        if emission_operator_name not in emission_operators:
            raise ValueError(
                f"Unsupported emission operator for {family}: {emission_operator_name}"
            )
        emission_energy = float(profile.get("emission_energy_multiplier", 0.8))
        if not 0.0 <= emission_energy <= 16.0:
            raise ValueError(f"Invalid emission energy for {family}: {emission_energy}")
        resource_lines.extend(
            [
                "emission_enabled = true",
                f"emission_operator = {emission_operators[emission_operator_name]}",
                "emission = Color(1, 1, 1, 1)",
                f'emission_texture = ExtResource("{ids["emission"]}")',
                f"emission_energy_multiplier = {fmt_float(emission_energy)}",
            ]
        )
    if "alpha" in maps:
        transparency_name = str(
            profile.get("transparency", "alpha_depth_prepass")
        ).lower()
        transparency_modes = {
            "alpha": 1,
            "alpha_scissor": 2,
            "alpha_hash": 3,
            "alpha_depth_prepass": 4,
        }
        if transparency_name not in transparency_modes:
            raise ValueError(
                f"Unsupported transparency mode for {family}: {transparency_name}"
            )
        two_sided = bool(profile.get("two_sided", True))
        resource_lines.extend(
            [
                f"transparency = {transparency_modes[transparency_name]}",
                "blend_mode = 0",
                "depth_draw_mode = 0",
                f"cull_mode = {2 if two_sided else 0}",
            ]
        )
    return (
        f'[gd_resource type="StandardMaterial3D" load_steps={len(textures) + 1} format=3]\n\n'
        + "\n".join(ext_lines)
        + "\n\n[resource]\n"
        + "\n".join(resource_lines)
        + "\n"
    )


def generate_materials(
    ctx: Context,
    plans: list[dict[str, Any]],
    families: dict[str, dict[str, Any]],
    force: bool,
) -> tuple[dict[str, Path], dict[str, str], set[Path]]:
    used_families = sorted(
        {
            family
            for plan in plans
            for family in plan["material_overrides"].values()
        },
        key=str.casefold,
    )
    material_paths: dict[str, Path] = {}
    states: dict[str, str] = {}
    used_textures: set[Path] = set()
    for family in used_families:
        if family not in families:
            raise ValueError(f"Texture family does not exist: {family}")
        family_data = families[family]
        maps = family_data["maps"]
        if "base_color" not in maps:
            raise ValueError(f"Texture family has no BaseColor: {family}")
        if "alpha" in maps:
            albedo_path, alpha_state = create_alpha_derivative(
                ctx, family, family_data, force
            )
            states[posix_relative(albedo_path)] = alpha_state
            used_textures.add(albedo_path)
        else:
            albedo_path = REPO_ROOT / maps["base_color"]
        for texture_relative in maps.values():
            used_textures.add(REPO_ROOT / texture_relative)
        output = material_path(ctx, family)
        text = godot_material_text(ctx, family, family_data, albedo_path)
        states[posix_relative(output)] = write_text_if_changed(
            output, text, force=force
        )
        material_paths[family] = output
    return material_paths, states, used_textures


def backup_import_metadata(ctx: Context, paths: Iterable[Path]) -> str:
    output = ctx.reports_root / "Import_Metadata_PrePilot.json"
    existing_report: dict[str, Any] = {}
    if output.exists():
        existing_report = json.loads(output.read_text(encoding="utf-8"))
    entries_by_path = {
        str(entry["path"]): entry
        for entry in existing_report.get("entries", [])
    }
    initial_count = len(entries_by_path)
    for source in sorted(set(paths), key=lambda value: str(value).casefold()):
        sidecar = Path(str(source) + ".import")
        if not sidecar.exists():
            continue
        relative = posix_relative(sidecar)
        if relative not in entries_by_path:
            entries_by_path[relative] = {
                "path": relative,
                "sha256": sha256_file(sidecar),
                "content": sidecar.read_text(encoding="utf-8"),
            }
    if (
        output.exists()
        and len(entries_by_path) == initial_count
        and existing_report.get("schema") == "SteamtekImportMetadataBackup-2"
    ):
        return "unchanged"
    created_utc = existing_report.get("created_utc") or existing_report.get(
        "generated_utc"
    ) or utc_now()
    return write_if_changed(
        output,
        json_bytes(
            {
                "schema": "SteamtekImportMetadataBackup-2",
                "created_utc": created_utc,
                "updated_utc": utc_now(),
                "classification": "mutable_godot_generated_metadata",
                "merge_policy": "append_original_once_never_overwrite",
                "entries": [
                    entries_by_path[path]
                    for path in sorted(entries_by_path, key=str.casefold)
                ],
            }
        ),
    )


def restore_import_metadata(ctx: Context) -> dict[str, Any]:
    backup_path = ctx.reports_root / "Import_Metadata_PrePilot.json"
    if not backup_path.exists():
        raise FileNotFoundError(f"Missing import metadata backup: {backup_path}")
    backup = json.loads(backup_path.read_text(encoding="utf-8"))
    restored: list[str] = []
    unchanged: list[str] = []
    for entry in backup.get("entries", []):
        relative = str(entry["path"])
        target = (REPO_ROOT / relative).resolve()
        try:
            target.relative_to(ctx.pack_root.resolve())
        except ValueError as error:
            raise ValueError(f"Backup path escapes this pack: {relative}") from error
        if target.suffix.lower() != ".import":
            raise ValueError(f"Backup target is not a Godot .import sidecar: {relative}")
        content = str(entry["content"])
        state = write_text_if_changed(target, content)
        (restored if state != "unchanged" else unchanged).append(relative)
        if sha256_file(target) != str(entry["sha256"]):
            raise RuntimeError(f"Restored sidecar hash mismatch: {relative}")
    return {
        "schema": "SteamtekImportMetadataRestore-1",
        "backup": posix_relative(backup_path),
        "restored": restored,
        "unchanged": unchanged,
        "verified_count": len(restored) + len(unchanged),
    }

def replace_import_parameter(text: str, key: str, value: str) -> str:
    expression = re.compile(rf"^{re.escape(key)}=.*$", re.MULTILINE)
    if not expression.search(text):
        return text
    return expression.sub(f"{key}={value}", text)


def patch_import_sidecar(
    source: Path,
    kind: str,
    normal_invert_y: bool = False,
    roughness_normal: Path | None = None,
) -> str:
    sidecar = Path(str(source) + ".import")
    if not sidecar.exists():
        return "missing_pending_first_godot_import"
    original = sidecar.read_text(encoding="utf-8")
    text = original
    if kind == "fbx":
        text = replace_import_parameter(text, "animation/import", "false")
    else:
        text = replace_import_parameter(text, "compress/mode", "2")
        text = replace_import_parameter(text, "mipmaps/generate", "true")
        text = replace_import_parameter(text, "detect_3d/compress_to", "0")
        if kind == "normal":
            text = replace_import_parameter(text, "compress/normal_map", "1")
            text = replace_import_parameter(text, "roughness/mode", "0")
            text = replace_import_parameter(text, "roughness/src_normal", '""')
            text = replace_import_parameter(
                text,
                "process/normal_map_invert_y",
                "true" if normal_invert_y else "false",
            )
        elif kind == "roughness":
            text = replace_import_parameter(text, "compress/normal_map", "0")
            text = replace_import_parameter(
                text, "roughness/mode", "1" if roughness_normal is not None else "0"
            )
            text = replace_import_parameter(
                text,
                "roughness/src_normal",
                json.dumps(res_path(roughness_normal))
                if roughness_normal is not None
                else '""',
            )
            text = replace_import_parameter(
                text, "process/normal_map_invert_y", "false"
            )
        else:
            text = replace_import_parameter(text, "compress/normal_map", "0")
            text = replace_import_parameter(text, "roughness/mode", "0")
            text = replace_import_parameter(text, "roughness/src_normal", '""')
            text = replace_import_parameter(
                text, "process/normal_map_invert_y", "false"
            )
    if text == original:
        return "unchanged"
    sidecar.write_text(text, encoding="utf-8", newline="\n")
    return "changed"


def fmt_float(value: float) -> str:
    if abs(value) < 0.0000005:
        return "0"
    return f"{value:.6f}".rstrip("0").rstrip(".")


def fmt_vector3(values: list[float]) -> str:
    return "Vector3(" + ", ".join(fmt_float(value) for value in values) + ")"


def packed_strings(values: Iterable[str]) -> str:
    return "PackedStringArray(" + ", ".join(json.dumps(value) for value in values) + ")"


def snap_marker_specs(plan: dict[str, Any]) -> list[dict[str, Any]]:
    dimensions = plan["dimensions_m"]
    contract = plan["modular_contract"]
    role = contract["primary_socket_role"]
    axis = contract["snap_axis"]
    markers: list[dict[str, Any]] = []
    if role in CHAIN_SOCKET_ROLES and axis in {"x", "y", "z"}:
        if axis == "x":
            endpoints = [("Snap_Left", [-dimensions[0] * 0.5, 0.0, 0.0], [-1.0, 0.0, 0.0], -1), ("Snap_Right", [dimensions[0] * 0.5, 0.0, 0.0], [1.0, 0.0, 0.0], 1)]
        elif axis == "z":
            endpoints = [("Snap_Back", [0.0, 0.0, -dimensions[2] * 0.5], [0.0, 0.0, -1.0], -1), ("Snap_Front", [0.0, 0.0, dimensions[2] * 0.5], [0.0, 0.0, 1.0], 1)]
        else:
            endpoints = [("Snap_Bottom", [0.0, 0.0, 0.0], [0.0, -1.0, 0.0], -1), ("Snap_Top", [0.0, dimensions[1], 0.0], [0.0, 1.0, 0.0], 1)]
        for name, position, normal, polarity in endpoints:
            marker = {"name": name, "position": position, "role": role, "normal": normal}
            if role == "street_sidewalk_chain":
                marker["polarity"] = polarity
            markers.append(marker)
    elif role == "prop_anchor":
        markers.append({"name": "PropAnchor", "position": [0.0, 0.0, 0.0], "role": role})
    if plan["category"] == "Road" and contract["classification"] == "structural_modular":
        markers.extend([
            {"name": "RoadEdge_Left", "position": [-dimensions[0] * 0.5, dimensions[1], 0.0], "role": "street_road_edge", "normal": [-1.0, 0.0, 0.0]},
            {"name": "RoadEdge_Right", "position": [dimensions[0] * 0.5, dimensions[1], 0.0], "role": "street_road_edge", "normal": [1.0, 0.0, 0.0]},
        ])
    elif plan["category"] == "Floor":
        if role == "street_sidewalk_chain":
            markers.append({"name": "SidewalkRoadEdge", "position": [0.0, dimensions[1], -dimensions[2] * 0.5], "role": "street_sidewalk_road_edge", "normal": [0.0, 0.0, -1.0]})
        elif role == "street_curb_chain":
            markers.extend([
                {"name": "CurbRoadEdge", "position": [0.0, dimensions[1], -dimensions[2] * 0.5], "role": "street_curb_road_edge", "normal": [0.0, 0.0, -1.0]},
                {"name": "CurbSidewalkEdge", "position": [0.0, dimensions[1], dimensions[2] * 0.5], "role": "street_curb_sidewalk_edge", "normal": [0.0, 0.0, 1.0]},
            ])
    return markers

def wrapper_scene_text(
    ctx: Context,
    plan: dict[str, Any],
    material_paths: dict[str, Path],
) -> str:
    collision = plan["collision"]
    root_type = "StaticBody3D" if collision == "box" else "Node3D"
    external_resources = [
        (
            "PackedScene",
            res_path(ctx.pack_root / plan["source"]),
            "1_source",
        ),
        ("Script", res_path(MATERIAL_BINDER), "2_binder"),
    ]
    for index, family in enumerate(
        sorted(set(plan["material_overrides"].values()), key=str.casefold),
        start=3,
    ):
        external_resources.append(
            ("Material", res_path(material_paths[family]), f"{index}_mat")
        )
    material_ids = {
        family: resource_id
        for family, (_, _, resource_id) in zip(
            sorted(set(plan["material_overrides"].values()), key=str.casefold),
            external_resources[2:],
            strict=True,
        )
    }
    ext_lines = [
        f'[ext_resource type="{resource_type}" path="{path}" id="{resource_id}"]'
        for resource_type, path, resource_id in external_resources
    ]
    sub_lines: list[str] = []
    if collision == "box":
        sub_lines = [
            '[sub_resource type="BoxShape3D" id="BoxShape3D_collision"]',
            f'size = {fmt_vector3(plan["dimensions_m"])}',
        ]
    bindings = ", ".join(
        f"{json.dumps(source_name)}: ExtResource({json.dumps(material_ids[family])})"
        for source_name, family in sorted(plan["material_overrides"].items())
    )
    dimensions = plan["dimensions_m"]
    contract = plan["modular_contract"]
    marker_specs = snap_marker_specs(plan)
    attachment_marker_count = 2 if plan["category"] == "Walls" else (1 if plan["category"] == "Road" else 0)
    total_snap_points = len(marker_specs) + attachment_marker_count
    root_lines = [
        f'[node name="{plan["production_name"]}" type="{root_type}" groups=["steamtek_live3d_modular"]]',
        'editor_description = "Generated Steamtek environment intake wrapper. Source geometry remains immutable; materials are shared external resources."',
        'script = ExtResource("2_binder")',
        f"material_bindings = {{{bindings}}}",
    ]
    if root_type == "StaticBody3D":
        root_lines.extend(["collision_layer = 1", "collision_mask = 0"])
    root_lines.extend(
        [
            'metadata/module_system = "live3d_meter_v1"',
            f'metadata/module_type = "{plan["category"].lower().replace(" ", "_")}"',
            f'metadata/module_family = "{ctx.config["pack_id"]}"',
            f'metadata/module_variant = "{plan["production_name"]}"',
            f'metadata/source_asset = "{res_path(ctx.pack_root / plan["source"])}"',
            'metadata/source_format = "FBX_provisional_geometry_authority"',
            'metadata/source_protection = "immutable_vendor_source"',
            f'metadata/source_sha256 = "{plan["source_sha256"]}"',
            f'metadata/dimensions_m = {fmt_vector3(dimensions)}',
            f'metadata/pivot_offset_m = {fmt_vector3(plan["visual_offset_m"])}',
            f'metadata/pivot = "{plan["pivot"]}"',
            'metadata/front_axis = "+Z"',
            'metadata/front_axis_status = "requires_normal_editor_confirmation"',
            'metadata/rotation_contract = "Yaw only: 0, 90, 180, or 270 degrees"',
            f'metadata/collision_policy = "{collision}"',
            f'metadata/triangle_count = {plan["triangles"]}',
            f'metadata/material_families = {packed_strings(sorted(set(plan["material_overrides"].values())))}',
            f'metadata/production_status = "{plan["production_status"]}"',
            f'metadata/modular_classification = "{contract["classification"]}"',
            f'metadata/primary_socket_role = "{contract["primary_socket_role"]}"',
            f'metadata/snap_axis = "{contract["snap_axis"]}"',
            f'metadata/snap_point_count = {total_snap_points}',
            f'metadata/rejected_modular_candidate = {str(contract["rejected_modular_candidate"]).lower()}',
            f'metadata/rejection_reason = "{contract["rejection_reason"]}"',
            'metadata/builder_candidate = true',
            'metadata/builder_registration_enabled = false',
            f'metadata/builder_parent = "{builder_parent(plan)}"',
            f'metadata/builder_profile = "{contract["builder_profile"]}"',
        ]
    )
    visual_lines = [
        '[node name="Visuals" type="Node3D" parent="."]',
        f'position = {fmt_vector3(plan["visual_offset_m"])}',
        "",
        '[node name="ImportedSource" parent="Visuals" instance=ExtResource("1_source")]',
    ]
    collision_lines: list[str] = []
    if collision == "box":
        collision_lines = [
            '[node name="Collision" type="CollisionShape3D" parent="."]',
            f"position = Vector3(0, {fmt_float(dimensions[1] * 0.5)}, 0)",
            'shape = SubResource("BoxShape3D_collision")',
        ]
    socket_lines = ['[node name="SnapPoints" type="Node3D" parent="."]']
    for marker in marker_specs:
        socket_lines.extend([
            "",
            f'[node name="{marker["name"]}" type="Marker3D" parent="SnapPoints" groups=["steamtek_live3d_snap"]]',
            f'position = {fmt_vector3(marker["position"])}',
            f'metadata/socket_role = "{marker["role"]}"',
        ])
        if "normal" in marker:
            socket_lines.append(f'metadata/socket_normal_local = {fmt_vector3(marker["normal"])}')
        if "polarity" in marker:
            socket_lines.append(f'metadata/socket_polarity = {marker["polarity"]}')
    attachment_lines: list[str] = []
    if plan["category"] == "Walls":
        attachment_lines = [
            '[node name="AttachmentPoints" type="Node3D" parent="."]',
            "",
            '[node name="Attach_Front_Center" type="Marker3D" parent="AttachmentPoints" groups=["steamtek_attachment_point", "steamtek_live3d_snap"]]',
            f"position = Vector3(0, {fmt_float(dimensions[1] * 0.5)}, {fmt_float(dimensions[2] * 0.5 + 0.001)})",
            "metadata/attachment_normal = Vector3(0, 0, 1)",
            "metadata/socket_normal_local = Vector3(0, 0, 1)",
            'metadata/socket_role = "wall_prop_surface"',
            "",
            '[node name="Attach_Front_Top_Center" type="Marker3D" parent="AttachmentPoints" groups=["steamtek_attachment_point", "steamtek_live3d_snap"]]',
            f"position = Vector3(0, {fmt_float(dimensions[1])}, {fmt_float(dimensions[2] * 0.5 + 0.001)})",
            "metadata/attachment_normal = Vector3(0, 0, 1)",
            "metadata/socket_normal_local = Vector3(0, 0, 1)",
            'metadata/socket_role = "wall_prop_surface"',
            'metadata/attachment_surface = "top_of_wall"',
        ]
    elif plan["category"] == "Road":
        attachment_lines = [
            '[node name="AttachmentPoints" type="Node3D" parent="."]',
            "",
            '[node name="Attach_Surface_Center" type="Marker3D" parent="AttachmentPoints" groups=["steamtek_attachment_point", "steamtek_live3d_snap"]]',
            f"position = Vector3(0, {fmt_float(dimensions[1] + 0.001)}, 0)",
            "metadata/attachment_normal = Vector3(0, 1, 0)",
            "metadata/socket_normal_local = Vector3(0, 1, 0)",
            'metadata/socket_role = "floor_prop_surface"',
        ]
    sections = [
        f"[gd_scene load_steps={len(external_resources) + len(sub_lines) // 2 + 1} format=3]",
        "\n".join(ext_lines),
    ]
    if sub_lines:
        sections.append("\n".join(sub_lines))
    sections.extend(
        [
            "\n".join(root_lines),
            "\n".join(visual_lines),
        ]
    )
    if collision_lines:
        sections.append("\n".join(collision_lines))
    sections.append("\n".join(socket_lines))
    if attachment_lines:
        sections.append("\n".join(attachment_lines))
    return "\n\n".join(sections) + "\n"


def generate_wrappers(
    ctx: Context,
    plans: list[dict[str, Any]],
    material_paths: dict[str, Path],
    force: bool,
) -> dict[str, str]:
    states: dict[str, str] = {}
    for plan in plans:
        text = wrapper_scene_text(ctx, plan, material_paths)
        states[posix_relative(plan["scene_path"])] = write_text_if_changed(
            plan["scene_path"], text, force=force
        )
    return states


def pilot_scene_path(ctx: Context) -> Path:
    return (
        ctx.output_root
        / f"Scenes/Tests/STK_SCN_{slug(ctx.config['pack_id'])}_IntakePilot.tscn"
    )


def pilot_scene_text(ctx: Context, plans: list[dict[str, Any]]) -> str:
    ext_resources = [
        ("Script", res_path(PILOT_REVIEW_SCRIPT), "1_review"),
    ]
    for index, plan in enumerate(plans, start=2):
        ext_resources.append(
            ("PackedScene", res_path(plan["scene_path"]), f"{index}_asset")
        )
    ext_lines = [
        f'[ext_resource type="{kind}" path="{path}" id="{resource_id}"]'
        for kind, path, resource_id in ext_resources
    ]
    sections = [
        f"[gd_scene load_steps={len(ext_resources) + 8} format=3]",
        "\n".join(ext_lines),
        "\n".join(
            [
                '[sub_resource type="Environment" id="Environment_pilot"]',
                "background_mode = 1",
                "background_color = Color(0.18, 0.18, 0.18, 1)",
                "background_energy_multiplier = 1.0",
                "ambient_light_source = 2",
                "ambient_light_color = Color(1, 1, 1, 1)",
                "ambient_light_energy = 0.3",
                "ambient_light_sky_contribution = 0.0",
                "reflected_light_source = 0",
                "tonemap_mode = 4",
                "tonemap_exposure = 0.9",
                "tonemap_agx_contrast = 1.0",
                "tonemap_agx_white = 8.0",
                "glow_enabled = false",
                "adjustment_enabled = false",
                "fog_enabled = false",
                "volumetric_fog_enabled = false",
                "ssao_enabled = false",
                "ssil_enabled = false",
                "ssr_enabled = false",
            ]
        ),
        "\n".join(
            [
                '[sub_resource type="CameraAttributesPractical" id="CameraAttributes_pilot"]',
                "exposure_multiplier = 1.0",
                "auto_exposure_enabled = false",
                "dof_blur_near_enabled = false",
                "dof_blur_far_enabled = false",
            ]
        ),
        "\n".join(
            [
                '[sub_resource type="StandardMaterial3D" id="GroundMaterial"]',
                "albedo_color = Color(0.18, 0.18, 0.18, 1)",
                "metallic = 0.0",
                "roughness = 1.0",
            ]
        ),
        "\n".join(
            [
                '[sub_resource type="PlaneMesh" id="GroundMesh"]',
                'material = SubResource("GroundMaterial")',
                "size = Vector2(48, 48)",
            ]
        ),
        "\n".join(
            [
                '[sub_resource type="StandardMaterial3D" id="WitnessLightMaterial"]',
                "albedo_color = Color(0.72, 0.72, 0.72, 1)",
                "shading_mode = 0",
            ]
        ),
        "\n".join(
            [
                '[sub_resource type="StandardMaterial3D" id="WitnessDarkMaterial"]',
                "albedo_color = Color(0.06, 0.06, 0.06, 1)",
                "shading_mode = 0",
            ]
        ),
        "\n".join(
            [
                '[sub_resource type="BoxMesh" id="WitnessTileMesh"]',
                "size = Vector3(2.22, 0.7, 0.02)",
            ]
        ),
        "\n".join(
            [
                f'[node name="STK_SCN_{slug(ctx.config["pack_id"])}_IntakePilot" type="Node3D"]',
                'editor_description = "Technical pilot for the permanent Steamtek environment intake pipeline. F6 visual approval is still required."',
                'script = ExtResource("1_review")',
                'metadata/production_status = "pilot_pending_normal_editor_approval"',
                "metadata/review_camera_target = Vector3(0.077605, 0.874598, -0.149413)",
            ]
        ),
        "\n".join(
            [
                '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]',
                'environment = SubResource("Environment_pilot")',
                'camera_attributes = SubResource("CameraAttributes_pilot")',
                "",
                '[node name="KeyLight" type="DirectionalLight3D" parent="."]',
                "rotation_degrees = Vector3(-48, -38, 0)",
                "light_color = Color(1, 1, 1, 1)",
                "light_energy = 0.7",
                "light_specular = 1.0",
                "shadow_enabled = true",
                "",
                '[node name="QAReviewCamera" type="Camera3D" parent="."]',
                "position = Vector3(18, 16, 18)",
                "projection = 1",
                "size = 10.5",
                "keep_aspect = 1",
                "current = true",
                "",
                '[node name="ReviewGround" type="MeshInstance3D" parent="."]',
                "position = Vector3(0, -0.025, 0)",
                'mesh = SubResource("GroundMesh")',
                "",
                '[node name="WindowTransparencyWitness" type="Node3D" parent="."]',
                "visible = false",
                "position = Vector3(-4.5, 0.812, -2.72)",
                "",
                '[node name="TopLeft" type="MeshInstance3D" parent="WindowTransparencyWitness"]',
                "position = Vector3(-1.12, 0.36, 0)",
                'mesh = SubResource("WitnessTileMesh")',
                'material_override = SubResource("WitnessLightMaterial")',
                "",
                '[node name="TopRight" type="MeshInstance3D" parent="WindowTransparencyWitness"]',
                "position = Vector3(1.12, 0.36, 0)",
                'mesh = SubResource("WitnessTileMesh")',
                'material_override = SubResource("WitnessDarkMaterial")',
                "",
                '[node name="BottomLeft" type="MeshInstance3D" parent="WindowTransparencyWitness"]',
                "position = Vector3(-1.12, -0.36, 0)",
                'mesh = SubResource("WitnessTileMesh")',
                'material_override = SubResource("WitnessDarkMaterial")',
                "",
                '[node name="BottomRight" type="MeshInstance3D" parent="WindowTransparencyWitness"]',
                "position = Vector3(1.12, -0.36, 0)",
                'mesh = SubResource("WitnessTileMesh")',
                'material_override = SubResource("WitnessLightMaterial")',
            ]
        ),
    ]
    for index, plan in enumerate(plans, start=2):
        position = plan["pilot_position"]
        sections.append(
            "\n".join(
                [
                    f'[node name="{plan["production_name"]}" parent="." instance=ExtResource("{index}_asset")]',
                    f"position = {fmt_vector3(position)}",
                    "",
                    f'[node name="Label_{plan["production_name"]}" type="Label3D" parent="."]',
                    f"position = {fmt_vector3([position[0], plan['dimensions_m'][1] + 0.55, position[2]])}",
                    f"text = {json.dumps(plan['production_name'])}",
                    "font_size = 24",
                    "outline_size = 6",
                    "billboard = 1",
                    "no_depth_test = true",
                ]
            )
        )
    for index, plan in enumerate(plans, start=2):
        socket_role = plan["socket_role"]
        if socket_role not in {"facade_horizontal", "street_road_chain"}:
            continue
        axis = plan["modular_contract"]["snap_axis"]
        axis_index = {"x": 0, "y": 1, "z": 2}[axis]
        for ordinal in (2, 3):
            duplicate_position = list(plan["pilot_position"])
            duplicate_position[axis_index] += plan["dimensions_m"][axis_index] * (ordinal - 1)
            duplicate_name = f'{plan["production_name"]}_Snap_Duplicate_{ordinal}'
            sections.append(
                "\n".join(
                    [
                        f'[node name="{duplicate_name}" parent="." instance=ExtResource("{index}_asset")]',
                        f"position = {fmt_vector3(duplicate_position)}",
                        "",
                        f'[node name="Label_{duplicate_name}" type="Label3D" parent="."]',
                        f"position = {fmt_vector3([duplicate_position[0], plan['dimensions_m'][1] + 0.55, duplicate_position[2]])}",
                        f"text = {json.dumps(plan['production_name'] + ' THREE-PIECE SNAP/SEAM')}",
                        "font_size = 22",
                        "outline_size = 6",
                        "billboard = 1",
                        "no_depth_test = true",
                    ]
                )
            )
    wall_entry = next(((index, plan) for index, plan in enumerate(plans, start=2) if plan["category"] == "Walls"), None)
    sign_entry = next(((index, plan) for index, plan in enumerate(plans, start=2) if plan["category"] == "Signs"), None)
    if wall_entry and sign_entry:
        wall_index, wall_plan = wall_entry
        sign_index, sign_plan = sign_entry
        attachment_position = list(wall_plan["pilot_position"])
        attachment_position[1] += wall_plan["dimensions_m"][1] * 0.5
        attachment_position[2] += wall_plan["dimensions_m"][2] * 0.5 + 0.001
        sections.append(
            "\n".join(
                [
                    f'[node name="{sign_plan["production_name"]}_Attachment_Test" parent="." instance=ExtResource("{sign_index}_asset")]',
                    f"position = {fmt_vector3(attachment_position)}",
                    "",
                    '[node name="Label_Attachment_Test" type="Label3D" parent="."]',
                    f"position = {fmt_vector3([attachment_position[0], attachment_position[1] + sign_plan['dimensions_m'][1] + 0.55, attachment_position[2]])}",
                    'text = "COMPATIBLE SIGN ATTACHMENT TEST"',
                    "font_size = 22",
                    "outline_size = 6",
                    "billboard = 1",
                    "no_depth_test = true",
                ]
            )
        )
    sections.append(
        "\n".join(
            [
                '[node name="ReviewBoundary" type="Label3D" parent="."]',
                "position = Vector3(0, 5.8, 0)",
                'text = "TECHNICAL PILOT - NORMAL EDITOR / F6 VISUAL APPROVAL REQUIRED"',
                "font_size = 30",
                "outline_size = 8",
                "modulate = Color(1, 0.72, 0.28, 1)",
                "billboard = 1",
                "no_depth_test = true",
            ]
        )
    )
    return "\n\n".join(sections) + "\n"


def regenerate_pilot_scene(
    ctx: Context,
    force: bool,
) -> dict[str, Any]:
    configured_pilot = ctx.config.get("pilot_assets", [])
    if not isinstance(configured_pilot, list) or len(configured_pilot) != 6:
        count = len(configured_pilot) if isinstance(configured_pilot, list) else "non-list"
        raise ValueError(
            "Scene-only pilot regeneration requires exactly six configured "
            f"pilot_assets; found {count}."
        )
    configured_sources = [str(item["source"]) for item in configured_pilot]
    if len(set(configured_sources)) != len(configured_sources):
        raise ValueError("Configured pilot_assets contains duplicate source entries.")

    probe = load_probe(ctx)
    probe_sources = probe_by_relative_source(ctx, probe)
    missing_probe_sources = [
        source for source in configured_sources if source not in probe_sources
    ]
    if missing_probe_sources:
        raise FileNotFoundError(
            "Configured pilot sources are missing from the existing probe: "
            + ", ".join(missing_probe_sources)
        )

    plans = select_plans(
        ctx,
        probe,
        "pilot",
        asset_filter=None,
        category_filter=None,
    )
    missing_wrappers = [
        plan["scene_path"] for plan in plans if not plan["scene_path"].is_file()
    ]
    if missing_wrappers:
        raise FileNotFoundError(
            "Scene-only pilot regeneration requires all existing wrapper scenes; "
            "missing: "
            + ", ".join(str(path) for path in missing_wrappers)
        )

    scene_path = pilot_scene_path(ctx)
    scene_state = write_text_if_changed(scene_path, pilot_scene_text(ctx, plans), force=force)
    for plan in plans:
        plan["production_status"] = production_status_for_scope("pilot")
    family_names = sorted({family for plan in plans for family in plan["material_overrides"].values()}, key=str.casefold)
    material_paths = {family: material_path(ctx, family) for family in family_names}
    missing_materials = [path for path in material_paths.values() if not path.is_file()]
    if missing_materials:
        raise FileNotFoundError("Pilot manifest refresh requires existing shared materials: " + ", ".join(str(path) for path in missing_materials))
    manifest = {
        "schema": "SteamtekEnvironmentPilotManifest-2",
        "pipeline_version": PIPELINE_VERSION,
        "generated_utc": utc_now(),
        "pilot_scene": res_path(scene_path),
        "assets": [manifest_asset(ctx, plan, material_paths) for plan in plans],
        "snap_demonstrations": pilot_snap_demonstrations(plans),
        "attachment_demonstrations": pilot_attachment_demonstrations(plans),
        "material_qa": {
            "profiles": {family: {"material": res_path(material_paths[family]), **material_profile(ctx, family)} for family in family_names},
            "environment": ctx.config.get("pilot_qa", {}),
            "review_presets": ["overview", "wall_seam", "road_seam", "crate", "window_front", "window_rear", "emissive_sign"],
        },
        "approval_boundary": "technical_validation_then_normal_editor_f6_visual_approval",
    }
    manifest_path = ctx.reports_root / "Pilot_Manifest.json"
    manifest_state = write_if_changed(manifest_path, json_bytes(manifest), force=force)
    return {
        "schema": "SteamtekEnvironmentPilotSceneRegeneration-2",
        "pipeline_version": PIPELINE_VERSION,
        "scene": res_path(scene_path),
        "scene_write": scene_state,
        "manifest": res_path(manifest_path),
        "manifest_write": manifest_state,
        "asset_count": len(plans),
        "wrapper_scenes": [res_path(plan["scene_path"]) for plan in plans],
        "camera": {
            "node": "QAReviewCamera",
            "position": [18.0, 16.0, 18.0],
            "projection": "orthographic",
            "orthographic_size": 10.5,
            "keep_aspect": "keep_height",
            "target": [0.077605, 0.874598, -0.149413],
        },
        "writes_permitted": [res_path(scene_path), res_path(manifest_path)],
        "full_pack_generation": "preserved",
    }
def production_status_for_scope(scope: str) -> str:
    if scope == "pilot":
        return "pilot_pending_normal_editor_approval"
    return "full_generated_pending_category_visual_review"


def manifest_asset(
    ctx: Context,
    plan: dict[str, Any],
    material_paths: dict[str, Path],
) -> dict[str, Any]:
    return {
        "source": res_path(ctx.pack_root / plan["source"]),
        "source_sha256": plan["source_sha256"],
        "scene": res_path(plan["scene_path"]),
        "production_name": plan["production_name"],
        "dimensions_m": plan["dimensions_m"],
        "source_bounds_min_m": plan["source_bounds_min_m"],
        "source_bounds_max_m": plan["source_bounds_max_m"],
        "visual_offset_m": plan["visual_offset_m"],
        "vertices": plan["vertices"],
        "triangles": plan["triangles"],
        "collision": plan["collision"],
        "socket_role": plan["socket_role"],
        "expected_socket_count": (
            2 if plan["socket_role"] in CHAIN_SOCKET_ROLES else (1 if plan["socket_role"] == "prop_anchor" else 0)
        ),
        "snap_point_count": len(snap_marker_specs(plan)) + (2 if plan["category"] == "Walls" else (1 if plan["category"] == "Road" else 0)),
        "modular_contract": plan["modular_contract"],
        "builder_candidate": True,
        "builder_registration_enabled": False,
        "material_bindings": {
            source_name: res_path(material_paths[family])
            for source_name, family in sorted(plan["material_overrides"].items())
        },
        "materials": sorted(
            {
                res_path(material_paths[family])
                for family in plan["material_overrides"].values()
            }
        ),
        "status": plan["production_status"],
    }


def pilot_snap_demonstrations(plans: list[dict[str, Any]]) -> list[dict[str, Any]]:
    demonstrations: list[dict[str, Any]] = []
    for plan in plans:
        role = plan["socket_role"]
        if role not in {"facade_horizontal", "street_road_chain"}:
            continue
        axis = plan["modular_contract"]["snap_axis"]
        axis_index = {"x": 0, "y": 1, "z": 2}[axis]
        node_names = [
            plan["production_name"],
            f'{plan["production_name"]}_Snap_Duplicate_2',
            f'{plan["production_name"]}_Snap_Duplicate_3',
        ]
        for pair_index in range(2):
            demonstrations.append(
                {
                    "production_name": plan["production_name"],
                    "source_scene": res_path(plan["scene_path"]),
                    "first_node": node_names[pair_index],
                    "second_node": node_names[pair_index + 1],
                    "axis": axis,
                    "expected_separation_m": plan["dimensions_m"][axis_index],
                    "socket_role": role,
                    "validation": "exact_endpoint_pair_and_visual_aabb_seam",
                }
            )
    return demonstrations


def pilot_attachment_demonstrations(plans: list[dict[str, Any]]) -> list[dict[str, Any]]:
    wall = next((plan for plan in plans if plan["category"] == "Walls"), None)
    sign = next((plan for plan in plans if plan["category"] == "Signs"), None)
    if wall is None or sign is None:
        return []
    return [{
        "host_node": wall["production_name"],
        "host_marker": "AttachmentPoints/Attach_Front_Center",
        "attachment_node": f'{sign["production_name"]}_Attachment_Test',
        "attachment_marker": "SnapPoints/PropAnchor",
        "host_role": "wall_prop_surface",
        "attachment_role": "prop_anchor",
        "validation": "existing_live3d_builder_role_compatibility_and_marker_coincidence",
    }]


def builder_parent(plan: dict[str, Any]) -> str:
    category = plan["category"]
    if category in {"Props", "Signs", "Wall Props"}:
        return "Props"
    if category in {"Metal Panels", "Metal Sheets", "Pipes"}:
        return "Infrastructure"
    return "Architecture"


def builder_profile(plan: dict[str, Any]) -> str:
    return str(plan["modular_contract"]["builder_profile"])


def catalog_payload(ctx: Context, plans: list[dict[str, Any]]) -> dict[str, Any]:
    statuses = sorted({plan["production_status"] for plan in plans})
    return {
        "schema": "SteamtekLive3DBuilderCatalogCandidates-2",
        "pack_id": ctx.config["pack_id"],
        "approval_state": statuses[0] if len(statuses) == 1 else "mixed",
        "registration_enabled": False,
        "builder_registration_allowed": False,
        "placement_contract": "socket_only_pending_pack_grid_visual_approval",
        "entries": [
            {
                "label": plan["production_name"],
                "path": res_path(plan["scene_path"]),
                "parent": builder_parent(plan),
                "profile": builder_profile(plan),
                "category": plan["category"],
                "source": plan["source"],
                "approved": False,
                "production_status": plan["production_status"],
                "modular_classification": plan["modular_contract"]["classification"],
                "primary_socket_role": plan["modular_contract"]["primary_socket_role"],
                "snap_axis": plan["modular_contract"]["snap_axis"],
                "snap_point_count": len(snap_marker_specs(plan)) + (2 if plan["category"] == "Walls" else (1 if plan["category"] == "Road" else 0)),
                "rejected_modular_candidate": plan["modular_contract"]["rejected_modular_candidate"],
                "rejection_reason": plan["modular_contract"]["rejection_reason"],
                "builder_candidate": True,
                "builder_registration_enabled": False,
            }
            for plan in plans
        ],
    }


def mapping_rows(plans: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        {
            "source": plan["source"],
            "production_name": plan["production_name"],
            "scene": posix_relative(plan["scene_path"]),
            "category": plan["category"],
            "materials": ";".join(
                sorted(set(plan["material_overrides"].values()))
            ),
            "collision": plan["collision"],
            "pivot": plan["pivot"],
            "socket_role": plan["socket_role"],
            "modular_classification": plan["modular_contract"]["classification"],
            "snap_axis": plan["modular_contract"]["snap_axis"],
            "snap_point_count": len(snap_marker_specs(plan)) + (2 if plan["category"] == "Walls" else (1 if plan["category"] == "Road" else 0)),
            "rejection_reason": plan["modular_contract"]["rejection_reason"],
            "status": plan["production_status"],
        }
        for plan in plans
    ]


def write_catalog_and_mapping(
    ctx: Context,
    plans: list[dict[str, Any]],
    force: bool,
) -> dict[str, str]:
    catalog_path = ctx.output_root / "Catalog/Generated_Catalog_Candidates.json"
    catalog = catalog_payload(ctx, plans)
    entries_by_source: dict[str, dict[str, Any]] = {}
    if catalog_path.exists():
        existing_catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        if (
            existing_catalog.get("schema")
            == "SteamtekLive3DBuilderCatalogCandidates-2"
            and existing_catalog.get("pack_id") == ctx.config["pack_id"]
        ):
            entries_by_source.update(
                {
                    str(entry["source"]): entry
                    for entry in existing_catalog.get("entries", [])
                }
            )
    entries_by_source.update(
        {str(entry["source"]): entry for entry in catalog["entries"]}
    )
    catalog["entries"] = [
        entries_by_source[source]
        for source in sorted(entries_by_source, key=str.casefold)
    ]
    statuses = sorted(
        {str(entry["production_status"]) for entry in catalog["entries"]}
    )
    catalog["approval_state"] = statuses[0] if len(statuses) == 1 else "mixed"
    states = {
        "catalog_candidates": write_if_changed(
            catalog_path,
            json_bytes(catalog),
            force=force,
        )
    }

    mapping_path = ctx.reports_root / "Source_to_Production_Mapping.csv"
    rows_by_source: dict[str, dict[str, Any]] = {}
    if mapping_path.exists():
        with mapping_path.open("r", encoding="utf-8", newline="") as handle:
            rows_by_source.update(
                {
                    str(row["source"]): dict(row)
                    for row in csv.DictReader(handle)
                }
            )
    rows_by_source.update(
        {str(row["source"]): row for row in mapping_rows(plans)}
    )
    states["source_to_production_mapping"] = write_csv(
        mapping_path,
        [
            rows_by_source[source]
            for source in sorted(rows_by_source, key=str.casefold)
        ],
        [
            "source",
            "production_name",
            "scene",
            "category",
            "materials",
            "collision",
            "pivot",
            "socket_role",
            "modular_classification",
            "snap_axis",
            "snap_point_count",
            "rejection_reason",
            "status",
        ],
    )
    return states

def generate_pilot_outputs(
    ctx: Context,
    plans: list[dict[str, Any]],
    material_paths: dict[str, Path],
    force: bool,
) -> dict[str, str]:
    states = write_catalog_and_mapping(ctx, plans, force)
    scene_path = pilot_scene_path(ctx)
    states[posix_relative(scene_path)] = write_text_if_changed(
        scene_path,
        pilot_scene_text(ctx, plans),
        force=force,
    )
    manifest = {
        "schema": "SteamtekEnvironmentPilotManifest-2",
        "pipeline_version": PIPELINE_VERSION,
        "generated_utc": utc_now(),
        "pilot_scene": res_path(scene_path),
        "assets": [
            manifest_asset(ctx, plan, material_paths) for plan in plans
        ],
        "snap_demonstrations": pilot_snap_demonstrations(plans),
        "attachment_demonstrations": pilot_attachment_demonstrations(plans),
        "material_qa": {
            "profiles": {
                family: {
                    "material": res_path(material_paths[family]),
                    **material_profile(ctx, family),
                }
                for family in sorted(material_paths, key=str.casefold)
            },
            "environment": ctx.config.get("pilot_qa", {}),
            "review_presets": [
                "overview",
                "wall_seam",
                "road_seam",
                "crate",
                "window_front",
                "window_rear",
                "emissive_sign",
            ],
        },
        "approval_boundary": "technical_validation_then_normal_editor_f6_visual_approval",
    }
    states["pilot_manifest"] = write_if_changed(
        ctx.reports_root / "Pilot_Manifest.json",
        json_bytes(manifest),
        force=force,
    )
    return states


def generate_full_outputs(
    ctx: Context,
    plans: list[dict[str, Any]],
    material_paths: dict[str, Path],
    force: bool,
) -> dict[str, str]:
    states = write_catalog_and_mapping(ctx, plans, force)
    manifest = {
        "schema": "SteamtekEnvironmentFullManifest-1",
        "pipeline_version": PIPELINE_VERSION,
        "generated_utc": utc_now(),
        "assets": [
            manifest_asset(ctx, plan, material_paths) for plan in plans
        ],
        "approval_boundary": "generated_not_builder_registered_category_visual_review_required",
    }
    states["full_manifest"] = write_if_changed(
        ctx.reports_root / "Full_Manifest.json",
        json_bytes(manifest),
        force=force,
    )
    return states


def generate_selective_output(
    ctx: Context,
    plans: list[dict[str, Any]],
    material_paths: dict[str, Path],
    scope: str,
    run_label: str,
    force: bool,
) -> dict[str, str]:
    states = write_catalog_and_mapping(ctx, plans, force)
    manifest_path = (
        ctx.reports_root
        / f"Selective_{scope}_{slug(run_label)}_Manifest.json"
    )
    manifest = {
        "schema": "SteamtekEnvironmentSelectiveManifest-1",
        "pipeline_version": PIPELINE_VERSION,
        "generated_utc": utc_now(),
        "scope": scope,
        "selection": run_label,
        "assets": [
            manifest_asset(ctx, plan, material_paths) for plan in plans
        ],
        "global_catalog_and_mapping_preserved": True,
        "selected_catalog_and_mapping_rows_refreshed": True,
    }
    states["selective_manifest"] = write_if_changed(
        manifest_path, json_bytes(manifest), force=force
    )
    return states


def state_report_path(
    ctx: Context,
    asset_filter: str | None,
    category_filter: str | None,
) -> Path:
    if asset_filter:
        return ctx.reports_root / f"Intake_State_asset_{slug(asset_filter)}.json"
    if category_filter:
        return ctx.reports_root / f"Intake_State_category_{slug(category_filter)}.json"
    return ctx.reports_root / "Intake_State.json"

def build(
    ctx: Context,
    scope: str,
    asset_filter: str | None,
    category_filter: str | None,
    force: bool,
    approve_full_pack: bool,
) -> dict[str, Any]:
    if scope == "full" and not approve_full_pack:
        raise PermissionError(
            "Full-pack processing is approval-gated. Re-run with --approve-full-pack "
            "only after the pilot receives normal-editor/F6 visual approval."
        )

    baseline_report, baseline_state = verify_or_create_vendor_baseline(
        ctx, force=force
    )
    if not baseline_report["passed"]:
        raise RuntimeError(
            "Vendor source verification failed before production writes: "
            f"{baseline_report}"
        )

    probe, families, material_rows, inventory_states = write_inventory_outputs(
        ctx, force=force
    )
    unresolved = [row for row in material_rows if not row["resolved"]]
    if unresolved:
        raise RuntimeError(f"Unresolved material families: {unresolved}")
    plans = select_plans(
        ctx, probe, scope, asset_filter=asset_filter, category_filter=category_filter
    )
    production_status = production_status_for_scope(scope)
    for plan in plans:
        plan["production_status"] = production_status

    material_paths, material_states, used_textures = generate_materials(
        ctx, plans, families, force=force
    )
    import_sources = [ctx.pack_root / plan["source"] for plan in plans]
    backup_state = backup_import_metadata(ctx, [*import_sources, *used_textures])
    import_states: dict[str, str] = {}
    import_policy = ctx.config.get("import_policy", {})
    for source in import_sources:
        sidecar_key = posix_relative(Path(str(source) + ".import"))
        import_states[sidecar_key] = (
            patch_import_sidecar(source, "fbx")
            if bool(import_policy.get("static_geometry", False))
            else "unchanged_animation_policy_preserved"
        )
    normal_invert_y = bool(import_policy.get("normal_map_invert_y", False))
    roughness_normal_pairs: dict[Path, Path] = {}
    used_family_names = {
        family
        for plan in plans
        for family in plan["material_overrides"].values()
    }
    for family in used_family_names:
        maps = families[family]["maps"]
        if "roughness" in maps and "normal" in maps:
            roughness_normal_pairs[
                (REPO_ROOT / maps["roughness"]).resolve()
            ] = (REPO_ROOT / maps["normal"]).resolve()
    for texture in used_textures:
        map_type = classify_texture_map(texture)
        kind = (
            "normal"
            if map_type == "normal"
            else "roughness"
            if map_type == "roughness"
            else "texture"
        )
        import_states[posix_relative(Path(str(texture) + ".import"))] = (
            patch_import_sidecar(
                texture,
                kind,
                normal_invert_y=normal_invert_y,
                roughness_normal=roughness_normal_pairs.get(texture.resolve()),
            )
        )
    wrapper_states = generate_wrappers(ctx, plans, material_paths, force=force)

    scope_states: dict[str, str]
    if asset_filter is None and category_filter is None:
        scope_states = (
            generate_pilot_outputs(ctx, plans, material_paths, force=force)
            if scope == "pilot"
            else generate_full_outputs(ctx, plans, material_paths, force=force)
        )
    else:
        selection = asset_filter or category_filter or "selection"
        scope_states = generate_selective_output(
            ctx,
            plans,
            material_paths,
            scope,
            selection,
            force=force,
        )

    state = {
        "schema": "SteamtekEnvironmentIntakeState-2",
        "pipeline_version": PIPELINE_VERSION,
        "config_sha256": sha256_file(ctx.config_path),
        "generated_utc": utc_now(),
        "scope": scope,
        "selection": {
            "asset": asset_filter,
            "category": category_filter,
        },
        "assets": [
            {
                "source": plan["source"],
                "source_sha256": plan["source_sha256"],
                "production_name": plan["production_name"],
                "scene": posix_relative(plan["scene_path"]),
                "status": plan["production_status"],
            }
            for plan in plans
        ],
        "write_states": {
            **inventory_states,
            **material_states,
            **wrapper_states,
            **scope_states,
        },
        "import_metadata_states": import_states,
        "import_metadata_backup": backup_state,
        "vendor_source_verification": {
            "passed": baseline_report["passed"],
            "file_count": baseline_report["file_count"],
            "added": baseline_report["added"],
            "removed": baseline_report["removed"],
            "changed": baseline_report["changed"],
            "report_write_state": baseline_state,
        },
    }
    state_path = state_report_path(ctx, asset_filter, category_filter)
    state["state_write"] = write_if_changed(
        state_path, json_bytes(state), force=force
    )
    return state

def dry_run(
    ctx: Context,
    scope: str,
    asset_filter: str | None,
    category_filter: str | None,
) -> dict[str, Any]:
    probe = load_probe(ctx)
    families = discover_texture_families(ctx)
    plans = select_plans(
        ctx, probe, scope, asset_filter=asset_filter, category_filter=category_filter
    )
    return {
        "schema": "SteamtekEnvironmentIntakeDryRun-1",
        "pipeline_version": PIPELINE_VERSION,
        "scope": scope,
        "asset_count": len(plans),
        "material_families": sorted(
            {
                family
                for plan in plans
                for family in plan["material_overrides"].values()
            }
        ),
        "planned_assets": [
            {
                "source": plan["source"],
                "production_name": plan["production_name"],
                "scene": posix_relative(plan["scene_path"]),
                "dimensions_m": plan["dimensions_m"],
                "collision": plan["collision"],
                "pivot": plan["pivot"],
                "socket_role": plan["socket_role"],
                "materials": plan["material_overrides"],
            }
            for plan in plans
        ],
        "unresolved_families": sorted(
            {
                family
                for plan in plans
                for family in plan["material_overrides"].values()
                if family not in families
            }
        ),
        "writes_performed": False,
    }


def command_inventory(ctx: Context, force: bool) -> int:
    _, _, _, states = write_inventory_outputs(ctx, force=force)
    verification, verification_state = verify_or_create_vendor_baseline(
        ctx, force=force, create_if_missing=True
    )
    print(
        json.dumps(
            {
                "inventory_states": states,
                "vendor_source": verification,
                "vendor_report_state": verification_state,
            },
            indent=2,
        )
    )
    return 0 if verification["passed"] else 1


def command_verify(ctx: Context, force: bool) -> int:
    report, state = verify_or_create_vendor_baseline(ctx, force=force)
    report["report_write"] = state
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description="Steamtek permanent environment asset intake pipeline"
    )
    result.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    subcommands = result.add_subparsers(dest="command", required=True)

    probe = subcommands.add_parser(
        "probe",
        help="Read-only Blender probe plus normal-editor Godot source probe",
    )
    probe.set_defaults(handler="probe")

    inventory = subcommands.add_parser(
        "inventory", help="Inventory source and establish/verify source hashes"
    )
    inventory.add_argument("--force", action="store_true")
    inventory.set_defaults(handler="inventory")

    dry = subcommands.add_parser("dry-run", help="Preview deterministic outputs")
    dry.add_argument("--scope", choices=("pilot", "full"), default="pilot")
    dry.add_argument("--asset")
    dry.add_argument("--category")
    dry.set_defaults(handler="dry_run")

    build_parser = subcommands.add_parser(
        "build", help="Generate shared materials and reusable scenes"
    )
    build_parser.add_argument("--scope", choices=("pilot", "full"), default="pilot")
    build_parser.add_argument("--asset")
    build_parser.add_argument("--category")
    build_parser.add_argument("--force", action="store_true")
    build_parser.add_argument("--approve-full-pack", action="store_true")
    build_parser.set_defaults(handler="build")

    verify = subcommands.add_parser(
        "verify", help="Verify immutable vendor sources against the baseline"
    )
    verify.add_argument("--force", action="store_true")
    verify.set_defaults(handler="verify")

    validate = subcommands.add_parser(
        "validate", help="Run technical pilot validation in normal Godot 4.7"
    )
    validate.set_defaults(handler="validate")

    validate_full = subcommands.add_parser(
        "validate-full",
        help="Run technical validation for every wrapper in the full manifest",
    )
    validate_full.set_defaults(handler="validate_full")

    review = subcommands.add_parser(
        "review", help="Open the pilot scene in the normal Godot editor"
    )
    review.set_defaults(handler="review")

    regenerate_scene = subcommands.add_parser(
        "regenerate-pilot-scene",
        help="Regenerate only the combined six-asset pilot review scene",
    )
    regenerate_scene.add_argument("--force", action="store_true")
    regenerate_scene.set_defaults(handler="regenerate_pilot_scene")

    restore = subcommands.add_parser(
        "restore-import-metadata",
        help="Restore backed-up Godot .import sidecars and verify their hashes",
    )
    restore.set_defaults(handler="restore_import_metadata")
    return result


def main() -> int:
    args = parser().parse_args()
    ctx = load_context(args.config)
    if args.handler == "probe":
        return run_probe(ctx)
    if args.handler == "inventory":
        return command_inventory(ctx, args.force)
    if args.handler == "verify":
        return command_verify(ctx, args.force)
    if args.handler == "validate":
        return run_pilot_validation(ctx)
    if args.handler == "validate_full":
        return run_full_validation(ctx)
    if args.handler == "review":
        print(json.dumps(open_pilot_review(ctx), indent=2))
        return 0
    if args.handler == "regenerate_pilot_scene":
        print(json.dumps(regenerate_pilot_scene(ctx, args.force), indent=2))
        return 0
    if args.handler == "restore_import_metadata":
        print(json.dumps(restore_import_metadata(ctx), indent=2))
        return 0
    if args.handler == "dry_run":
        print(
            json.dumps(
                dry_run(ctx, args.scope, args.asset, args.category),
                indent=2,
            )
        )
        return 0
    if args.handler == "build":
        print(
            json.dumps(
                build(
                    ctx,
                    args.scope,
                    args.asset,
                    args.category,
                    args.force,
                    args.approve_full_pack,
                ),
                indent=2,
            )
        )
        return 0
    raise AssertionError(f"Unknown handler {args.handler}")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, PermissionError, RuntimeError, ValueError) as error:
        print(f"STEAMTEK_INTAKE_ERROR={error}", file=sys.stderr)
        raise SystemExit(2)
