# Steamtek — 7-16 Conversation Record

Updated: July 16, 2026  
Project: `C:\My Game\Steamtek-RPG`

> This is a comprehensive chronological record of the project conversation and decisions through July 16, 2026. It is organized for continuation and is not a word-for-word export of every short acknowledgment or repeated troubleshooting message.

## 1. Original game idea

The project began with a request for a steampunk-themed isometric 2D alleyway map for a Godot RPG. Early generated images looked attractive but were concept art rather than production assets. The key distinction was established immediately:

- a single painted map cannot provide modular collision, Y-sorting, animation, or procedural reuse;
- Godot needs separate tiles, props, walls, doors, effects, and scenes;
- true isometric assets must use a consistent projection and ground contact;
- production assets require transparency, predictable scale, clean pivots, and reusable `.tscn` scenes.

The opening area was deliberately narrowed to:

```text
Apartment
└── Elevator / exit
    └── Rainy alley
        └── Straight street
            └── Brass Lantern bar
                └── Manhole / descent
                    └── The Silo
```

The surface is a tutorial, atmosphere piece, and persistent refuge. Nearly the entire game—described as roughly 99.9%—takes place underground.

## 2. Opening experience and gameplay loop

The first ten minutes were outlined:

- wake in a small apartment while rain hits the window;
- inspect environmental story clues;
- leave through the building/elevator;
- cross a narrow rain-soaked district;
- reach the Brass Lantern;
- meet recurring NPCs;
- accept a missing-courier or descent contract;
- enter the silo through a hatch/manhole;
- begin the real exploration loop.

The durable gameplay loop became:

```text
Prepare at surface hub
→ accept contract / train / craft / equip
→ descend into silo
→ explore, fight, solve hazards, recover artifacts
→ choose to push deeper or extract
→ return to Brass Lantern
→ upgrade professions, gear, relationships, and routes
→ descend again
```

The surface should become richer through NPC reactions, apartment upgrades, discoveries, and recovered relics—not become a large explorable city.

## 3. Steamtek identity and world bible

The working title became **Steamtek**.

The visual direction changed from conventional Victorian steampunk to a more original idea:

> Steam-powered technology in a cyberpunk-era world.

The established identity is:

- neo-industrial / neo-punk;
- modern apartment blocks and industrial infrastructure;
- concrete, gunmetal, black steel, copper, rain, steam, cyan, magenta, and amber;
- pneumatic weapons, pressure engines, mechanical prosthetics, drones, and brass robotics;
- functional machinery rather than decorative gears;
- no generic Victorian London, horse carriages, top hats everywhere, ornate taverns, or fantasy-steampunk clutter.

Vesper Kane later became an intentional exception to the generic “no top hats” shorthand: the hero’s tall hat is a specific neo-punk silhouette element, not a return to Victorian world design.

The lore direction became:

- the surface believes steam powers civilization;
- steam may actually be the key/interface used to activate ancient technology;
- deeper machinery is older but more advanced;
- people maintain systems they do not truly understand;
- the player’s central question is not “who rules the kingdom?” but “how deep does this go?”

The artifact name was standardized as **Steamtek Artifacts**.

## 4. Marketplace research and decision to create custom assets

Several affordable packs were discussed, but many recommendations turned out to be top-down, pixel-art, or 3D rather than true HD isometric 2D. That exposed an underserved niche:

- true isometric;
- steampunk/neo-industrial;
- HD or high-detail presentation;
- modular;
- Godot-friendly;
- commercially reusable.

Because the surface district is small and the silo is the real game, the project chose to create a custom Steamtek library rather than compromise the projection or visual identity.

## 5. First tile and prop experiments

The initial plan used a `256x128` isometric footprint. AI-generated “tiles” repeatedly included side faces, shadows, text, or rectangular backgrounds. Godot correctly displayed the whole rectangle, proving that the images were renders of tiles rather than actual tiles.

The production requirements were established:

