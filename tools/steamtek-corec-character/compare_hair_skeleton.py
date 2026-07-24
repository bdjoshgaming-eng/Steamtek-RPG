import bpy, os, json
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r'C:\My Game\Steamtek-RPG\output\corec_male_character\STK_CHAR_Player_M_CoreC_Hacker.glb')
master = next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
master_names={b.name for b in master.data.bones}
bpy.ops.import_scene.fbx(filepath=r'C:\My Game\Steamtek-RPG\incoming\corec_male_character\SKM_CoreC_Male_HairC07.fbx', automatic_bone_orientation=False, ignore_leaf_bones=False)
hair_arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE' and o!=master)
hair_mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==hair_arm)
hair_names={b.name for b in hair_arm.data.bones}
diff_names=sorted(master_names ^ hair_names)
diff_bind=[]
if not diff_names:
    for b in master.data.bones:
        hb=hair_arm.data.bones[b.name]
        d=b.matrix_local-hb.matrix_local
        if max(abs(d[r][c]) for r in range(4) for c in range(4))>1e-4:
            diff_bind.append(b.name)
print(json.dumps({'master_bones':len(master_names),'hair_bones':len(hair_names),'name_differences':diff_names,'bind_differences':diff_bind,'hair_mesh':hair_mesh.name,'tris':sum(len(p.vertices)-2 for p in hair_mesh.data.polygons),'materials':[m.name for m in hair_mesh.data.materials],'images':[im.filepath for im in bpy.data.images]},indent=2))
