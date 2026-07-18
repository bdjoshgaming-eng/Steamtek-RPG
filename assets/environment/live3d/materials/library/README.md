# Steamtek Live-3D Material Library

This directory is the reusable Godot material layer for the current live-3D
production path.

## Art ownership

- Base materials contain neutral local color, surface response, and authored
  wear only.
- Godot lights own cyan, blue, magenta, violet, amber, red, and green spill.
- Colored wet reflections must trace to a visible or explicitly justified
  light source. They are not baked into repeating textures.
- One Godot unit remains one meter. Material work must never resize C001 or
  compensate for incorrect environment geometry.

## Current status

- `STK_MAT_ApartmentFacade_Neutral_v01.tres` wraps the approved-direction
  hand-painted facade texture for reusable triplanar application.
- `STK_MAT_WetConcrete_Neutral_v01.tres` wraps the approved-direction neutral
  wet-concrete texture. It is a starting surface, not permission to repeat one
  texture across every road, sidewalk, alley, and plaza role.
- `STK_MAT_RainPolishedStreet_Candidate_v01.tres` is the first authored
  blue-black paving candidate derived from the holistic surface-world
  reference. The user approved its current tile size and material direction on
  2026-07-17. Keep triplanar scale `Vector3(0.24, 0.24, 0.24)` unless a new
  review authorizes a change. It remains isolated pending gameplay-scale
  repetition and live-light review.
- `STK_MAT_RainAgedBrick_Candidate_v01.tres` is the first reference-led
  painterly brick candidate. Its material character is ready for visual review,
  but the user accepted it only as a temporary placeholder on 2026-07-17. Its
  top/bottom repeat seam has not passed promotion. Do not repair, promote, or
  interpret it as the final building language; dark panelized gunmetal
  construction is the actual target.
- Gunmetal, aged copper, brass, and roof steel are neutral base presets. Their
  numeric metallic/roughness contracts are reusable, but their final authored
  texture maps and wear are still pending.
- `STK_MAT_RoadMarking_OffWhite_Base_v01.tres` and
  `STK_MAT_RoadMarking_Amber_Base_v01.tres` are restrained neutral marking
  presets for crosswalk and lane blockouts. They do not emit light and do not
  modify the approved rain-polished street material.

## Promotion states

1. `base preset` - stable neutral parameters; bespoke maps may still be absent.
2. `art-direction candidate` - authored maps exist and must be reviewed at
   gameplay scale under neutral and Steamtek lighting.
3. `production` - approved maps, scale, wear, and in-engine response.

Do not call a base preset final artwork. Promotion requires both an unlit or
neutral-light review and an in-engine Steamtek-light review.
