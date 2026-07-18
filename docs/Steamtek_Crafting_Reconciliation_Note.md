# Steamtek Crafting Reconciliation Note

Maps the new crafting specification
(`STEAMTEK_CRAFTING_EXPERIMENTATION_MOD_SOCKET_SYSTEM_HANDOFF.md`) against
the crafting code that exists in the repo TODAY.

Purpose: the spec's own Work Instructions say to inspect existing
architecture first, reuse existing abstractions, and REPORT CONFLICTS
BEFORE making destructive structural changes. This is that report.

Nothing here is implemented. This is a decision document.

Written 7-18-26, after Combat Overhaul Phase 4b.

------------------------------------------------------------------------

## 0. Headline

The good news: the existing crafting code already implements more of the
spec's SHAPE than expected. There is a real material -> weighted quality
-> assembly -> unique crafted item pipeline, and unique item identity is
already correct. The spec is largely an EXPANSION of that pipeline, not a
replacement of it.

The conflicts are concentrated in four places:

1. Quality scale and material data model (0-1000 single stat vs 0-100
   plus trait/instability).
2. Recipes vs Blueprints (no familiarity, no socket fields).
3. The Crafting KEYSTONE collision (combat-profession-gated vs universal).
4. Missing stages: experimentation, sockets, mods, durability.

Only #3 is a genuine design conflict that needs a decision from Josh.
The rest are additive migrations.

------------------------------------------------------------------------

## 1. What exists today (verified in code)

### 1.1 Recipes (GameData.gd, `var recipes`, 38 entries)
Per-recipe fields in use:
- `name`, `output`, `output_quantity`
- `requires` (material -> count), `slot_names` (material -> flavor slot label)
- `stat_weights` (material -> {stat: weight}) -- which material stats matter
- `quality_ingredients` (optional; which materials count toward quality)
- `item_class`, `item_subclass`, `requires_profession`, `requires_box`
- `weapon_categorical_stats` ({"Damage Type", "Wound Type"})
- `weapon_stat_ranges` ({stat: [min, max]}) -- realized by quality
- `max_charges` (consumables)

### 1.2 The crafting flow that exists
```
Crafting Book (browse recipes, gated by _is_recipe_learned)
   -> _select_crafting_book_recipe
   -> _enter_crafting_assembly        (assembly screen: pick material per slot)
   -> _execute_assembly_craft         (validate slots + amounts)
        - per slot: _get_weighted_stack_score(instance, slot, recipe)
          = weighted average of that material's stats using stat_weights
        - base_quality = weighted average across slots
   -> _finalize_crafted_item(recipe, base_quality)
        - quality x (1 + Crafting nodes*0.03 + Fabrication Mastery*0.01)
        - clamped to 1000
        - unique item_key via _generate_unique_resource_name()
        - realizes weapon_stat_ranges: value = min + (quality/1000)*(max-min)
        - copies weapon_categorical_stats verbatim
        - awards flat 15 Crafting XP (+15 for Medicine)
   -> _show_crafting_result_popup
```

### 1.3 Materials / resources
- Resource instances are unique inventory entries with a stat dictionary
  (`inventory_stats[instance]`), e.g. Mineral stats are
  ["Quality", "Energy", "Toughness", "Density"].
- Quality scale is 0-1000 (default 500), NOT 0-100.
- Sampling/surveying exists: `_on_sample_pressed`, survey tools,
  `resource_hotspots` / `resource_hotspot_centers`, a Survey Book UI.
- Hotspots are generated at RUNTIME around the player's position
  (`_generate_hotspot_set`) -- not from a saved campaign seed.

### 1.4 Recipe gating (`_is_recipe_learned`)
- No `requires_profession` -> always learned.
- Otherwise the profession must be unlocked.
- For Street Thug: the CRAFTING KEYSTONE must be unlocked; `Novice` box
  recipes then unlock, everything else needs 6+ points in that keystone.

------------------------------------------------------------------------

## 2. Conflict register

Severity: [DECISION] needs Josh | [MIGRATE] mechanical change |
[ADD] purely additive | [OK] already compatible.

### C1. Crafting keystone collision  [DECISION]
- TODAY: "Crafting" is one of Street Thug's four COMBAT-profession
  keystones. Recipe access is gated behind unlocking it and spending 6
  points in it.
