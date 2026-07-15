from pathlib import Path
import json

PROJECT = Path(r"C:\My Game\Steamtek-RPG")
MANIFEST = PROJECT / "assets/modular_v2/apartment_exterior_v3/Steamtek_ApartmentExterior_WestEast_Manifest.json"
data = json.loads(MANIFEST.read_text(encoding="utf-8"))

MODULE_DIR = PROJECT / "scenes/modular_v2/apartment_exterior_v3/modules"
BUILDING_DIR = PROJECT / "scenes/modular_v2/apartment_exterior_v3/buildings"
TEST_DIR = PROJECT / "scenes/tests/surface"
DOCS = PROJECT / "docs"
CONTRACT_DIR = PROJECT / "tools/modular_v2"
for path in (MODULE_DIR, BUILDING_DIR, TEST_DIR, DOCS, CONTRACT_DIR):
    path.mkdir(parents=True, exist_ok=True)


def v2(value):
    return f"Vector2({value[0]:.3f}, {value[1]:.3f})"


def module_scene(asset_id, display_name, manifest_key, orientation, feature):
    item = data["modules"][manifest_key]
    texture = item["texture"]
    offset = item["root_offset"]
    if orientation == "front":
        step = (256, -128)
        body_pos = (128, -64)
        body_rot = -0.463647609
        attach_name = "Attach_FoundationFront"
    else:
        step = (-256, -128)
        body_pos = (-128, -64)
        body_rot = 0.463647609
        attach_name = "Attach_FoundationSide"
    interact = ""
    load_steps = 3
    if feature == "door":
        interact = f'''\n[sub_resource type="RectangleShape2D" id="DoorInteractShape"]\nsize = Vector2(76, 44)\n'''
        load_steps = 4
    text = f'''[gd_scene load_steps={load_steps} format=3]\n\n[ext_resource type="Texture2D" path="{texture}" id="1_tex"]\n\n[sub_resource type="RectangleShape2D" id="WallShape"]\nsize = Vector2(284, 34)\n{interact}\n[node name="{asset_id}" type="Node2D" groups=["steamtek_modular", "steamtek_apartment_v3"]]\neditor_description = "{display_name}. Locked west-to-east 2:1 module. Root scale remains 1,1; use compatible markers with Steamtek Snap 2.3+."\nmetadata/steamtek_contract = "environment_west_east_v1"\nmetadata/steamtek_projection = "2_to_1_dimetric"\nmetadata/steamtek_bay_step = Vector2({step[0]}, {step[1]})\nmetadata/steamtek_storey_rise = Vector2(0, -219)\n\n[node name="Visual" type="Sprite2D" parent="."]\nposition = {v2(offset)}\ntexture = ExtResource("1_tex")\n\n[node name="Body" type="StaticBody2D" parent="."]\n\n[node name="BodyCollision" type="CollisionShape2D" parent="Body"]\nposition = Vector2({body_pos[0]}, {body_pos[1]})\nrotation = {body_rot}\nshape = SubResource("WallShape")\n\n[node name="Snap_Left" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Snap_Right" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2({step[0]}, {step[1]})\n\n[node name="Snap_Lower" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Snap_Upper" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(0, -219)\n\n[node name="{attach_name}" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Attach_Facade" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2({body_pos[0]}, {body_pos[1]-118})\n'''
    if feature == "door":
        text += f'''\n[node name="DoorInteraction" type="Area2D" parent="." groups=["steamtek_zone_door"]]\nposition = Vector2({body_pos[0]}, {body_pos[1]})\n\n[node name="DoorInteractionShape" type="CollisionShape2D" parent="DoorInteraction"]\nshape = SubResource("DoorInteractShape")\n\n[node name="DoorGroundContact" type="Marker2D" parent="."]\nposition = Vector2({body_pos[0]}, {body_pos[1]})\n'''
    return text


modules = [
    ("SMV3_W101_FrontPlain", "Apartment front plain bay", "FrontPlain", "front", "plain"),
    ("SMV3_W102_FrontWindow", "Apartment front cyan window bay", "FrontWindow", "front", "window"),
    ("SMV3_W103_FrontDoor", "Apartment front interactive door bay", "FrontDoor", "front", "door"),
    ("SMV3_W104_FrontUtility", "Apartment front utility and magenta fixture bay", "FrontUtility", "front", "utility"),
    ("SMV3_W201_SidePlain", "Apartment side plain bay", "SidePlain", "side", "plain"),
    ("SMV3_W202_SideWindow", "Apartment side cyan window bay", "SideWindow", "side", "window"),
]
for asset_id, label, key, orientation, feature in modules:
    (MODULE_DIR / f"{asset_id}.tscn").write_text(
        module_scene(asset_id, label, key, orientation, feature), encoding="utf-8"
    )


