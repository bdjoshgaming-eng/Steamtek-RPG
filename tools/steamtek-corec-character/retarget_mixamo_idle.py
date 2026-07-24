import bpy
import os
import json
import math
import hashlib
from mathutils import Matrix, Vector

ROOT = r'C:\My Game\Steamtek-RPG'
CHAR = os.path.join(ROOT, 'output', 'corec_male_character', 'STK_CHAR_Player_M_CoreC_Hacker.glb')
ANIM = os.path.join(ROOT, 'incoming', 'corsec_male_animations', 'MX_Idle.fbx')
OUT_DIR = os.path.dirname(CHAR)
METRICS = os.path.join(OUT_DIR, 'mixamo_idle_retarget_metrics.json')
REPORT = os.path.join(OUT_DIR, 'STK_CHAR_Player_M_CoreC_Hacker_assembly_report.md')
ANIM_NAME = 'STK_Idle_Mixamo_01'

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

source_root = os.path.join(ROOT, 'incoming', 'corec_male_character')
protected = [os.path.join(source_root, f) for f in os.listdir(source_root) if os.path.isfile(os.path.join(source_root, f))]
protected.append(ANIM)
hashes_before = {p: sha256(p) for p in protected}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=CHAR)
core = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
character_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.parent == core]
if len(core.data.bones) != 88:
    raise RuntimeError('Expected the existing CoreC skeleton to have 88 bones.')

bpy.ops.import_scene.fbx(filepath=ANIM, automatic_bone_orientation=False, ignore_leaf_bones=False)
mix = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE' and o != core)
src_action = mix.animation_data.action if mix.animation_data else None
if not src_action:
    raise RuntimeError('Mixamo FBX did not contain an armature action.')

mapping = {
    'mixamorig:Hips': 'pelvis',
    'mixamorig:Spine': 'spine_01',
    'mixamorig:Spine1': 'spine_03',
    'mixamorig:Spine2': 'spine_05',
    'mixamorig:Neck': 'neck_01',
    'mixamorig:Head': 'head',
    'mixamorig:LeftShoulder': 'clavicle_l',
    'mixamorig:LeftArm': 'upperarm_l',
    'mixamorig:LeftForeArm': 'lowerarm_l',
    'mixamorig:LeftHand': 'hand_l',
    'mixamorig:RightShoulder': 'clavicle_r',
    'mixamorig:RightArm': 'upperarm_r',
    'mixamorig:RightForeArm': 'lowerarm_r',
    'mixamorig:RightHand': 'hand_r',
    'mixamorig:LeftUpLeg': 'thigh_l',
    'mixamorig:LeftLeg': 'calf_l',
    'mixamorig:LeftFoot': 'foot_l',
    'mixamorig:LeftToeBase': 'ball_l',
    'mixamorig:RightUpLeg': 'thigh_r',
    'mixamorig:RightLeg': 'calf_r',
    'mixamorig:RightFoot': 'foot_r',
    'mixamorig:RightToeBase': 'ball_r',
}
finger_map = {'Index': 'index', 'Middle': 'middle', 'Ring': 'ring', 'Pinky': 'pinky', 'Thumb': 'thumb'}
for side_mix, side_core in [('Left', 'l'), ('Right', 'r')]:
    for mix_digit, core_digit in finger_map.items():
        for segment in range(1, 4):
            mapping[f'mixamorig:{side_mix}Hand{mix_digit}{segment}'] = f'{core_digit}_0{segment}_{side_core}'

src_names = {b.name for b in mix.data.bones}
core_names = {b.name for b in core.data.bones}
missing_map_sources = sorted(k for k in mapping if k not in src_names)
missing_map_targets = sorted(v for v in mapping.values() if v not in core_names)
if missing_map_sources or missing_map_targets:
    raise RuntimeError('Required humanoid mapping bones are missing: %s / %s' % (missing_map_sources, missing_map_targets))

frame_start = int(round(src_action.frame_range[0]))
frame_end = int(round(src_action.frame_range[1]))
bpy.context.scene.render.fps = 30
bpy.context.scene.frame_start = frame_start
bpy.context.scene.frame_end = frame_end
source_duration = (frame_end - frame_start) / 30.0

src_rest = {s: mix.matrix_world @ mix.data.bones[s].matrix_local for s in mapping}
dst_rest = {t: core.matrix_world @ core.data.bones[t].matrix_local for t in mapping.values()}
rest_corrections = []
for s, t in mapping.items():
    angle = math.degrees((dst_rest[t].to_quaternion() @ src_rest[s].to_quaternion().inverted()).angle)
    if angle > 0.01:
        rest_corrections.append({'source': s, 'target': t, 'angle_degrees': round(angle, 4)})

def bone_depth(name):
    d = 0
    b = core.data.bones[name]
    while b.parent:
        d += 1
        b = b.parent
    return d

ordered = sorted(mapping.items(), key=lambda item: bone_depth(item[1]))

def clear_core_pose():
    for pb in core.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
        pb.rotation_mode = 'QUATERNION'
    bpy.context.view_layer.update()

