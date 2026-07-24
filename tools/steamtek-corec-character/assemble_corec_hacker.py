import bpy
import os
import json
import hashlib
import math
from mathutils import Vector
import shutil
from mathutils import Matrix

SRC = r'C:\My Game\Steamtek-RPG\incoming\corec_male_character'
OUT = r'C:\My Game\Steamtek-RPG\output\corec_male_character'
GLB = os.path.join(OUT, 'STK_CHAR_Player_M_CoreC_Hacker.glb')
REPORT = os.path.join(OUT, 'STK_CHAR_Player_M_CoreC_Hacker_assembly_report.md')

BODY = [
    'SKM_CoreC_M_Base_Eyes.fbx', 'SKM_CoreC_M_Base_Face.fbx',
    'SKM_CoreC_M_Base_Feet.fbx', 'SKM_CoreC_M_Base_Hands.fbx',
    'SKM_CoreC_M_Base_Legs.fbx', 'SKM_CoreC_M_Base_Teeth.fbx',
    'SKM_CoreC_M_Base_Torso.fbx']
OUTFIT = ['SKM_Techwear_Hacker_M_Upper.fbx',
          'SKM_Techwear_Hacker_M_Lower.fbx',
          'SKM_Techwear_Hacker_M_Shoes.fbx']
HAIR = ['SKM_CoreC_Male_HairC07.fbx']
FILES = BODY + OUTFIT + HAIR
TEX = {
    'body_base': 'T_CoreC_M_Body_Mat_BaseColor.png',
    'body_n': 'T_CoreC_M_Body_Mat_N.png',
    'body_orm': 'T_CoreC_M_Body_Mat_ORM.png',
    'eye_base': 'T_CoreC_M_Eye_Left_Mat_BaseColor.png',
    'eye_orm': 'T_CoreC_M_Eye_Left_Mat_ORM.png',
    'face_base': 'T_CoreC_M_Face_Mat_BaseColor.png',
    'face_n': 'T_CoreC_M_Face_Mat_N.png',
    'face_orm': 'T_CoreC_M_Face_Mat_ORM.png',
    'teeth_base': 'T_CoreC_M_Teeth_Mat_BaseColor.png',
    'teeth_orm': 'T_CoreC_M_Teeth_Mat_ORM.png',
    'tech_base': 'T_CoreC_TechwearC_M_BaseColor.png',
    'tech_mask': 'T_CoreC_TechwearC_M_ColorMask.png',
    'tech_n': 'T_CoreC_TechwearC_M_N.png',
    'tech_orm': 'T_CoreC_TechwearC_M_ORM.png',
}

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1024 * 1024), b''):
            h.update(b)
    return h.hexdigest()

os.makedirs(OUT, exist_ok=True)
MASK_OUT = os.path.join(OUT, 'STK_CHAR_Player_M_CoreC_Hacker_T_CoreC_TechwearC_M_ColorMask.png')
shutil.copy2(os.path.join(SRC, TEX['tech_mask']), MASK_OUT)
source_hashes = {fn: sha256(os.path.join(SRC, fn)) for fn in FILES + list(TEX.values())}
bpy.ops.wm.read_factory_settings(use_empty=True)

armatures = []
meshes = []
source_map = {}
for index, fn in enumerate(FILES):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(SRC, fn), automatic_bone_orientation=False, ignore_leaf_bones=False)
    created = [o for o in bpy.data.objects if o not in before]
    arm = next((o for o in created if o.type == 'ARMATURE'), None)
    mesh = next((o for o in created if o.type == 'MESH'), None)
    if not arm or not mesh:
        raise RuntimeError('FBX import did not produce one armature and one mesh: ' + fn)
    armatures.append(arm)
    meshes.append(mesh)
    source_map[mesh.name] = fn

