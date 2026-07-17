# Steamtek Overnight Handoff — Environment Camera + Apartment Exterior V3

Date: July 15, 2026  
Status: **all five requested steps complete**

No changes were made to `main.gd`, `main.tscn`, `SurveyBook.gd`, or Claude's gameplay refactor.

## 1. Existing Blender camera audit — complete

The project was not using one environment camera:

- Foundation: 30° elevation, true 2:1
- Sidewalk: approximately 30°, true 2:1
- Roof: 35.264°, classic isometric
- Plain wall: approximately 39.19°, neither contract

This drift was a direct cause of assets that could share nominal snap points but still look visually misaligned.

## 2. West/east calibration environment — complete

A new Blender master was built with:

- current comparison camera;
- locked west/east candidate camera;
- two-storey apartment reference assembly;
- current C001 production scene used unchanged in Godot scale gates;
- real cyan, magenta, and amber fixtures supporting colored reflections;
- a continuous macro roof and a one-piece wet foundation/apron.

Master:

`blender/modular_v2/apartment_exterior_v3/Steamtek_ApartmentExterior_WestEast_Master.blend`

## 3. Current versus proposed camera renders — complete

Open:

`res://scenes/tests/surface/Steamtek_ApartmentExterior_WestEast_CameraGate.tscn`

Both renders use the same building and the same 30° elevation. The only change is a 90° horizontal azimuth rotation, so the true 2:1 diamond remains intact.

Rendered comparisons:

- `assets/modular_v2/apartment_exterior_v3/calibration/ApartmentExterior_CurrentAzimuth.png`
- `assets/modular_v2/apartment_exterior_v3/calibration/ApartmentExterior_WestToEastCandidate.png`

## 4. Camera and modular construction contract — complete

Locked V3 values:

- orthographic true 2:1 dimetric;
- elevation 30°;
- west/east forward vector `(-0.612372, 0.612372, -0.500000)`;
- front bay step `(256, -128)`;
- side bay step `(-256, -128)`;
- storey rise `(0, -219)`;
- module root scale `(1,1)`;
- C001 scale reference stays at visual scale `0.73`, offset about `(0,-110)`;
- collision reference remains `28 × 18`.

Contract files:

- `docs/STEAMTEK_ENVIRONMENT_CAMERA_CONTRACT.md`
- `tools/modular_v2/Steamtek_Environment_Camera_Contract.json`

Snap add-on upgraded to 2.3.0 without removing V2 support:

- recognizes V3 foundation families;
- accepts per-family lattice axes;
- skips occupied sockets instead of stacking a new module over an existing connection;
- retains automatic release snapping plus the compact `STK`, `Snap`, and `Grid` toolbar controls.

## 5. Apartment exterior kit + golden placeable assembly — complete

Reusable V3 modules:

- one-piece wet foundation/apron;
- front plain, window, door, and utility bays;
- side plain and window bays;
- continuous macro roof with one restrained drainage run;
- exact snap markers, pivots, and root-scale contract.

Open the modular proof:

`res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_ModularAssembly.tscn`

Open or place the complete exterior:

`res://scenes/modular_v2/apartment_exterior_v3/buildings/SMV3_B101_ApartmentExterior_Placeable.tscn`

The placeable exterior includes:

- one whole-building visual for stable sorting;
- a building-footprint collision shape;
- a door interaction area and target-scene metadata;
- footprint snap markers;
- no dependency on the gameplay refactor.

Compare modular versus golden in:

`res://scenes/tests/surface/Steamtek_ApartmentExterior_V3_ConstructionGate.tscn`

## QA completed

- Blender 4.5 LTS rebuild: passed
- Saved master camera/render inspection: passed
- Four isolated Godot scenes launched directly: passed
- Snap 2.3.0 clean-project editor load: passed
- Automated projection, alpha, pivot, scene, collision, snap, and packaging checks: **110/110 passed**

QA report:

`docs/STEAMTEK_APARTMENT_EXTERIOR_V3_QA.md`

The full Steamtek editor scan currently reports an unrelated compile error in Claude's in-progress `SurveyBook.gd/main.gd` refactor (`resource_stats_label` is not declared). That code was deliberately left untouched. It does not prevent the four isolated V3 scenes from launching directly.

## What to review tomorrow

1. Open the camera gate and compare the two horizontal views.
2. Open the construction gate and check the building against C001 scale.
3. Open the modular assembly and drag a bay away, then use `Snap` to reconnect it.
4. Open the placeable scene and inspect collision plus `DoorInteraction`.
5. Review the visual finish against the complete canonical surface reference, especially wet streets, pooled water, masonry, pipes, density, and cyan/magenta/blue/purple/amber balance.

The whole-image reference remains authoritative:

`docs/references/Steamtek_Surface_ColorPalette_Aesthetic_Reference.png`

The V3 kit is the first asset family built on the corrected technical contract. Further art refinement can now happen without changing camera, pivots, scale, roots, or sockets.

## Recovery archive

`docs/archives/Steamtek_ApartmentExterior_V3_20260715.zip`

SHA-256: `7E42B7A5A47C70B4EB1DCA4C6C3029577CD61020E5CA32C52E8FCE576EBF8255`
