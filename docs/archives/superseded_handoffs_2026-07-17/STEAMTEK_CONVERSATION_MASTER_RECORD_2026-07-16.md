# Steamtek Conversation Master Record

Date compiled: July 16, 2026  
Canonical project: `C:\My Game\Steamtek-RPG`

## Purpose and scope

This document is a comprehensive chronological reconstruction of the Steamtek collaboration available in the current conversation context. It preserves the decisions, corrections, user preferences, technical standards, asset milestones, and current state needed to continue the project on another PC or in another task.

It is not a byte-for-byte platform export. Attached screenshots, videos, generated images, and very repetitive troubleshooting turns are summarized and referenced by their outcome. Earlier source conversation material and the current Codex work are combined into one readable project record.

## 1. Original game concept

The project began as a request for a steampunk-themed isometric 2D alleyway map for a Godot RPG. The initial generated map looked attractive as concept art, but it was not production-ready because the environment was flattened into one image. It lacked modular tiles, transparent sprites, separate foreground/background layers, collision data, navigation, and clean Godot alignment.

The discussion established that the opening should be a deliberately small vertical slice:

- the player begins in an apartment;
- leaves through an elevator/door into a rainy alley;
- follows a straight street;
- reaches a bar;
- receives a quest;
- enters a manhole or maintenance access;
- descends into the silo, where nearly the entire game occurs.

The surface was never intended to become a large open city. It serves as tutorial, refuge, social hub, and atmospheric contrast to the silo.

## 2. Steamtek's identity

The working title became **Steamtek**.

The user rejected conventional Victorian steampunk. The chosen identity became modern neo-industrial/neo-punk: a cyberpunk-era society in which steam pressure, pneumatics, and mechanical systems replaced conventional electric technology.

The visual language includes:

- concrete;
- gunmetal and black steel;
- copper pressure lines;
- rubber, glass, worn wood, and wet pavement;
- rain, fog, steam, puddles, and industrial haze;
- warm amber practical lights;
- cyan and magenta atmosphere produced by runtime lighting;
- functional machinery with understandable purpose.

The project explicitly avoids:

- Victorian London architecture as the default;
- top hats and goggles as generic world fashion;
- decorative gears attached without function;
- horse carriages and 1800s city imagery;
- cartoon steampunk;
- fantasy ornament masquerading as engineering.

Vesper Kane's top hat is a deliberate character silhouette and is not permission for general Victorian drift.

## 3. World and lore direction

The silo is an ancient industrial megastructure with neo-punk layers. Humanity repairs and interfaces with old systems but does not truly understand their origin.

Steam may not be the original power source. It may only be the key or interface that lets modern society activate far older machinery.

The canonical term became **Steamtek Artifacts**, replacing the earlier phrase Steamwork Artifacts.

The world follows a vertical archaeological logic:

- surface society is modern, crowded, wet, improvised, and human;
- upper silo levels contain maintenance infrastructure and survivor modifications;
- middle levels reveal expansion-era factories, transit, foundries, and pressure systems;
- lower levels become older, cleaner, stranger, and more advanced;
- the deepest technology may be self-maintaining and almost impossible.

The core player promise is simple: **go deeper**.

## 4. Gameplay loop

The persistent gameplay loop was defined as:

1. Prepare in the surface hub.
2. Speak with NPCs, accept contracts, train, craft, repair, and equip.
3. Descend into the silo.
4. Explore modular or procedural underground districts.
5. Fight enemies and solve environmental hazards.
6. Recover resources and Steamtek Artifacts.
7. Decide whether to continue deeper or extract.
8. Return to the Brass Lantern and apartment district.
9. Upgrade equipment, professions, NPC relationships, and access.
10. Descend again.

The surface does not grow geographically. It becomes richer through NPC changes, recovered objects, dialogue, and progression.

## 5. Early asset-pack search and the decision to build custom assets

Several marketplace packs were considered. Many recommendations turned out to be top-down, pixel-art, fantasy, or pre-rendered 3D rather than true isometric assets. The user repeatedly clarified that the game required an isometric presentation and did not want a conventional top-down pack.

The project considered 128x64 and 256x128 diamond standards. It eventually standardized the ground footprint as a 2:1 isometric diamond represented by a 256x128 tile canvas where applicable.

The team learned that AI-generated images that looked like tilesets were usually concept sheets rather than usable assets. Common problems included:

- checkerboards baked into RGB pixels rather than real transparency;
- inconsistent object scale;
- shadows and steam baked into sprites;
- variable camera angles;
- thick platform sides on what should be flat ground tiles;
- misaligned pivots;
- source sheets that could not be sliced cleanly.

This led to a custom Steamtek asset pipeline and the creation of Steamtek Studio and its Asset Cutter.

