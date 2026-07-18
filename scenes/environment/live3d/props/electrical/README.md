# Steamtek Live-3D Electrical Prop Kit v2

Status: geometry, facing, and socket contract review

## Permanent contract

- One Godot unit equals one meter.
- Every reusable prop root remains at scale `(1,1,1)`.
- Rotate roots to orient assets; never use negative-scale mirroring.
- `Visual_Blockout` is intentionally replaceable by authored Blender/GLB art.
- `Sockets` and named `Marker3D` children remain stable during visual upgrades.
- Wall contact is at the root origin and local `+Z` points outward.
- Yaw the root in 90-degree steps to support both building axes.
- Conduit and cable tray may also roll around local Z to change direction on a
  wall. This is rotation, not mirroring.
- Materials stay neutral. Contextual cyan, magenta, amber, and warning color
  belong to lighting, lenses, decals, and authored final details.

## Art-direction blend

The permanent identity remains neo-industrial. Final authored meshes should
combine engineered dark-panel construction with rugged masonry weight, heavy
fasteners, inset service panels, exposed utility density, and readable shapes.

## Scenes

- `SteamtekWallConduitStraight1m3D.tscn` - one-meter wall conduit.
- `SteamtekWallCableTray1m3D.tscn` - one-meter wall cable tray.
- `SteamtekWallBreakerBox3D.tscn` - 0.5 x 0.7-meter breaker box.
- `SteamtekWallTransformer3D.tscn` - 0.9 x 1.1-meter transformer.
- `SteamtekWallPowerMeter3D.tscn` - compact round-dial power meter.
- `SteamtekWallFuseBox3D.tscn` - 0.45 x 0.6-meter fuse box.
- `SteamtekWallJunctionBox3D.tscn` - four-way conduit junction box.
- `SteamtekWallPowerRelay3D.tscn` - 0.55 x 0.8-meter power relay.

These primitive meshes are not final graphics. Their purpose is to validate
scale, axes, orientation, naming, and socket placement before final production
art is authored.
