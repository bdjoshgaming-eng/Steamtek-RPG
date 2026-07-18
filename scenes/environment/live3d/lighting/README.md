# Steamtek Live-3D Lighting Library v1

Status: reusable fixture, light, mounting, and aiming contract review

## Shared modular contract

- One Godot unit equals one meter.
- Every reusable root remains at scale `(1,1,1)`.
- Rotate roots for placement; never use negative-scale mirroring.
- `Fixture_Blockout` may be replaced by authored Blender/GLB art.
- `LightRig` preserves the approved color, energy, range, and shadow preset.
- `Sockets` preserves mounting, light-origin, aim, and effect markers.
- Wall fixtures use root origin as the contact plane and local `+Z` outward.
- Floor fixtures use root origin as the ground contact point and local `+Y` up.
- Yaw roots in 90-degree steps to support both building axes.
- Light colors are restrained accents supporting dark neo-industrial materials.

## Presets

- `SteamtekAmberDoorLight3D.tscn` - warm doorway pool.
- `SteamtekBlueSecurityLight3D.tscn` - directional blue security spot.
- `SteamtekStreetLamp3D.tscn` - warm floor-mounted street lamp.
- `SteamtekNeonSignGlow3D.tscn` - restrained magenta sign bounce.
- `SteamtekIndustrialFloodLight3D.tscn` - long-range cool floodlight.
- `SteamtekEmergencyRedLight3D.tscn` - compact red warning pool.
- `SteamtekSteamGlow3D.tscn` - subtle cyan steam accent.

The preview scene lives at
`res://scenes/tests/hybrid_3d/SteamtekLightingLibraryPreview3D.tscn` and is
intended for normal-editor F6 review. It does not reference the playable
dimensional blockout.
