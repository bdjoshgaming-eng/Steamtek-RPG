# Steamtek Environment Art Contract — Neutral Assets / Godot Lighting v1

Status: **locked for future environment production**

Approved: July 15, 2026

## Core rule

Production artwork contains neutral material information only. Cyan, magenta,
amber, and other scene-light colors are authored in Godot, not baked into PNG
assets.

## Production PNG requirements

Every environment base sprite must contain:

- Neutral albedo for concrete, masonry, steel, copper, rubber, glass, paint,
  grime, rust, repairs, and wear
- Material-local highlights and shadows required to describe the object
- Transparent background
- No colored environmental light spill
- No colored atmospheric glow
- No colored puddle or wet-surface reflection
- No baked bloom halo
- No baked cyan, magenta, or amber edge/rim light

Neutral material variation is allowed. For example, aged copper may remain
brown or oxidized, painted signage may retain its local pigment, and rust may
remain orange-brown. The restriction applies to illumination and reflections,
not to the object's actual manufactured color.

## Fixture structure

A reusable illuminated fixture is split into independently controlled parts:

```text
FixtureRoot (Node2D or StaticBody2D)
├── BaseVisual (Sprite2D)              # neutral housing and unlit lens
├── EmissionVisual (Sprite2D)          # grayscale/white mask, tint in Godot
├── FixtureLight (PointLight2D)        # cyan, magenta, amber, etc.
├── GlowOverlay (Sprite2D, optional)   # tint/additive material in Godot
├── Occluder (LightOccluder2D, optional)
└── Collision (optional)
```

The `EmissionVisual` texture is grayscale or white. Its `modulate`, energy,
animation, and final color are controlled by the Godot scene. This allows a
single fixture asset to become cyan, magenta, amber, emergency red, flickering,
disabled, or damaged without repainting the PNG.

## Wet surfaces and reflections

- Base wetness may be represented with neutral roughness/value changes.
- Colored reflections belong in a separate Godot overlay or shader.
- Rain, puddle ripple, steam diffusion, bloom, and reflected light respond to
  the active scene lighting.
- Turning off a light must also remove its colored spill and reflection.

## Godot light ownership

Lighting scenes own:

- Light color
- Energy and range
- Flicker and animation
- Day/night or power-state changes
- Light masks
- Glow/bloom contribution
- Colored wet-surface response

The base asset never owns those decisions.

## Art-direction target

Steamtek environment art is gritty, functional neo-industrial 2D:

- Desaturated concrete, masonry, and gunmetal
- Repairs, mismatched panels, welds, grime, leaks, corrosion, and rain damage
- Functional pressure lines and utilities
- Restrained manufactured pigments
- No showroom polish
- No broad baked neon wash
- No glossy generic 3D presentation render

## Approval gate

An environment asset cannot be promoted unless it passes both states:

1. **Unlit:** readable, neutral, and visually complete without colored light.
2. **Lit in Godot:** responds correctly to at least one cyan/magenta/amber light
   without colored pixels remaining after that light is disabled.

