import bpy, json
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r'C:\My Game\Steamtek-RPG\output\corec_male_character\STK_CHAR_Player_M_CoreC_Hacker.glb')
pts=[]
for o in bpy.context.scene.objects:
    if o.type=='MESH':
        pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
print(json.dumps({'objects':[(o.name,o.type,o.parent.name if o.parent else None,len(o.data.polygons) if o.type=='MESH' else None) for o in bpy.context.scene.objects], 'min':[min(p[i] for p in pts) for i in range(3)], 'max':[max(p[i] for p in pts) for i in range(3)]}, indent=2))
