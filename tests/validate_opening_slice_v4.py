from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "scenes/levels/surface/Steamtek_LanternWard_ApartmentAlley.tscn",
    "scenes/levels/apartment/Apartment_Interior.tscn",
    "scenes/modular_v4/effects/SMV4_FX401_RainOverlay.tscn",
    "scenes/modular_v4/scripts/steamtek_v4_rain_overlay.gd",
    "scenes/modular_v4/scripts/steamtek_v4_steam_fx.gd",
    "scenes/modular_v4/scripts/steamtek_v4_alley_prop_visual.gd",
    "scenes/modular_v4/modules/props/SMV4_P401_PressureBin.tscn",
    "scenes/modular_v4/modules/props/SMV4_P402_Dumpster.tscn",
    "scenes/modular_v4/modules/props/SMV4_P403_SteamVent.tscn",
    "scenes/modular_v4/modules/props/SMV4_P404_UtilityCabinet.tscn",
    "scenes/modular_v4/modules/props/SMV4_P405_PipeRack.tscn",
    "scenes/modular_v4/modules/props/SMV4_P406_StreetFixture.tscn",
    "scenes/modular_v4/modules/props/SMV4_P407_Barrier.tscn",
]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")


for rel in REQUIRED:
    require((ROOT / rel).is_file(), f"missing {rel}")
print(f"PASS: {len(REQUIRED)} opening-slice files")

exterior = (ROOT / REQUIRED[0]).read_text(encoding="utf-8")
interior = (ROOT / REQUIRED[1]).read_text(encoding="utf-8")
props = (ROOT / REQUIRED[5]).read_text(encoding="utf-8").lower()

for marker in (
    "ApartmentExterior",
    "OppositeAlleyWallA",
    "DrainChannel",
    "SteamVentA",
    "StreetFixture",
    "Player",
    "WorldBounds",
    "y_sort_enabled = true",
):
    require(marker in exterior, f"exterior is missing {marker}")
print("PASS: apartment, right alley, drainage, props, player, bounds, and Y-sort")

for light in ("DoorCyanSpill", "AlleyMagentaSpill", "StreetAmberSpill"):
    require(light in exterior, f"missing separate Godot light {light}")
require("SMV4_FX401_RainOverlay.tscn" in exterior, "rain overlay is not instanced")
require("steamtek_v4_steam_fx.gd" in (ROOT / REQUIRED[8]).read_text(encoding="utf-8"), "steam vent has no separate FX")
require("cyan" not in props and "magenta" not in props, "base prop art contains baked color direction")
print("PASS: neutral base art with separate rain, steam, and colored lights")

require(
    'target_scene = "res://scenes/levels/apartment/Apartment_Interior.tscn"'
    in (ROOT / "scenes/modular_v4/modules/walls/SMV4_W103_FrontDoor.tscn").read_text(encoding="utf-8"),
    "exterior door does not target apartment interior",
)
require(
    'target_scene = "res://scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn"'
    in interior,
    "interior exit does not return to the approved apartment/alley exterior",
)
require("WorkbenchCollision" in interior and "BedCollision" in interior and "StorageCollision" in interior, "interior furniture collision incomplete")
print("PASS: bidirectional zoning and upgraded interior collision")

for rel in REQUIRED[6:13]:
    text = (ROOT / rel).read_text(encoding="utf-8")
    if "StaticBody2D" in text:
        require("collision_layer = 1" in text and "collision_mask = 2" in text, f"incorrect layers in {rel}")
print("PASS: alley prop collision layers")
