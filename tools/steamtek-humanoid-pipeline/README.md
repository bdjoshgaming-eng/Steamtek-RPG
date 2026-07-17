# Steamtek Humanoid 3D Pipeline

This is the fast production route for Steamtek humanoid characters:

```text
Concept image
  -> Meshy character/model generation
  -> Meshy rigging and animation library
  -> Steamtek Blender Intake
  -> Godot modular equipment runtime
```

The pipeline does not replace the validated Steamtek hybrid 3D proof. It turns
that proof into a repeatable character and equipment workflow.

## What it does

- imports Meshy GLB/FBX files into Blender;
- preserves Meshy animation actions;
- audits the armature, skin weights, materials, textures, scale, and transforms;
- normalizes common animation names to `STK_IDLE`, `STK_WALK`, and related names;
- creates standard socket markers for rigid equipment;
- transfers body weights to fitted clothing as a production starting point;
- exports a Godot-ready GLB plus an intake report;
- supplies a Godot runtime for skinned clothing and rigid socket equipment.

## One-time installation

Run `Install_Steamtek_Humanoid_Pipeline.bat`. The installer uses the canonical
Steamtek project and Blender 4.5 paths by default. The installer:
Steamtek Godot project when prompted. The installer:

1. installs and enables the Blender add-on for Blender 4.5;
2. copies the Godot runtime into `res://addons/steamtek_humanoid_runtime`;
3. writes the shared standard and one-click intake tool into the project tools folder.

## One-click intake

After installation, run:

`C:\My Game\Steamtek-RPG\tools\Run_Meshy_Character_Intake.bat`

Choose a normal Meshy FBX, GLB, or glTF export. The tool creates an editable
Blender file, audits the character, and writes a Godot-ready GLB only when the
model passes the Steamtek character standard.

## Character intake

1. In Meshy, generate a humanoid in a neutral pose.
2. Rig it in Meshy and add the desired animations there. Start with idle and walk.
3. Download FBX (preferred for a rigged or animated character) or standard GLB.
   A valid binary GLB begins with `glTF`. A file beginning with `MESHY.AI` is a
   protected wrapper and must be downloaded again from Meshy.
4. Open Blender and choose **Steamtek** in the right sidebar.
5. Select the file under **Meshy Character / Animation File**.
6. Click **Import Meshy GLB/FBX**.
7. Click **Audit Character**.
8. Click **Normalize Animation Names**.
9. Click **Create Equipment Sockets**.
10. Click **Export Godot GLB + Report**.

## Clothing intake

Clothing must fit the canonical body in the same rest pose. A matching skeleton
name alone is not enough.

1. Import the canonical body and the clothing.
2. Select the clothing meshes first, then select the fitted body mesh last.
3. Set the canonical armature in the Steamtek panel.
4. Click **Bind Selected Clothing to Canonical Rig**.
5. Test shoulder, elbow, hip, and knee deformation before export.

The button transfers weights from the body by nearest surface and connects the
clothing to the canonical armature. It is a fast first pass; unusual coats,
skirts, or hard armor may still need a small weight correction.

## Production boundary

- Humanoid enemies use this same skeleton and animation library.
- Helmets, handheld weapons, backpacks, and small accessories use rigid sockets.
- Jackets, shirts, pants, boots, and gloves use skinning to the canonical rig.
- Non-humanoid enemies get separate rigs later; they do not block this pipeline.
