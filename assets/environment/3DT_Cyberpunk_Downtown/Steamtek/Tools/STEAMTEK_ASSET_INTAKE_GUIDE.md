# Steamtek Environment Asset Intake Guide

> Current Cyberpunk Downtown status: pipeline v1.0.2 rebuilt only the six-asset
> pilot and passes the strengthened Godot 4.7 technical validator with both seam
> deltas at 0 m. Normal-editor/F6 visual approval is still pending. No full-pack
> assets have been generated or registered.

## What this pipeline is for

This is Steamtek's reusable live-3D environment intake workflow. It is meant
for future purchased packs as well as `3DT_Cyberpunk_Downtown`.

The workflow:

1. Keeps purchased files untouched.
2. Probes and inventories the complete pack.
3. Resolves source material names to authoritative texture families.
4. Creates one shared Godot material per used family.
5. Creates reusable Steamtek wrapper scenes.
6. Adds collision according to gameplay purpose.
7. Creates traceable production names, pivots, and snap markers.
8. Writes mapping, hash, state, and validation reports.
9. Requires a representative pilot before full generation.
10. Keeps automated technical validation separate from visual approval.

The pipeline does not redesign or recolor purchased textures. Create future
Steamtek recolors as separate derived materials so the source reconstruction
remains inspectable and reversible.

## Read-only and generated-file boundaries

Treat every purchased file outside the pack's `Steamtek` folder as read-only,
including:

- `FBX`
- `Textures`
- `Original`
- Vendor archives and documents
- Any Blender, GLB, glTF, OBJ, or other source added later

Do not rename, move, overwrite, delete, or save conversions over those files.

Generated production files belong under:

`assets/environment/<Pack_ID>/Steamtek`

Godot `.import` files beside purchased assets are mutable engine metadata, not
purchased artistic content. The pipeline makes an append-only original-content
backup before changing a managed sidecar. It never overwrites an earlier
backup entry.

Do not manually alter `.godot/imported`. Godot owns that cache.

For Cyberpunk Downtown, the temporary Apartment Walls A PNG copies beside the
FBXs were already absent before intake. Only the authoritative maps under
`Textures/Apartment Walls A` are used.

## Requirements

- Godot 4.7 Stable
- Python 3.11 or newer
- Pillow for material families that supply a separate alpha map
- Blender 4.5 LTS for the read-only FBX probe

Configured executables for this pack:

- Godot: `C:\My Game\Godot_v4.7-stable_win64.exe`
- Blender: `C:\Program Files\Blender Foundation\Blender 4.5\blender.exe`

Install the Python dependency from the repository root:

```powershell
py -3 -m pip install -r "tools\steamtek-environment-intake\requirements.txt"
```

## Safest beginner workflow

### 1. Start with a dry run

Double-click:

`Steamtek\Tools\Launch_Steamtek_Environment_Intake.bat`

Choose `Dry-run pilot`.

The dry run lists planned assets, materials, output scenes, dimensions,
collision, pivots, sockets, and unresolved families. It performs no production
writes.

### 2. Build and technically validate the pilot

Choose `Build/rerun pilot, then run technical validation`.

The launcher safely rebuilds the six representative assets and runs the
validator in normal Godot 4.7. Repeated builds skip byte-identical production
outputs. Timestamped audit reports may refresh even when assets do not change.

The pilot includes:

- Apartment Walls A wall
- Multi-material road
- Transparent Window A
- Infrastructure pipe
- Crate
- Emissive sign

It also contains exact duplicate wall and road pairs for endpoint and seam
testing.

### 3. Perform the required visual review

Choose `Open pilot in normal Godot editor for F6 review`, or open:

`res://assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Scenes/Tests/STK_SCN_3DT_Cyberpunk_Downtown_IntakePilot.tscn`

Press F6 in the normal editor. The dedicated `QAReviewCamera` opens on a tight
orthographic overview at size `10.5 m`; imported asset scale remains unchanged.
Use keys `1` through `8` for Overview, Wall seam, Road seam, Crate, Window
front, Window rear, Pole, and Emissive sign.

Use `WASD` or the arrow keys to pan. Use the mouse wheel to zoom. Press `R` to
reset the active preset, `L` to toggle unobtrusive labels, `C` to toggle
collision debug drawing, and `P` or `F12` to save the current review frame.
The close presets isolate the relevant asset or seam pair so editor gizmos and
unrelated pilot pieces cannot obscure review. Automated review captures live
under `Steamtek/Reports/Visual_QA`.