## 6. Steamtek Studio and Asset Cutter

Steamtek Studio began as a small Python asset database and cutter. It evolved into a project-specific internal tool for:

- tracking asset IDs, names, kits, status, and categories;
- storing source, production, and Godot scene paths;
- selecting paths with folder/file browsers;
- extracting sprites from source sheets;
- generating source and production PNGs;
- removing checkerboard backgrounds;
- retaining settings across application restarts;
- tracking missing or deleted assets;
- supporting multi-PC project work.

The authoritative tool location became:

`C:\My Game\Steamtek-RPG\tools\steamtek-studio`

Runtime data may exist in:

`C:\My Game\Steamtek-RPG\.steamtek-studio`

The user reported several UI issues that were corrected during development:

- dark-theme font contrast was too weak;
- combobox/dropdown text became invisible;
- mouse-over text was unreadable;
- path fields needed folder icons;
- asset edits initially failed to persist;
- the embedded cutter initially failed to produce both source and production files;
- checkerboard removal needed multiple revisions;
- deleted filesystem assets remained in the SQLite database until cleanup behavior was added.

The user emphasized that the tool should remain practical rather than turning into a months-long custom editor project.

## 7. Surface Kit 001

The first surface kit established reusable props:

- P001 Street Lamp;
- P002 Industrial Crate;
- P003 Industrial Barrel;
- P004 Steam Vent;
- P005 Straight Pipe;
- P006 Pipe Valve;
- P007 Pipe Corner + Valve;
- P008 Utility Box.

The street lamp became the first reusable Godot prop scene and taught the production pattern:

```text
PropRoot (StaticBody2D)
|- Visual (Sprite2D)
|- BaseCollision
|- PointLight2D (optional)
|- GPUParticles2D (optional)
`- AudioStreamPlayer2D (optional)
```

Important lessons included:

- raw PNG assets belong under `assets`;
- reusable `.tscn` objects belong under `scenes`;
- the root origin should represent the ground-contact point;
- visual scale belongs on the visual child, not the scene root;
- collisions should represent the physical footprint, not the whole image;
- player collision belongs around the feet/lower body;
- a plain Sprite2D does not provide collision;
- reusable scenes must be instanced, not replaced with loose PNGs.

The user found that the apparent lamp collision problem was actually an oversized player collision shape. Correcting the player's collision resolved the issue.

## 8. Collision and Y-sorting education

The user requested repeated visual collision guides because Godot was new to them.

The following rules were established:

- use simple shapes wherever possible;
- use CollisionPolygon2D only for a genuine isometric footprint;
- polygon points must be ordered around the perimeter without crossing;
- convex-decomposition errors usually indicate crossed or invalid polygon order;
- do not collide with the full visible height of an isometric object;
- collide with the ground footprint or true blocking plane;
- ignore baked visual shadows when fitting collision;
- for walls and doors, use split blocking rather than a single token doorway rectangle;
- static wall sections block the player even when they are not interactable;
- interaction areas are separate from physical collision.

The user explicitly requested production-quality split blocking for future assets to avoid rework.

Collision layers were organized around:

```text
Layer 1: World
Layer 2: Player
Layer 3: Enemies
Layer 4: Interactables
Layer 5: Interaction Areas
```

Trainers remain NPCs because teaching is behavior, not identity. Doors, valves, elevators, consoles, and quest boards belong under interactables.

## 9. Building modules

The early apartment building family included:

- B001 Wall Module A;
- B002 Apartment Door;
- B003 Window Module;
- B004 Fire Escape;
- B005 Plain Straight Wall;
- B006 Plain Full Wall;
- roof, facade, cap, and corner experiments.

The user repeatedly caught inconsistent source scale. Some modules were taller or larger even when all Godot visual children used the same numeric scale. This proved that identical Godot scale values do not fix inconsistent source canvases or object proportions.

The production rule became:

- normalize source assets to a shared physical standard;
- use consistent attachment points and pivots;
- keep scene roots at scale 1,1;
- do not force the user to guess a different scale per supposedly modular wall;
- verify wall height and seam alignment side by side before declaring a module complete.

The fire escape was configured as non-climbable because the user did not need climbing gameplay there.

## 10. Ground tiles

The first ground images were multi-tile illustrations rather than individual Godot tiles. They were rebuilt into exact 256x128 2:1 diamonds.

Ground families included:

- G001 Wet Concrete;
- G002 Drain Grate;
- G003 Steel Plate;
- G004 Hazard Stripes;
- G005 Puddle Reflections.

The tile requirements became:

- exact 256x128 canvas per tile;
- diamond tips on all four canvas boundaries;
- no green-screen residue;
- no internal transparent holes;
- no neighboring-tile contamination;
- complete coverage to each edge;
- correct repeated appearance;
- no collision on ordinary flat floor tiles;
- TileSet shape configured as isometric;
- 2:1 refers to width-to-height ratio, while 256x128 is the actual pixel size.

The user successfully added multi-variation atlases and painted randomized wet-concrete flooring in Godot.

## 11. Weather effects

The surface weather stack was created as separate systems:

```text
World
`- Effects
   |- FX001_RainSystem
   |  |- RainFar
   |  `- RainNear
   |- FX002_RainSplash
   `- FX003_RainMist
```