- transparent PNG;
- no checkerboard painted into the image;
- no guide lines or text;
- no background;
- no unintentional baked steam or shadow;
- bottom-center or explicit ground-contact pivot;
- consistent projection;
- final asset imported through a reusable Godot scene.

The first successful prop was P001 Street Lamp. During collision troubleshooting, the true problem was eventually found: the player’s collision shape was massive. Shrinking it to the feet/lower body fixed the apparent “lamp collision” issue.

This established a repeated lesson: visible failure may come from the player, source PNG, scene root, visual child, collision, or Y-sort. Do not assume the last edited asset is the cause.

## 6. Surface Kit 001

Surface Kit 001 was defined as one complete kit, not multiple unrelated kits. It contained:

1. Industrial Crate
2. Industrial Barrel
3. Steam Vent
4. Straight Industrial Pipe
5. Pipe Corner + Valve
6. Utility Box
7. Wall Module A
8. Apartment Door
9. Window Module
10. Fire Escape
11. Ground tile examples

The initial extracted prop family became:

- P001 Street Lamp
- P002 Industrial Crate
- P003 Industrial Barrel
- P004 Steam Vent
- P005 Straight Pipe
- P006 Pipe Valve
- P007 Pipe Corner + Valve
- P008 Utility Box

Production PNGs were cleaned in Photopea. Problems included white halos, fake transparency, checkerboard residue, green outlines, and smoke being damaged by background removal. The lesson was to separate smoke/steam into Godot effects whenever possible and preserve the solid prop independently.

Legacy visual scales were tuned individually because source canvases differed. Approximate values included crate `0.16`, barrel `0.14`, valve `0.23`, and lamp `0.30`. These were never universal world standards.

The reusable rule became:

- scene root: position `0,0`, scale `1,1`;
- visual child: per-source scale and offset;
- collision child: physical footprint only;
- scene instance: positioning in the map, not compensation for bad source pivots.

## 7. Asset Cutter and Steamtek Studio

Manual extraction in Photopea led to the Steamtek Asset Cutter. It opened source sheets, let the user draw crop rectangles, assigned IDs/names, exported source and production PNGs, created folders, and generated documentation.

The tool then expanded into Steamtek Studio:

- SQLite asset database;
- dashboard;
- asset list and status tracking;
- kits;
- integrated Asset Cutter;
- source/production/Godot scene paths;
- QC flags;
- file count/status display;
- JSON export;
- local backups and thumbnails.

Several UI regressions were corrected or identified:

- double-click must open Edit Asset;
- edit popup styling should match the dark Steamtek theme;
- dropdown text must be readable;
- path fields need folder icons that open a file/folder picker;
- selections must save;
- assets removed from disk must be deletable from the database;
- the tool should auto-discover the current project structure;
- the Asset Cutter must remain included.

The code belongs in:

`C:\My Game\Steamtek-RPG\tools\steamtek-studio`

Runtime data may exist in:

`C:\My Game\Steamtek-RPG\.steamtek-studio`

The dot-folder may contain `studio.db`, backups, and thumbnails. It is not automatically obsolete merely because the main tool folder exists under `tools`.

The user explicitly wants the tool and database available through GitHub Desktop across multiple PCs. The whole Studio folder should not be hidden by `.gitignore`.

## 8. Godot hierarchy, collision, and Y-sort

The project adopted a clean world hierarchy:

```text
Main
└── World
    ├── Ground
    │   └── GroundTileMap
    ├── Effects
    ├── Lighting
    └── YSortLayer
        ├── Player
        ├── NPCs
        ├── Enemies
        ├── Props
        ├── Interactables
        └── Buildings when required for player-relative occlusion
```

Moving the player, NPCs, and props under one Y-sorted parent fixed the character appearing on top of lamps and crates when walking behind them.

NPC trainers remain under `NPCs`; training is behavior. Interactables are objects such as doors, elevators, levers, valves, harvesters, crafting stations, resource nodes, quest boards, consoles, and artifacts.

