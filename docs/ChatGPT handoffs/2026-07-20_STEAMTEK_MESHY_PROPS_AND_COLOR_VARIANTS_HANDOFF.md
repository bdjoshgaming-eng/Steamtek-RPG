# STEAMTEK HANDOFF — MESHY PROPS, COLOR VARIANTS, BED, AND BOOKSHELVES

**Date:** July 20, 2026  
**Project:** Steamtek RPG  
**Repository:** `C:\My Game\Steamtek-RPG`

This handoff captures the continuation state from the July 19 apartment handoffs through the current bed and bookshelf production work.

It is intended to let a new GPT Work / ChatGPT session continue without reinterpreting the user’s intent.

---

# 1. AUTHORITATIVE PROJECT DIRECTION

## Canonical Steamtek style

Use this exact style split:

- **40% cyberpunk**
- **20% neo-industrial**
- **20% modern steampunk**
- **20% Arcane-inspired painterly finish**

Rules:

- Functional
- Gritty
- Hand-painted
- Stylized
- Game-ready
- Matte to satin rather than glossy
- Copper/brass as supporting accents
- Neon tied to believable powered sources
- Avoid Victorian ornamentation
- Avoid decorative gears
- Avoid excessive pipes and valve wheels
- Avoid random neon trim
- Avoid photorealistic or wet-looking materials

Canonical style file:

`res://docs/STEAMPUNK_STYLE_MEMORY.md`

---

# 2. IMPORTANT COUCH-VARIANT CLARIFICATION

Three couches were temporarily placed in the apartment only to prove that one Meshy-imported model could support multiple color variants.

They were **not** placed to:

- propose a three-couch layout,
- decide how many couches the apartment needs,
- or review final furniture composition.

The proof-of-concept established that one GLB can reuse:

- geometry,
- UVs,
- textures,
- collision,
- sockets,
- wear,
- metallic/roughness data,

while selectively recoloring only intended regions such as upholstery.

This is the basis for the Steamtek Material Variant Editor.

---

# 3. MATERIAL VARIANT EDITOR GOAL

The user wants a Godot editor tool that allows recoloring assets without Blender, Photoshop, or other graphics tools.

Expected workflow:

1. Select a compatible asset.
2. Choose a valid recolorable region.
3. Pick a color or Steamtek palette preset.
4. Adjust simple controls:
   - tint strength,
   - brightness,
   - roughness,
   - emission color,
   - emission strength.
5. Preview immediately in Godot.
6. Save as:
   - reusable `.tres` material,
   - optional modular `.tscn` scene variant.

The tool must:

- never duplicate production geometry unnecessarily,
- avoid whole-object tinting,
- preserve scratches, grime, wear, roughness, metallic response, and baked shading,
- use region masks or separate material slots,
- create predictable names,
- integrate narrowly with the Builder.

### Safety rule learned

GPT Work temporarily broke the Godot editor layout while building the color tool.

Going forward:

- Do not modify editor layouts.
- Do not alter FileSystem, Inspector, Output, or Debugger dock positions.
- Keep Material Variant Editor changes inside its own addon folder.
- Modify only exact established integration points.
- Avoid broad plugin rewrites or broad search-and-replace operations.

---

# 4. GODOT / MESHY PIPELINE RULES

Default static-prop workflow:

1. Generate five consistent orthographic reference views.
2. Generate or optimize in Meshy.
3. Export GLB.
4. Keep raw source in `incoming`.
5. Process in Blender / GPT Work.
6. Validate dimensions, pivot, orientation, topology, materials, masks, collision, and sockets.
7. Export separate production GLB.
8. Create Godot wrapper.
9. Validate in normal Godot editor.
10. Approve from gameplay camera before replacing existing production assets.

Export settings from Meshy:

- **Format:** GLB
- **Resize:** Off
- **Origin:** Bottom

Do not send raw high-density Meshy GLBs directly into Godot.

---

# 5. GENERAL TOPOLOGY TARGETS

## Small props

- Preferred: 2,000–8,000 triangles
- Hard max: 12,000

## Chairs, crates, cabinets

- Preferred: 6,000–15,000
- Hard max: 25,000

## Beds, couches, workstations

- Preferred: 15,000–25,000
- Hard max: 35,000–40,000 only if silhouette requires it

## Large complex machinery

- Preferred: 20,000–40,000
- Hard max: 60,000

## Main characters

- Preferred: 12,000–20,000
- Case-by-case beyond that

Always tell Meshy:

> Do not generate a high-density sculpt or 3D-print mesh. This asset is intended for real-time use in Godot.

