# Steamtek Home Handoff — Apartment + Service Alley Art-Style Prototype

Date: July 15, 2026  
Project root: `C:\My Game\Steamtek-RPG`  
Status: **playable exterior art-style prototype completed and validated**

## 1. What was completed

A new playable Steamtek exterior scene was built from start to finish using the newly approved graphical direction:

- modern neo-industrial apartment building on the left;
- narrow service alley continuing to the right;
- hand-painted HD 2.5D presentation;
- dark charcoal concrete, gunmetal, pressure pipes, HVAC, vents, and sealed industrial architecture;
- wet reflective pavement;
- warm amber apartment lighting;
- restrained cyan and magenta accents;
- animated rain;
- three subtle animated steam plumes;
- existing animated C001 player;
- complete world collision and scene boundaries;
- working apartment-door interaction;
- transition into the apartment interior;
- working return transition from the interior to this exterior;
- fixed camera with no runtime rotation;
- Y-sorting and correct collision layers.

This is the current approved **rendering-style prototype** for the surface. It replaces the previous V1–V4 experiments as the visual-quality target, but it is not yet a fully separated modular production kit.

## 2. Open this first at home

In Godot, open:

`res://scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn`

Press `F6` to run that scene directly.

Controls:

- `WASD`: move
- `Enter` or `R`: use the apartment entrance

Walk to the illuminated apartment door and press `Enter` or `R`. The player enters the existing apartment interior. Use the interior exit to return to this new exterior.

The project main scene was not changed. Run this scene directly with `F6` for review.

## 3. Approved visual direction

The user approved the new apartment/alley artwork with:

> “yea this is the style i want. I want this graphical art style badly.”

The locked surface direction is:

- 2D runtime presented as 2.5D;
- hand-painted HD isometric/off-axis environment art;
- modern neo-industrial/cyberpunk steam technology;
- dark, dense, believable, functional architecture;
- rain-soaked ground with controlled reflections;
- gunmetal, charcoal concrete, blackened steel, copper pressure hardware;
- warm amber interior and utility light;
- cyan and magenta used as restrained illumination accents;
- pipes, vents, machinery, and fixtures must look functional;
- buildings may face both supported world directions;
- fixed camera; no dynamic camera rotation.

Avoid:

- Victorian London;
- 1920s or Art Deco architecture;
- top hats, decorative goggles, horse carriages;
- decorative gears attached without function;
- bright plastic-looking neon;
- clean or glossy generic 3D-render aesthetics;
- changing the structural design to copy a reference image;
- treating reference buildings as literal layouts.

Reference images establish the **rendering language, palette, density, atmosphere, and material treatment only**. They are not structure designs to duplicate.

## 4. Approved artwork

Project copy used by Godot:

`res://assets/surface/art_style_prototype/apartment_alley/STK_APT001_ApartmentAlley_Background_v001.png`

Absolute path:

`C:\My Game\Steamtek-RPG\assets\surface\art_style_prototype\apartment_alley\STK_APT001_ApartmentAlley_Background_v001.png`

Image dimensions: `1604 × 981`

The art was generated as an original Steamtek scene using three references only for graphical style:

- `C:\Users\bdjos\AppData\Local\Temp\codex-clipboard-5db3ab0a-adc7-4f2c-8d55-2b037bbf7f52.png`
- `C:\Users\bdjos\AppData\Local\Temp\codex-clipboard-3cd34451-06e9-47a3-ad0a-60e00d8bd82e.png`
- `C:\Users\bdjos\AppData\Local\Temp\codex-clipboard-94db42db-225b-42f3-8705-361129af5780.png`

Important: the third temporary reference path above may not exist on another PC. The production artwork already stored inside the project is the required portable file.

## 5. Runtime implementation

The prototype remains completely 2D at runtime:

- root: `Node2D`
- environment: one composite `Sprite2D`
- player: existing C001 `CharacterBody2D`
- world blocking: `StaticBody2D` with split `CollisionShape2D` regions
- apartment interaction: `Area2D`
- door behavior: existing `steamtek_zone_door.gd`
- camera: existing player `Camera2D`, overridden to `Vector2(1, 1)` zoom for this scene
- ordering: Y-sorted player layer
- atmosphere: separate animated rain overlay and three subtle steam nodes

Collision contract:

- Layer 1: World
- Layer 2: Player
- Layer 5 / bit value 16: Interactable/door area
- world collision mask targets Player
- door area mask targets Player

The environment image is not used for pixel-perfect collision. Collision follows the walkable footprint and architectural base lines.

## 6. Files added or changed

### Added

