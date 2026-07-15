# Steamtek Universal Modular Standard v1

## Locked project units

- Projection: true 2:1 isometric for ground and roof planes.
- Main ground footprint in Godot: 256 x 128.
- Art source-to-Godot ratio: 5:1.
- Environment Visual scale: (0.2, 0.2), except the two-module fire escape source which uses its documented scene scale.
- One approved wall story socket in Godot: 198 units.
- Standard wall module displayed width: 192 units.
- Standard wall source canvas: 1280 x 1152 RGBA.
- Scene root transform: position (0,0), rotation 0, scale (1,1).

## Asset status

- The pre-Modular-v1 B001-B012 and B100 building library has been retired and removed. Do not recreate or reference B-series building assets.
- P-series props remain active and are not part of the retired B-series cleanup.
- New strict modules use the `SMV1_` prefix.
- Only assets that pass a family snap test are approved for apartment construction.

## Wall contract

- Middle modules show only the facade plane: no baked side depth.
- Outer silhouette, baseline, top course, left seam and right seam are identical across variants.
- Pipes, lights, doors and windows stay inside both connection edges.
- Door, window and feature variants are derived from the same master shell.
- All variants retain the same canvas, alpha silhouette and output dimensions.

```text
SMV1_W00X_Name (Node2D)
|-- Visual (Sprite2D)
|-- Body (StaticBody2D)
|   `-- BodyCollision (CollisionShape2D)
|-- Snap_Left (Marker2D)
|-- Snap_Right (Marker2D)
`-- Snap_Upper (Marker2D)
```

- Visual scale: (0.2,0.2).
- Snap_Left: (0,0).
- Snap_Right: (192,-38).
- Snap_Upper: (0,-198).

### Facade ends and corners

- `SMV1_W005` and `SMV1_W006` retain the standard facade root, collision, and sockets while adding a finished outer steel termination.
- End-cap production masters inherit the exact W001 alpha mask and masonry geometry. Termination detail is composited only inside the outer edge; the neighbor connection edge remains identical to W001.
- `SMV1_W007` is a deterministic two-plane assembly. Its corner ground contact is the root; `Snap_Left` is `(-192,-38)`, `Snap_Right` is `(192,-38)`, and `Snap_Upper` is `(0,-198)`.
- W007 uses two W001 plane visuals at scale `(0.2,0.2)` centered at `(-96,-98.8)` and `(96,-98.8)`. Only the left Visual uses `flip_h`; scene roots are never mirrored or scaled.
- W007 collision uses two `196 x 24` rectangles centered at `(-96,-19)` and `(96,-19)`, rotated `+0.195` and `-0.195` radians.
- W007's production PNG is the corner-spine overlay on the standard 1280 x 1152 wall canvas. Its alpha occupies source x `590-690` and y `356-1070`, matching the projected corner edge: 20 units wide by 142.8 units tall at scale 0.2. The scene supplies the deterministic wall planes.
- `SMV1_W008` is the concave counterpart. Its recessed corner ground contact is the root; `Snap_Left` is `(-192,38)`, `Snap_Right` is `(192,38)`, and `Snap_Upper` remains `(0,-198)`.
- W008 uses W001 normally on the left and visually flipped on the right, centered at `(-96,-60.8)` and `(96,-60.8)`. This makes both runs extend outward and 38 units toward the viewer.
- W008 collision uses two `196 x 24` rectangles centered at `(-96,19)` and `(96,19)`, rotated `-0.195` and `+0.195` radians.
- W008's production PNG follows the same 1280 x 1152 spine-overlay canvas and `590-690`, `356-1070` projected-edge bounds as W007.

## Ground and roof contract

- Exact displayed diamond: 256 x 128.
- Source diamond: 1280 x 640 on a fixed transparent canvas.
- Root is the bottom diamond point.
- Visual position: (0,-64); scale: (0.2,0.2).
- Grid sockets: NE (128,-64), NW (-128,-64), SE (128,64), SW (-128,64).

## Foundation contract

