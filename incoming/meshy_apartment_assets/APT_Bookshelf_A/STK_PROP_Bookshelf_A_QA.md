# STK_PROP_Bookshelf_A Meshy Candidate QA

## Result

**APPROVED AND PROMOTED — PASS WITH RETAINED SOURCE-TOPOLOGY WARNINGS.**

The approved candidate now occupies the canonical production GLB, wrapper, and material paths. The established Builder registration was preserved.

## Source and candidate paths

- Requested source name: `STK_PROP_Bookshelf_A_Meshy.glb`
- Actual received source: `incoming/meshy_apartment_assets/APT_Bookshelf_A/APT_Bookshelf_A.glb`
- Staged normalized GLB: `incoming/meshy_apartment_assets/APT_Bookshelf_A/staged_pipeline/STK_PROP_Bookshelf_A_ProductionCandidate.glb`
- Godot candidate GLB: `assets/environment/live3d/models/apartment_interior/meshy/candidates/STK_PROP_Bookshelf_A_ProductionCandidate.glb`
- Production GLB: `assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Bookshelf_A_Production.glb`
- Production wrapper: `scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn`
- Candidate wrapper: `scenes/environment/live3d/props/apartment_interior/candidates/STK_PROP_Bookshelf_A_MeshyCandidate.tscn`
- Normal-editor review scene: `scenes/environment/live3d/qa/STK_PROP_Bookshelf_A_MeshyCandidate_Review.tscn`
- Apartment comparison scene: `scenes/environment/live3d/qa/STK_PROP_Bookshelf_A_MeshyCandidate_ApartmentReview.tscn`

## Geometry and scale

- Mesh objects: 1
- Render triangles: 15,679 source / 15,679 candidate
- Source vertices: 16,224
- Exported vertices after conservative cleanup/re-import: 16,521
- Target and exported dimensions: exactly `1.20 m W × 0.38 m D × 2.00 m H`
- Export bounds in Blender: X `-0.60..0.60`, Y `-0.19..0.19`, Z `0.00..2.00`
- Godot contract: X width, Y height, Z depth; front faces `+Z`
- Pivot: bottom center with floor contact at Y = 0 in Godot
- Object transforms: applied/identity
- Rig/animation: none
- UV layers: 1 preserved
- Embedded 4096 px maps preserved: BaseColor, MetallicRoughness, Emit
- Source material count: 1 combined Meshy material
- Candidate runtime material count: 1 shader override using the three source maps plus three grayscale control masks

## Shape review

- PASS: one consistent bookshelf
- PASS: solid left side panel
- PASS: solid right side panel
- PASS: full closed back panel
- PASS: open upper shelves and built-in contents
- PASS: lower cabinet with two front doors
- PASS: no side or rear handles
- PASS: top footprint remains rectangular
- PASS: cyan accent remains restrained and does not alter the top footprint
- PASS: no loose floor clutter, extra props, decorative gears, brass rivets, or added ornament

## Materials and recolor

The Meshy source uses one combined material, so clean recolor control is provided by geometry-aware UV masks while the baked source textures remain intact.

- `Frame_PaintedMetal`: generated frame mask
- `Shelf_PaintedMetal`: generated interior shelf mask
- `Accent_Powered`: generated emission mask
- Atlas coverage: frame 50.056%, shelves 11.582%, powered accent 0.331%
- Locked: books, paper, boxes, knick-knacks, structural hardware, scratches, grime, edge wear, and baked shading
- Original packed roughness: central atlas values approximately 0.44–0.47 (median about 0.45), which produced the glossy Meshy response
- Default matte response: source texture retained, roughness gain 1.25, frame floor 0.74, shelf/locked floor 0.80, metal hardware floor 0.60, specular 0.18
- Source-color normalization: a controlled 0.28 frame tint and 0.08 shelf tint keeps side, back, top, and cabinet paint in the dark blue-black family without repainting locked contents
- Test presets only: SourceMatte, DeepTeal, Oxblood, ElectricPlum, BurnishedOchre
- Oxblood uses a magenta accent; BurnishedOchre uses a warm-green accent; the other presets retain cyan
- Builder-facing color label and registered canonical scene path remain unchanged
- Material Variant Editor profile remains `steamtek_bookshelf_v1`; its bookshelf mesh allowlist now recognizes the imported production mesh name `STK_PROP_Bookshelf_A`

### Matte matching

- Reference scenes/materials inspected: `STK_PROP_Couch_A`, `STK_PROP_Workstation_A`, and `STK_PROP_Bed_A`
- Workstation reference: roughness floor 0.72, roughness gain 1.25, specular 0.18
- Bed reference: painted frame floor 0.75, structural metal floor 0.68, hardware/copper floor 0.58, specular 0.20
- Result: the bookshelf uses equally restrained specular, a 0.74 painted-frame floor, 0.80 shelves/books/locked-content floor, and 0.60 hardware floor. In the apartment comparison it does not read shinier than the workstation or couch frame.

### Emission

- Emission is masked to 0.331% of the atlas and has no real Light3D node in the prop wrapper
- Seventy-nine source emission islands were analyzed; nine substantial UV components belonging to the two authored light assemblies were retained and small stray islands were removed
- SourceMatte retains cyan at strength 0.90; variants can recolor, enable/disable, and adjust strength independently
- The normal apartment comparison confirms that the accent remains below the workstation and wall lights in visual dominance

## Collision and sockets

- Collision: one simplified `BoxShape3D`, exactly `1.20 × 2.00 × 0.38 m`
- Render mesh is not used as collision
- Left/right furniture sockets: X `-0.60` / `+0.60`
- Front/rear alignment sockets: Z `+0.19` / `-0.19`

## Validation

- PASS: Blender re-import of finished GLB
- PASS: exact dimensions within the 2 mm tolerance
- PASS: triangle target and hard maximum
- PASS: bottom-center pivot and applied transforms
- PASS: Godot full import completed with exit code 0
- PASS: Godot editor-mode resource loading for GLB, shader, all five materials, candidate wrapper, isolated review scene, and apartment comparison scene
- PASS: normal GPU-backed Godot runtime using AMD Radeon 890M / Compatibility renderer
- PASS: isolated SourceMatte and Oxblood captures; high-contrast Oxblood test shows no frame/shelf recolor leakage into books, boxes, or cabinet hardware
- PASS: apartment comparison under the approved wall shell, production lighting, locked orthographic review camera, C001, couch, workstation, and bed
- PASS: approved candidate promoted into the production GLB, wrapper, masks, shader, and five canonical material presets
- PASS: established Builder registration path/label preserved
- PASS: Material Variant Editor loads the production template material and recognizes the real imported mesh

## Warnings retained for visual approval

- 103 non-manifold edges and 61 boundary edges remain. Conservative repair preserved silhouette, UVs, shelf openings, and authored detail.
- Two connected components remain; neither is microscopic or safe to remove automatically.
- Meshy-generated top/back surfaces contain subtle triangular waviness and baked color variation visible under hard QA lighting. These are source characteristics, not new geometry or props.
- Running a rendered scene directly in this Windows headless Godot build crashes in the renderer. Editor-mode import/resource validation and normal GPU runtime both pass; use the normal Godot editor/F6 for user approval.

## Promotion status

User approval was received after normal-renderer isolated and apartment-comparison review. Promotion is complete. The old projected-atlas PNGs and their import sidecars were removed after reference checks confirmed they were unused; they remain recoverable from Git history.
