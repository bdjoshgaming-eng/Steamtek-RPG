from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    target = ROOT / path
    assert target.is_file(), f"Missing required file: {path}"
    return target.read_text(encoding="utf-8")


route = read("scenes/levels/surface/Steamtek_LanternWard_SurfaceRoute.tscn")
bar = read("scenes/levels/bar/BrassLantern_Interior.tscn")
apartment = read("scenes/levels/apartment/Apartment_Interior.tscn")
bar_door = read("scenes/modular_v4/modules/walls/SMV4_W105_FrontBarDoor.tscn")
bar_exterior = read("scenes/modular_v4/buildings/SMV4_B201_BrassLanternExterior.tscn")
ground_script = read("scenes/modular_v4/scripts/steamtek_v4_surface_route_ground.gd")
bar_script = read("scenes/modular_v4/scripts/steamtek_v4_bar_interior_visual.gd")
direction = read("docs/STEAMTEK_V4_GRAPHICAL_DIRECTION_LOCK.md")


for required in (
    "SMV4_B101_ApartmentExterior_Placeable.tscn",
    "SMV4_B201_BrassLanternExterior.tscn",
    "C001_PlayerBody.tscn",
    "SMV4_FX401_RainOverlay.tscn",
    "y_sort_enabled = true",
    "ApartmentExterior",
    "BrassLanternExterior",
    "StreetAmberSpill",
    "BarWarmSpill",
):
    assert required in route, f"Surface route missing contract token: {required}"

route_path = "res://scenes/levels/surface/Steamtek_LanternWard_SurfaceRoute.tscn"
apartment_route_path = "res://scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn"
assert apartment_route_path in apartment, "Apartment interior does not return to the approved apartment/alley exterior"
assert route_path in bar, "Bar interior does not return to the complete surface route"
assert "res://scenes/levels/bar/BrassLantern_Interior.tscn" in bar_door

for scene_text, label in ((bar, "bar interior"), (apartment, "apartment interior")):
    assert "collision_layer = 1" in scene_text, f"{label} lacks world collision"
    assert "collision_mask = 2" in scene_text, f"{label} world collision does not target Player"
    assert "collision_layer = 16" in scene_text, f"{label} lacks a zoning interaction layer"
    assert "collision_mask = 2" in scene_text, f"{label} zone does not target Player"

for token in (
    "metadata/steamtek_lattice_axis_a = Vector2(313.534, -90.509)",
    "metadata/steamtek_lattice_axis_b = Vector2(-181.02, -156.768)",
    "SMV4_W105_FrontBarDoor.tscn",
    "SMV4_R101_RoofCell.tscn",
    "SignLight",
):
    assert token in bar_exterior, f"Brass Lantern exterior missing: {token}"

assert "const AXIS_A := Vector2(313.534, -90.509)" in ground_script
assert "const AXIS_B := Vector2(-181.020, -156.768)" in ground_script
assert "street spine" in ground_script.lower()
assert "Long pressure-bar counter" in bar_script

for prohibited in ("Victorian", "decorative gears", "baked cyan"):
    assert prohibited.lower() in direction.lower(), f"Direction lock missing prohibited rule: {prohibited}"

print("Steamtek V4 surface route validation passed")