The user was guided through GradientTexture2D, gradient stops, alpha, offsets, particle process materials, emission shapes, and box extents. The user explicitly requested that Godot instructions remain click-by-click because they were learning the software.

## 12. Modular environment systems and camera changes

Manual module placement exposed inconsistent pivots, angles, and seams. A deterministic snapping system was developed, with later documentation referring to modular v1 and v2.

The project explored several viewpoints:

- classic symmetrical 2:1 isometric;
- off-axis fixed 2.5D;
- 45-degree view;
- 60-degree view.

The user preferred the 60-degree off-axis view and did not want dynamic camera rotation.

The final presentation direction became hybrid 2.5D:

- fixed orthographic camera;
- roughly 60-degree azimuth and 30-degree elevation;
- live 3D characters;
- real skeletal animation;
- real depth, shadows, and occlusion;
- modular environments assembled for that camera;
- no expectation of free camera rotation.

The user rejected Blender-converted assets that looked too clean, polished, or fully 3D. The target remained the painterly, moody, richly textured graphical feel seen in the Copper Hilt/Lantern Ward references, but with more modern architecture.

The user clarified that reference images were for palette, mood, texture density, lighting, and rendering style. They were not designs to duplicate literally.

## 13. Surface graphical direction

The strongest surface references established:

- rain-wet streets;
- high-contrast amber practical lights;
- controlled magenta/cyan reflections;
- deep shadow;
- painterly but readable materials;
- pipes, pressure vessels, vents, and industrial infrastructure;
- dense but functional clutter;
- modern apartment and service-alley architecture rather than 1920s facades.

The user explicitly requested that cyan and magenta come from runtime lighting rather than being painted permanently into neutral assets.

The opening environment target remained an apartment exterior with an alley immediately to its right. The apartment exterior door is the principal interactable. Entering it loads an interior instance rather than requiring the entire building interior to exist inside the exterior shell.

## 14. Git and multi-PC workflow

The project moved between computers through GitHub Desktop and PowerShell.

The repository remote initially failed because the remote URL referenced a nonexistent owner/repository. Credentials were inspected and the correct remote was set to:

`https://github.com/bdjoshgaming-eng/Steamtek-RPG.git`

The push eventually succeeded and `main` was configured to track `origin/main`.

The multi-PC rules became:

- store source, production, scenes, tools, manifests, and documentation in the repository;
- avoid absolute machine-specific paths in portable manifests;
- do not commit `.godot` cache unless intentionally required;
- preserve Steamtek Studio code and intended database state;
- use handoff documents to transfer context between Codex tasks and computers.

## 15. Hybrid 3D character proof

The project then focused on proving live 3D characters inside the hybrid 2.5D presentation.

An isolated hybrid proof scene was used so work would not conflict with Claude's gameplay implementation. Early rigs and animations required many iterations.

The walking problem was diagnosed through:

- runtime recordings;
- animation telemetry;
- model-forward correction;
- stationary walk tests;
- collision and obstacle tests;
- multiple rig-fit and deformation revisions.

The model's facing was corrected with a `+40 degree` model-forward offset. The user confirmed that this aligned the character correctly.

The workflow established an important rule: import success and action presence are not enough. The user must approve the actual gait and facing in motion.

## 16. Vesper Kane production character

Vesper Kane became the player-character target.

Her established identity includes:

- tall black top hat;
- long asymmetrical coat;
- high collar or respirator language;
- black, charcoal, and gunmetal base;
- controlled aged brass mechanics;
- physical-left mechanical arm;
- neo-industrial rather than generic Victorian costume;
- readable silhouette at the locked gameplay camera.

The production pipeline progressed through:

- multiple rig-fit versions;
- volume and silhouette refinements;
- deformation review;
- production mesh v1;
- production mesh v1.1;
- production appearance v1;
- reusable Steamtek humanoid character template.

The user asked whether every character would require the same long series of primitive-body steps. The answer became no: those iterations established the reusable skeleton, export, facing, scale, movement, and validation pipeline. Future characters should reuse the proven system and focus production work on identity meshes and clothing.

## 17. Modular clothing decision

The user asked whether clothing and armor could be swapped visibly. The answer was yes, provided all equipment used the shared skeleton and was divided into slots with body-region masking.

