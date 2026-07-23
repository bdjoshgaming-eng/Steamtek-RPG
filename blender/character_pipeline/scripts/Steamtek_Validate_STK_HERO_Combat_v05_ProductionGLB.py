"""Fresh-import validation for the Steamtek hero combat v05 production GLB."""

import json
import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
GLB = (
    ROOT
    / "assets"
    / "characters"
    / "humanoid"
    / "base"
    / "STK_HERO_BaseBody_01"
    / "v01"
    / "rigged"
    / "STK_HERO_BaseBody_01_Rigged_Combat_v05.glb"
)
REPORT = GLB.with_suffix(".validation.json")
EXPECTED_ACTIONS = {
    "STK_DEATH_FORWARD",
    "STK_HIT_REACT_STRONG",
    "STK_RIFLE_BUTTSTROKE",
    "STK_RIFLE_CROUCH_STRAFE_LEFT",
    "STK_RIFLE_CROUCH_STRAFE_RIGHT",
    "STK_RIFLE_FIRE",
    "STK_RIFLE_IDLE",
    "STK_RIFLE_RELOAD",
    "STK_RIFLE_TURN_LEFT",
    "STK_RIFLE_TURN_RIGHT",
    "STK_RUN",
    "STK_WALK",
}
EXPECTED_BONES = 24
EXPECTED_TRIANGLES = 31_138


def assign_action(armature, action):
    armature.animation_data_create()
    armature.animation_data.action = action
    if action.is_action_layered and action.slots:
        armature.animation_data.action_slot = action.slots[0]


if not GLB.is_file():
    raise FileNotFoundError(GLB)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(GLB))

armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
if len(armatures) != 1:
    raise RuntimeError(f"Expected one armature, found {len(armatures)}")

armature = armatures[0]
if len(armature.data.bones) != EXPECTED_BONES:
    raise RuntimeError(
        f"Bone mismatch: {len(armature.data.bones)} != {EXPECTED_BONES}"
    )

skinned_meshes = [
    obj
    for obj in bpy.context.scene.objects
    if obj.type == "MESH"
    and (
        obj.parent == armature
        or any(
            modifier.type == "ARMATURE" and modifier.object == armature
            for modifier in obj.modifiers
        )
    )
]
if len(skinned_meshes) != 1:
    raise RuntimeError(
        f"Expected one skinned mesh, found {len(skinned_meshes)}"
    )
body = skinned_meshes[0]

triangles = sum(max(0, len(poly.vertices) - 2) for poly in body.data.polygons)
if triangles != EXPECTED_TRIANGLES:
    raise RuntimeError(f"Triangle mismatch: {triangles} != {EXPECTED_TRIANGLES}")

actions = {action.name: action for action in bpy.data.actions}
if set(actions) != EXPECTED_ACTIONS:
    raise RuntimeError(
        f"Animation mismatch: found {sorted(actions)}, "
        f"expected {sorted(EXPECTED_ACTIONS)}"
    )

action_samples = {}
for action_name, action in sorted(actions.items()):
    assign_action(armature, action)
    frame_start, frame_end = action.frame_range
    frames = [
        frame_start,
        frame_start + (frame_end - frame_start) * 0.25,
        frame_start + (frame_end - frame_start) * 0.50,
        frame_start + (frame_end - frame_start) * 0.75,
        frame_end,
    ]
    samples = []
    for frame in frames:
        integer_frame = math.floor(frame)
        bpy.context.scene.frame_set(
            integer_frame, subframe=frame - integer_frame
        )
        bpy.context.view_layer.update()
        evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        points = [
            evaluated.matrix_world @ vertex.co
            for vertex in evaluated.data.vertices
        ]
        minimum = [min(point[axis] for point in points) for axis in range(3)]
        maximum = [max(point[axis] for point in points) for axis in range(3)]
        dimensions = [maximum[axis] - minimum[axis] for axis in range(3)]
        if not all(
            math.isfinite(value)
            for value in minimum + maximum + dimensions
        ):
            raise RuntimeError(
                f"Non-finite bounds in {action_name} at frame {frame}"
            )
        if min(dimensions) <= 1.0e-5 or max(dimensions) >= 5.0:
            raise RuntimeError(
                f"Implausible bounds in {action_name} at frame "
                f"{frame}: {dimensions}"
            )
        samples.append(
            {
                "frame": frame,
                "minimum": minimum,
                "maximum": maximum,
                "dimensions": dimensions,
            }
        )
    action_samples[action_name] = {
        "frame_start": frame_start,
        "frame_end": frame_end,
        "samples": samples,
    }

report = {
    "schema": "SteamtekHeroCombatGLBValidation-1",
    "status": "pass",
    "glb": str(GLB),
    "armature": armature.name,
    "bones": len(armature.data.bones),
    "mesh": body.name,
    "vertices": len(body.data.vertices),
    "triangles": triangles,
    "materials": [
        material.name for material in body.data.materials if material is not None
    ],
    "images": sorted(image.name for image in bpy.data.images),
    "actions": sorted(actions),
    "action_samples": action_samples,
}
REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")

print(f"STATUS={report['status'].upper()}")
print(f"GLB={GLB}")
print(f"REPORT={REPORT}")
print(f"BONES={report['bones']}")
print(f"VERTICES={report['vertices']}")
print(f"TRIANGLES={report['triangles']}")
print("ACTIONS=" + ",".join(report["actions"]))
print("MATERIALS=" + ",".join(report["materials"]))
print("IMAGES=" + ",".join(report["images"]))
