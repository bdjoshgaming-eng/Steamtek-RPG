# Steamtek Apartment Library D Handoff

Date: 2026-07-19

## Authority

- Camera and character presentation: **The Ascent**.
- Rendering language: **Shadowrun Returns** hand-painted illustrative style, not its palette.
- World design: **60% cyberpunk / 20% neo-industrial / 20% functional steampunk**.
- Palette: Steamtek dark blue-black steel, worn copper, restrained cyan/magenta source light, rust leather, teal fabric, plum/navy bedding, and warm domestic accents.
- Contract: real modular 3D geometry, meter scale, floor-center pivot, `+Z` front toward the room/C001, collision, and snap sockets. No cards or billboards.

## Production changes

- Removed the half wall from the production apartment and from the active Builder catalog.
- Replaced the ambiguous wall-card exit with a true 3D service door: inset leaf, separate frame, threshold, shadow gap, access reader, handle, status strip, and closed-door collision.
- Added two compatible 9 ft 10 in × 8 ft 10 in (3.0 m × 2.7 m) window-wall options: wide utility window and narrow slot window.
- Replaced the apartment's major placeholder furniture with Library D production modules.
- Preserved C001, The Ascent camera contract, gameplay markers, and the top-wall exit location.

## Modular catalog

The library contains 32 true-3D modules:

- Architecture: service door wall, wide window wall, slot window wall.
- Seating: rust/teal/plum two-seat couches, rust/teal/plum lounge chairs, rust/teal dining chairs, rust/teal bar stools.
- Sleep: rust/teal/plum full beds and rust/teal/plum/ochre independent pillows.
- Storage: low service cabinet, tall wardrobe, wall kitchen cabinet, base kitchen cabinet, open service shelf.
- Tables: dining, coffee, and side tables.
- Utility and decor: round steel trash can, teal smart bin, copper magenta-source floor lamp, teal planter.

The color variants are separate scenes, so room dressing can be changed without editing or duplicating geometry.

## Apartment research translated into the kit

The content is organized around four lived-in apartment zones: sleeping/storage, living, kitchen/work, and hygiene/utility. The cyberpunk layer is carried by integrated charging/status strips, compact service storage, cable/pipe logic, repair wear, source-linked cyan and magenta light, and adaptable furniture rather than indiscriminate neon.

## Key files

- Production apartment: `res://scenes/environment/live3d/interiors/apartments/SteamtekPlayerApartmentProductionAssembly3D_v02.tscn`
- Playable apartment: `res://scenes/levels/apartment_3d/SteamtekOpeningApartmentPlayable3D.tscn`
- Architecture wrappers: `res://scenes/environment/live3d/kits/apartment_interior/`
- Furniture wrappers: `res://scenes/environment/live3d/props/apartment_interior/`
- Small-prop wrappers: `res://scenes/environment/live3d/props/apartment_interior/small/`
- GLB library and manifest: `res://assets/environment/live3d/models/apartment_interior/library_d/`
- Blender master: `res://blender/live3d/apartment_interior/APT_ApartmentAssetLibrary_D.blend`
- Rebuild script: `res://blender/live3d/apartment_interior/Steamtek_Build_ApartmentAssetLibrary_D.py`
- Godot wrapper generator: `res://tools/live3d/generate_apartment_library_d_wrappers.py`
- Review renders: `res://docs/reviews/apartment_library_d/`

## Validation

- Blender batch build: `LIBRARY_ASSETS=32`.
- Godot wrappers: 32 scenes, all referenced resources present.
- Builder: 32 Library D entries added to the current `steamtek_live3d_builder` catalog.
- Production assembly: zero half-wall references and zero missing resource paths.
- Normal Godot 4.7 editor/F6 playable run completed after GLB import.
- C001 loaded in the playable scene. No scoped parse or runtime errors were logged.
- The only log message is the pre-existing C001 GLB UID fallback warning; Godot resolves its text path.

## Review status

The library is built and installed. The next human review is taste-level iteration inside the normal Godot editor: placement density, preferred color combinations, and whether individual variants should be promoted or held back. It is not waiting on missing geometry, modular setup, or engine integration.