- Foundation top face uses the exact ground diamond alpha geometry.
- Displayed side depth: 24.
- Root is the lowest front point; `TopCenter` is (0,-24).
- Foundation neighbors retain the same 256 x 128 grid spacing.

## Roof parapet contract

- One parapet spans one wall module.
- Snap_Left: (0,0); Snap_Right: (192,-38).
- Parapets chain with the same facade socket as wall modules.

## Character scale contract

- Character scale is calibrated against the usable opening in `SMV1_W002_ApartmentDoor`, not the full 198-unit wall story.
- Standard adult visual target: approximately 96-104 world units from boot contact to top of head/hair.
- C001 source canvas: 1254 x 1254 RGBA; measured visible alpha height: 1117 source pixels.
- C001 Visual scale: `(0.09,0.09)`, producing approximately 100.5 world units of visible height.
- C001 Visual position: `(-1.4,-50.5)` so the boot contact point aligns with the scene root.
- Player root remains at `(0,0)`, rotation `0`, scale `(1,1)`; never resize the `CharacterBody2D` root to correct art scale.
- Player collision remains a compact feet-level footprint. It does not outline the full character image.
- New adult character sources may use different canvas sizes, but their installed scenes must normalize to the 96-104 world-unit target and share a ground-contact root.
- Exceptional body sizes must be intentional gameplay categories, documented relative to the standard adult target, and checked beside W002 in a validation scene.

### On-screen character composition

- The approved C001 gameplay presentation is the screen-size reference for standard adult characters.
- With the main `Camera2D` at zoom `(1,1)`, the standard adult target is approximately 96-104 screen pixels from boot contact to head/hair before operating-system display scaling.
- Default gameplay camera zoom is explicitly `(1,1)`. Do not resize characters to compensate for a changed camera zoom.
- Camera zoom changes are presentation changes and must be validated separately against the approved C001/W002 composition.
- Resolution changes use `canvas_items` stretch with `expand`; world objects retain their relative size while the visible world area may expand.
- Every new playable character and human-sized NPC must be reviewed in the character scale test beside W002 and in the main gameplay camera before approval.
- Keep the feet and nearby floor readable. The character must not visually fill the door opening or dominate a one-module facade.

## Universal template families

```text
modular_v1
|-- walls
|-- ground
|-- foundations
|-- roofs
|-- fire_escape
|-- stairs
|-- ladders
|-- pipes
|-- props
`-- validation
```

Character assets use parallel versioned folders:

```text
assets/characters
|-- source
`-- production

scenes/characters
```

Every family receives fixed geometry, an anchor set and a validation scene before variants are produced.

## Definition of done

- Fixed dimensions and alpha canvas.
- Graphic fidelity matches the approved family at both 100% source view and final in-game scale: comparable texture frequency, material relief, edge definition, value range, and restrained accent detail.
- No flat placeholder shading, broad untextured faces, visibly synthetic repetition, or loss of detail after downscaling.
- Correct source-to-Godot scale.
- Approved root and socket locations.
- No edge-crossing decoration.
- No green fringe.
- Identical modules snap without a visible geometric gap.
- Variants interchange without moving neighbors.
- Scene tested at root scale (1,1).

### Fidelity validation

- Review every new family member beside approved members on the same neutral background, never in isolation.
- Inspect at the locked final display scale as well as source resolution.
- Graphic fidelity does not waive deterministic geometry: alpha bounds must be measured and compared before a candidate enters a snap test.
- The pre-fidelity-fix backup of `SMV1_R002_ParapetFront` is the negative reference for flat placeholder shading. The active production PNG has received a wet, textured material pass but still requires a rendered snap-test approval.
- W005 and W006 now match the W001 canvas, alpha silhouette, baseline, collision, and inward connection regions exactly. Both have passed local rendered-scale adjacency previews and remain pending final Godot-rendered approval.
- W007 has been converted to the deterministic two-plane assembly contract and has passed a local rendered-scale assembly preview. It remains pending final Godot-rendered collision/socket approval.
- W008 has been converted to the deterministic concave two-plane assembly contract and has passed a local rendered-scale assembly preview. It remains pending final Godot-rendered collision/socket approval.
