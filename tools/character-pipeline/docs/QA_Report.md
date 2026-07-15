# Pipeline QA report

Validated with Blender 4.5.11 LTS and Python on 2026-07-14.

## Passed

- C001 golden-reference hashes match the discovered source files.
- All Python and JSON files parse successfully.
- Master `.blend` contains the four required collections and ten required infrastructure objects.
- Master render output is 1254 x 1254, 100%, PNG RGBA, with transparent film.
- `Camera_Iso` is orthographic at the exact 2:1 dimetric elevation and uses C001-calibrated orthographic scale `2.21636`.
- Master non-production validation passes with the expected uncalibrated-armature warning.
- Production validation rejects the empty placeholder armature.
- End-to-end temporary dummy test rendered 16 files: two frames in each of eight genuine direction folders.
- Render-output QA passed frame dimensions, alpha, naming, direction order, completeness, and per-direction baseline stability.
- Blender 4.5's bundled Rigify human metarig generated successfully as `Steamtek_HumanRig_v1`.
- Approved rig contains 706 production/control bones and retains the editable 159-bone metarig.
- Rig and metarig are parented to locked `ROOT_CharacterFacing`; source `-Y` is adapted by `135` degrees so rendered names agree with Godot movement. This replaces the v1.4 adapter after C002's playable-map test exposed a 180-degree facing inversion.
- Locked `Camera_Iso`, 1254 x 1254 canvas, and transparent render settings remain unchanged after rig generation.
- Production scene validation passes with `steamtek_rig_status = approved`.
- `STK_CalibrationDummy_v1` binds 34 modular mesh parts to the generated Rigify deform bones.
- `STK_IDLE` and `STK_WALK` contain eight frames each and render through all eight genuine direction rotations.
- Full calibration output passed raw QA: 128 transparent 1254 x 1254 PNGs across idle and walk.
- Full calibration output passed production QA: 128 fixed 256 x 256 PNGs across idle and walk, uniformly resized without crop or recentering.
- A combined Godot 4 `SpriteFrames` resource and C001 comparison scene were generated with the locked `0.73` visual scale and `(0, -110)` offset.
- The first real Godot comparison revealed a three-quarter `south` view and a small baseline mismatch; v1.3 corrects both in Blender infrastructure rather than remapping Godot animations or adding a character-specific offset.
- The corrected calibration dummy's front frame occupies production pixels 18 through 238, matching C001's measured front-frame envelope.
- The corrected Godot comparison passed: C001 and the dummy both measured runtime vertical bounds of 143 through 461, faced south consistently, and aligned with their shared ground footprint.

## Not executable in this environment

- Godot was not installed on the available command path, so the generated `.tres`, `.tscn`, and importer were structurally inspected but not launched. They target Godot 4 syntax and standard resource APIs.

## Required next calibration

The shared rig and camera are approved for production character work. If an authoritative original C001 `.blend` becomes available, audit it against the approved contract before changing any locked infrastructure.
