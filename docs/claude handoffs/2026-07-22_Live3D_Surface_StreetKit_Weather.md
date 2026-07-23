STEAMTEK RPG - LIVE3D SURFACE: STREET KIT COLLISION, STEP CLIMBING & WEATHER
=============================================================================
Date: 2026-07-22
Status: COMPLETE and confirmed working in-game
Touches: SteamtekSurfaceBlank3D.tscn, steamtek_humanoid_character_3d.gd,
         Steamtek_HumanoidCharacter3D.tscn, 5 street kit .tscn files,
         steamtek_transition_level_3d.gd, steamtek_apartment.gd,
         steamtek_lantern_playable_3d.gd, steamtek_surface_weather_3d.gd (new)


--------------------------------------------------------------
1. SCENE TREE ORGANIZATION (SteamtekSurfaceBlank3D.tscn)
--------------------------------------------------------------
Added four organizer Node3Ds under the scene root:
  Streets   -- all street kit instances (road, curb, sidewalk, etc.)
  Buildings -- empty, ready for building kit instances
  Props     -- empty, ready for prop instances
  Lighting  -- empty, ready for scene-specific lights
  Weather   -- rain volume + storm atmosphere (added later in session)

The user is actively editing this scene in Godot. DO NOT
overwrite wholesale -- append or edit surgically.


--------------------------------------------------------------
2. STREET KIT COLLISION
--------------------------------------------------------------
Every street kit piece now has a StaticBody3D + CollisionShape3D
so the character walks at the correct height on each surface.

  SteamtekRoadStraight4_8x2_4m3D.tscn:
    BoxShape3D(2.4, 0.16, 4.8) at y=-0.08
    Provides a thin road surface at the road plane.

  SteamtekRoadIntersection4Way4_8m3D.tscn:
    BoxShape3D(4.8, 0.16, 4.8) at y=-0.08

  SteamtekCurbStraight2_4m3D.tscn:
    BoxShape3D(2.4, 0.04, 0.2) at y=0.16
    Thin 4cm slab sitting on top of the curb mesh (curb top).

  SteamtekSidewalkStraight2_4m3D.tscn:
    BoxShape3D(2.4, 0.04, 1.2) at y=-0.02
    Thin slab. Top face at y=0 local = y=0.18 world (sidewalk plane).

  SteamtekSidewalkCurbRamp2_4m3D.tscn:
    Multiple collision shapes:
    - SidewalkLeftShape / SidewalkRightShape: BoxShape3D(0.5, 0.04, 1.2) at y=-0.02
    - CurbLeftShape / CurbRightShape: BoxShape3D(0.5, 0.04, 0.2) at y=-0.02
    - OpeningWalkwayShape: ConvexPolygonShape3D ramp from road to sidewalk level

All collision bodies have collision_mask = 0 (don't detect other bodies,
only get detected). Character collision_layer = 2, collision_mask = 1.

IMPORTANT: Collision is defined in the kit .tscn files, NOT in the
surface scene. Every instance of a kit piece inherits its collision
automatically.


--------------------------------------------------------------
3. CHARACTER STEP CLIMBING
--------------------------------------------------------------
Problem: CharacterBody3D with move_and_slide() treats any vertical
face (even a 4cm thin slab edge) as a wall. The character could not
walk from road to sidewalk because the 0.18m height difference
registered as a wall collision.

Solution: Step-up teleport system in the character controller.

File: steamtek_humanoid_character_3d.gd
New export: step_height := 0.25

New logic in _physics_process():
  1. Record was_on_floor before moving
  2. Apply gravity / floor stick
  3. Call move_and_slide()
  4. If is_on_wall() AND was_on_floor -> call _try_step_up()

_try_step_up(saved_velocity, delta):
  1. Compute horizontal velocity (strip Y)
  2. If too slow, skip (avoid jitter at zero speed)
  3. Test: can we move up by step_height? (test_move up)
  4. Test: is that position clear to move forward? (test_move forward)
  5. Test: is there floor below the forward position? (test_move down)
  6. If all pass: teleport character up by step_height, set velocity
     to horizontal with slight downward to trigger floor snap

File: Steamtek_HumanoidCharacter3D.tscn
  Added floor_snap_length = 0.3 to the CharacterBody3D node.
  This snaps the character down to the surface after a step-up
  teleport, preventing floating.

CRITICAL: The step climbing + floor_snap_length combo is what makes
height transitions work. Without floor_snap_length, the character
floats after teleporting up. Without step climbing, thin slabs
block movement like walls.

Confirmed working: character walks freely between road (y=0),
curb (y=0.18), and sidewalk (y=0.18) without being blocked.
User said "its working now."


--------------------------------------------------------------
4. F8 QUIT BEHAVIOR
--------------------------------------------------------------
F8 quits the running game process. When launched from the Godot
editor, F8 is also the editor's "Stop Running Scene" shortcut,
so it cleanly stops the debug session.

