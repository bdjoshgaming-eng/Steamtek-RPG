# Steamtek Live-3D Street Kit

This folder contains the meter-scale foundation modules for Steamtek roads, sidewalks, alleys, drainage, and street boundaries. Geometry is deliberately simple while dimensions, roots, rotation, and snap behavior are reviewed.

## Locked foundation contract

- 1 Godot unit = 1 meter.
- Standard chain length is 2.4 m.
- Module roots remain at scale `(1, 1, 1)`.
- Horizontal-surface roots sit on their finished surface plane; structural thickness extends downward.
- Curb roots sit on the road plane and rise 0.18 m.
- Sidewalk roots sit on the finished walking plane, 0.18 m above the road.
- Rotate module roots around Y by 0, 90, 180, or 270 degrees.
- Never use negative-scale mirroring.
- `Marker3D` nodes in the `steamtek_live3d_snap` group are the authoritative sockets.
- Current visible geometry is temporary and must not redefine these contracts.

## Foundation dimensions

- Road straight: 2.4 m long by 4.8 m wide.
- Sidewalk straight: 2.4 m long by 1.2 m wide.
- Curb straight: 2.4 m long, 0.2 m deep, and 0.18 m high.
- Drain bay: 2.4 m chain length, wrapping two existing one-meter drain props.
- Alley tile: 2.4 m by 2.4 m.
- Fence straight: 2.4 m long by 1.8 m high.

## Included scenes

- `SteamtekRoadStraight4_8x2_4m3D.tscn`
- `SteamtekSidewalkStraight2_4m3D.tscn`
- `SteamtekCurbStraight2_4m3D.tscn`
- `SteamtekDrainBay2_4m3D.tscn`
- `SteamtekAlleyTile2_4m3D.tscn`
- `SteamtekFenceStraight2_4m3D.tscn`

## Specialty scenes

- `SteamtekRoadIntersection4Way4_8m3D.tscn` - 4.8 m square road intersection with four chain sockets.
- `SteamtekSidewalkCorner2_4m3D.tscn` - 2.4 m square raised corner landing.
- `SteamtekCurbCorner90_3D.tscn` - authored 90-degree curb turn with local `+X` and `+Z` arms.
- `SteamtekSidewalkCurbRamp2_4m3D.tscn` - straight sidewalk replacement bay descending 0.18 m toward local `-Z`.
- `SteamtekFenceCorner90_3D.tscn` - authored 90-degree fence turn.
- `SteamtekFenceGate2_4m3D.tscn` - 2.4 m service gate matching the fence chain.

## Marking and transition scenes

- `SteamtekRoadLaneMarkedStraight4_8x2_4m3D.tscn` - marked replacement for a straight road bay.
- `SteamtekRoadCrosswalk4_8x2_4m3D.tscn` - full-width crosswalk replacement bay.
- `SteamtekAlleyRoadApron2_4m3D.tscn` - 2.4 m alley tile with a local `-Z` road threshold.
- `SteamtekAlleyDrivewayCut2_4m3D.tscn` - sidewalk replacement bay providing the alley/driveway descent.

The approved rain-polished street candidate retains triplanar scale `Vector3(0.24, 0.24, 0.24)`. Sidewalks and alleys currently use the neutral wet-concrete candidate so role separation can be reviewed without baking colored light into materials.

The Steamtek Live3D Builder includes both the foundation and specialty scenes. Straight pieces use the 2.4 m placement buttons; intersection edges, cross-section attachments, and authored corners use `Snap Nearest` when necessary.

The lane-marked road and crosswalk scenes retain the exact root, footprint, and sockets of the unmarked road straight. The driveway cut retains the straight-sidewalk chain contract. The road apron retains the square alley grid and connects to the road side at local `-Z`.

Final collision and production artwork remain deferred until the complete Street Kit assembly is approved in a gameplay-scale district test.
