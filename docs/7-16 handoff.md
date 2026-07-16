# Steamtek — 7-16 Handoff

Updated: July 16, 2026  
Canonical project: `C:\My Game\Steamtek-RPG`

## Immediate resume point

The only active problem at handoff is the **live 3D character walk inside the isolated hybrid proof scene**.

The user’s latest recording is:

`C:\Users\bdjos\AppData\Local\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe\TempState\Recordings\20260716-0723-31.4553265.mp4`

The user’s verdict is: **“still not working.”**

Do not call the walk fixed merely because Blender exports, Godot imports, or the scene parses. The in-game gait must look smooth in motion. The next worker must diagnose the actual runtime result shown in the recording before authoring another animation revision.

### Current live hybrid proof

Open and run:

`res://scenes/tests/hybrid_3d/Steamtek_Hybrid3D_POC.tscn`

Controller:

`C:\My Game\Steamtek-RPG\scenes\tests\hybrid_3d\steamtek_hybrid_3d_poc.gd`

Current character model:

`C:\My Game\Steamtek-RPG\assets\characters\npc\Steamtek_C002\production\STK_C002_RigProof_v1.glb`

Current Blender source:

`C:\My Game\Steamtek-RPG\assets\characters\npc\Steamtek_C002\blender\Steamtek_C002_DetailedPrototype_v1_3.blend`

Current walk authoring script:

`C:\My Game\Steamtek-RPG\blender\character_pipeline\scripts\Steamtek_Upgrade_C002_Walk_v3.py`

Current walk report:

`C:\My Game\Steamtek-RPG\assets\characters\npc\Steamtek_C002\blender\STK_C002_Walk_v3.report.json`

Rollback backup made before installing walk v3:

`C:\My Game\Steamtek-RPG\assets\characters\npc\Steamtek_C002\production\backups\20260716_015838_pre_walk_v3`

Workspace QA and diagnostic material:

```text
C:\Users\bdjos\Documents\Codex\2026-07-10\steampunk-alleyway-map-chatgpt-conversation-6a5068ff\character_3d_pipeline\
├── walk_issue_recording.mp4
├── walk_issue_recording_2.mp4
├── extract_video_frames_blender.py
├── upgrade_c002_walk_v3.py
├── Steamtek_C002_DetailedPrototype_v1_3_walk_v3.blend
├── STK_C002_RigProof_v1_walk_v3.glb
├── STK_C002_RigProof_v1_walk_v3.export.json
├── STK_C002_RigProof_v1_walk_v3.validation.json
├── STK_C002_Walk_v3.report.json
├── STK_C002_Walk_v3_QA.png
├── STK_C002_Walk_v3_QA.gif
└── walk_v3_qa\
```

The second recording was copied into the workspace, but frame extraction was interrupted by this handoff request. `extract_video_frames_blender.py` was created for that purpose and should be run with Blender 4.5.

## What was already checked

- The controller does **not** restart the walk every physics frame. `_play_character_animation()` returns when the requested animation is already active.
- The live controller finds imported clips by suffix and expects `STK_IDLE` and `STK_WALK`.
- The current controller uses camera-relative movement and smooth yaw interpolation.
- Current movement constants are:

```gdscript
const WALK_SPEED := 4.2
const MOVEMENT_ACCELERATION := 18.0
const MOVEMENT_DECELERATION := 24.0
const TURN_RESPONSE := 12.0
const GRAVITY := 18.0
```

- Walk v3 was authored as a one-second, 24 FPS, root-motion-free loop with poses at frames `1, 4, 7, 10, 13, 16, 19, 22, 25`.
- The source and exported GLB passed structural validation.
- First and last authored poses matched exactly.
- The exported GLB round-tripped with the rig, meshes, `STK_IDLE`, and `STK_WALK` present.
- Godot reimported the GLB, and the hybrid scene loaded headlessly without parse errors.
- A still-pose contact sheet and animated GIF showed alternating leg poses.
- Despite those checks, the user’s actual in-game recording still failed the visual acceptance test.