- SPEC: crafting is explicitly NOT a class. Every character must be able
  to gather, sample, research, craft, experiment, install basic mods,
  dismantle and repair. The crafting keystone is a SEPARATE 15-node,
  pick-4 tree, and no node may block baseline crafting.
- Conflict: the current design makes crafting a combat-profession
  purchase; the spec forbids that.
- Options:
  (a) Keep the Street Thug Crafting keystone as a small thematic BONUS
      (spec explicitly allows small class bonuses) and remove its
      recipe-gating role, adding the separate universal crafting keystone
      alongside it.
  (b) Retire the Street Thug Crafting keystone entirely and move its
      content into the new universal tree (frees a keystone slot -- but
      changes an already-built and already-rendered profession tree).
  (c) Defer: keep gating as-is until the crafting keystone phase.
- Recommendation: (a). It satisfies the spec, preserves the existing
  KeystoneViewer work, and is the least destructive.
- NOTE: `_finalize_crafted_item` also reads `Crafting` and
  `Fabrication Mastery` node counts for a quality multiplier. Under the
  spec these bonuses should come from the universal crafting keystone,
  not the combat profession.

### C2. Quality scale 0-1000 vs 0-100  [MIGRATE]
- TODAY: quality 0-1000, default 500; stat realization divides by 1000.
- SPEC: Quality is 0-100 (player-facing).
- Touch points: `_finalize_crafted_item`, `_scale_by_quality`,
  `_get_weighted_stack_score` fallbacks (50.0 / 500 defaults),
  `_grant_starting_weapon`, consumable effect lines, result popup, loot
  quality defaults (`= 500`), and every saved item already carrying a
  0-1000 value.
- Risk: SAVE COMPATIBILITY. Existing saves hold 0-1000 values; a naive
  switch silently divides every crafted item's power by 10.
- Options: (a) convert on load with a save-version bump; (b) keep 0-1000
  internally and only DISPLAY 0-100; (c) leave as-is and treat the spec's
  0-100 as notional.
- Recommendation: (b) for now -- the spec's concern is what the PLAYER
  sees, and (b) needs no save migration. Revisit if internal 0-100 is
  wanted later.

### C3. Material data model  [MIGRATE + ADD]
- TODAY: a material instance is a stat dictionary (Quality, Energy,
  Toughness, Density...). `stat_weights` decides which stats matter per
  recipe slot -- this is genuinely SWG-like and worth keeping.
- SPEC: a material BATCH carries: quality, primary trait, instability/
  drawback, amount, source id, floor id, location id, extraction purity,
  discovered/analyzed flags.
- Gap: no trait, no instability, no source/floor provenance, no analysis
  state.
- Note: the spec also says do NOT expose an SWG-style stat spreadsheet.
  The current multi-stat display is closer to the spreadsheet the spec
  warns about; the trait/instability model is meant to replace it as the
  PLAYER-FACING layer.
- Recommendation: additive -- keep the stat dict as the internal
  potential model, add trait/instability/provenance fields, and simplify
  what the UI shows.

### C4. Recipes vs Blueprints  [ADD]
- Missing vs spec: blueprint familiarity 0-100, mastery states, socket
  fields (guaranteed/max sockets), experimentation category definitions,
  learning/reverse-engineering paths.
- Existing recipe fields map cleanly onto blueprint fields; this is an
  extension of the recipe dictionary, not a rewrite.
- Recommendation: extend `recipes` in place, keep stable IDs (`output`
  names are currently the de-facto ID and are referenced by
  WEAPON_CERT_REQUIREMENTS and keystone `weapons` lists -- do not rename).

### C5. Experimentation stage missing  [ADD]
- TODAY: assembly immediately finalizes. Quality alone determines stats.
- SPEC: after assembly, generate experimentation points, allocate them by
  category, resolve with a risk mode (Stable/Standard/Aggressive), THEN
  finalize.
- Good news: `_enter_crafting_assembly` / `_execute_assembly_craft` /
  `_finalize_crafted_item` are already separate steps, so the
  experimentation stage inserts between assembly and finalize without
  restructuring the flow.