foundation = data["modules"]["FoundationMacro"]
(MODULE_DIR / "SMV3_F101_ApartmentFoundationMacro.tscn").write_text(f'''[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="{foundation['texture']}" id="1_tex"]\n\n[node name="SMV3_F101_ApartmentFoundationMacro" type="Node2D" groups=["steamtek_modular", "steamtek_apartment_v3"]]\neditor_description = "One-piece apartment footprint and wet sidewalk apron. This replaces checkerboard foundation repetition for complete building exteriors."\nmetadata/steamtek_contract = "environment_west_east_v1"\nmetadata/steamtek_lattice_axis_a = Vector2(1024, -512)\nmetadata/steamtek_lattice_axis_b = Vector2(-768, -384)\n\n[node name="Visual" type="Sprite2D" parent="."]\nposition = {v2(foundation['root_offset'])}\ntexture = ExtResource("1_tex")\n\n[node name="Attach_WallFront" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Attach_WallSide" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(1024, -512)\n\n[node name="Snap_SW" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Snap_SE" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(1024, -512)\n\n[node name="Snap_NE" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(256, -896)\n\n[node name="Snap_NW" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(-768, -384)\n''', encoding="utf-8")


roof = data["modules"]["RoofMacro"]
(MODULE_DIR / "SMV3_R101_ApartmentRoofMacro.tscn").write_text(f'''[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="{roof['texture']}" id="1_tex"]\n\n[node name="SMV3_R101_ApartmentRoofMacro" type="Node2D" groups=["steamtek_modular", "steamtek_apartment_v3"]]\neditor_description = "Continuous one-piece wet roof with perimeter parapet, drainage runs, and rooftop vent. No tiled checkerboard seams."\nmetadata/steamtek_contract = "environment_west_east_v1"\nmetadata/steamtek_roof_rise = Vector2(0, -478)\n\n[node name="Visual" type="Sprite2D" parent="."]\nposition = {v2(roof['root_offset'])}\ntexture = ExtResource("1_tex")\n\n[node name="Snap_Lower" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Snap_SW" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Snap_SE" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(1024, -512)\n\n[node name="Snap_NE" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(256, -896)\n\n[node name="Snap_NW" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(-768, -384)\n''', encoding="utf-8")


# Modular construction proof: every visible facade bay is a separate snap-compatible scene.
resource_lines = []
resource_map = {}
for idx, (asset_id, *_rest) in enumerate(modules, start=1):
    rid = f"{idx}_{asset_id}"
    resource_map[asset_id] = rid
    resource_lines.append(f'[ext_resource type="PackedScene" path="res://scenes/modular_v2/apartment_exterior_v3/modules/{asset_id}.tscn" id="{rid}"]')
resource_lines.append('[ext_resource type="PackedScene" path="res://scenes/modular_v2/apartment_exterior_v3/modules/SMV3_F101_ApartmentFoundationMacro.tscn" id="7_foundation"]')
resource_lines.append('[ext_resource type="PackedScene" path="res://scenes/modular_v2/apartment_exterior_v3/modules/SMV3_R101_ApartmentRoofMacro.tscn" id="8_roof"]')
resource_lines.append('[ext_resource type="PackedScene" path="res://assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn" id="9_player"]')

assembly_nodes = []
front_lower = [
    ("DoorLower", "SMV3_W103_FrontDoor", (0, 0)),
    ("WindowLowerA", "SMV3_W102_FrontWindow", (256, -128)),
    ("WindowLowerB", "SMV3_W102_FrontWindow", (512, -256)),
    ("UtilityLower", "SMV3_W104_FrontUtility", (768, -384)),
]
front_upper = [
    ("PlainUpperA", "SMV3_W101_FrontPlain", (0, -219)),
    ("WindowUpperA", "SMV3_W102_FrontWindow", (256, -347)),
    ("WindowUpperB", "SMV3_W102_FrontWindow", (512, -475)),
    ("PlainUpperB", "SMV3_W101_FrontPlain", (768, -603)),
]
side_lower = [
    ("SideWindowLower", "SMV3_W202_SideWindow", (1024, -512)),
    ("SidePlainLower", "SMV3_W201_SidePlain", (768, -640)),
    ("SideWindowRear", "SMV3_W202_SideWindow", (512, -768)),
]
side_upper = [
    ("SidePlainUpper", "SMV3_W201_SidePlain", (1024, -731)),
    ("SideWindowUpper", "SMV3_W202_SideWindow", (768, -859)),
    ("SidePlainRear", "SMV3_W201_SidePlain", (512, -987)),
]
for node_name, asset_id, pos in front_lower + front_upper + side_lower + side_upper:
    assembly_nodes.append(f'''\n[node name="{node_name}" parent="Architecture" instance=ExtResource("{resource_map[asset_id]}")]\nposition = Vector2({pos[0]}, {pos[1]})\n''')

