# Steamtek Lantern Ward Surface Route V4

## Delivered playable route

`Apartment exterior -> service alley -> rain-soaked main street -> Brass Lantern exterior`

Both landmark doors are working zone transitions:

- Apartment exterior -> `Apartment_Interior.tscn` -> complete surface route.
- Brass Lantern exterior -> `BrassLantern_Interior.tscn` -> complete surface route.

## Main scenes

- `res://scenes/levels/surface/Steamtek_LanternWard_SurfaceRoute.tscn`
- `res://scenes/levels/apartment/Apartment_Interior.tscn`
- `res://scenes/levels/bar/BrassLantern_Interior.tscn`
- `res://scenes/modular_v4/buildings/SMV4_B201_BrassLanternExterior.tscn`

## New reusable content

- `SMV4_W105_FrontBarDoor.tscn`: snapped front-axis door module with separate light and zone area.
- `SMV4_B201_BrassLanternExterior.tscn`: modular two-storey bar exterior assembled from V4 wall and roof scenes.
- `steamtek_v4_surface_route_ground.gd`: reusable V4 wet pavement, street spine, sidewalk highlight, seams, and drainage treatment.
- `steamtek_v4_bar_interior_visual.gd`: starter Brass Lantern interior visual, deliberately separate from the world exterior.

## How to edit it

1. Open `Steamtek_LanternWard_SurfaceRoute.tscn`.
2. Expand `YSortLayer` to move complete buildings and props.
3. Open `SMV4_B201_BrassLanternExterior.tscn` to rearrange its reusable wall and roof modules.
4. Turn on **Editable Children** only for a placed instance that needs a one-off override.
5. Keep scene roots at scale `1,1`; change composition through snapped modules rather than compensating scale.

## Controls

- `WASD`: move.
- `Enter` or `R`: use a nearby landmark door.

## Validation

- Godot 4.7 headless project import passed.
- Surface route, apartment interior, Brass Lantern interior, and Brass Lantern exterior all load successfully.
- Automated contract checks cover required scenes, paths, collisions, Y-sort, lighting separation, and the V4 snap basis.