The modular plan became:

1. Lock skeleton, scale, animation, and export contract.
2. Build a finished-proportion neutral base body.
3. Divide the body into hideable regions.
4. Convert the default outfit into separate skinned equipment slots.
5. Export a versioned modular character without replacing the working Vesper.
6. Build an isolated Godot equipment-swap test.
7. Validate idle, walk, facing, scale, and visibility states.
8. Obtain visual approval before the detailed face/clothing/material pass.

## 18. Modular Vesper implementation completed July 16

The existing v1.1 production mesh was audited. It already contained useful separate garment pieces, so they were reused instead of rebuilt.

The modular contract was created at:

`assets/characters/player/VesperKane_3D/modular_character_v01/VESPER_MODULAR_CHARACTER_CONTRACT_V01.md`

A separate versioned Blender branch was built from:

`Steamtek_C001_VesperKane_ProductionMesh_v11.blend`

The new branch contains:

- 20 modular base-body meshes;
- 31 default-outfit slot meshes;
- the original 706-bone skeleton;
- `STK_IDLE` frames 1-8;
- `STK_WALK` frames 1-25;
- unchanged scale and animation contract;
- permanent physical-left mechanical arm;
- runtime-lighting-only metadata;
- neutral fitted body materials.

Body regions include:

```text
head
neck
torso
pelvis
upper_arm_r
forearm_r
hand_r
mechanical_arm_l
thigh_l
thigh_r
shin_l
shin_r
foot_l
foot_r
```

Current outfit slots include:

```text
headgear
outer_torso
shoulders
gloves
legs
boots
waist
hip_right
```

The versioned production folder is:

`assets/characters/player/VesperKane_3D/modular_character_v01`

The working player scene was not replaced.

## 19. Godot modular equipment review

The isolated player wrapper is:

`res://scenes/characters/player/VesperKane_ModularCharacterReview_v01.tscn`

The isolated playtest is:

`res://scenes/tests/characters/VesperKane_ModularEquipment_Playtest_v01.tscn`

Controls:

```text
WASD - movement
1    - body only
2    - default outfit
3    - mixed loadout
```

Godot imported the GLB and reported:

```text
20 modular body meshes
31 modular outfit meshes
1 skeleton
1 AnimationPlayer
STK_IDLE present
STK_WALK present
validation PASS
```

The automated equipment visibility signatures were:

```text
body only      20:0
default outfit  9:31
mixed loadout  12:13
swap test PASS
```

The current working Vesper and Claude-owned `main.tscn`, `main.gd`, and gameplay code were deliberately untouched.

## 20. Current state and next decision

The technical modular-character stage is complete and ready for visual review.

The neutral base body is a finished-proportion garment-support shell, not the final face and skin-detail pass. The default outfit is the approved v1.1 production geometry organized into real equipment slots.

The next scheduled work, after review, is:

1. finalize Vesper's face and head identity;
2. refine visible anatomy and transitions;
3. author final garment topology and surface detail;
4. create neutral PBR textures and weathering;
5. create at least one alternate equipment item;
6. prove a real item-to-item swap;
7. validate the final result in movement and at the locked gameplay camera;
8. only then prepare an approved replacement candidate for the live player.

## 21. Persistent user preferences

The user has repeatedly requested that collaborators follow these working rules:

- complete coherent batches before reporting;
- do not stop after every tiny step when a sequence is already approved;
- avoid one-step-forward/three-steps-back tool expansion;
- avoid unnecessary rework;
- use production-safe methods when known;
- preserve working versions and rollback sources;
- keep files organized and portable across PCs;
- provide click-by-click Godot instructions while the user is learning;
- use visual collision and setup examples when helpful;
- never declare an animation fixed from structural validation alone;
- protect the modern neo-industrial art direction;
- reject Victorian drift;
- treat cyan/magenta as runtime environmental lighting rather than baked neutral-asset color;
- keep the camera fixed rather than dynamically rotating;
- do not interfere with Claude-owned gameplay files unless explicitly requested.

## 22. Authoritative current resume files

Read these before continuing character work:

```text
docs/STEAMTEK_HANDOFF_2026-07-16_MODULAR_VESPER.md
assets/characters/player/VesperKane_3D/modular_character_v01/VESPER_MODULAR_CHARACTER_CONTRACT_V01.md
docs/STEAMTEK_HUMANOID_3D_TEMPLATE_V01.md
docs/VESPER_PRODUCTION_MESH_V11_REVIEW.md
docs/VESPER_PRODUCTION_APPEARANCE_V01_REVIEW.md
```

Run this scene first:

`res://scenes/tests/characters/VesperKane_ModularEquipment_Playtest_v01.tscn`

Do not replace the current player until the user explicitly approves the modular visual result.

