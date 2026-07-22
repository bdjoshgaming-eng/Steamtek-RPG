STEAMTEK RPG - COMBAT PHASE 8: ENEMY AI, LAIRS & NOTORIOUS MONSTERS
=====================================================================
Date: 2026-07-21
Status: COMPLETE and tested in-game
Touches: main.gd, CombatData.gd


--------------------------------------------------------------
1. ENEMY AI STATE MACHINE
--------------------------------------------------------------
Enemies are no longer stationary. Each enemy runs a per-frame
AI update via _update_enemy_ai() called from _process(delta).

Three states: idle, chase, leash.

  IDLE:
    - Enemy wanders slowly near its home_position (patrol)
    - Picks random points within patrol_radius, walks at 30% speed
    - Pauses 2-5 seconds at each patrol point
    - If player enters aggro_range -> transition to CHASE
    - Calls _ai_call_for_help() to alert lair-mates

  CHASE:
    - Moves toward player at chase_speed
    - Attacks when within ENEMY_ATTACK_RANGE
    - If player dies -> transition to LEASH
    - If distance to home > leash_range -> transition to LEASH
    - Stagger check: enemies with stagger_until_msec in future skip attacks

  LEASH:
    - Walks back to home_position at 1.5x chase_speed
    - Heals 15% max HP per second while walking back
    - IMMUNE TO DAMAGE while leashing (attack hits + DOT ticks skip)
    - On arrival: full heal, clear all debuffs/DOTs, reset to IDLE

AI constants (defaults, overridable per-enemy in spawn table):
  DEFAULT_AGGRO_RANGE = 300.0
  DEFAULT_CHASE_SPEED = 80.0
  DEFAULT_LEASH_RANGE = 500.0
  DEFAULT_PATROL_RADIUS = 60.0
  LEASH_HEAL_RATE = 0.15

Functions added to main.gd:
  _update_enemy_ai(enemy_id, delta)
  _ai_try_attack(_enemy_id, e, n)
  _ai_leash_tick(_enemy_id, e, n, body, home, dist_to_home, delta)
  _ai_patrol_tick(_enemy_id, _e, n, body, home, dist_to_home, delta)
  _ai_pick_patrol_target(n, home)
  _ai_call_for_help(aggroed_id)

Fields added to generate_enemy() in CombatData.gd:
  ai_state ("idle"), ai_target (""), is_nm (false)

Fields added to enemy_nodes dict:
  home_position, aggro_range, chase_speed, leash_range,
  patrol_radius, lair_id, spawn_data, nm_def

Per-enemy overrides in ENEMY_SPAWN_TABLE:
  aggro_range, chase_speed, leash_range (all three existing enemies
  have custom values tuned to their archetype)


--------------------------------------------------------------
2. LAIR SYSTEM (SWG-style)
--------------------------------------------------------------
Lairs are groups of enemies that spawn together and share
linked aggro. Defined in LAIR_SPAWN_TABLE (main.gd).

Current lairs:
  rust_outpost: 3x Rust Scrapper (CL2) + 1x Rust Foreman (CL4)
    Center: (250, 600), Radius: 100
  blackline_checkpoint: 2x Blackline Sentry (CL8) + 1x Blackline Lieutenant (CL10)
    Center: (1400, 400), Radius: 90

Lair behavior:
  - Members spawn spread evenly around the lair center
  - All share the same lair_id for linked aggro
  - When one member is aggroed, _ai_call_for_help() alerts
    lair-mates within 1.5x their aggro_range
  - Individual lair members DO NOT respawn when killed
  - When ALL members are dead, the lair is "cleared"
  - "Cleared!" message displayed to player

Lair spawning is handled by _spawn_lair_enemies(), called from
_build_enemy_node_registry(). Enemy IDs are generated as
"{lair_id}_{index}" (e.g., "rust_outpost_0", "rust_outpost_1").

Combat data entries for lair members are created in _ready()
using CombatData.generate_enemy() before the node registry
is built.

_spawn_enemy() now accepts an optional spawn_override dict
so lair members can pass their spawn data directly instead
of reading from ENEMY_SPAWN_TABLE.


--------------------------------------------------------------
3. NOTORIOUS MONSTER LOTTERY (FFXI-style)
--------------------------------------------------------------
When a lair is fully cleared, after a 3.5-second delay, the
NM lottery rolls. If successful, the NM spawns at the lair.
If not, nothing happens -- the lair stays dead.