(BUILDING_DIR / "SMV3_B101_ApartmentExterior_ModularAssembly.tscn").write_text(f'''[gd_scene load_steps={len(resource_lines)+1} format=3]\n\n{chr(10).join(resource_lines)}\n\n[node name="SMV3_B101_ApartmentExterior_ModularAssembly" type="Node2D" groups=["steamtek_modular_assembly", "steamtek_apartment_v3"]]\ny_sort_enabled = true\neditor_description = "Construction proof assembled from V3 snap-compatible modules. Open this to inspect, replace, duplicate, and resnap individual bays."\n\n[node name="Foundation" parent="." instance=ExtResource("7_foundation")]\nz_index = -20\n\n[node name="Architecture" type="Node2D" parent="."]\n{''.join(assembly_nodes)}\n[node name="Roof" parent="." instance=ExtResource("8_roof")]\nposition = Vector2(0, -478)\nz_index = 5\n\n[node name="ScaleReference_C001" parent="." instance=ExtResource("9_player")]\nposition = Vector2(132, -56)\nz_index = 20\n''', encoding="utf-8")


# Placeable golden assembly: single visual, whole-building sorting, collision, and door trigger.
golden = data["golden"]
(BUILDING_DIR / "SMV3_B101_ApartmentExterior_Placeable.tscn").write_text(f'''[gd_scene load_steps=4 format=3]\n\n[ext_resource type="Texture2D" path="{golden['texture']}" id="1_tex"]\n\n[sub_resource type="ConvexPolygonShape2D" id="BuildingShape"]\npoints = PackedVector2Array(0, 0, 1024, -512, 256, -896, -768, -384)\n\n[sub_resource type="RectangleShape2D" id="DoorShape"]\nsize = Vector2(82, 48)\n\n[node name="SMV3_B101_ApartmentExterior_Placeable" type="Node2D" groups=["steamtek_modular", "steamtek_placeable_building", "steamtek_apartment_v3"]]\neditor_description = "Golden placeable apartment exterior. Root is ground-contact origin; building sorts as one object. Door area is ready for the later zone-transition script."\nmetadata/steamtek_contract = "environment_west_east_v1"\nmetadata/source_blend = "res://blender/modular_v2/apartment_exterior_v3/Steamtek_ApartmentExterior_WestEast_Master.blend"\nmetadata/mockup_reference = "res://docs/references/ApartmentExterior_AssemblyMockup.png"\nmetadata/aesthetic_reference = "res://docs/references/Steamtek_Surface_ColorPalette_Aesthetic_Reference.png"\n\n[node name="Visual" type="Sprite2D" parent="."]\nposition = {v2(golden['root_offset'])}\ntexture = ExtResource("1_tex")\n\n[node name="BuildingBody" type="StaticBody2D" parent="."]\n\n[node name="BuildingCollision" type="CollisionShape2D" parent="BuildingBody"]\nshape = SubResource("BuildingShape")\n\n[node name="DoorInteraction" type="Area2D" parent="." groups=["steamtek_zone_door"]]\nposition = Vector2(134, -67)\nmetadata/target_scene = "res://scenes/levels/apartment/Apartment_Interior.tscn"\n\n[node name="DoorInteractionShape" type="CollisionShape2D" parent="DoorInteraction"]\nshape = SubResource("DoorShape")\n\n[node name="DoorGroundContact" type="Marker2D" parent="."]\nposition = Vector2(134, -67)\n\n[node name="Snap_SW" type="Marker2D" parent="." groups=["steamtek_snap"]]\n\n[node name="Snap_SE" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(1024, -512)\n\n[node name="Snap_NE" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(256, -896)\n\n[node name="Snap_NW" type="Marker2D" parent="." groups=["steamtek_snap"]]\nposition = Vector2(-768, -384)\n''', encoding="utf-8")


