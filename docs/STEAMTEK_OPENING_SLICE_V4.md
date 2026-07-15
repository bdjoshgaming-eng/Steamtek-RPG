# Steamtek Opening Slice V4

Status: complete and ready for review

Date: July 15, 2026

## Run this scene

`res://scenes/levels/surface/Steamtek_LanternWard_ApartmentAlley.tscn`

Controls:

- WASD: movement
- Enter or R: use the apartment door

The apartment door loads:

`res://scenes/levels/apartment/Apartment_Interior.tscn`

The interior exit returns to the opening exterior.

## Completed scope

1. Approved V4 apartment exterior retained at root scale `(1,1)`.
2. A deliberate service alley was built immediately to the apartment's right.
3. Reusable pressure bin, dumpster, vent, utility cabinet, pipe rack, street
   fixture, and barrier scenes were added.
4. Wet ground variations, neutral puddles, repairs, drainage, rain, and steam
   were added without baking cyan, magenta, or amber into base architecture.
5. Godot `PointLight2D` nodes own the colored illumination.
6. The apartment interior was upgraded with a rain window, bed, pressure
   workbench, storage, collision, and bidirectional zoning.

## Scene organization

- Base ground and drainage render below the world.
- Apartment, alley walls, props, and C001 share one Y-sorted layer.
- Every solid prop uses World layer 1 and Player mask 2.
- The apartment door's interaction area uses Interactable layer 5 and Player
  mask 2.
- Rain is a screen-space CanvasLayer effect.
- Steam is a separate animated child of each vent.
- Colored lights remain independent from neutral module artwork.

## Reusable alley kit

All reusable props live in:

`res://scenes/modular_v4/modules/props/`

- `SMV4_P401_PressureBin.tscn`
- `SMV4_P402_Dumpster.tscn`
- `SMV4_P403_SteamVent.tscn`
- `SMV4_P404_UtilityCabinet.tscn`
- `SMV4_P405_PipeRack.tscn`
- `SMV4_P406_StreetFixture.tscn`
- `SMV4_P407_Barrier.tscn`

## Validation

The exterior, interior, reusable props, animation scripts, snap plug-in, and
both transition targets were loaded with Godot 4.7 stable. The automated
opening-slice contract test also checks file presence, Y-sorting, collision
layers, separate lighting/effects, and bidirectional zoning.
