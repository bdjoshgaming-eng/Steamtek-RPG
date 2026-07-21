# STK_PROP_Table_Dining_Rect_01 QA

## Result

**PASS WITH WARNINGS**

- Source: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Table_Dining_Rect_01\STK_PROP_Table_Dining_Rect_01_Meshy.glb`
- Production GLB: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Table_Dining_Rect_01\staged_pipeline\STK_PROP_Table_Dining_Rect_01_ProductionCandidate.glb`
- Godot collision wrapper: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Table_Dining_Rect_01\staged_pipeline\STK_PROP_Table_Dining_Rect_01_ProductionCandidate.tscn`
- Scale contract: `1 Godot unit = 1 meter`
- Pivot contract: bottom center, floor contact at ground level

## Dimensions

Blender uses X width, Y depth, Z height. Godot imports this as X width, Z depth, Y height.

- Source bounds: `[1.899508, 0.913925, 0.732601]`
- Target bounds: `[2.4, 1.2, 0.75]`
- Exported bounds: `[2.4, 1.2, 0.75]`
- Exported minimum: `[-1.2, -0.6, 0.0]`
- Applied axis scale factors: `[1.263485, 1.313018, 1.02375]`

## Geometry

- Source mesh objects: `1`
- Source vertices: `17629`
- Source triangles: `18184`
- Exported mesh objects: `1`
- Exported vertices: `17901`
- Exported triangles: `18184`
- Vertices merged at tolerance: `8532`
- Loose vertices removed: `0`
- Loose edges removed: `0`
- Microscopic disconnected components removed: `0`
- Connected components preserved: `2`
- Boundary edges after cleanup: `96`
- Non-manifold edges after cleanup: `167`
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

- PASS: Production GLB exists — 39331948 bytes
- PASS: Dimensions match target within 2 mm — target [2.4, 1.2, 0.75], exported [2.4, 1.2, 0.75]
- PASS: Bottom-center pivot and ground contact — exported minimum Z 0.0 m
- PASS: Applied object transforms — {"STK_PROP_Table_Dining_Rect_01": {"location": [0.0, 0.0, 0.0], "rotation_euler": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}}
- PASS: No rig or animation — armatures [], actions []
- PASS: Material assignments preserved — source slots ['Material_0.001'], exported slots ['Material_0.001']
- PASS: Embedded texture payload preserved — source images {'Baked_Emit': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_BaseColor': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_MetallicRoughness': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}}, exported images {'Baked_Emit': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_BaseColor': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_MetallicRoughness': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}}
- PASS: UVs preserved — source 1, exported 1
- PASS: Triangle count remains near source — source 18184, exported 18184
- PASS: Zero-area faces removed — 0 zero-area faces
- PASS: Simplified collision wrapper exists — C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Table_Dining_Rect_01\staged_pipeline\STK_PROP_Table_Dining_Rect_01_ProductionCandidate.tscn
- PASS: Requested triangle budget — requested approximately 18184, exported 18184

## Warnings

- 167 non-manifold edges remain after conservative repair. They were preserved because automatic filling could alter visible frame openings, UVs, or silhouette.
- 96 boundary edges remain; review the production mesh visually before final promotion.
- 2 connected mesh components remain. No microscopic floating component met the safe-removal threshold; disconnected hard-surface details were retained.

## Notes

- Normals were recalculated consistently after conservative cleanup.
- Existing material assignments, texture-node references, and UV layers were retained through Blender import/export.
- The pipeline deliberately avoided aggressive decimation or automatic removal of meaningful disconnected trim pieces.
- Blender successfully re-imported the finished GLB. A normal Godot editor import remains a separate approval gate.
- Visual approval must still occur in the normal Godot editor/gameplay camera.
