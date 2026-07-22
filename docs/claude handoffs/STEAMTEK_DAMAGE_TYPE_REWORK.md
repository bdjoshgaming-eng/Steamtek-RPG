STEAMTEK RPG - DAMAGE TYPE & MOD REWORK SPEC
==============================================
Status: APPROVED DESIGN, ready to build
Replaces: Phase 6 mod definitions, socket tag system, EMP damage type
Touches: CombatData.gd, Combat.gd, crafting_data.gd, crafting_models.gd, main.gd
Date: 2026-07-21


--------------------------------------------------------------
1. DAMAGE TYPES (was 7, now 6 -- EMP removed)
--------------------------------------------------------------
EMP is cut. Six types remain, each with a distinct combat identity:

  Kinetic    Bruising     Lowers target damage output
  Ballistic  Piercing     Ignores a % of armor
  Thermal    Burn         DOT (fire damage over time)
  Pressure   Blast        Knockback / stagger
  Arc        Electrical   Stun / slow
  Chemical   Toxic        Poison DOT

Every damage type now has a SECONDARY EFFECT that fires on hit
(chance or guaranteed TBD during tuning). This is the mechanical
reason to choose a type beyond the RPS matchup.

MIGRATION: remove "EMP" from DAMAGE_TYPES, ARCHETYPE_RESISTANCE_PROFILES,
and the validation check. Any code referencing EMP becomes dead.


--------------------------------------------------------------
2. TYPE EFFECTIVENESS (SWG-style resist profiles, NO RPS)
--------------------------------------------------------------
REJECTED: Rock-Paper-Scissors matchup table. Too abstract, adds
a layer players have to memorise on top of the per-enemy profiles.

ADOPTED: SWG-style per-enemy resistance display. Each enemy has
per-type resist percentages derived from its archetype profile
and CL-derived armor rating (this already exists). The player
examines the enemy, sees which types it resists and which it
doesn't, then picks the right Core mod. Scouting IS the game.

No additional matchup multiplier -- archetype profiles are the
ENTIRE system. The profiles just need dramatic enough spreads
that the right type choice matters visibly:
  - Near-immunity (profile 1.5+): this type bounces off
  - Moderate resist (0.8-1.2): normal mitigation
  - Vulnerability (below 0.5): this type cuts right through

Example: a Heavy has Kinetic 1.5, Arc 0.6. Against a CL12 Heavy
with 43 base armor:
  - Kinetic resist = 64 armor -> 31% DR (bounces)
  - Arc resist = 26 armor -> 16% DR (cuts through)
The player who equips an Arc Core on their weapon does roughly
double the effective damage. That's the whole system.


--------------------------------------------------------------
3. ARCHETYPE RESISTANCE PROFILES (updated for 6 types)
--------------------------------------------------------------
EMP column removed. Profiles rebalanced so every archetype has
at least one vulnerability below 0.7 and one strength above 1.2.
The design rule "every damage type is the right answer against
something" still holds.

Updated profiles (EMP column dropped, otherwise unchanged):

  Brawler:           Kin 1.3  Bal 0.7  Thm 0.6  Prs 0.8  Arc 0.5  Chm 0.6
  Assault:           Kin 1.0  Bal 1.2  Thm 0.8  Prs 0.8  Arc 0.7  Chm 0.7
  Rifleman:          Kin 0.8  Bal 1.0  Thm 0.8  Prs 0.7  Arc 0.8  Chm 0.8
  Heavy:             Kin 1.5  Bal 1.4  Thm 1.0  Prs 1.2  Arc 0.6  Chm 0.8
  Sniper:            Kin 0.6  Bal 0.8  Thm 0.7  Prs 0.6  Arc 0.8  Chm 0.8
  Engineer:          Kin 0.8  Bal 0.8  Thm 1.3  Prs 1.2  Arc 0.4  Chm 1.2
  Hacker:            Kin 0.6  Bal 0.6  Thm 0.7  Prs 0.6  Arc 0.3  Chm 0.8
  Medic:             Kin 0.7  Bal 0.7  Thm 0.9  Prs 0.8  Arc 0.8  Chm 1.4
  Commander:         Kin 1.1  Bal 1.1  Thm 1.0  Prs 1.0  Arc 0.9  Chm 0.9
  Shield Specialist: Kin 1.4  Bal 1.3  Thm 1.0  Prs 1.5  Arc 0.7  Chm 0.9


--------------------------------------------------------------
4. WEAPON DEFAULTS
--------------------------------------------------------------
ALL weapons default to Kinetic. Melee and ranged alike.

Every other damage type -- including Ballistic -- is ONLY
available through a Core mod. This makes every non-Kinetic type
an active investment. Ballistic's armor-piercing identity is
something you earn by crafting and installing a Ballistic Core,
not something every gun gets for free.

