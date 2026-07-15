# Steamtek C001 - Godot Walk Asset

This folder contains a Godot-ready, eight-direction, four-frame walk prototype.

## Use in Godot

The easiest option is to instantiate:

`godot/Steamtek_C001_WalkVisual.tscn`

The reusable scene keeps the root `Node2D` at scale `(1, 1)` and applies the calibrated visual scale only to its `AnimatedSprite2D` child.

Alternatively, assign this resource to an existing `AnimatedSprite2D`:

`godot/Steamtek_C001_Walk_8dir_4f_256.tres`

Then use:

- Visual scale: `(0.73, 0.73)`
- Sprite offset: `(0, -110)`
- Playback speed: `8 FPS`
- Texture filtering: `Nearest`

## Animation names

- `walk_south`
- `walk_south_west`
- `walk_west`
- `walk_north_west`
- `walk_north`
- `walk_north_east`
- `walk_east`
- `walk_south_east`

## Sheet layout

- Cell size: `256 x 256`
- Columns: `4` animation frames
- Rows: `8` directions
- Sheet size: `1024 x 2048`
- Background: transparent RGBA
- Boot baseline: `Y = 238` within every cell

The JSON file in `production` records the layout, alignment, scale, and frame bounds for tooling.

## Important

This is a usable prototype derived from an AI-generated direction sheet. The locked Blender render pipeline remains the production target for fully consistent anatomy, equipment, lighting, and animation motion.