`res://assets/surface/art_style_prototype/apartment_alley/STK_APT001_ApartmentAlley_Background_v001.png`

`res://scenes/levels/surface/Steamtek_ApartmentAlley_ArtStylePrototype.tscn`

`res://docs/STEAMTEK_APARTMENT_ALLEY_ART_STYLE_PROTOTYPE.md`

`res://tests/validate_apartment_art_style_prototype.py`

### Changed

`res://scenes/levels/apartment/Apartment_Interior.tscn`

- The interior exit now returns to `Steamtek_ApartmentAlley_ArtStylePrototype.tscn`.
- Prompt now reads `Return to the apartment exterior`.

`res://tests/validate_opening_slice_v4.py`

- Updated the apartment return-path check to the approved exterior.

`res://tests/validate_surface_route_v4.py`

- Updated the apartment return-path check while retaining the legacy Brass Lantern route check.

## 7. Validation completed

Godot 4.7 successfully loaded:

- `Steamtek_ApartmentAlley_ArtStylePrototype.tscn`
- `Apartment_Interior.tscn`

All automated validation suites passed:

- `validate_apartment_art_style_prototype.py`
- `validate_modular_v4.py`
- `validate_opening_slice_v4.py`
- `validate_surface_route_v4.py`

The final scene was re-tested after adding animated rain and steam.

## 8. Current limitations — do not mistake these for finished production systems

The exterior is a complete playable **style prototype**, but:

- the apartment and alley are currently one composite background image;
- the architecture is not yet broken into snappable wall, roof, door, window, pipe, and foreground modules;
- baked lighting and reflections remain in the composite artwork;
- the long-term production kit still needs neutral architecture plus separate emission masks and Godot lighting;
- the apartment interior is the existing functional placeholder interior, not the approved final graphical treatment;
- collision has been authored for this prototype scene and will need per-module production collision later;
- the previous V4 modular experiments remain legacy technical references, not the approved graphical result.

Do not claim this composite image is a finished modular kit.

## 9. Recommended next production phase

Build the approved apartment into original, isolated, snappable production modules while preserving this exact graphical language.

Recommended order:

1. Lock the module grid, fixed camera, visible scale, and root/pivot contract against C001.
2. Create neutral front-facing apartment facade modules.
3. Create the matching perpendicular/side-facing facade modules.
4. Create outside and inside corner modules plus left/right facade caps.
5. Create a pressure-sealed apartment door module and separate interaction area.
6. Create matching window modules with separate emission masks.
7. Create roof center, roof edge, roof corner, parapet, HVAC, tank, and vent modules.
8. Create separate pipe, utility cabinet, drain, railing, curb, and alley clutter modules.
9. Create wet pavement, service walkway, curb, drain, road, and puddle/reflection layers.
10. Create foreground occlusion pieces for walking behind architecture.
11. Add production split collision to every wall/module from the beginning.
12. Rebuild the apartment exterior from modules and compare it directly with the approved composite prototype.
13. Only after the exterior passes the graphical gate, replace the placeholder apartment interior art.

Production-lighting rule:

- architecture should be authored primarily neutral;
- amber fixtures, cyan/magenta accents, reflections, rain, and steam should be separate whenever practical;
- avoid baking strong cyan/magenta across every base module;
- the final assembled scene should still match the approved composite’s atmosphere.

## 10. Immediate review checklist at home

1. Open the new exterior scene and press `F6`.
2. Walk the full accessible pavement and alley route.
3. Confirm the player cannot enter the apartment walls or leave the scene boundaries.
4. Walk to the door and enter the apartment.
5. Use the interior exit and confirm the exterior reloads.
6. Review rain and steam motion at normal gameplay speed.
7. Review the camera framing and C001 scale against the building.
8. Decide whether this composite passes as the authoritative rendering-quality gate before modular production begins.

## 11. Copy/paste continuation prompt

Use this when continuing in a new task or on the home PC:

> Read `C:\My Game\Steamtek-RPG\docs\from output\STEAMTEK_HOME_HANDOFF_2026-07-15_APARTMENT_ALLEY.md` completely before changing anything. Continue from the playable `Steamtek_ApartmentAlley_ArtStylePrototype.tscn`. Preserve the approved modern neo-industrial hand-painted HD 2.5D graphical direction. References define graphical style only, not structure designs. The current composite is the visual-quality prototype; the next phase is to create original neutral, snappable production modules with separate lighting/emission/reflection/FX layers and production collision from the beginning. Do not return to the rejected V1–V4 graphical appearance, Victorian styling, generic polished 3D rendering, or bright artificial lighting.
