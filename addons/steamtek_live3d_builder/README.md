# Steamtek Live3D Builder

This editor-only add-on provides a beginner-friendly placement dock for Steamtek exterior, street, and fully modular apartment-interior kits.

It is intentionally separate from `steamtek_modular_snap`, which serves the older Marker2D/pixel-lattice workflow. This add-on recognizes only:

- Module group: `steamtek_live3d_modular`
- Socket group: `steamtek_live3d_snap`
- Module metadata: `module_system = live3d_meter_v1`

It does not modify runtime scenes, C001, the camera contract, or the existing 2D modular add-on.

## Enable in Godot

1. Let Godot finish importing the new files.
2. Open **Project > Project Settings > Plugins**.
3. Enable **Steamtek Live3D Builder**.
4. The **Steamtek Live3D Builder** dock appears on the right side of the editor.

The add-on is enabled in the canonical project and validated with Godot 4.7 Compatibility. It has no dependency on the older modular snap workflow.

## Drag directly from the FileSystem

Enable **Auto Snap FileSystem / Viewport Drag** in the Builder dock. Drag any `live3d_meter_v1` modular scene from Godot's FileSystem into the 3D viewport and release it within 1 meter of a compatible Marker3D socket. The dropped module snaps automatically and the placement remains undoable. The same option also snaps an existing module after it is moved with the viewport gizmo. Disable the checkbox when free placement is preferred; **Snap Nearest** remains available for manual snapping.

## Beginner workflow

1. Open `SteamtekApartmentInteriorAssemblyBlank3D.tscn`.
2. Choose a module in the dock.
3. Click **Add First Module at Assembly Origin**.
4. Keep that module selected, choose the next module, and click `-X`, `+X`, `-Z`, `+Z`, or `+ Storey`.
5. Use **Rotate +90** to change the selected module's building axis.
6. For corner connectors, drag the selected piece within 1 meter of the intended socket and click **Snap Nearest**.
7. Use normal Godot Undo whenever necessary.

Placement buttons inherit the selected module's rotation. A facade rotated 90 degrees therefore continues along the other street axis without negative-scale mirroring.

The module list also includes the Street Kit road, intersection, sidewalk, curb, drain, alley, fence, ramp, corner, gate, lane-marked road, crosswalk, driveway cut, and alley-apron scenes. Straight and substitution modules use the same 2.4 m placement buttons. Use **Snap Nearest** for intersection edges, curb-to-road placement, sidewalk-to-curb placement, and authored corner connectors.

For an empty Street Kit workspace, open `SteamtekStreetAssemblyBlank3D.tscn`. The Builder places structural modules beneath its `Architecture` node; keep decorative props and lights in their named groups.

## Locked dimensions

- Exterior horizontal grid: 2.4 m
- Interior structural sub-grid: 1.2 m
- Furniture grid: 0.3 m
- Small-prop grid: 0.1 m
- Storey step: 3.2 m
- Root scale: `(1, 1, 1)`
- Rotation: Y-axis increments of 90 degrees

Street widths and height offsets remain owned by their scene contracts. The Builder never scales a street piece to make it fit.

## Apartment interior workflow

1. Open an interior assembly containing `Architecture`, `Furniture`, `Props`, and `Lighting` Node3D groups.
2. Build floor and wall structure on the 1.2 m profile.
3. Switch to the 0.3 m profile to place independent beds, tables, workbenches, lockers, seating, and storage.
4. Select a table, shelf, workbench, wall, or floor module that exposes a prop socket.
5. Choose an independent small prop such as a cup, book, or tool case and click **Add Chosen Object at Selected Surface Socket**.
6. Move, rotate, replace, or delete that prop without changing the furniture or any texture.

Visible clutter is never baked into a furniture texture. Hand-painted textures may contain wear, grime, seams, and material variation, but cups, books, tools, dishes, lamps, boxes, and other authored objects remain separate scenes with contact-point pivots.
