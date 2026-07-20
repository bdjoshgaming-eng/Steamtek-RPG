# STK_PROP_Couch_L4_Right — Production Candidate QA

## Result

**APPROVED WITH CONSERVATIVE GEOMETRY WARNINGS — gameplay approved 2026-07-20**

The Meshy source was normalized as a separate right-facing production asset. The approved left-facing sectional and the v02 apartment assembly were not replaced or edited. Following gameplay approval, the right-facing base couch was registered once in the Builder.

## Outputs

- Production GLB: `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Couch_L4_Right_Production.glb`
- Modular wrapper: `res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Couch_L4_Right.tscn`
- Right-specific materials: `res://assets/environment/live3d/materials/apartment_interior_variants/couch_l4_right/`
- Reference comparison: `res://scenes/environment/live3d/qa/STK_PROP_Couch_L4_Right_Candidate_Review.tscn`
- Apartment comparison: `res://scenes/environment/live3d/qa/STK_PROP_Couch_L4_Right_Candidate_ApartmentReview.tscn`

## Dimensions, pivot, and orientation

Blender source coordinates use X width, Y depth, and Z height. Godot imports the normalized GLB as X width, Z depth, and Y height.

| Check | Source | Final |
|---|---:|---:|
| Width | 1.899189 m | 3.200000 m |
| Depth | 0.914958 m | 1.800000 m |
| Height | 0.596109 m | 0.900000 m |
| Minimum bound | source-local | `(-1.6, 0.0, -0.9)` in Godot |
| Root scale | source-dependent | `(1, 1, 1)` |

- Bottom-center pivot: **PASS**
- Floor contact at Godot Y = 0: **PASS**
- Front faces +Z toward the room: **PASS**
- Negative scale: **none**
- Right-facing orientation: **PASS** — the source return is preserved on negative X when facing +Z; it was not mirrored from the left asset.

## Geometry

| Check | Source | Final Godot import |
|---|---:|---:|
| Mesh objects | 1 | 1 |
| Vertices | 13,327 | 13,745 |
| Triangles | 17,529 | 17,529 |
| UV layers | 1 | 1 |
| Materials | 1 | 1 |
| Connected components retained | — | 1 |
| Zero-area faces | — | 0 |
| Loose vertices | — | 0 |
| Loose edges | — | 0 |
| Boundary edges | — | 36 |
| Non-manifold edges | — | 56 |

Repairs performed:

- Merged 4,554 duplicate/coincident vertices at the conservative pipeline tolerance.
- Recalculated normals consistently.
- Removed no meaningful disconnected pieces; the silhouette, cushions, arms, return back, UVs, and baked texture layout were preserved.
- Applied location, rotation, and scale before GLB export.
- Re-imported the completed GLB in Blender and Godot.

The remaining 36 boundary and 56 non-manifold edges are retained warnings. Automated filling was not used because it could close intentional hard-surface openings or damage the approved silhouette and UVs.

## Source materials and textures

Meshy supplied one combined material, `Material_0.001`, with one UV atlas and three embedded 4096 × 4096 maps:

- Baked base color — sRGB
- Baked metallic/roughness — non-color packed data
- Baked emission

No normal map was supplied. The source base color, leather grain, cushion shading, scratches, grime, edge wear, copper coloring, and ambient shading remain intact.

The Godot copies use VRAM compression and mipmaps to match the validated import policy used by the approved left sectional and reduce runtime texture pressure.

## Matte response

The production shader uses the accepted apartment-prop response as its reference:

- Approved `STK_PROP_Couch_L4_Left`
- Existing two-seat `STK_PROP_Couch_A`
- `STK_PROP_Workstation_A`
- Production bed and apartment lighting

Applied response:

- Source roughness is multiplied by 1.20 before regional floors are applied.
- Upholstery roughness floor: 0.84; metallic forced to 0.
- Painted-frame roughness floor: 0.74; metallic adjustment limited to 0.30 maximum.
- Structural response floor: 0.76 for low-metal areas, grading to 0.62 for metal.
- Aged-copper roughness floor: 0.56; metallic adjustment remains limited.
- Specular response: 0.18.

Normal GPU captures under the comparison rig and apartment lighting show broad, restrained highlights. The upholstery does not read wet or plastic-coated, the frame does not read as polished steel, and copper remains subordinate.

## Recolor masks and presets

Because the source contains one combined material, three right-specific soft grayscale masks were created:

| Region | Nonzero atlas coverage | Weighted atlas coverage |
|---|---:|---:|
| `Cushion_Leather` | 22.326% | 18.643% |
| `Frame_PaintedMetal` | 56.721% | 48.150% |
| `Accent_Metal` | 1.102% | 0.229% |

Files:

