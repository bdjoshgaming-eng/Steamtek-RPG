# Steamtek Character Pipeline v1.6

## Authority

`Steamtek_C001` is the immutable golden reference. `Steamtek_Character_Master.blend` is reusable infrastructure, not C001. Never save new character work over either file.

## Master scene

The v1.6 master contains the locked camera, render settings, lighting collections, direction root, ground-contact root, character-facing adapter, character/equipment slots, reference metadata, and production-approved `Steamtek_HumanRig_v1`. The rig is generated from Blender 4.5 LTS's bundled Rigify human metarig because no authoritative C001/source rig was found. Representative deformation, genuine eight-direction rendering, fixed-canvas QA, and corrected in-Godot movement comparison against immutable C001 passed on 2026-07-14.

The hierarchy is:

```text
ROOT_Direction
└── ROOT_GroundContact
    └── ROOT_CharacterFacing (-45 degrees locked)
        ├── Armature (Steamtek_HumanRig_v1 approved)
        ├── Character_Mesh_SLOT
        └── Equipment_SLOT
```

The ground-contact and direction roots remain at the world origin. Fit the character so the point centered between both boot contacts is `(0, 0, 0)`. Character source files face Blender `-Y`; the locked `ROOT_CharacterFacing` adapter rotates that local forward axis by `-45` degrees. `ROOT_Direction` advances clockwise: `south 0`, `south_west -45`, `west -90`, `north_west -135`, `north 180`, `north_east 135`, `east 90`, `south_east 45`. Artists do not edit this adapter or order. Pipeline v1.6 locks the screen-direction handedness verified during C002's playable-map test.

## Character setup

1. Duplicate `Steamtek_Character_Master.blend` to a character-specific file.
2. Fit the character mesh to `Steamtek_HumanRig_v1` without moving the roots, camera, or render rig.
3. Keep `Armature["steamtek_rig_status"]` set to `approved`; do not substitute an unvalidated rig under this identifier.
4. Parent mesh and equipment beneath `ROOT_CharacterFacing` (normally through the armature).
5. Assign one of the shared actions named in the character manifest.
6. Keep every frame on the fixed 1254 x 1254 canvas. Do not crop or recenter renders.

## Scene validation

From Blender's Scripting workspace, run:

```text
Steamtek_Validate_CharacterScene.py -- --manifest <manifest.json> --production
```

Omit `--production` only while checking the uncalibrated master itself.

## Eight-direction render

Run Blender in the background or from its Scripting workspace:

```text
blender -b Character.blend --python-exit-code 1 --python Steamtek_Render_8Directions.py -- \
  --manifest Steamtek_Character_Manifest.json \
  --character-id Steamtek_C002 \
  --animation walk \
  --output renders \
  --production
```

The renderer does not repair, crop, scale, move, or guess. It validates the locked scene, rotates only `ROOT_Direction`, renders each real direction, restores the scene, and writes `render_manifest.json`.

## Output QA

Run:

```text
python Steamtek_Validate_RenderOutput.py \
  renders/Steamtek_C002/walk \
  metadata/Steamtek_Character_Manifest.json
```

The validator checks dimensions, frame counts, alpha, naming, direction completeness, and baseline stability.

## Production frames

Raw Blender renders remain on the locked 1254 x 1254 canvas. Build the Godot delivery set by uniformly resizing the complete canvas to 256 x 256:

```text
python Steamtek_Build_ProductionFrames.py \
  renders/Steamtek_C002/walk \
  production/Steamtek_C002/walk \
  --size 256
```

This is a whole-canvas resize, never a crop or per-frame alignment operation. Validate the delivery set with `Steamtek_Validate_RenderOutput.py --production`.

## Godot import

Install the visual/body scenes under `res://scenes/characters/templates/` and the importer under `res://tools/character-pipeline/godot/`. Set the constants at the top of `Steamtek_Import_CharacterFrames.gd` to the character's `production` folder, then run it from the Godot editor. It creates a standard `SpriteFrames` resource with names such as `walk_south` and `walk_north_east`.

The calibration fixture is installed under `res://assets/characters/test/STK_CalibrationDummy_v1/`, with the comparison scene at `res://scenes/characters/validation/STK_CharacterPipelineCalibration.tscn`.

Blender source folders are marked with `.gdignore`. Godot uses the rendered PNG frames, not direct `.blend` import. Disable Godot's `.blend` importer if the editor prompts for a Blender executable.

Use `Steamtek_CharacterVisual.tscn` for replaceable visuals and `Steamtek_CharacterBodyTemplate.tscn` for the gameplay shell. The visual child owns the `0.73` scale and `(0, -110)` offset; the `CharacterBody2D` remains at scale `1`.

## Approval gate

A character is not production-ready until it has genuine eight-direction renders, stable boot baseline, correct asymmetrical equipment sides, no mirroring, no baked background, the approved rig/actions, matching scale against C001, and an in-Godot Y-sort/collision test.

The shared rig/camera infrastructure passed its approval gate on 2026-07-14. Each new character still passes the per-character gate above.

When running Blender from automation, keep `--python-exit-code 1` so validation failures return a failing process status.
