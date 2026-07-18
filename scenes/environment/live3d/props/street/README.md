# Steamtek Live-3D Street and Alley Prop Kit v2

Status: geometry, facing, mounting, and socket contract review

## Permanent contract

- One Godot unit equals one meter.
- Every reusable prop root remains at scale `(1,1,1)`.
- Rotate roots to orient assets; never use negative-scale mirroring.
- `Visual_Blockout` is intentionally replaceable by authored Blender/GLB art.
- `Sockets` and named `Marker3D` children remain stable during visual upgrades.
- Floor and street contact is at the root origin and local `+Y` points up.
- Yaw roots in 90-degree steps so props work on both street and building axes.
- Chainable assets expose named connection sockets.
- Interactive-looking blockouts expose explicit interaction, seat, display, or
  sign-face anchors without adding gameplay scripts.
- Materials stay neutral. Wetness, reflections, cyan, magenta, and amber belong
  to the material and lighting context rather than permanent neon-colored mesh.

## Art-direction blend

The permanent identity remains neo-industrial. Final authored meshes should
combine engineered dark construction, rugged material weight, heavy fasteners,
utility wear, and clear silhouettes that remain readable under wet night
lighting.

## Scenes

- `SteamtekDumpster3D.tscn` - 1.6 x 1.0 x 0.85-meter dumpster.
- `SteamtekTrafficBarrier3D.tscn` - chainable 1.2-meter barrier.
- `SteamtekStreetDrain1m3D.tscn` - chainable one-meter street drain.
- `SteamtekFireHydrant3D.tscn` - 0.9-meter neo-industrial hydrant.
- `SteamtekStreetBench3D.tscn` - 1.6-meter public bench.
- `SteamtekStreetSignPost3D.tscn` - 2.35-meter sign post with face anchor.
- `SteamtekChainBollard3D.tscn` - chain-ready 0.9-meter bollard.
- `SteamtekParkingMeter3D.tscn` - 1.25-meter parking meter.
- `SteamtekTrashClusterSmall3D.tscn` - small rotatable trash cluster.

These primitive meshes are not final graphics. Their purpose is to validate
scale, axes, orientation, naming, and socket placement before final production
art is authored.
