# Steamtek Live-3D Apartment Exterior Kit

This folder contains the first meter-scale structural modules for the Steamtek apartment exterior kit. The geometry is deliberately simple so proportions and snap behavior can be approved before final art is authored.

## Locked module contract

- 1 Godot unit = 1 meter.
- Standard facade bay width: 2.4 m.
- Standard storey height: 3.2 m.
- Standard wall thickness: 0.24 m.
- Module roots remain at scale `(1, 1, 1)`.
- Facade roots sit at the base-center of the bay, on the front facade plane.
- The authored facade front is `+Z`; the wall body extends toward `-Z`.
- Rotate a module root around Y by 0, 90, 180, or 270 degrees to face either street axis.
- Do not mirror modules with negative scale. Author a handed variant when text or asymmetric detail requires one.
- `Marker3D` nodes in the `steamtek_live3d_snap` group are the authoritative sockets.

## Included scenes

- `SteamtekFacadeBaySolid3D.tscn`
- `SteamtekFacadeBayWindow3D.tscn`
- `SteamtekFacadeBayDoor3D.tscn`
- `SteamtekFacadeCornerColumn3D.tscn`
- `SteamtekParapetStraight3D.tscn`
- `SteamtekParapetCorner3D.tscn`
- `SteamtekBalconyModule3D.tscn`
- `SteamtekFloorTile3D.tscn`
- `SteamtekRoofTile3D.tscn`

## Horizontal shell tiles

- Floor and roof tiles use a 2.4 m by 2.4 m footprint.
- Their roots sit at tile center on the finished assembly plane.
- Structural thickness extends downward so storey and parapet heights stay exact.
- Four edge sockets support assembly along either X or Z.
- Floor tiles also expose the standard 3.2 m vertical storey sockets.

## Production boundary

These scenes establish dimensions, pivots, rotations, and socket placement. Their visible meshes and materials are blockout-grade placeholders for the approved neo-industrial / neo-punk art direction. Collision is intentionally not part of this first snap-contract pass.
