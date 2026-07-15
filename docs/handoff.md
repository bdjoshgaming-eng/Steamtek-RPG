# Steamtek RPG — Modular V2 Handoff

Updated: July 14, 2026

## Resume point

Resume by reviewing the **staging-only rough wet-concrete street family**, then
continue building the remaining street roles. The user accepted G001-G004 as
**good for now**, but they have not been promoted or wired into `main.tscn`.

The first G005 worn yellow guide-stripe treatment was rejected as too generic
and archived at `docs/archives/rejected_g005_generic_stripes_2026-07-14.zip`.
G005 is now an approved rain-polished traffic-wear role: blue-black pavement,
fine aggregate, irregular wet/dry roughness, broad wheel-polished water film,
subtle seams, and soft non-emissive teal/amber reflections. It has no painted
markings and preserves the exact G001 diamond alpha. It was promoted after the
user's gameplay-scale review on 2026-07-14.

Open this exact scene first:

- `scenes/modular_v2/validation/SMV2_WetStreetFamilyFidelityTest.tscn`

Current separate paintable roles:

- G001 rough rain-darkened concrete base
- G002 repaired/resurfaced concrete
- G003 shallow-puddle concrete
- G004 cracked/worn concrete
- G005 rain-polished traffic wear
- G006 rain-wet sidewalk slab (approved production base)

There is intentionally **no storm drain**. The user wants multiple separate
tiles for assembling streets. Every variant retains the exact shared `256x128`
isometric diamond footprint.

The QA scene now uses the current animated player visual:

- `assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn`

Do not replace it with legacy `scenes/characters/C001_SteamtekRunner.tscn`.
Do not edit `scenes/main.tscn` or `scenes/main.gd`; the user is separately
reorganizing gameplay code into multiple `.gd` files.

W005/W006 are approved and promoted. The complete W001-W013 wall family now
uses the locked Blender-fidelity language and passed its production-family gate.
R001 is approved and promoted to production. Its former gray concrete PNG is
archived, and the complete R001-R005 roof family passed its production gate.
F001 is approved and promoted. Its first Blender render used a mismatched
approximately `0.584` ground-edge slope; the corrected production render now
matches the wall families at exact `+/-0.500`. The replaced version is archived
at `docs/archives/pre_f001_true2to1_correction_2026-07-14.zip`.

Outside-art intake is available from Steamtek Studio or directly through
`tools/modular-intake/Launch_Steamtek_Modular_Intake.bat`. It currently creates
staging-only candidates and QA scenes for front/side walls, ground diamonds,
roof surfaces, and foundation blocks. It never overwrites production.

Foundation attachment is now deterministic rather than visual-only:

- Front-family walls expose `Attach_FoundationFront` at their root.
- Side-family walls expose `Attach_FoundationSide` at their root.
- F001 exposes `Attach_WallFront` at `(-192, -158)` and `Attach_WallSide` at
  `(0, -254)`.
- The two wall runs occupy the foundation's back edges and meet exactly at the
  back point `(0, -254)`.
- W007 is required at any exposed front/side shared corner; raw wall planes are
  not considered a finished visual joint without the seam cover.
- `tools/validate_modular_v2.py` enforces all four attachment coordinates.

## Immediate continuation sequence

1. Open `scenes/modular_v2/validation/SMV2_WetStreetFamilyFidelityTest.tscn`.
2. Confirm the current animated player appears at the correct gameplay scale.
3. Confirm the concrete reads rough enough at 1x and the mixed field has no
   gaps or lighting checkerboard.
4. Keep G001-G004 in staging until the user explicitly approves promotion.
5. Use the promoted `scenes/modular_v2/ground/SMV2_G005_RainPolishedWear.tscn`
   as the approved rain-polished street role.
6. Continue additional street tiles as separate roles; do not add a storm drain
   unless the user later requests one.
7. Keep every ground tile on the exact `256x128` diamond and shared `64x32`
   TileMap lattice.
8. Run `tools/validate_modular_v2.py` only. Do not start headless Godot while
   the GUI editor is open.
9. Do not touch `main.gd` or `main.tscn` during modular-pipeline work.

