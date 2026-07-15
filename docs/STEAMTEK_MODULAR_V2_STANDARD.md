# Steamtek Modular v2 Standard

`modular_v2` is the corrected, snap-driven environment library. `modular_v1` is reference-only and must not be mixed into v2 assemblies.

## Canonical geometry

- Projection: true 2:1 isometric.
- Base sub-grid: `64 x 32` Godot units.
- Wall bay: three sub-grid steps, `192 x 96` Godot units.
- Story height: `160` Godot units.
- Scene root: `Node2D`, position `(0, 0)`, scale `(1, 1)`, rotation `0`.
- Production wall canvas: `1280 x 1440` transparent PNG.
- Wall visual scale: `(0.2, 0.2)` only inside the reusable module scene.
- Instances placed in maps always remain scale `(1, 1)`.

## Wall coordinates

Front-running walls use these visible corners relative to the scene root:

```text
Upper-left  (0, -160)       Upper-right (192, -256)
Lower-left  (0,    0)       Lower-right (192,  -96)
```

Side-running walls use:

```text
Upper-left  (0, -160)       Upper-right (192, -64)
Lower-left  (0,    0)       Lower-right (192,  96)
```

Therefore adjacent bays are translated by exactly:

- Front run: `(192, -96)`
- Side run: `(192, 96)`
- Story above: `(0, -160)`
- Story below: `(0, 160)`

## Snap contract

Every reusable module root belongs to group `steamtek_modular`.
Every snap marker is a `Marker2D` in group `steamtek_snap`.

Compatible marker names:

```text
Snap_Left  <-> Snap_Right
Snap_Base  <-> Snap_Left or Snap_Right
Snap_Upper <-> Snap_Lower
Snap_RoofEdge <-> Snap_Left
Snap_Parapet <-> Snap_Left
Snap_NE    <-> Snap_SW
Snap_NW    <-> Snap_SE
```

`Snap_Base` is used by visual corner and seam overlays so they can attach to a wall-run socket. `Snap_RoofEdge` is the visible front-facade roof transition at `(0, -112)` and accepts a front cornice `Snap_Left`. `Snap_Parapet` is the cornice top at `(0, -19)` and accepts the front parapet `Snap_Left`, producing a true wall -> cornice -> parapet stack without overlapping alpha wedges. Informational anchors such as `Snap_Top` on a foundation or `GroundContact` on a ladder do not belong to the `steamtek_snap` group unless a defined compatible partner is added.

Foundation-to-wall placement uses explicit family sockets rather than the
informational `Snap_Top`. `Attach_FoundationFront` at a front-wall root accepts
foundation `Attach_WallFront` at `(-192, -158)`. The front wall ends at the
foundation back point `(0, -254)`. `Attach_FoundationSide` at a side-wall root
accepts foundation `Attach_WallSide` at `(0, -254)` and ends at the top-right
point `(192, -158)`. The wall planes therefore occupy the two back edges and
meet exactly at `(0, -254)`, leaving the foundation floor in front of them.
Where front and side wall planes share a vertical corner, instantiate W007 at
that shared point. The wall sockets establish geometry; W007 is the required
production seam cover that closes the exposed alpha edges and carries the
corner visually from the base strip through the full story height.

The Steamtek Modular Snap editor plugin moves the selected module root until a compatible marker pair occupies the exact same global coordinate.

### TileMapLayer grid bridge

Ground and flooring may be painted with an isometric `TileMapLayer`. Walls,
foundations, roofs, and architectural modules remain separate reusable scenes.
The snap plugin aligns those scene roots to the TileMapLayer's exact Steamtek
base lattice using local basis vectors `(64,-32)` and `(64,32)`, transformed by
the TileMapLayer's global transform.

- **Snap Selected** prefers a compatible scene marker within tolerance. If no
  marker is available, it falls back to the nearest isometric TileMapLayer grid
  point.
- **Snap Selected to Grid** always uses the nearest valid point on an isometric
  TileMapLayer.
- Non-isometric TileSets are ignored.
- The TileMapLayer, module root, and generated scenes must not be scaled or
  rotated to disguise alignment errors.

Diamond surfaces place these markers at shared-edge midpoints, never at diamond vertices. This makes one marker-to-marker operation produce the correct neighboring origin offset:

```text
256x128 ground: NE (64,-96), NW (-64,-96), SE (64,-32), SW (-64,-32)
384x192 roof/foundation: NE (96,-144), NW (-96,-144), SE (96,-48), SW (-96,-48)
```

## Production rules

1. Alpha boundaries, scene origins, markers, and collision must be generated from the same canonical geometry.
2. Decorative pixels may remain inside the module boundary but may not extend beyond its joining edges.
3. Never move or scale the `Visual` to fix an assembly. Fix the production generator and rebuild the module.
4. Never move or scale an instance's root to hide a seam.
5. Validate without collision-shape overlays before approval.
6. A module is approved only after straight-run, corner, story-stack, and in-game tests pass.

Production canvas and alpha silhouettes are locked by `assets/modular_v2/geometry_manifest.json` and checked by `tools/validate_modular_v2.py`. Fidelity work must also follow `docs/STEAMTEK_MODULAR_V2_FIDELITY_STANDARD.md`.

## Required scene shape

```text
SMV2_ModuleName (Node2D) [group: steamtek_modular]
├── Visual (Sprite2D)
├── Body (StaticBody2D)
│   └── BodyCollision (CollisionShape2D)
├── Snap_Left (Marker2D) [group: steamtek_snap]
├── Snap_Right (Marker2D) [group: steamtek_snap]
├── Snap_Upper (Marker2D) [group: steamtek_snap]
├── Snap_Lower (Marker2D) [group: steamtek_snap]
└── Snap_RoofEdge (Marker2D) [group: steamtek_snap] = (0, -112)
```
