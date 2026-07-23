# STK_NPC_SCU_Mk1 Production Intake

Status: Mesh, material, scale, LOD, and Godot intake passed. Animation approval is blocked pending a proper shared-rig pose match and manual weight validation.

## Source

- Supplied source: `incoming/meshy_enemy_npc/STK_NPC_SCU_Mk1.glb`
- Source format: standard binary glTF/GLB
- Source geometry: 32,658 triangles, 31,151 vertices
- Source rig/animations: none
- Source appearance: one material with embedded base-color, emission, and metallic/roughness textures
- The source GLB was preserved unchanged.

## Production Outputs

- Godot GLB: `assets/characters/humanoid/base/STK_NPC_SCU_Mk1/v01/STK_NPC_SCU_Mk1.glb`
- Editable Blender source: `blender/character_pipeline/enemies/STK_NPC_SCU_Mk1.blend`
- Enemy wrapper: `scenes/characters/enemies/STK_NPC_SCU_Mk1.tscn`
- Visual QA scene: `scenes/characters/validation/STK_NPC_SCU_Mk1_Review.tscn`
- Machine-readable report: `docs/reviews/characters/STK_NPC_SCU_Mk1/STK_NPC_SCU_Mk1_Production_Report.json`
- Godot review capture: `docs/reviews/characters/STK_NPC_SCU_Mk1/STK_NPC_SCU_Mk1_GodotReview.png`

## Final Production Counts

- LOD0: 18,000 triangles
- LOD1: 10,000 triangles
- LOD2: 4,500 triangles
- Materials: 1, named `STK_MAT_SCU_BodyArmorEmissive`
- Textures: 3 embedded textures at 2048 x 2048
  - Base color
  - Emission
  - Metallic/roughness

## Scale, Orientation, and Rig

- Physical height contract: 1.8288 m / 6 ft
- Internal mesh height: approximately 1.70 m
- Godot visual scale: `1.075765, 1.075765, 1.075765`, matching the current C001 six-foot presentation contract
- Root scale: `1,1,1`
- Feet grounded at Y = 0 in Godot
- Root centered at ground contact
- Forward: -Z in Godot / -Y in Blender
- Intended rig target: established 24-bone C001 humanoid skeleton; the current transferred skin is rejected and not approved
- Experimental transferred weights contain no unweighted vertices and are limited to four influences per vertex, but their deformation quality is not production-approved
- The GLB contains `STK_IDLE`, `STK_WALK`, and `STK_RUN`, but the SCU wrapper deliberately disables both animation playback and the rejected skin binding.
- Included sockets: head, both hands, and back

## Repairs and Optimization

- Grounded and centered the source without redesigning it.
- Preserved the supplied silhouette, UV map, material assignment, emissive regions, helmet, respirator, backpack/tanks, hoses, armor, gauge, gloves, and boots.
- Removed no intentional equipment or appearance regions.
- Removed no loose vertices because none were present.
- Recalculated face-normal orientation and passed Blender mesh validation.
- Preserved the source's baked UV/normal boundary splits instead of destructively welding them; automatic welding would risk texture and hard-edge damage.
- Reduced each LOD independently from the cleaned source so the lower LODs do not compound reduction damage.
- Reused the established Steamtek humanoid skeleton as the intended target rather than creating a new custom enemy rig.
- The automatic weight-transfer experiment was rejected after F6 exposed severe arm deformation. The source mesh uses an arms-down neutral pose while the shared C001 skeleton rests with nearly horizontal arms. The wrapper now disconnects the rejected skin and renders the untouched SCU base mesh instead of displaying invalid deformation.
- Preserved cyan and magenta emission and raised the material's roughness floor to maintain a matte/low-satin response.
- Reduced the three embedded textures from 4096 x 4096 to the Steamtek 2048 x 2048 character standard.

## Godot Validation

Normal Godot 4.7 Compatibility runtime validation reported:

- LOD triangles: `[18000, 10000, 4500]`
- Imported animation clips: `STK_IDLE`, `STK_RUN`, `STK_WALK`
- SCU runtime animation and transferred skin: disabled; F6 renders the untouched base mesh pending proper pose matching and manual weight validation
- Root scale: `1,1,1`
- Visual scale: `1.075765,1.075765,1.075765`
- Review scene initialized successfully with no SCU import, skeleton, skin, animation, or script errors.

The only runtime warning was the pre-existing C001 invalid-UID text-path fallback. It is unrelated to the SCU.

The visible review window supports:

- Space: animate the C001 reference only
- Left/Right: rotate the SCU
- 1/2/3: force LOD0/LOD1/LOD2
- 0: restore automatic distance-based LOD selection

The next rigging pass must first repose the SCU into the shared skeleton's rest pose, then perform and manually validate weights around shoulders, elbows, wrists, hips, knees, ankles, helmet, backpack, tanks, and major hoses before SCU animation is re-enabled.
