# Steamtek Assembly System - Design Spec

Companion to STEAMTEK_CRAFTING_EXPERIMENTATION_MOD_SOCKET_SYSTEM_HANDOFF.md.
This document covers the RARE ITEM path: Steamtek fragments, Analysis,
schematics, and how recovered ancient tech produces items ordinary
crafting cannot.

Written 7-19-26, after crafting Phase 5.

Reference: Neocron's Tech Part / Research / Construction loop. Used for
SHAPE only -- all numbers are Steamtek-native.

------------------------------------------------------------------------

## 1. Identity

Steamtek is the world's premise: partially-understood ancient technology.
This system is where that premise becomes a mechanic.

    Recover fragments -> Analyse them -> Learn what they belong to
    -> Gather the set -> Assemble something better than you could build

The single rule the whole system obeys:

    STEAMTEK GIVES +1 OVER WHAT YOU COULD OTHERWISE MAKE AT THIS DEPTH.

That applies to sockets AND to mod grade. It is why the system stays
relevant from floor 1 to floor 60 instead of being an endgame bolt-on.

What Steamtek is NOT:
- NOT a mod grade. It is an INGREDIENT tier that feeds blueprints.
- NOT depth-locked to the endgame. Fragments drop at every tier.
- NOT a lottery. Nothing in this system fails or destroys parts.

------------------------------------------------------------------------

## 2. Fragment tiers

Mirrors Neocron's three unressed part tiers (T / E / L), renamed to carry
Steamtek's own fiction. Deeper floors are OLDER but CLEANER and BETTER
MADE, so tier tracks depth naturally.

| Tier         | Recovered from                          | Feeds              |
|--------------|-----------------------------------------|--------------------|
| Salvaged     | Surface, floors 1-20, early bosses       | Low-tier schematics|
| Intact       | Floors 21-45, uncommon bosses            | Mid-tier schematics|
| Pristine     | Floors 46-60, exceptional bosses, quests | Endgame schematics |

Flavour: a Salvaged fragment is picked-over junk that still half-works.
A Pristine fragment is Builders-era work, recovered from the era that
actually understood what it was building.

A fragment's tier SCALES ITS RESULT. Salvaged fragments used in a low-CL
craft produce a good LOW-CL item -- not an endgame one. This is the +1
rule, not a shortcut to the ceiling.

------------------------------------------------------------------------

## 3. Analysis

Fragments drop UNIDENTIFIED. They are inert until analysed.

- Analysis happens at an ANALYSIS BENCH (deliberate action, not instant).
- Analysis reveals WHICH component the fragment is, and therefore which
  schematics it can feed.
