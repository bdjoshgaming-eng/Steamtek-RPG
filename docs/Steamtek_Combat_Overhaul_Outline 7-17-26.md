# Steamtek Combat Overhaul - Outline & Build Order

Companion to `Steamtek_Combat_Framework_v1_SWG_Inspired.md` (the design
target) and the weapon-formula / weapon-cert design memories. This
document is the BRIDGE: how to get from the combat that exists in code
today to the framework, in an order where each step stands on the last.

Approach: GROW from the current dummy/enemy2 test combat. Nothing gets
ripped out up front. Instead, each phase upgrades what's already there,
and the two test enemies become the first two data-driven NPCs.

------------------------------------------------------------------------

## 1. Where we are vs where we're going

| Area              | In code today                                   | Framework target                                        |
|-------------------|-------------------------------------------------|---------------------------------------------------------|
| Enemies           | Hardcoded `dummy` + `enemy2` with loose vars    | Any NPC generated from CL + Archetype + Faction + Gear   |
| Difficulty        | Fixed per-enemy health/action numbers           | Hidden Combat Level 1-100 drives everything             |
| Survivability     | Single health pool                              | Effective Health (health after armor + mitigation)      |
| Damage            | `dmg x ability_mult x cert_mult` inline         | One central coefficient formula                         |
| Armor             | None                                            | 6 armor classes, 6 typed resistances, armor pen         |
| Combat rolls      | Range-based accuracy only                       | Accuracy/Defense, Crit chance/dmg/resist, Dodge, Block  |
| Weapon classes    | 6 melee + 6 ranged buckets                      | 12 weapon families with proficiency scaling             |
| Certs             | Half-damage placeholder                         | Tiered certs + accuracy/speed proficiency               |
| AI                | Basic attack loop                               | Behavior scales with CL (rush -> cover -> flank)         |
| Loot              | Flat drop tables                                | CL scales quality, crafted competes with dropped        |

The gap is large, so ORDER matters. Building armor before a central
damage pipeline, or NPC generation before a stat block, means redoing
work. The phases below are sequenced by dependency.

------------------------------------------------------------------------

## 2. Guiding principles (apply to every phase)

- DATA-DRIVEN: NPC stats are derived, never hand-typed per enemy.
- ONE FORMULA: all damage flows through a single function so balance is
  tuned in one place.
- CENTRALIZED DATA: combat numbers live in editable data assets
  (dictionaries/resources), not scattered constants.
- HIDDEN CL: Combat Level never shows to the player; they see Name,
  Faction, Rank, visual Equipment, and Threat Rating.
- GEAR-FIRST: the weapon and gear carry most of the power; abilities and
  levels amplify, they don't replace.
- SWG IS INSPIRATION ONLY: build fresh numbers for Steamtek's own scale.
- GROW, DON'T GUT: each phase leaves the game playable.

------------------------------------------------------------------------

## 3. Design Spec (what each system is)

### 3.1 Combat Stat Block
A shared structure carried by the player and every NPC. One definition,
used everywhere. Fields: Base Health, Effective Health, Armor Rating,
Damage Reduction, Accuracy, Defense, Critical Chance, Critical Damage,
Critical Resistance, Dodge, Block, Armor Penetration, Heat, Pressure
Capacity, Movement Speed.

### 3.2 Hidden Combat Level (CL 1-100)
An internal number per NPC. Drives Base Health, Effective Health, Armor,
Damage, XP, Credits, Loot Quality, and AI tier. Anchored by the v1
sample table (CL1-40) and interpolated between anchors; expanded toward
CL100 later.

### 3.3 Master Damage Formula
`Damage = WeaponDamage x AbilityCoefficient x ClassModifier x
CriticalModifier x WeakPointModifier x RandomVariance`.
Basic attack coefficient = 1.0; specials scale relative to it. The
weapon supplies base damage; abilities supply coefficients. (See weapon
memory for reference multiplier ranges.)

### 3.4 Armor & Mitigation
6 classes (Civilian Clothing, Reinforced Clothing, Industrial Armor,
Tactical Armor, Powered Armor, Experimental Powered Armor). Each has
Armor Rating, Damage Reduction, Armor Pen Resistance, Weight, Noise,
Heat Generation, and per-type resistances: Ballistic, Arc, Thermal,
Chemical, Pressure, EMP. Armor reduces damage; it does not inflate
health. Effective Health is what survivability and encounter tuning are
measured against.

### 3.5 Combat Roll Layer
Hit determination (Accuracy vs Defense), Critical Chance/Damage/
Resistance, Dodge, Block, Armor Penetration. These feed the Critical and
WeakPoint modifiers in the damage formula and decide whether a hit lands
at all.

### 3.6 NPC Generation
`spawn(CL, Archetype, Faction, Equipment)` produces a stat block.
Archetypes (Brawler, Assault, Rifleman, Heavy, Sniper, Engineer, Hacker,
Medic, Commander, Shield Specialist) reshape derived stats. Factions
(Rust Syndicate, Blackline Security, Reactor Authority, Ghost Circuit)
add identity, equipment pools, and loot flavor.

### 3.7 Threat & Presentation
Because CL is hidden, the player reads difficulty from Name, Faction,
Rank, visible Equipment, and a Threat Rating derived from the enemy's CL
relative to the player.

### 3.8 AI Scaling
Low CL: rush, limited tactics. Mid CL: use cover, coordinate. High CL:
flank, use abilities, retreat, call reinforcements, use consumables.

