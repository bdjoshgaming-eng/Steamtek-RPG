# Steamtek Studio v1.4.0

## Launch

Double-click `Launch_Steamtek_Studio.bat`.

Requirements:

- Windows 10 or 11
- Python 3.10 or newer
- Pillow (`py -m pip install Pillow`)

## Included

- Asset dashboard and portable SQLite database
- Asset editing, deletion, approval, and production status
- Kit progress tracking
- JSON and CSV export
- Source-sheet cutter with alpha trim and padding
- Automatic project asset discovery
- Portable `res://` paths for Godot files
- Automatic matching of source PNG, production PNG, and `.tscn` scene by asset ID
- Strict `SMV1_` and `SMV2_` modular apartment support
- Modular Intake launcher for converting outside wall renders into staged,
  snappable Modular v2 candidates with generated QA scenes
- Searchable Godot **Steamtek Modular Assets** dock for adding approved modules
  directly to a clean construction workspace
- Manifest-driven batch intake and Blender family builds so related assets are
  generated together instead of through repeated one-at-a-time setup

## Project scanning

Studio scans the Godot project automatically when it starts. Click `Scan Project`
on the Assets page to refresh it manually.

The scan searches:

```text
<project>/assets/**/*.png
<project>/scenes/**/*.tscn
```

Recognized IDs include `P001`, `B001`, `G001`, `FX001`, `SMV1_W001`,
`SMV1_FE001`, `SMV2_W001`, `SMV2_G001`, and the other strict modular families.

The scanner:

- creates missing database records;
- updates discovered source, production, and scene paths;
- preserves existing status, notes, approvals, and testing flags;
- assigns `SMV1_` and `SMV2_` assets to their matching modular kit;
- never deletes files or database records.

Use `Find Missing` separately when you want to review records whose files were
removed from disk.

## Portable database

When installed inside `<Godot project>/tools/steamtek-studio`, the database is
stored at `<Godot project>/.steamtek-studio/studio.db`. Commit that database if
you want the same Studio records available on every PC.
