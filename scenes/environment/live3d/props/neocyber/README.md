# Steamtek Live-3D Neo-Cyber Prop Kit v1

Status: geometry, facing, mounting, interaction, and emission contract review

## Permanent contract

- One Godot unit equals one meter.
- Every reusable prop root remains at scale `(1,1,1)`.
- Rotate roots to orient assets; never use negative-scale mirroring.
- `Visual_Blockout` is replaceable by authored Blender/GLB art.
- Named wall, floor, power, screen, interaction, and view markers remain stable.
- Wall contact is at the root origin with local `+Z` facing outward.
- Emission stays restrained and supports the dark structure rather than
  replacing material readability.
- No behavior, surveillance, interaction, or advertising scripts are included.

## Scenes

- `SteamtekNeonSignPanel3D.tscn` - restrained wall neon panel.
- `SteamtekDataTerminal3D.tscn` - 1.55-meter floor data terminal.
- `SteamtekAdvertisementScreen3D.tscn` - wall advertisement screen.
- `SteamtekSecurityCamera3D.tscn` - camera shell with aim and view markers.

These blockout visuals lock scale, roots, axes, markers, and restrained emission
before final neo-industrial/neo-cyber production art is authored.
