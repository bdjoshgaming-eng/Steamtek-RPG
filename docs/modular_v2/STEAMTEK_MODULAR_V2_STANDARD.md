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
Snap_Upper <-> Snap_Lower
Snap_NE    <-> Snap_SW
Snap_NW    <-> Snap_SE
```

The Steamtek Modular Snap editor plugin moves the selected module root until a compatible marker pair occupies the exact same global coordinate.

### TileMapLayer grid bridge

Ground and flooring may be painted with an isometric `TileMapLayer`. Walls and
other architecture remain separate scenes and snap to the shared base lattice
with local basis vectors `(64,-32)` and `(64,32)`. **Snap Selected** falls back
to this grid when no compatible scene marker is nearby; **Snap Selected to
Grid** forces the selected module to the nearest TileMapLayer lattice point.
Only isometric TileSets participate.

## Production rules

1. Alpha boundaries, scene origins, markers, and collision must be generated from the same canonical geometry.
2. Decorative pixels may remain inside the module boundary but may not extend beyond its joining edges.
3. Never move or scale the `Visual` to fix an assembly. Fix the production generator and rebuild the module.
4. Never move or scale an instance's root to hide a seam.
5. Validate without collision-shape overlays before approval.
6. A module is approved only after straight-run, corner, story-stack, and in-game tests pass.

## Required scene shape

```text
SMV2_ModuleName (Node2D) [group: steamtek_modular]
├── Visual (Sprite2D)
├── Body (StaticBody2D)
│   └── BodyCollision (CollisionShape2D)
├── Snap_Left (Marker2D) [group: steamtek_snap]
├── Snap_Right (Marker2D) [group: steamtek_snap]
├── Snap_Upper (Marker2D) [group: steamtek_snap]
└── Snap_Lower (Marker2D) [group: steamtek_snap]
```
