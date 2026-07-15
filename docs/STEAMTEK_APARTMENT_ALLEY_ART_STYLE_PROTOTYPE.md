# Steamtek Apartment & Alley Art-Style Prototype

## Purpose

This is the first playable Steamtek scene using the approved hand-painted HD 2.5D graphical treatment instead of code-drawn environment art.

## Scene

`res://scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn`

## Implementation

- Runtime remains completely 2D.
- Environment is a raster `Sprite2D`.
- Player is the existing C001 `CharacterBody2D`.
- World blocking uses `StaticBody2D` collision.
- Apartment entrance uses an `Area2D` and the existing zone-door script.
- Door enters the current apartment interior and the interior returns to this exterior.
- Camera is fixed and does not rotate.
- Rain and three subtle steam plumes are separate animated Godot effects layered over the raster environment.

## Controls

- `WASD`: move.
- `Enter` or `R`: use the apartment entrance.

## Visual status

The approved exterior artwork is a complete composite style prototype. It establishes the target rendering quality, atmosphere, modern material language, scale, and scene readability. It is not yet the later modular production split into neutral architecture, emission masks, foreground occluders, and separate reflection layers.

## Production follow-up

After this scene is approved in motion, the same visual language should be produced as original modular assets:

1. Neutral apartment facade and side modules.
2. Pressure-sealed door module.
3. Window modules and emission masks.
4. Roof, HVAC, tank, pipe, and utility props.
5. Alley pavement and drainage modules.
6. Foreground occlusion pieces.
7. Restrained local Godot lighting and reflection overlays.
