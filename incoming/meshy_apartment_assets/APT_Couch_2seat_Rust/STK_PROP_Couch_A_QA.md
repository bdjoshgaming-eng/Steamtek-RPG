# STK_PROP_Couch_A QA

## Result

**PASS WITH WARNINGS**

- Source: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_2seat_Rust\STK_PROP_Couch_A_Meshy.glb`
- Production GLB: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_2seat_Rust\STK_PROP_Couch_A_Production.glb`
- Godot collision wrapper: `C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_2seat_Rust\STK_PROP_Couch_A_Production.tscn`
- Scale contract: `1 Godot unit = 1 meter`
- Pivot contract: bottom center, floor contact at ground level

## Dimensions

Blender uses X width, Y depth, Z height. Godot imports this as X width, Z depth, Y height.

- Source bounds: `[1.773323, 0.890785, 0.9]`
- Target bounds: `[2.1, 0.9, 0.9]`
- Exported bounds: `[2.1, 0.9, 0.9]`
- Exported minimum: `[-1.05, -0.45, 0.0]`
- Applied axis scale factors: `[1.184218, 1.010345, 1.0]`

## Geometry

- Source mesh objects: `1`
- Source vertices: `10317`
- Source triangles: `9444`
- Exported mesh objects: `1`
- Exported vertices: `10529`
- Exported triangles: `9444`
- Vertices merged at tolerance: `5577`
- Loose vertices removed: `0`
- Loose edges removed: `0`
- Microscopic disconnected components removed: `0`
- Connected components preserved: `5`
- Boundary edges after cleanup: `57`
- Non-manifold edges after cleanup: `91`
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

- PASS: Production GLB exists — 38688116 bytes
- PASS: Dimensions match target within 2 mm — target [2.1, 0.9, 0.9], exported [2.1, 0.9, 0.9]
- PASS: Bottom-center pivot and ground contact — exported minimum Z 0.0 m
- PASS: Applied object transforms — {"STK_PROP_Couch_A": {"location": [0.0, 0.0, 0.0], "rotation_euler": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}}
- PASS: No rig or animation — armatures [], actions []
- PASS: Material assignments preserved — source slots ['Material_0.001'], exported slots ['Material_0.001']
- PASS: Embedded texture payload preserved — source images {'Baked_Emit': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_BaseColor': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_MetallicRoughness': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}}, exported images {'Baked_Emit': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_BaseColor': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}, 'Baked_MetallicRoughness': {'size': [4096, 4096], 'packed': True, 'source': 'FILE', 'filepath': ''}}
- PASS: UVs preserved — source 1, exported 1
- PASS: Triangle count remains near source — source 9444, exported 9444
- PASS: Zero-area faces removed — 0 zero-area faces
- PASS: Simplified collision wrapper exists — C:\My Game\Steamtek-RPG\incoming\meshy_apartment_assets\APT_Couch_2seat_Rust\STK_PROP_Couch_A_Production.tscn
- PASS: Requested triangle budget — requested approximately 9444, exported 9444

## Warnings

- 91 non-manifold edges remain after conservative repair. They were preserved because automatic filling could alter visible frame openings, UVs, or silhouette.
- 57 boundary edges remain; review the production mesh visually before final promotion.
- 5 connected mesh components remain. No microscopic floating component met the safe-removal threshold; disconnected hard-surface details were retained.

## Notes

- Normals were recalculated consistently after conservative cleanup.
- Existing material assignments, texture-node references, and UV layers were retained through Blender import/export.
- The pipeline deliberately avoided aggressive decimation or automatic removal of meaningful disconnected trim pieces.
- Blender successfully re-imported the finished GLB. A normal Godot editor import remains a separate approval gate.
- Visual approval must still occur in the normal Godot editor/gameplay camera.
