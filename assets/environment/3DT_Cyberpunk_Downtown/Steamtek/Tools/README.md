# Steamtek Environment Intake

This folder contains the pack-specific configuration and helper scripts for
`3DT_Cyberpunk_Downtown`. The reusable intake engine lives at:

`tools/steamtek-environment-intake`

## Safest first run

Double-click `Launch_Steamtek_Environment_Intake.bat`, then choose:

1. `Dry-run pilot` to preview without writing production assets.
2. `Build/rerun pilot, then run technical validation`.
3. `Open pilot in normal Godot editor for F6 review`.
4. `Verify purchased-source hashes`.

The full-pack build is approval-gated. Do not run it until the pilot has been
opened in the normal Godot editor, run with F6, and visually approved.

In the pilot review, keys `1`-`7` select the overview and six close material-QA
views. `P` or `F12` captures the current view. Updated pilot screenshots are in
`Steamtek/Reports/Visual_QA`.

## What stays read-only

Treat every purchased file outside `Steamtek` as immutable, including FBX,
textures, PDFs, ZIPs, and any future Blender/GLB source. Godot-generated
`.import` sidecars are engine metadata, not purchased content; the pipeline
backs up each managed original once, extends that backup for later scopes, and
provides a hash-verified restore command.

Generated materials, scenes, derived textures, catalogs, and reports stay
under `Steamtek`. The one current derived texture combines the authoritative
Window A base-color and alpha maps; it does not replace either source image.

See `STEAMTEK_ASSET_INTAKE_GUIDE.md` for the complete beginner-friendly
workflow, recovery instructions, and steps for adding another pack.
