# CoreC Male Hacker Assembly Report

## Output

- Source root: `C:\My Game\Steamtek-RPG\incoming\corec_male_character`
- GLB: `C:\My Game\Steamtek-RPG\output\corec_male_character\STK_CHAR_Player_M_CoreC_Hacker.glb`
- Production source files changed: **0**

## Counts

- Total triangles: **73544**
- Total bones: **88**
- Materials: **5**
- Duplicate armatures removed: **10**
- Armatures in export: **1**

## Included meshes

- `CoreC_M_Face_Eyes` (from `SKM_CoreC_M_Base_Eyes.fbx`)
- `CoreC_M_Base_Face` (from `SKM_CoreC_M_Base_Face.fbx`)
- `CoreC_M_Base_Feet` (from `SKM_CoreC_M_Base_Feet.fbx`)
- `CoreC_M_Base_Hands` (from `SKM_CoreC_M_Base_Hands.fbx`)
- `CoreC_M_Base_Legs` (from `SKM_CoreC_M_Base_Legs.fbx`)
- `CoreC_M_Face_Teeth` (from `SKM_CoreC_M_Base_Teeth.fbx`)
- `CoreC_M_Base_Torso` (from `SKM_CoreC_M_Base_Torso.fbx`)
- `SKM_Techwear_Hacker_M_Jacket` (from `SKM_Techwear_Hacker_M_Upper.fbx`)
- `SKM_Techwear_Hacker_M_Pants` (from `SKM_Techwear_Hacker_M_Lower.fbx`)
- `SKM_Techwear_Hacker_M_Shoes` (from `SKM_Techwear_Hacker_M_Shoes.fbx`)
- `SKM_CoreC_Male_HairC07.001` (from `SKM_CoreC_Male_HairC07.fbx`)

## Omitted body meshes

None. All supplied body parts are retained as separate modular meshes so skin remains available at neck, wrists, waist, and ankles.

## Skeleton

- Exactly one skeleton exported: **yes** (`SKEL_CoreC_Male`).
- All imported FBXs matched the master bone-name set and bind matrices: **yes**.

## Deformation checks

- shoulders: **PASS** (5528 vertices moved; finite=True)
- elbows: **PASS** (4396 vertices moved; finite=True)
- wrists: **PASS** (2860 vertices moved; finite=True)
- hips: **PASS** (5357 vertices moved; finite=True)
- knees: **PASS** (3800 vertices moved; finite=True)
- ankles: **PASS** (2390 vertices moved; finite=True)
- head_neck: **PASS** (27438 vertices moved; finite=True)

Temporary pose checks were reset before export; no test animations were exported. Materials use supplied BaseColor, Normal, and ORM textures; the supplied ColorMask is preserved in the techwear material for later recoloring.


## Mixamo idle retarget

- Resolved source: `C:\My Game\Steamtek-RPG\incoming\corsec_male_animations\MX_Idle.fbx`
- Animation: `STK_Idle_Mixamo_01` (looping, in place)
- Source frames: **251** (1-251 at 30 FPS), duration **8.3333 s**
- Final duration: **8.3667 s in Godot** (8.3333 s keyed motion span).
- Mapped bones: **52**; unmapped Mixamo bones: **13**; unmapped CoreC helper/twist bones: **36**
- Removed source position tracks: **156 curves / 16656 keys**
- Removed source scale tracks: **156 curves / 16656 keys**
- Retained translation: pelvis vertical motion only; armature and horizontal root motion removed.
- Rest-pose orientation corrections: **52 mapped bones**
- Foot contact: left **PASS**, right **PASS**
- Deformation samples: **PASS**
- Godot load/playback: **PASS** (`STK_Idle_Mixamo_01`, loop mode enabled).
- Final skeletons: **1**; temporary source rig removed.
- Purchased source files changed: **0**


## Retarget mapping detail

### Mapped bones