The "Damage Type" and "Wound Type" fields in
ITEM_DEFINITIONS.weapon_categorical_stats are removed entirely.
Damage type is determined at attack time:
  1. Check for an installed Core mod -> use its damage type
  2. No Core mod -> Kinetic

Wound Type / secondary effect is determined by the active
damage type, not the weapon class. See section 1.


--------------------------------------------------------------
5. MOD TYPES (replaces Phase 6 mod definitions)
--------------------------------------------------------------
Six mod TYPES, each with melee and ranged naming variants.
A weapon can have AT MOST ONE mod of each type installed.

  Type       Melee Name          Ranged Name        Effect
  -------    ----------------    ---------------    -------------------
  Damage     Edge                Barrel             Raw damage boost
  Accuracy   Counterweight       Gyro               Accuracy boost
  Speed      Spring Mechanism    Valve Assembly      Attack speed boost
  Ammo       --                  Magazine            Ammo capacity
  Range      --                  Scope               Range boost
  DmgType    Core                Core                Sets damage type

Melee weapons can accept: Damage, Accuracy, Speed, DmgType (4 types).
Ranged weapons can accept: all 6 types.

SOCKETS ARE GENERIC. A socket does not have a type tag -- it
accepts any mod type the weapon is eligible for. The old socket
tag system (kinetic/arc/thermal/pressure/utility) is removed.

Sockets from Phase 5 still determine HOW MANY mods a weapon
holds. A 3-socket melee weapon picks 3 of its 4 eligible types.
A 3-socket ranged weapon picks 3 of 6. Socket count from Phase 5
is now even more valuable.

UNIQUENESS RULE: one mod per type, enforced at install. You can
have 1 Edge + 1 Core + 1 Spring Mechanism, but never 2 Edges.
This replaces the old incompatible_tags system entirely.

SUITABILITY GATES:
  - CL range: a mod has a CL requirement. Cannot install a
    CL100 mod into a CL10 weapon. Range TBD (within 10 CLs?
    within same tier?).
  - Steamtek: Steamtek-crafted mods only go in Steamtek-crafted
    weapons. Normal mods go in normal weapons.
  - Weapon range: Magazine and Scope cannot go in melee weapons.


--------------------------------------------------------------
6. CORE MODS (damage type mods)
--------------------------------------------------------------
A Core mod is crafted from materials that determine its damage
type. The material families map to damage types:

  Damage Type   Example Materials
  ----------    ------------------------------------------
  Kinetic       (default -- no Core needed, but a Kinetic Core
                 can boost the secondary bruising effect)
  Ballistic     Projectile casings, penetrator tips
  Thermal       Fuel cells, heat catalysts
  Pressure      Pneumatic cores, compressed canisters
  Arc           Arc batteries, conductive compounds
  Chemical      Acid vials, toxin extracts

All six types are available as Core mods. Kinetic Cores are
optional (weapon already deals Kinetic), but a high-quality
Kinetic Core still provides a stronger bruising secondary
effect and, at higher grades, stat bonuses.

The QUALITY of materials used to craft the Core determines the
STRENGTH of the secondary effect (burn duration, poison damage,
armor ignore %, etc.). A low-quality Chemical Core applies weak
poison; a high-quality one applies strong poison.

At higher grades (Advanced, Prototype, Masterwork), Core mods
ALSO grant stat bonuses (damage, speed, accuracy) on top of the
damage type. This makes high-grade Cores the most valuable mods
in the game -- they do two jobs at once.

  Grade        Type Effect    Stat Bonus
  ---------    -----------    ----------
  Standard     Base           None
  Refined      Base x1.2      None
  Advanced     Base x1.4      Small (+1-2 to one stat)
  Prototype    Base x1.8      Moderate (+3-4, with drawback)
  Masterwork   Base x1.6      Moderate (+2-3, no drawback)

These multipliers scale the secondary effect strength, NOT the
RPS matchup multiplier (which is always 1.25/0.75).


--------------------------------------------------------------
7. MOD GRADE SYSTEM (unchanged)
--------------------------------------------------------------
The existing 5-grade system carries over:

  Standard     1.00x effect   1.00x drawback
  Refined      1.40x effect   1.00x drawback
  Advanced     1.80x effect   1.00x drawback
  Prototype    2.30x effect   1.60x drawback
  Masterwork   2.10x effect   0.00x drawback

Grades apply to ALL mod types (Edge, Barrel, Core, etc.).
A Masterwork Edge is a big damage boost with no penalty.
A Prototype Core is a strong elemental effect with a drawback.