Use textures / normal maps for:

- scratches,
- paint chips,
- fine seams,
- fabric weave,
- tiny bolts,
- grime,
- minor dents,
- micro-detail.

---

# 6. BED ASSET

## Asset identity

`STK_PROP_Bed_A`

Type:

Static environment prop / apartment furniture

Intake folder:

`C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Bed`

Expected raw source:

`STK_PROP_Bed_A_Meshy.glb`

Production outputs:

- `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Bed_A_Production.glb`
- `res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bed_A.tscn`
- `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Bed\STK_PROP_Bed_A_QA.md`

---

## Bed dimensions

- Width: **1.20 m**
- Length: **2.10 m**
- Overall height: **1.05 m**
- Mattress top height: approximately **0.52 m**

Designed for a 1.83 m / 6 ft character.

Orientation:

- Y up
- Front +Z
- Bottom-center pivot
- Ground contact at Y = 0
- Root scale 1,1,1

---

## Bed recolorable regions

### `Bedding_Main`

Main blanket only.

### `Bedding_Secondary`

Sheets and pillow.

### `Frame_PaintedMetal`

Painted frame/headboard regions.

### `Accent_Powered`

Small powered accent.

Locked:

- structural metal,
- copper,
- rust,
- grime,
- scratches,
- edge wear,
- baked shading.

Preferred materials:

- `MAT_Bed_Blanket`
- `MAT_Bed_SheetPillow`
- `MAT_Bed_FramePaint`
- `MAT_Bed_StructuralMetal`
- `MAT_Bed_Copper`
- `MAT_Bed_Emission`

Fallback masks:

- `MASK_Bed_BeddingMain`
- `MASK_Bed_BeddingSecondary`
- `MASK_Bed_FramePaint`
- `MASK_Bed_Emission`

---

## Bed topology history

Initial Meshy result:

- approximately 907,006 faces
- approximately 480,706 vertices

Rejected as far too dense.

First optimization:

- 24,089 faces

Final accepted optimization:

- **19,131 faces**
- **21,976 vertices**

The 19,131-face result preserved:

- blanket folds,
- pillow,
- sheets,
- mattress,
- headboard,
- footboard,
- under-bed storage,
- copper trim,
- cyan accent.

Do not reduce further unless QA requires it.

---

## Bed material direction

The user explicitly prefers a matte appearance.

Suggested roughness:

- Blanket: 0.75–0.90
- Sheets/pillow: 0.70–0.88
- Painted frame: 0.58–0.75
- Structural metal: 0.48–0.68
- Copper: 0.38–0.58
- Powered accent housing: 0.45–0.65

Avoid:

- glossy bedding,
- plastic-looking fabrics,
- wet-looking painted metal,
- mirror-like reflections,
- polished copper.

---

## Bed Material Variant Editor metadata

```text
recolor_enabled = true
recolor_profile = "steamtek_bed_v1"
recolor_regions = [
    "Bedding_Main",
    "Bedding_Secondary",
    "Frame_PaintedMetal",
    "Accent_Powered"
]
```

Test variants are proof-of-concept only:

- Oxblood / gray / blue-black
- Deep teal / muted gray / charcoal
- Electric plum / dark gray / navy
- Burnished ochre / brown-gray / dark frame

Do not place multiple beds in the apartment as a layout proposal.

---

# 7. BOOKSHELF / BOOKCASE FAMILY STRATEGY

The user prefers creating approximately **8–10 reusable dressed bookshelves and bookcases** to use throughout the game.

The user does **not** want to manually place books and knick-knacks on each shelf.

Therefore:

- bookshelf contents may be integrated into the static model,
- each reusable variant should have different shelf contents and/or silhouette,
- variants should be production props rather than empty shells,
- repetition should be solved through a family of 8–10 assets.

The first asset is:

`STK_PROP_Bookshelf_A`

---

# 8. BOOKSHELF A DESIGN

Type:

Static environment prop / dressed bookshelf / apartment furniture

Dimensions:

- Width: **1.20 m**
- Depth: **0.38 m**
- Height: **2.00 m**

Design requirements:

- One single tall bookshelf
- Strong rectangular silhouette
- Solid left side panel
- Solid right side panel
- Full closed back panel
- Open upper shelving
- Lower two-door cabinet
- Built-in books
- Built-in storage boxes
- Built-in industrial knick-knacks
- Small restrained cyan powered accent
- Dark blue-black painted metal
- Charcoal structural metal
- Restrained copper/brass hardware
- Matte hand-painted wear

