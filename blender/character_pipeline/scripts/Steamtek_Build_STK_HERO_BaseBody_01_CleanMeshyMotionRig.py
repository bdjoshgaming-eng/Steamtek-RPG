"""Build a clean hero rig and retarget the salvaged Meshy motions.

The approved production GLB and incoming Meshy downloads are read-only.
Meshy's damaged mesh and malformed Blender bone tails are retained only as
hidden motion references. A new meter-scale armature is fitted from the valid
joint origins, the approved hero is rebound with fresh weights, and coincident
GLB seam vertices receive identical weights.
"""

from __future__ import annotations

import hashlib
import json
import math
import sys
from collections import defaultdict
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parents[3]
APPROVED_MESH = (
    ROOT
    / "assets"
    / "characters"
    / "humanoid"
    / "base"
    / "STK_HERO_BaseBody_01"
    / "v01"
    / "STK_HERO_BaseBody_01.glb"
)
MESHY_MOTIONS = (
    ROOT
    / "incoming"
    / "meshy_hero_char"
    / "rig_source"
    / "v01"
    / "Meshy_AI_STK_HERO_BaseBody_01__biped_Meshy_AI_Meshy_Merged_Animations.glb"
)
OUTPUT_BLEND = (
    ROOT
    / "blender"
    / "character_pipeline"
    / "heroes"
    / "STK_HERO_BaseBody_01_Rigged_MeshyMotion_v04.blend"
)
OUTPUT_DIR = ROOT / "output" / "hero_rig_rebuild"
REPORT_JSON = OUTPUT_DIR / "STK_HERO_BaseBody_01_Rigged_MeshyMotion_v04_Report.json"
REPORT_MD = OUTPUT_DIR / "STK_HERO_BaseBody_01_Rigged_MeshyMotion_v04_Report.md"
REVIEW_DIR = OUTPUT_DIR / "review_v04"

TARGET_ARMATURE_NAME = "STK_HERO_BaseBody_01_Armature"
TARGET_MESH_NAME = "STK_HERO_BaseBody_01_RiggedBody"
WELD_KEY_DIGITS = 6
EXPECTED_TRIANGLES = 31_138

BONE_ORDER = (
    "Hips",
    "LeftUpLeg",
    "LeftLeg",
    "LeftFoot",
    "LeftToeBase",
    "RightUpLeg",
    "RightLeg",
    "RightFoot",
    "RightToeBase",
    "Spine02",
    "Spine01",
    "Spine",
    "LeftShoulder",
    "LeftArm",
    "LeftForeArm",
    "LeftHand",
    "RightShoulder",
    "RightArm",
    "RightForeArm",
    "RightHand",
    "neck",
    "Head",
    "head_end",
    "headfront",
)

PARENT = {
    "Hips": None,
    "LeftUpLeg": "Hips",
    "LeftLeg": "LeftUpLeg",
    "LeftFoot": "LeftLeg",
    "LeftToeBase": "LeftFoot",
    "RightUpLeg": "Hips",
    "RightLeg": "RightUpLeg",
    "RightFoot": "RightLeg",
    "RightToeBase": "RightFoot",
    "Spine02": "Hips",
    "Spine01": "Spine02",
    "Spine": "Spine01",
    "LeftShoulder": "Spine",
    "LeftArm": "LeftShoulder",
    "LeftForeArm": "LeftArm",
    "LeftHand": "LeftForeArm",
    "RightShoulder": "Spine",
    "RightArm": "RightShoulder",
    "RightForeArm": "RightArm",
    "RightHand": "RightForeArm",
    "neck": "Spine",
    "Head": "neck",
    "head_end": "Head",
    "headfront": "Head",
}

TAIL_CHILD = {
    "Hips": "Spine02",
    "LeftUpLeg": "LeftLeg",
    "LeftLeg": "LeftFoot",
    "LeftFoot": "LeftToeBase",
    "RightUpLeg": "RightLeg",
    "RightLeg": "RightFoot",
    "RightFoot": "RightToeBase",
    "Spine02": "Spine01",
    "Spine01": "Spine",
    "Spine": "neck",
    "LeftShoulder": "LeftArm",
    "LeftArm": "LeftForeArm",
    "LeftForeArm": "LeftHand",
    "RightShoulder": "RightArm",
    "RightArm": "RightForeArm",
    "RightForeArm": "RightHand",
    "neck": "Head",
    "Head": "head_end",
}

