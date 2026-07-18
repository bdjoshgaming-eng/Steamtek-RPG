# Steamtek Live-3D Industrial Prop Kit v1

Status: geometry, facing, mounting, and socket contract review

## Permanent contract

- One Godot unit equals one meter.
- Every reusable prop root remains at scale `(1,1,1)`.
- Rotate roots to orient assets; never use negative-scale mirroring.
- `Visual_Blockout` is replaceable by authored Blender/GLB art.
- Named mount, pipe, output, effect, and interaction markers remain stable.
- Floor and roof contact is at the root origin and local `+Y` points up.
- Materials remain dark and neutral; contextual colored light owns the mood.

## Scenes

- `SteamtekGenerator3D.tscn` - 1.7 x 1.35 x 1.0-meter generator.
- `SteamtekRooftopFan3D.tscn` - 1.2-meter rooftop exhaust fan.
- `SteamtekWaterTank3D.tscn` - 1.4 x 2.2-meter water tank.
- `SteamtekBoiler3D.tscn` - 1.35 x 1.55-meter horizontal boiler.

The companion `SteamtekPipeSteamValve3D.tscn` completes the utility pipe set
and is stored in the utility category.

These primitive meshes are not final graphics. They lock scale, roots, axes,
and socket placement before final neo-industrial production art is authored.
