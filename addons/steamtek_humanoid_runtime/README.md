# Steamtek Humanoid Runtime

This addon sits beside the Meshy Godot plugin. Meshy creates/imports the model and animations; this addon enforces Steamtek's runtime contract.

## Required contract

- One canonical `Skeleton3D` per humanoid.
- Imported Meshy actions are normalized in Blender to `STK_IDLE`, `STK_WALK`, and other `STK_*` names.
- Jackets, shirts, pants, boots, and gloves must already be skinned to the canonical bone names.
- Helmets, weapons, and backpacks use `BoneAttachment3D` sockets.
- Model root scale stays `(1, 1, 1)` in Godot.

The equipment controller intentionally rejects an unweighted clothing mesh. Pointing a mesh at a skeleton does not create skin weights.

