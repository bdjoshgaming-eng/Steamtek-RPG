STEAMTEK RPG - LIVE3D COMBAT DEEP DIVE
=============================================================
Date: 2026-07-23 (same day as, and a direct continuation of, the
      "3D Pivot, Combat/Inventory/Persistence" session -- read
      2026-07-23_3D_Pivot_Combat_And_Persistence_Removal.md first
      for the ground truth this session builds on)
Status: everything below is COMPLETE and confirmed working in-game
        by Josh, except where explicitly flagged otherwise
Touches: scenes/characters/templates/steamtek_humanoid_character_3d.gd
         (by far the most-changed file this session), scenes/GameData.gd,
         scenes/gameplay/live3d/*, scenes/effects/live3d/*,
         scenes/levels/apartment_3d/steamtek_apartment.gd,
         systems/crafting/crafting_service.gd

This was a single very long session that closed out the entire "ranged
combat redesign" cluster from the original 2D handoff, then kept going
into crafting Phase 6 Batch 2, crafting Phase 8, and a full weapon
resource-economy rework (Speed/Ammo/Reload/stamina). Organized below by
topic in roughly the order it happened, since later items sometimes
revise earlier ones in this same session (most notably the grenade
mechanic, which went through several real iterations before landing).


--------------------------------------------------------------
1. GRENADE LAUNCHER -- FINAL STATE (revised several times, read to the
   end of this section, not just the top)
--------------------------------------------------------------
Click once to drop a BLUE ring telegraph (color convention: player
damage = blue, player heal = green, enemy damage = red, enemy CC =
yellow -- this is now a hard standing rule, see section 9). Ring is
clamped to the weapon's Range stat. Click again to confirm.

TRAJECTORY: real ballistic simulation in
scenes/effects/live3d/steamtek_grenade_projectile_3d.gd -- launch
velocity is SOLVED (not guessed) from throw distance/height via the
standard height-adjusted projectile range equation, then gravity +
bounce restitution/friction are integrated frame by frame. Current
tuning: GRENADE_GRAVITY=5.5, GRENADE_LAUNCH_ANGLE_DEGREES=20 (flat, not
a mortar lob), GRENADE_BOUNCE_RESTITUTION=0.45, GRENADE_BOUNCE_FRICTION
=0.55, GRENADE_MAX_BOUNCES=3 (bounces energetically, Junkrat-style --
this is safe now, see DAMAGE below for why). All in
steamtek_humanoid_character_3d.gd.

DAMAGE MODEL -- this is the important part, and it changed TWICE this
session:
  - v1 (broken): AoE splash check against the grenade's FINAL RESTING
    position only. Reliability was terrible (~1/20 hits) because a
    chasing enemy moves during the ~0.5-1.5s flight and the splash
    radius (deliberately shrunk small per earlier Josh requests) no
    longer lined up with where the target actually was by landing time.
  - v2 (current, correct): DIRECT HIT ON CONTACT. The projectile checks
    its distance to every live member of ENEMY_GROUP EVERY PHYSICS
    FRAME of its entire flight (both the initial arc and every bounce),
    and detonates the instant it comes within GRENADE_CONTACT_RADIUS
    (0.5m) of one. This is what actually fixed reliability -- continuous
    checking instead of one static endpoint check. A grenade that never
    touches anyone still lands/settles normally and calls back with a
    null hit_enemy (clean miss, VFX plays, no damage).
  - Splash radius (GameData.splash_radius_for_class /
    WEAPON_SPLASH_RADIUS) is EXPLICITLY NOT what grenades use for damage
    anymore -- Josh's own words: "splash radius is for rocket launchers,
    arc cannons, etc." It's kept only for sizing the ground-target
    RING's visual size. The direct-hit function (_resolve_grenade_impact)
    ALSO applies a secondary splash layer on top: whoever was hit takes
    100% damage, anyone else within GRENADE_SPLASH_RADIUS (2.0m, a
    separate constant from the 0.5m contact radius) of the actual
    detonation point takes 50% (GRENADE_SPLASH_DAMAGE_FRACTION). The
    old AoE-only function (_resolve_aoe_damage) still exists UNCHANGED
    and is used by the ground_target "else" branch -- i.e. it's reserved
    for future instant-detonate blast weapons (Rocket Launcher/Arc
    Cannon) that won't have a travel-time problem to begin with.

TRIED AND EXPLICITLY REVERTED (do not reintroduce without asking):
  - Automatic 3-round burst per click. Josh: "I do not like the 3 in a
    row. Id rather a steady pace of them." Fully removed
    (_launch_grenade_burst/_fire_grenade_burst_shot deleted). Confirm
    now fires exactly one grenade per click again, paced by the normal
    weapon-Speed cooldown + magazine system (section 3).
  - Accuracy-based random scatter around the reticle (better Accuracy =
    tighter grouping). Josh: "lets reverse the spread pattern and just
    rely on aim for it. That was a bad idea." Fully removed
    (_apply_accuracy_scatter deleted). Grenades land exactly where
    aimed, full stop.

Research that informed the final tuning (session included live web
research on request): Overwatch Junkrat (deliberately slow-flying
grenades, 5-round clip, ~0.6s/shot, 1.5s reload), TF2 Demoman (4-grenade
clip, fires as fast as clicked, ~1216 units/sec, 2.3s fuse), Global
Agenda's Tremor/Aftershock Launchers (burst-capable, contact or timed
detonation), Borderlands Dahl (burst-fire grenade launchers as a real
established archetype, baseline mag ~4). These numbers are why the
final GameData stat rebalance (section 3) landed where it did.


--------------------------------------------------------------
2. EXPLOSION VFX (still live, unchanged since built)
--------------------------------------------------------------
scenes/effects/live3d/SteamtekGrenadeExplosion3D.tscn /
steamtek_grenade_explosion_3d.gd -- fire burst (26 particles, sphere
emission, 0.4s life) + smoke puff (10 particles, 1.3s life) + a bright
OmniLight3D flash that decays over 0.25s. Self-frees ~1.6s after
spawning. Scales to whatever radius is passed to play(radius) -- called
from _resolve_grenade_impact with GRENADE_SPLASH_RADIUS (2.0m) so what
you see matches the actual splash extent.


--------------------------------------------------------------
3. WEAPON SPEED / MAGAZINE / RELOAD / STAMINA -- THE BIG REWORK
--------------------------------------------------------------
This is the largest structural change of the session. Three
previously-100%-decorative GameData stats (Speed, Ammo Capacity, Reload
Speed) are now real, plus Action was repurposed entirely.

WEAPON SPEED -> REAL ATTACK COOLDOWN. Previously every weapon fired as
fast as you could click regardless of its Speed stat (only shown in the
inventory Details panel's DPS line). Now `_attack_cooldown_timer`
(steamtek_humanoid_character_3d.gd) gates hitscan tap-fire, Charged
Shot (both the charge-start and the shot it releases), and
ground_target confirm (grenade throw). Speed = seconds between shots,
lower is faster, same convention the DPS calc already assumed. Flame
Thrower is DELIBERATELY EXCLUDED -- its tick rate is its own
already-tuned system (FLAME_TICK_INTERVAL). So are Buttstroke/Dodge
Roll (fixed-cooldown abilities, not tied to the equipped weapon).
_get_weapon_attack_cooldown() reads the EFFECTIVE (mod-adjusted) Speed
stat, so Speed-affecting mods (Spring Mechanism/Valve Assembly from
Phase 6) now visibly change fire rate, not just a cosmetic DPS number.

MAGAZINE + RELOAD (Ammo Capacity, Reload Speed). Session-local only
(not persisted, matches the project's no-save rule), tracked per weapon
name in `_weapon_ammo: Dictionary`. Auto-reload on empty: pulling the
trigger with 0 rounds starts a reload (_start_weapon_reload) instead of
firing, blocking further fire until _reload_timer (driven by the
effective Reload Speed stat) elapses, then refills to the effective
Ammo Capacity. Applies to every weapon firing through
attempt_attack/_fire_hitscan/_confirm_ground_target -- again, NOT Flame
Thrower (heat already plays this role for it).

GRENADE LAUNCHER STAT REBALANCE (GameData.gd) -- the authored Ammo
Capacity for Canister Launcher was [1, 4] and Reload Speed was
[5.0, 3.0]s. At BASE quality (index [0], the convention every stat read
in this codebase already uses) that's a 1-round mag with a 5s reload --
unplayable once the numbers became real instead of decorative (they'd
never been played against before this session). Researched real games
(section 1) and rebalanced BOTH Grenade Launcher items as one coherent
package:
  Canister Launcher:     Speed [3.5,2.2]->[0.8,0.5]
                         Ammo Capacity [1,4]->[4,8]
                         Reload Speed [5.0,3.0]->[2.0,1.2]
  Pressure-Fed Launcher: Speed [3.0,1.8]->[1.0,0.65]
                         Ammo Capacity [2,5]->[5,10]
                         Reload Speed [4.5,2.8]->[2.5,1.5]
Every OTHER weapon's Ammo Capacity/Reload Speed (Pistol, Assault Rifle,
Sniper Rifle, Shotgun, Flame Thrower) was left untouched -- those
ranges (8-35 rounds) were already sane and hadn't been flagged as a
problem.

CHARGED SHOT'S COST MOVED TO AMMO. It used to spend extra Action
(GameData.ability_definitions["Charged Shot"]["action_cost"], 40). Now
a FULL charge burns CHARGED_SHOT_FULL_AMMO_COST (2 rounds) instead of
the normal 1; a tap/partial charge still costs 1. The old action_cost
field in GameData is now unread/vestigial for this ability.

ACTION IS NOW A STAMINA POOL, PERIOD. Direct instruction from Josh:
"Action is going to become a stamina bar for running, dodge rolling,
etc. It wont have anything to do with being able to use abilities. We
will tie that to resource systems (ammo, heat, etc)."
  - Removed: ATTACK_ACTION_COST constant, and every spend_action() call
    in the weapon-fire paths (_fire_hitscan, _confirm_ground_target).
    Weapons/abilities NEVER touch Action anymore -- their resource is
    ammo (hitscan/grenade), heat (Flame Thrower), or a flat ability
    cooldown (Buttstroke).
  - Added: sprinting (Shift+move) drains Action continuously at
    SPRINT_STAMINA_DRAIN_PER_SECOND (100/sec) and is hard-gated --
    `wants_to_run` requires get_action() > 0, so you physically cannot
    sprint at 0 stamina, it silently falls back to walk speed.
  - Added: Dodge Roll costs a flat DODGE_STAMINA_COST (150) on top of
    its existing 2s cooldown -- both gates apply, whichever is stricter
    blocks the roll.
  - Regen bumped 10/sec -> 60/sec in _regen_combat_state. The old rate
    was tuned for the abandoned action-per-shot economy (a slow trickle
    against 35-per-shot costs) and would have taken over a minute to
    refill from empty against the new stamina drain rates.
  - ALL of the above numbers (150 dodge, 100/sec sprint drain, 60/sec
    regen) are explicitly flagged as placeholder-but-reasoned against
    the existing ~850 max_action pool -- nobody has actually played
    this yet, a real balance pass is still needed.

KNOWN GAP: no on-screen ammo counter or reload indicator exists yet.
You feel it (can't fire, brief pause, then it works) but there's no
number/bar shown. Same for stamina -- the bar exists (relabeled
semantically, not visually -- see below) but nothing calls out "you're
out of stamina" beyond just not being able to sprint/dodge.
Flag if/when Josh wants that UI built.

NOTE: the HUD's action_bar Control node/variable names were NOT renamed
to "stamina" anywhere (steamtek_live3d_hud.gd, combat_state dict keys
current_action/max_action, get_action()/get_max_action()/spend_action()
method names) -- only the BEHAVIOR changed. Renaming would touch the
HUD, the base transition script's combat_state defaults, and is a pure
cosmetic/organizational task with no functional benefit, so it was
deliberately left alone. If a future session wants to rename for
clarity, grep for "current_action"/"max_action"/"_action" across
scenes/gameplay/live3d/steamtek_live3d_hud.gd and
scenes/levels/transition_tests/steamtek_transition_level_3d.gd first.


--------------------------------------------------------------
4. FLAME THROWER (hold-to-channel, unchanged since built)
--------------------------------------------------------------
scenes/characters/templates/steamtek_humanoid_character_3d.gd
_process_flame_channel() and friends. Hold primary_fire while a Flame
Thrower is equipped: a BLUE cone telegraph (SteamtekConeTelegraph3D,
rebuilt every frame via a runtime-generated wedge mesh so it always
matches the live aim direction) follows your mouse continuously, damage
ticks every FLAME_TICK_INTERVAL (0.15s) at FLAME_TICK_DAMAGE_FRACTION
(0.4) of the weapon's Damage Rating per tick. Heat builds at
FLAME_HEAT_PER_SECOND (8/sec, ~12.5s of continuous fire to overheat --
deliberately slow, the cheapest resource drain in the kit by design)
and regenerates at FLAME_HEAT_REGEN_PER_SECOND (12/sec) when not
firing. Overheating force-stops the channel and locks it out for
FLAME_OVERHEAT_LOCKOUT_SECONDS (1.5s).

HUD gained a third bar (HeatBar, steamtek_live3d_hud.gd) below
Health/Action -- hidden by default, only visible when
_is_flame_thrower_equipped() is true, checked every frame against
progress_ref["equipped_weapon"]'s item_class.

The apartment's starting crate now includes an Oil Burner (Flame
Thrower item) alongside Rusty Pistol/Canister Launcher specifically so
this is testable -- see steamtek_apartment.gd's _open_starter_storage().


--------------------------------------------------------------
5. GRIT'S DOT/CC INTERACTION (first real consumer of previously-dead
   Combat.gd functions)
--------------------------------------------------------------
Combat.gd's grit_dot_reduction()/grit_cc_duration_mult() existed since
an earlier session but had NOTHING to resist -- no enemy DoT/CC ability
existed anywhere in the 3D pipeline. Fixed:
  - GameData.gd gained total_purchased_stat(stat_name) -- a generic
    helper that sums the "amount" of every PURCHASED keystone node
    across every profession/keystone whose "stat" field matches (e.g.
    "Grit"). Currently only the Auxiliary keystone's 3 Grit nodes (5
    each, 15 max) feed this, but it's generic for future nodes.
  - steamtek_humanoid_character_3d.gd gained apply_dot_effect()/
    apply_cc_slow(), which compute Grit mitigation at the MOMENT the
    effect lands (not per-tick), then tick/countdown every physics
    frame via _process_status_effects(). The slow multiplies directly
    into the movement speed calc.
  - ScrapThief (steamtek_tutorial_combat_target_3d.gd) gained a second
    attack, "Corrosive Grasp": an alternate contact hit on its OWN
    8s cooldown (separate from the normal attack_cooldown), applying a
    Grit-mitigated DoT (4 ticks over 4s, ~1.2x normal hit total) + a 3s
    slow (50% speed) instead of a flat hit.
  - Dodge Roll's i-frames (is_invulnerable) fully block apply_damage/
    apply_dot_effect/apply_cc_slow -- a well-timed roll dodges the
    Corrosive Grasp DoT+slow entirely, not just the initial hit.

NO VISUAL TELEGRAPH exists for this enemy special yet -- per the color
convention (section 9) it would be red (damage) or yellow (CC) if/when
built.


--------------------------------------------------------------
6. CHARGED SHOT, BUTTSTROKE, DODGE ROLL (all confirmed working)
--------------------------------------------------------------
CHARGED SHOT -- aim_hitscan weapons only (Pistol/Assault Rifle/Sniper
Rifle/Shotgun; Grenade Launcher and Flame Thrower have their own hold
mechanics already). Hold primary_fire: tap-release fires at base
multiplier (1.0x), holding past charge_partial_time (1.0s) steps to
1.75x, past charge_full_time (2.0s) to 2.5x
(GameData.ability_definitions["Charged Shot"]). Cost is now ammo-based,
see section 3.

BUTTSTROKE -- universal melee "get off me" disengage, bound to V
(project.godot's existing "buttstroke" action, left over from the
pre-2D-deletion work, no new binding needed). Always available
regardless of equipped weapon. 4s cooldown, hits everything within
1.2m: 5 Kinetic damage (deliberately weak, it's a stagger tool not
DPS), 1.5s stagger (freezes enemy AI entirely), 1m knockback. Numbers
match the archived 2D design (commit 31122e5) exactly.

DODGE ROLL -- Space (project.godot's existing "dodge_roll" action, same
leftover-binding situation as Buttstroke). Dashes in current movement
direction, or backs away from the camera if standing still. 0.3s
duration at 11 m/s, 2s cooldown, now ALSO gated by 150 stamina (section
3). Full i-frames during the dash (apply_damage/apply_dot_effect/
apply_cc_slow all early-out). No dedicated animation yet -- pure
velocity override on the existing capsule, works fine without one; a
future dodge animation just needs to play alongside the existing
override, not replace any logic.


--------------------------------------------------------------
7. PHASE 6 BATCH 2 -- MODS ACTUALLY AFFECT COMBAT NOW
--------------------------------------------------------------
Batch 1 (an earlier session) built the mod DATA (8 weapon mods, 6 Core/
damage-type mods, 5 grades) and validation-only functions
(mod_install_problems, mod_stat_deltas) but nothing consumed any of it.
This session built the missing half:

systems/crafting/crafting_service.gd gained:
  - apply_mod_installation(item, mod) / remove_mod_installation(item,
    mod) -- the actual socket mutation, previously only validated.
  - compute_final_weapon_stats(base_stat_ranges, installed_mods) --
    combines base [0]-index stats with mod_stat_deltas(), the missing
    link nothing previously consumed.
  - resolve_damage_type(installed_mods) -- installed Core mod's
    damage_type, else Kinetic.

steamtek_humanoid_character_3d.gd: EVERY combat stat read (all 5
call sites: hitscan fire, Charged Shot, grenade range/damage, flame
cone length/tick damage) now routes through _get_effective_weapon_
stats()/_get_weapon_damage_type() instead of raw GameData [0] reads.
An un-modded weapon (the common case) behaves identically to before --
purely additive.

GRANTING MODS: the HUD's crafting panel gained a "Mods" section listing
all 14 mod definitions, grantable for a flat 40 Cogs (MOD_GRANT_COGS_
COST) via CraftingService.create_mod(). KNOWN SCOPE GAP, called out
explicitly at build time: the 8 weapon mods have no blueprint/material
requirement anywhere in the data model (only Core mods do, via
bp_core_mod), so this is a placeholder Cogs-shop, not a real recipe.
Josh has NOT asked for the real recipe version yet.

INSTALL/REMOVE UI: the inventory window's Details panel, when a weapon
is selected, shows its sockets (filled ones with Remove buttons) and
owned uninstalled mods (with Install buttons). A weapon gets a LAZILY
CREATED crafted-instance wrapper (flat DEFAULT_WEAPON_SOCKET_COUNT=3
sockets, no experimentation/quality pass) the first time a mod is
installed on it -- sidesteps needing to route through the full
blueprint/experimentation pipeline just to host mods. This lazy
instance is also what Phase 8's durability (section 8) hangs off of.

A real bug was caught during the build's own audit: an @onready node
path pointed one level too shallow (OwnedModsList was nested inside a
ScrollContainer, the path didn't include it) -- would have crashed on
first inventory open. Caught and fixed before Josh ever saw it, by
re-verifying every path against the actual scene tree as a final step.
LESSON reinforced: always re-verify @onready paths against the .tscn
after any manual node restructuring, don't just trust what you meant to
type.

LAYOUT BUG (found by Josh via screenshot, fixed): the Details panel's
Stats Label was a FIXED-HEIGHT plain Label -- once a weapon had enough
stat lines (6 base stats + Damage Type + DPS), text overflowed past its
box into the Sockets section below with no clipping. Same root cause as
several earlier fixed-Panel-vs-content-length bugs this project has
hit. FIXED by converting the whole Details content area (ItemName +
Stats + ModsPanel) into a ScrollContainer > VBoxContainer instead of
absolutely-positioned Labels -- this class of bug cannot recur here
regardless of how many stat lines/mods a future weapon has, since the
container reflows automatically instead of needing hand-tuned pixel
offsets.


--------------------------------------------------------------
8. PHASE 8 -- REPAIR / DISMANTLE / REBUILD
--------------------------------------------------------------
current_durability/maximum_durability existed on CraftedItemInstance
since Phase 1 but nothing ever drained OR restored them before this
session -- completely inert.

DURABILITY DRAIN (steamtek_humanoid_character_3d.gd): every hitscan
shot, grenade/AoE detonation, and flame tick costs durability
(DURABILITY_DRAIN_PER_SHOT=2.0, DURABILITY_DRAIN_PER_FLAME_TICK=0.3),
scaled by (1 + mod_instability_total(installed_mods)) -- a heavily-
modded weapon wears out faster, finally giving Phase 6's
instability_cost field a real consequence. ONLY weapons with a crafted
instance track durability at all (see section 7's "lazy instance"
note) -- a plain starter weapon is indestructible. At 0 durability a
weapon is BROKEN and refuses to fire (checked in attempt_attack and
the flame channel's wants_to_fire) until repaired/rebuilt.

CraftingService.gd gained drain_durability(), is_broken(), repair_item
(item, amount), rebuild_item(item) (full reset: durability to max AND
strips all installed mods back to loose, returns their ids), and
dismantle_refund_fraction(item) (current/max durability ratio, the
basis for a Cogs refund).

UI (inventory Details panel, only visible once a weapon has a crafted
instance): a Durability: X/Y readout (shows "(BROKEN)" at 0) plus three
buttons --
  - Repair: restores durability only, costs 1 Cog per point missing.
  - Rebuild: full durability reset + strips all mods back to owned
    (not destroyed), flat 60 Cogs.
  - Dismantle: destroys the weapon entirely, unequips it if equipped,
    returns installed mods to owned, refunds Cogs scaled by remaining
    durability fraction (up to 50 at full health, ~0 near-broken).
All three emit a new inventory_changed signal (steamtek_inventory_
window.gd) that the HUD listens for to refresh the outer grid + Cogs
label -- previously only slot_double_clicked propagated upward, so
dismantle in particular would have left a stale grid entry for a
weapon that no longer exists.


--------------------------------------------------------------
9. UNIVERSAL WEAPON-EQUIP FIX + TELEGRAPH COLOR CONVENTION
--------------------------------------------------------------
BUG FOUND AND FIXED: double-clicking a weapon in the inventory only
equipped it in the APARTMENT scene -- steamtek_apartment.gd's override
of _on_inventory_slot_double_clicked fully replaced the handler with
apartment-only logic (door-unlock check + toast message), and the BASE
class's version (steamtek_transition_level_3d.gd) was an empty `pass`.
Neither the lantern nor the surface scene could equip anything.

FIX: moved the universal part (set equipped_weapon, save, refresh the
inventory window) into the BASE class's handler so every scene gets it
for free. The apartment's override now calls `super.
_on_inventory_slot_double_clicked(key)` for that shared part, then
layers ONLY its genuinely tutorial-specific extras on top (door-unlock
gate check, objective text update, "Time to head out" toast). Deleted
the now-fully-redundant _equip_starter_weapon() helper it used to route
through.

STANDING COLOR RULE (memory: feedback_telegraph_color_convention.md):
  Player character telegraphs: BLUE for damage, GREEN for healing.
  Enemy/NPC telegraphs:        RED for damage, YELLOW for CC/debuffs.
Set explicitly after Josh referenced a WoW-style RED cone image for
SHAPE inspiration only -- the color was not meant to carry over, since
red is reserved for enemy telegraphs. Both the Grenade Launcher ring
and the Flame Thrower cone are blue, correctly, per this rule. Apply
this automatically to any future telegraph (player or enemy) regardless
of what reference art is used for shape/animation.


--------------------------------------------------------------
10. PLAYER CHAT/THOUGHT BUBBLES -- SEPARATED FROM QUEST DIALOGUE
--------------------------------------------------------------
Direct request: "The quest item dialogue should be separate from my
players chat box / dialogue. I want the player character to have a
chat bubble by their head like world of warcraft."

New scenes/gameplay/live3d/SteamtekPlayerChatBubble3D.tscn +
steamtek_player_chat_bubble_3d.gd -- owned by the character itself
(instantiated in steamtek_humanoid_character_3d.gd's _ready(),
positioned CHAT_BUBBLE_HEIGHT above the origin), exposing character.
say()/say_sequence() (SPEECH, pointed tail) and character.think()/
think_sequence() (THOUGHT, three trailing dots instead of a tail --
comic-strip convention, added after Josh asked for monologues to read
as thinking vs. talking). Styled FFXIV-reference: cream/white
background, dark text, thin border, NOT the WoW-style dark/colored
bubble it started as -- Josh sent a reference screenshot mid-session
and the style was rebuilt to match. Advances on the interact key (E),
NOT a timer -- explicit choice ("Click/key to advance"), true WoW-style
auto-fade was considered and rejected.

Panel is a PanelContainer (auto-sizes to wrapped text) with the tail/
dot-trail repositioned every frame to track the panel's current size --
same fixed-size-vs-content-length bug class as section 7's Details
panel, avoided from the start here since it was built after that
lesson landed.

SteamtekDialogueBox (the modal) is now reserved ONLY for actual quest
item text -- reading the apartment note's literal written words. The
player's own reaction to reading it ("An hour ago, in this? That's not
like them...") was previously blended into the SAME modal under the
same "Note" speaker; it's now a separate think_sequence() call, wired
via a new on_complete Callable parameter added to steamtek_apartment.gd
's _show_dialogue_sequence()/_advance_dialogue() so the thought bubble
plays automatically once the modal closes.

Currently apartment-only wiring (the only scene with any dialogue at
all), but say()/say_sequence()/think()/think_sequence() live on the
reusable character script, so the lantern scene or any future NPC
conversation can use the same bubble for free.


--------------------------------------------------------------
11. WEATHER TOGGLE (F4 debug key)
--------------------------------------------------------------
scenes/effects/live3d/steamtek_surface_weather_3d.gd gained
set_weather_enabled(bool), toggled by F4 (raw physical-keycode check in
_unhandled_input, same convention as the existing F8 quit handler --
not a named InputMap action since it's a dev convenience, not
gameplay). Stops/resumes rain particle emission AND
steamtek_storm_atmosphere_3d.gd's lightning cycle + rain/thunder audio
(new set_enabled(bool) method there). SteamtekSurfaceBlank3D.tscn
itself was NOT touched -- both changes live entirely in the two reusable
effect scripts, respecting the "never overwrite Josh's canvas scene"
rule.


--------------------------------------------------------------
12. RESEARCH NOTE ON STEAMTEK ASSEMBLY SYSTEM (Josh chose to defer,
    not build -- recorded here so it isn't re-investigated from
    scratch)
--------------------------------------------------------------
Investigated whether to start the Steamtek Assembly System (rare-item
path, STEAMTEK_ASSEMBLY_SYSTEM.md). FOUND: its entire socket-ceiling
and mod-grade curve design is keyed on "floor depth" (1-60,
Survivors/Expansion/Builders eras) from the OLD 2D 60-floor procedural
dungeon crawler. Confirmed via grep that NOTHING in the live scenes/
tree references floor/depth/campaign generation at all --
crafting_resource_generator.gd's generate_campaign() still exists in
the file but is never called from anywhere in scenes/. The Live3D game
has no notion of depth/zones/floors whatsoever, just a handful of
hand-built named scenes. Josh's call: "we can wait on steamtek assembly
stuff til later" -- explicitly ON HOLD until a real zone/difficulty/
depth concept exists in the 3D game to hang the curves on. Do not
build Assembly System mechanics against floor numbers; there's nothing
there.

Also on hold, per earlier explicit instruction: crafting Phase 7
(the 15-node pick-4 crafting keystone) -- the keystone system itself
is expected to be reworked, don't build against the current shape.


--------------------------------------------------------------
13. FILE MANIFEST (this session, on top of what 2026-07-23_3D_Pivot_
    Combat_And_Persistence_Removal.md already lists)
--------------------------------------------------------------
New:
  scenes/effects/live3d/SteamtekGrenadeExplosion3D.tscn +
    steamtek_grenade_explosion_3d.gd
  scenes/effects/live3d/SteamtekGrenadeProjectile3D.tscn +
    steamtek_grenade_projectile_3d.gd (heavily rewritten twice --
    fixed-hop -> real physics -> collision-detection damage model)
  scenes/effects/live3d/SteamtekGroundTelegraph3D.tscn +
    steamtek_ground_telegraph_3d.gd
  scenes/effects/live3d/SteamtekConeTelegraph3D.tscn +
    steamtek_cone_telegraph_3d.gd
  scenes/gameplay/live3d/SteamtekPlayerChatBubble3D.tscn +
    steamtek_player_chat_bubble_3d.gd

Modified (partial list, the ones that matter for a future session):
  scenes/characters/templates/steamtek_humanoid_character_3d.gd (by far
    the largest and most-churned file this entire session)
  scenes/GameData.gd (WEAPON_TARGETING_MODES/WEAPON_SPLASH_RADIUS/
    WEAPON_CONE_ANGLE_DEGREES additions, total_purchased_stat(), the
    Grenade Launcher stat rebalance)
  scenes/Combat.gd -- NOT modified this session, but its
    grit_dot_reduction()/grit_cc_duration_mult() finally got a real
    consumer (section 5)
  scenes/gameplay/live3d/steamtek_live3d_hud.gd (HeatBar, Mods granting
    section, inventory_changed listener, _refresh_cogs tie-in)
  scenes/gameplay/live3d/steamtek_inventory_window.gd (mods/durability
    UI, ScrollContainer layout fix, inventory_changed signal)
  scenes/gameplay/live3d/SteamtekInventoryWindow.tscn
  scenes/gameplay/live3d/SteamtekLive3DHud.tscn
  scenes/gameplay/live3d/steamtek_tutorial_combat_target_3d.gd
    (Corrosive Grasp special attack, stagger/knockback)
  scenes/levels/apartment_3d/steamtek_apartment.gd (equip-handler
    slimdown, note dialogue split into modal+thought-bubble)
  scenes/levels/transition_tests/steamtek_transition_level_3d.gd
    (universal equip handler)
  scenes/effects/live3d/steamtek_surface_weather_3d.gd +
    steamtek_storm_atmosphere_3d.gd (F4 toggle)
  systems/crafting/crafting_service.gd (Phase 6 Batch 2 + Phase 8
    functions, all appended, nothing removed)


--------------------------------------------------------------
14. STILL OPEN / NEXT SLICE CANDIDATES
--------------------------------------------------------------
- No on-screen ammo counter or reload indicator (section 3).
- No stamina-empty feedback beyond just not being able to sprint/dodge.
- Enemy death feedback/loot drop still minimal (health hits 0,
  deactivates, nothing else).
- Only one enemy archetype (ScrapThief) exists in 3D.
- No visual telegraph for ScrapThief's Corrosive Grasp (an ENEMY
  ability -- would be red/yellow per the color convention, section 9)
  or for the player's Buttstroke swing (a PLAYER ability -- would be
  BLUE, not red/yellow -- do not conflate the two, they are unrelated
  abilities on opposite sides of combat that just both lack a
  telegraph right now).
- Weapon certification (professions_unlocked is still always passed as
  {} everywhere -- any cert-gated weapon is silently always
  "uncertified" regardless of real profession/keystone state tracked
  by the talent panel). Identified but not yet built; next planned
  combat-application item per Josh.
- Abilities backlog: Aimed Shot, Suppressing Fire, Buckshot Barrage are
  fully specced in GameData.ability_definitions but none are
  implemented as real actions (only Charged Shot exists).
- Crit chance is still flagged dead (old conditioning_nodes/path system,
  superseded by keystones, never reconnected -- no "Crit Chance"
  keystone node exists, only "Crit Damage").
- Steamtek Assembly System and crafting Phase 7 both explicitly ON HOLD
  (section 12).
- Mod granting is a flat-Cogs placeholder, not a real blueprint/
  material recipe (section 7).
