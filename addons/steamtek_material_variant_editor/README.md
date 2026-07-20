# Steamtek Material Variant Editor

This editor-only dock creates reusable color variants without duplicating render geometry, collision, pivots, or snap sockets.

## First supported asset

- `STK_PROP_Couch_A`
- Recolorable region: Upholstery
- Mask method: computed red, saturated, non-metal pixels
- Emission editing: locked because upholstery is not a powered region

The couch is the proof asset. Future assets should expose approved recolor profiles during intake. Prefer separate imported materials or explicit grayscale mask textures over heuristic color detection.

## Beginner workflow

1. Enable **Steamtek Material Variant Editor** under **Project > Project Settings > Plugins**.
2. Open a 3D scene containing `STK_PROP_Couch_A` or one of its variants.
3. Select the couch root or any child of the couch.
4. Choose a Steamtek palette preset or a custom color.
5. Adjust strength, brightness, and upholstery roughness.
6. Click **Preview on Selected Asset**.
7. Enter a short variant name and click **Save as Variant**.
8. In the Live3D Builder, click **Refresh module list**.

Generated materials are saved beneath:

- `res://assets/environment/live3d/materials/apartment_interior_variants/generated/`

Generated modular scenes are saved beneath:

- `res://scenes/environment/live3d/props/apartment_interior/generated_variants/`

Generated scenes inherit the approved production couch and use the existing material-variant script. They do not duplicate the production GLB.