### C6. Mod sockets and mods missing  [ADD]
- Nothing in the codebase models sockets, mods, install/remove, or
  compatibility. Fully new. Depends on C4 (blueprint socket fields) and
  C5 (Mod Architecture experimentation feeding socket odds).

### C7. Seeded campaign resources  [MIGRATE]
- TODAY: `resource_hotspots` are generated at runtime around the player's
  current position when scanning; nothing is seeded or permanent, and
  floors have no resource identity.
- SPEC: a saved `campaign_seed` generates a PERMANENT resource map at new
  game; floors/districts have industrial identities and eligible pools;
  validation guarantees progression-critical materials exist; reloading
  never rerolls.
- This is the single largest new subsystem, and it is essentially
  independent of the item-crafting pipeline. It can be built in parallel
  or deferred without blocking C4/C5/C6.

### C8. Anti-save-scumming / craft seeds  [ADD]
- TODAY: craft results are rolled live; nothing stores a craft seed.
  Reloading before finalizing would reroll.
- SPEC: store craft seeds so reloads never reroll a finalized result.
- Cheap to add at the same time as C5.

### C9. Durability / repair / dismantle / rebuild  [ADD]
- Not modeled today. Spec Phase 8. No conflict, purely new.

### C10. Crafting XP  [OK, minor]
- TODAY: flat 15 Crafting XP per craft (+15 Medicine).
- SPEC: doesn't dictate XP. Compatible, but XP should probably eventually
  reward experimentation quality rather than a flat rate.

------------------------------------------------------------------------

## 3. Interaction with the Combat Overhaul

Only two combat phases actually touch crafting.

- COMBAT PHASE 9 (loot quality scaling): the spec says crafted gear must
  stay competitive with drops, and that CL raises loot QUALITY. If loot
  quality and crafted quality use the same scale (see C2), keep them on
  one shared quality concept so "competitive" is measurable.
- COMBAT PHASE 10 (weapon families / proficiency / crafted endgame): this
  is the real overlap. Phase 10 assumes crafted weapons are the endgame
  power source; the spec changes HOW those weapons are produced (sockets,
  mods, experimentation-realized stats). Phase 10 should therefore treat a
  crafted weapon's final stats as opaque inputs -- read the item's
  realized stats, never assume they came from `weapon_stat_ranges` x
  quality.

Everything else in the combat overhaul (4c armor classes, Phase 5 rolls,
Phase 6 NPC generation, Phase 7 threat, Phase 8 AI) is independent of
crafting and can proceed with no crafting decisions made.

Consequence: the combat overhaul can be finished first WITHOUT blocking on
this note, provided Phase 10 follows the "opaque stats" rule above.

------------------------------------------------------------------------

## 4. Recommended sequencing

1. Decide C1 (keystone collision) and C2 (quality scale). These two shape
   everything downstream and are cheap prose decisions.
2. Finish the Combat Overhaul (4c -> Phase 10), honoring the Phase 10
   "opaque stats" rule.
3. Crafting Phase 1 (data foundation): extend recipes -> blueprints,
   add trait/instability/provenance to materials, add the crafted-item
   instance model and player crafting profile, save serialization.
4. Crafting Phase 3-5 (basic crafting -> experimentation -> sockets)
   built on the existing assembly flow.
5. Crafting Phase 2 (campaign resource generator) can slot in any time
   after step 1; it is independent of the item pipeline.
6. Crafting Phases 6-8 (mods, keystone, repair) last.

Note this deliberately reorders the spec's own phase list: the spec puts
the campaign resource generator at Phase 2, but it is the least coupled
piece and the most work, so it need not block the crafting loop itself.

------------------------------------------------------------------------

## 5. Open questions for Josh

1. C1: keystone collision -- option (a) keep Street Thug's Crafting
   keystone as a thematic bonus and add a separate universal crafting
   tree, (b) retire it, or (c) defer?
2. C2: quality scale -- keep 0-1000 internally and display 0-100
   (no save migration), or migrate fully to 0-100?
3. Do existing saves need to survive the crafting migration, or is a
   fresh campaign acceptable when the new system lands?
4. Should the 38 existing recipes be converted to blueprints in place, or
   should blueprints start as a new parallel set while recipes keep
   working during the transition?