For collisions:

- `CollisionShape2D` must be a child of a collision object such as `StaticBody2D`, `CharacterBody2D`, `Area2D`, or `RigidBody2D`;
- player collision belongs around the feet/lower torso;
- prop collision belongs around the ground footprint;
- isometric-looking visual art does not require tracing the whole silhouette;
- debug collision visibility is used to inspect the real shapes.

## 9. ScaleLab and universal sizing

The project attempted to establish common visual proportions for characters and props. The major discovery was that Godot scale values are not physical measurements by themselves. A scale of `0.2` applied to a 1280-pixel source is completely different from `0.2` applied to a 300-pixel source.

The stable rule became:

- keep reusable scene roots at `1,1`;
- tune each visual child against a shared ScaleLab scene;
- compare characters, doors, barrels, crates, lamps, valves, vents, and pipe diameters in the same scene;
- assets that physically connect must be generated from the same source scale/camera or normalized before import;
- do not carry a visual-scale number to a different source-resolution family.

Later, the modular and Blender pipelines replaced eyeballed scale with locked source families and attachment contracts.

## 10. Rain, splash, and mist

The surface was locked to nighttime rain. The weather stack became:

```text
FX001_RainSystem
├── RainFar
└── RainNear

FX002_RainSplash

FX003_RainMist
```

Rain used GPU particles with box emission, directional velocity, gravity/acceleration, lifetime, amount, visibility rect, and gradient-based streak textures. Near and far layers were tuned separately for brightness, size, and density.

The user supplied rain video references and rejected thick, blurry streaks. The desired result is crisp, sharp, impactful nighttime rain—not oversized white bars.

Rain splash added ground-contact response. Mist initially appeared as floating squares until its texture/shape/alpha behavior was corrected. Effects live under `World/Effects`, not under Y-sort by default.

## 11. Apartment exterior attempt

The desired apartment was defined by `ApartmentExterior_AssemblyMockup.png`: a two-story neo-industrial building with windows, door, roof, parapets, fire escape, pipes, wet foundation/sidewalk, cyan and magenta accents, and dense detail.

The first assembly scene was organized as:

```text
B100_ApartmentExterior (Node2D)
└── Modules (Node2D)
    ├── Foundation (Node2D)
    ├── GroundFloor (Node2D)
    ├── UpperFloor (Node2D)
    ├── Structure (Node2D)
    ├── FireEscapeSection (Node2D)
    └── Roof (Node2D)
```

Assets were placed manually, but some lined up and others did not even when scene roots and visual scales appeared identical. The reasons included:

- different production PNG canvases;
- inconsistent visible extents;
- source pivots not normalized;
- different ground-contact offsets;
- camera/projection drift;
- pieces containing overlapping wall geometry;
- fire escape baked together with wall material;
- no authoritative snap markers.

The user correctly objected that this was not truly modular and requested a system where walls, floors, roofs, foundations, stairs, ladders, windows, doors, and corners genuinely snap together.

## 12. Modular v1

The old panels were frozen as legacy and a new versioned modular library was built beside them. Work included:

- W001 plain wall;
- W005/W006 wall end caps;
- W007 outside corner;
- W008 inside corner;
- W009 seam column;
- W010 side plain wall;
- W011 side window wall;
- W012 side apartment door;
- W013 side feature wall;
- front and side wall-family validation scenes;
- roof surface tiles;
- parapet front/side runs;
- outside and inside parapet corners;
- parapet end caps;
- cornice/fascia pieces;
- fire escape split into platform and ladder;
- apartment-shell and roof-system assembly tests.

Screenshots confirmed many families lined up visually in validation scenes. Some generated `.tscn` files briefly failed with `Parse Error: Expected '['`; those files had to be repaired as valid Godot text resources.

The apartment shell eventually assembled into a recognizable two-story structure with roof and fire escape, but visible gaps and seams remained. This proved that correct-looking artwork was not enough; deterministic snapping had to become an editor and data contract.

