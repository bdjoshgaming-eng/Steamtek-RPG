import bpy, os, json
from mathutils import Vector
SRC = r'C:\My Game\Steamtek-RPG\incoming\corec_male_character\SKM_CoreC_Male_HairC07.fbx'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC, automatic_bone_orientation=False, ignore_leaf_bones=False)
rows=[]
for o in bpy.context.scene.objects:
    rows.append({'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None,
                 'verts':len(o.data.vertices) if o.type=='MESH' else None,
                 'tris':sum(len(p.vertices)-2 for p in o.data.polygons) if o.type=='MESH' else None,
                 'mods':[m.object.name if m.type=='ARMATURE' and m.object else None for m in o.modifiers]})
print(json.dumps(rows, indent=2))