Implementation:
  steamtek_transition_level_3d.gd (base class):
    _unhandled_input checks KEY_F8 -> get_tree().quit()

  steamtek_apartment.gd (override):
    Calls super._unhandled_input(event) at start so F8 reaches base.

  steamtek_lantern_playable_3d.gd (override):
    Calls super._unhandled_input(event) at start so F8 reaches base.

  steamtek_main_menu.gd:
    Has its own F8 handler (doesn't extend base class).

  scenes/main.gd:
    F8 handler removed (was replaced with pass) -- old scene, not in
    the Live3D pipeline.

NOTE: User now launches the game themselves (F6 on the current scene
in Godot editor) rather than having Claude launch via MCP. Do NOT
auto-launch.


--------------------------------------------------------------
5. WEATHER SYSTEM (RAIN + STORM)
--------------------------------------------------------------
Added rain and storm atmosphere to SteamtekSurfaceBlank3D.tscn
using existing reusable effect scenes.

Scene tree addition:
  Weather (Node3D, script: steamtek_surface_weather_3d.gd)
    RainVolume (instance of SteamtekRainVolume3D.tscn)
    StormAtmosphere (instance of SteamtekStormAtmosphere3D.tscn)

Components:

  SteamtekRainVolume3D.tscn (pre-existing):
    GPUParticles3D "RainStreaks", 720 particles, 0.78s lifetime
    Emission box: 8.5 x 0.35 x 8.5 meters
    Thin billboard quad meshes (0.009 x 0.38), velocity 14-18 m/s
    local_coords = false (particles stay in world space)
    Tuned to the approved "thin, fast, restrained" rain reference.

  SteamtekStormAtmosphere3D.tscn (pre-existing):
    - Procedural rain ambient audio (SteamtekProceduralRainAudio):
      Generates a 4-second filtered-noise loop at 22050 Hz, looping.
    - Procedural thunder audio (SteamtekProceduralThunderAudio):
      Generates a 2.5-second thunder rumble on demand.
    - Lightning flashes: 2 OmniLight3D nodes that flash periodically
      (4-12 second intervals), with 35% double-flash chance.
    - Thunder follows lightning after 0.3-1.8 second delay.

  Instance overrides on the surface scene:
    - Lightning OmniLights repositioned for outdoor: y=12, range=20
      (defaults were interior apartment positions, y=1.8, range=8)
    - ambient_rain_volume_db = -40.0 (default was -24.0)
      ~10% perceived loudness per user request
    - thunder_volume_db = -34.0 (default was -20.0)
      Quieter to match the subdued rain ambiance

  steamtek_surface_weather_3d.gd (NEW file):
    class_name SteamtekSurfaceWeather3D, extends Node3D
    Smoothly follows the player character's XZ position each frame
    so rain stays overhead as the player walks around.
    Finds player via "steamtek_humanoid" group on first process frame.
    Exports: rain_height (10.0), follow_response (6.0).

Existing rain-related files NOT used on this scene (available
for future use):
  - FX001_RainSystem.tscn -- 2D screen-space rain overlay (Node2D)
  - FX002_RainSplash.tscn -- 2D rain splash particles (Node2D)
  - FX003_RainMist.tscn -- 2D mist cloud overlay (Node2D)
  - SteamtekWindowRainOverlay3D.tscn -- shader-based window rain
  These are 2D overlays or window-specific; the 3D particle rain
  is more appropriate for the outdoor isometric camera.


--------------------------------------------------------------
6. LESSONS LEARNED / GOTCHAS
--------------------------------------------------------------
- .tscn format: ALL [sub_resource] blocks must appear before ANY
  [node] blocks. Placing sub_resources after nodes crashes Godot
  on scene load. This bit us on the first collision pass.

- Jolt Physics + ConvexPolygonShape3D ramps: unreliable. Ramps
  that should have been walkable at <45 degrees were rejected.
  Rotated BoxShape3D ramps only worked in one direction (curbs
  get rotated 90 degrees differently). The step climbing approach
  bypassed all of this.

- floor_snap_length is essential for step climbing. Without it,
  after teleporting the character up by step_height, gravity is
  too weak in a single frame (-0.288 m/s with 18.0 gravity) to
  reach the surface. The character floats, fails is_on_floor(),
  and the system breaks. floor_snap_length = 0.3 snaps the
  character down to the nearest surface within 30cm.

- test_move() is the key to safe step climbing. Before teleporting,
  we verify: (a) nothing blocks us at the elevated position,
  (b) there IS floor ahead at the elevated position. Without
  check (b), the character would teleport up into empty air at
  the edge of a sidewalk and fall.

- SteamtekSurfaceBlank3D.tscn is actively edited by the user in
  Godot. Never overwrite wholesale. Append ext_resources and nodes
  carefully, or use Godot MCP tools.


--------------------------------------------------------------
7. FILE MANIFEST
--------------------------------------------------------------
Modified:
  scenes/characters/templates/steamtek_humanoid_character_3d.gd
  scenes/characters/templates/Steamtek_HumanoidCharacter3D.tscn
  scenes/environment/live3d/kits/street/SteamtekRoadStraight4_8x2_4m3D.tscn
  scenes/environment/live3d/kits/street/SteamtekRoadIntersection4Way4_8m3D.tscn
  scenes/environment/live3d/kits/street/SteamtekCurbStraight2_4m3D.tscn
  scenes/environment/live3d/kits/street/SteamtekSidewalkStraight2_4m3D.tscn
  scenes/environment/live3d/kits/street/SteamtekSidewalkCurbRamp2_4m3D.tscn
  scenes/levels/surface_3d/SteamtekSurfaceBlank3D.tscn
  scenes/levels/transition_tests/steamtek_transition_level_3d.gd
  scenes/levels/apartment_3d/steamtek_apartment.gd
  scenes/levels/lantern_3d/steamtek_lantern_playable_3d.gd
  scenes/main.gd

New:
  scenes/effects/live3d/steamtek_surface_weather_3d.gd


--------------------------------------------------------------
8. STILL TO DO
--------------------------------------------------------------
- Building kit instances under the Buildings organizer node
- Props placement under the Props organizer node
- Scene-specific lighting under the Lighting organizer node
- The 2D rain overlays (FX001-003) could be layered on top via
  a CanvasLayer for additional screen-space rain density
- Rain toggling / weather state system (currently always raining)
- Wet surface shader integration (STK_MAT_RainPolishedStreet,
  STK_MAT_WetConcrete already exist as materials)
