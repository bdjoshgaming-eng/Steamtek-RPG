# Steamtek Character Pipeline Handoff

**Date:** 2026-07-14  
**Repository:** `C:\My Game\Steamtek-RPG`  
**Current pipeline:** v1.6.0  
**Current test character:** `Steamtek_C002` detailed prototype v1.2  
**Golden reference:** `Steamtek_C001` — immutable

## Current state

The reusable Blender-to-Godot character pipeline is installed in the canonical Steamtek repository. It produces fixed-canvas, genuinely rendered eight-direction character animation frames and packages them into a reusable Godot `SpriteFrames` resource.

`Steamtek_C001` was not rebuilt or edited. Its verification manifest still passes and it remains the visual, scale, and ground-contact benchmark.

`Steamtek_C002` is currently integrated into `scenes/main.tscn` as the existing `Trainer` character, displayed in game as **Foreman Brassguard**. It has a four-point patrol, eight-direction idle/walk animation, a 28x18 collision footprint, interaction support, and a nameplate fixed above its head.

## Locked character contract

- Source render: 1254x1254 PNG RGBA
- Background: transparent
- Canvas: fixed across every direction and frame; never crop individual frames
- Projection: true 2:1 dimetric/isometric
- Camera: locked orthographic `Camera_Iso`
- Ground contact: world origin, centered between the boots
- Model forward axis: Blender `-Y`
- Godot production frame: 256x256
- Godot visual scale: `(0.73, 0.73)`
- Godot visual offset: `(0, -110)`
- Collision footprint: `28x18`
- Godot visual node: `AnimatedSprite2D` named `Visual`
- Animation naming: `{state}_{direction}`, for example `walk_south_west`
- Mirroring: prohibited for production assets
- Gameplay direction remapping: prohibited

## Authoritative v1.6 direction contract

Playable-map QA showed that Godot's screen-direction order requires a clockwise Blender turntable. Pipeline v1.6 supersedes the earlier positive-angle table.

| Direction | `ROOT_Direction` Z rotation |
|---|---:|
| south | 0° |
| south_west | -45° |
| west | -90° |
| north_west | -135° |
| north | 180° |
| north_east | 135° |
| east | 90° |
| south_east | 45° |

`ROOT_CharacterFacing` is locked at `-45°`. Artists must not change the facing adapter or turntable order.

The verified visual result is:

- South shows the character's front.
- North shows the regulator backpack.
- East and west face their matching screen directions.
- Diagonals preserve the corresponding front/back and left/right quarters.

All eight directions are separately rendered. No rows are mirrored, substituted, or fixed in Godot code.

## Installed pipeline files

### Blender master and rig

- `blender/character_pipeline/master/Steamtek_Character_Master.blend`
- `blender/character_pipeline/master/Steamtek_HumanRig_v1.blend`
- `blender/character_pipeline/scripts/Steamtek_Render_8Directions.py`
- `blender/character_pipeline/scripts/Steamtek_Validate_CharacterScene.py`
- `blender/character_pipeline/scripts/Steamtek_Correct_Turntable_v16.py`
- `blender/character_pipeline/scripts/Steamtek_Build_Character_Master.py`
- `blender/character_pipeline/scripts/Steamtek_Build_HumanRig_v1.py`
- `blender/character_pipeline/scripts/Steamtek_Build_CalibrationDummy.py`

`Steamtek_Character_Master_v16.blend` is also present as the v1.6 promotion source. The canonical file used for new work is `Steamtek_Character_Master.blend`.

### Pipeline tools and metadata

- `tools/character-pipeline/metadata/Steamtek_Character_Manifest.json`
- `tools/character-pipeline/metadata/Steamtek_HumanRig_v1.json`
- `tools/character-pipeline/metadata/STK_CalibrationDummy_v1.json`
- `tools/character-pipeline/metadata/Steamtek_C001_GoldenReference.json`
- `tools/character-pipeline/Steamtek_Build_ProductionFrames.py`
- `tools/character-pipeline/Steamtek_Build_GodotFramesFromRenders.py`
- `tools/character-pipeline/Steamtek_Validate_RenderOutput.py`
- `tools/character-pipeline/Steamtek_Verify_GoldenReference.py`
- `tools/character-pipeline/docs/Steamtek_Character_Pipeline.md`

