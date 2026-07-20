# STK_PROP_Bookshelf_A - Static Prop QA

Date: 2026-07-20  
Status: Production integration complete; normal Godot editor import and F6 visual approval pending.

## Visual authority

The five supplied PNGs are authoritative for this asset. The rejected Meshy interpretation was not used as the final visible surface. The production asset projects the supplied front, back, left, right, and top artwork directly onto a meter-correct bookshelf shell. This preserves the exact panel layout, books, storage objects, cabinet hardware, copper trim, wear, and cyan powered accents shown in the references.

Archived references:

- `STK_PROP_Bookshelf_A_Reference_Front.png`
- `STK_PROP_Bookshelf_A_Reference_Left.png`
- `STK_PROP_Bookshelf_A_Reference_Back.png`
- `STK_PROP_Bookshelf_A_Reference_Right.png`
- `STK_PROP_Bookshelf_A_Reference_Top.png`

The neutral studio backdrop beneath the front feet is excluded from the production silhouette.

## Meshy intake audit

- Actual source: `APT_Bookshelf_A.glb`
- Source render meshes: 1
- Source material slots: 1
- Source vertices: 20,120
- Source triangles: 18,000
- Source bounds before production normalization: approximately 0.9517 x 0.5927 x 1.8993 m
- Embedded source textures: 4096 BaseColor, MetallicRoughness, and Emit
- Intake decision: reject the Meshy render appearance; retain the file only as intake evidence
- Rejected visual issues: bowed/glossy top, incorrect side accents, incorrect rear ornamentation, and panel/content layout that did not match the approved PNGs

## Production render asset

- File: `STK_PROP_Bookshelf_A_Production.glb`
- Method: authoritative multi-view projected atlas with a shallow layered front facade
- Dimensions: 1.20 m wide x 0.38 m deep x 2.00 m high
- Bounds: X -0.60 to +0.60 m; Y 0.00 to 2.00 m in Godot; Z -0.19 to +0.19 m
- Pivot: bottom center
- Lowest floor contact: Y = 0
- Forward: +Z toward the room
- Root scale: 1, 1, 1
- Vertices: 76
- Triangles: 38
- Material slots: 1

Topology exception: the brief's 15,000-25,000 triangle target was intended for a conventional detailed Meshy mesh. After explicit visual correction, this asset uses the supplied artwork itself as the visible detail and therefore needs only 38 triangles. Adding unseen geometry would not improve the locked gameplay-camera result. The shallow shelf-bay offsets provide limited parallax while keeping the PNG artwork intact.

The render shell uses layered cards and is intentionally not a watertight collision mesh. Gameplay collision is supplied separately by a closed simplified box.

## Material response and recoloring

- Base appearance: source PNG color and hand-painted detail
- Structural/base roughness: 0.74
- Frame roughness: 0.68 plus editor adjustment
- Shelf roughness: 0.76 plus editor adjustment
- Specular: 0.20
- Frame metallic base: 0.18 with restricted editor adjustment
- Recolorable regions:
  - `Frame_PaintedMetal`
  - `Shelf_PaintedMetal`
  - `Accent_Powered`
- Locked visual regions:
  - structural metal
  - copper
  - books and paper
  - storage boxes and display objects
  - rust, grime, scratches, edge wear, and painted shading
- Masks:
  - `MASK_Bookshelf_FramePaint.png`
  - `MASK_Bookshelf_ShelfPaint.png`
  - `MASK_Bookshelf_Emission.png`
- Material Variant Editor profile: `steamtek_bookshelf_v1`
- Scene-local overrides and saved variants: implemented; normal editor interaction test pending

## Collision and sockets

- Collision: 1 simplified `BoxShape3D`, 1.20 x 2.00 x 0.38 m, centered at Y = 1.00 m
- Left furniture-chain socket: X = -0.60 m
- Right furniture-chain socket: X = +0.60 m
- Front alignment socket: Z = +0.19 m
- Rear wall-alignment socket: Z = -0.19 m

## Godot integration

- Model: `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Bookshelf_A_Production.glb`
- Wrapper: `res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn`
- Base material: `res://assets/environment/live3d/materials/apartment_interior_variants/bookshelf/STK_MAT_Bookshelf_A_SourceMatte.tres`
- Builder profile: Furniture / 0.3 m
- Production scene placement: intentionally not performed before gameplay visual approval

## Remaining approval gate

1. Allow the normal Godot editor to import the new GLB and PNG resources.
2. Open `STK_PROP_Bookshelf_A.tscn` and review it in the 3D editor.
3. Run the scene with F6 and compare front and angled gameplay views against the supplied PNGs.
4. Confirm the matte response and cyan brightness under apartment lighting.
5. Test each of the three Material Variant Editor regions and confirm locked artwork does not move or recolor.
6. Only after approval, place the bookshelf in the apartment production assembly.

No headless Godot visual approval was used.