The overview uses camera position `(18, 16, 18)`, target
`(0.077605, 0.874598, -0.149413)`, orthographic size `10.5`, and keep-height
aspect. Close presets use perspective FOVs from `38` to `45` degrees.

Check:

- No object is white from a missing material.
- Base-color textures face and align correctly.
- Normal maps produce outward detail instead of inverted dents.
- Road and concrete occupy the correct surfaces.
- Window alpha has no opaque black background.
- Transparent sorting is acceptable from intended camera angles.
- Sign emission is readable without excessive bloom or clipping.
- Materials remain matte and preserve the source's painted character.
- No unsupported gloss or metallic look was introduced.
- Every asset rests at Y = 0 with root scale `1, 1, 1`.
- The provisional +Z front direction is correct.
- Wall and road pairs meet cleanly at their displayed seams.
- Collision represents gameplay boundaries rather than visual detail.
- Scale is believable beside Steamtek characters and environments.

Automated checks prove loadability, hashes, transforms, UV0 presence, material
binding, collision geometry, socket endpoints, exact AABB seams, and repeated
fresh loads. They do not approve appearance, UV orientation, transparency
sorting, normal direction, artistic roughness, front direction, or gameplay
feel.

### 4. Verify purchased files

Choose `Verify purchased-source hashes`.

A passing result must show:

- `added: []`
- `removed: []`
- `changed: []`

If it fails, stop. Do not replace or force-refresh the baseline. Recover the
named purchased file from the original archive or backup.

### 5. Approve full-pack generation only after F6 review

From `C:\My Game\Steamtek-RPG`:

```powershell
$runner = "assets\environment\3DT_Cyberpunk_Downtown\Steamtek\Tools\Run_Steamtek_Environment_Intake.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action BuildFullApproved -ApproveFullPack
```

The switch is an explicit statement that the pilot passed normal-editor/F6
review. Without it, full-scope generation is refused.

A full build would still create review candidates. It would not automatically
approve them or register them with the Live3D Builder.

## Common commands

Set the launcher path once:

```powershell
$runner = "assets\environment\3DT_Cyberpunk_Downtown\Steamtek\Tools\Run_Steamtek_Environment_Intake.ps1"
```

Run both the Blender and normal-editor Godot source probes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action Probe
```

Refresh inventory, material mapping, and source verification:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action Inventory
```

Preview or build the pilot:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action DryRunPilot
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action BuildPilot
```

Regenerate only the combined pilot review scene after a camera/framing change:

```powershell
$config = "assets\environment\3DT_Cyberpunk_Downtown\Steamtek\Tools\intake_config.json"
$tool = "tools\steamtek-environment-intake\steamtek_environment_intake.py"
py -3 $tool --config $config regenerate-pilot-scene
```

Run validation or open the visual review separately:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action ValidatePilot
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action ReviewPilot
```

Verify purchased files and preview all 181 assets:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action Verify
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action PlanFull
```

Rebuild one configured pilot asset:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action RebuildAsset -Asset "SM_3DT_Crate.fbx"
```

