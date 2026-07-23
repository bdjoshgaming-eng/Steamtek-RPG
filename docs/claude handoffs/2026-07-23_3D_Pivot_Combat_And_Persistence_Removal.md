STEAMTEK RPG - 2D DELETION, 3D COMBAT/INVENTORY BUILD, PERSISTENCE REMOVAL
=============================================================================
Date: 2026-07-23
Status: COMPLETE and confirmed working in-game
Touches: scenes/ (2D prototype fully deleted), scenes/gameplay/live3d/*,
         scenes/levels/*, scenes/characters/templates/steamtek_humanoid_character_3d.gd,
         project.godot


--------------------------------------------------------------
1. THE 2D PROTOTYPE IS GONE. FOR GOOD.
--------------------------------------------------------------
Josh: "I want the 2d prototype scene gone, obliterated. no trace left.
3d is the way forward." Confirmed "commit first, then delete" before
anything was removed.

Commits:
  31122e5 -- last commit with the 2D prototype + this session's earlier
             ranged-combat-redesign work (melee removal, buttstroke,
             Grit, Charged Shot, aim-fire, telegraphs -- all 2D-only,
             see that commit's message/diff for exact numbers if ever
             worth porting to 3D)
  39846d2 -- "Remove the 2D combat prototype entirely -- 3D is the way
             forward". Deleted: scenes/main.gd, scenes/main.tscn (+
             autosave .tmp files), scenes/player.gd, scenes/enemy.tscn,
             scenes/Quest.gd, scenes/TrainerDialogue.gd,
             scenes/CraftingPanel.gd, scenes/inventory_slot.gd,
             scenes/action_bar_slot.gd, scenes/ability_drag_source.gd,
             scenes/mod_drag_source.gd, scenes/mod_socket_slot.gd,
             scenes/TalentViewer.gd, scenes/CraftingResultPopup.gd,
             scenes/AbilityBook.gd, scenes/CraftingBook.gd,
             scenes/InventoryBook.gd, scenes/SurveyBook.gd,
             scenes/characters/C001_PlayerBody.tscn,
             scenes/effects/surface/FX001_RainSystem.tscn,
             FX002_RainSplash.tscn, FX003_RainMist.tscn,
             scenes/props/surface/P001_Street_Lamp.tscn

SURVIVED (confirmed live 3D dependencies, verified before deletion):
  scenes/GameData.gd, scenes/Combat.gd, scenes/CombatData.gd (autoloads
  -- weapon/item stats, damage formulas, keystone/Grit data)
  scenes/KeystoneViewer.gd (3D HUD's talent panel instantiates this
  directly via a local stub bridge)
  systems/crafting/*.gd (shared crafting infra, used by 3D HUD too)

IMPORTANT for any future session: the entire "PRE-EXISTING HANDOFF"
section of claude_handoff.txt below the 2026-07-22 session describes
this now-deleted main.gd/main.tscn system. Treat it as HISTORICAL
REFERENCE ONLY -- none of that code exists in the working tree anymore.
It's recoverable from commit 31122e5 if a mechanic is ever worth
rebuilding in 3D, but do not assume any of it is live.


--------------------------------------------------------------
2. AUTOLOAD UID-CACHE CRASH -- THE BIG LESSON THIS SESSION
--------------------------------------------------------------
First attempt at global inventory/combat state: added two NEW autoload
singletons (SteamtekPlayerCombatState, SteamtekPlayerInventory) to
project.godot's [autoload] section.

Result: Godot 4.7 editor threw
  "ERROR: Failed to create an autoload, can't load from UID or path:
   uid://bx41u45ujcnb8"
on every launch, even though the scripts, their .uid sidecar files, and
the Autoload Globals tab in Project Settings all looked completely
correct. This is a UID-cache desync bug in the Godot 4.4+ editor's
internal resource_uid mapping -- it can happen when a script file (and
its .uid sidecar) is created by an external tool/editor rather than
through Godot's own "New Script" flow, and the editor's cached uid_cache
doesn't pick up the new mapping. A full "Project -> Reload Current
Project" did NOT fix it. This completely blocked the game from
launching -- "cant start a new game."

FIX, and the standing rule going forward:
  DO NOT register new autoload singletons for shared runtime state.
  Instead extend the already-registered, already-working
  SteamtekLive3DProgressStore autoload with new methods/keys. Zero new
  autoload entries means zero risk of hitting this bug again.

  Concretely: SteamtekLive3DProgressStore gained
    get_global_inventory() / save_global_inventory()
    get_global_combat_state() / save_global_combat_state()
  each just get_progress()/save_progress() under a fixed key
  ("steamtek_global_inventory" / "steamtek_global_combat_state").

If more shared state is ever needed (quest flags that should be truly
global instead of per-scene, party/companion state, whatever) -- extend
this same store the same way. Do not add another autoload.


--------------------------------------------------------------
3. GLOBAL INVENTORY SYSTEM (works in every Live3D scene now)
--------------------------------------------------------------
Two bugs were causing "nothing in inventory" / "I doesn't work"
complaints, both now fixed:

BUG A -- inventory panel only worked in the apartment.
  hud.set_inventory_enabled(...) was only ever called from
  steamtek_apartment.gd, gated behind note_found. Lantern and surface
  scenes never called it at all.
  FIX: base class SteamtekTransitionLevel3D._setup_hud() now calls
  hud.set_inventory_enabled(true) unconditionally, every scene.

BUG B -- items/weapons/cogs/equipped weapon didn't carry between scenes.
  Each scene kept its own local progress/tutorial_state dict for these.
  FIX: base class binds the HUD's progress_ref to
  SteamtekLive3DProgressStore.get_global_inventory() -- a Dictionary,
  and GDScript Dictionaries are reference types, so the HUD and every
  scene script reading hud.progress_ref are looking at the SAME object
  in memory. steamtek_apartment.gd and steamtek_lantern_playable_3d.gd
  were migrated to read/write items/weapons/cogs/equipped-weapon through
  hud.progress_ref, while crate contents / quest flags / note_found stay
  in each scene's own local progress dict (correctly scene-local -- a
  crate shouldn't move between rooms).

BUG C (found right after, subtler) -- inventory WINDOW showed stale/
  empty data on first open in a scene that hadn't just mutated anything.
  It only redrew when a scene script explicitly pushed rebuilt entries
  into it after a mutation (hud.refresh_inventory(...)).
  FIX: added SteamtekLive3DHud._refresh_inventory_display(), which
  rebuilds the window straight from progress_ref -- called from bind()
  and from set_inventory_open(true), so every scene's [I] key always
  shows current state regardless of what that scene's own script does.

CONFIRMED: took items + a weapon from the apartment crate, equipped it,
walked to the surface scene, pressed [I] -- items/weapon/cogs all
showed correctly there too.


--------------------------------------------------------------
4. BASIC 3D RANGED COMBAT (aim-hitscan, confirmed working)
--------------------------------------------------------------
Scope: a single instant-hitscan basic attack against one AI target
archetype. NOT built yet: ground-target/cone telegraphs for Grenade
Launcher/Flame Thrower (every weapon just fires as instant hitscan
right now regardless of its data-driven targeting_mode), Grit's DoT/CC
interaction, Charged Shot, Dodge Roll, buttstroke -- all still 2D-only
design intent, not rebuilt in 3D (see section 1).

Combat health/action state: same safe pattern as the inventory fix.
SteamtekLive3DProgressStore.get_global_combat_state()/
save_global_combat_state() (key "steamtek_global_combat_state"). Base
class _setup_hud() loads/defaults this dict (current_health/max_health/
current_action/max_action, default 500/850) and passes the SAME
Dictionary reference to both character.set_combat_state(state, save_fn)
and hud.bind_combat_state(state) -- mutations either side makes are
visible to both immediately, and hud._process() repaints the bars from
it every frame.

SteamtekHumanoidCharacter3D (scenes/characters/templates/
steamtek_humanoid_character_3d.gd) now owns combat:
  is_alive() / get_health() / get_action() / apply_damage() /
  spend_action() / save_combat_state()
  _regen_combat_state(delta) -- 2%/sec max health, +10/sec action,
  runs every physics frame regardless of player_controlled so it
  continues through dialogue/cutscenes.
  attempt_attack() -- fires on the primary_fire input action (left
  mouse button, added to project.godot's [input] section). Reads the
  equipped weapon from inventory.get("equipped_weapon") (character
  holds the same shared inventory dict as the HUD, via set_inventory()).
  Builds attack_parameters from
  GameData.ITEM_DEFINITIONS[weapon]["weapon_stat_ranges"]["Damage
  Rating"/"Range"][0] -- the LOW end of the range, same convention
  steamtek_inventory_window.gd already uses for its Details panel.
  Raycasts from player position + 1m up, toward the mouse's
  ground-plane intersection point (camera ray -> Plane(Vector3.UP,
  player_y).intersects_ray()), collision mask 16, areas only, then
  calls Combat.compute_player_attack_damage(...) via the hit target's
  receive_player_attack(). Costs 35 action per shot whether it hits or
  not.

Combat is blocked while any HUD panel is open -- base class wires
hud.panel_opened/panel_closed straight to character.combat_blocked =
true/false.

Enemy side (SteamtekTutorialCombatTarget3D.tscn/.gd) already had
receive_player_attack()/roll_enemy_attack()/resistance mitigation
committed from an EARLIER phase (before the 2D deletion) and survived
intact. What was missing and got added back this session:
  - collision_layer 8 -> 16 (own dedicated layer, separate from the
    interactable layer 8 used by crates/doors/notes, so a crate can't
    physically block a raycast shot)
  - actual attack-on-contact: attack_cooldown / attack_contact_distance
    / attack_timer added to _chase_tick(), calling
    player_ref.apply_damage(roll_enemy_attack())
  - the base class now wires every steamtek_tutorial_enemy_3d-group
    node's set_player_reference(character) in _ready() -- the method
    existed on the enemy script already, nothing was ever calling it,
    so its AI _process() no-oped forever.

A "ScrapThief" combat target instance placed in
SteamtekSurfaceBlank3D.tscn under Props for live testing.

CONFIRMED WORKING: fired on the ScrapThief with a Canister Launcher
equipped, floating health label above it dropped, action bar decreased
per shot. Only point of confusion was Josh expecting a ground-target
telegraph circle for the Canister Launcher (a real, data-driven
distinction -- WEAPON_TARGETING_MODES maps "Grenade Launcher" item_class
to "ground_target" -- just not implemented yet). Explained: that's the
natural next slice if combat work continues.


--------------------------------------------------------------
5. PERSISTENCE REMOVED ENTIRELY, PER EXPLICIT REQUEST
--------------------------------------------------------------
After the UID-cache crash (section 2) got tangled up with debugging a
broken save-dependent autoload, and after separately hitting confusion
from stale save data resuming mid-apartment instead of starting fresh,
Josh said: "please delete the persistant game code. Ill just start a
new game every time."

SteamtekLive3DProgressStore (scenes/gameplay/live3d/
steamtek_live3d_progress_store.gd) was stripped of ALL FileAccess/
user:// disk I/O. It is now a pure in-memory Dictionary cache. Public
API is UNCHANGED (get_progress/save_progress/get_global_inventory/
save_global_inventory/get_global_combat_state/save_global_combat_state)
so zero other files needed to change -- this validated the abstraction
boundary was drawn in the right place.

What still works: cross-scene consistency WITHIN one running session
(inventory, equipped weapon, health/action all carry from apartment ->
lantern -> surface), because autoloads survive change_scene_to_file()
on their own -- only the scene tree gets swapped, not the autoload
singletons.

What changed: stopping the game (F8, editor Stop, closing the project)
and pressing Play again now ALWAYS starts a completely clean game.
Nothing survives a process restart, by design.

Also removed: the now-pointless character.save_combat_state() call in
the F8 quit handler (saving to a RAM cache that's about to be freed
does nothing), and deleted the stale user://
steamtek_live3d_progress.json save file from disk since nothing reads
it anymore.

STANDING RULE: do not reintroduce disk-backed save/load without Josh
asking for it again first.


--------------------------------------------------------------
6. FILE MANIFEST
--------------------------------------------------------------
Deleted (2D prototype, commit 39846d2): see section 1's list.

Modified:
  project.godot (autoloads: removed 2 broken singletons, never re-added;
    [input]: added primary_fire, left over buttstroke/dodge_roll from
    the pre-deletion 2D work, now unused but harmless)
  scenes/gameplay/live3d/steamtek_live3d_progress_store.gd (global
    inventory/combat-state keys added, then all disk I/O removed)
  scenes/gameplay/live3d/steamtek_live3d_hud.gd (bind_combat_state,
    _refresh_combat_bars, _refresh_inventory_display, _process bar
    repaint)
  scenes/gameplay/live3d/steamtek_tutorial_combat_target_3d.gd
    (collision_layer 16, attack-on-contact)
  scenes/gameplay/live3d/SteamtekTutorialCombatTarget3D.tscn
    (collision_layer/mask)
  scenes/characters/templates/steamtek_humanoid_character_3d.gd
    (combat state/inventory refs, attempt_attack, aim raycast, regen)
  scenes/levels/transition_tests/steamtek_transition_level_3d.gd
    (base class: combat state + inventory binding, enemy group wiring,
    combat_blocked gating, F8 handler simplified)
  scenes/levels/apartment_3d/steamtek_apartment.gd (migrated to shared
    inventory via hud.progress_ref)
  scenes/levels/lantern_3d/steamtek_lantern_playable_3d.gd (same
    migration for the vendor flow)
  scenes/levels/surface_3d/SteamtekSurfaceBlank3D.tscn (ScrapThief
    combat target instance added under Props)


--------------------------------------------------------------
7. STILL TO DO / NEXT SLICE
--------------------------------------------------------------
- Ground-target telegraph circle for Grenade Launcher, cone telegraph
  for Flame Thrower (WEAPON_TARGETING_MODES data already exists, just
  needs the visual + delayed-resolution logic built)
- Grit's DoT/CC interaction, Charged Shot hold-to-fire, Dodge Roll,
  buttstroke -- all 2D-only design intent from commit 31122e5, not
  rebuilt in 3D
- Enemy death feedback/loot drop is minimal (label goes to 0/max,
  set_active(false)) -- no visible death animation or reward yet
- Only one enemy archetype (ScrapThief) exists in 3D; no variety yet
