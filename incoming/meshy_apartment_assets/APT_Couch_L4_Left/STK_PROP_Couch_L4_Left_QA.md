# STK_PROP_Couch_L4_Left Production QA

## Result

**PASS — gameplay approved, registered in the Builder, and placed in the v02 production apartment.**

- Asset: `STK_PROP_Couch_L4_Left`
- Production GLB: `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Couch_L4_Left_Production.glb`
- Modular wrapper: `res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Left.tscn`
- Material package: `res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_left/`
- Scale contract: `1 Godot unit = 1 meter`
- Pivot contract: bottom center of the full L-shaped footprint
- Forward axis: `+Z`

The requested source filename `STK_PROP_Couch_L4_Left_Meshy.glb` was not present. The only GLB in the supplied source folder, `APT_Couch_L4_Left.glb`, was used and preserved as the intake source.

## Dimensions and orientation

- Final width: **3.200 m**
- Final depth: **1.800 m**
- Final height: **0.900 m**
- Bounds minimum in Godot: **(-1.600, 0.000, -0.900)**
- Seat-height contract: **0.450 m**
- Usable-seat-depth contract: **0.580 m**
- Root transform: identity; scale **(1, 1, 1)**
- Ground contact: all lowest render points at **Y = 0**
- Sectional direction: return on positive X when facing +Z; no negative-scale mirroring

## Geometry

- Source mesh objects: **1**
- Source vertices: **15,579**
- Source triangles: **18,455**
- Final render mesh objects: **1**
- Final imported vertices: **16,566**
- Final triangles: **18,455**
- Connected components preserved: **1**
- Duplicate-position vertices merged during cleanup: **6,346**
- Loose vertices removed: **0**
- Loose edges removed: **0**
- Microscopic disconnected components removed: **0**
- Zero-area faces after cleanup: **0**
- Rig / skeletons: **none**
- Animations / AnimationPlayers: **none**

The source was already inside the requested 18,000–20,000 triangle range, so no aggressive remesh or decimation was used. Normals were recalculated consistently and transforms were applied. Cushion thickness, cushion separation, return backrest, both arms, hard-surface panel edges, frame thickness, and the original L direction were preserved.

## Materials and textures

- Source material count: **1 combined material** (`Material_0.001`)
- UV sets: **1**, preserved
- Base color: embedded 4096 × 4096, preserved
- Metallic/roughness: embedded 4096 × 4096, preserved
- Emission: embedded 4096 × 4096, preserved; source signal is effectively black and remains restrained
- Normal map: **not supplied by the source**

The production material uses the accepted Steamtek props as matte references: `STK_PROP_Couch_A`, `STK_PROP_Workstation_A`, and `STK_PROP_Bed_A`.

Runtime response:

- Cushion leather roughness floor: **0.84**, metallic forced to **0**
- Painted frame roughness floor: **0.74**, metallic limited to **0.30**
- Locked structural response: approximately **0.62–0.76** based on source metallic data
- Aged copper/accent roughness floor: **0.56**
- Specular: **0.18**
- Source grain, folds, scratches, grime, edge wear, ambient shading, and metallic variation remain texture-driven

Godot textures and masks use mipmaps and VRAM compression. Project GPU texture compression remains disabled, so import compression uses the stable CPU path that avoided the prior importer crash.

## Recolor masks

Because Meshy supplied one combined material, texture-aware soft grayscale masks were created:

| Region | Nonzero atlas coverage | Weighted atlas coverage |
|---|---:|---:|
| `Cushion_Leather` | 26.204% | 23.124% |
| `Frame_PaintedMetal` | 76.243% | 51.868% |
| `Accent_Metal` | 2.192% | 0.969% |

Files:

- `MASK_CouchL4_CushionLeather.png`
- `MASK_CouchL4_FramePaint.png`
- `MASK_CouchL4_AccentMetal.png`

The masks preserve baked texture detail and do not use whole-object tinting. Godot render tests confirmed that upholstery recoloring does not recolor the frame and that frame/copper regions remain separate. Structural gunmetal, scratches, grime, edge wear, and baked shading stay locked through the residual source response.

Test-only materials were created without duplicating the GLB or couch scene:

- Source Matte
- Oxblood / blue-black / aged copper
- Deep Teal / charcoal / dark copper
- Electric Plum / navy / muted copper
- Burnished Ochre / brown-gray / brass-copper

## Collision and sockets

Collision uses **6 BoxShape3D** resources under one `StaticBody3D`; the render mesh is not used for physics:

1. Long lower couch frame
2. Return lower frame
3. Main backrest
4. Return backrest
5. Main outer armrest
6. Return outer armrest

The boxes preserve the L-shaped footprint and leave the inside corner/walking clearance open.

Sockets:

- 2 furniture-chain outer-end sockets
- 1 front-alignment socket
- 1 rear-wall-alignment socket
- 4 seat-position sockets at Y = 0.45 m
- Return seat orientation faces inward toward the main section

All placement markers use the established `live3d_meter_v1` contracts and the `furniture_0_3m` placement profile.

## Godot and integration validation

- Dedicated Godot import: **PASS**, no crash
- Production GLB scene import: **PASS**
- Production wrapper load: **PASS**
- Exact render bounds: **PASS**
- Triangle count: **PASS**
- Collision type/count: **PASS**
- Socket type/count: **PASS**
- Four material-test loads and mask bindings: **PASS**
- Material Variant Editor script parse: **PASS**
- Profile: `steamtek_sectional_couch_v1`
- Editable regions: `Cushion_Leather`, `Frame_PaintedMetal`, `Accent_Metal`
- Builder catalog: **registered once as `Apartment - Couch L4 Left`**
- `SteamtekPlayerApartmentProductionAssembly3D_v02.tscn`: **approved sectional is the primary couch; the user's additional two-seat comparison couch remains available with its corrected matte material**

Normal GPU-rendered Godot captures—not the headless renderer—were reviewed in the isolated QA scene and in a v02 apartment comparison beside C001, `STK_PROP_Couch_A`, `STK_PROP_Workstation_A`, the accepted bed, walls, and floor. The review confirmed:

- Full backrest across the main and return sections
- Both substantial armrests present
- Four readable seating positions
- Correct original L direction
- Matte worn upholstery without a wet/plastic response
- Frame response consistent with accepted apartment props
- Restrained aged copper
- Correct relative scale against C001 and the existing two-seat couch

## Remaining warnings

- **93 non-manifold edges** and **55 boundary edges** remain. They were retained because conservative automatic filling would risk changing visible frame openings, silhouette, UVs, or baked textures.
- The source supplied no normal map.
- Apartment comparison emits a pre-existing invalid-UID warning for the C001 GLB but resolves successfully by its text path; this is unrelated to the couch.
- Gameplay approval was received on 2026-07-20. The production apartment and Builder now use the approved base asset; the four color tests remain material-only and are not separately registered.