bpy.context.scene.frame_set(frame_start)
bpy.context.view_layer.update()
src_hips_ref = (mix.matrix_world @ mix.pose.bones['mixamorig:Hips'].matrix).translation.copy()
src_leg = ((mix.matrix_world @ mix.data.bones['mixamorig:Hips'].matrix_local).translation -
           (mix.matrix_world @ mix.data.bones['mixamorig:LeftFoot'].matrix_local).translation).length
dst_leg = ((core.matrix_world @ core.data.bones['pelvis'].matrix_local).translation -
           (core.matrix_world @ core.data.bones['foot_l'].matrix_local).translation).length
translation_scale = dst_leg / src_leg if src_leg > 1e-6 else 1.0

if core.animation_data:
    core.animation_data_clear()
for action in list(bpy.data.actions):
    if action != src_action:
        bpy.data.actions.remove(action)
target_action = bpy.data.actions.new(ANIM_NAME)
core.animation_data_create()
core.animation_data.action = target_action

target_rest_local = {}
for dst_name in mapping.values():
    bone = core.data.bones[dst_name]
    local_rest = bone.parent.matrix_local.inverted() @ bone.matrix_local if bone.parent else bone.matrix_local
    target_rest_local[dst_name] = local_rest.to_quaternion()

first_values = {}
for frame in range(frame_start, frame_end + 1):
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    clear_core_pose()
    for src_name, dst_name in ordered:
        src_pose_world = mix.matrix_world @ mix.pose.bones[src_name].matrix
        delta_q = src_pose_world.to_quaternion() @ src_rest[src_name].to_quaternion().inverted()
        desired_world_q = delta_q @ dst_rest[dst_name].to_quaternion()
        pb = core.pose.bones[dst_name]
        parent_world_q = (core.matrix_world @ pb.parent.matrix).to_quaternion() if pb.parent else core.matrix_world.to_quaternion()
        desired_local_q = parent_world_q.inverted() @ desired_world_q
        basis_q = target_rest_local[dst_name].inverted() @ desired_local_q
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = basis_q.normalized()
        pb.scale = (1.0, 1.0, 1.0)
        if dst_name == 'pelvis':
            src_delta = src_pose_world.translation - src_hips_ref
            world_delta = Vector((0.0, 0.0, src_delta.z * translation_scale))
            arm_delta = core.matrix_world.to_3x3().inverted() @ world_delta
            pb.location = core.data.bones[dst_name].matrix_local.to_3x3().inverted() @ arm_delta
        pb.keyframe_insert('rotation_quaternion', frame=frame, group=dst_name)
        if dst_name == 'pelvis':
            pb.keyframe_insert('location', frame=frame, group=dst_name)
    if frame == frame_start:
        first_values = {dst: (core.pose.bones[dst].rotation_quaternion.copy(), core.pose.bones[dst].location.copy()) for dst in mapping.values()}

# Force an exact loop closure by matching the final keyed pose to the first pose.
bpy.context.scene.frame_set(frame_end)
clear_core_pose()
for dst_name, values in first_values.items():
    pb = core.pose.bones[dst_name]
    pb.rotation_mode = 'QUATERNION'
    pb.rotation_quaternion = values[0]
    pb.location = values[1]
    pb.scale = (1.0, 1.0, 1.0)
    pb.keyframe_insert('rotation_quaternion', frame=frame_end, group=dst_name)
    if dst_name == 'pelvis':
        pb.keyframe_insert('location', frame=frame_end, group=dst_name)

for fc in target_action.fcurves:
    for kp in fc.keyframe_points:
        kp.interpolation = 'LINEAR'
    fc.extrapolation = 'CONSTANT'

source_location_fcurves = sum(1 for fc in src_action.fcurves if fc.data_path.endswith('.location'))
source_scale_fcurves = sum(1 for fc in src_action.fcurves if fc.data_path.endswith('.scale'))
source_location_keys = sum(len(fc.keyframe_points) for fc in src_action.fcurves if fc.data_path.endswith('.location'))
source_scale_keys = sum(len(fc.keyframe_points) for fc in src_action.fcurves if fc.data_path.endswith('.scale'))

# Foot contact and in-place QA on the baked target animation.
foot_samples = {'foot_l': [], 'foot_r': []}
pelvis_xy = []
for frame in range(frame_start, frame_end + 1):
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    for name in foot_samples:
        foot_samples[name].append((core.matrix_world @ core.pose.bones[name].matrix).translation.copy())
    p = (core.matrix_world @ core.pose.bones['pelvis'].matrix).translation
    pelvis_xy.append(Vector((p.x, p.y)))

foot_results = {}
for name, pts in foot_samples.items():
    ref = pts[0]
    horizontal = max(math.hypot(p.x-ref.x, p.y-ref.y) for p in pts)
    vertical = max(p.z for p in pts) - min(p.z for p in pts)
    foot_results[name] = {'max_horizontal_drift_m': horizontal, 'vertical_range_m': vertical, 'pass': horizontal <= 0.05 and vertical <= 0.05}
pelvis_horizontal = max((p - pelvis_xy[0]).length for p in pelvis_xy)