ACTION_NAMES = {
    "Running": "STK_RUN",
    "Walking": "STK_WALK",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def clean_matrix(matrix: Matrix) -> Matrix:
    location, rotation, _scale = matrix.decompose()
    return Matrix.Translation(location) @ rotation.to_matrix().to_4x4()


def mesh_triangle_count(obj: bpy.types.Object) -> int:
    return sum(max(0, len(poly.vertices) - 2) for poly in obj.data.polygons)


def mesh_topology_stats(obj: bpy.types.Object) -> dict[str, int]:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    stats = {
        "vertices": len(bm.verts),
        "edges": len(bm.edges),
        "faces": len(bm.faces),
        "boundary_edges_raw": sum(
            1 for edge in bm.edges if len(edge.link_faces) == 1
        ),
        "overfull_edges_raw": sum(
            1 for edge in bm.edges if len(edge.link_faces) > 2
        ),
        "wire_edges_raw": sum(
            1 for edge in bm.edges if len(edge.link_faces) == 0
        ),
        "degenerate_faces": sum(
            1 for face in bm.faces if face.calc_area() <= 1.0e-12
        ),
    }
    bm.free()
    return stats


def import_approved_mesh() -> bpy.types.Object:
    bpy.ops.import_scene.gltf(filepath=str(APPROVED_MESH))
    meshes = [
        obj
        for obj in bpy.context.scene.objects
        if obj.type == "MESH" and mesh_triangle_count(obj) == EXPECTED_TRIANGLES
    ]
    if len(meshes) != 1:
        raise RuntimeError(f"Approved source produced {len(meshes)} hero meshes")
    body = meshes[0]
    body.name = TARGET_MESH_NAME
    body.data.name = f"{TARGET_MESH_NAME}_Mesh"
    body["steamtek_approved_source"] = str(APPROVED_MESH)
    body["steamtek_approved_source_sha256"] = sha256(APPROVED_MESH)
    return body


def import_meshy_reference() -> tuple[
    bpy.types.Object, bpy.types.Object, dict[str, bpy.types.Action]
]:
    before_objects = set(bpy.data.objects)
    before_actions = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=str(MESHY_MOTIONS))
    new_objects = [obj for obj in bpy.data.objects if obj not in before_objects]
    source_armatures = [obj for obj in new_objects if obj.type == "ARMATURE"]
    source_meshes = [
        obj
        for obj in new_objects
        if obj.type == "MESH" and mesh_triangle_count(obj) > 1_000
    ]
    if len(source_armatures) != 1 or len(source_meshes) != 1:
        raise RuntimeError(
            f"Meshy reference import found {len(source_armatures)} armatures "
            f"and {len(source_meshes)} character meshes"
        )
    source_armature = source_armatures[0]
    source_mesh = source_meshes[0]
    source_armature.name = "SOURCE_Meshy_Armature"
    source_mesh.name = "SOURCE_Meshy_DamagedMesh"

    actions = {
        action.name: action
        for action in bpy.data.actions
        if action not in before_actions and action.name in ACTION_NAMES
    }
    if set(actions) != set(ACTION_NAMES):
        raise RuntimeError(f"Expected Running and Walking, found {sorted(actions)}")

    source_collection = bpy.data.collections.new("SOURCE_Meshy_Reference")
    bpy.context.scene.collection.children.link(source_collection)
    for obj in new_objects:
        for collection in list(obj.users_collection):
            collection.objects.unlink(obj)
        source_collection.objects.link(obj)
        obj.hide_render = True
        obj.hide_set(True)
    source_collection.hide_render = True

    source_armature["steamtek_motion_source"] = str(MESHY_MOTIONS)
    source_armature["steamtek_motion_source_sha256"] = sha256(MESHY_MOTIONS)
    return source_armature, source_mesh, actions


def source_joint_positions(source_armature: bpy.types.Object) -> dict[str, Vector]:
    missing = [name for name in BONE_ORDER if name not in source_armature.data.bones]
    if missing:
        raise RuntimeError(f"Meshy skeleton is missing bones: {missing}")
    return {
        name: source_armature.matrix_world
        @ source_armature.data.bones[name].head_local
        for name in BONE_ORDER
    }


def terminal_tail(name: str, heads: dict[str, Vector]) -> Vector:
    head = heads[name]
    if name in ("LeftToeBase", "RightToeBase"):
        return Vector((head.x, head.y - 0.12, max(0.025, head.z)))
    if name == "LeftHand":
        direction = (head - heads["LeftForeArm"]).normalized()
        return head + direction * 0.14
    if name == "RightHand":
        direction = (head - heads["RightForeArm"]).normalized()
        return head + direction * 0.14
    if name == "head_end":
        direction = (head - heads["Head"]).normalized()
        return head + direction * 0.10
    if name == "headfront":
        return head + Vector((0.0, -0.10, 0.0))
    raise RuntimeError(f"No terminal-tail rule for {name}")


