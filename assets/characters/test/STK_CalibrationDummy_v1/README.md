# STK Calibration Dummy v1

This is an engineering validation fixture, not a production Steamtek character.

It contains a low-poly humanoid bound to the real `Steamtek_HumanRig_v1` deform bones, plus eight-frame `STK_IDLE` and `STK_WALK` actions. Both actions were rendered in eight genuine directions through the locked camera.

The v1.5 fixture includes the approved C001-calibrated camera framing and the Godot movement-aligned character-facing adapter. Its full compass was rerendered after the playable C002 test exposed the earlier 180-degree facing inversion. Its front-frame vertical envelope remains matched to C001 at production pixels 18 through 238, and its final Godot comparison matched C001's runtime vertical bounds exactly at 143 through 461.

## Included

- `blender/STK_CalibrationDummy_v1.blend`: rigged and animated source scene
- `production/idle` and `production/walk`: fixed 256 x 256 Godot delivery frames
- `godot/STK_CalibrationDummy_v1_Frames.tres`: sixteen standard animation names (`idle_*` and `walk_*`)
- `godot/STK_CalibrationDummy_v1_Visual.tscn`: reusable visual at scale `0.73` and offset `(0, -110)`
- `metadata`: source-render manifests and validation status

The authoritative raw renders were generated at 1254 x 1254 and passed QA. They are omitted from the portable package because they are reproducible from the `.blend` and total about 84 MB. The production set is a uniform whole-canvas resize; no frame was cropped or re-centered.

The rig passed its installed Godot comparison against immutable `Steamtek_C001` on 2026-07-14 and is marked `approved`.
