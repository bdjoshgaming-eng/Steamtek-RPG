"""Generate Godot wrappers and Builder catalog entries for apartment library D."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "assets/environment/live3d/models/apartment_interior/library_d/manifest.json"
KIT_DIR = ROOT / "scenes/environment/live3d/kits/apartment_interior"
PROP_DIR = ROOT / "scenes/environment/live3d/props/apartment_interior"
SMALL_DIR = PROP_DIR / "small"
BUILDER = ROOT / "addons/steamtek_live3d_builder/steamtek_live3d_builder.gd"
BEGIN = "\t# APARTMENT_LIBRARY_D_BEGIN"
END = "\t# APARTMENT_LIBRARY_D_END"


def fmt(value: float) -> str:
    if abs(value) < 0.000001:
        return "0"
    return f"{value:.4f}".rstrip("0").rstrip(".")


def vec(values) -> str:
    return f"Vector3({', '.join(fmt(float(v)) for v in values)})"


def output_path(asset: dict) -> Path:
    if asset["category"] == "architecture":
        return KIT_DIR / f"{asset['id']}.tscn"
    if asset["category"] == "small_prop":
        return SMALL_DIR / f"{asset['id']}.tscn"
    return PROP_DIR / f"{asset['id']}.tscn"


def scene_path(asset: dict) -> str:
    return "res://" + output_path(asset).relative_to(ROOT).as_posix()


def label(asset: dict) -> str:
    words = asset["id"].replace("APT_", "").replace("_", " ")
    prefix = "Interior" if asset["category"] == "architecture" else ("Prop" if asset["category"] == "small_prop" else "Apartment")
    return f"{prefix} - {words}"


def make_wrapper(asset: dict) -> str:
    # Manifest dimensions are authored in Blender XYZ (X width, Y depth, Z height).
    # Godot's live3d contract is X width, Y height, Z depth.
    blender_width, blender_depth, blender_height = [float(v) for v in asset["dimensions"]]
    width, height, depth = blender_width, blender_height, blender_depth
    model = asset["model"]
    sockets = list(asset.get("sockets") or [])
    if asset["category"] == "architecture":
        sockets.extend([
            {"name": "WallLeft", "position": [-width / 2, 0, 0], "role": "interior_wall_chain"},
            {"name": "WallRight", "position": [width / 2, 0, 0], "role": "interior_wall_chain"},
            {"name": "FloorAttachment", "position": [0, 0, 0], "role": "interior_wall_base"},
        ])
    elif asset["category"] != "small_prop":
        existing = {s["name"] for s in sockets}
        if "LeftFurniture" not in existing:
            sockets.append({"name": "LeftFurniture", "position": [-width / 2, 0, 0], "role": "furniture_chain"})
        if "RightFurniture" not in existing:
            sockets.append({"name": "RightFurniture", "position": [width / 2, 0, 0], "role": "furniture_chain"})

    lines = [
        "[gd_scene load_steps=3 format=3]",
        "",
        f'[ext_resource type="PackedScene" path="{model}" id="1_model"]',
        "",
        '[sub_resource type="BoxShape3D" id="PrimaryShape"]',
        f"size = {vec([width, height, depth])}",
        "",
        f'[node name="{asset["id"]}" type="Node3D" groups=["steamtek_live3d_modular"]]',
        'metadata/module_system = "live3d_meter_v1"',
        f'metadata/module_family = "apartment_library_d_{asset["category"]}"',
        f'metadata/module_variant = "{asset["id"]}"',
        f"metadata/module_dimensions_m = {vec([width, height, depth])}",
        'metadata/contact_pivot = "floor_center"',
        'metadata/front_axis = "+Z_toward_room_and_c001"',
        'metadata/art_style = "hand_painted_shadowrun_returns_rendering_language_not_palette"',
        'metadata/world_design = "60_cyberpunk_20_neoindustrial_20_functional_steampunk"',
        'metadata/visual_contract = "finished_true_3d_no_cards_no_billboards"',
        'metadata/source_library = "APT_ApartmentAssetLibrary_D.blend"',
        "",
        '[node name="Visual" parent="." instance=ExtResource("1_model")]',
        "",
        '[node name="StaticBody" type="StaticBody3D" parent="."]',
        "collision_layer = 1",
        "collision_mask = 0",
        "",
        '[node name="PrimaryCollision" type="CollisionShape3D" parent="StaticBody"]',
        f"position = {vec([0, height / 2, 0])}",
        'shape = SubResource("PrimaryShape")',
    ]

    if asset["id"] == "APT_Lamp_Floor_Copper":
        lines.extend([
            "",
            '[node name="MagentaSourceLight" type="OmniLight3D" parent="."]',
            "position = Vector3(0, 1.55, 0.05)",
            "light_color = Color(1, 0.06, 0.34, 1)",
            "light_energy = 0.55",
            "omni_range = 2.6",
            "shadow_enabled = true",
        ])
    elif asset["category"] == "architecture" and "Window" in asset["id"]:
        lines.extend([
            "",
            '[node name="WindowSourceLight" type="OmniLight3D" parent="."]',
            "position = Vector3(0, 1.45, 0.38)",
            "light_color = Color(0.08, 0.72, 0.82, 1)",
            "light_energy = 0.22",
            "omni_range = 2.2",
            "shadow_enabled = false",
        ])

    lines.extend(["", '[node name="Sockets" type="Node3D" parent="."]'])
    for socket in sockets:
        lines.extend([
            "",
            f'[node name="{socket["name"]}" type="Marker3D" parent="Sockets" groups=["steamtek_live3d_snap"]]',
            f"position = {vec(socket['position'])}",
            f'metadata/socket_role = "{socket["role"]}"',
        ])
    return "\n".join(lines) + "\n"


def patch_builder(assets: list[dict]) -> None:
    text = BUILDER.read_text(encoding="utf-8")
    if "var library := [" not in text:
        text = text.replace("func _module_library() -> Array:\n\treturn [", "func _module_library() -> Array:\n\tvar library := [", 1)
        text = text.replace("\n\t]\n\n\nfunc _create_dock", "\n\t]\n\tlibrary.append_array(_production_apartment_library())\n\treturn library\n\n\nfunc _production_apartment_library() -> Array:\n\treturn [\n" + BEGIN + "\n" + END + "\n\t]\n\n\nfunc _create_dock", 1)
    entries = []
    for asset in assets:
        parent = "Architecture" if asset["category"] == "architecture" else ("Props" if asset["category"] == "small_prop" else "Furniture")
        entries.extend([
            "\t\t{",
            f'\t\t\t"label": "{label(asset)}",',
            f'\t\t\t"path": "{scene_path(asset)}",',
            f'\t\t\t"parent": "{parent}",',
            "\t\t},",
        ])
    replacement = BEGIN + "\n" + "\n".join(entries) + "\n" + END
    text, count = re.subn(re.escape(BEGIN) + r".*?" + re.escape(END), replacement, text, flags=re.S)
    if count != 1:
        raise RuntimeError("Builder production-library markers were not found exactly once")
    BUILDER.write_text(text, encoding="utf-8", newline="\n")


def main() -> None:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = data["assets"]
    for directory in (KIT_DIR, PROP_DIR, SMALL_DIR):
        directory.mkdir(parents=True, exist_ok=True)
    for asset in assets:
        output_path(asset).write_text(make_wrapper(asset), encoding="utf-8", newline="\n")
    patch_builder(assets)
    print(f"WRAPPERS={len(assets)}")
    print(f"BUILDER_ENTRIES={len(assets)}")


if __name__ == "__main__":
    main()
