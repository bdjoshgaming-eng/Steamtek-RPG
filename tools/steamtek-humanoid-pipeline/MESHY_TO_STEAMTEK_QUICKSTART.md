# Meshy to Steamtek: Fast Humanoid Intake

This is the approved fast path for humanoid players, NPCs, and enemies.

## 1. Generate in Meshy

- Use a neutral A-pose or T-pose humanoid.
- Ask Meshy to rig the character.
- Import Meshy's animations with the model. Start with Idle and Walk; Run,
  Attack, Hurt, and Death can be included immediately.
- Keep the untouched Meshy download under:
  `assets/characters/humanoid/incoming/<character_id>/`

Meshy's animation clips are first-class source material. The Blender intake
does not discard them; it preserves every clip and normalizes recognized names:

| Meshy / source name contains | Steamtek action |
|---|---|
| Idle | STK_IDLE |
| Walk / Walking | STK_WALK |
| Run / Running | STK_RUN |
| Attack | STK_ATTACK |
| Melee | STK_ATTACK_MELEE |
| Pistol / Shoot | STK_ATTACK_PISTOL |
| Rifle | STK_ATTACK_RIFLE |
| Hurt / Hit | STK_HURT |
| Death / Die | STK_DEATH |

Unrecognized clips retain their original name instead of being deleted.

## 2. Pass through Blender

### Fast path

Run `C:\My Game\Steamtek-RPG\tools\Run_Meshy_Character_Intake.bat`, select the
downloaded character, and let the tool create the Blender source, QA report,
and approved Godot GLB.

For rigged or animated characters, download **FBX** from Meshy first. Standard
GLB is also supported. If a `.glb` begins with `MESHY.AI`, it is a protected
wrapper rather than an importable glTF file; download the model again from the
Meshy model page.

### Manual Blender path

1. Open Blender 4.5.
2. In the 3D View press `N`, then open the **Steamtek** tab.
3. Choose the Meshy GLB/FBX and click **Import Meshy GLB/FBX**.
4. Click **Audit Character**.
5. Click **Normalize Animation Names**.
6. Click **Create Equipment Sockets**.
7. Choose an export location and click **Export Godot GLB + Report**.

The report beside the GLB is the intake receipt. Do not approve a character
that reports no armature, no weighted mesh, or missing required rig data.

## 3. Clothing versus equipment sockets

### Skinned clothing

Jackets, shirts, pants, boots, and gloves must contain real skin weights for
the same skeleton. Merely assigning Godot's `skeleton` property does not rig a
mesh. In Blender, fit the clothing to the body, select the clothing first and
the fitted body last, then use **Bind Selected Clothing to Canonical Rig**.
Inspect shoulders, elbows, hips, and knees before export.

### Rigid socket equipment

Helmets, weapons, and backpacks do not need deformation weights. They attach
to `Socket_Head`, `Socket_Hand_R`, `Socket_Hand_L`, or `Socket_Back`.

## 4. Godot intake

- Keep processed character GLBs under `assets/characters/humanoid/base/`.
- Keep processed animations under `assets/characters/humanoid/animations/`.
- Create equipment resources under `resources/equipment/`.
- Use `scenes/characters/templates/SteamtekModularHumanoid3D.tscn` as the
  structure reference. Replace its placeholder Skeleton3D/BaseBody with the
  imported character's real skeleton and weighted body.
- The equipment controller rejects unweighted clothing instead of pretending
  it has been rigged.

## First acceptance test

The first approved character must pass all five checks:

1. Idle and Walk play from Meshy's imported clips.
2. Movement and facing rotate smoothly, not in eight visual jumps.
3. One helmet follows `Socket_Head`.
4. One jacket bends correctly with the shared skeleton.
5. Godot reports no missing animation, skeleton, or skin errors.