This means the remaining fault is likely in one of these areas:

1. The imported action is present but the model is not visibly deforming enough at runtime.
2. Godot is sampling or blending the imported action differently from the Blender QA render.
3. The world movement speed and animation playback speed are mismatched, producing obvious foot sliding.
4. The generated proof rig/model is too stiff or mechanically constrained for the authored transforms to read as a natural gait.
5. A different imported clip or stale `.godot` cache is being used in the GUI session even though headless import succeeded.

## Exact next diagnostic sequence

Do this before creating walk v4:

1. Run the Blender video-frame extractor against `walk_issue_recording_2.mp4` and inspect at least 12 evenly spaced frames.
2. Determine whether the character visibly changes pose while moving.
3. Add a temporary runtime diagnostic label to the isolated proof only, showing:
   - current animation name;
   - animation position;
   - animation length;
   - playback speed;
   - horizontal player speed.
4. Log the imported `STK_WALK` track count and duration from Godot.
5. Temporarily stop world movement while forcing `STK_WALK` to play. If the model still does not visibly walk, the issue is animation import/deformation rather than speed matching.
6. If the gait animates correctly while stationary, calculate animation playback from actual movement speed instead of guessing. Keep root motion disabled.
7. Only after that evidence should a new Blender gait be authored.
8. Preserve the current GLB and `.blend` as rollback sources before any replacement.

Do not repeat the previous pattern of declaring success from parse/import checks alone. The final acceptance gate is a new user-recorded runtime test.

## Hybrid 2.5D direction lock

Steamtek’s chosen presentation is a **hybrid 2.5D game**:

- live high-fidelity 3D characters;
- live skeletal animation;
- continuous 3D facing, not eight-direction sprite snapping;
- fixed orthographic camera;
- existing painted/modular Steamtek environment art mounted in a 3D scene where useful;
- real depth, occlusion, lighting, and shadows;
- Godot remains the engine.

Current hybrid camera contract:

- orthographic;
- 60-degree azimuth;
- 30-degree elevation;
- camera position `Vector3(8.660254, 10.0, 15.0)`;
- current camera size `18.0`.

The technical proof character is not the final hero. It validates integration only.

Canonical character target documentation:

- `docs/VESPER_KANE_CHARACTER_TARGET.md`
- `docs/STEAMTEK_HYBRID_3D_POC.md`

Vesper Kane visual identity:

- neo-industrial / neo-punk, not Victorian costume parody;
- tall black top hat;
- high collar or scarf;
- long asymmetrical weathered coat;
- black and gunmetal base;
- controlled brass mechanics;
- cyan primary emissive technology;
- magenta secondary accent;
- one persistent brass mechanical arm whose side may never drift or mirror;
- raven drone as an optional detachable attachment;
- boots define ground contact.

## Art-direction lock

Steamtek is not Victorian steampunk. The established surface direction is:

- modern neo-industrial / neo-punk;
- steam-pressure technology in a cyberpunk-era society;
- concrete, gunmetal, black steel, copper pressure lines, rain, steam, cyan, magenta, amber;
- functional exposed infrastructure;
- rain-wet streets and reflections;
- no top hats/gears/Victorian architecture as generic decoration, except character-specific choices such as Vesper’s intentional silhouette;
- no painted checkerboard backgrounds or green-screen residue in production PNGs;
- no AI-generated geometry drift in modular assets.

Canonical surface references:

- `Steamtek_Surface_ColorPalette_Aesthetic_Reference.png` for palette, materials, wet lighting, water, and overall scene mood;
- `ApartmentExterior_AssemblyMockup.png` for apartment composition.

When both apply, use the apartment mockup for construction and the surface reference for the graphical treatment.

## Modular environment system status

The original hand-assembled surface modules exposed inconsistent pivots, source canvases, angles, and scale. That work was frozen as legacy. The project moved to strict modular systems with deterministic attachment points.

