# STK_PROP_CONTAINER_Maintenance_Crate_01 QA

## Result

**PASS — production intake complete; gameplay-lighting taste approval remains optional.**

- Source: `res://incoming/meshy_world_assets/STK_PROP_CONTAINER_Maintenance_Crate_01.glb`
- Production GLB: `res://assets/environment/live3d/models/industrial/meshy/STK_PROP_CONTAINER_Maintenance_Crate_01_Production.glb`
- Reusable scene: `res://scenes/environment/live3d/props/industrial/STK_PROP_CONTAINER_Maintenance_Crate_01.tscn`
- Scale contract: `1 Godot unit = 1 meter`
- Pivot contract: bottom center at the root origin
- Front contract: the central locking/vent face points toward local Godot `+Z`

## Dimensions and grounding

The source was normalized non-destructively to the requested production dimensions:

- Width (X): `1.10 m`
- Height (Y in Godot): `0.65 m`
- Depth (Z in Godot): `0.65 m`
- Final GLB bounds: `X -0.55 to +0.55`, `Y 0.00 to 0.65`, `Z -0.325 to +0.325`
- Ground contact: `PASS`; the lowest vertex is at `Y = 0.00 m`
- Production object transform: location `0,0,0`, rotation `0,0,0`, scale `1,1,1`

## Geometry

- Source mesh objects: `1`
- Production mesh objects: `1`
- Source triangles: `6,896`
- Production triangles: `6,896`
- Source Blender vertices: `9,531`
- Source UV layers: `1`
- Topology signature before processing: `9,531 vertices / 14,966 edges / 6,896 polygons / 6,896 triangles`
- Topology signature after processing: `9,531 vertices / 14,966 edges / 6,896 polygons / 6,896 triangles`
- Decimation, remeshing, simplification, mesh joining, normal recalculation, and silhouette editing: `none`

The GLB exporter may split render vertices at UV or normal boundaries, but it preserved the exact triangle and polygon topology.

## Materials and textures

- Material count: `1`
- Material name: `MAT_MaintenanceCrate_Source`
- Material edits: `none`; the source matte/low-satin PBR response was preserved
- Base color: `res://assets/environment/live3d/models/industrial/meshy/STK_PROP_CONTAINER_Maintenance_Crate_01_Production_Baked_BaseColor.png`
- Metallic/roughness: `res://assets/environment/live3d/models/industrial/meshy/STK_PROP_CONTAINER_Maintenance_Crate_01_Production_Baked_MetallicRoughness.png`
- Emission: `res://assets/environment/live3d/models/industrial/meshy/STK_PROP_CONTAINER_Maintenance_Crate_01_Production_Baked_Emit.png`
- Texture resolution: `4096 x 4096` for all three maps
- Texture payload: embedded in the production GLB and extracted beside it by Godot using the same clean paths
- Preserved appearance: base paint, weathering, vents, powered accents, corner guards, and central locking structure

## Collision and interaction

- Collision type: one simplified `BoxShape3D`
- Collision size: `1.06 x 0.61 x 0.61 m`
- Collision position: `Y = 0.305 m`
- Detailed render-mesh/trimesh collision: `not used`
- Interaction marker: `InteractionPoint` at `Vector3(0, 0.325, 0.38)`
- Loot marker: `LootSpawnPoint` at `Vector3(0, 0.36, 0)`
- Future hinge marker: `LidHingePoint` at `Vector3(0, 0.61, -0.285)`
- Empty `AnimationPlayer` included for a later authored lid-opening animation

## Lid status

The supplied GLB contains one combined mesh. The body and lid are **not** separate objects. No attempt was made to cut or separate the approved geometry. The scene records this limitation and reserves a rear hinge marker; an independently animated lid will require a future authored source with separate body and lid objects.

## Validation

- Blender 4.5 re-export: `PASS`
- Exact production dimensions: `PASS`
- Ground contact and bottom-center pivot: `PASS`
- Triangle preservation: `PASS`
- UV and material preservation: `PASS`
- Embedded camera count: `0`
- Embedded light count: `0`
- Embedded animation count: `0`
- Godot 4.7 normal-editor import: `PASS`
- Godot scene parse and preview generation: `PASS`
- Godot crate-specific errors in final validation log: `0`

The final editor log contains one unrelated existing warning that `res://Steamtek-Character-Validation` contains another `project.godot`; Godot ignores that nested project folder. It did not affect the crate import.

## Intake artifacts

- Deterministic intake script: `res://tools/live3d/process_maintenance_crate.py`
- Machine-readable audit: `res://incoming/meshy_world_assets/STK_PROP_CONTAINER_Maintenance_Crate_01_QA/STK_PROP_CONTAINER_Maintenance_Crate_01_Audit.json`
- Normal-editor log: `res://incoming/meshy_world_assets/STK_PROP_CONTAINER_Maintenance_Crate_01_QA/godot_import.log`
- QA renders: `res://incoming/meshy_world_assets/STK_PROP_CONTAINER_Maintenance_Crate_01_QA/previews/`