- `mixamorig:Hips` -> `pelvis`
- `mixamorig:Spine` -> `spine_01`
- `mixamorig:Spine1` -> `spine_03`
- `mixamorig:Spine2` -> `spine_05`
- `mixamorig:Neck` -> `neck_01`
- `mixamorig:Head` -> `head`
- `mixamorig:LeftShoulder` -> `clavicle_l`
- `mixamorig:LeftArm` -> `upperarm_l`
- `mixamorig:LeftForeArm` -> `lowerarm_l`
- `mixamorig:LeftHand` -> `hand_l`
- `mixamorig:RightShoulder` -> `clavicle_r`
- `mixamorig:RightArm` -> `upperarm_r`
- `mixamorig:RightForeArm` -> `lowerarm_r`
- `mixamorig:RightHand` -> `hand_r`
- `mixamorig:LeftUpLeg` -> `thigh_l`
- `mixamorig:LeftLeg` -> `calf_l`
- `mixamorig:LeftFoot` -> `foot_l`
- `mixamorig:LeftToeBase` -> `ball_l`
- `mixamorig:RightUpLeg` -> `thigh_r`
- `mixamorig:RightLeg` -> `calf_r`
- `mixamorig:RightFoot` -> `foot_r`
- `mixamorig:RightToeBase` -> `ball_r`
- `mixamorig:LeftHandIndex1` -> `index_01_l`
- `mixamorig:LeftHandIndex2` -> `index_02_l`
- `mixamorig:LeftHandIndex3` -> `index_03_l`
- `mixamorig:LeftHandMiddle1` -> `middle_01_l`
- `mixamorig:LeftHandMiddle2` -> `middle_02_l`
- `mixamorig:LeftHandMiddle3` -> `middle_03_l`
- `mixamorig:LeftHandRing1` -> `ring_01_l`
- `mixamorig:LeftHandRing2` -> `ring_02_l`
- `mixamorig:LeftHandRing3` -> `ring_03_l`
- `mixamorig:LeftHandPinky1` -> `pinky_01_l`
- `mixamorig:LeftHandPinky2` -> `pinky_02_l`
- `mixamorig:LeftHandPinky3` -> `pinky_03_l`
- `mixamorig:LeftHandThumb1` -> `thumb_01_l`
- `mixamorig:LeftHandThumb2` -> `thumb_02_l`
- `mixamorig:LeftHandThumb3` -> `thumb_03_l`
- `mixamorig:RightHandIndex1` -> `index_01_r`
- `mixamorig:RightHandIndex2` -> `index_02_r`
- `mixamorig:RightHandIndex3` -> `index_03_r`
- `mixamorig:RightHandMiddle1` -> `middle_01_r`
- `mixamorig:RightHandMiddle2` -> `middle_02_r`
- `mixamorig:RightHandMiddle3` -> `middle_03_r`
- `mixamorig:RightHandRing1` -> `ring_01_r`
- `mixamorig:RightHandRing2` -> `ring_02_r`
- `mixamorig:RightHandRing3` -> `ring_03_r`
- `mixamorig:RightHandPinky1` -> `pinky_01_r`
- `mixamorig:RightHandPinky2` -> `pinky_02_r`
- `mixamorig:RightHandPinky3` -> `pinky_03_r`
- `mixamorig:RightHandThumb1` -> `thumb_01_r`
- `mixamorig:RightHandThumb2` -> `thumb_02_r`
- `mixamorig:RightHandThumb3` -> `thumb_03_r`

### Unmapped Mixamo end bones

- `mixamorig:HeadTop_End`
- `mixamorig:LeftHandIndex4`
- `mixamorig:LeftHandMiddle4`
- `mixamorig:LeftHandPinky4`
- `mixamorig:LeftHandRing4`
- `mixamorig:LeftHandThumb4`
- `mixamorig:LeftToe_End`
- `mixamorig:RightHandIndex4`
- `mixamorig:RightHandMiddle4`
- `mixamorig:RightHandPinky4`
- `mixamorig:RightHandRing4`
- `mixamorig:RightHandThumb4`
- `mixamorig:RightToe_End`

### Unmapped CoreC helper, twist, and intermediate bones

- `calf_twist_01_l`
- `calf_twist_01_r`
- `calf_twist_02_l`
- `calf_twist_02_r`
- `center_of_mass`
- `ik_foot_l`
- `ik_foot_r`
- `ik_foot_root`
- `ik_hand_gun`
- `ik_hand_l`
- `ik_hand_r`
- `ik_hand_root`
- `index_metacarpal_l`
- `index_metacarpal_r`
- `interaction`
- `lowerarm_twist_01_l`
- `lowerarm_twist_01_r`
- `lowerarm_twist_02_l`
- `lowerarm_twist_02_r`
- `middle_metacarpal_l`
- `middle_metacarpal_r`
- `neck_02`
- `pinky_metacarpal_l`
- `pinky_metacarpal_r`
- `ring_metacarpal_l`
- `ring_metacarpal_r`
- `spine_02`
- `spine_04`
- `thigh_twist_01_l`
- `thigh_twist_01_r`
- `thigh_twist_02_l`
- `thigh_twist_02_r`
- `upperarm_twist_01_l`
- `upperarm_twist_01_r`
- `upperarm_twist_02_l`
- `upperarm_twist_02_r`
