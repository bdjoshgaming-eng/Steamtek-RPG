"""Inspect SCU arm/torso vertex-group coverage in the production Blender file."""

from __future__ import annotations

import json

import bpy
from mathutils import Vector


GROUPS = [
    "LeftShoulder",
    "LeftArm",
    "LeftForeArm",
    "LeftHand",
    "RightShoulder",
    "RightArm",
    "RightForeArm",
    "RightHand",
    "Spine",
    "Spine01",
    "Spine02",
]


def group_report(obj: bpy.types.Object, group_name: str) -> dict:
    group = obj.vertex_groups.get(group_name)
    if group is None:
        return {"name": group_name, "missing": True}
    weighted = []
    for vertex in obj.data.vertices:
        for assignment in vertex.groups:
            if assignment.group == group.index and assignment.weight > 0.05:
                weighted.append((obj.matrix_world @ vertex.co, assignment.weight))
                break
    if not weighted:
        return {"name": group_name, "vertices_above_005": 0}
    coordinates = [item[0] for item in weighted]
    weights = [item[1] for item in weighted]
    minimum = Vector(
        (
            min(value.x for value in coordinates),
            min(value.y for value in coordinates),
            min(value.z for value in coordinates),
        )
    )
    maximum = Vector(
        (
            max(value.x for value in coordinates),
            max(value.y for value in coordinates),
            max(value.z for value in coordinates),
        )
    )
    return {
        "name": group_name,
        "vertices_above_005": len(weighted),
        "bounds": {
            "minimum": [round(value, 5) for value in minimum],
            "maximum": [round(value, 5) for value in maximum],
        },
        "average_weight": round(sum(weights) / len(weights), 5),
        "maximum_weight": round(max(weights), 5),
    }


report = {}
for lod_name in (
    "STK_NPC_SCU_Mk1_LOD0",
    "STK_NPC_SCU_Mk1_LOD1",
    "STK_NPC_SCU_Mk1_LOD2",
):
    mesh = bpy.data.objects[lod_name]
    report[lod_name] = [group_report(mesh, name) for name in GROUPS]

armature = bpy.data.objects["STK_NPC_SCU_Mk1_Rig"]
report["armature"] = {
    "pose_position": armature.data.pose_position,
    "active_action": (
        armature.animation_data.action.name
        if armature.animation_data and armature.animation_data.action
        else ""
    ),
}
print("STEAMTEK_SCU_WEIGHT_REPORT=" + json.dumps(report, indent=2))
