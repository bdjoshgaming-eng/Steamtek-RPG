# Steamtek Apartment Exterior V3

This is the first apartment kit built against the locked west/east environment camera and current production C001 scale. It is isolated from `main.gd` and `main.tscn`.

## Open these tomorrow

1. Camera comparison: `res://scenes/tests/surface/Steamtek_ApartmentExterior_WestEast_CameraGate.tscn`
2. Construction comparison: `res://scenes/tests/surface/Steamtek_ApartmentExterior_V3_ConstructionGate.tscn`
3. Modular construction proof: `res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_ModularAssembly.tscn`
4. Placeable golden exterior: `res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_Placeable.tscn`
5. Blender master: `blender/modular_v2/apartment_exterior_v3/Steamtek_ApartmentExterior_WestEast_Master.blend`

## Module family

- `SMV3_F101_ApartmentFoundationMacro` — one-piece footprint and wet apron
- `SMV3_W101_FrontPlain`
- `SMV3_W102_FrontWindow`
- `SMV3_W103_FrontDoor` — includes door interaction area
- `SMV3_W104_FrontUtility`
- `SMV3_W201_SidePlain`
- `SMV3_W202_SideWindow`
- `SMV3_R101_ApartmentRoofMacro` — one-piece continuous roof, no checkerboard

## How to build

Create the foundation first. Add front bays along `(256,-128)`, side bays along `(-256,-128)`, and the second storey at `(0,-219)`. Use the Steamtek toolbar `Snap` button or automatic release snapping. Occupied sockets are skipped in Snap 2.3.0, so a new bay will not stack over an already-connected bay.

The complete placeable scene sorts as one building and includes a footprint collision shape plus a door interaction area. The door transition script is intentionally not connected while Claude is reorganizing gameplay scripts.

## Rebuild

Run the source script in Blender 4.5 LTS:

`blender/modular_v2/apartment_exterior_v3/Steamtek_Build_ApartmentExterior_WestEast.py`

It rebuilds the master blend, both camera calibration renders, eight production module renders, the golden render, and the JSON manifest.
