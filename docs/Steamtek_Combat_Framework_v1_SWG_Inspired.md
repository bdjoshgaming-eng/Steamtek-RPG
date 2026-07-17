# Steamtek Combat Framework v1.0

## SWG-Inspired Combat Design Specification

------------------------------------------------------------------------

# Design Intent

This document defines the intended combat framework for **Steamtek**.

Steamtek is **inspired by the design philosophy of Star Wars Galaxies
(Pre-CU)** while remaining its own original game. References to SWG are
included to explain the reasoning behind design decisions and to capture
the strengths of that game's combat, progression, crafting, and
encounter design.

This document is **not** intended to reproduce SWG's implementation,
proprietary data, or code. Instead, it establishes a balancing framework
that can be implemented natively for Steamtek.

This document should be treated as the authoritative combat reference.

------------------------------------------------------------------------

# Core Design Philosophy

## SWG Inspiration

Pre-CU SWG succeeded because:

-   Equipment mattered more than levels.
-   Crafted gear remained valuable throughout progression.
-   Hidden combat levels balanced encounters without being
    player-facing.
-   NPC difficulty was communicated through rank, equipment, and
    behavior.
-   Combat rewarded preparation, specialization, and gear quality.

## Steamtek Implementation

Steamtek adopts those philosophies while replacing SWG's systems with a
new setting and mechanics.

Core principles:

-   Hidden Combat Levels (CL 1--100)
-   Gear-first progression
-   Modular NPC archetypes
-   Data-driven balancing
-   Visual progression through equipment
-   Long-term scalability

------------------------------------------------------------------------

# Hidden Combat Levels

## SWG Inspiration

Combat level was primarily an internal balancing value that influenced
encounter difficulty, rewards, and progression rather than serving as
the player's primary progression metric.

## Steamtek Implementation

Combat Level is never shown directly.

Players see:

-   Enemy Name
-   Faction
-   Rank
-   Visual Equipment
-   Threat Rating

Combat Level drives:

-   Base Health
-   Effective Health
-   Armor Rating
-   Damage
-   XP
-   Credits
-   Loot Quality
-   AI Scaling

------------------------------------------------------------------------

# Core Combat Statistics

Player / NPC Statistics

-   Base Health
-   Effective Health
-   Armor Rating
-   Damage Reduction
-   Accuracy
-   Defense
-   Critical Chance
-   Critical Damage
-   Critical Resistance
-   Dodge
-   Block
-   Armor Penetration
-   Heat
-   Pressure Capacity
-   Movement Speed

------------------------------------------------------------------------

# Effective Health

## SWG Inspiration

Survivability came from more than a single health pool. Armor,
mitigation, and equipment quality significantly affected time-to-kill.

## Steamtek

Effective Health represents total survivability after armor and
mitigation are considered.

Effective Health is the balancing value used for encounter design.

------------------------------------------------------------------------

# Armor

## SWG Inspiration

Armor reduced incoming damage and featured different protection profiles
depending on damage type.

## Steamtek Armor Classes

1.  Civilian Clothing
2.  Reinforced Clothing
3.  Industrial Armor
4.  Tactical Armor
5.  Powered Armor
6.  Experimental Powered Armor

Armor properties

-   Armor Rating
-   Damage Reduction
-   Armor Penetration Resistance
-   Weight
-   Noise
-   Heat Generation

Damage Resistances

-   Ballistic
-   Arc
-   Thermal
-   Chemical
-   Pressure
-   EMP

------------------------------------------------------------------------

# Weapon Philosophy

## SWG Inspiration

Weapons supplied most combat power while abilities amplified weapon
performance. Crafted weapons represented meaningful upgrades.

## Steamtek

Abilities scale from equipped weapons.

Weapon families include:

-   Pistols
-   Revolvers
-   SMGs
-   Assault Rifles
-   Battle Rifles
-   Shotguns
-   Precision Rifles
-   Heavy Weapons
-   Steam Weapons
-   Arc Weapons
-   Pressure Weapons
-   Melee

------------------------------------------------------------------------

# NPC Progression

## Archetypes

-   Brawler
-   Assault
-   Rifleman
-   Heavy
-   Sniper
-   Engineer
-   Hacker
-   Medic
-   Commander
-   Shield Specialist

## Factions

### Rust Syndicate

Street gangs and scavengers.

### Blackline Security

Corporate military contractors.

### Reactor Authority

Industrial government security.

### Ghost Circuit

Cybernetically enhanced mercenaries.

------------------------------------------------------------------------

# Sample Combat Progression (v1)

    CL Tier         Effective Health   Armor   Avg Damage
  ---- ---------- ------------------ ------- ------------
     1 Trash                     120       0            8
     5 Trash                     250       6           14
    10 Trash                     600      12           25
    15 Standard                 1430      28           43
    20 Standard                 3250      45           70
    25 Veteran                  7000      70          110
    30 Veteran                 13800      95          170
    35 Elite                   26000     130          255
    40 Elite                   50000     170          365

These values establish progression targets only and are intended to be
expanded through CL100.

------------------------------------------------------------------------

# Time-to-Kill Targets

Trash: 3--6 seconds

Standard: 8--15 seconds

Veteran: 20--35 seconds

Elite: 45--90 seconds

Bosses: 2--10 minutes

------------------------------------------------------------------------

# Loot Philosophy

Inspired by SWG:

-   Better equipment should remain meaningful.
-   Crafted equipment should compete with dropped equipment.
-   Higher combat level should improve quality rather than simply
    quantity.
-   Rare components should enable long-term crafting progression.

------------------------------------------------------------------------

# AI Philosophy

Enemy intelligence scales with combat level.

Low CL: - Rushes player - Limited tactics

Mid CL: - Uses cover - Coordinates

High CL: - Flanks - Uses abilities - Retreats - Calls reinforcements -
Uses consumables

------------------------------------------------------------------------

# Implementation Guidelines

The implementation should:

-   Be data driven.
-   Derive NPC statistics from Combat Level, Archetype, Faction, and
    Equipment.
-   Keep formulas centralized.
-   Avoid hard-coded per-NPC statistics.
-   Allow balancing through editable data assets.

------------------------------------------------------------------------

# Appendix A --- SWG Design References

These concepts inspired Steamtek's combat framework:

-   Hidden combat levels
-   Equipment-first progression
-   Meaningful crafting economy
-   Weapon-centric combat
-   Armor as mitigation instead of simple health inflation
-   Profession specialization
-   Distinct combat roles
-   Faction identity
-   Time-to-kill balancing
-   Encounter difficulty communicated through presentation rather than
    exposed levels
-   Long-term progression through equipment quality
-   Rewarding preparation and specialization

For Steamtek, these principles should be adapted to a neo-industrial
cyberpunk world powered by pressure technology, industrial engineering,
and advanced augmentation rather than reproducing SWG's mechanics
directly.