def create_clean_armature(
    source_armature: bpy.types.Object,
) -> bpy.types.Object:
    heads = source_joint_positions(source_armature)
    armature_data = bpy.data.armatures.new(f"{TARGET_ARMATURE_NAME}_Data")
    armature = bpy.data.objects.new(TARGET_ARMATURE_NAME, armature_data)
    bpy.context.scene.collection.objects.link(armature)
    armature.show_in_front = True
    armature_data.display_type = "STICK"

    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    edit_bones: dict[str, bpy.types.EditBone] = {}
    for name in BONE_ORDER:
        bone = armature_data.edit_bones.new(name)
        bone.head = heads[name]
        child_name = TAIL_CHILD.get(name)
        bone.tail = heads[child_name] if child_name else terminal_tail(name, heads)
        if (bone.tail - bone.head).length < 0.025:
            raise RuntimeError(f"Clean bone {name} is too short")
        edit_bones[name] = bone

    for name in BONE_ORDER:
        parent_name = PARENT[name]
        if parent_name is None:
            continue
        bone = edit_bones[name]
        parent = edit_bones[parent_name]
        bone.parent = parent
        bone.use_connect = (bone.head - parent.tail).length <= 1.0e-5

    bpy.ops.object.mode_set(mode="OBJECT")
    armature.data.pose_position = "POSE"
    for helper_name in ("head_end", "headfront"):
        armature.data.bones[helper_name].use_deform = False
    armature["steamtek_schema"] = "SteamtekCleanMeshyMotionRig-4"
    armature["steamtek_motion_compatibility"] = (
        "24-bone Meshy hierarchy; motions retargeted to clean rest bones"
    )
    return armature


def bind_with_automatic_weights(
    body: bpy.types.Object, armature: bpy.types.Object
) -> None:
    proxy = body.copy()
    proxy.data = body.data.copy()
    proxy.name = "TEMP_STK_HERO_WeldedWeightProxy"
    proxy.data.name = f"{proxy.name}_Mesh"
    bpy.context.scene.collection.objects.link(proxy)
    proxy.data.materials.clear()

    bm = bmesh.new()
    bm.from_mesh(proxy.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1.0e-6)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(proxy.data)
    bm.free()
    proxy.data.update()

    bpy.ops.object.select_all(action="DESELECT")
    proxy.select_set(True)
    bpy.context.view_layer.objects.active = proxy
    proxy.data.remesh_voxel_size = 0.012
    proxy.data.remesh_voxel_adaptivity = 0.0
    bpy.ops.object.voxel_remesh()
    proxy.data.update()

    bpy.ops.object.select_all(action="DESELECT")
    proxy.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.parent_set(type="ARMATURE_AUTO", keep_transform=True)

    modifiers = [
        modifier
        for modifier in proxy.modifiers
        if modifier.type == "ARMATURE" and modifier.object == armature
    ]
    if len(modifiers) != 1:
        raise RuntimeError(
            "Proxy automatic binding did not create one armature modifier"
        )

    deform_names = [
        name for name in BONE_ORDER if armature.data.bones[name].use_deform
    ]
    proxy_groups = {
        name: proxy.vertex_groups.get(name) for name in deform_names
    }
    zero_proxy_vertices = [
        vertex.index
        for vertex in proxy.data.vertices
        if not any(
            membership.weight > 1.0e-8
            and proxy.vertex_groups[membership.group].name in deform_names
            for membership in vertex.groups
        )
    ]
    if zero_proxy_vertices:
        # Bone heat can leave a few isolated vertices. Assign only those to
        # the nearest deform segment rather than discarding the successful
        # heat weights on the rest of the closed proxy.
        segments = []
        for name in deform_names:
            bone = armature.data.bones[name]
            segments.append((name, bone.head_local.copy(), bone.tail_local.copy()))
        for vertex_index in zero_proxy_vertices:
            position = proxy.data.vertices[vertex_index].co
            nearest_name = None
            nearest_distance = math.inf
            for name, head, tail in segments:
                direction = tail - head
                denominator = direction.length_squared
                factor = (
                    0.0
                    if denominator <= 1.0e-12
                    else max(
                        0.0,
                        min(1.0, (position - head).dot(direction) / denominator),
                    )
                )
                closest = head + direction * factor
                distance = (position - closest).length_squared
                if distance < nearest_distance:
                    nearest_distance = distance
                    nearest_name = name
            group = proxy_groups[nearest_name]
            if group is None:
                group = proxy.vertex_groups.new(name=nearest_name)
                proxy_groups[nearest_name] = group
            group.add([vertex_index], 1.0, "REPLACE")

    for name in BONE_ORDER:
        if body.vertex_groups.get(name) is None:
            body.vertex_groups.new(name=name)

    transfer = body.modifiers.new("TEMP_STK_HERO_WeightTransfer", "DATA_TRANSFER")
    transfer.object = proxy
    transfer.use_vert_data = True
    transfer.data_types_verts = {"VGROUP_WEIGHTS"}
    transfer.vert_mapping = "POLYINTERP_NEAREST"
    transfer.layers_vgroup_select_src = "ALL"
    transfer.layers_vgroup_select_dst = "NAME"
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=transfer.name)

    body.parent = armature
    body.matrix_parent_inverse = armature.matrix_world.inverted()
    modifier = body.modifiers.new("STK_HERO_Armature", "ARMATURE")
    modifier.object = armature
    modifier.use_vertex_groups = True
    modifier.use_deform_preserve_volume = True

    proxy_mesh = proxy.data
    bpy.data.objects.remove(proxy, do_unlink=True)
    bpy.data.meshes.remove(proxy_mesh)