### 3.9 Loot Quality
Higher CL raises loot QUALITY, not just quantity. Crafted gear stays
competitive with drops. Rare components feed long-term crafting.

### 3.10 Weapon Families & Proficiency
Expand the current 6+6 class buckets to the 12 families. Per-family
proficiency raises accuracy and speed; certs gate tiers; crafted weapons
are the endgame power source.

------------------------------------------------------------------------

## 4. Build Order (phased migration)

Each phase says what it does, what it depends on, and how it grows from
current code. Ship and test each phase before starting the next.

### Phase 0 - Centralize the damage path (prep)
- Pull the existing inline damage math into ONE function all attacks call.
- No behavior change; this just creates the choke point everything else
  plugs into.
- Depends on: nothing. Do this first.

### Phase 1 - Combat Stat Block
- Define the shared stat structure (3.1).
- Give player, dummy, and enemy2 a stat block instead of loose vars
  (dummy_max_health, etc. become fields in the block).
- Depends on: Phase 0.
- Grows from: dummy/enemy2 keep working, now backed by a stat block.

### Phase 2 - Hidden Combat Level + stat derivation
- Add a CL field to NPCs and a derivation module: CL -> Base Health,
  Effective Health (pre-armor for now), Armor Rating, Damage, using the
  v1 anchor table with interpolation.
- Re-express dummy/enemy2 as "CL N" enemies; their numbers now come from
  the derivation, not hardcoded values.
- Depends on: Phase 1.

### Phase 3 - Master damage formula
- Implement the coefficient formula (3.3) in the Phase 0 function.
- Migrate abilities from fixed multipliers to coefficients; basic attack
  = 1.0. Weapon supplies base damage.
- Depends on: Phase 0, Phase 1 (needs weapon/attacker stats).

### Phase 4 - Armor & mitigation -> real Effective Health
- Add armor classes, damage reduction, typed resistances, armor pen.
- Effective Health becomes Base Health seen through mitigation; this is
  now the encounter-balancing value.
- Depends on: Phase 2 (armor rating derived from CL) and Phase 3 (formula
  to apply mitigation into).

### Phase 5 - Combat roll layer
- Accuracy vs Defense hit checks; Crit chance/damage/resist; Dodge;
  Block; Armor Pen interacting with armor.
- Wire crit/weak-point into the formula's Critical/WeakPoint modifiers.
- Depends on: Phase 3, Phase 4.

### Phase 6 - NPC generation (archetype + faction)
- Build `spawn(CL, Archetype, Faction, Equipment)` producing a full
  stat block via archetype/faction templates.
- Re-create dummy/enemy2 as the FIRST outputs of this generator (e.g. a
  low-CL Rust Syndicate Brawler), then delete their hardcoded paths once
  generation covers them.
- Depends on: Phases 1-5 (needs the whole stat/damage/armor spine).

### Phase 7 - Threat rating + presentation
- Compute Threat Rating from enemy CL vs player; show Name/Faction/Rank/
  Equipment/Threat instead of any number.
- Depends on: Phase 2 (CL), Phase 6 (faction/rank data).

### Phase 8 - AI scaling by CL
- Behavior tiers (3.8) selected by the enemy's CL band.
- Depends on: Phase 6 (archetypes give behavior hooks).

### Phase 9 - Loot quality scaling
- CL drives quality rolls; ensure crafted competes with dropped.
- Depends on: Phase 2 (CL), existing loot/crafting systems.

### Phase 10 - Weapon-family reconciliation
- Expand 6+6 classes to the 12 families; attach per-family proficiency
  (accuracy + speed) and tiered certs (replacing the half-damage
  placeholder with the fuller penalty model).
- Depends on: Phases 3-5. Can run partly in parallel once the formula is
  stable.

------------------------------------------------------------------------

## 5. Decisions to lock before/along the way

- Steamtek's own number SCALE: pick real Base/Effective Health and damage
  ranges for CL1 and CL100 anchors (framework gives targets to CL40).
- How CL maps to the current XP progression (does killing a CL10 enemy
  give more Combat XP than a CL1?).
- Whether the player also has a hidden CL or is purely gear-defined.
- Which damage TYPE each existing weapon deals (maps to armor
  resistances).
- Where combat data assets physically live (extend GameData.gd, or new
  data files?).
- How the 12 weapon families map onto Street Thug's current Melee/Ranged
  keystones (some families may belong to later specializations).

------------------------------------------------------------------------

## 6. Risks & gotchas

- BIG BANG RISK: doing armor/crit/NPC-gen before the stat block and
  central formula exist will force rework. Hold the order.
- HIDDEN CL LEAK: make sure CL never prints to any label, tooltip, or
  debug line the player can see.
- SAVE COMPATIBILITY: adding stat blocks / CL to enemies and gear may
  change save data shape; plan a migration or version check.
- BALANCE DRIFT: once damage is one formula, re-tune abilities as
  coefficients; old fixed multipliers won't map 1:1.
- SCOPE: this is many sessions of work. Treat each phase as its own
  FEATURE (concept -> build -> test) rather than one giant push.

------------------------------------------------------------------------

## 7. Suggested first move

Phase 0 + Phase 1 together make a clean, low-risk first session: create
the central damage function and the shared stat block, back dummy/enemy2
with it, and confirm nothing changed in play. That establishes the spine
everything else hangs on, without altering how combat currently feels.