- `MASK_CouchL4Right_CushionLeather.png`
- `MASK_CouchL4Right_FramePaint.png`
- `MASK_CouchL4Right_AccentMetal.png`

The masks retain the baked texture detail and keep upholstery, frame paint, and narrow copper accents independently controllable. Structural gunmetal, scratches, grime, rust, edge wear, and baked shading remain in the residual source response.

Test-only presets were created without duplicating the GLB or adding multiple couches to the apartment:

- Source Matte
- Oxblood
- Deep Teal
- Electric Plum
- Burnished Ochre

All five materials load in Godot and bind all three right-specific masks. Normal GPU captures confirm that upholstery recoloring does not tint the surrounding approved reference couches or workstation.

## Collision

The render mesh is not used for physics. The wrapper contains six `BoxShape3D` collision shapes:

| Shape | Position | Size |
|---|---|---|
| Long lower frame | `(0, 0.20, -0.49)` | `(3.20, 0.40, 0.82)` |
| Return lower frame | `(-1.19, 0.20, 0)` | `(0.82, 0.40, 1.80)` |
| Main backrest | `(0, 0.67, -0.80)` | `(3.20, 0.46, 0.20)` |
| Return backrest | `(-1.50, 0.67, 0)` | `(0.20, 0.46, 1.60)` |
| Main outer arm | `(1.49, 0.48, -0.43)` | `(0.22, 0.56, 0.78)` |
| Return outer arm | `(-1.19, 0.48, 0.79)` | `(0.78, 0.56, 0.22)` |

The two-part lower collision and two-part back collision preserve the correct right-facing L footprint and interior-corner walking clearance.

## Sockets

All sockets use `live3d_meter_v1` and the 0.3 m furniture placement profile.

Seat sockets:

| Socket | Position | Y rotation |
|---|---|---:|
| `Seat01` | `(1.02, 0.45, -0.25)` | 0° |
| `Seat02` | `(0.16, 0.45, -0.25)` | 0° |
| `Seat03` | `(-0.70, 0.45, -0.25)` | 0° |
| `Seat04_Return` | `(-1.18, 0.45, 0.46)` | 90° |

Furniture/alignment sockets:

| Socket | Position | Y rotation |
|---|---|---:|
| `MainOuterFurniture` | `(1.60, 0, -0.40)` | 0° |
| `ReturnOuterFurniture` | `(-1.20, 0, 0.90)` | 90° |
| `FrontAlignment` | `(0, 0, 0.90)` | 0° |
| `RearWallAlignment` | `(0, 0, -0.90)` | 0° |

The return-side transforms were derived for this mesh and were not copied unchanged from the left-facing asset.

## Godot and editor integration

- Normal Godot import: **PASS**
- Structural validator: **PASS** (`SECTIONAL_RIGHT_CANDIDATE_QA PASS`)
- Normal non-headless GPU renderer: **PASS**, AMD Radeon 890M via OpenGL Compatibility
- Cameras/lights in production wrapper: **none**
- Rig/animations: **none**
- Material Variant Editor: **compatible**; right-oriented sectionals now resolve the right texture/mask template and save variants against the right base scene.
- Steamtek Live3D Builder: **registered once as `Apartment - Couch L4 Right`** following gameplay approval.
- Production apartment replacement: **not performed**.

The QA scenes compare the candidate beside C001, the approved left sectional, the existing two-seat couch, the workstation, the approved floor, walls, and apartment lighting. The return, full return backrest, both outer arms, and all four seating positions remain readable.

## Left-variant protection

Before/after SHA-256 hashes are identical:

| Protected file | SHA-256 |
|---|---|
| `STK_PROP_Couch_L4_Left_Production.glb` | `25863832A691FB71368585CF6F1BB6F16E44D2EE0A13766E3B92CDF709F3F308` |
| `STK_PROP_Couch_L4_Left.tscn` | `219084F724B55A86E99C19046F82BA7437CC31E69C16C57E30175F3DE4170E56` |
| `STK_CouchL4_MaterialVariant.gdshader` | `92B287A86ED192B859C0DD1E5A74DF15F88C79753566BA2D677C9451EBE26A0C` |

The approved left couch remains registered once in the Builder and remains in `SteamtekPlayerApartmentProductionAssembly3D_v02.tscn`. The approved right couch is available in the Builder but appears only in dedicated QA scenes until the user places it.

## Remaining warnings

- Conservative topology warnings: 56 non-manifold and 36 boundary edges remain, with no zero-area faces or loose geometry.
- Existing unrelated project warnings remain for a nested `project.godot`, the street-lamp UID, and the C001 external-resource UID fallback.
- The approved base asset is in the Builder catalog. It does not automatically replace or remove any production couch.
