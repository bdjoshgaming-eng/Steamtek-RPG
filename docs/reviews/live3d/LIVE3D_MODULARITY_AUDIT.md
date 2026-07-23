# Steamtek Live3D Builder Modularity Audit

## Scope

Every scene exposed by the Steamtek Live3D Builder was audited, including generated material variants. Current audited module count: 49.

## Required contract

- Node3D root at scale 1,1,1
- Root group: `steamtek_live3d_modular`
- Module system metadata: `live3d_meter_v1`
- Builder-compatible Marker3D sockets use group `steamtek_live3d_snap`
- Every Builder socket has a recognized `socket_role`
- Chain modules expose compatible edge sockets
- Corner and apron modules may use intentional orthogonal or one-sided socket layouts

## Builder placement behavior

The -X, +X, -Z, and +Z placement buttons now align the chosen module directly to a compatible socket on the requested side. The selected placement profile grid is used only when no compatible directional socket pair exists.

Manual Snap Nearest preserves the module's existing rotation for chain sockets and performs translation-only alignment. Interior wall-to-floor attachment sockets retain their authored orientation behavior so walls align correctly to rotated floor edges.

Curb snapping uses a 1.5 m socket capture radius and ignores compatible sockets that are already occupied by another module. This applies to curb chains, curb corners, curb-to-road edges, and curb-to-sidewalk edges, preventing intermittent selection of a blocked socket. Road-edge and sidewalk-edge attachments infer the required yaw from the target side, so the curb automatically rotates 180 degrees when moving from one side of a road or sidewalk to the opposite side.

## Result

- Modules audited: 49
- Contract failures: 0
- Missing module groups: 0
- Missing or invalid module-system metadata: 0
- Invalid root scales: 0
- Missing Builder socket roles: 0
- Broken chain definitions: 0

Three decorative-span notes are intentional and do not change the structural socket span:

- `SteamtekParapetStraight3D`: the cap overhangs the 2.4 m structural body by 0.05 m per end.
- `APT_Pipe_Run_240_A`: the visible service pipes stop inside the 2.4 m placement bay.
- `SteamtekDrainBay2_4m3D`: the drain inserts are spaced inside a nominal 2.4 m street bay.

Run `res://tools/qa/audit_live3d_modularity.gd` with Godot headless mode to repeat the audit after adding or changing Builder assets.
