# 3DT Cyberpunk Downtown Steamtek Intake Report

Status: pipeline v1.0.2 rebuilt only the six-asset pilot after its first visual
review. The strengthened Godot 4.7 validator passes with zero failures; wall and
road seam deltas are both 0 m. Seven updated material-QA screenshots were
rendered in the normal runtime. User visual approval is still pending, and
full-pack generation remains unauthorized.

The correction pass uses multiply emission at 0.45 for Signs C, a derived-only
alpha remap plus front/rear-safe transparency for Window A, corrected paired
normal/roughness import metadata, and a neutral AgX QA environment with glow and
auto exposure disabled. Purchased FBX and texture files were not modified.

## 1. Backup or Git safety step performed

A pre-change checkpoint was recorded in
`2026-07-23_Pre_Intake_Safety_Checkpoint.md`.

At the task boundary:

- Branch: `main`
- HEAD: `f05e51b8ebcdd2032b383f53105fdc7fbf4dae70`
- Existing dirty status entries: 414

Those unrelated changes were preserved. No reset, revert, commit, or push was
performed.

The pipeline also created:

- A 483-file immutable vendor SHA-256 baseline
- An append-only, original-content backup for managed Godot `.import` sidecars
- A verified restore command
- Generated outputs confined to the pack's `Steamtek` area

## 2. Source formats discovered

Locally available vendor content:

- 181 FBX geometry files
- 298 PNG textures
- 2 PDF documents
- 2 ZIP archives
- 479 pre-existing Godot `.import` sidecars
- 0 Blend files
- 0 GLB or glTF files
- 0 OBJ/MTL or DAE files

The `Blender` and `Original` folders are empty. The two ZIPs mirror the
extracted 181 FBXs and 298 PNGs; they do not provide a second geometry format.

The FBXs reference a missing vendor master:

`C:\Users\marcu\Documents\Blender\Cyberpunk Street\Cyberpunk Downtown Pack\3DT_Cyberpunk_Downtown_Pack.blend`

## 3. Source format selected

FBX is the provisional geometry authority because it is the only vendor
geometry format present locally.

This is not a final FBX-versus-Blend-versus-glTF decision. The authoritative
material inputs are the organized vendor texture folders, not imported FBX
material links.

## 4. Reason for selecting it

Blender 4.5.11 and Godot 4.7 both loaded 181/181 FBXs with zero source-probe
errors.

Cross-probe findings:

- Triangle counts match for all 181 assets.
- Material-slot-name sets match for all 181 assets.
- Blender XYZ dimensions map to Godot XZY within 0.001 m maximum.
- UV layers are present.
- FBXs store normals but no tangent/binormal layers; Godot generates tangents.

This validates geometry transport, scale conversion, names, and UV presence.
It does not approve appearance, UV orientation, intended pivots, front
direction, collision, transparency, emission, or gameplay scale.

FBX materials were rejected as production authority because all 176 unique
image references are absolute paths on the vendor author's computer. Only four
FBXs reference Base Color, none references AO, and the records are incomplete.
Steamtek therefore keeps FBX geometry immutable and reconstructs shared
external materials from `Textures`.

The final source-format choice remains open if the missing Blend becomes
available for a controlled Blend/FBX/derived-GLB comparison.

## 5. Folder structure created

Pack-specific generated work is organized under:

`assets/environment/3DT_Cyberpunk_Downtown/Steamtek`

Production-purpose areas:

- `Architecture`
- `Infrastructure`
- `Props`
- `Materials/Source_Reconstructed`
- `Materials/Derived_Textures`
- `Scenes/Architecture`
- `Scenes/Infrastructure`
- `Scenes/Props`
- `Scenes/Tests`
- `Catalog`
- `Tools`
- `Reports`

The reusable engine-wide core is:

`tools/steamtek-environment-intake`

An unused empty legacy `Materials/Apartment_walls_A` folder was removed.
Reports now contain `.gdignore` so Godot does not import CSV audit tables as
localization resources.

## 6. Automation tools created

Reusable core:

- `steamtek_environment_intake.py`
- `requirements.txt`
- `godot/probe_environment_sources.gd`
- `godot/steamtek_material_binding.gd`
- `godot/validate_environment_intake_pilot.gd`
- `godot/steamtek_intake_pilot_review.gd`

Pack-specific configuration and entry points:

- `intake_config.json`
- `blender/steamtek_blender_probe.py`
- `godot/steamtek_probe_imported_scenes.gd`
- `Run_Steamtek_Environment_Intake.ps1`
- `Launch_Steamtek_Environment_Intake.bat`

Supported behavior:

- Blender and normal-editor Godot source probing
- Source/generated inventory separation
- Full material-to-texture mapping
- Dry-run pilot and full planning
- Shared-material and wrapper generation
- Content-aware idempotent writes
- One-asset and category selection with canonical row refresh
- Fail-closed pre-write vendor verification; only inventory can initialize a
  missing baseline
- Pack/source/output/category/scene path-containment checks
- Append-only import-sidecar backups
- Verified sidecar restoration
- Scope-correct pilot, full, and selective manifests
- Builder-shaped but disabled candidate catalog
- Explicit full-pack approval gate
- Strengthened normal-Godot technical validation

The core accepts common texture source extensions and reports conventional ORM
and RMA packed-channel suffixes. A new pack that depends on packed channels
still requires a reviewed channel strategy before production material
generation.

## 7. Number of source assets discovered

181 FBX source assets:

- Doorways: 6
- Floor: 2
- Metal Panels: 7
- Metal Sheets: 11
- Pipes: 43
- Platform: 1
- Props: 20
- Railings: 3
- Road: 4
- Shelters: 4
- Signs: 21
- Steps: 4
- Trims: 21
- Wall Props: 8
- Walls: 13
- Windows: 13

Source totals:

- Blender mesh vertices: 69,682
- Godot expanded surface vertices: 197,815
- Triangles: 135,978
- Mesh objects: 181
- Multi-material meshes: 4 roads

The different vertex metrics reflect Blender mesh vertices versus Godot
expanded surface vertices; triangle counts agree.

## 8. Number of pilot assets processed

6 reusable pilot wrappers:

1. `STK_ARCH_Wall_Apartment_A_01`
2. `STK_ARCH_Road_01`
3. `STK_ARCH_Window_A_01`
4. `STK_INFRA_Pipe_01`
5. `STK_PROP_Crate_01`
6. `STK_PROP_Sign_Emissive_013`

The combined pilot additionally instances a duplicate wall and road to test
endpoint spacing and visible AABB seams.

## 9. Number of full-pack assets processed, if approved and completed

0 full-pack assets were processed.

A write-free full dry run successfully planned:

- 181 assets
- 52 actually used material families
- 0 unresolved families
- 0 duplicate production names or scene paths

Full processing remains intentionally blocked until the user visually approves
the pilot in the normal Godot editor with F6.

## 10. Number of shared materials created

7 external `StandardMaterial3D` resources:

- `STK_MAT_Apartment_Walls_A`
- `STK_MAT_Bins`
- `STK_MAT_Pipes`
- `STK_MAT_Seamless_Concrete_C`
- `STK_MAT_Seamless_Road`
- `STK_MAT_Signs_C`
- `STK_MAT_Window_A`

Every material is referenced. No per-mesh duplicate material was generated.

## 11. Number of `.tscn` scenes created

7:

- 6 reusable wrapper scenes
- 1 combined pilot review scene

The pilot scene contains 8 wrapper instances because the wall and road each
have a seam-test duplicate. Geometry remains referenced from vendor FBXs rather
than embedded or duplicated.

## 12. Number and type of collision shapes generated

4 `StaticBody3D` roots with one `BoxShape3D` each:

- Wall
- Road
- Window
- Crate

Pipe and emissive sign intentionally have no collision.

The strengthened validator confirms exact box size, center, enabled state,
body type, and collision layer.

## 13. Texture families resolved

Full source accounting:

- 58 texture folders/families discovered
- 185 source material-slot rows
- 52 families actually used by FBX slots
- 162 normalized-exact resolutions
- 23 explicit-alias resolutions
- 0 unresolved rows

Six folders are not referenced by FBX material slots and were not generated:

- `Alphas`
- `Seamless/Concrete A`
- `Seamless/Concrete B`
- `Seamless/Concrete D`
- `Seamless/Metal Rusted`
- `Seamless/Sidewalk`

Pilot families:

- `Apartment Walls A`
- `Bins`
- `Pipes`
- `Seamless/Concrete C`
- `Seamless/Road`
- `Signs C`
- `Window A`

Window A uses one clearly separated 2048 × 2048 RGBA BaseColor+Alpha
derivative. Its two vendor source maps remain unchanged.

## 14. Missing or unresolved textures

Unresolved source material slots: 0.

Supplied-map omissions are documented, not invented:

- `Seamless/Concrete C` has no AO.
- `Seamless/Road` has no AO.

Their materials omit AO.

Four conventional `_Alpha` families resolve automatically. Two plural-named
mask atlases under `Textures/Alphas` remain unclassified and unbound; they
require manual decal/sign review.