## Current production status

The Modular-v2 validator currently passes:

Latest validation after approved G006 promotion:

`MODULAR V2 QA PASSED: 15 wall PNGs, 32 production scenes, 67 validation scenes`

Current wet-concrete staging source chain:

- `blender/scripts/build_smv2_g001.py`
- `blender/modular_v2/SMV2_G001_WetAsphaltBase.blend`
- `blender/modular_v2/SMV2_G002_WetAsphaltRepair.blend`
- `blender/modular_v2/SMV2_G003_WetAsphaltPuddle.blend`
- `blender/modular_v2/SMV2_G004_WetAsphaltCracked.blend`
- `assets/modular_v2/ground/source/blender_renders/`
- `assets/modular_v2/ground/source/fidelity_candidates/`
- `scenes/modular_v2/validation/SMV2_WetStreetFamilyFidelityTest.tscn`
- `blender/scripts/build_smv2_g005.py`
- `blender/modular_v2/SMV2_G005_RainPolishedWear.blend`
- `scenes/modular_v2/validation/SMV2_G005_RainPolishedWearFidelityTest.tscn`
- `assets/modular_v2/ground/production/SMV2_G005_RainPolishedWear.png`
- `scenes/modular_v2/ground/SMV2_G005_RainPolishedWear.tscn`
- `blender/scripts/build_smv2_g006.py`
- `blender/modular_v2/SMV2_G006_RainWetSidewalkSlab.blend`
- `scenes/modular_v2/validation/SMV2_G006_RainWetSidewalkSlabFidelityTest.tscn`

The first modeled-slab G006 revision was rejected by the user on 2026-07-15.
Although its projection, footprint, and scale were correct, it did not match the
fidelity or overall graphical feel of the current Steamtek assets. It was too
clean, flat, procedural, evenly lit, and visually sparse beside C001 and the
approved tileset reference. Technical compatibility alone is not approval.

Rejected revision archive:

- `docs/archives/rejected_g006_flat_procedural_2026-07-15.zip`

The active G006 rebuild retains the exact geometry contract but adds layered
aggregate color, irregular wetness/roughness, grime, flush repairs, branching
cracks, subtle cool rain film, stronger material highlights, and the established
Steamtek cool/cyan/amber lighting language. Curbs remain a separate family.

The approved fidelity rebuild has been copied to the canonical G006 `.blend`
filename. Numbered rebuild masters are staging history, not production sources.

The user's repeated-field screenshot exposed an obvious stamped pattern in the
second fidelity rebuild: the same cracks, repairs, and warm/cool panel layout
appeared on every tile. The third rebuild makes G006 a high-detail but neutral
base. It removes identifiable baked damage and tightens the four slab materials
into one shared range. Cracked, patched, grime-heavy, and colored-reflection
sidewalks must be separate genuine variants or overlays, never repeated motifs
inside the base tile.

Current G006 review asset:

- `assets/modular_v2/ground/source/fidelity_candidates/SMV2_G006_RainWetSidewalkSlab_blender_masked.png`

The user approved G006 on 2026-07-15. The exact reviewed PNG and rebuilt Blender
master are now promoted to:

- `assets/modular_v2/ground/production/SMV2_G006_RainWetSidewalkSlab.png`
- `scenes/modular_v2/ground/SMV2_G006_RainWetSidewalkSlab.tscn`
- `blender/modular_v2/SMV2_G006_RainWetSidewalkSlab.blend`

G006 is the neutral high-detail base. Identifiable cracks, repairs, grime,
puddles, and colored reflections remain separate variants or overlays.

Staging G006 variation family built after base approval:

- `SMV2_G006A_SidewalkWorn`
- `SMV2_G006B_SidewalkRepaired`
- Builder: `blender/scripts/build_smv2_g006_variants.py`
- Review: `scenes/modular_v2/validation/SMV2_G006_SidewalkVariationFamilyFidelityTest.tscn`

Both active variants use genuine Blender renders from approved G006 geometry and exact
canonical alpha. They remain staging-only. The mixed-field review intentionally
uses the approved base more often than each distinctive variant. Worn cracks
are thin, and the repair is a small textured utility patch contained within one
slab.

