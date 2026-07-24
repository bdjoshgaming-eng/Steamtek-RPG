import bpy, json
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:\My Game\Steamtek-RPG\incoming\corec_male_character\SKM_CoreC_Male_HairC07.fbx', automatic_bone_orientation=False, ignore_leaf_bones=False)
out=[]
for m in bpy.data.materials:
 n=[]
 if m.use_nodes:
  for node in m.node_tree.nodes:
   if node.type=='TEX_IMAGE': n.append({'node':node.name,'image':node.image.name if node.image else None,'path':node.image.filepath if node.image else None})
 out.append({'name':m.name,'nodes':n})
print(json.dumps(out,indent=2))
