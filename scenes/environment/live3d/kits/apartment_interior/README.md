# Steamtek Apartment Interior Modular Kit v01

This is the production-facing kit for building the opening apartment in Godot. Every wall, floor, furniture item, and tabletop object remains an independent scene instance. A cup can be moved off a table and replaced with a book without editing the table.

## Open these first

- Blank workspace: `res://scenes/tests/hybrid_3d/SteamtekApartmentInteriorAssemblyBlank3D.tscn`
- Furnished production apartment: `res://scenes/environment/live3d/interiors/apartments/SteamtekPlayerApartmentProductionAssembly3D_v02.tscn`
- Playable opening: `res://scenes/levels/apartment_3d/SteamtekOpeningApartmentPlayable3D.tscn`

## Fast builder workflow

1. Open the blank workspace.
2. Use the **Steamtek Live3D Builder** dock on the right.
3. Choose **Interior Structure - 1.2 m** for floors, walls, windows, doors, half-walls, and corners.
4. Pick a module, click **Add First Module at Assembly Origin**, then extend it with the direction buttons or **Snap Nearest**.
5. Use only **Rotate +90** for alternate orientations. Never mirror with negative scale.
6. Choose **Furniture - 0.3 m** for beds, couches, tables, workbenches, lockers, bookshelves, rugs, pictures, and chairs.
7. Choose **Small Props - 0.1 m** for cups, books, bottles, plates, pillows, lamps, notes, and tool cases.
8. To dress a table or shelf, select the furniture, choose a small prop, and click **Add Chosen Object at Selected Surface Socket**.
9. Move or delete the prop normally. The furniture remains untouched. Godot Undo is supported.

The module search box accepts names and tags such as `floor`, `wall`, `bed`, `desk`, `couch`, `rug`, `picture`, `cup`, and `book`.

## Asset naming

Apartment assets use `APT_Category_Subtype_Dimensions_Variant`.

- Dimensions are centimeters: `120`, `240`, or `120x300`.
- Variant letters (`A`, `B`, `C`) identify visibly different designs.
- Textures end in `_Albedo.png`; Godot materials end in `_Mat.tres`.
- Git stores revisions, so filenames do not carry `v01`, `v02`, or workflow labels such as `HandPainted`.
- Examples: `APT_Floor_120_A.tscn`, `APT_Wall_Door_240x300_A.tscn`, and `APT_Prop_Cup_A.tscn`.

## Locked contracts

- One Godot unit equals one meter.
- Structural snap: 1.2 m.
- Furniture snap: 0.3 m.
- Small-prop snap: 0.1 m.
- Root scale: `(1, 1, 1)`.
- Y rotation: 0, 90, 180, or 270 degrees.
- C001 and its wrapper are never rescaled.
- No baked clutter: wear may be painted into a material, but authored objects remain separate.

## Architecture modules

- 1.2 m floor tile
- 2.4 m floor macro tile
- 1.2 m service grate overlay
- 1.2 m solid wall
- 2.4 m solid wall macro
- 1.2 m window wall
- 2.4 m door wall
- 1.2 m half-height partition
- corner column
- 2.4 m exposed service-pipe run

## Furniture and prop modules

- Utility table / desk
- Apartment workbench
- Locker
- Bed frame and separate mattress
- Couch
- Large rug
- Wall picture
- Coffee table
- Bookshelf
- Chair
- Cup
- Book
- Tool case
- Bottle
- Plate
- Pillow
- Table lamp
- Quest note

## Visual direction

The material set lives at `res://assets/environment/live3d/materials/apartment_interior_v01/`. Its locked mixture is **40% neo-industrial, 40% cyberpunk, and 20% practical steampunk**. It uses hand-painted dark steel wall panels, worn industrial floors, embedded interfaces, segmented technical framing, controlled cyan/magenta signals, exposed pressure infrastructure, and warm-amber domestic lighting.

This kit is Neo-Industrial and practical: no Victorian ornament, decorative gears, glossy showroom materials, or baked prop arrangements.