def vertex_weights(body: bpy.types.Object, vertex_index: int) -> dict[str, float]:
    result: dict[str, float] = {}
    vertex = body.data.vertices[vertex_index]
    for membership in vertex.groups:
        group = body.vertex_groups[membership.group]
        if group.name in BONE_ORDER and membership.weight > 1.0e-8:
            result[group.name] = membership.weight
    return result


def set_vertex_weights(
    body: bpy.types.Object, indices: list[int], weights: dict[str, float]
) -> None:
    for group in body.vertex_groups:
        try:
            group.remove(indices)
        except RuntimeError:
            pass
    for name, weight in weights.items():
        body.vertex_groups[name].add(indices, weight, "REPLACE")


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    if edge1 <= edge0:
        return 0.0
    factor = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return factor * factor * (3.0 - 2.0 * factor)


def correct_lower_body_weights(
    body: bpy.types.Object, armature: bpy.types.Object
) -> dict[str, int | float]:
    bones = armature.data.bones
    hip_joint_z = (
        bones["LeftUpLeg"].head_local.z + bones["RightUpLeg"].head_local.z
    ) * 0.5
    knee_joint_z = (
        bones["LeftLeg"].head_local.z + bones["RightLeg"].head_local.z
    ) * 0.5
    pelvis_top_z = bones["Hips"].tail_local.z

    knee_blend_bottom = knee_joint_z - 0.08
    knee_blend_top = knee_joint_z + 0.11
    thigh_full_top = hip_joint_z - 0.08
    pelvis_full_bottom = hip_joint_z + 0.02
    correction_ceiling = hip_joint_z + 0.09
    side_fade_start = 0.20
    side_fade_end = 0.245

    corrected = 0
    left_vertices = 0
    right_vertices = 0
    pelvis_vertices = 0

    for vertex in body.data.vertices:
        position = vertex.co
        z = position.z
        if z < knee_blend_bottom or z > correction_ceiling:
            continue

        side_correction = 1.0 - smoothstep(
            side_fade_start, side_fade_end, abs(position.x)
        )
        upper_correction = 1.0 - smoothstep(
            pelvis_full_bottom, correction_ceiling, z
        )
        correction_amount = side_correction * upper_correction
        if correction_amount <= 1.0e-5:
            continue

        is_left = position.x >= 0.0
        up_leg = "LeftUpLeg" if is_left else "RightUpLeg"
        lower_leg = "LeftLeg" if is_left else "RightLeg"

        if z >= thigh_full_top:
            vertical_factor = 1.0 - smoothstep(
                thigh_full_top, pelvis_full_bottom, z
            )
            side_factor = smoothstep(0.025, 0.16, abs(position.x))
            up_leg_weight = vertical_factor * (0.65 + 0.25 * side_factor)
            corrected_weights = {
                "Hips": 1.0 - up_leg_weight,
                up_leg: up_leg_weight,
            }
            pelvis_vertices += 1
        elif z >= knee_blend_top:
            corrected_weights = {up_leg: 1.0}
        else:
            up_leg_weight = smoothstep(knee_blend_bottom, knee_blend_top, z)
            corrected_weights = {
                up_leg: up_leg_weight,
                lower_leg: 1.0 - up_leg_weight,
            }

        original_weights = vertex_weights(body, vertex.index)
        blended_weights: dict[str, float] = defaultdict(float)
        for name, weight in original_weights.items():
            blended_weights[name] += weight * (1.0 - correction_amount)
        for name, weight in corrected_weights.items():
            blended_weights[name] += weight * correction_amount
        total = sum(blended_weights.values())
        if total <= 1.0e-8:
            continue
        weights = {
            name: weight / total
            for name, weight in blended_weights.items()
            if weight > 1.0e-8
        }
        set_vertex_weights(body, [vertex.index], weights)
        corrected += 1
        if is_left:
            left_vertices += 1
        else:
            right_vertices += 1

    return {
        "corrected_vertices": corrected,
        "left_side_vertices": left_vertices,
        "right_side_vertices": right_vertices,
        "pelvis_vertices": pelvis_vertices,
        "knee_joint_z": knee_joint_z,
        "hip_joint_z": hip_joint_z,
        "pelvis_top_z": pelvis_top_z,
        "correction_ceiling_z": correction_ceiling,
        "side_fade_end_x": side_fade_end,
    }


