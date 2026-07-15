# Steamtek Fixed Off-Axis 2.5D Camera Gate

Status: **complete — 60° selected and locked on July 15, 2026**

This gate compares one unchanged golden building under four fixed orthographic camera azimuths. Every candidate uses:

- Orthographic projection
- 30° camera elevation
- 0° camera roll
- The same building, materials, lights, and render resolution
- No runtime camera rotation

## Candidates

| Candidate | Character | Front bay step | Side bay step | Assessment |
|---|---|---:|---:|---|
| 45° | Symmetrical | `(349.091, 174.546)` | `(349.091, -174.545)` | Current equal-axis diamond view |
| 35° | Mild off-axis | `(283.168, 202.203)` | `(404.406, -141.584)` | Conservative change |
| 30° | Strong off-axis | `(246.845, 213.774)` | `(427.547, -123.422)` | Recommended balance |
| 25° | Extreme off-axis | `(208.642, 223.717)` | `(447.434, -104.321)` | One plane becomes very narrow |
| 60° | Reverse strong off-axis | `(427.547, 123.422)` | `(246.845, -213.774)` | **Approved Steamtek view** |

## Recommendation

The approved production camera is **60° azimuth**. It provides the preferred dominant facade while retaining a readable secondary wall and roof plane.

This decision replaces the earlier 30° recommendation. New production assets must follow `docs/STEAMTEK_ENVIRONMENT_CAMERA_CONTRACT.md`.

## Review Scene

Open:

`res://scenes/tests/surface/Steamtek_ApartmentExterior_OffAxis_CameraGate.tscn`

The four candidates are shown together with small projected-footprint guides.

## Lock Procedure

The lock procedure is:

1. Update the authoritative camera contract with the selected azimuth. **Complete.**
2. Record its projected front, side, and vertical step vectors.
3. Update Blender render templates and validation tools.
4. Re-render only the approved modular asset set.
5. Rebuild Godot assembly tests against the locked projection.
