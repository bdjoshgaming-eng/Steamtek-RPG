from pathlib import Path
from PIL import Image
import hashlib
import json
import math

PROJECT = Path(r"C:\My Game\Steamtek-RPG")
ROOT = PROJECT / "assets/modular_v2/apartment_exterior_v3"
MANIFEST_PATH = ROOT / "Steamtek_ApartmentExterior_WestEast_Manifest.json"
REPORT_JSON = ROOT / "Steamtek_ApartmentExterior_V3_QA.json"
REPORT_MD = PROJECT / "docs/STEAMTEK_APARTMENT_EXTERIOR_V3_QA.md"

manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
checks = []


def check(name, passed, detail):
    checks.append({"name": name, "passed": bool(passed), "detail": detail})


contract = manifest["contract"]
check("projection", contract["projection"] == "true_2_to_1_dimetric", contract["projection"])
check("elevation", abs(contract["elevation_degrees"] - 30.0) < 1e-6, str(contract["elevation_degrees"]))
check("locked_azimuth", contract["locked_azimuth"] == "south_east_to_north_west", contract["locked_azimuth"])
check("front_step", contract["projected_bay_step_front"] == [256, -128], str(contract["projected_bay_step_front"]))
check("side_step", contract["projected_bay_step_side"] == [-256, -128], str(contract["projected_bay_step_side"]))
check("front_slope_2_to_1", abs(contract["projected_bay_step_front"][1] / contract["projected_bay_step_front"][0]) == 0.5, "abs(dy/dx)=0.5")
check("side_slope_2_to_1", abs(contract["projected_bay_step_side"][1] / contract["projected_bay_step_side"][0]) == 0.5, "abs(dy/dx)=0.5")
check("c001_scale", contract["character_visual_scale"] == [0.73, 0.73], str(contract["character_visual_scale"]))
check("c001_offset", contract["character_visual_offset"] == [0, -110], str(contract["character_visual_offset"]))
check("collision_footprint", contract["collision_footprint"] == [28, 18], str(contract["collision_footprint"]))

pngs = [
    ROOT / "calibration/ApartmentExterior_CurrentAzimuth.png",
    ROOT / "calibration/ApartmentExterior_WestToEastCandidate.png",
    ROOT / "production/SMV3_B101_ApartmentExterior_Golden.png",
]
pngs += sorted((ROOT / "production").glob("SMV3_Front*.png"))
pngs += sorted((ROOT / "production").glob("SMV3_Side*.png"))
pngs += [ROOT / "production/SMV3_RoofMacro.png", ROOT / "production/SMV3_FoundationMacro.png"]

hashes = {}
for path in pngs:
    exists = path.exists()
    check(f"exists:{path.name}", exists, str(path.relative_to(PROJECT)))
    if not exists:
        continue
    with Image.open(path) as image:
        check(f"rgba:{path.name}", image.mode == "RGBA", image.mode)
        alpha = image.getchannel("A")
        extrema = alpha.getextrema()
        check(f"alpha_content:{path.name}", extrema[1] > 0, str(extrema))
        check(f"transparent_margin:{path.name}", extrema[0] == 0, str(extrema))
        check(f"nonempty_bbox:{path.name}", alpha.getbbox() is not None, str(alpha.getbbox()))
    hashes[str(path.relative_to(PROJECT)).replace("\\", "/")] = hashlib.sha256(path.read_bytes()).hexdigest()

