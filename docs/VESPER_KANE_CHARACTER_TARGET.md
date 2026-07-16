# Vesper Kane - Canonical Character Target

## Purpose

These references define the visual target for Steamtek's principal character. They are design references, not direct 3D geometry and not sprite-sheet source material.

## Canonical references

- `VesperKane_FullBody_Target.png`
- `VesperKane_CharacterSheet_Target.png`

## Identity lock

- Neo-industrial / neo-punk silhouette, never Victorian-costume parody.
- Tall black top hat, high collar or scarf, and long asymmetrical weathered coat.
- Black and gunmetal base materials with controlled brass mechanical construction.
- Cyan is the primary emissive technology color; magenta is the secondary accent.
- One brass mechanical arm is a persistent anatomical feature. Its side may not be mirrored, swapped, or regenerated inconsistently.
- Raven drone is an optional detachable character attachment, not part of the base skeleton silhouette.
- Boots define ground contact and the character root.

## Runtime presentation

- Final character: live high-fidelity 3D model.
- World presentation: locked 2.5D hybrid view.
- Camera: orthographic, 60 degree azimuth, 30 degree elevation.
- Godot movement: eight-direction input with continuous 3D rotation and real skeletal animation.
- Required baseline clips: `STK_IDLE` and `STK_WALK`.

## Geometry rules

- No permanent sprite mirroring.
- No AI-generated direction substitutions.
- No silhouette or mechanical-arm drift between animations.
- Future art enhancement may change materials and surface detail, but not rig scale, origin, contact point, camera contract, or gameplay collision contract without revalidation.

## Current implementation status

`STK_C002_RigProof_v1.glb` is the reusable rig-and-animation integration proof. It is intentionally not the final Vesper model. The next character-art pass replaces its technical mesh and materials with the Vesper target while preserving the proven Godot integration, animation names, scale contract, and locked camera.