### C002 character package

- Blender source: `assets/characters/npc/Steamtek_C002/blender/Steamtek_C002_DetailedPrototype_v1_2.blend`
- Character specification: `assets/characters/npc/Steamtek_C002/metadata/Steamtek_C002_CharacterSpec.json`
- Production idle frames: `assets/characters/npc/Steamtek_C002/production/idle/`
- Production walk frames: `assets/characters/npc/Steamtek_C002/production/walk/`
- Godot frames: `assets/characters/npc/Steamtek_C002/godot/Steamtek_C002_Frames.tres`
- Godot visual: `assets/characters/npc/Steamtek_C002/godot/Steamtek_C002_Visual.tscn`
- Reusable NPC scene: `scenes/characters/npc/Steamtek_C002_NPC.tscn`
- NPC controller: `scenes/characters/npc/Steamtek_C002_NPC.gd`

## Nameplate fix

C002 owns its `NameLabel` inside the reusable NPC scene, while the older trainers keep sibling labels in the main world scene. The legacy update loop originally wrote a world-space coordinate into C002's local child label, which pushed the text through or below the character.

`scenes/main.gd` now distinguishes the two cases:

- Child labels use local position `(-75, -235)`.
- Legacy sibling labels retain their existing world-space positioning.
- C002's `NameLabel` uses `z_index = 100`.
- Its speech label is above the nameplate at `z_index = 101`.

This compatibility branch should remain until all legacy trainers are converted to reusable character scenes.

## Validation completed

- Blender production scene validation passed for C002 v1.2.
- Idle: 8 directions x 8 frames, 1254x1254 raw render QA passed.
- Walk: 8 directions x 8 frames, 1254x1254 raw render QA passed.
- Idle and walk 256x256 production-frame QA passed.
- Godot `SpriteFrames` rebuilt with 16 animations and 8 frames per animation.
- Godot movement-vector selection passed for north, east, south, and west.
- Nameplate position and draw-layer verification passed.
- Collision footprint verification passed at 28x18.
- C001 golden-reference verification passed with no discovered reference changes.

## Known unrelated warning

Godot reports an invalid UID in:

`scenes/props/surface/P001_Street_Lamp.tscn`

It falls back successfully to:

`res://assets/surface/props/street_lamp/production/P001_StreetLamp_v001.png`

This warning did not block C002 importing or validation. It should be repaired separately by resaving/relinking the street-lamp texture resource in Godot.

## Repository caution

The worktree already contains multiple modified and untracked files unrelated to the character-pipeline pass, including changes in `project.godot`, `scenes/player.gd`, the theme, modular validation content, and other assets. Do not reset, delete, or overwrite these changes. Review and commit the character-pipeline work selectively.

No Git commit was created during this handoff.

## Recommended next step

1. Complete one final visual patrol check in the fresh game instance, paying special attention to all four cardinals and the four diagonals.
2. If that passes, treat v1.6 as the locked direction contract and create a `Steamtek_Character_Pipeline_v1.6.zip` archive under `docs/archives/`.
3. Convert the next humanoid NPC by duplicating `Steamtek_Character_Master.blend`, replacing only mesh/materials/equipment, and reusing the approved rig/actions.
4. Convert the remaining legacy trainer nameplates into the reusable NPC scene structure, then remove the temporary legacy-label compatibility branch only after all trainers use local child labels.

## Do not regress

- Do not modify or rebuild C001.
- Do not return to the v1.5 `135°` facing adapter.
- Do not restore the old positive-angle turntable order.
- Do not swap Godot animation names to repair Blender orientation.
- Do not mirror permanent directional frames.
- Do not crop frames independently.
- Do not move the camera, roots, lights, framing, or ground-contact origin per character.