`Window C` contains a vendor file named
`T_3DT_Window_B_Roughness.png`. Its content differs from Window B's map and is
resolved through the Window C folder. This is a vendor naming anomaly, not a
missing texture.

## 15. Assets that failed

Final technical failures: 0.

Final validator result:

- Schema: `SteamtekEnvironmentPilotGodotValidation-2`
- Godot: 4.7 Stable
- Assets: 6
- Snap demonstrations: 2
- Failure count: 0
- Passed: true

Reusable-pipeline issues found during development were corrected centrally:

- Ambiguous `Sidewalk` resolution stopped safely before generation; an explicit
  alias now resolves it.
- A first-import dependency for the derived alpha texture was completed through
  the normal Godot importer.
- A roughly 1 mm Road 01 bounds discrepancy exposed Blender-to-Godot conversion
  drift; generated wrappers now use Godot-imported AABBs as engine authority.
- Five exploratory Sidewalk import sidecars were restored byte-for-byte.
- Godot CSV localization sidecars were isolated and removed.
- Missing vendor baselines now fail closed for build and verify; only explicit
  inventory can initialize one.
- Configured pack, source, output, tool, category, and scene paths are rejected
  if they escape their allowed roots.
- Selective rebuilds refresh their canonical catalog and mapping rows without
  truncating unrelated entries.

A final repeated pilot build compared the 15 generated production targets
(6 wrappers, 7 materials, 1 derived texture, and 1 pilot scene); 0 hashes
changed. A second normal-Godot validation also passed with 0 failures.

No vendor mesh received a manual per-asset patch.

## 16. Assets requiring manual review

All 6 pilot assets require normal-editor/F6 visual approval for:

- Base-color and UV orientation
- Generic normal-map direction
- Provisional +Z front direction
- Road material placement
- Window alpha and sorting
- Sign emission strength and bloom
- Matte versus unintended glossy response
- Silhouette and character-relative scale
- Collision gameplay usefulness
- Seam appearance beyond numerical AABB contact
- Steamtek art-direction fit

The three validator warnings explicitly preserve these boundaries.

## 17. Import warnings

Known warnings and decisions:

- 79 static FBXs contain the same unrelated 191-animation camera payload across
  eight categories.
- This pack is configured as static geometry; selected FBX animation import is
  disabled.
- Only the 6 pilot FBXs currently have that policy applied.
- Only 35 source texture sidecars and 1 derived texture sidecar currently have
  the pilot production settings.
- Eleven normal filenames explicitly identify OpenGL orientation; generic
  filenames still need visual confirmation.
- FBX material records contain stale vendor-machine paths.
- Godot has a pre-existing unrelated nested-project warning for
  `res://Steamtek-Character-Validation`.
- Validator warning: visual approval is required.
- Validator warning: UV0 presence does not prove UV orientation.
- Validator warning: repeated `CACHE_MODE_REPLACE` loads are not a true editor
  reimport.

There are no final validator errors.

## 18. Scale and modular-grid findings

Godot units are meters and Y is up. Wrapper roots use scale `1, 1, 1` and a
bottom-center production pivot.

Pilot X × Y × Z dimensions in meters:

- Wall: `2.190474 × 0.789717 × 0.233581`
- Road: `4.464783 × 0.123232 × 14.866685`
- Window: `4.693586 × 1.624604 × 0.249189`
- Pipe: `0.064857 × 4.607897 × 0.064857`
- Crate: `0.524496 × 0.651435 × 0.509540`
- Sign: `1.599921 × 1.088375 × 0.332493`

Automated pair results:

- Wall separation: `2.190474 m`; seam delta: `0.0 m`
- Road separation: `14.866685 m`; seam delta: `0.0 m`

This proves exact contact for those two generated pairs, not a universal pack
grid. The pack does not establish a single 1.2 m or 2.4 m increment, and
measured dimensions vary by category.

Bottom-center pivots, +Z front, 90-degree yaw, and AABB-derived sockets remain
provisional production contracts pending normal-editor and category assembly
review. No arbitrary rescale was applied.

## 19. Performance concerns

Pack-wide:

- 135,978 triangles
- 181 meshes
- 4 multi-material roads
- 298 purchased textures
- Every purchased texture is 2048 × 2048
- Worst-case RGBA8 source allocation: approximately 4.66 GiB before mipmaps
- No authored source LOD meshes
- No authored source collision meshes

Godot production imports use VRAM compression and mipmaps for managed pilot
textures, but platform budgets still need representative-scene measurement.

The highest-complexity caged pipes are approximately 12,304 triangles each.
They are LOD and placement-frequency candidates. No destructive decimation or
artistic geometry modification was performed.