## 13. Modular v2 deterministic snap system

The user made modular snapping the only priority until it worked.

The project moved to Modular v2 with:

- fixed lattice and projection;
- authoritative attach markers;
- standardized source families;
- Blender-controlled geometry;
- validation scenes;
- an editor snap plugin;
- a strict validator;
- no manual “looks close” acceptance.

Key contracts include:

- ground diamond `256x128`;
- shared TileMap lattice axes `(64,-32)` and `(64,32)`;
- deterministic foundation/wall attachment points;
- explicit corner and seam pieces;
- production/staging separation;
- canonical alpha masks;
- geometry cannot be changed by AI fidelity passes.

The existing authoritative modular-v2 state is documented in:

`C:\My Game\Steamtek-RPG\docs\handoff.md`

It includes walls, roofs, foundations, wet concrete/street tiles, sidewalk families, rejected variants, fidelity rules, scene-driven colored reflections, and the current modular snap plugin.

## 14. Fidelity and Blender direction

The user repeatedly emphasized high-fidelity graphics and was concerned that AI-generated images would drift in projection and geometry. A Reddit discussion reinforced the solution: a locked 3D-to-2D render pipeline with controlled camera, lighting, scale, model, animation, and batch rendering.

The agreed long-term art pipeline became:

```text
Controlled 3D geometry in Blender
→ locked orthographic camera
→ fixed scale, origin, lighting, and projection
→ batch render
→ optional AI/style enhancement constrained by masks
→ geometry/silhouette/snap validation
→ Godot-ready production asset
```

AI may improve materials, weathering, or surface fidelity, but it may not redefine:

- silhouettes;
- module endpoints;
- snap points;
- pivots;
- projection;
- connected pipe diameter;
- character anatomy or mechanical-arm side;
- direction correctness.

The user tested PromeAI on a wall and liked the higher material fidelity. That demonstrated a useful possible enhancement stage, but geometry remains authoritative in Blender.

## 15. Character sprite pipeline

An AI-generated character sheet was rejected as a production source because character details, pivots, directions, silhouettes, and feet drifted between frames.

The project built a reusable C001 character pipeline with:

- locked Blender master;
- `Root_CTRL` direction pivot;
- true eight-direction renders;
- transparent fixed-size frames;
- walk/idle export;
- automatic atlas and Godot resource generation;
- QA manifests;
- installer/package for moving between PCs.

The validated conversation-root C001 package used `1254x1254` frames, eight directions, and eight frames per walk direction. One checkout used visual scale `0.09` and offset `(0,-422)`; another canonical repo note recorded `0.73` and approximately `(0,-110)`. Those values belong to different source/checkouts and must never be silently mixed.

Direct AI sprite-sheet attempts produced wrong diagonal directions and mirroring. The user explicitly rejected permanent mirroring and asked to finish the Blender pipeline instead of repeatedly patching bad sheets.

## 16. Pivot to live 3D characters

The user asked how difficult it would be to use 3D characters in the locked-camera 2.5D-HD world. Godot was confirmed capable, and the project chose a hybrid approach:

- live 3D character models;
- skeletal animation;
- continuous rotation;
- real lighting and shadow;
- orthographic locked camera;
- existing painted/modular environment art used in the hybrid scene;
- no forced eight-direction sprite snapping.

The isolated proof was created at:

`res://scenes/tests/hybrid_3d/Steamtek_Hybrid3D_POC.tscn`

It demonstrated:

- live imported GLB character;
- `STK_IDLE` and `STK_WALK` clips;
- camera-relative movement;
- continuous turn interpolation;
- 3D collision and occlusion;
- cyan, magenta, and amber runtime lighting;
- an existing painted Steamtek wall on a 3D plane;
- no changes to the main game scene.

The user said the early hybrid proof worked well, but later versions did not walk smoothly.

## 17. Vesper Kane target

The desired hero was locked from full-body and character-sheet references:

