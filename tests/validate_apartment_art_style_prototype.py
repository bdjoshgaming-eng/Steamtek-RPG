from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn"
ART = ROOT / "assets/surface/art_style_prototype/apartment_alley/STK_APT001_ApartmentAlley_Background_v001.png"
INTERIOR = ROOT / "scenes/levels/apartment/Apartment_Interior.tscn"

assert SCENE.is_file(), "Missing playable apartment/alley art-style scene"
assert ART.is_file(), "Missing approved apartment/alley raster artwork"
assert INTERIOR.is_file(), "Missing apartment interior"

with Image.open(ART) as image:
    assert image.size == (1604, 981), f"Unexpected art dimensions: {image.size}"
    assert image.mode in ("RGB", "RGBA"), f"Unexpected art mode: {image.mode}"

scene = SCENE.read_text(encoding="utf-8")
interior = INTERIOR.read_text(encoding="utf-8")

for token in (
    "STK_APT001_ApartmentAlley_Background_v001.png",
    "C001_PlayerBody.tscn",
    "StaticBody2D",
    "collision_layer = 1",
    "collision_mask = 2",
    "y_sort_enabled = true",
    "ApartmentDoor",
    "collision_layer = 16",
    "Apartment_Interior.tscn",
    "zoom = Vector2(1, 1)",
    "SMV4_FX401_RainOverlay.tscn",
    "SteamVentWest",
    "SteamVentRoof",
    "SteamVentAlley",
):
    assert token in scene, f"Scene missing required token: {token}"

return_path = "res://scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn"
assert return_path in interior, "Apartment interior does not return to art-style exterior"

print("Steamtek apartment/alley art-style prototype validation passed")
