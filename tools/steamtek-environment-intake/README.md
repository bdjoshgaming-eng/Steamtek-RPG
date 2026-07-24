# Steamtek Environment Intake Core

This tool is the reusable engine-wide intake core for purchased or licensed
3D environment packs. Pack-specific configuration and generated production
assets stay inside each pack's `Steamtek` output directory.

The current production test case is:

`assets/environment/3DT_Cyberpunk_Downtown`

## Safety model

- Vendor `.fbx`, `.png`, `.pdf`, `.zip`, `.blend`, `.glb`, `.gltf`, and
  `.obj` files are immutable inputs.
- Godot `.import` sidecars are mutable engine-generated metadata. Originals
  are backed up append-only before first management, can be restored with a
  verified command, and are excluded from the immutable source hash.
- Generated materials, derived textures, scenes, catalogs, and reports stay
  under the pack's `Steamtek` directory. Configured source, tool, category, and
  scene paths are containment-checked before work begins.
- Build and verify fail closed if the immutable source baseline is missing;
  only the explicit inventory command can initialize a new baseline.
- Selective rebuilds merge refreshed selected rows into the canonical catalog
  and source mapping without truncating unrelated entries.
- Full-pack generation is refused unless `--approve-full-pack` is supplied.
- Builder registration remains disabled until normal-editor/F6 visual
  approval.

## Dependencies

- Python 3.11 or newer
- Pillow, only for families with a separate alpha map
- Godot 4.7 Stable for source probing and validation
- Blender 4.5 LTS for the read-only FBX source probe

Install the Python dependency with:

```powershell
py -3 -m pip install -r tools/steamtek-environment-intake/requirements.txt
```

## Core commands

Run from the repository root:

```powershell
$config = "assets/environment/3DT_Cyberpunk_Downtown/Steamtek/Tools/intake_config.json"
$tool = "tools/steamtek-environment-intake/steamtek_environment_intake.py"

py -3 $tool --config $config probe
py -3 $tool --config $config inventory
py -3 $tool --config $config dry-run --scope pilot
py -3 $tool --config $config build --scope pilot
py -3 $tool --config $config regenerate-pilot-scene
py -3 $tool --config $config validate
py -3 $tool --config $config validate-full
py -3 $tool --config $config review
py -3 $tool --config $config build --scope pilot --asset "SM_3DT_Crate.fbx"
py -3 $tool --config $config dry-run --scope full --category Pipes
py -3 $tool --config $config verify
py -3 $tool --config $config restore-import-metadata
```

The following command is deliberately blocked until the pilot is visually
approved:

```powershell
py -3 $tool --config $config build --scope full --approve-full-pack
```

## Pipeline components

- `steamtek_environment_intake.py`: pre-write source verification, inventory,
  mapping, source hashes, dry-run, idempotent generation, selective rebuilds,
  append-only sidecar backup/restore, scoped manifests, normal-editor Godot
  orchestration, and approval gating.
- `godot/probe_environment_sources.gd`: engine-authoritative imported bounds,
  materials, surface counts, and animation inventory.
- `godot/steamtek_material_binding.gd`: shared external material binding by
  original source material name.
- `godot/validate_environment_intake_pilot.gd`: technical validation of
  source hashes, finite transforms, UV0 presence, performance, materials,
  pivots, exact collision, socket endpoints, snap/seam pairs, repeated fresh
  loads, and the pilot scene.
- `godot/steamtek_intake_pilot_review.gd`: dedicated QA camera, tight overview,
  WASD/arrow-key pan, mouse-wheel zoom, and eight isolated review presets for
  the visible pilot.

`regenerate-pilot-scene` is the narrow correction path for review-scene
framing. It requires the complete six-asset pilot and rewrites only the
combined pilot scene; it does not rebuild materials, wrappers, catalogs,
manifests, or full-pack assets.

The tools never mark a candidate production-ready. That status requires the
normal Godot editor and an explicit visual approval.
