# Steamtek Modular V4 — Playable Apartment + Right Alley Milestone

Status: implemented for review

Date: July 15, 2026

## Final validation

Validated with the official Godot 4.7 stable Windows build on July 15, 2026.

- Editor startup and Steamtek Modular Snap 4.0 plug-in load: pass
- Nine reusable V4 module scenes: pass
- Neutral facade art gate scene load: pass
- Modular apartment assembly scene load: pass
- Apartment interior scene load: pass
- Apartment + right alley playable demo scene load: pass
- Existing `main.tscn` compatibility wrapper load: pass
- Static contract checks for basis, scale, collision layers, door zoning, and
  separate colored lighting: pass

The only editor messages observed were pre-existing warnings for the nested
external Godot test project and the legacy P001 street-lamp texture UID. Neither
belongs to the V4 milestone and neither prevents the V4 demo from loading.

## Locked construction basis

- Camera presentation: fixed orthographic 2.5D
- Azimuth: 60 degrees
- Elevation: 30 degrees
- Front bay: `(313.534, -90.509)`
- Side bay: `(-181.020, -156.768)`
- Storey rise: `(0, -219)`
- Root scale: `(1,1)`
- Runtime camera rotation: disabled

## Snap system

Steamtek Modular Snap 4.0 uses the V4 basis directly. V4 modules can be placed
without a TileMapLayer. `Snap` joins compatible Marker2D sockets; `Grid` rounds
the selected V4 root to the nearest point on the locked two-axis lattice.

## Neutral art structure

The V4 facade kit is drawn as deterministic neutral Godot CanvasItem artwork.
Concrete, gunmetal, copper, repairs, grime, rain streaks, and mismatched panels
are local material information. Cyan, magenta, and amber illumination are
separate PointLight2D and emission-mask nodes. Turning the lights off leaves
complete neutral architecture with no colored spill baked into it.

## Reusable modules

- `SMV4_W101_FrontPlain.tscn`
- `SMV4_W102_FrontWindow.tscn`
- `SMV4_W103_FrontDoor.tscn`
- `SMV4_W104_FrontUtility.tscn`
- `SMV4_W201_SidePlain.tscn`
- `SMV4_W202_SideWindow.tscn`
- `SMV4_R101_RoofCell.tscn`
- `SMV4_C101_OutsideCorner.tscn`
- `SMV4_C102_FrontEndCap.tscn`

All modules are in `res://scenes/modular_v4/` and retain root scale `(1,1)`.

## Apartment exterior

Reusable assembly:

`res://scenes/modular_v4/buildings/SMV4_B101_ApartmentExterior_ModularAssembly.tscn`

Placeable wrapper:

`res://scenes/modular_v4/buildings/SMV4_B101_ApartmentExterior_Placeable.tscn`

Compatibility wrapper used by the existing main scene:

`res://scenes/levels/apartment/Apartment_Exterior_Working.tscn`

The building uses split wall collisions plus a complete footprint blocker. The
only interactable exterior feature is the apartment door. Its detection area
is separate from the solid body collision and zones to the apartment interior.

## Playable proof

Open or run:

`res://scenes/tests/surface/Steamtek_ApartmentRightAlley_V4_Demo.tscn`

The scene contains the modular apartment exterior, an open service alley to its
right, C001, collision, Y-sorting, Godot-owned colored lights, and an apartment
door that responds to Enter or the future `interact` action.

Interior zoning target:

`res://scenes/levels/apartment/Apartment_Interior.tscn`

The interior exit zones back to the isolated V4 demo.

## Art review gate

`res://scenes/modular_v4/validation/Steamtek_V4_NeutralFacade_ArtGate.tscn`

This gate is the review surface for the less-polished, gritty, functional
neo-industrial direction. It intentionally avoids glossy Blender presentation,
decorative Victorian treatment, and baked colored lighting.
