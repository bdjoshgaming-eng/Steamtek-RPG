import bpy, os, json, math

SRC = r'C:\My Game\Steamtek-RPG\incoming\corec_male_character'
files = [
 'SKM_CoreC_M_Base_Eyes.fbx','SKM_CoreC_M_Base_Face.fbx','SKM_CoreC_M_Base_Feet.fbx','SKM_CoreC_M_Base_Hands.fbx','SKM_CoreC_M_Base_Legs.fbx','SKM_CoreC_M_Base_Teeth.fbx','SKM_CoreC_M_Base_Torso.fbx',
 'SKM_Techwear_Hacker_M_Upper.fbx','SKM_Techwear_Hacker_M_Lower.fbx','SKM_Techwear_Hacker_M_Shoes.fbx']

bpy.ops.wm.read_factory_settings(use_empty=True)
rows=[]
for fn in files:
    bpy.ops.import_scene.fbx(filepath=os.path.join(SRC,fn), automatic_bone_orientation=False, ignore_leaf_bones=False)
    new=[]
    for o in bpy.context.selected_objects:
        new.append({"name":o.name,"type":o.type,"verts":len(o.data.vertices) if o.type=='MESH' else None,"tris":sum(len(p.vertices)-2 for p in o.data.polygons) if o.type=='MESH' else None,"parent":o.parent.name if o.parent else None,"mods":[m.object.name if m.type=='ARMATURE' and m.object else None for m in o.modifiers]})
    rows.append({"file":fn,"objects":new,"all_created":[{"name":o.name,"type":o.type} for o in created]})
    bpy.ops.object.select_all(action='DESELECT')
print(json.dumps(rows, indent=2))