# Camera comparison gate and complete construction gate, both isolated from main.gd/main.tscn.
(TEST_DIR / "Steamtek_ApartmentExterior_WestEast_CameraGate.tscn").write_text('''[gd_scene load_steps=4 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/modular_v2/apartment_exterior_v3/calibration/ApartmentExterior_CurrentAzimuth.png" id="1_current"]\n[ext_resource type="Texture2D" path="res://assets/modular_v2/apartment_exterior_v3/calibration/ApartmentExterior_WestToEastCandidate.png" id="2_candidate"]\n[ext_resource type="PackedScene" path="res://assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn" id="3_player"]\n\n[node name="Steamtek_ApartmentExterior_WestEast_CameraGate" type="Node2D"]\neditor_description = "Side-by-side camera calibration. Both renders use the same building and 30-degree elevation; only the horizontal azimuth changes by 90 degrees."\n\n[node name="CurrentAzimuth" type="Node2D" parent="."]\nposition = Vector2(-700, 0)\n\n[node name="Render" type="Sprite2D" parent="CurrentAzimuth"]\nscale = Vector2(0.38, 0.38)\ntexture = ExtResource("1_current")\n\n[node name="C001" parent="CurrentAzimuth" instance=ExtResource("3_player")]\nposition = Vector2(35, 300)\nz_index = 20\n\n[node name="WestToEastLocked" type="Node2D" parent="."]\nposition = Vector2(700, 0)\n\n[node name="Render" type="Sprite2D" parent="WestToEastLocked"]\nscale = Vector2(0.38, 0.38)\ntexture = ExtResource("2_candidate")\n\n[node name="C001" parent="WestToEastLocked" instance=ExtResource("3_player")]\nposition = Vector2(-260, 300)\nz_index = 20\n''', encoding="utf-8")

(TEST_DIR / "Steamtek_ApartmentExterior_V3_ConstructionGate.tscn").write_text('''[gd_scene load_steps=4 format=3]\n\n[ext_resource type="PackedScene" path="res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_ModularAssembly.tscn" id="1_modular"]\n[ext_resource type="PackedScene" path="res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_Placeable.tscn" id="2_placeable"]\n[ext_resource type="PackedScene" path="res://assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn" id="3_player"]\n\n[node name="Steamtek_ApartmentExterior_V3_ConstructionGate" type="Node2D"]\ny_sort_enabled = true\neditor_description = "Isolated review scene. Modular proof is left; final placeable golden assembly is right. Exact production C001 references remain unscaled."\n\n[node name="ModularProof" parent="." instance=ExtResource("1_modular")]\nposition = Vector2(-1450, 250)\n\n[node name="PlaceableGolden" parent="." instance=ExtResource("2_placeable")]\nposition = Vector2(900, 250)\n\n[node name="ScaleGate_C001" parent="." instance=ExtResource("3_player")]\nposition = Vector2(1034, 183)\nz_index = 50\n\n[node name="Camera2D" type="Camera2D" parent="."]\nposition = Vector2(0, -250)\nzoom = Vector2(0.55, 0.55)\n''', encoding="utf-8")


contract = data["contract"]
(CONTRACT_DIR / "Steamtek_Environment_Camera_Contract.json").write_text(json.dumps({
    "version": "environment_west_east_v1",
    "status": "locked_for_modular_v3",
    **contract,
    "render": {"engine": "BLENDER_EEVEE_NEXT", "format": "PNG", "color": "RGBA", "transparent": True, "view_transform": "AgX", "look": "AgX - Medium High Contrast"},
    "rules": [
        "Do not rotate exported sprites in Godot to fake another azimuth.",
        "Do not crop modules independently after pivot generation.",
        "Do not scale module roots; root scale stays 1,1.",
        "All light-colored ground reflections must be supported by a visible light fixture or scene light.",
        "C001 is the immutable scale reference and remains at its production visual transform."
    ]
}, indent=2), encoding="utf-8")

