# STEAMTEK CHATGPT HANDOFF — JULY 19, 2026

## Apartment Art Direction, Gameplay Scale, Modular Props, and Couch Production

This is the current continuation handoff for the Steamtek live-3D opening apartment. It supersedes stale art ratios, camera values, asset counts, half-wall instructions, and placeholder-prop guidance in older handoffs where they conflict with the actual production scene or the decisions below.

The companion visible-chat transcript is:

- `res://docs/ChatGPT handoffs/2026-07-19_CHAT_TRANSCRIPT_APARTMENT_ART_AND_COUCH.md`

The older July 18 transcript remains at:

- `res://docs/7-18 after work.md`

## Immediate state

- Canonical repository: `C:\My Game\Steamtek-RPG`
- Current playable apartment: `res://scenes/levels/apartment_3d/SteamtekOpeningApartmentPlayable3D.tscn`
- Current production apartment assembly: `res://scenes/environment/live3d/interiors/apartments/SteamtekPlayerApartmentProductionAssembly3D_v02.tscn`
- Current modular system: `live3d_meter_v1`
- Current editor tool: `res://addons/steamtek_live3d_builder/`
- Current couch wrapper: `res://scenes/environment/live3d/props/apartment_interior/APT_Couch_2Seat_Rust.tscn`
- Current couch production revision: **F, pending user gameplay review**
- Current Godot validation: normal editor/F6 launched successfully; no scoped errors were logged.
- Known log warning: the pre-existing C001 GLB UID fallback warning. Godot resolves the correct text path and continues.
- No Git commit was created.

## Authority stack — do not merge these categories

### 1. Gameplay camera and on-screen character scale: The Ascent

The Ascent is the authority for the gameplay camera, character occupancy, and character-forward isometric framing. It is not the rendering-style authority.

The actual playable scene currently declares and uses:

- Orthographic camera.
- 45-degree azimuth.
- 35-degree elevation.
- Orthographic size: `9.14`.
- Camera position: `Vector3(14.142, 15.004, 14.142)`.
- C001 approved height: **6 ft 0 in (1.83 m)**.
- C001 scene metadata identifies the six-foot calibration and adjusted collision/targets.

Do not restore the older apartment values of 60-degree azimuth, 30-degree elevation, or orthographic size 12.5. Those values remain in older documentation but are superseded for this playable apartment by the actual scene and the user-approved Ascent calibration.

### 2. Rendering language: Shadowrun Returns

“Like Shadowrun Returns” means the art style, not Shadowrun's palette:

- Hand-painted, illustrative surfaces.
- Simplified geometry carrying authored painted detail.
- Broad, readable shapes at isometric gameplay distance.
- Controlled texture detail rather than photorealistic noise.
- Strong silhouettes and selective edge highlights.
- Slightly exaggerated concept-art depth.
- Lighting that feels painted into the scene while remaining linked to believable sources.

It does **not** mean copying Shadowrun Returns' brown or sepia coloring.

### 3. World-design mixture

The latest approved mixture is:

- **40% cyberpunk**
- **20% neo-industrial**
- **20% practical steampunk**
- **20% Arcane-inspired color treatment**

This supersedes the older 60/20/20 direction and the temporary 40% neo-industrial / 40% cyberpunk / 20% steampunk wording.

Arcane is a color and value-treatment influence only. Do not copy its characters, objects, architecture, or intellectual property.

### 4. Palette: Steamtek's own palette

- Dark blue-black and charcoal engineered steel.
- Localized rust, scratches, repaired wear, and warm edge highlights.
- Oxblood/rust leather, teal fabric, plum/navy textiles, and warm domestic materials where appropriate.
- Restrained copper/brass used as functional service hardware.
- Magenta, cyan, and pink may appear as cyberpunk source light or controlled signal accents.
- **Cyan must not be added to every asset.** Reserve cyan emission for actual light sources, screens, powered indicators, or believable signal hardware.
- Do not use arbitrary neon as decoration.

## Quality benchmarks

1. **Approved apartment walls are the primary quality benchmark.**
2. **Approved computer/workbench is the secondary quality benchmark.**
3. **The approved oxblood two-seat couch concept is the prop benchmark.**

The walls established the correct combination of painted material depth, broad readable shapes, technical panel structure, restrained wear, source-linked lighting, and the Steamtek palette. Props that look procedurally smooth, generically glossy, brightly saturated, flat, toy-like, or covered in arbitrary cyan do not belong in the room even if their geometry is technically complete.

## Non-negotiable modular contracts

