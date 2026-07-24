import bpy, json
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:\My Game\Steamtek-RPG\incoming\corec_male_character\SKM_CoreC_M_Base_Torso.fbx', automatic_bone_orientation=False, ignore_leaf_bones=False)
body=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
bpy.ops.import_scene.fbx(filepath=r'C:\My Game\Steamtek-RPG\incoming\corec_male_character\SKM_CoreC_Male_HairC07.fbx', automatic_bone_orientation=False, ignore_leaf_bones=False)
hair=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE' and o!=body)
names={b.name for b in body.data.bones}; hnames={b.name for b in hair.data.bones}; diffs=[]
if names==hnames:
 for b in body.data.bones:
  d=b.matrix_local-hair.data.bones[b.name].matrix_local
  if max(abs(d[r][c]) for r in range(4) for c in range(4))>1e-4: diffs.append(b.name)
print(json.dumps({'body_bones':len(names),'hair_bones':len(hnames),'name_differences':sorted(names^hnames),'bind_differences':diffs},indent=2))
