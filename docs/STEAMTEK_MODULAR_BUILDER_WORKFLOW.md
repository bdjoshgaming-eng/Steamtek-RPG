# Steamtek Modular Builder Workflow

## Goal

The project supplies approved, reusable, snap-compatible assets. The level
designer decides the apartment footprint, alley direction, street layout,
lighting, and prop placement.

## Start a new construction scene

1. Open `scenes/tools/Steamtek_Modular_BuildWorkspace.tscn`.
2. Immediately use **Save As** and create the actual level scene.
3. Open the **Steamtek Modular Assets** dock in Godot.
4. Filter by Walls, Roofs, Foundations, Cornices, Fire Escapes, Ground, or Props.
5. Double-click an asset or select it and press **Add Selected**.
6. Drag the new module near a compatible socket and release it.

The editor plugin snaps compatible sockets automatically. The toolbar also
provides **Steamtek Snap: ON/OFF**, **Snap Selected**, and
**Snap Selected to Grid** for the shared 64x32 isometric lattice.

The clean template organizes additions under GroundModules, Architecture,
Props, Characters, LightingAndEffects, and Gameplay. It contains no authored
level layout.

## Fast asset production

### Finished PNG family

1. Copy `tools/modular-intake/batch_manifest.example.json`.
2. Add every reviewed family member with its source, ID, name, and profile.
3. Set approved entries to `"enabled": true`.
4. Drag the manifest onto
   `tools/modular-intake/Launch_Steamtek_Modular_Batch.bat`.

The batch preflights every entry before writing, builds all staged candidates,
creates their reusable scenes and QA scenes, and writes one batch report. It
does not promote candidates automatically.

### Deterministic Blender family

1. Copy `blender/scripts/batch_builders.example.json`.
2. List related deterministic builder scripts and enable them.
3. Drag the manifest onto
   `blender/scripts/Launch_Steamtek_Blender_Batch.bat`.

All builders run inside one Blender 4.5 process, avoiding repeated startup and
manual clicking while retaining each builder's locked render contract.

## Approval boundary

Batching accelerates generation; it does not weaken quality control. Review a
family together at gameplay scale, reject systemic errors across the batch,
and promote only mechanically valid, visually compatible candidates. Run
`python tools/validate_modular_v2.py` after every promotion batch.
