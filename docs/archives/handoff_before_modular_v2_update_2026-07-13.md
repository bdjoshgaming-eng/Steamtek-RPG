# Steamtek Project Handoff

**Updated:** July 12, 2026  
**Engine:** Godot 4.7  
**Project folder:** `C:\My Game\Steamtek-RPG`  
**Current production focus:** Strict Modular v1 apartment exterior

---

## 1. Current Direction

Steamtek is a 2D isometric action RPG / roguelite with a rain-soaked neo-industrial setting powered by steam pressure, pneumatics, and partially understood ancient technology.

The visual direction is neo-punk / neo-industrial rather than Victorian steampunk.

Primary materials:

- Rain-darkened concrete
- Gunmetal and black steel
- Black iron
- Copper pressure lines
- Restrained brass fittings
- Tempered pressure glass
- Rubber and reinforced technical fabrics
- Wet pavement

Accent colors:

- Cyan
- Magenta
- Amber industrial light
- Acid green used sparingly

Avoid decorative gears, top hats, fashionable goggles, ornate Victorian styling, fantasy magic, and machinery without an understandable function.

Core art rule:

> Everything should look like it could work.

---

## 2. Asset Library Status

The pre-Modular-v1 B-series building library has been retired and deleted.

Removed:

- B001-B012 building assets and scenes
- B100 apartment assemblies and tests
- Associated B-series source images, previews, and Godot import cache entries

Do not recreate or reference B-series building assets.

P-series props remain active and were intentionally preserved.

All new strict modular environment work uses the `SMV1_` prefix.

Primary locations:

```text
assets/modular_v1
scenes/modular_v1
docs/STEAMTEK_MODULAR_STANDARD_V1.md
```

---

## 3. Locked Modular Wall Contract

Standard wall family settings:

```text
Source canvas:       1280 x 1152 RGBA
Visual scale:        0.2, 0.2
Visual position:     96, -98.8
Displayed bounds:    192 x 197.8
Snap_Left:           0, 0
Snap_Right:          192, -38
Snap_Upper:          0, -198
Collision midpoint:  96, -19
Collision rotation: -0.195 radians
Collision size:      196 x 24
```

Reusable scene roots remain:

```text
Position: 0, 0
Rotation: 0
Scale:    1, 1
```

Never resize or mirror a reusable scene root to correct source art. Adjust only Visual children, and only according to the documented family contract.

---

## 4. Wall Modules W001-W008

Base facade family:

```text
SMV1_W001 Plain Wall
SMV1_W002 Apartment Door
SMV1_W003 Window
SMV1_W004 Feature Wall
```

W003 was updated to remove the baked city skyline. The active glass is dark blue-black with abstract wet reflections, droplets, and runoff trails.

Facade terminations:

```text
SMV1_W005 Left Facade End Cap
SMV1_W006 Right Facade End Cap
```

W005 and W006 now inherit W001's exact canvas, alpha silhouette, baseline, connection geometry, collision, and sockets. High-fidelity steel termination detail is composited only inside the appropriate outer edge.

Their obsolete full painted candidates and chroma sources were deleted. Small actively used spine source components remain for deterministic rebuilding.

Validation scenes:

```text
scenes/modular_v1/validation/SMV1_W005_LeftEndCapTest.tscn
scenes/modular_v1/validation/SMV1_W006_RightEndCapTest.tscn
```

Outside corner:

```text
SMV1_W007 Outside Corner
```

W007 is a deterministic two-plane Godot assembly rather than a single compressed corner image.

```text
Root:             outside-corner ground contact
Snap_Left:        -192, -38
Snap_Right:        192, -38
Snap_Upper:          0, -198
Left Visual:       -96, -98.8, flipped horizontally
Right Visual:       96, -98.8
Left collision:    -96, -19, rotation +0.195
Right collision:    96, -19, rotation -0.195
```

The production PNG is only the high-fidelity corner-spine overlay. Its source alpha bounds are `590-690, 356-1070`, producing a displayed spine approximately 20 units wide by 142.8 units tall.

Inside corner:

```text
SMV1_W008 Inside Corner
```

W008 uses the concave two-plane contract:

```text
Root:             recessed corner ground contact
Snap_Left:        -192, 38
Snap_Right:        192, 38
Snap_Upper:          0, -198
Left Visual:       -96, -60.8
Right Visual:       96, -60.8, flipped horizontally
Left collision:    -96, 19, rotation -0.195
Right collision:    96, 19, rotation +0.195
```

The W008 production PNG is also only a normalized spine overlay.

