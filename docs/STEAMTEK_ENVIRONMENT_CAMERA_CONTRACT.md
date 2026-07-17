# Steamtek Environment Camera Contract — Fixed Off-Axis 60° v2

Status: **locked for future environment production**

Approved: July 15, 2026

Live-3D scale note: meter-based hybrid scenes are additionally governed by
`docs/STEAMTEK_LIVE_3D_SCALE_CONTRACT.md`. The projected 2D basis below remains
preserved for its original asset pipeline and must not be used to rescale the
approved live-3D protagonist.

## Locked camera

- Presentation: fixed orthographic 2.5D
- Projection family: off-axis orthographic dimetric
- Horizontal azimuth: 60°
- Elevation: 30° above the ground plane
- Camera roll: 0°
- Runtime camera rotation: disabled
- Camera forward: `(-0.433013, 0.750000, -0.500000)`
- Camera location vector: `(5.656854, -9.797959, 6.531973)`
- Root scale in Godot: `(1, 1)`
- Render: PNG RGBA, transparent, AgX Medium High Contrast

## Locked projected construction basis

At the established Steamtek production scale:

- Front bay step: `(313.534, -90.509)` pixels
- Side bay step: `(-181.020, -156.768)` pixels
- Storey rise: `(0, -219)` pixels

The ground basis is now a **custom parallelogram**, not the former symmetrical 256×128 diamond. New ground tiles, modular sockets, placement tools, procedural generation, and collision references must use these two locked basis vectors.

The old 256×128 true 2:1 diamond remains useful only for legacy assets. It is not the production grid for new 60° assets.

## Scale gate

Every environment module is checked beside the exact production C001 scene:

`res://assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn`

C001 keeps visual scale `0.73`, visual offset approximately `(0, -110)`, and collision footprint `28 × 18`. Environment assets are fitted to that reference; C001 is never rescaled to fit an environment asset.

## Non-negotiable rules

1. Never rotate a rendered sprite in Godot to fake another camera azimuth.
2. Never change a module root scale from `(1,1)`.
3. Never independently crop a module after its pivot is generated.
4. Do not force new 60° assets onto a 256×128 symmetrical TileMap grid.
5. Geometry, alpha silhouette, root, snap endpoints, and collision remain authoritative.
6. Cyan, magenta, amber, glow, spill, and colored reflections are never baked into production PNGs; Godot lighting, tintable emission layers, overlays, and shaders own them.
7. Every illuminated asset must remain visually correct when all Godot lights and emission layers are disabled.
8. Whole-image aesthetic reference: `docs/references/Steamtek_Surface_ColorPalette_Aesthetic_Reference.png`.

## Migration rule

Existing V3 assets are preserved as legacy assets until a corresponding 60° replacement passes its visual, scale, pivot, collision, snap, and in-engine construction gates. Do not delete working V3 content during migration.