NM definitions live at the lair level in LAIR_SPAWN_TABLE,
not on individual members:

  "nm": {
      "display_name": "Rusty Pete",
      "cl": 6,
      "archetype": "Brawler",
      "faction": "Rust Syndicate",
      "tint": Color(1.0, 0.3, 0.1, 1),
      "kill_xp": 300,
      "loot_key": "NM_RustyPete",
      "spawn_chance": 0.05,
      "replaces_index": 0,
  }

replaces_index determines which lair member slot the NM
replaces (always member 0 currently).

Current NMs:
  Rusty Pete (CL6 Brawler) -- from Rust Outpost, 5% chance
  Sergeant Volkov (CL14 Commander) -- from Blackline Checkpoint, 4% chance
  Ironjaw (CL5 Brawler) -- from solo Scrap Thief, 5% chance

NM mechanics:
  - _check_lair_cleared() detects full clear, starts 3.5s timer
  - _on_lair_nm_roll() fires after delay, checks spawn_chance
  - _promote_to_nm() overrides identity (name, cl, archetype),
    re-derives stats, updates visual tint and name label
  - "A Notorious Monster has appeared: {name}!" announcement
  - "NOTORIOUS MONSTER {name} has been slain!" on defeat
  - nm_active_by_type dict prevents duplicate NMs of same lair_type
  - When NM is killed, nm_active_by_type is cleared for that type

Solo enemies (not in lairs) can also have NMs via the "nm" key
in ENEMY_SPAWN_TABLE. Solo NM lottery rolls on individual
respawn via _on_enemy_respawn().

Shared NM pool: multiple lairs with the same lair_type value
share the nm_active_by_type flag, so only one NM of a given
type can exist at a time.


--------------------------------------------------------------
4. OTHER FIXES
--------------------------------------------------------------
  - Player respawn now resets action points (was only resetting HP)
  - Duplicate "Mod Sockets" display removed from inventory stats
    (socket area UI already shows it)
  - Debug key changed from F9 to F3 (F9 conflicts with Godot
    debugger pause)
  - F8 key added as in-game quit shortcut
  - Debug weapon (F3) upgraded to masterwork quality for testing
  - _get_enemy_name() now reads from enemies dict first (supports
    lair enemies whose names aren't in ENEMY_SPAWN_TABLE)


--------------------------------------------------------------
5. FILES CHANGED
--------------------------------------------------------------
  scenes/main.gd:
    - ENEMY_SPAWN_TABLE: added per-enemy AI overrides (aggro_range,
      chase_speed, leash_range), NM def on "dummy"
    - LAIR_SPAWN_TABLE: new constant with two lair definitions
    - AI constants and functions (section 1 above)
    - _spawn_enemy(): accepts spawn_override parameter
    - _spawn_lair_enemies(): spawns lair member groups
    - _build_enemy_node_registry(): now calls _spawn_lair_enemies()
    - _ready(): creates lair enemy combat data entries
    - _defeat_enemy(): lair members skip individual respawn,
      check for lair clear instead; NM kill clears active flag
    - _reset_enemy(): extracted shared reset logic
    - _on_enemy_respawn(): solo enemy respawn + solo NM lottery
    - _check_lair_cleared(): detects full lair clear
    - _on_lair_nm_roll(): delayed NM lottery after lair clear
    - _promote_to_nm(): identity swap + stat re-derivation
    - _on_player_respawn(): now resets player_current_action
    - _input(): F3 debug grant, F8 quit
    - Leash immunity in attack loop and DOT tick loop
    - Patrol pause timer wired up

  scenes/CombatData.gd:
    - generate_enemy(): added ai_state, ai_target, is_nm fields
    - (burn/poison/stagger fields added in prior session)


--------------------------------------------------------------
6. STILL TO DO
--------------------------------------------------------------
  - Add more lair instances of each type across the map (currently
    one of each -- with no respawn, each lair is one NM roll)
  - NM-specific loot tables (NM_RustyPete, NM_Volkov, NM_Ironjaw
    loot_keys exist but no special loot defined yet)
  - Lair visual marker (campfire, crate pile, etc.) so players can
    spot lairs before aggroing
  - Enemy ranged attacks (currently all melee)
  - Enemy ability usage (abilities exist in data but enemies don't
    use them)
  - Group/pack pathing (enemies clip through each other during chase)
  - Multiple floors / zones with level-appropriate lair placement
  - Balance pass: NM spawn chances, respawn timers, enemy stat tuning
  - Restore DUMPSTER_RESPAWN_TIME from 5.0 to 45.0 before balance pass