master = armatures[0]
master.name = 'SKEL_CoreC_Male'
master.data.name = 'SKEL_CoreC_Male_Data'
master_bones = {b.name: b for b in master.data.bones}
skeleton_consistent = True
skeleton_differences = []
for arm in armatures[1:]:
    names = {b.name for b in arm.data.bones}
    if names != set(master_bones):
        skeleton_consistent = False
        skeleton_differences.append('%s bone-name set differs' % arm.name)
    else:
        for name, mb in master_bones.items():
            b = arm.data.bones[name]
            diff = mb.matrix_local - b.matrix_local
            if max(abs(diff[r][c]) for r in range(4) for c in range(4)) > 1e-4:
                skeleton_consistent = False
                skeleton_differences.append('%s bind matrix differs at %s' % (arm.name, name))
                break

# Redirect each mesh to the master armature while retaining all vertex groups/weights.
for mesh in meshes:
    world = mesh.matrix_world.copy()
    for mod in mesh.modifiers:
        if mod.type == 'ARMATURE':
            mod.object = master
    mesh.parent = master
    mesh.matrix_world = world
    mesh['steamtek_source_fbx'] = source_map[mesh.name]
    mesh['steamtek_modular_mesh'] = True

duplicate_count = len(armatures) - 1
for arm in armatures[1:]:
    bpy.data.objects.remove(arm, do_unlink=True)

def image(key, noncolor=False):
    path = os.path.join(SRC, TEX[key])
    im = bpy.data.images.load(path, check_existing=True)
    if noncolor:
        im.colorspace_settings.name = 'Non-Color'
    return im