Recommended later review:

- Platform-specific texture budgets
- Repeated 2K-family usage
- Draw calls in representative blocks
- Occlusion in dense street scenes
- Authored LODs for frequent complex assets
- Category collision and navigation tests

## 20. Exact instructions for running the pipeline again

From `C:\My Game\Steamtek-RPG`:

```powershell
$runner = "assets\environment\3DT_Cyberpunk_Downtown\Steamtek\Tools\Run_Steamtek_Environment_Intake.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action DryRunPilot
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action BuildPilot
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action Verify
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action PlanFull
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action ReviewPilot
```

`BuildPilot` also runs technical validation. In the opened normal Godot editor,
press F6 and complete the visual checklist.

After explicit visual approval:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action BuildFullApproved -ApproveFullPack
```

One pilot asset:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action RebuildAsset -Asset "SM_3DT_Crate.fbx"
```

One category after approval:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action RebuildCategory -Category "Pipes" -ApproveFullPack
```

Import-sidecar recovery:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action RestoreImportMetadata
```

## 21. Exact instructions for adding the next 3D Tudor pack

1. Put the complete untouched pack under `assets/environment/<New_Pack_ID>`.
2. Keep vendor geometry, textures, documents, archives, and masters outside its
   `Steamtek` folder.
3. Confirm the download is complete before establishing hashes.
4. Copy the pack configuration, launchers, and generic Blender probe into
   `<New_Pack_ID>/Steamtek/Tools`.
5. Update `pack_id`, roots, executable paths, source format, import policy,
   category defaults, aliases, and pilot assets.
6. Inventory all available formats; do not assume FBX wins.
7. Compare a wall, road/floor, structure, prop, transparent/emissive asset, and
   multi-material asset in normal Godot.
8. Add a controlled probe or derived conversion stage if the winning source is
   not FBX.
9. Run `Probe`, `Inventory`, and `PlanFull`.
10. Resolve every ambiguity with an explicit alias.
11. Build only the representative pilot.
12. Run technical validation.
13. Press F6 in the normal editor.
14. Fix reusable logic or configuration if the pilot fails.
15. Verify vendor hashes.
16. Use explicit full approval only after visual approval.

The reusable core remains in `tools/steamtek-environment-intake`; each pack
keeps its own configuration, generated library, and reports.

## 22. Files created, changed, or removed

Created:

- Reusable Python intake core and dependency file
- Four reusable Godot scripts
- Pack configuration, Blender probe, and representative Godot probe
- PowerShell and batch launchers
- Beginner guide, safety checkpoint, and this final report
- JSON/CSV source probes, inventory, material map, source mapping, state,
  manifest, validation, and hash reports
- 7 shared `.tres` materials
- 1 derived Window A RGBA texture
- 6 wrapper scenes
- 1 pilot scene
- 1 disabled Builder-shaped catalog-candidate file
- `Reports/.gdignore`

Modified mutable Godot metadata:

- Pilot-managed sidecars: 42 total
- FBX sidecars: 6
- Source texture sidecars: 35
- Derived texture sidecar: 1

The append-only backup contains 47 entries: the 42 current pilot-managed
sidecars plus the five restored Sidewalk exploratory entries. At final
inspection, 41 entries differ from their saved originals and 6 match exactly.

Removed during controlled cleanup:

- 20 unintended `.translation` files
- 2 report CSV `.import` sidecars
- 2 Python bytecode files
- The now-empty Python cache directory
- The unused empty `Apartment_walls_A` directory
- One unused generated Sidewalk material from the preliminary mapping test

No temporary Apartment Walls A copies were removed because none remained at
the task boundary. No vendor FBX, PNG, PDF, ZIP, Blend, GLB, glTF, OBJ, or
other purchased file was removed.

No unrelated project file was intentionally changed. Pre-existing
`project.godot` and other dirty-worktree changes were preserved.

## 23. Confirmation that original purchased files were not modified

Confirmed by final SHA-256 verification.

Baseline-controlled vendor files:

- 181 FBX
- 298 PNG
- 2 PDF
- 2 ZIP
- Total: 483

Verification:

- Added: 0
- Removed: 0
- Changed: 0
- Passed: true

The baseline protects every non-`.import` file outside `Steamtek`. Build and
verify fail closed if that baseline is absent; only an explicit inventory run
can establish it after the source download is confirmed complete.
`Steamtek/**` is generated output; `.import` files are mutable Godot metadata
and are separately backed up.

Original purchased geometry, textures, documents, and archives remain
unchanged. No commit or push was performed.
