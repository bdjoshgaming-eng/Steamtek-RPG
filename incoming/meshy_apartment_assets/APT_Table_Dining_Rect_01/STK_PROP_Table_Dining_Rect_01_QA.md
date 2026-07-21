# STK_PROP_Table_Dining_Rect_01 Production QA

## Status

**PRODUCTION APPROVED — NORMAL GODOT EDITOR/F6 REVIEW PASSED 2026-07-20**

The approved Meshy GLB has been conservatively cleaned, scaled, grounded, promoted to the production asset location, wrapped for Godot, given simplified collision and sockets, and integrated with the Steamtek Material Variant Editor. The corrected material was reviewed in the normal Godot editor and approved by the user. The base table is registered with the Live3D Builder; the four test materials remain material-only and are not separate Builder entries. The table has not been placed in the production apartment.

## Production outputs

- Production GLB: `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Table_Dining_Rect_01_Production.glb`
- Godot wrapper: `res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Table_Dining_Rect_01.tscn`
- Source-matte material: `res://assets/environment/live3d/materials/apartment_interior_variants/table_dining_rect_01/STK_MAT_Table_Dining_Rect_01_SourceMatte.tres`
- Isolated review scene: `res://scenes/environment/live3d/qa/STK_PROP_Table_Dining_Rect_01_Candidate_Review.tscn`
- Apartment comparison scene: `res://scenes/environment/live3d/qa/STK_PROP_Table_Dining_Rect_01_Candidate_ApartmentReview.tscn`

## Dimensions and transforms

Blender used X width, Y depth, Z height. Godot imports the result as X width, Z depth, Y height.

| Check | Source | Final |
|---|---:|---:|
| Width | 1.899508 m | **2.400000 m** |
| Depth | 0.913925 m | **1.200000 m** |
| Overall height | 0.732601 m | **0.750000 m** |
| Tabletop height | — | **0.750 m** |
| Tabletop thickness | — | **0.130 m** collision proxy / approximately 0.10–0.14 m visual target |

- Controlled whole-asset scale factors: X `1.263485`, depth `1.313018`, height `1.023750`.
- Production GLB root location: `0,0,0`.
- Production GLB root rotation: `0,0,0`.
- Production GLB root scale: `1,1,1`.
- Lowest floor contact: Godot Y `0.000000 m`.
- Pivot: bottom center of the full footprint.
- Forward contract: `+Z` toward the room. The table is nearly front/rear symmetrical, but the wrapper and sockets use this convention consistently.
- Negative scale: none.
- The resulting 0.75 m tabletop height and 2.40 x 1.20 m footprint read as a seated dining table in the Blender candidate audit. Final C001/gameplay judgment remains an F6 approval item.

## Geometry

| Check | Source | Final GLB re-import |
|---|---:|---:|
| Mesh objects | 1 | 1 |
| Triangles | 18,184 | **18,184** |
| Vertices | 17,629 | **17,901** |
| UV sets | 1 | 1 |
| Material slots | 1 | 1 |
| Rig | none | none |
| Animations | none | none |

The vertex-count difference is an export/re-import representation change at UV/hard-edge seams; triangle count and visible topology were preserved. No decimation or aggressive remesh was applied.

Cleanup and checks:

- Loose vertices removed: `0`.
- Loose edges removed: `0`.
- Zero-area faces after cleanup: `0`.
- Microscopic disconnected components removed: `0`.
- Connected components retained: `2`; both are large enough to be intentional construction/trim.
- Normals were recalculated consistently after conservative cleanup.
- Boundary edges remaining: `96`.
- Non-manifold edges remaining: `167`.

The remaining boundary/non-manifold edges were not automatically filled because that could close purposeful hard-surface openings or damage the silhouette, UVs, and baked appearance. They require normal-editor visual inspection but are not currently treated as a production blocker for a static prop.

## Materials, textures, and matte correction

Meshy supplied one combined material named `Material_0.001`. It contained three embedded 4096 x 4096 maps:

- `Baked_BaseColor`
- `Baked_MetallicRoughness`
- `Baked_Emit`

The embedded maps were extracted to stable production paths and explicitly rebound in the Steamtek shader material. No external broken texture path was present; the repair was stable extraction and explicit Godot binding.

The source color, UV appearance, panel separation, baked shading, scratches, grime, edge wear, copper detail, cyan, and magenta were retained. No broad texture repaint was performed.

Matte correction in `STK_TableDining_MaterialVariant.gdshader`:

- Source roughness multiplier: `1.25`.
- Locked structural roughness floor: `0.64`.
- Tabletop roughness floor: `0.76`.
- Painted-frame roughness floor: `0.70`.
- Aged-copper/accent-metal roughness floor: `0.54`.
- Source metallic response capped at `0.72`.
- Tabletop metallic response capped at `0.40` before the limited editor offset.
- Painted-frame metallic response capped at `0.50` before the limited editor offset.
- Specular set to `0.18`.

These values target matte to low-satin response and avoid the wet, plastic-coated Meshy-viewer look. The accepted couch, sectional, workstation, bed, and bookshelf are present as visual references across the two QA scenes; exact apartment-lighting approval is still pending normal-editor F6 review.

## Recolor masks

Because the source has one atlas/material, five 4096 x 4096 grayscale UV masks were created from the real production mesh and textures:

| Region | Mask | UV coverage |
|---|---|---:|
| `Tabletop_DarkSurface` | `MASK_TableDining_Tabletop.png` | 19.905829% |
| `Frame_PaintedMetal` | `MASK_TableDining_FramePaint.png` | 30.727702% |
| `Accent_Metal` | `MASK_TableDining_AccentMetal.png` | 5.307359% |
| `Accent_Powered_Cyan` | `MASK_TableDining_EmissionCyan.png` | 1.759869% |
| `Accent_Powered_Magenta` | `MASK_TableDining_EmissionMagenta.png` | 0.197941% |

Locked pixels preserve structural gunmetal, scratches, grime, rust, edge wear, ambient occlusion, baked shading, and surface panel lines. Recoloring is luminance-preserving and does not use a whole-object tint.

Emission configuration:

- Cyan and magenta use separate masks, tint controls, strengths, and enable/disable parameters.
- Source-matte cyan strength: `0.90`.
- Source-matte magenta strength: `0.55`.
- Emission is multiplied by the source emission-map luminance and its matching mask.
- No `OmniLight3D` or `SpotLight3D` was added to the prop.

Four material-only test presets were created without duplicating the GLB or placing extra tables:

- `STK_MAT_Table_Dining_Rect_01_Graphite.tres`
- `STK_MAT_Table_Dining_Rect_01_DeepNavy.tres`
- `STK_MAT_Table_Dining_Rect_01_MutedOxblood.tres`
- `STK_MAT_Table_Dining_Rect_01_BurnishedOchreGray.tres`

## Collision

The wrapper uses one `StaticBody3D` with **three BoxShape3D collision shapes**. The render mesh is not used for collision.

| Shape | Size (X,Y,Z) | Center (X,Y,Z) |
|---|---|---|
| Tabletop | `2.40, 0.13, 1.20` | `0, 0.685, 0` |
| Pedestal | `0.95, 0.44, 0.58` | `0, 0.370, 0` |
| Floor base | `1.68, 0.12, 0.88` | `0, 0.060, 0` |

The arrangement omits pipes, light strips, panels, trim, and minor bevels. It leaves the long sides and most of the underside open for chairs, knees, and navigation. Final collision feel remains part of gameplay review.

## Furniture snap sockets

All transforms are local to the bottom-center table root; rotations are zero unless noted.