def synchronize_seam_weights(body: bpy.types.Object) -> dict[str, int]:
    by_position: dict[tuple[float, float, float], list[int]] = defaultdict(list)
    for vertex in body.data.vertices:
        key = tuple(round(value, WELD_KEY_DIGITS) for value in vertex.co)
        by_position[key].append(vertex.index)

    duplicate_groups = [indices for indices in by_position.values() if len(indices) > 1]
    for indices in duplicate_groups:
        combined: dict[str, float] = defaultdict(float)
        for index in indices:
            for name, weight in vertex_weights(body, index).items():
                combined[name] += weight
        averaged = {
            name: weight / len(indices) for name, weight in combined.items()
        }
        strongest = sorted(
            averaged.items(), key=lambda item: item[1], reverse=True
        )[:4]
        total = sum(weight for _name, weight in strongest)
        if total <= 1.0e-8:
            continue
        normalized = {name: weight / total for name, weight in strongest}
        set_vertex_weights(body, indices, normalized)

    return {
        "positional_groups": len(by_position),
        "duplicate_position_groups": len(duplicate_groups),
        "vertices_in_duplicate_groups": sum(len(group) for group in duplicate_groups),
    }


def lock_hair_to_head(body: bpy.types.Object) -> int:
    hair_slots = {
        index
        for index, material in enumerate(body.data.materials)
        if material and "hair" in material.name.lower()
    }
    if not hair_slots:
        return 0
    indices = sorted(
        {
            vertex_index
            for polygon in body.data.polygons
            if polygon.material_index in hair_slots
            for vertex_index in polygon.vertices
        }
    )
    if indices:
        set_vertex_weights(body, indices, {"Head": 1.0})
    return len(indices)


def normalize_and_limit_weights(body: bpy.types.Object) -> dict[str, int | float]:
    zero_weight = 0
    max_influences = 0
    min_sum = math.inf
    max_sum = -math.inf
    for vertex in body.data.vertices:
        weights = vertex_weights(body, vertex.index)
        strongest = sorted(weights.items(), key=lambda item: item[1], reverse=True)[:4]
        total = sum(weight for _name, weight in strongest)
        if total <= 1.0e-8:
            zero_weight += 1
            continue
        normalized = {name: weight / total for name, weight in strongest}
        set_vertex_weights(body, [vertex.index], normalized)
        total_after = sum(normalized.values())
        min_sum = min(min_sum, total_after)
        max_sum = max(max_sum, total_after)
        max_influences = max(max_influences, len(normalized))
    return {
        "zero_weight_vertices": zero_weight,
        "max_influences": max_influences,
        "min_weight_sum": 0.0 if min_sum is math.inf else min_sum,
        "max_weight_sum": 0.0 if max_sum is -math.inf else max_sum,
    }


def action_fcurves(action: bpy.types.Action):
    if action.is_action_layered:
        for layer in action.layers:
            for strip in layer.strips:
                if strip.type != "KEYFRAME":
                    continue
                for channelbag in strip.channelbags:
                    yield from channelbag.fcurves
    else:
        yield from action.fcurves


