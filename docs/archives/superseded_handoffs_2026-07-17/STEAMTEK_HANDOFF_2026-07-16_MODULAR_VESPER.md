# Steamtek Handoff - Modular Vesper Character

Updated: July 16, 2026  
Canonical project: `C:\My Game\Steamtek-RPG`

## Immediate resume point

Vesper Kane now has a versioned modular-character branch containing:

- a finished-proportion neutral base body;
- separate hideable body regions;
- the approved v1.1 default outfit converted into equipment slots;
- the locked Steamtek humanoid skeleton and animation library;
- a versioned GLB that does not replace the current working player;
- an isolated Godot equipment-swap playtest;
- body-only, default-outfit, and mixed-loadout states;
- neutral Blender review renders at the locked camera direction.

The current working Vesper remains unchanged. Claude-owned gameplay files were not modified.

## Open this first

In Godot, open:

`res://scenes/tests/characters/VesperKane_ModularEquipment_Playtest_v01.tscn`

Run the current scene with `F6`.

Controls:

- `WASD`: move Vesper;
- `1`: modular base body;
- `2`: complete default outfit;
- `3`: mixed loadout with headgear and outer torso removed.

The review scene uses the established `+40 degree` model-forward correction and the existing Steamtek humanoid controller.

## Completed validation

Blender/export results:

```text
Skeleton bones:       706
Base-body meshes:      20
Default-outfit meshes: 31
Mechanical arm:        physical left
Skeleton changed:      false
Animation changed:     false
Scale changed:         false
Actions:               STK_IDLE, STK_WALK
```

Godot import validation:

```text
MODULAR_BODY_MESHES=20
MODULAR_OUTFIT_MESHES=31
MODULAR_SKELETONS=1
MODULAR_ANIMATION_PLAYERS=1
MODULAR_ANIMATIONS=[STK_IDLE, STK_WALK]
MODULAR_VALIDATION=PASS
```

Equipment-state validation:

```text
Body only:      20 body meshes / 0 outfit meshes
Default outfit:  9 body meshes / 31 outfit meshes
Mixed loadout:  12 body meshes / 13 outfit meshes
VESPER_MODULAR_SWAP_TEST=PASS
```

Idle and walk-frame Blender reviews were rendered successfully. The body and outfit deform through the existing walk action without changing the rig.

## New canonical files

### Versioned modular character

`assets/characters/player/VesperKane_3D/modular_character_v01/`

Important contents:

```text
Steamtek_C001_VesperKane_ModularCharacter_v01.blend
STK_C001_VesperKane_ModularCharacter_v01.glb
STK_C001_VesperKane_ModularCharacter_v01.export.json
VESPER_MODULAR_CHARACTER_CONTRACT_V01.md
scripts/
reviews/
```

### Godot integration

```text
scenes/characters/player/VesperKane_ModularCharacterReview_v01.tscn
scenes/tests/characters/VesperKane_ModularEquipment_Playtest_v01.tscn
scenes/tests/characters/vesper_modular_equipment_review.gd
```

### Review images

```text
assets/characters/player/VesperKane_3D/modular_character_v01/reviews/
|- Vesper_ModularBody_v01_locked60.png
|- Vesper_DefaultOutfit_v01_locked60.png
|- Vesper_MixedLoadout_v01_locked60.png
|- Vesper_ModularBody_v01_walk_frame13.png
`- Vesper_DefaultOutfit_v01_walk_frame13.png
```

## Modular-character contract

The source of truth is:

`assets/characters/player/VesperKane_3D/modular_character_v01/VESPER_MODULAR_CHARACTER_CONTRACT_V01.md`

The locked rules are:

- use the existing Vesper v1.1 skeleton;
- never rename or reorder bones for clothing;
- retain `STK_IDLE` and `STK_WALK`;
- retain scale, ground contact, and the physical-left mechanical arm;
- retain the `+40 degree` Godot facing correction;
- prefix base-body meshes with `VK_MB01_`;
- prefix equipment meshes with `VK_SLOT_<SLOT>_`;
- hide covered body regions rather than allowing garments to clip;
- use neutral authored materials;
- cyan and magenta environmental color must come from runtime lighting, not baked color;
- export versioned branches until the user explicitly approves replacement of the live player.

Current equipment slots:

```text
headgear
outer_torso
shoulders
gloves
legs
boots
waist
hip_right
```

Planned slots already reserved by the contract:

```text
back
mechanical_arm_attachment
weapon_right
item_left
```

## Visual status

The modular system is technically complete and validated. The current base body is a finished-proportion neutral fitted shell, not the final skin/face detail pass. It exists to provide reliable anatomy, deformation, garment support, and body masking.

The default outfit is the approved production-mesh v1.1 geometry reorganized into equipment slots. It has not yet received the final detailed face, garment-surface, weathering, or production texture pass.

The next visual approval should answer:

1. Are Vesper's proportions correct at the locked gameplay camera?
2. Does the physical-left mechanical arm remain readable?
3. Does the default silhouette still read as Vesper?
4. Does body masking prevent visible clipping while walking?
5. Does switching among states 1, 2, and 3 work in the Godot review scene?

## Next scheduled production stage

After approval of proportions and live equipment swapping:

1. Refine the head and face into Vesper's production identity.
2. Refine the base-body hands, neck transitions, and anatomical silhouette where visible.
3. Give the default outfit authored garment topology and final seams, closures, wear, and material breakup.
4. Create production PBR textures with neutral albedo.
5. Keep cyan/magenta atmosphere in Godot lights and effects.
6. Add at least one genuinely different equipment item for a real swap proof, not merely hidden default pieces.
7. Validate every equipment item through idle, walk, turning, and all locked gameplay camera views.
8. Only after user approval, create a replacement candidate for the live player scene.

## Files that must remain untouched

Unless the user explicitly authorizes integration, do not replace or edit:

```text
scenes/characters/player/VesperKane_PlayerCharacter_v01.tscn
main.tscn
main.gd
Claude-owned gameplay scripts
```

The modular review remains isolated so character work cannot break the active gameplay branch.

## Project direction lock

Steamtek is a hybrid 2.5D game:

- fixed orthographic camera;
- approximately 60-degree azimuth and 30-degree elevation;
- live 3D characters and skeletal animation;
- modular 3D or 2.5D environment presentation where appropriate;
- modern neo-industrial/neo-punk surface;
- neutral assets lit at runtime with amber, cyan, and magenta;
- no Victorian-city drift;
- no cyan/magenta atmosphere baked into environment textures;
- no dynamic camera rotation planned.

The playable opening remains:

```text
Apartment interior
-> exterior apartment building
-> narrow rainy service alley
-> short straight street
-> Brass Lantern bar
-> manhole/lift descent
-> silo
```

The surface is deliberately tiny. Almost the entire game takes place underground.

## Working preferences

- Finish coherent batches before reporting.
- Avoid rework and temporary systems when the production-safe method is known.
- Preserve rollback sources before replacement.
- Keep instructions click-by-click when the user is operating Godot.
- Validate runtime behavior, not merely imports and file existence.
- Do not declare a visual or animation fixed until the user sees it in motion.
- Store tools, manifests, reviews, and handoffs inside the repository for multi-PC work.

## Definition of done for the modular Vesper stage

This stage is ready for user review because:

- the original working player was preserved;
- the modular GLB imports successfully;
- the skeleton and actions are present;
- the base body and outfit are independently addressable;
- three visibility/loadout states produce distinct verified results;
- the isolated playtest runs without scene or script errors;
- Blender source, export, contract, scripts, manifests, and reviews are all stored with the project.

Final visual approval is still pending.

