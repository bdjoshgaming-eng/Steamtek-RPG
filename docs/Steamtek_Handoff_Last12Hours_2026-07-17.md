# Steamtek — Comprehensive Handoff (Last 12 Hours)

**Date:** 2026-07-17  
**Project:** Steamtek  
**Canonical project:** `C:\My Game\Steamtek-RPG`  
**Primary engine:** Godot 4.7  
**Current priority:** get a reliable 3D character intake path working, then return to the modular environment snap system.

This document is the current source of truth for the work discussed during the last twelve hours. It intentionally records decisions, verified facts, experiments, unresolved issues, and the exact next action. It is written so another PC or another collaborator can resume without relying on chat history.

## 1. Project identity and gameplay target

Steamtek is a neo-industrial / neo-punk isometric RPG. The surface is deliberately small: the player begins in an apartment, exits into a rainy alley, follows a street to the Brass Lantern bar, receives the first quest, and descends through a manhole/elevator route into the silo. Almost all long-term gameplay takes place underground.

The intended loop is:

1. Return to the surface safe zone.
2. Talk to trainers, merchants, and quest givers.
3. Choose equipment, profession skills, and a contract.
4. Descend into the silo.
5. Explore procedural/assembled industrial districts.
6. Fight, loot Steamtek artifacts, and manage resources.
7. Return to the Brass Lantern or apartment.
8. Upgrade equipment and unlock deeper access.
9. Repeat at greater depth while uncovering the silo mystery.

The surface should establish tone and provide a persistent hub; it should not become a second open-world project.

## 2. Locked art direction

Do not drift back to Victorian steampunk. The target is **modern neo-industrial technology powered by steam and pressure**:

- concrete and dark steel architecture;
- gunmetal, copper, limited brass, rust, and weathered materials;
- functional pipes, pressure systems, vents, gauges, machinery, and utility infrastructure;
- rain, steam, fog, wet pavement, puddles, and reflective surfaces;
- cyan, magenta, amber, and occasional acid-green light used as functional signals;
- gritty, worn, lived-in surfaces;
- cyberpunk-era equipment with steam as the dominant energy language;
- no top hats, ornate Victorian trim, decorative gear clutter, or 1800s-London architecture.

Every character should have one recognizable Steamtek technology signature (pressure gauntlet, artifact lantern, respirator, mechanical backpack, belt reactor, exoskeleton brace, or pneumatic tool). Profession identity should be readable from that equipment.

Canonical exterior references to keep using together:

- `Steamtek_Surface_ColorPalette_Aesthetic_Reference.png` — palette, wet materials, night lighting, neon balance, water treatment, and overall graphical feel.
- `ApartmentExterior_AssemblyMockup.png` — composition and apartment massing.

The desired world style is a controlled 2.5D hybrid: 2D/painted or rendered environment art presented through a locked orthographic isometric camera, with 3D characters and effects layered on top. The project uses a **2:1 dimetric** visual convention for its isometric ground projection.

## 3. Strategic decision made today

Direct AI sprite-sheet generation caused inconsistent perspective, frames, pivots, scale, and direction. The long-term solution is a controlled 3D-to-2D/2.5D pipeline:

```text
Meshy or commissioned model
        ↓
Godot DCC bridge for fast intake
        ↓
Godot validation (skeleton, materials, scale, animation)
        ↓
Blender master pipeline when cleanup, rigging, equipment, or locked renders are needed
        ↓
Godot production scene
```

The DCC bridge is the fast intake route. Blender remains the authoritative cleanup/rendering route when a model needs geometry correction, shared skeleton work, modular clothing, consistent camera renders, or production-quality animation. Do not discard the working intake path until the bridge has been validated with the actual model.

## 4. Meshy/Godot bridge status

The Meshy Godot plug-in was installed under:

`C:\My Game\Steamtek-RPG\addons`

The bridge accepted the model package and produced the following extracted files:

