# STK_HERO_BaseBody_01 — Meshy Rigging Input Report

## Status

**PASSED — ready for Meshy auto-rigging.**

The approved production source was not modified or overwritten.

## Deliverable

- Export: `C:\My Game\Steamtek-RPG\output\meshy_rig_input\STK_HERO_BaseBody_01_MeshyRigInput.glb`
- Material: `STK_MAT_HERO_MeshyRigInput`
- Base-color atlas: `STK_HERO_BaseBody_01_MeshyRigInput_BaseColor.png`
- Source: `C:\My Game\Steamtek-RPG\assets\characters\humanoid\base\STK_HERO_BaseBody_01\v01\STK_HERO_BaseBody_01.glb`

## Final Counts

- Mesh objects: **1**
- Materials: **1**
- UV maps: **1**
- Triangles: **31,138**
- Base-color texture: **4096 × 4096**
- Armatures: **0**
- Animation actions: **0**

## Diagnosis

The approved source already contained one mesh object, but it used two material
primitives and reused UV space across the body and hair materials. This was the
primary Meshy compatibility risk.

The source also contained mixed triangle winding that was hidden by its
double-sided materials. When a correct single-sided material was used, those
faces appeared as jagged black or missing patches during rotation and rigging.

No duplicate faces, separate hidden shell, armature, animation, overfull edges,
wire edges, or degenerate geometry faces were found. The many raw GLB boundary
edges are attribute/UV seam splits rather than physical holes: a read-only
positional seam test resolves the character to one closed manifold component.

## Repairs Performed

- Preserved the approved face, hairstyle, proportions, mild A-pose, fingers,
  toes, and triangle count.
- Preserved the character as one unrigged mesh object.
- Applied mesh transforms and verified identity transforms after reimport.
- Reoriented **20,526** inward-facing triangles using bidirectional
  nearest-surface testing.
- Reimport validation found **0 inward-facing faces** and one numerically
  ambiguous face.
- Created one new non-overlapping UV atlas.
- Repaired **15** collapsed source UV triangles before transferring appearance.
- Transferred the approved skin, shirt, shorts, and matte-black hair appearance
  into one 4096 × 4096 base-color atlas.
- Replaced the source materials with one opaque PBR material.
- Removed alpha blending, alpha masking, emissive output, metallic/roughness
  texture dependencies, custom material graphs, and normal-map tangent risk.
- Verified no duplicate faces and a closed positional-weld topology:
  **0 boundary edges, 0 overfull edges, 0 wire edges, 0 degenerate faces**.

## Validation

- Reimported successfully outside Godot through Blender's GLB importer.
- Exactly one mesh, one material, and one UV map after reimport.
- Material is opaque and backface culling is enabled.
- Normals face outward.
- Eight-angle single-sided turnaround review completed across 360 degrees.
- No black patches, missing polygons, or incorrect skin, shirt, shorts, or hair
  regions were visible.

## Integrity

- Production source SHA-256:
  `4bd4ce97fc8d0c4929e843383345cd042c3bd48b1087f74c80abae1185636408`
- Rigging-copy SHA-256:
  `355a05f85f5ca379f864923b7c82b3c83b67881bcaf7dac2e35ff124475eec10`