G006C reflected color was rejected on 2026-07-15 because the hard cyan/magenta
marks read as paint rather than wet reflected light. Archive:

- `docs/archives/rejected_g006c_painted_reflection_2026-07-15.zip`

Colored reflections are not sidewalk variants. Build them later as separate
environmental overlays tied to visible signs, windows, lamps, kiosks, or other
real light sources, with wet breakup and believable falloff.

Lighting ownership is now explicit: Blender bakes neutral material/form
readability, while Godot light-source scenes own contextual colored spill,
flicker, state, shadows, and wet reflections. A glowing prop may contain its
visible emissive face, but its effect on surrounding assets is scene-driven.
No orphan color is allowed: every colored spill or reflection must trace to a
visible or explicitly justified off-screen light source.
See `docs/STEAMTEK_SURFACE_SYSTEM_VISION.md`.

## G007 service-alley staging candidate

The next distinct fill role is now built as:

- `SMV2_G007_RainWetServiceAlley`
- Builder: `blender/scripts/build_smv2_g007.py`
- Active master: `blender/modular_v2/SMV2_G007_RainWetServiceAlley_Review03.blend`
- Candidate: `assets/modular_v2/ground/source/fidelity_candidates/SMV2_G007_RainWetServiceAlley_blender_masked.png`
- Review: `scenes/modular_v2/validation/SMV2_G007_RainWetServiceAlleyFidelityTest.tscn`

The paver-grid G007 was rejected because the alley should be one continuous
surface rather than another subdivided tile. Its sources are preserved in:

- `docs/archives/rejected_g007_paver_grid_2026-07-15.zip`

The active G007 is one seamless dark rain-wet resurfaced field with material
variation only. The neutral base contains no internal squares, drain, manhole,
colored reflection, litter, or identifiable repeated damage. It remains
staging-only.

The staging filenames still say `WetAsphalt`, but the current Blender materials
and QA direction are rough wet concrete. Rename them only as a deliberate
cleanup pass so active scene references are not broken.

## TileMap and wall-scene snapping

The snap plugin is version `2.1.0` and supports module-marker snapping plus the
shared TileMapLayer grid:

- `addons/steamtek_modular_snap/steamtek_modular_snap.gd`
- `addons/steamtek_modular_snap/plugin.cfg`
- Toolbar action: **Snap Selected to Grid**
- Shared lattice axes: `(64, -32)` and `(64, 32)`
- QA scene: `scenes/modular_v2/validation/SMV2_TileMapWallSnapQATest.tscn`
- TileSet: `resources/modular_v2/tilesets/SMV2_GroundTileSet.tres`

If the toolbar action is missing, disable and re-enable the Steamtek modular
snap plugin in **Project Settings → Plugins** to reload version 2.1.

Approved R001 source chain:

- `scenes/modular_v2/validation/SMV2_R001_RoofSurfaceFidelityTest.tscn`
- `scenes/modular_v2/validation/SMV2_R001_BlenderCandidate.tscn`
- `assets/modular_v2/roofs/source/fidelity_candidates/SMV2_R001_RoofSurface_blender_masked.png`
- `blender/modular_v2/SMV2_R001_RoofSurface.blend`

Current roof gate:

- `scenes/modular_v2/validation/SMV2_ProductionRoofFamilyGate.tscn`

Approved F001 source chain:

- `scenes/modular_v2/validation/SMV2_F001_FoundationFidelityTest.tscn`
- `scenes/modular_v2/validation/SMV2_F001_BlenderCandidate.tscn`
- `assets/modular_v2/foundations/source/fidelity_candidates/SMV2_F001_FoundationBlock_blender_masked.png`
- `blender/modular_v2/SMV2_F001_FoundationBlock.blend`

Current foundation gate:

- `scenes/modular_v2/validation/SMV2_ProductionFoundationGate.tscn`
- `scenes/modular_v2/validation/SMV2_F001_FrontWallAlignmentTest.tscn`
- `scenes/modular_v2/validation/SMV2_F001_RightWallPairAlignmentTest.tscn`