Rebuild one full category after visual approval:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action RebuildCategory -Category "Pipes" -ApproveFullPack
```

Rebuild one non-pilot full-pack asset after visual approval:

```powershell
$config = "assets\environment\3DT_Cyberpunk_Downtown\Steamtek\Tools\intake_config.json"
$tool = "tools\steamtek-environment-intake\steamtek_environment_intake.py"
py -3 $tool --config $config build --scope full --asset "SM_3DT_Example.fbx" --approve-full-pack
```

Avoid `--force` during normal use. Content-aware generation already skips
unchanged production files.

## What each operation does

### Probe

`Probe` runs two controlled stages:

1. Blender reads every FBX without animation import or saving over the source.
2. Normal Godot 4.7 loads every imported FBX and records engine-authoritative
   bounds, material slots, surfaces, triangles, and load errors.

The current command is FBX-focused. A new non-FBX pack needs a tested source
probe or controlled derivative-conversion stage; it must not be silently
routed through FBX assumptions.

### Inventory

Inventory records:

- Source and generated file counts separately
- Geometry categories
- Mesh, vertex, triangle, material-slot, and multi-material counts
- Texture families and supplied map types
- Possible LOD, collision, decal, alpha, and emissive content
- Material-to-texture resolution method
- Vendor-source SHA-256 hashes

Common PNG, JPG/JPEG, TGA, WebP, TIFF, EXR, HDR, and DDS texture inputs are
discoverable. Conventional ORM and RMA suffixes are classified for reporting.
A pack that relies on packed channels still needs a reviewed channel strategy
before material generation.

### Dry run

Dry run selects assets and calculates deterministic outputs without generating
materials, scenes, or import changes.

Use it before a pilot, category rebuild, material-alias change, or full-pack
approval.

### Build

Build:

- Verifies immutable vendor files before production writes.
- Refuses build or verify when the baseline is absent; only `Inventory` can
  initialize a baseline after the complete download is confirmed.
- Rejects configured roots, tool paths, category paths, or scene paths that
  escape the pack, its source areas, or its reserved `Steamtek` output root.
- Stops on unresolved or ambiguous material families.
- Extends the import-sidecar backup before changing new sidecars.
- Generates shared external materials and required derived textures.
- Generates reusable wrapper scenes and selected collision.
- Generates manifests, mappings, catalog candidates, and run state.
- Refreshes selected catalog/mapping rows while preserving all unrelated canonical entries.

Full builds produce their own complete manifest. Selective builds use
run-scoped reports instead of truncating the canonical pilot state.

### Validate

The Godot validator checks:

- Manifest, wrapper metadata, and current source hashes
- Finite transforms and root scale
- UV0 presence and mesh performance totals
- Shared material use on every surface
- Grounded dimensions and bottom-center bounds
- Collision body type, shape type, size, center, enabled state, and layer
- Supported socket roles, group membership, endpoints, midpoint, and spacing
- Wall and road pair separation and AABB seam
- Repeated wrapper, source, and pilot loads with cache replacement

Its structured boundary warnings are intentional. Visual approval remains
human.

### Verify

Verify hashes every non-`.import` file outside `Steamtek`. This protects
current and future vendor extensions without relying on a narrow allowlist.

### Restore import metadata

If a managed Godot sidecar must be restored, close Godot first and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner -Action RestoreImportMetadata
```

The command restores only paths recorded in
`Reports/Import_Metadata_PrePilot.json` and verifies every restored SHA-256.
The backup is append-only: later full or category builds add newly managed
sidecars without replacing earlier originals.

After restoration, reopen the normal editor, allow imports to finish, and
rebuild the pilot if the production import policy is still wanted.

## Material resolution and generation

Every direct texture directory is a candidate family. Resolution uses:

1. Explicit aliases in `intake_config.json`
2. Normalized source-material and folder-name equality
3. Unique normalized token matching

Ambiguity stops the pipeline instead of guessing.

Current examples:

- `Apartment Windows A` to `Apartment Windows`
- `Seamless Concrete C.001` to `Seamless/Concrete C`
- `Seamless Road.001` to `Seamless/Road`
- `Windows B` to `Window B`

FBX material links are not authority for this pack. They contain stale
vendor-machine paths and omit many maps. Authoritative maps live under
`Textures`.

Shared `StandardMaterial3D` resources are stored under:

`Steamtek/Materials/Source_Reconstructed`

One resource is created per used family, not per mesh.

Window A supplies alpha separately, so the pipeline creates:

`Steamtek/Materials/Derived_Textures/STK_TEX_Window_A_BaseColorAlpha.png`

The family-specific derivative remaps the vendor's narrow 250-255 opacity
range to controlled glass-versus-frame alpha while preserving RGB. It uses
alpha depth pre-pass, two-sided rendering, opaque-only depth draw, and
AABB-centered sorting. The original Base Color and Alpha maps remain unchanged.

Signs C uses the source emission texture as a multiply mask at energy 0.45.
Glow stays disabled in the neutral technical QA scene.

Missing maps are not invented. `Seamless/Road` and
`Seamless/Concrete C` supply no AO, so their pilot materials omit AO.

## Scene, collision, and naming contracts

Generated wrappers:

- Reference the vendor FBX as an external `PackedScene`.
- Bind external shared materials by original source material name.
- Keep root scale at `1, 1, 1`.
- Keep the production root at a bottom-center pivot.
- Offset only the generated `Visuals` child.
- Record source path, source hash, dimensions, materials, collision, and status.
- Use +Z front and 90-degree yaw as provisional review contracts.
- Remain traceable through the source-to-production CSV.

Production prefixes:

- `STK_ARCH_`
- `STK_INFRA_`
- `STK_PROP_`
- `STK_MAT_`
- `STK_SCN_`

Pilot collision:

- Wall, road, window, crate: one `BoxShape3D` each
- Pipe and emissive sign: no collision

