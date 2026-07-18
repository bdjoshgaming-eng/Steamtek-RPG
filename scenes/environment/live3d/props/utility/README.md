# Steamtek Live-3D Utility Prop Kit v4

Status: geometry and socket contract review

## Permanent contract

- One Godot unit equals one meter.
- Every prop root remains at scale `(1,1,1)`.
- Rotate roots to orient props; never use negative-scale mirroring.
- `Visual_Blockout` is replaceable by authored Blender/GLB art.
- `Sockets` and named `Marker3D` children remain stable during visual upgrades.
- Pipe connections use local Y and half-meter end positions.
- Wall props use root origin as the contact plane and local `+Z` as outward.
- Floor and rooftop equipment use root origin as the mounting plane and local
  `+Y` as up.
- Materials stay neutral; contextual lighting owns colored spill.

## Art-direction blend

The permanent identity is neo-industrial, blended with rugged masonry weight,
heavy inset frames, exposed utilities, dense readable detail, wet surfaces,
and restrained cyan and magenta accents.

## Scenes

- `SteamtekPipeStraight3D.tscn`
- `SteamtekPipeElbow90_3D.tscn`
- `SteamtekPipeValve3D.tscn`
- `SteamtekPipeSteamValve3D.tscn`
- `SteamtekPipeTJunction3D.tscn`
- `SteamtekPipeCrossJunction3D.tscn`
- `SteamtekWallUtilityCabinet3D.tscn`
- `SteamtekWallVentUnit3D.tscn`
- `SteamtekPressureTank3D.tscn`
- `SteamtekAccessLadder2m3D.tscn`
- `SteamtekSteamOutlet3D.tscn`

These primitive meshes are not final graphics. They validate scale,
orientation, naming, instancing, and socket placement before final art.
