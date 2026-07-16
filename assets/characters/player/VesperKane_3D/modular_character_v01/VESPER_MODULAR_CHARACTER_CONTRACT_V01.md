# Vesper Kane Modular Character Contract v0.1

## Locked foundation

- Character: `Steamtek_C001_VesperKane`
- Skeleton source: `Steamtek_C001_VesperKane_ProductionMesh_v11.blend`
- Bone names, hierarchy, rest pose, scale, ground contact, and animation actions are immutable.
- Required actions: `STK_IDLE` and `STK_WALK`.
- Godot model-forward correction remains `+40 degrees`.
- Vesper's mechanical arm is the physical left arm.

## Base-body regions

The base body is a fitted neutral undersuit/body shell, not underwear and not a temporary primitive blockout. It is divided into hideable regions:

- `head`
- `neck`
- `torso`
- `pelvis`
- `upper_arm_r`
- `forearm_r`
- `hand_r`
- `mechanical_arm_l`
- `thigh_l`, `thigh_r`
- `shin_l`, `shin_r`
- `foot_l`, `foot_r`

Every base-body mesh begins with `VK_MB01_` and carries `steamtek_body_region` metadata.

## Equipment slots

- `headgear`
- `outer_torso`
- `shoulders`
- `gloves`
- `legs`
- `boots`
- `waist`
- `back`
- `mechanical_arm_attachment`
- `weapon_right`
- `item_left`
- `hip_right`

Every default outfit mesh begins with `VK_SLOT_<SLOT>_` and carries `steamtek_equipment_slot` metadata.

## Body masking

Equipped garments declare the body regions they cover. Godot hides only those regions, preventing clipping without changing the skeleton. Default outfit masks:

- Outer torso: torso, pelvis, upper right arm, right forearm
- Gloves: right hand
- Legs: both thighs and shins
- Boots: both feet
- Headgear: no body masking; head remains visible
- Mechanical attachments: no arm masking; they mount to the permanent mechanical arm

## Visual rules

- Neutral gunmetal, charcoal cloth, rubber, skin, and aged brass materials.
- No magenta or cyan environment lighting baked into textures or materials.
- Small functional indicators may be separate swappable meshes; the base materials remain neutral.
- Silhouette must read at the locked Steamtek gameplay camera.

## Export rules

- Versioned GLB; never replace the approved working player visual until review passes.
- Export the locked roots, armature, base-body meshes, and all slot meshes.
- Preserve skins and action clips.
- No unapplied object scaling on the character roots.
- Validate body-only, fully equipped, and one deliberately mixed equipment state.