---

# 9. BOOKSHELF CONTENTS

Recommended integrated contents:

- grouped upright books,
- stacked books,
- 1–2 storage boxes,
- 1–2 industrial decorative objects,
- one framed diagram or mechanical print,
- one small powered object or contained device,
- controlled negative space.

Avoid:

- overcrowding,
- excessive plants,
- tiny noisy clutter,
- loose floor clutter,
- random bright colors,
- props extending beyond the silhouette.

Books and knick-knacks should generally remain locked from recoloring.

---

# 10. FIVE-VIEW BOOKSHELF REQUIREMENTS

The five images must depict the same exact bookshelf:

- Front
- Back
- Left
- Right
- Top

Requirements:

- same proportions,
- same cabinet height,
- same shelf count,
- same silhouette,
- same colors,
- same cyan accent location,
- same construction details,
- neutral gray background,
- even lighting,
- no labels,
- no cast shadows,
- no floor plane,
- tight framing without cropping.

Non-negotiable consistency:

- left side must be solid,
- right side must be solid,
- books must not be visible through side panels,
- back must be closed,
- no handles on the back,
- no handles on side panels,
- top footprint must be rectangular,
- cyan light must not protrude incorrectly in top view,
- one single bookshelf only.

---

# 11. BOOKSHELF IMAGE FAILURES TO AVOID

Several generated sets were rejected because they showed:

- multiple different bookcases,
- wide and narrow variants mixed together,
- transparent side construction,
- books visible from side views,
- handles on the back,
- handles on side panels,
- an incorrect top view,
- a cyan light protruding from the top view,
- inconsistent proportions between views.

Do not repeat these errors.

---

# 12. LATEST BOOKSHELF A PRE-3D APPROVAL

The latest pre-3D front image was considered strong.

Working elements:

- clean silhouette,
- curated built-in books and objects,
- lower cabinet,
- dark matte metal,
- worn copper,
- restrained cyan accent,
- readable negative space,
- strong game-art presentation.

Before final Meshy generation, verify:

- both side panels are solid,
- back is fully closed,
- no side/back handles,
- top is rectangular,
- cyan accent stays consistent,
- colors remain consistent,
- all five views match the same asset.

---

# 13. BOOKSHELF A TOPOLOGY TARGET

Preferred:

- **12,000–18,000 triangles**

Acceptable:

- **10,000–20,000**

Hard maximum:

- **22,000**

Geometry priority:

1. Outer silhouette
2. Solid side panels
3. Back panel
4. Shelves
5. Lower cabinet
6. Major book groups
7. Storage boxes
8. Large knick-knacks
9. Accent housing
10. Major copper brackets

Texture-only:

- scratches,
- tiny bolts,
- fine seams,
- paint chips,
- grime,
- minor dents,
- fine book lettering,
- micro-detail.

---

# 14. BOOKSHELF A RECOLOR REGIONS

### `Frame_PaintedMetal`

- Outer frame
- Main body
- Lower cabinet doors

### `Shelf_PaintedMetal`

- Interior shelf surfaces
- Internal painted shelf structures

### `Accent_Powered`

- Cyan powered accent only

Locked:

- Structural metal
- Copper
- Books
- Paper
- Storage boxes
- Knick-knacks
- Rust
- Grime
- Scratches
- Edge wear
- Painted shading

Preferred materials:

- `MAT_Bookshelf_FramePaint`
- `MAT_Bookshelf_ShelfPaint`
- `MAT_Bookshelf_StructuralMetal`
- `MAT_Bookshelf_Copper`
- `MAT_Bookshelf_Contents`
- `MAT_Bookshelf_Emission`

Fallback masks:

- `MASK_Bookshelf_FramePaint`
- `MASK_Bookshelf_ShelfPaint`
- `MASK_Bookshelf_Emission`

---

# 15. BOOKSHELF MATERIAL FINISH

Suggested roughness:

- Painted frame: 0.58–0.75
- Shelf surfaces: 0.62–0.78
- Structural metal: 0.48–0.68
- Copper: 0.38–0.58
- Books/paper: 0.72–0.90
- Storage boxes/knick-knacks: 0.60–0.82

Avoid:

- glossy books,
- polished copper,
- wet-looking paint,
- mirror-like reflections.

---

# 16. BOOKSHELF PRODUCTION PATHS

Intake:

`C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Bookshelf_A`

Expected source:

`STK_PROP_Bookshelf_A_Meshy.glb`

Production GLB:

`res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Bookshelf_A_Production.glb`

Godot wrapper:

`res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Bookshelf_A.tscn`

QA report:

`C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Bookshelf_A\STK_PROP_Bookshelf_A_QA.md`

---

# 17. BOOKSHELF MATERIAL VARIANT EDITOR METADATA

```text
recolor_enabled = true
recolor_profile = "steamtek_bookshelf_v1"
recolor_regions = [
    "Frame_PaintedMetal",
    "Shelf_PaintedMetal",
    "Accent_Powered"
]
```

The tool must not modify:

- books,
- knick-knacks,
- copper,
- structural metal,
- rust,
- grime,
- scratches,
- collision,
- sockets,
- pivot,
- scale.

Test variants:

- Deep teal / charcoal / cyan
- Oxblood / dark gray / magenta
- Electric plum / navy / cyan
- Burnished ochre / brown-gray / warm green

These are tests only.

Do not place multiple bookshelves in the apartment as a layout proposal.

Do not duplicate the production GLB.

---

# 18. BOOKSHELF COLLISION AND SOCKETS

Collision:

- one tall box for the main body,
- optional lower cabinet box,
- optional thin front shelf-volume box only if interaction requires it.

Do not create collision for:

- books,
- knick-knacks,
- small trim,
- brackets,
- cyan accent.

Sockets:

- `live3d_meter_v1`
- furniture placement profile 0.3 m
- two furniture-chain sockets
- one front-alignment socket
- optional rear/wall alignment socket if compatible with Builder rules

---

# 19. GPT WORK SAFETY RULES

For all future prop processing:

- Make narrow edits only.
- Preserve unrelated dirty-worktree changes.
- Do not reset Git.
- Do not perform broad text replacement.
- Do not modify editor layouts.
- Do not alter FileSystem, Inspector, Output, or Debugger docks.
- Do not edit unrelated plugins.
- Keep Material Variant Editor work inside its own addon folder.
- Stop and report before broad changes.
- Validate in normal Godot.
- Do not use headless Godot for visual approval.
- Do not replace production assets before gameplay approval.

---

# 20. CURRENT EXACT CONTINUATION POINT

Current state:

- Bed source accepted at 19,131 faces.
- Bed GPT Work processing prompt defined.
- Matte material preference locked.
- Bookshelf A strategy defined.
- Latest Bookshelf A pre-3D front image approved enough to continue.
- Five-view bookshelf requirements are fully clarified.
- Main remaining task is to finalize one exact matching set of:
  - Front
  - Back
  - Left
  - Right
  - Top

Then:

1. Verify all five views match.
2. Feed them into Meshy.
3. Target 12k–18k triangles.
4. Use Meshy optimization first if over budget.
5. Export GLB with Resize Off and Origin Bottom.
6. Put raw GLB in `APT_Bookshelf_A`.
7. Run GPT Work cleanup/import prompt.
8. Validate in normal Godot.
9. Approve in gameplay.
10. Begin Bookshelf B only after Bookshelf A is validated.

---

# 21. CONVERSATION TIMELINE SUMMARY

1. July 19 apartment handoffs were read.
2. User clarified couch variants were only a recoloring test.
3. Material Variant Editor concept was defined.
4. GPT Work briefly disrupted Godot editor layout; issue was fixed.
5. Recolorable bed specification created.
6. Five bed images generated.
7. Meshy prompt refined for separate blanket, sheet/pillow, frame, copper, and emission regions.
8. First bed result was over 900k faces.
9. Meshy optimization reduced it to 24k.
10. Further optimization reduced it to 19,131 faces.
11. Matte appearance was added to the GPT Work prompt.
12. User requested reusable dressed bookshelves.
13. Strategy changed to 8–10 reusable bookcases throughout the game.
14. Multiple bookshelf view sets were rejected for inconsistency.
15. Requirements were corrected:
    - one bookshelf,
    - five matching views,
    - solid sides,
    - closed back,
    - no side/back handles,
    - rectangular top,
    - consistent cyan accent.
16. Latest pre-3D front bookshelf result was accepted enough to proceed.
17. This handoff was requested.

---

# 22. DO NOT DEVIATE

- Do not interpret color-variant test scenes as final layouts.
- Do not use whole-object tinting.
- Do not generate multiple different assets when five views of one asset are requested.
- Do not allow open side panels on the bookshelf.
- Do not show books through side panels.
- Do not add handles to the back or sides.
- Do not let the top view contradict the side-light geometry.
- Do not exceed topology targets without a clear reason.
- Do not use glossy or wet-looking materials.
- Do not replace production assets before gameplay approval.
