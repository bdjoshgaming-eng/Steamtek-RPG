# Steamtek Humanoid Character 3D Template v1

## Purpose

This scene packages any compatible Steamtek humanoid GLB into a reusable production character without repeating collision, movement, facing, animation lookup, or anchor setup.

## Shared node contract

- `CharacterBody3D` root on Player layer 2, masking World layer 1.
- Capsule body collision aligned to the approved humanoid scale.
- `VisualPivot` applies the locked +40-degree model-forward correction during movement.
- `InteractionOrigin` follows the character's visual facing.
- `CameraTarget` provides a stable follow/look-at anchor.
- `GroundContact` marks the authored foot plane.
- `AudioStreamPlayer3D` provides a standard character audio origin.
- Shared runtime lookup and looping for `STK_IDLE` and `STK_WALK`.
- `InteractionDetector` automatically finds nearby layer-4 `Area3D` interactables.
- The player owns the single `interact` input handler and selects the nearest valid target.

## 3D interaction contract

An interactable uses collision layer 4 (`collision_layer = 8`) and provides:

- `can_interact(actor) -> bool`
- `get_interaction_prompt() -> String`
- `interact(actor) -> void`

Extend `SteamtekInteractable3D` for standard behavior. The player emits
`interaction_focus_changed` for UI prompts and `interaction_performed` after activation.

## Vesper production scene

Use `res://scenes/characters/player/VesperKane_PlayerCharacter_v01.tscn`.

This scene references Production Appearance v1 and is ready to be instanced into a 3D gameplay level. It does not replace the current player or modify the main scene.

## Future humanoids

Duplicate the Vesper character scene, assign another compatible GLB to `character_scene`, change `character_instance_name`, and keep the shared template unchanged.