(DOCS / "STEAMTEK_ENVIRONMENT_CAMERA_CONTRACT.md").write_text('''# Steamtek Environment Camera Contract — West/East v1\n\nStatus: **locked for Modular V3 production**\n\n## Why this was necessary\n\nThe existing Blender environment files did not share one projection:\n\n- `SMV2_F001_FoundationBlock.blend`: 30° elevation — true 2:1\n- `SMV2_G006_RainWetSidewalkSlab.blend`: approximately 30° — true 2:1\n- `SMV2_R001_RoofSurface.blend`: 35.264° — classic isometric, not 2:1\n- `SMV2_W001_PlainWall.blend`: approximately 39.19° — neither contract\n\nThat camera drift explains why walls, roofs, and foundations could share nominal snap markers but still look wrong together.\n\n## Locked V3 contract\n\n- Projection: orthographic true 2:1 dimetric\n- Elevation: 30° above the ground plane\n- Horizontal azimuth: southeast toward northwest (the approved west/east composition)\n- Camera forward: `(-0.612372, 0.612372, -0.500000)`\n- Front bay step: `(256, -128)` pixels\n- Side bay step: `(-256, -128)` pixels\n- Storey rise: `(0, -219)` pixels\n- Root scale in Godot: `(1, 1)`\n- Render: PNG RGBA, transparent, AgX Medium High Contrast\n\nThe azimuth is a 90° horizontal rotation from the comparison view. Elevation is unchanged, so the 2:1 diamond is preserved; only which two building faces dominate the composition changes.\n\n## Scale gate\n\nEvery environment module is checked beside the exact production C001 scene:\n\n`res://assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn`\n\nC001 keeps visual scale `0.73`, visual offset approximately `(0, -110)`, and collision footprint `28 × 18`. Environment assets are fitted to that reference; C001 is never rescaled to fit an environment asset.\n\n## Non-negotiable rules\n\n1. Never rotate a rendered sprite in Godot to fake another camera azimuth.\n2. Never change a module root scale from `(1,1)`.\n3. Never independently crop a module after its pivot is generated.\n4. Geometry, alpha silhouette, root, snap endpoints, and collision remain authoritative.\n5. Cyan/magenta/amber reflections require a visible corresponding fixture or actual scene light.\n6. Whole-image aesthetic reference: `docs/references/Steamtek_Surface_ColorPalette_Aesthetic_Reference.png`.\n''', encoding="utf-8")

(DOCS / "STEAMTEK_APARTMENT_EXTERIOR_V3.md").write_text('''# Steamtek Apartment Exterior V3\n\nThis is the first apartment kit built against the locked west/east environment camera and current production C001 scale. It is isolated from `main.gd` and `main.tscn`.\n\n## Open these tomorrow\n\n1. Camera comparison: `res://scenes/tests/surface/Steamtek_ApartmentExterior_WestEast_CameraGate.tscn`\n2. Construction comparison: `res://scenes/tests/surface/Steamtek_ApartmentExterior_V3_ConstructionGate.tscn`\n3. Modular construction proof: `res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_ModularAssembly.tscn`\n4. Placeable golden exterior: `res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_Placeable.tscn`\n5. Blender master: `blender/modular_v2/apartment_exterior_v3/Steamtek_ApartmentExterior_WestEast_Master.blend`\n\n## Module family\n\n- `SMV3_F101_ApartmentFoundationMacro` — one-piece footprint and wet apron\n- `SMV3_W101_FrontPlain`\n- `SMV3_W102_FrontWindow`\n- `SMV3_W103_FrontDoor` — includes door interaction area\n- `SMV3_W104_FrontUtility`\n- `SMV3_W201_SidePlain`\n- `SMV3_W202_SideWindow`\n- `SMV3_R101_ApartmentRoofMacro` — one-piece continuous roof, no checkerboard\n\n## How to build\n\nCreate the foundation first. Add front bays along `(256,-128)`, side bays along `(-256,-128)`, and the second storey at `(0,-219)`. Use the Steamtek toolbar `Snap` button or automatic release snapping. Occupied sockets are skipped in Snap 2.3.0, so a new bay will not stack over an already-connected bay.\n\nThe complete placeable scene sorts as one building and includes a footprint collision shape plus a door interaction area. The door transition script is intentionally not connected while Claude is reorganizing gameplay scripts.\n\n## Rebuild\n\nRun the source script in Blender 4.5 LTS:\n\n`blender/modular_v2/apartment_exterior_v3/Steamtek_Build_ApartmentExterior_WestEast.py`\n\nIt rebuilds the master blend, both camera calibration renders, eight production module renders, the golden render, and the JSON manifest.\n''', encoding="utf-8")

print("Generated Steamtek Apartment Exterior V3 Godot scenes and contracts")
