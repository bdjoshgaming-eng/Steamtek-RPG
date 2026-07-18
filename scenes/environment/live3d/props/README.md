# Steamtek Live-3D Prop Library

Status: Phase 1 geometry and socket contract complete

The library contains 36 reusable live-3D prop scenes. Preview scenes and README
files are not included in that count.

## Category totals

- Utility: 11 scenes
- Electrical: 8 scenes
- Street and alley: 9 scenes
- Industrial: 4 scenes
- Neo-cyber: 4 scenes

## Shared production contract

- One Godot unit equals one meter.
- Reusable roots remain at scale `(1,1,1)`.
- Use root rotation for direction changes; never use negative-scale mirroring.
- Stable roots, axes, and named markers survive final-art replacement.
- Primitive `Visual_Blockout` geometry is temporary and replaceable.
- Both building axes are supported through 90-degree root yaw.
- The locked live-3D camera and C001 scale are not changed by this library.
- Final art remains neo-industrial with rugged masonry weight, dense exposed
  infrastructure, wet-surface context, and restrained neo-cyber accents.

## Normal-editor previews

- `SteamtekUtilityKitPreview3D.tscn`
- `SteamtekElectricalKitPreview3D.tscn`
- `SteamtekStreetKitPreview3D.tscn`
- `SteamtekIndustrialKitPreview3D.tscn`
- `SteamtekNeoCyberKitPreview3D.tscn`

These previews live under `res://scenes/tests/hybrid_3d/` and are intended for
normal-editor F6 review. They are not gameplay scenes.

Phase 1 completion means the reusable blockout contracts are present. It does
not mean the temporary primitive visuals are final production models.