Validation scenes:

```text
scenes/modular_v1/validation/SMV1_W007_OutsideCornerTest.tscn
scenes/modular_v1/validation/SMV1_W008_InsideCornerTest.tscn
```

W008 passed its Godot concave-orientation, center-spine, root, and collision-continuity inspection on July 12, 2026. Its right-side continuation remains dependent on the future second side-wall family; do not use a front-facade end cap as that neighbor. W005-W007 retain their previously documented validation status.

Seam / structural column overlay:

```text
SMV1_W009 Seam Column
```

W009 is a visual-only structural overlay placed at facade connection sockets. The connected wall modules provide collision.

```text
Source canvas:       1280 x 1152 RGBA
Production alpha:    590-690, 273-1070
Displayed size:      approximately 20 x 159.4 units
Visual scale:        0.2, 0.2
Visual position:     0, -98.8
Attach_Base:         0, 0
Attach_Upper:        0, -198
Collision:           none
```

The 797-pixel vertical alpha envelope was calculated from the higher top edge of the preceding wall and the lower baseline of the following wall. Do not resize it to the wall family's overall diagonal alpha height.

Validation scene:

```text
scenes/modular_v1/validation/SMV1_W009_SeamColumnTest.tscn
```

W009 passed final Godot visual validation across a three-wall facade on July 12, 2026.

---

## 5. Roof and Parapet Status

Current roof assets:

```text
SMV1_R001 Roof Surface
SMV1_R002 Parapet Front
```

R002 received a new wet, textured material pass to replace its original flat placeholder graphics. Its original canvas and alpha mask were preserved.

R002 remains pending a final Godot-rendered snap test.

---

## 6. Character Art-Direction Test

Current test character:

```text
C001 Steamtek Runner
```

Files:

```text
assets/characters/production/C001_SteamtekRunner.png
assets/characters/source/C001_SteamtekRunner_chroma.png
scenes/characters/C001_SteamtekRunner.tscn
scenes/modular_v1/validation/SMV1_CharacterScaleTest.tscn
```

C001 is an original male neo-industrial test character with a pressure jacket, pneumatic gauntlet, belt-mounted gauge, reinforced trousers, and industrial boots.

Character scale contract:

```text
Source canvas:          1254 x 1254 RGBA
Measured alpha height: 1117 source pixels
Visual scale:           0.09, 0.09
Visual position:       -1.4, -50.5
Displayed height:       approximately 100.5 world units
Standard adult target:  96-104 world units
```

Adult characters are calibrated against the usable W002 door opening, not the complete 198-unit wall story.

The main Camera2D is explicitly set to zoom `(1,1)`. Standard adults should therefore appear approximately 96-104 screen pixels tall before operating-system display scaling.

The active player uses C001 in `scenes/main.tscn`. Movement is controlled by `scenes/player.gd`. C001 is currently a single-frame sprite, so it moves and flips horizontally but does not yet have a walk animation.

---

## 7. Main Scene and Sorting Rules

Main working hierarchy:

```text
Main
`-- World
    |-- Ground
    |-- Effects
    |-- Lighting
    `-- YSortLayer
        |-- Player
        |-- NPCs
        |-- Enemies
        |-- Props
        |-- Buildings
        |-- Interactables
        `-- Harvesters