def action_frames(action: bpy.types.Action) -> list[float]:
    frames = {
        round(float(point.co.x), 6)
        for fcurve in action_fcurves(action)
        for point in fcurve.keyframe_points
    }
    if not frames:
        raise RuntimeError(f"Action {action.name} has no keyframes")
    return sorted(frames)


def set_scene_frame(frame: float) -> None:
    integer = math.floor(frame)
    bpy.context.scene.frame_set(integer, subframe=frame - integer)
    bpy.context.view_layer.update()


def create_target_action(
    name: str, target_armature: bpy.types.Object
) -> tuple[bpy.types.Action, bpy.types.ActionSlot, bpy.types.ActionKeyframeStrip]:
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    slot = action.slots.new("OBJECT", target_armature.name)
    layer = action.layers.new(name="Base")
    strip = layer.strips.new(type="KEYFRAME")
    return action, slot, strip


def retarget_actions(
    source_armature: bpy.types.Object,
    source_actions: dict[str, bpy.types.Action],
    target_armature: bpy.types.Object,
) -> dict[str, dict]:
    source_armature.hide_set(False)
    source_armature.animation_data_create()
    target_armature.animation_data_create()

    source_rest = {
        name: clean_matrix(
            source_armature.matrix_world
            @ source_armature.data.bones[name].matrix_local
        )
        for name in BONE_ORDER
    }
    target_rest = {
        name: clean_matrix(
            target_armature.matrix_world
            @ target_armature.data.bones[name].matrix_local
        )
        for name in BONE_ORDER
    }

    results: dict[str, dict] = {}
    for source_name, target_name in ACTION_NAMES.items():
        source_action = source_actions[source_name]
        source_armature.animation_data.action = source_action
        source_armature.animation_data.action_slot = source_action.slots[0]
        frames = action_frames(source_action)

        target_action, target_slot, target_strip = create_target_action(
            target_name, target_armature
        )
        target_armature.animation_data.action = target_action
        target_armature.animation_data.action_slot = target_slot

        for pose_bone in target_armature.pose.bones:
            pose_bone.rotation_mode = "QUATERNION"

        for frame in frames:
            set_scene_frame(frame)
            for pose_bone in target_armature.pose.bones:
                pose_bone.matrix_basis.identity()
            bpy.context.view_layer.update()

            for name in BONE_ORDER:
                source_pose_world = clean_matrix(
                    source_armature.matrix_world
                    @ source_armature.pose.bones[name].matrix
                )
                delta_world = source_pose_world @ source_rest[name].inverted()
                desired_world = delta_world @ target_rest[name]
                target_armature.pose.bones[name].matrix = (
                    target_armature.matrix_world.inverted() @ desired_world
                )
                bpy.context.view_layer.update()

            for name in BONE_ORDER:
                pose_bone = target_armature.pose.bones[name]
                data_path = f'pose.bones["{name}"]'
                for index, value in enumerate(pose_bone.location):
                    target_strip.key_insert(
                        slot=target_slot,
                        data_path=f"{data_path}.location",
                        array_index=index,
                        value=float(value),
                        time=frame,
                    )
                for index, value in enumerate(pose_bone.rotation_quaternion):
                    target_strip.key_insert(
                        slot=target_slot,
                        data_path=f"{data_path}.rotation_quaternion",
                        array_index=index,
                        value=float(value),
                        time=frame,
                    )
                for index, value in enumerate(pose_bone.scale):
                    target_strip.key_insert(
                        slot=target_slot,
                        data_path=f"{data_path}.scale",
                        array_index=index,
                        value=float(value),
                        time=frame,
                    )

        channelbag = target_strip.channelbag(target_slot, ensure=False)
        for fcurve in channelbag.fcurves:
            for point in fcurve.keyframe_points:
                point.interpolation = "LINEAR"

        source_action.name = f"SOURCE_Meshy_{source_name}"
        results[target_name] = {
            "action": target_action,
            "slot": target_slot,
            "frame_start": frames[0],
            "frame_end": frames[-1],
            "keyed_frames": len(frames),
            "key_times": frames,
        }

    source_armature.hide_set(True)
    return results


def assign_action(
    armature: bpy.types.Object, action_info: dict | None
) -> None:
    armature.animation_data_create()
    if action_info is None:
        armature.animation_data.action = None
        return
    armature.animation_data.action = action_info["action"]
    armature.animation_data.action_slot = action_info["slot"]