# Sample evaluated meshes for non-finite or explosive deformation.
sample_frames = sorted({frame_start, (frame_start + frame_end) // 2, frame_end})
deformation_ok = True
deformation_samples = []
depsgraph = bpy.context.evaluated_depsgraph_get()
for frame in sample_frames:
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    min_v = Vector((1e9, 1e9, 1e9)); max_v = Vector((-1e9, -1e9, -1e9)); finite = True
    for obj in character_meshes:
        ev = obj.evaluated_get(depsgraph)
        mesh = ev.to_mesh()
        for v in mesh.vertices:
            w = obj.matrix_world @ v.co
            finite = finite and all(math.isfinite(x) for x in w)
            for i in range(3):
                min_v[i] = min(min_v[i], w[i]); max_v[i] = max(max_v[i], w[i])
        ev.to_mesh_clear()
    size = max_v - min_v
    ok = finite and max(size) < 10.0
    deformation_ok = deformation_ok and ok
    deformation_samples.append({'frame': frame, 'finite': finite, 'bounds_size': list(size), 'pass': ok})

# Remove the Mixamo rig, its helper objects, and importer-only geometry.
for obj in list(bpy.data.objects):
    if obj != core and obj not in character_meshes:
        bpy.data.objects.remove(obj, do_unlink=True)
if src_action.name in bpy.data.actions:
    bpy.data.actions.remove(src_action)
core.animation_data.action = target_action

for obj in bpy.data.objects:
    obj.select_set(False)
for obj in [core] + character_meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = core
bpy.context.scene.frame_set(frame_start)

bpy.ops.export_scene.gltf(
    filepath=CHAR, export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='ACTIONS',
    export_frame_range=True, export_force_sampling=True,
    export_skins=True, export_morph=False, export_apply=False,
    export_all_influences=True, export_materials='EXPORT', export_image_format='AUTO')

hashes_after = {p: sha256(p) for p in protected}
changed_sources = [p for p in protected if hashes_before[p] != hashes_after[p]]
unmapped_source = sorted(src_names - set(mapping))
unmapped_core = sorted(core_names - set(mapping.values()))
metrics = {
    'source_animation': ANIM,
    'source_frame_start': frame_start,
    'source_frame_end': frame_end,
    'source_frame_count': frame_end - frame_start + 1,
    'source_fps': 30,
    'source_duration_seconds': source_duration,
    'final_animation_name': ANIM_NAME,
    'final_duration_seconds': source_duration,
    'mapped_bones': mapping,
    'mapped_bone_count': len(mapping),
    'unmapped_mixamo_bones': unmapped_source,
    'unmapped_core_bones': unmapped_core,
    'removed_position_fcurves': source_location_fcurves,
    'removed_position_keys': source_location_keys,
    'removed_scale_fcurves': source_scale_fcurves,
    'removed_scale_keys': source_scale_keys,
    'retained_translation_tracks': ['pelvis.location (vertical component only)'],
    'rest_pose_corrections': rest_corrections,
    'translation_scale': translation_scale,
    'root_motion': {'in_place': pelvis_horizontal <= 0.001, 'pelvis_max_horizontal_displacement_m': pelvis_horizontal, 'armature_object_motion': 'removed'},
    'foot_contact': foot_results,
    'deformation_test_pass': deformation_ok,
    'deformation_samples': deformation_samples,
    'final_skeleton_count': 1,
    'source_files_changed': changed_sources,
}
with open(METRICS, 'w', encoding='utf-8') as f:
    json.dump(metrics, f, indent=2)

with open(REPORT, 'a', encoding='utf-8') as f:
    f.write('\n\n## Mixamo idle retarget\n\n')
    f.write('- Resolved source: `%s`\n' % ANIM)
    f.write('- Animation: `%s` (looping, in place)\n' % ANIM_NAME)
    f.write('- Source frames: **%d** (%d-%d at 30 FPS), duration **%.4f s**\n' % (metrics['source_frame_count'], frame_start, frame_end, source_duration))
    f.write('- Final duration: **%.4f s**\n' % source_duration)
    f.write('- Mapped bones: **%d**; unmapped Mixamo bones: **%d**; unmapped CoreC helper/twist bones: **%d**\n' % (len(mapping), len(unmapped_source), len(unmapped_core)))
    f.write('- Removed source position tracks: **%d curves / %d keys**\n' % (source_location_fcurves, source_location_keys))
    f.write('- Removed source scale tracks: **%d curves / %d keys**\n' % (source_scale_fcurves, source_scale_keys))
    f.write('- Retained translation: pelvis vertical motion only; armature and horizontal root motion removed.\n')
    f.write('- Rest-pose orientation corrections: **%d mapped bones**\n' % len(rest_corrections))
    f.write('- Foot contact: left **%s**, right **%s**\n' % ('PASS' if foot_results['foot_l']['pass'] else 'FAIL', 'PASS' if foot_results['foot_r']['pass'] else 'FAIL'))
    f.write('- Deformation samples: **%s**\n' % ('PASS' if deformation_ok else 'FAIL'))
    f.write('- Final skeletons: **1**; temporary source rig removed.\n')
    f.write('- Purchased source files changed: **%d**\n' % len(changed_sources))