Complex categories marked `manual_review_no_collision` are intentionally left
for a reviewed simplified solution. They do not silently receive detailed
trimesh collision.

Catalog candidates use Builder-native `label`, `path`, `parent`, and `profile`
fields, but both file-level registration and every entry remain disabled.

## Scale, pivots, and modular snapping

Godot units are meters and Y is up.

The pilot proves exact AABB contact for:

- Wall pair: separation `2.190474 m`, seam delta `0.0 m`
- Road pair: separation `14.866685 m`, seam delta `0.0 m`

This does not prove one universal pack grid. Measured dimensions vary, and the
pack does not cleanly establish Steamtek's existing 1.2 m/2.4 m grid. Preserve
source scale; do not rescale every asset merely to force compatibility.

The current bottom-center, +Z front, yaw, and AABB-derived socket policies are
pilot contracts pending visual and category assembly review.

## Adding the next 3D Tudor pack

1. Place the complete untouched pack under
   `assets/environment/<New_Pack_ID>`.
2. Keep geometry, textures, archives, documents, and masters outside its
   `Steamtek` output folder.
3. Confirm the download is complete before establishing the hash baseline.
4. Copy the Cyberpunk Downtown pack configuration, launchers, and generic
   Blender probe into `<New_Pack_ID>/Steamtek/Tools`.
5. Update `pack_id`, roots, tool paths, import policy, aliases, category
   defaults, and pilot assets.
6. Inventory every available source format. Do not assume FBX is best.
7. Compare representative assets in the normal Godot editor.
8. If FBX remains selected, run the integrated probe and require zero errors.
9. Add a category default for every immediate geometry category.
10. Use only tested pivot, collision, and socket policies.
11. Select at least a wall, road/floor, doorway/window, infrastructure item,
    ordinary prop, and transparent/emissive asset.
12. Run `Probe`, `Inventory`, and `PlanFull`.
13. Resolve every ambiguity with an explicit alias.
14. Build only the pilot.
15. Press F6 in the normal editor and complete the visual checklist.
16. Fix reusable logic or configuration if the pilot fails; do not hand-patch
    generated scenes.
17. Verify vendor hashes.
18. Use explicit full approval only after visual approval.

If Blend, GLB, glTF, OBJ, or another format wins the comparison, add a
controlled read-only probe or separate derived conversion stage. Never save a
conversion over the vendor source.

## Recovering from errors

The tool reports controlled failures as:

`STEAMTEK_INTAKE_ERROR=...`

General recovery:

1. Stop and read the named asset, family, or path.
2. Do not delete, rename, or overwrite vendor files.
3. Do not use `--force` as a shortcut.
4. Run `Verify`.
5. Keep the reports for diagnosis.

Common cases:

- **Missing probe:** run `Probe` and confirm configured executable paths.
- **Ambiguous material:** add one explicit alias, then rerun inventory and dry
  run.
- **No asset matched:** use the exact FBX filename, relative path, or immediate
  category name.
- **Missing `.import`:** open the project normally, let Godot finish importing,
  then rerun.
- **Wrong material appearance:** fix the family resolver or shared-material
  generator, not every wrapper.
- **Wrong bounds or pivot:** compare the Blender and Godot source probes, then
  fix the reusable transform policy.
- **Missing source baseline:** confirm the purchased download is complete, then
  run `Inventory`; build and verify intentionally refuse to invent a baseline.
- **Source verification failure:** restore the named purchased file; do not
  replace the baseline.
- **Damaged managed sidecars:** use the verified restore command above.
- **Generated-output rollback:** use version control or remove only reviewed
  files under the exact pack `Steamtek` output area.

## Current Cyberpunk Downtown limitations

- FBX is provisional because it is the only local vendor geometry format.
- The vendor-referenced `3DT_Cyberpunk_Downtown_Pack.blend` is missing.
- A final Blend/FBX/derived-GLB comparison remains open.
- Seventy-nine static FBXs contain unrelated camera-animation data; the static
  import policy is pack-configured.
- Eleven normal filenames explicitly say OpenGL. Generic names still require
  visual direction confirmation.
- No authored source LOD or collision meshes were found.
- Two plural-named mask atlases under `Textures/Alphas` remain unclassified and
  require manual decal/sign review.
- All 298 purchased textures are 2048 × 2048.
- High-complexity caged pipes are optimization candidates, not automatic
  decimation targets.
- Catalog registration is disabled.
- Full-pack generation remains zero until the user approves the F6 pilot.