def evaluated_mesh_bounds(
    body: bpy.types.Object,
) -> tuple[Vector, Vector, int]:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = body.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    world_positions = [evaluated.matrix_world @ vertex.co for vertex in mesh.vertices]
    minimum = Vector(
        (
            min(position.x for position in world_positions),
            min(position.y for position in world_positions),
            min(position.z for position in world_positions),
        )
    )
    maximum = Vector(
        (
            max(position.x for position in world_positions),
            max(position.y for position in world_positions),
            max(position.z for position in world_positions),
        )
    )
    collapsed = sum(
        1
        for polygon in mesh.polygons
        if polygon.area <= 1.0e-12
    )
    evaluated.to_mesh_clear()
    return minimum, maximum, collapsed


def validate_actions(
    body: bpy.types.Object,
    armature: bpy.types.Object,
    actions: dict[str, dict],
) -> dict[str, dict]:
    validation: dict[str, dict] = {}
    armature.data.pose_position = "POSE"
    for name, info in actions.items():
        assign_action(armature, info)
        sample_frames = info["key_times"]
        samples = []
        for frame in sample_frames:
            set_scene_frame(frame)
            minimum, maximum, collapsed = evaluated_mesh_bounds(body)
            dimensions = maximum - minimum
            if max(dimensions) > 3.0 or minimum.z < -1.0 or maximum.z > 3.0:
                raise RuntimeError(
                    f"{name} frame {frame} has implausible bounds {tuple(dimensions)}"
                )
            if collapsed:
                raise RuntimeError(
                    f"{name} frame {frame} has {collapsed} collapsed faces"
                )
            samples.append(
                {
                    "frame": frame,
                    "minimum": list(minimum),
                    "maximum": list(maximum),
                    "dimensions": list(dimensions),
                    "collapsed_faces": collapsed,
                }
            )
        validation[name] = {"samples": samples}
    return validation