```

Player, characters, props, and sortable building pieces must share the Y-sorted branch.

Collision remains concentrated at feet and ground footprints. Do not outline entire sprites with collision shapes.

---

## 8. Definition of Done

A modular asset is not approved until it passes all applicable checks:

- Correct Steamtek neo-industrial direction
- Fixed ID and filename
- Fixed canvas and deterministic alpha geometry
- Root transform remains `(0,0)`, rotation `0`, scale `(1,1)`
- Correct Visual scale and offset
- Correct sockets
- Appropriate ground-footprint collision
- No green fringe
- Comparable graphic fidelity to its approved family
- No flat placeholder shading
- No edge-crossing decorative detail
- Interchangeable with family neighbors
- Local rendered-scale preview passes
- Godot snap-test render passes
- Registered or discoverable by Steamtek Studio

Graphic fidelity never overrides geometry. A detailed image with incorrect dimensions is still rejected.

---

## 9. Steamtek Studio Note

Deleting the B-series files may leave old B-series database records visible as missing. Steamtek Studio intentionally does not delete records automatically.

Use **Find Missing** to review and manually delete retired B-series records if desired. Do not delete P-series prop records.

---

## 10. Immediate Next Work

W008 through W013 have completed their current Godot validation passes.

`SMV1_W010_SidePlainWall` is the approved plain master for the second visible isometric wall direction. It is a deterministic horizontal counterpart to the front-facing plain wall and continues cleanly from the right socket of W008.

W010 contract:

```text
Root:       position (0,0), rotation 0, scale (1,1)
Visual:     position (96,-60.8), scale (0.2,0.2)
Snap_Left:  (0,0)
Snap_Right: (192,38)
Snap_Upper: (0,-198)
Collision:  position (96,19), rotation +0.195, size 196x24
```

`SMV1_W011_SideWindowWall` is the approved window variant for the second visible wall direction. It preserves W010's complete transform, socket, and collision contract.

Important seam rule: adjacent sloped wall modules require `SMV1_W009_SeamColumn` at the shared socket. The column is part of the approved modular assembly language and covers the full overlap envelope of both panels. For a run at roots `(0,0)`, `(192,38)`, and `(384,76)`, place seam columns at `(192,38)` and `(384,76)`.

`SMV1_W012_SideApartmentDoor` is the approved door variant for the second visible wall direction. It preserves the W010 contract. Its current collision intentionally blocks the complete module while the door is nonfunctional; replace it with doorway/interactable collision when functional doors are implemented.

`SMV1_W013_SideFeatureWall` is the approved feature variant for the second visible wall direction. W010-W013 now form the complete first-pass side-wall family.

The complete W001-W013 wall system has passed its current Godot validation cycle. This includes the mixed W008 inside-corner run and the corrected W007 outside-corner run. Outside-corner direction rule: the W010-W013 side family approaches W007 from its left socket, while the W001-W004 front family continues from its right socket.

The next production family is roofs and parapets. R001 RoofSurface and R002 ParapetFront already exist. R003 ParapetSide is the approved deterministic second-direction counterpart to R002 and passed a three-module uninterrupted-run test.

`SMV1_R004_ParapetOutsideCorner`, `SMV1_R005_ParapetInsideCorner`, and `SMV1_R006_ParapetEndCap` are approved. R004 is a two-leg composite using R003 on the side approach, R002 on the front continuation, and a parapet-height structural cap derived from W007. Its first cap was rejected for being full-column height; the corrected cap is exactly parapet height and closes the V without moving either leg or snap marker. R005 reverses the leg arrangement for the concave `∧` corner and uses a parapet-height cap derived from W008. R006 terminates exposed parapet sockets and passed a front-run test with caps at both ends.

R001 originally passed an isolated 3x3 test using a 256x128 2:1 diamond, but the complete integration test exposed that its `(128,64)` vectors were incompatible with the approved wall/parapet `(192,38)` projection. That original is archived under `modular_v1/legacy/roofs` and must not be used in SMV1 building assemblies. Canonical R001 was corrected to a displayed 384x76 diamond with sockets `NW(-192,-38)`, `NE(192,-38)`, `SW(-192,38)`, and `SE(192,38)`. It passed a closed R001-R006 roof assembly without child transform overrides.

Recommended sequence:

1. R001 roof-surface tiling passed a strict 3x3 socket test with no gaps, overlaps, or broken exterior edges.
2. Complete R001-R006 roof integration passed using the corrected canonical facade-projection R001.
3. Validate R001 roof-surface tiling under both parapet directions.
4. Validate both outside- and inside-corner continuations with the full side family.
5. Create remaining parapet orientations and roof corners.
6. Rebuild the apartment shell entirely from SMV1 modules.
7. Render the full apartment validation assembly.
8. Normalize fire-escape components if finer modularity is required.
9. Continue with stairs, landings, ladders, and pipe connector families.

Do not polish interactions or interior transitions until the exterior shell snaps correctly.

---

## 11. Resume Instruction

Use the following instruction to resume work:

> Continue Steamtek from `docs/handoff.md` and `docs/STEAMTEK_MODULAR_STANDARD_V1.md`. Work only in the versioned SMV1 building library; the pre-Modular-v1 B-series has been retired and deleted, while P-series props remain active. The complete W001-W013 wall system has passed its current Godot validation cycle. Canonical R001 now uses the locked facade projection and passed the complete closed R001-R006 roof integration test. R003 ParapetSide, R004 ParapetOutsideCorner, R005 ParapetInsideCorner, and R006 ParapetEndCap are approved. Continue with the apartment roof-and-wall shell assembly. Preserve deterministic geometry, family-level graphic fidelity, ground-contact origins, and rendered snap-test requirements.