required_scenes = [
    PROJECT / "scenes/tests/surface/Steamtek_ApartmentExterior_WestEast_CameraGate.tscn",
    PROJECT / "scenes/tests/surface/Steamtek_ApartmentExterior_V3_ConstructionGate.tscn",
    PROJECT / "scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_ModularAssembly.tscn",
    PROJECT / "scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_Placeable.tscn",
]
required_scenes += sorted((PROJECT / "scenes/modular_v2/apartment_exterior_v3/modules").glob("*.tscn"))
for path in required_scenes:
    check(f"scene_exists:{path.name}", path.exists(), str(path.relative_to(PROJECT)))
    if path.exists():
        text = path.read_text(encoding="utf-8")
        check(f"isolated_from_main:{path.name}", "main.gd" not in text and "main.tscn" not in text, "no main dependency")
        node_blocks = text.split("[node name=")
        root_block = node_blocks[1].split("[node name=")[0] if len(node_blocks) > 1 else ""
        check(f"root_scale_locked:{path.name}", "scale = Vector2(" not in root_block, "root has no scale override")

placeable = (PROJECT / "scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_Placeable.tscn").read_text(encoding="utf-8")
check("placeable_collision", "BuildingCollision" in placeable and "ConvexPolygonShape2D" in placeable, "footprint collision present")
check("placeable_door", "DoorInteraction" in placeable and "steamtek_zone_door" in placeable, "door interaction present")
check("placeable_whole_sort", "SMV3_B101_ApartmentExterior_Placeable" in placeable and "Visual" in placeable, "single root visual")

plugin = (PROJECT / "addons/steamtek_modular_snap/steamtek_modular_snap.gd").read_text(encoding="utf-8")
plugin_cfg = (PROJECT / "addons/steamtek_modular_snap/plugin.cfg").read_text(encoding="utf-8")
check("snap_v3_foundation", 'node.name.begins_with("SMV3_F")' in plugin, "V3 prefix supported")
check("snap_occupied_socket", "_marker_is_occupied" in plugin, "occupied sockets skipped")
check("snap_metadata_axes", "_foundation_axes_for" in plugin and "steamtek_lattice_axis_a" in plugin, "per-family axes supported")
check("snap_version", 'version="2.3.0"' in plugin_cfg, "2.3.0")

blend = PROJECT / "blender/modular_v2/apartment_exterior_v3/Steamtek_ApartmentExterior_WestEast_Master.blend"
build_script = PROJECT / "blender/modular_v2/apartment_exterior_v3/Steamtek_Build_ApartmentExterior_WestEast.py"
check("master_blend", blend.exists() and blend.stat().st_size > 100000, f"{blend.stat().st_size if blend.exists() else 0} bytes")
check("rebuild_script", build_script.exists(), str(build_script.relative_to(PROJECT)))

passed = all(item["passed"] for item in checks)
report = {
    "status": "PASS" if passed else "FAIL",
    "checks_total": len(checks),
    "checks_passed": sum(1 for item in checks if item["passed"]),
    "checks": checks,
    "sha256": hashes,
    "note": "Godot scene launch and clean plugin-load tests are recorded in the handoff document. Full editor scan remains affected by unrelated in-progress SurveyBook.gd/main.gd work and was not modified."
}
REPORT_JSON.write_text(json.dumps(report, indent=2), encoding="utf-8")

lines = [
    "# Steamtek Apartment Exterior V3 QA",
    "",
    f"Status: **{report['status']}**",
    "",
    f"Passed {report['checks_passed']} of {report['checks_total']} structural, projection, alpha, scene, snap, and packaging checks.",
    "",
    "## Test notes",
    "",
    "- All four isolated V3 Godot scenes launched headlessly and exited cleanly.",
    "- Snap 2.3.0 loaded cleanly in a separate empty Godot editor project.",
    "- Blender 4.5 LTS rebuilt the master, calibration renders, module renders, golden render, and manifest without errors.",
    "- The full Steamtek editor scan currently reports Claude's unrelated in-progress `SurveyBook.gd/main.gd` compile error. Those files were deliberately not touched.",
    "",
    "## Checks",
    "",
]
for item in checks:
    lines.append(f"- {'PASS' if item['passed'] else 'FAIL'} — {item['name']}: {item['detail']}")
REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(json.dumps({"status": report["status"], "passed": report["checks_passed"], "total": report["checks_total"]}))
if not passed:
    raise SystemExit(1)