--------------------------------------------------------------
8. DAMAGE RESOLUTION (updated formula)
--------------------------------------------------------------
Player attack with the new system:

  1. Weapon base damage = Damage Rating +/- 20% variance
  2. x Ability Coefficient
  3. x Certification Modifier
  4. x Critical Modifier
  5. x Class Modifier (placeholder 1.0)
  6. x Weak Point Modifier (placeholder 1.0)
  -- raw damage computed --
  7. Determine active damage type:
       If Core mod installed -> Core's damage type
       Else -> Kinetic
  8. Apply archetype resist (existing, unchanged):
       rating = armor x profile_multiplier_for_type
       DR = rating / (rating + 140)
       damage = damage x (1.0 - DR)
  9. Apply secondary effect (NEW):
       Roll for burn/poison/stun/etc. based on type + Core quality
  10. Damage dealt to target.

Steps 1-8 are unchanged from the existing system. Step 9 is new.
The mitigation path (apply_typed_mitigation) is UNCHANGED -- the
archetype profiles already handle type effectiveness. The only
new combat code is the secondary effect roll.


--------------------------------------------------------------
9. WHAT THIS REPLACES
--------------------------------------------------------------
REMOVED:
  - EMP damage type (from DAMAGE_TYPES, all profiles, validation)
  - weapon_categorical_stats["Damage Type"] per weapon in ITEM_DEFINITIONS
  - weapon_categorical_stats["Wound Type"] per weapon in ITEM_DEFINITIONS
  - SOCKET_TAGS (kinetic/arc/thermal/pressure/utility)
  - socket_tags on crafted items (sockets become generic slots)
  - All 8 existing MOD_DEFINITIONS (conductive_accelerator, recoil_stabilizer,
    heat_sink, pressure_chamber, targeting_optic, balanced_haft,
    reinforced_binding, status_module)
  - MOD_INCOMPATIBILITY_TAGS (replaced by one-per-type rule)
  - The "[DATA CHECK] no weapon deals Chemical, EMP" validation note

KEPT:
  - MOD_GRADES (5-tier grade system)
  - Socket count from Phase 5 (how many sockets a crafted item gets)
  - Socket probability bands and opportunity score
  - Mod instance model (mod_instance_id, mod_id, grade_id, installed_in)
  - Archetype resistance profiles (updated for 6 types)
  - The diminishing-returns armor curve (rating / (rating + 140))

NEW:
  - MOD_TYPES constant (6 mod type definitions)
  - Core mod crafting (material -> damage type mapping)
  - Secondary effect system (burn, poison, stun, etc.)
  - All weapons default to Kinetic damage type


--------------------------------------------------------------
10. IMPLEMENTATION ORDER
--------------------------------------------------------------
Phase A - Data cleanup (small, safe): DONE
  1. Remove EMP from DAMAGE_TYPES and all resistance profiles
  2. Remove weapon_categorical_stats from ITEM_DEFINITIONS
  3. Default damage type to Kinetic in _perform_attack
  4. Update validation checks (remove per-weapon type check)

Phase B - Mod type rework (medium): DONE
  1. Define MOD_TYPES constant with all 6 types + melee/ranged names
  2. Replace MOD_DEFINITIONS with new type-based definitions
  3. Remove SOCKET_TAGS -- sockets become generic
  4. Update socket generation to produce untagged sockets
  5. Update mod install logic: one-per-type + suitability gates

Phase C - Core mod crafting (medium): DONE
  1. FAMILY_DAMAGE_TYPE mapping in crafting_data.gd
  2. bp_core_mod blueprint + craft_mod() in CraftingService
  3. _perform_attack reads installed Core mod damage_type
  4. effect_strength stored on mod instance from material quality

Phase D - Secondary effects (can be iterative): DONE
  1. Burn DOT (Thermal)
  2. Poison DOT (Chemical)
  3. Armor pierce % (Ballistic)
  4. Damage debuff (Kinetic)
  5. Stun/slow (Arc)
  6. Knockback/stagger (Pressure)


--------------------------------------------------------------
11. SAVE COMPATIBILITY
--------------------------------------------------------------
Existing saves have weapons with the old socket_tags and possibly
old mod instances. Migration strategy:

  - socket_tags on items: ignore on load, treat as generic slots
  - Old mod instances: these mods no longer exist in MOD_DEFINITIONS.
    On load, any installed mod whose mod_id is not in the new
    MOD_DEFINITIONS is silently uninstalled (removed from the item's
    installed_mod_instance_ids). Since mods are currently NOT wired
    into equipped stats (Phase 6 Batch 2 was never completed), this
    has zero gameplay impact -- no player has a working modded weapon.
  - Damage type: weapons without a Core mod default to Kinetic.
    No migration needed -- this IS the new default behavior.