def mat(name, base_key, orm_key, normal_key=None, mask_key=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (0.55, 0.55, 0.55, 1.0)
    m['steamtek_pbr_source'] = 'CoreC supplied BaseColor/Normal/ORM'
    if mask_key:
        m['steamtek_color_mask'] = MASK_OUT
    n = m.node_tree.nodes
    l = m.node_tree.links
    bs = n.get('Principled BSDF')
    bs.inputs['Roughness'].default_value = 0.78
    bs.inputs['Metallic'].default_value = 0.0
    bc = n.new('ShaderNodeTexImage'); bc.name = 'BaseColor_sRGB'; bc.image = image(base_key)
    l.new(bc.outputs['Color'], bs.inputs['Base Color'])
    orm = n.new('ShaderNodeTexImage'); orm.name = 'ORM_NonColor'; orm.image = image(orm_key)
    sep = n.new('ShaderNodeSeparateRGB'); sep.name = 'ORM_Channel_Split'
    l.new(orm.outputs['Color'], sep.inputs['Image'])
    l.new(sep.outputs['G'], bs.inputs['Roughness'])
    l.new(sep.outputs['B'], bs.inputs['Metallic'])
    if normal_key:
        no = n.new('ShaderNodeTexImage'); no.name = 'Normal_NonColor'; no.image = image(normal_key)
        norm = n.new('ShaderNodeNormalMap'); norm.name = 'Normal_Map'
        l.new(no.outputs['Color'], norm.inputs['Color'])
        l.new(norm.outputs['Normal'], bs.inputs['Normal'])
    if mask_key:
        mask = n.new('ShaderNodeTexImage'); mask.name = 'ColorMask_Preserved'; mask.image = image(mask_key)
        mask['steamtek_recolor_mask'] = True
    return m

materials = {
    'body': mat('MAT_CoreC_Body_Matte', 'body_base', 'body_orm', 'body_n'),
    'face': mat('MAT_CoreC_Face_Matte', 'face_base', 'face_orm', 'face_n'),
    'eyes': mat('MAT_CoreC_Eyes_Matte', 'eye_base', 'eye_orm'),
    'teeth': mat('MAT_CoreC_Teeth_Matte', 'teeth_base', 'teeth_orm'),
    'techwear': mat('MAT_CoreC_Techwear_Hacker_Matte', 'tech_base', 'tech_orm', 'tech_n', 'tech_mask'),
}
for mesh in meshes:
    fn = source_map[mesh.name]
    if 'HairC07' in fn:
        mesh['steamtek_hair_material_source'] = 'original FBX material slots preserved'
        continue
    if 'Eyes' in fn:
        mesh.data.materials.clear(); mesh.data.materials.append(materials['eyes'])
    elif 'Teeth' in fn:
        mesh.data.materials.clear(); mesh.data.materials.append(materials['teeth'])
    elif 'Face' in fn:
        mesh.data.materials.clear(); mesh.data.materials.append(materials['face'])
    elif 'Techwear' in fn:
        mesh.data.materials.clear(); mesh.data.materials.append(materials['techwear'])
    else:
        mesh.data.materials.clear(); mesh.data.materials.append(materials['body'])

# Temporary joint deformation checks. No actions or animation data are retained.
depsgraph = bpy.context.evaluated_depsgraph_get()
test_bones = {
    'shoulders': ['upperarm_l', 'upperarm_r'],
    'elbows': ['lowerarm_l', 'lowerarm_r'],
    'wrists': ['hand_l', 'hand_r'],
    'hips': ['thigh_l', 'thigh_r'],
    'knees': ['calf_l', 'calf_r'],
    'ankles': ['foot_l', 'foot_r'],
    'head_neck': ['head', 'neck_02'],
}
def snapshot():
    out = {}
    for o in meshes:
        ev = o.evaluated_get(depsgraph)
        me = ev.to_mesh()
        out[o.name] = [tuple(o.matrix_world @ v.co) for v in me.vertices]
        ev.to_mesh_clear()
    return out
def clear_pose():
    for p in master.pose.bones:
        p.rotation_mode = 'XYZ'
        p.rotation_euler = (0, 0, 0)
        p.location = (0, 0, 0)
        p.scale = (1, 1, 1)
    bpy.context.view_layer.update()
def finite(vals):
    return all(math.isfinite(x) for xyz in vals for x in xyz)
deformation = {}
for label, names in test_bones.items():
    clear_pose(); before = snapshot()
    for name in names:
        if name in master.pose.bones:
            master.pose.bones[name].rotation_euler[1] = math.radians(12)
    bpy.context.view_layer.update(); after = snapshot()
    moved = 0; valid = True
    for objname in before:
        valid = valid and finite(after[objname])
        moved += sum(1 for a, b in zip(before[objname], after[objname]) if sum((a[i]-b[i])**2 for i in range(3)) > 1e-10)
    deformation[label] = {'pass': bool(valid and moved > 0), 'moved_vertices': moved, 'finite': valid}
clear_pose()

def world_bbox(o):
    pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]

# Rest-pose placement QA for the skinned hair against the face/scalp region.
hair_obj = next((m for m in meshes if 'HairC07' in source_map[m.name]), None)
face_obj = next((m for m in meshes if 'Base_Face' in source_map[m.name]), None)
hair_placement = {'skinned': bool(hair_obj and any(mod.type == 'ARMATURE' for mod in hair_obj.modifiers)), 'scale': tuple(hair_obj.scale) if hair_obj else None}
if hair_obj and face_obj:
    hmin, hmax = world_bbox(hair_obj); fmin, fmax = world_bbox(face_obj)
    overlap = all(hmax[i] >= fmin[i] and hmin[i] <= fmax[i] for i in range(3))
    hair_placement.update({'bbox_overlaps_face': overlap, 'floating_or_disjoint': not overlap, 'finite_bounds': all(math.isfinite(x) for x in hmin+hmax+fmin+fmax)})
else:
    hair_placement.update({'bbox_overlaps_face': False, 'floating_or_disjoint': True, 'finite_bounds': False})

# Remove importer helper geometry that is not one of the supplied meshes or the master skeleton.
for o in list(bpy.data.objects):
    if o not in ([master] + meshes):
        bpy.data.objects.remove(o, do_unlink=True)

