from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "addons/steamtek_modular_snap/steamtek_modular_snap.gd",
    "scenes/modular_v4/scripts/steamtek_v4_module_visual.gd",
    "scenes/modular_v4/scripts/steamtek_zone_door.gd",
    "scenes/modular_v4/modules/walls/SMV4_W101_FrontPlain.tscn",
    "scenes/modular_v4/modules/walls/SMV4_W102_FrontWindow.tscn",
    "scenes/modular_v4/modules/walls/SMV4_W103_FrontDoor.tscn",
    "scenes/modular_v4/modules/walls/SMV4_W104_FrontUtility.tscn",
    "scenes/modular_v4/modules/walls/SMV4_W201_SidePlain.tscn",
    "scenes/modular_v4/modules/walls/SMV4_W202_SideWindow.tscn",
    "scenes/modular_v4/modules/roofs/SMV4_R101_RoofCell.tscn",
    "scenes/modular_v4/modules/corners/SMV4_C101_OutsideCorner.tscn",
    "scenes/modular_v4/modules/corners/SMV4_C102_FrontEndCap.tscn",
    "scenes/modular_v4/buildings/SMV4_B101_ApartmentExterior_ModularAssembly.tscn",
    "scenes/modular_v4/buildings/SMV4_B101_ApartmentExterior_Placeable.tscn",
    "scenes/tests/surface/Steamtek_ApartmentRightAlley_V4_Demo.tscn",
    "scenes/levels/apartment/Apartment_Interior.tscn",
    "scenes/characters/C001_PlayerBody.tscn",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


for relative in REQUIRED:
    if not (ROOT / relative).is_file():
        fail(f"missing {relative}")

plugin = (ROOT / REQUIRED[0]).read_text(encoding="utf-8")
for literal in ("Vector2(313.534, -90.509)", "Vector2(-181.020, -156.768)"):
    if literal not in plugin:
        fail(f"snap plugin missing {literal}")
if "64x32" in plugin or "scenes/modular_v2/walls" in plugin:
    fail("snap plugin still contains a V2 grid/library dependency")

module_files = list((ROOT / "scenes/modular_v4/modules").rglob("*.tscn"))
for path in module_files:
    text = path.read_text(encoding="utf-8")
    if "environment_off_axis_60_v4" not in text:
        fail(f"{path.name} missing V4 contract metadata")
    if "scale = Vector2" in text:
        fail(f"{path.name} changes a module scale")
    if "steamtek_modular_v4" not in text:
        fail(f"{path.name} missing V4 modular group")

door = (ROOT / "scenes/modular_v4/modules/walls/SMV4_W103_FrontDoor.tscn").read_text(encoding="utf-8")
for token in ("BodyCollision", "DoorInteraction", "InteractionShape", "EmissionVisual", "FixtureLight", "Apartment_Interior.tscn"):
    if token not in door:
        fail(f"door missing {token}")

player = (ROOT / "scenes/characters/C001_PlayerBody.tscn").read_text(encoding="utf-8")
if "collision_layer = 2" not in player or "collision_mask = 1" not in player:
    fail("player collision layer/mask contract is wrong")

visual = (ROOT / "scenes/modular_v4/scripts/steamtek_v4_module_visual.gd").read_text(encoding="utf-8").lower()
for forbidden in ("magenta", "cyan", "bloom"):
    if forbidden in visual:
        fail(f"neutral base visual contains forbidden lighting term {forbidden}")

working = (ROOT / "scenes/levels/apartment/Apartment_Exterior_Working.tscn").read_text(encoding="utf-8")
if "SMV4_B101_ApartmentExterior_Placeable.tscn" not in working:
    fail("main compatibility wrapper does not point to V4")

demo = (ROOT / "scenes/tests/surface/Steamtek_ApartmentRightAlley_V4_Demo.tscn").read_text(encoding="utf-8")
for token in ("RightServiceAlley", "Player", "ApartmentExterior", "CyanDoorSpill", "MagentaAlleySpill", "AmberStreetSpill"):
    if token not in demo:
        fail(f"demo missing {token}")

print(f"PASS: {len(REQUIRED)} required files")
print(f"PASS: {len(module_files)} reusable V4 modules")
print("PASS: locked 60-degree A/B lattice")
print("PASS: neutral base art and Godot-owned colored lighting")
print("PASS: collision, player layer, door zoning, and demo wiring")
