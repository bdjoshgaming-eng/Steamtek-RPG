# STK_PROP_Workstation_A QA

## Result

**PASS WITH WARNINGS**

The production asset passed dimensional, transform, UV, material, texture-payload, triangle-budget, rig/animation, pivot, and conservative mesh-cleanup validation. A normal Godot editor import and gameplay-camera visual review remain the final approval gate.

## Files

- Raw intake source: `res://incoming/meshy_apartment_assets/APT_Computer/STK_PROP_Workstation_A_Meshy.glb`
- Validated intake export: `res://incoming/meshy_apartment_assets/APT_Computer/STK_PROP_Workstation_A_Production.glb`
- Installed production GLB: `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Workstation_A_Production.glb`
- Installed Godot scene: `res://scenes/environment/live3d/props/apartment_interior/STK_PROP_Workstation_A.tscn`
- Raw source remains in intake and was not copied into the production asset folder.

## Dimensions, origin, and orientation

Blender uses X width, Y depth, and Z height. Godot imports the GLB as X width, Z depth, and Y height.

- Source bounds: `2.575125 × 1.454798 × 1.500000 m`
- Final production bounds: **`2.100000 × 0.850000 × 1.500000 m`**
- Applied scale factors: `0.815494 × 0.584273 × 1.000000`
- Production root location: `0,0,0`
- Production root rotation: `0,0,0`
- Production root scale: `1,1,1`
- Final minimum: `-1.05, -0.425, 0.0`
- Final maximum: `1.05, 0.425, 1.5`
- Floor contact: **PASS**, lowest point is exactly `Z = 0` in Blender
- Pivot: **PASS**, bottom center of complete workstation
- Orientation: upright; Blender `+Y` maps to the project's Godot `+Z` front direction
- Collision work-surface top: `0.80 m`
- The render mesh is a single unlabelled mesh, so the exact visual work-surface height still requires normal-editor visual confirmation.

## Geometry

- Source mesh objects: `1`
- Final mesh objects: `1`
- Source vertices reported by GLB import: `23,529`
- Conservative cleaned working-mesh vertices: `8,784`
- Final exported GLB vertices after UV/normal seam expansion: **`23,779`**
- Source triangles: `17,925`
- Final triangles: **`17,925`**
- Triangle-budget variance: `0`
- Connected components preserved: `5`
- Zero-area faces: `0`
- Loose vertices removed: `0`
- Loose edges removed: `0`
- Microscopic components removed: `0`
- Vertices welded at conservative tolerance: `14,745`
- Weld tolerance: approximately `0.00000021 m`

No aggressive remesh or decimation was performed. The monitor housings, support arms, overhead gantry, keyboard/control surface, cabinet pedestals, conduit shapes, hard-surface panels, silhouette, and open center leg space were preserved.

## Normals and manifold checks

- Face normals were recalculated consistently after cleanup.
- Zero-area faces: **PASS**, none remain.
- Boundary edges remaining: `90`
- Non-manifold edges remaining: `192`
- Connected components remaining: `5`

The remaining open/non-manifold edges and disconnected components were not filled or deleted automatically because that could close intentional frame openings, damage UVs, alter monitor/gantry details, or change the silhouette. These are visual-review warnings rather than pipeline failures.

## Materials, UVs, and textures

- Material count: **`1`**
- Material: `Material_0.001`
- UV layers: **`1`**
- Embedded texture count: **`3`**
- `Baked_BaseColor`: `4096 × 4096`, sRGB, linked to Principled BSDF Base Color
- `Baked_Emit`: `4096 × 4096`, sRGB, linked to Principled BSDF Emission Color
- `Baked_MetallicRoughness`: `4096 × 4096`, Non-Color; blue channel drives Metallic and green channel drives Roughness
- Dedicated normal map: **not present in the source GLB**
- Emission connection: **PASS in the validated GLB**
- Base color, emission, and packed metallic/roughness payloads remained embedded and preserved through export/reimport.
- The source material imports as dithered. Confirm monitor-edge appearance in the normal Godot editor.
- Final Godot emission intensity and screen readability require visual confirmation after the editor imports the installed production GLB.

## Rig and animation

- Source armatures: `0`
- Source actions: `0`
- Final armatures: `0`
- Final actions: `0`
- Cameras, lights, and animation players in the Godot wrapper: `0`

## Simplified static collision

The detailed render mesh is not used for collision. The Godot wrapper contains one `StaticBody3D` with **four `BoxShape3D` collision nodes**:

1. Left cabinet pedestal: `0.48 × 0.78 × 0.75 m`
2. Right cabinet pedestal: `0.48 × 0.78 × 0.75 m`
3. Desktop: `2.10 × 0.12 × 0.85 m`
4. Overhead gantry: `2.00 × 0.18 × 0.18 m`

The center leg space remains open below the desktop. Monitor assemblies intentionally have no extra collision because they do not affect normal player navigation.

## Repairs performed

- Removed rig/animation data gate (none was present).
- Detached imported hierarchy while preserving world transforms.
- Applied rotation and scale.
- Scaled to the exact production dimensions.
- Conservatively welded coincident vertices.
- Checked and removed loose geometry where present; none was found.
- Checked microscopic disconnected debris; none met the safe-removal threshold.
- Recalculated face normals.
- Set the bottom-center pivot and grounded all floor-contact points.
- Preserved UVs, material assignment, embedded textures, and triangle count.
- Exported the production GLB and successfully reimported it in Blender.
- Created workstation-specific open-center box collision and modular placement sockets.

## Remaining warnings

- `192` non-manifold edges remain after conservative repair.
- `90` boundary edges remain.
- `5` connected mesh components remain.
- No dedicated normal map was supplied.
- Normal Godot editor import and gameplay-camera visual approval are still required.
