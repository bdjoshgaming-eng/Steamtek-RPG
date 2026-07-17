"""Create a deterministic Steamtek-compliant humanoid GLB for intake testing.

This is a pipeline fixture, not game art.  It proves that the complete success
path can import, inspect, normalize, socket, and export a standards-compliant
character without relying on a third-party model.

Run with Blender 4.5 or newer:
    blender.exe --background --python create_compliant_fixture.py -- \
        --output Steamtek_CompliantFixture.glb
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import bpy


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    return parser.parse_args(argv)


def add_bone(armature, name, head, tail, parent=None):
    bone = armature.data.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.parent = parent
    return bone


def create_armature():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "Steamtek_SharedHumanoid"
    armature.data.name = "Steamtek_SharedHumanoid_Skeleton"

    hips = armature.data.edit_bones[0]
    hips.name = "Hips"
    hips.head = (0, 0, 0.9)
    hips.tail = (0, 0, 1.1)

    spine = add_bone(armature, "Spine", hips.tail, (0, 0, 1.3), hips)
    chest = add_bone(armature, "Chest", spine.tail, (0, 0, 1.5), spine)
    neck = add_bone(armature, "Neck", chest.tail, (0, 0, 1.62), chest)
    add_bone(armature, "Head", neck.tail, (0, 0, 1.82), neck)

    for side, sign in (("L", 1.0), ("R", -1.0)):
        upper = add_bone(
            armature,
            f"UpperArm.{side}",
            (0.05 * sign, 0, 1.47),
            (0.32 * sign, 0, 1.38),
            chest,
        )
        lower = add_bone(
            armature,
            f"LowerArm.{side}",
            upper.tail,
            (0.52 * sign, 0, 1.25),
            upper,
        )
        add_bone(
            armature,
            f"hand.{side}",
            lower.tail,
            (0.65 * sign, -0.02, 1.2),
            lower,
        )

        thigh = add_bone(
            armature,
            f"Thigh.{side}",
            (0.1 * sign, 0, 0.95),
            (0.12 * sign, 0, 0.55),
            hips,
        )
        shin = add_bone(
            armature,
            f"Shin.{side}",
            thigh.tail,
            (0.12 * sign, 0, 0.18),
            thigh,
        )
        add_bone(
            armature,
            f"foot.{side}",
            shin.tail,
            (0.12 * sign, -0.22, 0.12),
            shin,
        )

    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def create_16000_triangle_mesh(armature):
    # 80 x 100 quads produce exactly 16,000 triangles after triangulation.
    columns = 80
    rows = 100
    vertices = []
    faces = []
    for row in range(rows + 1):
        z = 0.05 + (1.75 * row / rows)
        for column in range(columns + 1):
            x = -0.3 + (0.6 * column / columns)
            # A shallow curve keeps the fixture visible as a volume-like sheet.
            y = 0.04 * (1.0 - ((column - columns / 2) / (columns / 2)) ** 2)
            vertices.append((x, y, z))

    stride = columns + 1
    for row in range(rows):
        for column in range(columns):
            a = row * stride + column
            b = a + 1
            c = a + stride + 1
            d = a + stride
            faces.append((a, b, c, d))

    mesh_data = bpy.data.meshes.new("Steamtek_CompliantBody_Mesh")
    mesh_data.from_pydata(vertices, [], faces)
    mesh_data.update()

    body = bpy.data.objects.new("Body", mesh_data)
    bpy.context.collection.objects.link(body)
    body.parent = armature
    modifier = body.modifiers.new("SteamtekSharedSkeleton", "ARMATURE")
    modifier.object = armature
    group = body.vertex_groups.new(name="Hips")
    group.add(range(len(vertices)), 1.0, "REPLACE")

    material = bpy.data.materials.new("Steamtek_Fixture_Material")
    material.diffuse_color = (0.035, 0.045, 0.055, 1.0)
    material.metallic = 0.65
    material.roughness = 0.35
    body.data.materials.append(material)
    return body


def create_action(armature, name, movement):
    armature.animation_data_create()
    action = bpy.data.actions.new(name=name)
    armature.animation_data.action = action
    pose_bone = armature.pose.bones["Hips"]
    for frame, x_value in ((1, 0.0), (12, movement), (24, 0.0)):
        pose_bone.location.x = x_value
        pose_bone.keyframe_insert(data_path="location", frame=frame, group="Hips")
    action.frame_start = 1
    action.frame_end = 24
    return action


def create_animations(armature):
    idle = create_action(armature, "Idle", 0.002)
    walk = create_action(armature, "Walking", 0.03)

    # Keep both actions assigned through NLA so the glTF exporter includes them.
    armature.animation_data.action = None
    for action in (idle, walk):
        track = armature.animation_data.nla_tracks.new()
        track.name = action.name
        track.strips.new(action.name, 1, action)


def main():
    args = parse_args()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    armature = create_armature()
    body = create_16000_triangle_mesh(armature)
    create_animations(armature)

    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_skins=True,
        export_morph=True,
        export_yup=True,
        export_apply=False,
    )
    if not output.is_file():
        raise RuntimeError(f"Fixture export did not create {output}")
    print(f"STEAMTEK_COMPLIANT_FIXTURE={output}")


if __name__ == "__main__":
    main()