### Modular v1

Modular v1 established standardized 2D scenes and validation scenes for:

- wall runs;
- inside/outside corners;
- seam columns;
- front/side walls;
- window, door, and feature wall variants;
- roof surfaces;
- parapets, corners, and end caps;
- fire escape split into platform and ladder;
- apartment-shell assembly tests.

It proved that the asset families could be assembled, but visible seams and placement drift still occurred when relying on manual alignment.

### Modular v2

Modular v2 is the authoritative deterministic snap system. Read the existing `docs/handoff.md` before changing it.

Important current rules:

- shared TileMap lattice axes `(64, -32)` and `(64, 32)`;
- exact `256x128` isometric ground diamonds;
- wall/foundation attachment markers are authoritative;
- the Steamtek modular snap editor plugin is version `2.1.0`;
- validator: `tools/validate_modular_v2.py`;
- do not launch headless Godot while the GUI editor is open;
- do not modify `main.tscn` or `main.gd` during modular pipeline work.

Existing modular-v2 handoff:

`C:\My Game\Steamtek-RPG\docs\handoff.md`

That document contains the current wall, roof, foundation, sidewalk, wet-street, fidelity, validation, and staging status. It remains the source of truth for modular-v2 environment continuation.

## Earlier Godot scene standards

Reusable 2D props were built as scenes, not loose PNGs:

```text
PropName (StaticBody2D)
├── Visual (Sprite2D)
├── BaseCollision (CollisionShape2D or CollisionPolygon2D)
├── PointLight2D (optional)
├── GPUParticles2D (optional)
└── AudioStreamPlayer2D (optional)
```

Root scene nodes normally stay at:

```text
Position: 0, 0
Scale: 1, 1
```

Per-asset sizing belongs on the visual child. Collision is separately fitted to the physical ground footprint. Do not reuse a scale value across different source resolutions without validation.

Y-sorted runtime hierarchy established earlier:

```text
Main
└── World
    ├── Ground
    ├── Effects
    ├── Lighting
    └── YSortLayer
        ├── Player
        ├── NPCs
        ├── Enemies
        ├── Props
        └── Buildings when player-relative occlusion is required
```

Trainers remain NPCs; teaching is behavior, not scene identity. Interactables are world objects such as doors, elevators, valves, consoles, chests, crafting stations, quest boards, and Steamtek Artifacts.

## Surface Kit 001 and legacy prop status

The first surface kit produced reusable scenes for:

- P001 Street Lamp;
- P002 Industrial Crate;
- P003 Industrial Barrel;
- P004 Steam Vent;
- P005 Straight Pipe;
- P006 Pipe Valve;
- P007 Pipe Corner + Valve;
- P008 Utility Box.

Legacy visual scales were calibrated per source image and must not be treated as universal physical standards. Examples discussed during prototyping included approximately:

- crate `0.16`;
- barrel `0.14`;
- valve `0.23`;
- lamp `0.30`.

These numbers belong only to those particular legacy source canvases. The reusable scene root must remain `1,1`.

## Weather FX completed earlier

The surface weather stack was created as separate effects:

```text
World
└── Effects
    ├── FX001_RainSystem
    │   ├── RainFar
    │   └── RainNear
    ├── FX002_RainSplash
    └── FX003_RainMist
```

The user supplied a rain reference video and requested crisp, impactful nighttime rain. The rain, splash, and mist were made functional. Y-sort is not needed for full-screen/weather particles unless an effect is specifically meant to pass behind/in front of world objects.

## Steamtek Studio and asset intake

Steamtek Studio evolved from an Asset Cutter and SQLite asset database into the project’s asset tracking/intake tool.

Authoritative tool location:

`C:\My Game\Steamtek-RPG\tools\steamtek-studio`

Runtime data may exist under:

`C:\My Game\Steamtek-RPG\.steamtek-studio`

