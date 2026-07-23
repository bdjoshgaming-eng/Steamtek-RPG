import json
import sys
from pathlib import Path

import bpy


if "--" not in sys.argv:
    raise SystemExit("Expected: -- <input.glb> <report.json>")

input_path, report_path = sys.argv[sys.argv.index("--") + 1 :]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=input_path)

objects = []
armatures = []
for obj in bpy.data.objects:
    objects.append(
        {
            "name": obj.name,
            "type": obj.type,
            "location": list(obj.location),
            "rotation_mode": obj.rotation_mode,
            "scale": list(obj.scale),
            "dimensions": list(obj.dimensions),
            "parent": obj.parent.name if obj.parent else None,
        }
    )
    if obj.type == "ARMATURE":
        armatures.append(
            {
                "object_name": obj.name,
                "data_name": obj.data.name,
                "bone_count": len(obj.data.bones),
                "bones": [bone.name for bone in obj.data.bones],
            }
        )

actions = []
for action in bpy.data.actions:
    try:
        fcurve_count = len(action.fcurves)
    except AttributeError:
        fcurve_count = None
    actions.append(
        {
            "name": action.name,
            "frame_range": list(action.frame_range),
            "frame_count": int(round(action.frame_range[1] - action.frame_range[0] + 1)),
            "fcurve_count": fcurve_count,
            "users": action.users,
        }
    )

report = {
    "input": str(Path(input_path).resolve()),
    "objects": objects,
    "armatures": armatures,
    "actions": actions,
}

Path(report_path).write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