Promoted Blender-fidelity assets include:

- Walls: W001-W013, including W003/W011 closed/open variants
- Cornices: C001, C002, C003, C004
- Roof surface: R001
- Parapets: R002, R003, R004, R005
- Foundation: F001

Important production scenes:

- `scenes/modular_v2/walls/SMV2_W001_PlainWall.tscn`
- `scenes/modular_v2/walls/SMV2_W002_ApartmentDoor.tscn`
- `scenes/modular_v2/walls/SMV2_W003_Window.tscn`
- `scenes/modular_v2/walls/SMV2_W003_WindowOpen.tscn`
- `scenes/modular_v2/walls/SMV2_W007_OutsideCorner.tscn`
- `scenes/modular_v2/walls/SMV2_W008_InsideCorner.tscn`
- `scenes/modular_v2/walls/SMV2_W009_SeamColumn.tscn`
- `scenes/modular_v2/walls/SMV2_W010_SidePlainWall.tscn`
- `scenes/modular_v2/walls/SMV2_W011_SideWindowWall.tscn`
- `scenes/modular_v2/walls/SMV2_W011_SideWindowOpen.tscn`
- `scenes/modular_v2/walls/SMV2_W012_SideApartmentDoor.tscn`

## Work completed immediately before this handoff

### W002 Apartment Door

W002 was rebuilt in Blender and promoted into the existing snap-enabled scene.
The door is human scale, uses a pneumatic header actuator, terminates the wall
service pipes at its jambs, and uses restrained cyan, magenta, and amber access
accents. Its footprint and `(192, -96)` front-wall socket were preserved.

Blender master and script:

- `blender/modular_v2/SMV2_W002_ApartmentDoor.blend`
- `blender/scripts/build_smv2_w002.py`

### W003 Window family

W003 closed and open-casement variants were built and promoted. The glass is
smoked and rain-streaked, with a blackout backing. It contains no city skyline
or city reflection. Closed and open versions have identical collision, root,
canvas, alpha envelope, and `(192, -96)` socket geometry.

Blender masters and script:

- `blender/modular_v2/SMV2_W003_Window.blend`
- `blender/modular_v2/SMV2_W003_WindowOpen.blend`
- `blender/scripts/build_smv2_w003.py`

Run the open build with Blender arguments ending in `-- --open`.

### W009 Seam Column correction

W009 had accidentally retained its ornate legacy texture. It now intentionally
uses the approved Blender narrow-trim master shared with W007 because both
scenes have the same full-story overlay role, transform, sockets, and alpha
envelope.

A second defect was found after inspecting W009 on a gray background: the old
rectangular alpha made empty cap corners opaque black. W007, W008, and W009 now
preserve the fitted Blender silhouette. Their black corner wedges are removed
without changing placement or height.

Review scene:

- `scenes/modular_v2/validation/SMV2_W009_SeamColumnFidelityTest.tscn`

The alpha-preservation option was added to:

- `tools/normalize_fidelity_candidate.py --preserve-candidate-alpha`

## Canonical snapping rules

Do not move or scale production scene roots. Roots remain position `(0, 0)`,
rotation `0`, and scale `(1, 1)`.

Front walls:

- Visual position: `(96, -128)`
- Visual scale: `0.2`
- Right socket: `(192, -96)`

Side walls:

- Visual position: `(96, -32)`
- Visual scale: `0.2`
- Right socket: `(192, 96)`

Standard full wall image:

- Canvas: `1280x1440`
- Front approved alpha bounds: `(160, 80, 1121, 1361)`
- Side approved alpha bounds: `(159, 80, 1120, 1361)`

Assets are individual Godot scenes, not baked assemblies. Designers drag the
wall, door, window, corner, cornice, and parapet scenes separately with
**Steamtek Snap: ON**.

## Blender render standard

Authoritative shared file:

- `blender/scripts/steamtek_render_standard.py`

Documentation:

- `docs/STEAMTEK_BLENDER_RENDER_STANDARD.md`
- `docs/STEAMTEK_MODULAR_V2_FIDELITY_STANDARD.md`