Do not delete the dot-folder merely because the application code lives under `tools`; it may contain `studio.db`, backups, and thumbnails.

The tool must preserve:

- asset edit popup on double-click;
- readable dark-theme fields and dropdown text;
- asset ID, name, category, status, kit, source path, production path, and Godot scene path;
- folder-picker icons for file/path fields;
- saving edits;
- deleting stale database records for assets removed from disk;
- asset cutter integration;
- auto-discovery of the project’s current modular structure.

The user wants the Studio code and database committed to Git so the same project state can move between PCs. Do not hide the whole Studio directory with `.gitignore`. Ignore only disposable caches if necessary.

## Gameplay loop

Steamtek’s core loop remains:

1. Prepare at the tiny rain-soaked surface hub.
2. Talk to NPCs, accept contracts, train, craft, repair, and equip.
3. Descend through the manhole/elevator into the silo.
4. Explore procedural or modular underground districts.
5. Fight enemies, solve hazards, and recover Steamtek Artifacts and resources.
6. Decide whether to push deeper or extract.
7. Return to the Brass Lantern/surface refuge.
8. Cash in discoveries, upgrade equipment and professions, advance NPC stories, and unlock deeper routes.
9. Descend again.

The surface is intentionally tiny: apartment, alley, straight rainy street, Brass Lantern bar, and descent point. Approximately 99.9% of the game is underground in the silo.

## World and tone lock

- Working title: **Steamtek**.
- The technology is steam-pressure based, but the era and architecture are modern/neo-industrial.
- Society believes steam powers civilization, but steam may only be the interface or key to much older impossible machinery.
- The deeper the player travels, the older and more advanced the machinery becomes.
- Steamtek Artifacts are the canonical artifact name.
- The surface is a persistent safe-zone/hub that becomes richer, not geographically larger.
- The central promise is vertical mystery: **go deeper**.

## Git and multi-PC workflow

Canonical repo:

`C:\My Game\Steamtek-RPG`

The user uses GitHub Desktop to move between PCs. Keep project tools, source files, production assets, scenes, database, and documentation inside the repo wherever practical.

Current Codex sandbox may report Git “dubious ownership” because the canonical repo is owned by the Windows Administrator group while Codex runs under a sandbox account. Do not modify global Git configuration without the user’s approval. GitHub Desktop on the user account remains the normal commit/push route.

Before pushing:

1. Review changed files in GitHub Desktop.
2. Ensure large generated archives do not exceed GitHub’s per-file limit.
3. Include `tools/steamtek-studio` and the intended database.
4. Include `docs/7-16 handoff.md` and `docs/7-16 convo.md`.
5. Do not commit `.godot` import cache unless the project has intentionally chosen to do so.
6. Commit and push from the PC containing the latest canonical repo.

## User working preferences

- Give direct, click-by-click Godot instructions until the user says otherwise.
- Show scene structures as trees.
- Use Godot scale values when discussing current scene visuals, but never pretend one scale applies to unrelated source resolutions.
- Be encouraging and decisive.
- Shoulder the production work instead of returning abstract art-direction advice.
- Do not repeatedly ask permission to move to the next obvious stage.
- Do not rebuild working material merely for the sake of rework.
- Preserve rollback copies before replacements.
- Verify actual in-game behavior, not just file existence or parse success.
- For visuals, prioritize Godot-ready assets and reusable pipelines over concept sheets.
- Keep neo-industrial identity and reject Victorian drift.

## Definition of done for the current walk task

The C002 walk task is not complete until all of the following are true:

- `STK_WALK` visibly deforms the model through a readable alternating gait in Godot;
- the loop has no hitch;
- feet do not obviously skate at the configured movement speed;
- start/stop blending is smooth;
- continuous turning remains smooth;
- no eight-direction snapping is reintroduced;
- no root motion fights `CharacterBody3D` movement;
- the user records and approves the runtime result;
- the working `.blend`, GLB, scripts, reports, and backup are retained.

