# STK_PROP_Couch_L4_Left QA

## Result

**PASS WITH WARNINGS**

- Source: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_L4_Left\APT_Couch_L4_Left.glb`
- Production GLB: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_L4_Left\staged_pipeline\STK_PROP_Couch_L4_Left_ProductionCandidate.glb`
- Godot collision wrapper: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_L4_Left\staged_pipeline\STK_PROP_Couch_L4_Left_ProductionCandidate.tscn`
- Scale contract: `1 Godot unit = 1 meter`
- Pivot contract: bottom center, floor contact at ground level

## Dimensions

Blender uses X width, Y depth, Z height. Godot imports this as X width, Z depth, Y height.

- Source bounds: `[1.895945, 1.310375, 0.650512]`
- Target bounds: `[3.2, 1.8, 0.9]`
- Exported bounds: `[3.2, 1.8, 0.9]`
- Exported minimum: `[-1.6, -0.9, 0.0]`
- Applied axis scale factors: `[1.687813, 1.373652, 1.383526]`

## Geometry

- Source mesh objects: `1`
- Source vertices: `15579`
- Source triangles: `18455`
- Exported mesh objects: `1`
- Exported vertices: `16566`
- Exported triangles: `18455`
- Vertices merged at tolerance: `6346`
- Loose vertices removed: `0`
- Loose edges removed: `0`
- Microscopic disconnected components removed: `0`
- Connected components preserved: `1`
- Boundary edges after cleanup: `55`
- Non-manifold edges after cleanup: `93`
- Zero-area faces after cleanup: `0`

Disconnected components larger than the microscopic threshold were preserved because they may be intentional hard-surface frame details.

## Materials and UVs

- Source materials: `Material_0.001`
- Exported materials: `Material_0.001`
- Source UV layers: `1`
- Exported UV layers: `1`
- Exported embedded/referenced images: `3`

## Rig and animation

- Source armatures removed: `0`
- Source actions removed: `0`
- Exported armatures: `0`
- Exported actions: `0`

## Collision

The production GLB contains render geometry only. The companion Godot wrapper implements four simplified box shapes:

- One full footprint/base box
- One rear/backrest box
- One left arm box
- One right arm box

The detailed render mesh is not used for physics collision.

## Validation checks

- PASS: Production GLB exists — 37573420 bytes
- PASS: Dimensions match target within 2 mm — target [3.2, 1.8, 0.9], exported [3.2, 1.8, 0.9]
- PASS: Bottom-center pivot and ground contact — exported minimum Z 0.0 m
- PASS: Applied object transforms — {"STK_PROP_Couch_L4_Left": {"location": [0.0, 0.0, 0.0], "rotation_euler": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}}
- PASS: No rig or animation — armatures [], actions []
- PASS: Material assignments preserved — source slots ['Material_0.001'], exported slots ['Material_0.001']
- PASS: Embedded texture payload preserved — source images {'Baked_Emit': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_BaseColor': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_MetallicRoughness': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}}, exported images {'Baked_Emit': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_BaseColor': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_MetallicRoughness': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}}
- PASS: UVs preserved — source 1, exported 1
- PASS: Triangle count remains near source — source 18455, exported 18455
- PASS: Zero-area faces removed — 0 zero-area faces
- PASS: Simplified collision wrapper exists — C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_L4_Left\staged_pipeline\STK_PROP_Couch_L4_Left_ProductionCandidate.tscn
- PASS: Requested triangle budget — requested approximately 19000, exported 18455

## Warnings

- 93 non-manifold edges remain after conservative repair. They were preserved because automatic filling could alter visible frame openings, UVs, or silhouette.
- 55 boundary edges remain; review the production mesh visually before final promotion.

## Notes

- Normals were recalculated consistently after conservative cleanup.
- Existing material assignments, texture-node references, and UV layers were retained through Blender import/export.
- The pipeline deliberately avoided aggressive decimation or automatic removal of meaningful disconnected trim pieces.
- Blender successfully re-imported the finished GLB. A normal Godot editor import remains a separate approval gate.
- Visual approval must still occur in the normal Godot editor/gameplay camera.