```text
res://imported_models/Neo-Steampunk Protagonist Rigged/
└── Meshy_AI_Neo_Steampunk_Protago_biped/
    ├── Meshy_AI_Neo_Steampunk_Protago_biped_Animation_Walking_withSkin.glb
    └── Meshy_AI_Neo_Steampunk_Protago_biped_Character_output.glb
```

The bridge log also reported:

```text
Starting ZIP file processing...
ZIP file extraction complete...
WARNING: No FBX model found in ZIP. Skipping model import.
Successfully deleted original ZIP file...
```

Interpretation: the bridge extracted the GLBs, but its specific importer expected an FBX and skipped the automatic FBX import step. The original ZIP was deleted after extraction. The GLBs are the important outputs and must be preserved/copied into a versioned intake folder before trying anything destructive.

Recommended canonical intake location:

```text
C:\My Game\Steamtek-RPG\assets\characters\intake\meshy\VesperKane\source\
```

Recommended layout:

```text
assets
└── characters
    └── intake
        └── meshy
            └── VesperKane
                ├── source
                │   ├── VesperKane_Walking_withSkin.glb
                │   └── VesperKane_Character_output.glb
                ├── godot_test
                ├── blender_cleanup
                ├── production
                └── README.md
```

Do not overwrite the source files. Keep a copy of every received GLB, even if one turns out not to be usable.

## 5. Immediate character acceptance test

The next work item is not a full equipment system. It is a small, visible proof that one imported character works.

Use this order:

1. Preserve both extracted GLBs in the canonical intake folder.
2. Import/open the walking GLB in Godot.
3. Confirm a `Skeleton3D` exists and the animation library is visible.
4. Confirm materials and textures load without missing-resource warnings.
5. Confirm the model is facing the expected forward direction.
6. Confirm the model is at a sensible world scale beside the existing player/NPC reference.
7. Create a simple `CharacterBody3D` test scene containing the imported character, collision, camera, and one light.
8. Play the supplied walking animation without adding inventory, combat, clothing, or procedural generation.
9. Record what works and what fails before deciding whether Blender cleanup is required.

Acceptance criteria:

- skeleton imports;
- materials are present;
- no green/background artifact;
- model is not microscopic or huge;
- walk animation plays;
- character can be placed beside the existing world for scale comparison;
- one reusable Godot scene can be saved.

If the GLB fails this test, use Blender only to repair the failing part. Do not restart the entire character pipeline.

## 6. Character production standard

The agreed player target is a high-fidelity 3D character rendered or displayed through the locked 2.5D presentation.

```text
Triangles LOD0: 15,000–18,000
Triangles LOD1: 8,000–10,000
Triangles LOD2: 3,000–5,000
Skeleton: one shared humanoid skeleton
Rig: humanoid
Materials: 3–5 maximum
Textures: 2048×2048 for the player
Maps: Base Color, Normal, Roughness, Metallic as needed
```

Keep the character as separate meshes so equipment can be swapped:

- body;
- hair;
- coat/jacket;
- gloves;
- boots;
- belt;
- backpack;
- weapons;
- accessories.

The equipment system should eventually show a looted jacket, pants, boots, helmet, gloves, or weapon in-game. The best first implementation is shared skeleton + mesh visibility/swap per equipment slot. More advanced bone-attached clothing is a later improvement, not a prerequisite for the first playable character.

## 7. Blender pipeline status

Blender is installed on this home PC at:

`C:\Program Files\Blender Foundation\Blender 4.5\`

The project has an existing controlled character pipeline and should reuse it rather than inventing a new camera or scale. Important known assets/scripts include:

- `Steamtek_Character_Master.blend`;
- `Steamtek_C001` character pipeline files;
- `build_godot_walk_scene.py`;
- `Install_C001_Into_Godot.bat`;
- `Root_CTRL` and `boot_contact` conventions;
- `Camera_Iso` / locked orthographic camera conventions;
- `STK_WALK` and the eight-direction render/export workflow.

There are two historical scale contracts in older records. Do not merge them blindly:

- older legacy contract: approximately `0.73` and root near `(0, -110)`;
- newer validated C001 contract: `0.09` and `Vector2(0.000, -422.000)` for the Godot 2D render scene.

Use the existing C001 master/scene as the authority for the current character work. Recalibrate only after measuring the actual imported model and comparing it to the approved in-game reference.

The long-term Blender flow should provide:

1. locked orthographic isometric camera;
2. locked lighting and transparent-background render settings;
3. shared humanoid rig;
4. predictable root/boot contact;
5. clean animation clips;
6. eight directions or a real 3D character that can be rotated smoothly;
7. batch export to Godot-ready GLB/PNG/scene resources.

## 8. Modular equipment plan

The requested gameplay behavior is: loot a jacket, equip it, and see it change on the character.

Recommended scene structure:

```text
Player (CharacterBody3D)
├── Armature
│   └── Skeleton3D
├── BaseBody
├── EquipmentRoot
│   ├── JacketSlot
│   ├── PantsSlot
│   ├── BootsSlot
│   ├── GlovesSlot
│   ├── HelmetSlot
│   ├── BackpackSlot
│   ├── WeaponSlot
│   └── AccessorySlot
├── AnimationPlayer / AnimationTree
└── CollisionShape3D
```

All clothing generated in Meshy or commissioned externally must be checked for:

- compatible humanoid skeleton/bone names;
- correct scale and rest pose;
- clean weights;
- no hidden body intersections that matter in gameplay;
- material count within budget;
- matching Steamtek style.

For the first proof, use simple scene swapping: remove the old slot scene, instantiate the new jacket scene, and keep the same skeleton. Do not build a full inventory UI until one jacket can be equipped successfully.

## 9. Environment/modular snap status

The environment work established a large neo-industrial surface kit and a newer `modular_v1` validation library. Many older assets were manually aligned and do not share a reliable snap contract. This is why walls, windows, floors, roofs, foundations, seams, and fire escapes repeatedly showed gaps or offsets in Godot.

The modular project contains validation scenes and families for:

- plain walls;
- left/right end caps;
- inside and outside corners;
- seam columns;
- side/plain/window/door/feature wall families;
- parapets and roof surfaces;
- roof corners and end caps;
- foundations and sidewalk pieces;
- fire escapes;
- apartment shell assemblies.

The correct modular priority remains:

1. define the canonical ground contact and origin;
2. define the exact snap points/markers;
3. validate one straight wall run;
4. validate one inside corner;
5. validate one outside corner;
6. validate window/door/feature variants against the same run;
7. validate floor/foundation/roof attachment;
8. only then build large apartment assemblies.

Rules:

- geometry is authoritative; AI enhancement may repaint materials but may not change silhouette or anchor positions;
- all modules must use the same camera/projection and source scale;
- no permanent mirroring to hide a wrong directional asset;
- no hand-tuning each placed instance as the normal workflow;
- every family needs a visible validation scene with snap markers;
- keep legacy panels separate from the new modular library until the new contract is proven.

The current modular work should stay snap-first. Do not let character work erase this priority; the two tracks can proceed independently once the character intake proof is stable.

## 10. Surface, rain, and current world systems

The surface prototype already contains:

- apartment/surface modules;
- props such as lamp, crate, barrel, valve, pipe, steam vent, and utility box;
- NPCs/trainers/enemies;
- a Y-sort layer for 2D world ordering;
- night modulation/lighting;
- rain layers and rain splash/mist effects;
- wet industrial ground and reflective neon treatment.

Rain was built as layered effects (`FX001_RainSystem`, `FX002_RainSplash`, `FX003_RainMist`) with far/near particle systems. The working direction is thin, sharp, impactful rain rather than huge opaque streaks. The mist should use soft alpha, not visible square particles. Keep the attached rain video as a mood reference, not a literal asset specification.

## 11. Steamtek Studio/database

Steamtek Studio is an internal tool/database used to track assets, kits, status, source paths, production paths, Godot scene paths, and QC fields. The project has had several versions and recovery builds. The database may live in `.steamtek-studio` or inside the tools folder depending on the checkout.

Use the tool for tracking and asset intake, but do not make the tool itself the blocker. A usable project with clear folders is more important than a polished editor.

Expected asset statuses include:

```text
Planned → Concept → Source → QC → Production → Approved → In Game
```

## 12. Git and multi-PC rules

Canonical repo:

`C:\My Game\Steamtek-RPG`

Before changing PCs:

```powershell
Set-Location 'C:\My Game\Steamtek-RPG'
git status
git add -A
git commit -m "Checkpoint: Steamtek character and modular pipeline"
git push origin main
```

On the other PC:

```powershell
Set-Location 'C:\My Game\Steamtek-RPG'
git pull origin main
```

Do not blindly commit generated Godot `.import` files, caches, or temporary exports if the project policy excludes them. However, source GLBs, production textures, Blender files, scripts, docs, and required Godot scenes must be tracked. The user specifically prefers not to lose tools or database files to an over-aggressive ignore rule, so check `.gitignore` before assuming a missing tool is backed up.

Recommended checkpoint habit:

```powershell
git status
git add -A
git commit -m "Checkpoint: <short description>"
git push
```

## 13. Known issues and what not to repeat

- The Meshy bridge log says “No FBX model found” even though two GLBs were extracted. Treat this as an importer limitation, not proof that the model is unusable.
- Do not delete the extracted GLBs while troubleshooting.
- Do not jump to a full Blender rewrite before the smallest Godot GLB test is complete.
- Do not use the older 2D sprite scale numbers for the new 3D character without measurement.
- Do not build five clothing sets before one jacket swap is proven.
- Do not manually repair every modular wall instance; fix the snap contract or source origins.
- Do not return to prompt-generated eight-direction sheets as the final character solution.
- Do not expand the surface city. The surface is a focused hub.
- Do not let the tool/database project replace actual playable content.

## 14. Exact work order from here

### Task A — Finish the Meshy bridge proof

1. Copy both extracted GLBs into `assets\characters\intake\meshy\VesperKane\source`.
2. Rename them clearly without spaces or unstable generated names.
3. Open the walking GLB in Godot.
4. Confirm skeleton, materials, scale, orientation, and animation.
5. Save a minimal `VesperKane_MeshyBridgeTest.tscn`.
6. Add a collision shape and a basic camera/light only if needed for the test.
7. Record the result in the asset README and Steamtek Studio.

### Task B — Repair only what the test proves is broken

If the bridge output is acceptable, keep it as the fast path. If not, use Blender to correct the exact failing item:

- missing materials;
- incorrect scale/origin;
- wrong animation import;
- skeleton incompatibility;
- equipment/socket setup;
- geometry cleanup.

Export a production GLB and re-run the same Godot test.

### Task C — Prove one equipment swap

Use one jacket or coat slot. Keep the implementation simple. The deliverable is a visible equip/unequip result on the same skeleton.

### Task D — Resume snap-system validation

Return to the modular validation scenes and finish one complete, gap-free path:

```text
foundation → straight wall → corner → window/door variant → roof/fascia
```

Only after that path is reliable should the full apartment shell be considered production-ready.

### Task E — Build the demo slice

The demo slice is:

```text
apartment → alley → rainy street → Brass Lantern → descent entrance
```

Use approved modules and the validated character. Avoid adding broad systems until this walkable slice is visually coherent and playable.

## 15. Definition of done for the current milestone

This milestone is complete when all of the following are true:

- the two Meshy GLBs are preserved in the canonical repo;
- one imports into Godot with skeleton and materials;
- one walk animation plays;
- one reusable character scene exists;
- one equipment slot can visibly swap an item;
- the modular validation path has no visible gaps at its snap joins;
- the apartment shell can be placed in-game without per-instance rescue offsets;
- a Git checkpoint exists and can be pulled on another PC;
- this handoff and the existing `7-17 handoff.md` / `7-17 convo.md` are present in `docs`.

## 16. One-line resume point

**Recover the two Meshy bridge GLBs, validate the walking GLB in a minimal Godot scene, repair only the proven failures through the existing Blender master, prove one jacket swap, then return to the snap-first modular validation path.**