- neo-industrial runner;
- top hat and covered lower face;
- cyan monocle/HUD;
- mechanical arm;
- long weathered coat;
- black, gunmetal, brass, cyan, and magenta;
- optional raven drone;
- fluid run/attack possibilities;
- no mirrored anatomy drift.

The current C002 model is only a rig/animation technical proof. It is not final Vesper art.

## 18. Current C002 walk-cycle failure

The user reported that the live 3D model was not walking smoothly. The controller was inspected and confirmed not to restart the animation each physics frame.

The first procedural walk was identified as a sine-wave pose wobble rather than a real gait. Walk v3 was then authored with:

- 24 FPS;
- one-second loop;
- contact, pass, lift, and alternating step poses;
- arm counter-swing;
- hip movement;
- no root motion;
- exact matching first/last pose.

The new source and exported GLB passed structural validation. Godot reimported the model, and the isolated scene parsed and loaded. Still-pose QA showed alternating steps.

However, the user’s July 16 runtime recording still failed visually. The most recent recording is:

`20260716-0723-31.4553265.mp4`

The current diagnosis must continue from runtime evidence. Do not create another gait merely because the last one was unsatisfactory. First distinguish among:

- animation not visibly deforming in Godot;
- stale imported model;
- wrong imported action;
- playback/movement speed mismatch;
- excessive rigidity in the proof rig;
- blend/interpolation issue.

The precise resume steps are in `docs/7-16 handoff.md`.

## 19. Current canonical paths

```text
C:\My Game\Steamtek-RPG\
├── assets\
│   ├── characters\
│   │   ├── player\Steamtek_C001\
│   │   └── npc\Steamtek_C002\
│   └── modular_v2\
├── blender\
│   ├── character_pipeline\
│   └── modular_v2\
├── scenes\
│   ├── tests\hybrid_3d\
│   ├── modular_v1\
│   └── modular_v2\
├── tools\
│   ├── steamtek-studio\
│   ├── character-pipeline\
│   └── modular-intake\
├── .steamtek-studio\
└── docs\
```

Current live hybrid files:

```text
scenes/tests/hybrid_3d/Steamtek_Hybrid3D_POC.tscn
scenes/tests/hybrid_3d/steamtek_hybrid_3d_poc.gd
assets/characters/npc/Steamtek_C002/production/STK_C002_RigProof_v1.glb
assets/characters/npc/Steamtek_C002/blender/Steamtek_C002_DetailedPrototype_v1_3.blend
blender/character_pipeline/scripts/Steamtek_Upgrade_C002_Walk_v3.py
```

## 20. Permanent project rules

1. Steamtek is neo-industrial/neo-punk, not generic Victorian steampunk.
2. The surface remains small; the silo is the game.
3. Reusable assets and pipelines are more valuable than one-off concept art.
4. Godot-ready scenes/resources are preferred over PNG-only handoffs.
5. Scene roots stay clean; visual offsets/scales belong to visual children.
6. Never assume one Godot scale value applies to different source resolutions.
7. Collision represents ground footprint, not the whole illustration.
8. Player, NPCs, enemies, and sortable props share an appropriate Y-sorted hierarchy in 2D scenes.
9. Modular geometry, pivots, projection, and snap points are authoritative.
10. AI can enhance materials but cannot redefine geometry.
11. Character direction/anatomy may not be faked through permanent mirroring.
12. Keep rollback versions before overwriting working files.
13. Do not call a feature complete until the user verifies it in the actual game.
14. Give direct, step-by-step Godot instructions and scene trees when teaching.
15. Keep project tools and documentation inside the Git repo so work can move across PCs.

## 21. Immediate next action

Resume at the C002 runtime walk failure. Review the latest recording frame by frame, add temporary runtime animation telemetry to the isolated hybrid proof, determine whether the imported skeleton is visibly deforming, and only then either correct Godot playback/speed synchronization or author the next Blender gait revision.

