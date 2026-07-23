"""Report shared-rig rest-bone positions against SCU weighted limb bounds."""

from __future__ import annotations

import json

import bpy


armature = bpy.data.objects["STK_NPC_SCU_Mk1_Rig"]
names = [
    "LeftShoulder",
    "LeftArm",
    "LeftForeArm",
    "LeftHand",
    "RightShoulder",
    "RightArm",
    "RightForeArm",
    "RightHand",
]
report = {}
for name in names:
    bone = armature.data.bones.get(name)
    if bone is None:
        report[name] = {"missing": True}
        continue
    head = armature.matrix_world @ bone.head_local
    tail = armature.matrix_world @ bone.tail_local
    report[name] = {
        "head": [round(value, 5) for value in head],
        "tail": [round(value, 5) for value in tail],
        "length": round((tail - head).length, 5),
    }
print("STEAMTEK_SCU_RIG_FIT=" + json.dumps(report, indent=2))