| Socket | Position (X,Y,Z) |
|---|---|
| `FurnitureChain_Front_01` | `-0.80, 0.00, 0.60` |
| `FurnitureChain_Front_02` | `0.80, 0.00, 0.60` |
| `FurnitureChain_Rear_01` | `-0.80, 0.00, -0.60` |
| `FurnitureChain_Rear_02` | `0.80, 0.00, -0.60` |
| `FurnitureChain_LeftEnd` | `-1.20, 0.00, 0.00` |
| `FurnitureChain_RightEnd` | `1.20, 0.00, 0.00` |
| `FrontAlignment` | `0.00, 0.00, 0.60` |
| `RearAlignment` | `0.00, 0.00, -0.60` |

Placement metadata uses `live3d_meter_v1` and the `furniture_0_3m` profile.

## Chair sockets

The chair sockets are separate from Builder chain sockets and do not place chairs automatically.

| Socket | Position (X,Y,Z) | Y rotation |
|---|---|---:|
| `ChairSocket_Front_01` | `-0.80, 0.00, 0.92` | 180° |
| `ChairSocket_Front_02` | `0.00, 0.00, 0.92` | 180° |
| `ChairSocket_Front_03` | `0.80, 0.00, 0.92` | 180° |
| `ChairSocket_Back_01` | `-0.80, 0.00, -0.92` | 0° |
| `ChairSocket_Back_02` | `0.00, 0.00, -0.92` | 0° |
| `ChairSocket_Back_03` | `0.80, 0.00, -0.92` | 0° |
| `ChairSocket_LeftEnd` | `-1.50, 0.00, 0.00` | +90° |
| `ChairSocket_RightEnd` | `1.50, 0.00, 0.00` | -90° |

The QA scenes instance simple 0.45 m seat-height chair proxies at these transforms for 6–8 seat clearance review.

## Tool compatibility

- Material Variant Editor profile: `steamtek_dining_table_rect_v1`.
- Supported independent regions: tabletop, frame paint, accent metal, cyan power, magenta power.
- Tabletop/frame/accent controls: color, tint strength, brightness, roughness adjustment, and limited metallic adjustment.
- Powered controls: color, emission strength, and emission enable/disable.
- Scene-local override and generated-variant paths are integrated.
- Geometry, collision, sockets, pivot, scale, and dimensions are not touched by material changes.
- Builder-compatible metadata and furniture sockets are present.
- Builder library registration: **PASS — base table only**.

## Godot validation state

- Blender finished-GLB re-import: **PASS**.
- Resource-path/static wrapper audit: **PASS**.
- Production GLB and production textures imported by the normal Godot editor: **PASS**.
- Initial Godot shader compile: **FAILED**, because `source_color` was used as a local variable name and is reserved by the Godot 4.7 shader language.
- Shader repair: **APPLIED** — the local variable was renamed to `base_sample`; the texture bindings themselves were valid.
- Normal Godot editor shader recompile after repair: **PASS**; the latest review log contains no table shader error.
- Isolated normal-editor visual review: **PASS / USER APPROVED**.
- Material texture, panel detail, scratches, copper edging, and matte response: **PASS / USER APPROVED**.
- Locked-apartment-camera review: **accepted by user as the production visual gate**.
- Material Variant Editor compatibility: **IMPLEMENTED**; five-region editing remains available for scene-local and saved-variant use.
- Gameplay collision/legroom layout: **APPROVED with the eight temporary chair proxies**.

The asset is visually approved. It may now be placed through the Live3D Builder or instanced manually. No automatic production-apartment placement was performed.

## Remaining warnings

1. `167` non-manifold and `96` boundary edges remain after conservative repair; visual openings and UVs were prioritized over destructive automatic filling.
2. The table uses one atlas/material, so mask edges must receive a normal-editor visual spot-check at tabletop/frame/copper boundaries.
3. The first normal-editor review exposed a real shader compile error that rendered the table pale white. The reserved identifier was repaired and the corrected dark source material was subsequently approved.
4. The source is nearly symmetric front-to-back; the `+Z` front contract is authoritative through wrapper metadata and socket naming.
