import json
import sys
from pathlib import Path

import bpy


if "--" not in sys.argv:
    raise SystemExit(
        "Expected: -- <production.glb> <new_merged.glb> <comparison.json>"
    )

production_path, merged_path, report_path = sys.argv[sys.argv.index("--") + 1 :]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=production_path)

production_armature = next(
    obj
    for obj in bpy.data.objects
    if obj.type == "ARMATURE" and obj.name.startswith("STK_HERO")
)
production_run = bpy.data.actions["STK_RUN"]

bpy.ops.import_scene.gltf(filepath=merged_path)

new_armature = next(
    obj
    for obj in bpy.data.objects
    if obj.type == "ARMATURE" and obj != production_armature
)
new_run = bpy.data.actions["Running"]


def point_tuple(point):
    return [float(point.x), float(point.y), float(point.z)]


bone_comparison = []
production_bone_names = {bone.name for bone in production_armature.data.bones}
new_bone_names = {bone.name for bone in new_armature.data.bones}
for name in sorted(production_bone_names & new_bone_names):
    production_bone = production_armature.data.bones[name]
    new_bone = new_armature.data.bones[name]
    production_head = production_armature.matrix_world @ production_bone.head_local
    production_tail = production_armature.matrix_world @ production_bone.tail_local
    new_head = new_armature.matrix_world @ new_bone.head_local
    new_tail = new_armature.matrix_world @ new_bone.tail_local
    bone_comparison.append(
        {
            "name": name,
            "production_head": point_tuple(production_head),
            "new_head": point_tuple(new_head),
            "head_distance": float((production_head - new_head).length),
            "production_tail": point_tuple(production_tail),
            "new_tail": point_tuple(new_tail),
            "tail_distance": float((production_tail - new_tail).length),
        }
    )


def curve_summary(action):
    summary = {}
    for curve in action.fcurves:
        values = [float(point.co.y) for point in curve.keyframe_points]
        key = f"{curve.data_path}[{curve.array_index}]"
        summary[key] = {
            "key_count": len(values),
            "minimum": min(values) if values else None,
            "maximum": max(values) if values else None,
            "max_abs": max((abs(value) for value in values), default=None),
        }
    return summary


production_summary = curve_summary(production_run)
new_summary = curve_summary(new_run)
shared_curves = sorted(set(production_summary) & set(new_summary))

curve_comparison = []
for key in shared_curves:
    production_curve = production_summary[key]
    new_curve = new_summary[key]
    production_max_abs = production_curve["max_abs"] or 0.0
    new_max_abs = new_curve["max_abs"] or 0.0
    ratio = (
        new_max_abs / production_max_abs
        if production_max_abs > 0.0000001
        else None
    )
    curve_comparison.append(
        {
            "curve": key,
            "production": production_curve,
            "new": new_curve,
            "new_to_production_max_abs_ratio": ratio,
        }
    )

report = {
    "production_armature": {
        "name": production_armature.name,
        "scale": list(production_armature.scale),
    },
    "new_armature": {
        "name": new_armature.name,
        "scale": list(new_armature.scale),
    },
    "max_bone_head_distance": max(
        (item["head_distance"] for item in bone_comparison), default=0.0
    ),
    "max_bone_tail_distance": max(
        (item["tail_distance"] for item in bone_comparison), default=0.0
    ),
    "bones": bone_comparison,
    "production_run": {
        "frame_range": list(production_run.frame_range),
        "curves": production_summary,
    },
    "new_run": {
        "frame_range": list(new_run.frame_range),
        "curves": new_summary,
    },
    "shared_curve_comparison": curve_comparison,
}

Path(report_path).write_text(json.dumps(report, indent=2), encoding="utf-8")
print(
    json.dumps(
        {
            "max_bone_head_distance": report["max_bone_head_distance"],
            "max_bone_tail_distance": report["max_bone_tail_distance"],
            "production_armature_scale": report["production_armature"]["scale"],
            "new_armature_scale": report["new_armature"]["scale"],
            "hips_location": [
                item
                for item in curve_comparison
                if 'pose.bones["Hips"].location' in item["curve"]
            ],
        },
        indent=2,
    )
)
