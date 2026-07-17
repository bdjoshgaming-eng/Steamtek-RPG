# Steamtek Live-3D Scale Contract v1

Status: **locked for live-3D hybrid production**

Approved: July 17, 2026

## Scope

This contract governs Steamtek scenes that use live 3D characters, 3D
movement, 3D collision, and the locked orthographic camera. It does not erase
or silently reinterpret the preserved 2D V3/V4 route records.

The approved reference scene is:

`res://scenes/tests/hybrid_3d/Steamtek_ApartmentAlley_DimensionalBlockout_v01.tscn`

## World scale

- One Godot unit equals one meter.
- The approved C001 protagonist remains at root scale `(1, 1, 1)`.
- Environment geometry and artwork are fitted to C001; C001 is never rescaled
  to compensate for an environment asset.
- Imported characters, enemies, props, and effects must declare their physical
  dimensions before production approval.

## Approved apartment and alley dimensions

- Apartment door clear opening: `1.2 m` wide by `2.2 m` high.
- Storey height: `3.2 m`.
- Two-storey facade height before roof/parapet: `6.4 m`.
- Reference apartment footprint: `10 m` wide by `7 m` deep.
- Service alley clear width: `3.5 m`.
- Exterior and interior remain separate scenes connected by a door transition.
- The exterior building footprint remains solid collision; interacting with
  the door loads the interior rather than walking physically through the shell.

Gameplay spaces may receive a documented clearance increase of approximately
`10-20%` when combat, party navigation, or readability requires it. Such an
override never changes character scale or camera angle.

## Locked camera relationship

- Projection: orthographic.
- Horizontal azimuth: `60 degrees`.
- Elevation: `30 degrees` above the ground plane.
- Camera roll: `0 degrees`.
- Runtime camera rotation: disabled.
- Orthographic size may vary by scene for framing, but the angle and projection
  do not change. The current close exploration reference uses size `8.5`.

## Art and collision rules

1. Build and validate meter-based collision before fitting painted artwork.
2. Painted environment layers may be used as 2.5D cards, but their doors,
   windows, storeys, ground contact, and occlusion boundaries must match the
   dimensional shell.
3. Do not resize C001 to make legacy apartment artwork appear correct.
4. Use separate background, walk-behind, and foreground layers where a single
   flattened image would produce incorrect occlusion.
5. Interactive doors, cover, hazards, and traversal boundaries use real 3D
   collision even when their visible art is painted.
6. The old full-apartment painted card is a technical pipeline proof only and
   is not a scale authority.

## Approval gate for future environments

An environment passes the live-3D scale gate only when:

1. C001 remains at scale `(1, 1, 1)`.
2. Door and storey proportions read correctly beside C001.
3. Navigation clearances work at walk and run speeds.
4. The 60/30 orthographic camera frames the space without camera rotation.
5. Collision prevents entry into inaccessible painted or unmodeled volumes.
6. Foreground and background occlusion behave correctly.