Locked surface settings:

- Blender 4.5 LTS
- Eevee Next
- `1280x1440` RGBA PNG
- Orthographic camera location `(-4.81, -6.08, 7.54)`
- Orthographic scale `3.529`
- AgX Medium High Contrast
- Standard-surface lights: key `900`, fill `150`, rim `500`

Do not tune the camera independently per asset. Use the shared render profiles
and approved role materials. W010 and other side-family assets are deterministic
horizontal mirrors of their approved front-family counterparts via:

- `tools/build_side_fidelity_candidates.py`

## Art direction

Target high-fidelity pre-rendered 3D-to-2D isometric assets, not pixel art or
32-bit-style graphics. The Ascent is a fidelity reference only, not a palette
reference.

Keep:

- Rain-dark blue-black steel and composite panels
- Crisp manufactured edges and layered construction
- Believable material-specific highlights
- Functional pneumatic and pressure-line detail
- Restrained copper hardware
- Vibrant cyan, electric blue, magenta, hot pink, violet, and amber focal color
- Wet reflected color tied to signs, windows, machinery, and practical lights
- Clear large/medium/small form hierarchy at gameplay scale

Avoid:

- Victorian ornament
- Decorative gears
- Fantasy machinery
- Saturation with no focal hierarchy or material logic
- Uniformly dark, gray, brown, or desaturated environments
- City silhouettes painted into windows
- Flat painted details that should be modeled

## Character scale standard

Current player visual used by the game and new QA scenes:

- `assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn`
- SpriteFrames: `assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_Walk_8dir_4f_256.tres`
- Visual scale inside the scene: `0.73`
- Root is the player ground-contact point; visual offset is `(0, -110)`

The old static scene below is legacy calibration art and should not be used in
new QA scenes:

- `scenes/characters/C001_SteamtekRunner.tscn`
- `assets/characters/production/C001_SteamtekRunner.png`

Character pipeline documentation:

- `docs/STEAMTEK_CHARACTER_PIPELINE.md`
- `docs/Steamtek_Character_Pipeline_Handoff_2026-07-14.md`

## Godot stability precaution

Godot produced Windows access-violation crashes when an additional GUI or
headless Godot process accessed the same `.godot` import cache while the main
editor was already open.

Rules going forward:

- Keep only one Godot editor process open per project.
- Do not launch headless Godot validation while the GUI editor is open.
- Use `tools/validate_modular_v2.py` for routine checks.
- Give the user the exact review-scene path and let them open it in the existing
  editor.
- If Godot crashes without a second process, close it before safely rebuilding
  the generated `.godot` cache.

## Archives created during this pass

- `docs/archives/pre_w002_blender_promotion_2026-07-13.zip`
- `docs/archives/pre_w003_blender_promotion_2026-07-13.zip`
- `docs/archives/pre_w009_blender_correction_2026-07-13.zip`
- `docs/archives/pre_column_alpha_correction_2026-07-13.zip`
- `docs/archives/pre_r001_blender_promotion_2026-07-14.zip`
- `docs/archives/pre_f001_blender_promotion_2026-07-14.zip`
- `docs/archives/handoff_before_modular_v2_update_2026-07-13.md`

## Required validation command

From the project root, run:

`python tools/validate_modular_v2.py`

The exact Python executable may differ on the home computer. Do not refresh
geometry-manifest hashes merely to silence a failure; only refresh them after
an explicitly approved geometry or alpha revision.

## Surface-system vision locked 2026-07-14

The user's district sketch now governs the next ground work. The surface is a
complete modular streetscape composed of a broad main street/intersection,
raised sidewalks, a narrower apartment service alley, building frontages, and
The Lantern at the upper destination corner.

The Lantern is a rain-soaked neo-industrial bar/tavern and Lantern Ward social
anchor. Its frontage needs warm amber entry light, restrained magenta/cyan
commercial accents, wet localized reflections, industrial utility detail, and
enough pedestrian space for NPCs and interactions.

Full design and build order:

- `docs/STEAMTEK_SURFACE_SYSTEM_VISION.md`

