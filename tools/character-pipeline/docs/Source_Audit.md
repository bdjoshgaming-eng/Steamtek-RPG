# Source audit

## Located

- C001 walk source, production atlas, previews, metadata, Godot `SpriteFrames`, and visual scene.
- `Steamtek_C001_GodotReady.zip`, containing the same C001 walk package.
- An earlier generated Blender proxy template and scripts.
- Blender 4.5.11 LTS at the expected local installation path.

## Not located

- The original `.blend` that produced C001.
- A production C001 armature or reusable humanoid rig.
- Native 1254 x 1254 per-frame C001 renders.

## Exact earlier proxy-template values

The earlier generated proxy template was inspected without modifying it:

- frame canvas: 512 x 512
- camera: `STK_CharacterCamera`
- location: `(-4.8180384636, -6.0901603699, 7.2005119324)`
- Euler rotation: `(0.8891771436, 0.00000002593, -0.6693018079)` radians
- orthographic scale: `2.2999999523`
- transparent film: enabled
- character root: `STK_CharacterRoot`
- no humanoid armature; proxy parts used separate object actions

Those values conflict with the newly requested 1254 canvas/name contract and the file is not a C001 source scene. The new master therefore retains the source-derived orthographic scale (`2.3`) but uses an exact mathematical 2:1 dimetric viewing angle and the required object names.

## C001 protection

No C001 source or Godot file was edited. `metadata/Steamtek_C001_GoldenReference.json` records stable hashes for the discovered reference PNGs. Run `tools/Steamtek_Verify_GoldenReference.py` against the C001 directory before using it for visual comparison.

