# Iso Alley Test Scene (Godot 4)

Drop-in test scene for a 2:1 isometric background.

## Contents
- `assets/iso-alley-scene.png` - 1920x960, pre-projected 2:1 isometric art.
- `scenes/TestScene.tscn` - background sprite, Camera2D, collision + nav placeholders, player.
- `scripts/Player.gd` - WASD/arrow-key movement mapped onto 2:1 iso axes.

## Character standards baked into the scene
- Source sprite 1254x1254, visible 443x1117 at scale 0.09 -> ~40 x 100.5 world units.
- Collision footprint: 28 x 18 (RectangleShape2D on Player).
- Root position: centered between the boots at ground contact - the `SpritePlaceholder` ColorRect is offset so its bottom-center sits on the CharacterBody2D origin.

## Layers
- `CollisionLayer` (Node2D) - StaticBody2D children for walls/props. Includes one placeholder wall collider; trace real silhouettes in the editor.
- `NavLayer` (NavigationRegion2D) - placeholder walkable rectangle over the cobblestone. Rebake after tracing the actual ground polygon.

## Camera
Camera2D is axis-aligned (no rotation) because the art is already 2:1 projected. Limits are clamped to the 1920x960 background.

## To use
1. Open the folder in Godot 4.3+ (`project.godot`).
2. Run - you spawn near the manhole and can walk with arrow keys.
3. Replace the placeholders with real collision polygons and a baked NavigationPolygon.