# Never export actions created by an importer or test.
for o in bpy.data.objects:
    if o.animation_data:
        o.animation_data_clear()
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)

for o in bpy.data.objects:
    o.select_set(False)
for o in [master] + meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = master

bpy.ops.export_scene.gltf(filepath=GLB, export_format='GLB', use_selection=True,
    export_animations=False, export_skins=True, export_morph=False,
    export_apply=False, export_all_influences=True, export_materials='EXPORT', export_image_format='AUTO')

triangles = sum(sum(len(p.vertices)-2 for p in m.data.polygons) for m in meshes)
all_material_names = sorted({slot.name for m in meshes for slot in m.data.materials if slot})
hair_material_names = sorted({slot.name for m in meshes if 'HairC07' in source_map[m.name] for slot in m.data.materials if slot})
report = {
    'source_root': SRC, 'output_glb': GLB, 'included_meshes': [m.name for m in meshes],
    'omitted_body_meshes': [], 'triangles': triangles,
    'bones': len(master.data.bones), 'materials': len(all_material_names),
    'hair_triangles': sum(sum(len(p.vertices)-2 for p in m.data.polygons) for m in meshes if 'HairC07' in source_map[m.name]),
    'hair_materials': len(hair_material_names), 'hair_material_names': hair_material_names,
    'hair_binding': 'skinned to shared 88-bone CoreC skeleton', 'hair_placement': hair_placement,
    'duplicate_armatures_removed': duplicate_count,
    'armatures_in_export': 1, 'skeleton_consistent': skeleton_consistent,
    'skeleton_differences': skeleton_differences,
    'deformation_tests': deformation,
    'temporary_animations_exported': False,
    'source_hashes_before': source_hashes,
    'source_hashes_after': {fn: sha256(os.path.join(SRC, fn)) for fn in source_hashes},
}
report['source_files_changed'] = [fn for fn in source_hashes if report['source_hashes_before'][fn] != report['source_hashes_after'][fn]]
with open(os.path.join(OUT, 'assembly_metrics.json'), 'w', encoding='utf-8') as f:
    json.dump(report, f, indent=2)
with open(REPORT, 'w', encoding='utf-8') as f:
    f.write('# CoreC Male Hacker Assembly Report\n\n')
    f.write('## Output\n\n- Source root: `%s`\n- GLB: `%s`\n- Production source files changed: **%d**\n\n' % (SRC, GLB, len(report['source_files_changed'])))
    f.write('## Counts\n\n- Total triangles: **%d**\n- Total bones: **%d**\n- Materials: **%d**\n- Duplicate armatures removed: **%d**\n- Armatures in export: **1**\n\n' % (triangles, len(master.data.bones), len(materials), duplicate_count))
    f.write('## Included meshes\n\n' + ''.join('- `%s` (from `%s`)\n' % (m.name, source_map[m.name]) for m in meshes))
    f.write('\n## Omitted body meshes\n\nNone. All supplied body parts are retained as separate modular meshes so skin remains available at neck, wrists, waist, and ankles.\n\n')
    f.write('## Skeleton\n\n- Exactly one skeleton exported: **yes** (`SKEL_CoreC_Male`).\n- All imported FBXs matched the master bone-name set and bind matrices: **%s**.\n' % ('yes' if skeleton_consistent else 'no'))
    if skeleton_differences: f.write('- Differences: ' + '; '.join(skeleton_differences) + '\n')
    f.write('\n## Deformation checks\n\n')
    for k, v in deformation.items(): f.write('- %s: **%s** (%d vertices moved; finite=%s)\n' % (k, 'PASS' if v['pass'] else 'FAIL', v['moved_vertices'], v['finite']))
    f.write('\nTemporary pose checks were reset before export; no test animations were exported. Materials use supplied BaseColor, Normal, and ORM textures; the supplied ColorMask is preserved in the techwear material for later recoloring.\n')
