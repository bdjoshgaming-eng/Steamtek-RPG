# Steamtek Reusable Character Pipeline

This package establishes the reusable Blender-to-Godot character pipeline while keeping `Steamtek_C001` as an immutable golden reference.

## Start here

1. Read `docs/Steamtek_Character_Pipeline.md`.
2. Open `blender/Steamtek_Character_Master.blend` in Blender 4.5 LTS.
3. Replace only the character mesh, calibrated armature, materials, and equipment slots.
4. Run `blender/scripts/Steamtek_Validate_CharacterScene.py` before rendering.
5. Render with `blender/scripts/Steamtek_Render_8Directions.py`.
6. Import the frames with `godot/Steamtek_Import_CharacterFrames.gd`.

The v1.1 master contains `Steamtek_HumanRig_v1`, generated from Blender 4.5 LTS's bundled Rigify human metarig because no authoritative C001 rig was found. It remains a calibration candidate; production validation rejects it until representative mesh deformation and the eight-direction Godot comparison against C001 pass.

## Locked contract

- 1254 x 1254 RGBA frame canvas
- transparent background
- orthographic 2:1 dimetric camera
- eight genuine rotations, never mirrored
- ground-contact root at world origin, centered between the boots
- Godot visual scale `0.73`
- Godot visual offset `(0, -110)`
- collision footprint `28 x 18`
- fixed canvas; no per-frame cropping or recentering
