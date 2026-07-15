# Steamtek Surface Construction Test

## Purpose

`res://scenes/tests/surface/Steamtek_SurfaceConstructionTest.tscn` is the isolated promotion gate for the Steamtek surface construction system.

It exists so camera calibration, modular snapping, building assets, scale, collision, rain, lighting, and complete exterior assemblies can be tested without touching `main.gd` or `main.tscn`. This keeps the construction work independent while the gameplay code is reorganized.

## Approved references

- `res://docs/references/ApartmentExterior_AssemblyMockup.png` — apartment composition, proportions, silhouette, module language, and golden assembly target.
- `res://docs/references/Steamtek_Surface_ColorPalette_Aesthetic_Reference.png` — complete surface-world palette and holistic aesthetic, especially wet street tiles, pooled water, reflections, masonry, piping, neon color, warm lamps, steam, and environmental density.

Use each reference as a complete image. Do not evaluate future work against isolated cropped details alone.

## Scene structure

```text
Steamtek_SurfaceConstructionTest
├── SnapGrid
├── BuildUnderTest
│   ├── GroundModules
│   ├── Architecture
│   ├── Roofs
│   ├── MountedDetails
│   ├── Props
│   └── Collision
├── ScaleGate
│   └── CurrentProductionC001
├── CameraAzimuthGate
│   ├── Current2To1
│   └── WestToEastCandidate
├── LightingAndEffects
├── PromotionCandidates
└── Camera2D
```

## Scale gate

The `CurrentProductionC001` instance is the exact visual used by the current game. Its root remains position-independent, rotation `0`, and scale `1,1`.

Do not approve rebuilt exterior modules merely because they share old canvas sizes. Judge them in this scene against the production player:

- the door must read as a usable human-scale entrance;
- a single storey must provide believable headroom above C001;
- wall-bay width must support doors, windows, and mounted details without crowding;
- sidewalk, curb, foundation, pipes, vents, and utility props must read at the same world scale;
- a two-storey apartment must look like a building rather than a character-height box.

Exact ratios are locked only after the first representative apartment bay is approved. Once locked, batch production must inherit them without per-asset resizing.

## Camera gate

Steamtek remains a fixed-camera 2.5D game using orthographic Blender renders and Godot 2D scenes.

The camera elevation remains the approved top-down isometric elevation. The current test is an azimuth decision: orient the environment west-to-east while retaining a valid 2:1 dimetric grid. Do not rotate finished sprites in Godot to simulate this change.

Place the current render under `Current2To1` and the new Blender candidate under `WestToEastCandidate`. Approve the new direction only after ground edges, wall axes, character viewing angle, attachment points, and snap vectors remain coherent.

## Promotion rule

Nothing is moved into `main.tscn` simply because it renders successfully. A candidate must pass:

1. Current production C001 scale comparison.
2. Exact snap placement without manual coordinate repair.
3. Front-wall, side-wall, vertical-storey, roof, parapet, and mounted-detail connections.
4. Complete building collision and door interaction footprint review.
5. Apartment mockup composition comparison.
6. Full surface aesthetic comparison.
7. Rebuild test from a clean scene using the same modules available to the user.

The golden result will be saved as a single placeable apartment exterior scene while remaining reproducible from the modular kit.