The latest user reference also locks the desired tile-construction quality:
modeled thickness, beveled edges, recessed joints, distinct curb geometry, and
controlled local wear. Use that structural quality with Steamtek materials.
Do not copy the generic yellow striping or bake a drain/manhole into the base
family. G006 passed this comparison and is approved as the neutral sidewalk base.

Palette clarification from the user: Steamtek should be vibrant, not totally
dark. Dark neo-industrial materials are the backdrop for cyan, electric blue,
magenta, pink, violet, and amber in signs, windows, technology, characters, and
rain reflections. "Controlled neon" means deliberate hierarchy, not muted
color. The complete reference sheet also supports five kit families: ground,
façades, street details, industrial props, and small details/decals.

This vivid rain-reflective treatment applies specifically to the surface. Most
of the game takes place in the massive underground city/silo. The underground
retains vibrant inhabited districts, but becomes progressively darker, grittier,
and less reliably lit with depth. Even the deepest areas retain neo-punk color
through selected machinery, signage, luminous fluids, graffiti, faction marks,
and character accents. Authoritative progression:

- `docs/STEAMTEK_WORLD_COLOR_PROGRESSION.md`

Do not solve the layout with a giant baked intersection texture. Build separate
road, sidewalk, alley, curb, transition, and environmental-overlay layers.
G005 remains the approved road reference and G006 is now the approved sidewalk
base. Next review the sidewalk wear/repair variants, then build the
darker service alley, curb/transition family, and a gameplay-scale district
blockout based on the user's sketch.

## Location-first surface rule locked 2026-07-15

Choose construction from the actual location before choosing an attractive
pattern. Record purpose, traffic/load, maintenance, rain and drainage, age and
repairs, adjacent buildings, and district function first. A plaza may justify
pavers; that does not make pavers appropriate for a service alley.

The apartment service alley is a long, narrow, neglected corridor between
building backs. Build it from visually seamless continuous center segments,
plus separate building-edge strips, entrance and alley-mouth transitions,
drainage, utility-cut/repair overlays, and prop zones. It must not read as a
polished plaza or as a repeating grid of four decorative floor squares.

The original paver-grid G007 and the overly polished continuous Review03 were
archived as rejected explorations. Review04 was approved and promoted as the
production G007 coarse continuous center base. Its corridor QA scene verifies a
two-tile-wide lengthwise run while reserving separate edge, entrance, drainage,
repair, and prop modules.

The first corridor QA exposed visible image-edge repetition even though each
G007 cell had no internal grid. Review05 replaces the non-periodic Blender noise
and per-tile point-light gradient with a packed two-axis periodic aggregate and
uniform neutral render light. Contextual colored alley lighting remains owned
by Godot scenes. Review the same corridor QA scene for uninterrupted pavement.

The 4x8 apartment-service-alley macro blockout was rejected as off-scope and
removed from active QA. The user owns level layout, direction, and prop
placement. Pipeline work now targets the clean construction scene at
`scenes/tools/Steamtek_Modular_BuildWorkspace.tscn`, the searchable Godot asset
dock, reliable socket/grid snapping, and manifest-driven family batch builds.
See `docs/STEAMTEK_MODULAR_BUILDER_WORKFLOW.md`.

## Ready-to-paste continuation prompt

> Continue Steamtek from `docs/handoff.md`. Start at
> `docs/STEAMTEK_SURFACE_SYSTEM_VISION.md` and the approved G006 sidewalk base.
> The rough wet-concrete G001-G004 street family is accepted for now but remains
> staging-only. Use the current animated Steamtek_C001 player, not the legacy
> static runner. Continue with separate street-tile roles, preserve the exact
> 256x128 diamond and 64x32 lattice, and do not create a storm-drain tile. Do not
> Build the service-alley fill next, then the curb/transition family and a
> gameplay-scale blockout representing the apartment-to-alley-to-main-street-to-
> Lantern layout. Do not use a giant baked intersection. Do not edit or wire
> anything into main.gd/main.tscn. Run only the Python validator
> while Godot is open and always provide the exact scene path for review.
