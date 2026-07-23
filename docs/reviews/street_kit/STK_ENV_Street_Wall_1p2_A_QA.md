# STK_ENV_Street_Wall_1p2_A Production QA

- Production GLB: `res://assets/environment/live3d/models/street_kit/STK_ENV_Street_Wall_1p2_A_Production_v15.glb`
- Reusable scene: `res://scenes/environment/live3d/kits/street/STK_ENV_Street_Wall_1p2_A.tscn`
- Three-module test: `res://scenes/environment/live3d/qa/STK_ENV_Street_Wall_1p2_A_ThreeModuleTest.tscn`
- Blender master: `res://blender/live3d/street/STK_ENV_Street_Wall_1p2_A.blend`

## Validated production values

- Bounds: 1.200 m wide x 3.200 m high x 0.160 m deep
- Pivot: bottom center
- Root scale: 1,1,1
- Godot visible face: +Z
- Triangle count: 2,464
- Materials: 5
- Collision: one exact 1.2 x 3.2 x 0.16 m BoxShape3D
- Horizontal socket role: `facade_horizontal`
- Snap points: X -0.6 m and +0.6 m

## Material construction

The brick field is a recessed flat surface. It does not use individually modeled bricks. Its PBR set contains albedo, normal, roughness, and AO maps derived from the approved front reference. The finishing pass darkens the brick palette, adds restrained brick-to-brick variation, improves dark mortar readability, and layers subtle soot, water staining, dampness, and bottom-weighted grime without introducing glossy surfaces.

Blackened-steel structural pieces use a separate gunmetal PBR set with albedo, normal, roughness, and AO maps. Restrained edge wear and localized rust emphasize seams, corners, bolts, and lower areas. The existing maintenance panel and vent grilles use coordinated material variants to improve depth and grime readability while preserving their geometry, placement, and size.

The final readability adjustment raises ordinary brick midtones by approximately 12.5%, lifts the blackened-gunmetal midtones without turning the steel gray, and gives the vent trim a modest additional lift. Bottom-weighted dampness, grime, soot, rust, roughness, normals, UV scale, and edge wear are preserved.

No geometry, object transforms, UVs, hierarchy, pivot, snap points, collision, or dimensions changed from the validated v13 production asset. The v15 GLB is a material-only finishing export with the same 2,464-triangle geometry.

## Lighting readability validation

- Neutral white: brick edges and mortar are clearly separated; side rails, top trim, lower panel, seams, rivets, and vent louvers remain visible.
- Dim alley: brick courses and the complete steel silhouette remain readable; lower grime stays dark while the maintenance panel and both vents remain distinguishable.
- Cyan and magenta accents: colored highlights preserve brick relief, frame separation, panel depth, and vent-louver definition without emissive material or permanent colored lighting.

## Modular validation

Three instances were placed at X -1.2 m, 0 m, and +1.2 m under neutral alley lighting. The combined span is 3.6 m. Calculated gap is 0.0 m and calculated overlap is 0.0 m. The test shows matching material scale, consistent UV mapping, no material discontinuities within a module, and no unintended texture-scale change between instances. Structural collision does not extend beyond the module bounds.

Godot 4.7 imported the v15 GLB and loaded the three-module QA scene successfully.