- True 3D modular assets only.
- No flat cards, camera-facing billboards, or 2D workaround geometry for furniture.
- One Godot unit equals one meter.
- Preserve existing meter footprints unless a deliberate contract revision is approved.
- Root scale stays `(1, 1, 1)`.
- Floor-center contact pivot for furniture.
- Front axis must face the room/C001 consistently; the current couch wrapper declares `+Z_toward_room_and_c001`.
- Preserve collision, clearances, pivots, socket roles, and snap behavior.
- No negative-scale mirroring.
- Furniture uses the 0.3 m placement profile; structure uses 1.2 m; small props use 0.1 m.
- Continue using `res://addons/steamtek_live3d_builder/` and `res://scenes/environment/live3d/`.
- Do not return to `modular_v1` or the retired snapping workflow.
- Modular visual options are interchangeable alternatives, not mandatory literal multi-panel pictures.

## User workflow preferences

- Use both imperial and metric measurements. The user is in the United States and prefers feet/inches first or alongside meters.
- Validate one meaningful asset in the normal Godot editor before advancing to the next family.
- Never use headless Godot for visual approval.
- Do not capture desktop screenshots. Review generated renders directly and let the user inspect the normal Godot F6 window.
- When the user says pause or stop, do not continue production changes.
- Preserve unrelated dirty-worktree changes.

## Production work completed during this continuation

### Camera and C001

- Built an isolated gameplay-scale calibration scene.
- Compared the room and C001 against Shadowrun Returns and then The Ascent references.
- The Ascent became the fixed camera and character-scale authority.
- The user approved the 35-degree elevation, 45-degree azimuth, orthographic size 9.14, and final on-screen character size.
- C001 was calibrated to 6 ft 0 in (1.83 m) without replacing the character model.

### Apartment architecture and wall art

- Apartment walls were promoted to the primary art-quality benchmark.
- Built compatible solid, maintenance, vent/light, exposed-service, cyan utility-window, magenta source-light, and secure-door visual families.
- Established that apparent painted wall glow can be supported by real Godot lights outside the wall material.
- Removed the half wall from the production apartment because it cluttered the room and felt out of place.
- Added modular window-wall choices.
- Reworked the door wall to read clearly as a door.
- Moved the apartment exit to the top wall between the workstation and storage area.
- Corrected objects that obscured the door.

### Apartment prop library and Builder

- A true-3D modular apartment prop library was built and added to the current Live3D Builder.
- Library families include seating, sleep, storage, tables, kitchen/utility, decor, windows, and the service door.
- The half wall was removed from the active Builder catalog.
- Props remain independent and snappable.
- The first mass-produced prop pass was rejected at taste level: it was too smooth, flat, saturated, cyan-heavy, and disconnected from the approved wall language.
- The computer/workbench was the strongest exception and became the secondary benchmark.
- Future props must be rebuilt or repainted one at a time from the approved benchmark stack rather than accepting the initial Library D blockouts as finished art.

## Current couch production state

### Approved reference

- Project reference: `res://docs/references/APT_Couch_2Seat_Rust_E_Concept.png`
- The user requested this appearance as the in-game target: deep oxblood two-seat cushions, dark engineered steel side shell and plinth, restrained copper service details, strong readable silhouette, and no unnecessary cyan.

### Current production files

- Production GLB: `res://assets/environment/live3d/models/apartment_interior/library_d/APT_Couch_2Seat_Rust.glb`
- Godot wrapper: `res://scenes/environment/live3d/props/apartment_interior/APT_Couch_2Seat_Rust.tscn`
- Blender source: `res://blender/live3d/apartment_interior/APT_Couch_2Seat_Rust_F.blend`
- Rebuild script: `res://blender/live3d/apartment_interior/Steamtek_Rebuild_APT_Couch_2Seat_Rust_E.py`
- Baked Godot-safe upholstery albedo: `res://assets/environment/live3d/textures/apartment_interior/APT_Couch_Oxblood_Painted_F.png`
- Isolated review render: `res://docs/reviews/apartment_library_d/APT_Couch_2Seat_Rust_F.png`

### Why revision F exists

The earlier couch looked wrong in Godot because the custom Blender color-ramp grading did not survive the GLB export. Godot displayed the raw bright-red source texture. Revision F bakes the final oxblood color treatment into a PNG and connects that simple texture directly to the exported Principled material.

Revision F also:

- Removes cyan material from the couch entirely.
- Reduces bright rivets, caps, seam bars, and copper strips.
- Keeps two independent seat cushions and two independent back cushions.
- Preserves actual arm, side, base, front, and rear volume.
- Adds quiet side vent/service detail.
- Retains the 2.2 m × 1.05 m × 0.9 m footprint, approximately 7 ft 3 in × 3 ft 5 in × 2 ft 11 in.
- Retains collision and seating/furniture snap sockets.

### Apartment presentation cleanup

`LoungeRug` in `SteamtekPlayerApartmentProductionAssembly3D_v02.tscn` is currently set to `visible = false`. It was not deleted. Its black silhouette merged into the couch base and made the couch appear to sit on a large broken rectangle. Decide after couch approval whether to redesign, recolor, reposition, or permanently hold the rug.

### Validation status

- Blender batch rebuild completed.
- GLB export completed.
- Baked texture, Blender source, review PNG, and production GLB exist.
- Normal Godot 4.7 editor/F6 run was launched after replacement.
- Godot log showed no scoped parse/runtime errors.
- The only message was the existing C001 invalid-UID fallback warning.
- **The user has not yet given final taste approval to couch revision F in gameplay.** Do not mark it approved merely because it loads.

## Known stale or contradictory documentation

Treat this handoff and the actual scenes as authoritative when conflicts appear.

- `res://docs/7-18 after work.md` contains older 40/40/20 art direction, half-wall work, 60-degree/30-degree camera values, and orthographic size 12.5. Those are historical, not current.
- `res://docs/handoff.md` contains a production update using 60% cyberpunk / 20% neo-industrial / 20% functional steampunk. That ratio is superseded.
- `res://docs/APARTMENT_LIBRARY_D_HANDOFF.md` describes the initial 32-module Library D as production-complete. The geometry and modular setup exist, but the user rejected most of the prop art as not belonging in the game. Do not equate technical completion with visual approval.
- `SteamtekPlayerApartmentProductionAssembly3D_v02.tscn` still has stale `metadata/art_direction` text naming 60/20/20. The visible assets and this handoff use the newer 40/20/20/20 direction. Metadata cleanup can occur after the current couch review.
- The couch rebuild script still ends in `_E.py` even though it now produces the F source/review. Rename it only with an exact-path update to the wrapper metadata; do not perform a broad rename.

## Recommended next actions

1. Open or rerun `SteamtekOpeningApartmentPlayable3D.tscn` with normal Godot F6.
2. Judge the current couch from the locked gameplay camera beside C001 and the approved walls.
3. Confirm the oxblood surface remains dark and painted in Godot, the couch has real depth from multiple views, and no cyan appears on it.
4. If approved, change the couch wrapper status from `production_F_pending_user_gameplay_review` to an approved status.
5. Decide whether the lounge rug stays hidden, is rebuilt, or is recolored.
6. Clean the stale 60/20/20 assembly metadata and, optionally, rename the rebuild script from E to F with exact references.
7. Continue one prop at a time using the benchmark order: walls, computer/workbench, approved couch.
8. Suggested next prop after the couch: one chair variant from the same seating family. Validate it in gameplay before expanding to additional colors.
9. Then rebuild the bed, cabinets/storage, kitchen pieces, tables, trash cans, pillows, and smaller decor in measured batches.
10. Reserve cyan/magenta/pink for believable powered sources and let most objects live in Steamtek's non-emissive material palette.

## Do not do next

- Do not mass-approve the original prop library visually.
- Do not cover every object with cyan trim.
- Do not solve couch fidelity with a flat image plane.
- Do not change the approved camera or C001 scale to make a prop look better.
- Do not reintroduce the half wall.
- Do not bake clutter into room textures.
- Do not take screenshots of the user's desktop.
- Do not run destructive Git cleanup or broad text replacements.

## Dirty-worktree caution

The repository contains extensive existing modifications and untracked files from multiple workstreams. Preserve them. Make narrow edits only. Do not reset, delete, rename broadly, or assume that every modified file belongs to this apartment task. In particular, preserve Claude/combat work and user-created temporary scenes unless the user explicitly asks for cleanup.

## Definition of done for the next prop

A prop is not finished when a Blender file or GLB merely exists. It is finished only when:

- Its art belongs beside the approved walls.
- It matches the computer/couch benchmark where relevant.
- It reads clearly at the locked Ascent camera.
- It uses Shadowrun Returns' illustrative rendering language without copying its palette.
- Its Steamtek palette and world-design ratio are respected.
- Emissive color is source-linked and restrained.
- Its true-3D geometry, meter scale, pivot, collision, and sockets are preserved.
- It imports and runs through normal Godot F6 without scoped errors.
- The user approves it in gameplay.