def configure_review_stage() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"

    world = scene.world or bpy.data.worlds.new("STK_HeroRigReviewWorld")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.012, 0.016, 0.024, 1.0)
    background.inputs["Strength"].default_value = 0.25

    camera_data = bpy.data.cameras.new("STK_HeroRigReviewCamera")
    camera = bpy.data.objects.new("STK_HeroRigReviewCamera", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.35
    camera.location = (3.2, -5.4, 3.0)
    camera.rotation_euler = (
        Vector((0.0, 0.0, 0.95)) - camera.location
    ).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    for name, location, energy, size in (
        ("STK_RigReview_Key", (4.0, -4.0, 5.5), 850.0, 4.0),
        ("STK_RigReview_Fill", (-4.0, -2.0, 3.0), 350.0, 3.0),
        ("STK_RigReview_Rim", (0.0, 4.0, 4.5), 500.0, 3.0),
    ):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        light = bpy.data.objects.new(name, data)
        bpy.context.scene.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (
            Vector((0.0, 0.0, 1.0)) - light.location
        ).to_track_quat("-Z", "Y").to_euler()
    return camera


def render_reviews(
    body: bpy.types.Object,
    armature: bpy.types.Object,
    actions: dict[str, dict],
) -> dict[str, str]:
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    configure_review_stage()
    armature.hide_render = True
    body.hide_render = False

    outputs: dict[str, str] = {}
    armature.data.pose_position = "REST"
    assign_action(armature, None)
    set_scene_frame(0.0)
    rest_path = REVIEW_DIR / "STK_HERO_BaseBody_01_CleanRig_Rest.png"
    bpy.context.scene.render.filepath = str(rest_path)
    bpy.ops.render.render(write_still=True)
    outputs["rest"] = str(rest_path)

    armature.data.pose_position = "POSE"
    for action_name in ("STK_WALK", "STK_RUN"):
        info = actions[action_name]
        assign_action(armature, info)
        frame = (info["frame_start"] + info["frame_end"]) * 0.5
        set_scene_frame(frame)
        path = REVIEW_DIR / f"STK_HERO_BaseBody_01_CleanRig_{action_name}.png"
        bpy.context.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        outputs[action_name] = str(path)
    return outputs


def write_report(report: dict) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_JSON.write_text(json.dumps(report, indent=2), encoding="utf-8")
    lines = [
        "# STK_HERO_BaseBody_01 Clean Meshy-Motion Rig",
        "",
        "## Status",
        "",
        "**TECHNICAL CANDIDATE — visual deformation approval pending.**",
        "",
        "## Sources",
        "",
        f"- Approved mesh: `{APPROVED_MESH}`",
        f"- Meshy motion reference: `{MESHY_MOTIONS}`",
        "",
        "## Build",
        "",
        f"- Clean armature: `{TARGET_ARMATURE_NAME}`",
        f"- Bones: **{report['bone_count']}**",
        f"- Triangles: **{report['triangle_count']}**",
        f"- Zero-weight vertices: **{report['weights']['zero_weight_vertices']}**",
        f"- Maximum influences: **{report['weights']['max_influences']}**",
        f"- Hair vertices locked to Head: **{report['hair_vertices']}**",
        (
            "- Coincident seam groups synchronized: "
            f"**{report['seam_weights']['duplicate_position_groups']}**"
        ),
        "",
        "## Motions",
        "",
        (
            f"- `STK_WALK`: {report['actions']['STK_WALK']['keyed_frames']} "
            "sampled key times"
        ),
        (
            f"- `STK_RUN`: {report['actions']['STK_RUN']['keyed_frames']} "
            "sampled key times"
        ),
        "",
        "## Output",
        "",
        f"- Blender candidate: `{OUTPUT_BLEND}`",
        "",
        "The malformed Meshy mesh and bone-tail display are hidden reference data.",
        "The approved production GLB was not modified.",
    ]
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    for path in (APPROVED_MESH, MESHY_MOTIONS):
        if not path.is_file():
            raise FileNotFoundError(path)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_BLEND.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = 24

    body = import_approved_mesh()
    source_armature, _source_mesh, source_actions = import_meshy_reference()
    target_armature = create_clean_armature(source_armature)
    bind_with_automatic_weights(body, target_armature)

    hair_vertices = lock_hair_to_head(body)
    seam_stats = synchronize_seam_weights(body)
    weight_stats = normalize_and_limit_weights(body)
    if weight_stats["zero_weight_vertices"]:
        raise RuntimeError(
            f"Binding left {weight_stats['zero_weight_vertices']} zero-weight vertices"
        )
    if weight_stats["max_influences"] > 4:
        raise RuntimeError("Binding exceeded four influences")

    target_actions = retarget_actions(
        source_armature, source_actions, target_armature
    )
    action_validation = validate_actions(body, target_armature, target_actions)
    review_outputs = render_reviews(body, target_armature, target_actions)

    body_stats = mesh_topology_stats(body)
    assign_action(target_armature, target_actions["STK_WALK"])
    target_armature.data.pose_position = "POSE"
    set_scene_frame(0.0)
    scene.frame_start = 0
    scene.frame_end = math.ceil(target_actions["STK_WALK"]["frame_end"])
    scene.use_preview_range = True
    scene.frame_preview_start = scene.frame_start
    scene.frame_preview_end = scene.frame_end
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body

    report = {
        "schema": "SteamtekCleanMeshyMotionRig-4",
        "status": "technical_candidate_visual_approval_pending",
        "approved_mesh": str(APPROVED_MESH),
        "approved_mesh_sha256": sha256(APPROVED_MESH),
        "meshy_motion_source": str(MESHY_MOTIONS),
        "meshy_motion_sha256": sha256(MESHY_MOTIONS),
        "output_blend": str(OUTPUT_BLEND),
        "bone_count": len(target_armature.data.bones),
        "bones": list(BONE_ORDER),
        "triangle_count": mesh_triangle_count(body),
        "mesh_topology": body_stats,
        "materials": [
            material.name for material in body.data.materials if material
        ],
        "hair_vertices": hair_vertices,
        "seam_weights": seam_stats,
        "weights": weight_stats,
        "actions": {
            name: {
                key: value
                for key, value in info.items()
                if key not in ("action", "slot")
            }
            for name, info in target_actions.items()
        },
        "action_validation": action_validation,
        "review_outputs": review_outputs,
    }
    write_report(report)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_BLEND))

    print(f"OUTPUT_BLEND={OUTPUT_BLEND}")
    print(f"REPORT={REPORT_MD}")
    print(f"BONES={len(target_armature.data.bones)}")
    print(f"TRIANGLES={mesh_triangle_count(body)}")
    print(f"ZERO_WEIGHT_VERTICES={weight_stats['zero_weight_vertices']}")
    print(f"MAX_INFLUENCES={weight_stats['max_influences']}")
    print(f"STK_WALK_FRAMES={target_actions['STK_WALK']['keyed_frames']}")
    print(f"STK_RUN_FRAMES={target_actions['STK_RUN']['keyed_frames']}")
    print("STATUS=TECHNICAL_CANDIDATE_VISUAL_APPROVAL_PENDING")


if __name__ == "__main__":
    main()
