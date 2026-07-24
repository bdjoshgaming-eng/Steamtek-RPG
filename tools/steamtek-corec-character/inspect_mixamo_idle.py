import bpy, json

CHAR = r'C:\My Game\Steamtek-RPG\output\corec_male_character\STK_CHAR_Player_M_CoreC_Hacker.glb'
ANIM = r'C:\My Game\Steamtek-RPG\incoming\corsec_male_animations\MX_Idle.fbx'

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=CHAR)
core = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
bpy.ops.import_scene.fbx(filepath=ANIM, automatic_bone_orientation=False, ignore_leaf_bones=False)
mix = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE' and o != core)
action = mix.animation_data.action if mix.animation_data else None
print(json.dumps({
    'core_armature': core.name,
    'core_bones': len(core.data.bones),
    'core_bone_names': sorted(b.name for b in core.data.bones),
    'mixamo_armature': mix.name,
    'mixamo_bones': len(mix.data.bones),
    'mixamo_bone_names': sorted(b.name for b in mix.data.bones),
    'action': action.name if action else None,
    'frame_range': list(action.frame_range) if action else None,
    'fps': bpy.context.scene.render.fps,
    'fcurves': len(action.fcurves) if action else 0,
    'object_scale': list(mix.scale),
}, indent=2))
