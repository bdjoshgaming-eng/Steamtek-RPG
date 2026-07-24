# Steamtek Environment Intake Full Generation Final Summary

- Date: 2026-07-23
- Pack: `3DT_Cyberpunk_Downtown`
- Pipeline: `1.0.3` (modular integration successor to the previously validated `1.0.2`)
- Pack identity gate: PASS; all six approved pilot sources occur in the 181-asset full manifest with identical source hashes
- Builder registration: disabled and locked
- Remaining approval boundary: generated categories remain subject to normal-editor visual review before registration

## Exact roots

- Purchased pack root: `C:\My Game\Steamtek-RPG\assets\environment\3DT_Cyberpunk_Downtown`
- Purchased geometry source root: `C:\My Game\Steamtek-RPG\assets\environment\3DT_Cyberpunk_Downtown\FBX`
- Production output root: `C:\My Game\Steamtek-RPG\assets\environment\3DT_Cyberpunk_Downtown\Steamtek`

## Production totals

| Result | Count |
|---|---:|
| Purchased source files verified | 483 |
| Assets processed | 181 |
| Wrapper scenes generated | 181 |
| Shared materials generated | 52 |
| Box collision shapes generated | 56 |
| Manual-review/no-collision assets | 14 |
| Explicit no-collision assets | 111 |
| Unresolved materials | 0 |
| Failed imports or wrapper loads | 0 |
| Failed seam tests | 0 |
| Changed purchased source files | 0 |
| Added purchased source files | 0 |
| Removed purchased source files | 0 |
| Source or manifest hash mismatches | 0 |

## Modular integration totals

| Result | Count |
|---|---:|
| Structural modular assets | 58 |
| Non-structural assets, total | 123 |
| Attachment-compatible non-structural assets | 80 |
| Ordinary non-modular assets | 23 |
| Rejected modular candidates | 33 |
| Total snap points | 233 |
| Builder candidates generated | 181 |
| Builder registrations performed | 0 |
| Existing live-builder modules recognized | 181 / 181 |
| Failed snap compatibility tests | 0 |
| Failed seam/gap/overlap tests | 0 |
| Failed orientation tests | 0 |
| Failed cardinal-yaw rotation tests | 0 |
| Failed elevation tests | 0 |

Classification is intentionally conservative. Ordinary decorative props receive no structural chain points. Attachment-compatible props use the existing `prop_anchor` contract only. Ambiguous corners, compound/bent pipes, sloped roads, unproven stairs, and unclear trim endpoints fail closed as rejected candidates.

### Snap points by asset category

| Asset category | Assets | Snap points |
|---|---:|---:|
| Doorways | 6 | 0 |
| Floor | 2 | 7 |
| Metal Panels | 7 | 7 |
| Metal Sheets | 11 | 11 |
| Pipes | 43 | 64 |
| Platform | 1 | 2 |
| Props | 20 | 20 |
| Railings | 3 | 6 |
| Road | 4 | 12 |
| Shelters | 4 | 0 |
| Signs | 21 | 21 |
| Steps | 4 | 0 |
| Trims | 21 | 18 |
| Wall Props | 8 | 8 |
| Walls | 13 | 44 |
| Windows | 13 | 13 |
| **Total** | **181** | **207** |

### Primary snap roles

| Existing live-3D role | Assets | Primary points |
|---|---:|---:|
| `facade_horizontal` | 9 | 18 |
| `floor_horizontal` | 1 | 2 |
| `prop_anchor` | 67 | 67 |
| `street_curb_chain` | 1 | 2 |
| `street_fence_chain` | 3 | 6 |
| `street_road_chain` | 2 | 4 |
| `street_sidewalk_chain` | 1 | 2 |
| `wall_service_chain` | 41 | 82 |

The remaining 50 points are existing-compatible wall/floor attachment surfaces and road/sidewalk/curb edge roles, including the new top-of-wall anchors.

### Rejected modular candidates

| Reason group | Count |
|---|---:|
| Compound, bent, or caged pipe endpoints not proven | 11 |
| Sloped road endpoint elevations require authored points | 2 |
| Stair travel/elevation not proven | 4 |
| Trim/corner endpoints ambiguous | 12 |
| Wall/corner endpoints ambiguous | 4 |
| **Total** | **33** |

Exact rejected asset names and reasons are retained in the generated catalog candidates and full manifest.

## Existing-tool integration

- The legacy 2D addon was archived intact at `addons/_archived/steamtek_modular_snap_legacy_2d` and removed from the active project plugin list. It remains available for recovery but is no longer an active snapping tool.
- `addons/steamtek_live3d_builder` remains the sole 3D module/snap/placement authority.
- Generated roots use group `steamtek_live3d_modular` and `metadata/module_system = "live3d_meter_v1"`.
- Generated points use `Marker3D`, group `steamtek_live3d_snap`, and only roles already accepted by the live builder.
- Three read-only QA hooks were added to the existing live builder; they delegate to its canonical recognition and compatibility functions. No second snap, placement, catalog, or registration system was created.
- Catalog entries are candidates only. Both catalog-level and per-wrapper registration flags remain false.

## Pilot snap validation

The pilot scene now contains:

- three connected wall pieces with two independently validated seams;
- three connected road pieces with two independently validated seams;
- one wall/sign attachment using `wall_prop_surface` and `prop_anchor`;
- the existing dedicated runtime QA camera and close material-review presets.

Normal-editor Godot 4.7 result: PASS.

- Pilot wrappers: `6 / 6`
- Wall/road seam joins: `4 / 4`
- Compatible sign attachment: `1 / 1`
- Gap/overlap delta: `0.0 m` for every tested seam
- Root scales: `1,1,1`

## Full validation

- Full normal-editor Godot 4.7 validation: PASS (`181 / 181`, `0` failures).
- Existing live-builder recognition: PASS (`181 / 181`).
- Structural socket compatibility/orientation/cardinal-yaw/elevation checks: PASS.
- Material binding validation: PASS (`0` unresolved or mismatched assets).
- Import/load validation: PASS (`0` failed imports or replacement loads).
- Purchased-source verification after generation: PASS (`483` files; no added, removed, or changed files).

## Repeatability

- The integrated full build was run repeatedly.
- `723` deterministic wrapper, pilot scene, material, catalog, mapping, and managed import files were SHA-256 compared.
- Added deterministic files: `0`.
- Removed deterministic files: `0`.
- Changed deterministic files: `0`.
- Full-manifest semantic match after excluding the audit timestamp: PASS.
- Timestamped audit reports are intentionally allowed to refresh.

## Locations

- Full manifest: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Full_Manifest.json`
- Builder candidates: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Catalog/Generated_Catalog_Candidates.json`
- Full Godot validation: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Full_Godot_Validation.json`
- Pilot manifest: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Pilot_Manifest.json`
- Pilot scene: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Scenes/Tests/STK_SCN_3DT_Cyberpunk_Downtown_IntakePilot.tscn`
- Pilot validation: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Pilot_Godot_Validation.json`
- Purchased-source verification: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Reports/Vendor_Source_Verification.json`
- Production output root: `res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek`

No purchased geometry was redesigned, resized, decimated, renamed, or overwritten. No Git commit or push was performed.