- ANALYSIS CANNOT FAIL. The fragment is never destroyed. (Neocron
  destroyed parts on failed research; that is rejected here -- it
  contradicts the crafting spec's guardrail against frequent total loss.)
- Analysis is the natural home for the Research half of the crafting
  keystone (Phase 7). Nodes there should improve yield/insight, never
  gate access.

The unidentified -> identified moment is the point of the mechanic. It is
the "what did I just find" beat that made Tech Parts memorable.

### 3.1 Analysis Bench (dependency)
Workbenches are spec Phase 8. Rather than drag that whole system forward,
add a MINIMAL Analysis Bench now: a standalone interactable, structurally
identical to the alley dumpster (walk up, press E, opens a panel).

This is deliberate seeding, the same way the dumpster became the
scavenging loop. The minimal bench becomes the seed the full workshop
system grows from in Phase 8.

------------------------------------------------------------------------

## 4. Component types

After Analysis, a fragment resolves to one of five component types.
Mirrors Neocron's hull / frame / comp / core / tech / add-tech.

| Component  | Role                                    |
|------------|-----------------------------------------|
| Core       | The power source. Rarest.               |
| Frame      | Structural skeleton.                    |
| Regulator  | Pressure/flow control.                  |
| Matrix     | The part nobody fully understands.      |
| Housing    | Casing and mounting. Most common.       |

A schematic names types and counts, e.g. Core x1, Frame x2, Regulator x2.
Tier and type are independent: a Pristine Housing and a Salvaged Housing
are the same component at different tiers.

------------------------------------------------------------------------

## 5. Schematics

A Steamtek Schematic is a blueprint that consumes components in addition
to (or instead of) ordinary materials.

| Category | Status  | Produces                                     |
|----------|---------|----------------------------------------------|
| Weapon   | Ready   | Socket ceiling +1 for the tier used          |
| Mod      | Ready   | One grade above what that depth would give   |
| Armor    | BLOCKED | No armor item type exists in Steamtek yet    |

Armor is explicitly deferred. Phase 6 is weapon mods only for the same
reason -- the item types do not exist. Do not design armor schematics
until an armor item type lands.

------------------------------------------------------------------------

## 6. Socket ceiling curve (APPROVED)

TWO TUNABLES AND A CURVE -- never a hardcoded socket count.

    MAX_SOCKETS            project-wide ceiling. Currently 5.
                           Change it to 6 or 7 and everything re-derives.
    DEPTH_SOCKET_CEILING   what NORMAL crafting reaches at a given depth.
    Steamtek               depth ceiling + 1.

STRUCTURAL RULE: normal crafting tops out at MAX_SOCKETS - 1. Steamtek is
the ONLY path to the true maximum, at every setting of MAX_SOCKETS. This
is what makes "+1" hold with no special cases, and keeps the top socket
permanently Steamtek-exclusive however high the cap is raised.

Shown at MAX_SOCKETS = 5:

| Floor band | Era                 | Normal | Steamtek |
|------------|---------------------|--------|----------|
| 1-10       | Survivors           | 1      | 2        |
| 11-20      | Survivors           | 2      | 3        |
| 21-35      | Expansion           | 3      | 4        |
| 36-50      | Expansion/Builders  | 4      | 5        |
| 51-60      | Builders            | 4      | 5        |

Normal crafting flattens at MAX_SOCKETS - 1 around floor 36. The last
stretch of the Silo is therefore about QUALITY and Steamtek access, not
more sockets. Raising MAX_SOCKETS stretches this table rather than
breaking it.

------------------------------------------------------------------------

## 7. Mod grade curve (APPROVED)

Grade derives from what goes IN -- same principle as sockets.

| Floor band | Era        | Grade                             |
|------------|------------|-----------------------------------|
| 1-10       | Survivors  | Standard   (x1.0)                 |
| 11-25      | Survivors  | Refined    (x1.4)                 |
| 26-45      | Expansion  | Advanced   (x1.8)                 |
| 46-60      | Builders   | Prototype  (x2.3, drawback x1.6)  |

Steamtek components raise the result ONE GRADE above what that depth
would otherwise produce -- the same +1 rule as sockets.

TOP GRADE: **Artifact** (x2.1, drawback x0.0). Named provisionally --
"Steamtek" now belongs to the ingredient, and Artifact is Neocron's own
term for a maxed rare. Masterwork remains an alternative.

Artifact gives LESS raw power than Prototype but removes the drawback
entirely, so the top grade is a CHOICE, not a strict upgrade. Prototype
is human over-engineering; Artifact just works, because nobody alive
knows how.

------------------------------------------------------------------------

## 8. Nothing fails

Josh's call, and consistent with the crafting spec's guardrails.

- Analysis cannot fail. The fragment survives.
- Assembly cannot fail. The components survive... by being consumed into
  the item, as normal.
- THE GRIND IS THE ENTIRE COST.

Neocron destroyed parts on both failed research and failed construction.
That is rejected. It is the single biggest reason rares felt punishing
rather than rewarding, and the crafting spec explicitly warns against
frequent total item loss.

Assembly still runs through the existing experimentation system, so the
OUTCOME still varies with allocation and materials. What is guaranteed is
that you get an item and keep your progress.

------------------------------------------------------------------------

## 9. Integration with the existing system

### 9.1 Reconciliations required
- BLUEPRINT max_sockets IS NOW DERIVED. Blueprints currently declare a
  flat max_sockets (3 for weapons, 0 for consumables). Weapon socket
  capacity must come from the depth curve instead, or the blueprint
  silently overrides it. Consumables keep an explicit 0.
- PHASE 5 OPPORTUNITY BANDS must roll WITHIN the depth ceiling. A great
  roll on shallow materials should give the shallow maximum, not a deep
  result. Opportunity decides where you land UNDER the ceiling; depth
  decides the ceiling.

### 9.2 Reused as-is
- MaterialBatch provenance already carries floor_id / source_id, so
  "depth of the materials used" is already known at craft time.
- craft_seed derivation and the anti-save-scum rule apply unchanged.
- CraftingService.craft() remains the single mutation point.

### 9.3 New state
- Fragments (unidentified) and components (identified) need an inventory
  representation. They are closer to MaterialBatch than to plain items:
  they carry tier and provenance.
- Known schematics belong on the player crafting profile alongside
  blueprint familiarity.

------------------------------------------------------------------------

## 10. Open items and dependencies

BLOCKING
- FRAGMENT DROP SOURCES. Enemies do not drop fragments today. Combat loot
  tables are the natural hook, BUT there are no boss enemies and no AI at
  all (combat Phase 8). So early Steamtek must initially come from FLOOR
  LOOT and QUESTS. Boss drops arrive with bosses.
- ANALYSIS BENCH must exist before Analysis can be a deliberate action.

DECISIONS STILL OPEN
- Confirm "Artifact" as the top grade name (vs Masterwork).
- How many fragments per schematic, per tier. Suggested starting point:
  low-tier 3 components, mid 5, endgame 7. Needs playtesting.
- Do schematics drop, or are they researched from an existing item the
  way Neocron blueprints were?

DEFERRED
- Armor schematics (no armor item type).
- Workshop/tool contributions (Phase 8).
- Crafting keystone Research nodes (Phase 7).

------------------------------------------------------------------------

## 11. Suggested implementation order

1. Fragment + component data model and the tier table (data only, no
   main.gd risk -- same staging that worked for crafting Phase 3).
2. Depth-derived socket ceiling; reconcile blueprint max_sockets and the
   Phase 5 opportunity bands against it.
3. Minimal Analysis Bench interactable + Analysis panel.
4. Steamtek schematics and assembly through CraftingService.
5. Fragment drops from floor loot and quests.
6. Boss drops once bosses exist (combat Phase 8).
