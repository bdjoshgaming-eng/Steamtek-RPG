# Steamtek 3D Zone Transition v0.1

## Purpose

This package proves the production round-trip used by the apartment exterior door:

1. Approach the apartment door.
2. Press **E** when the interaction prompt appears.
3. Fade to black.
4. Load the apartment interior at its named entry spawn.
5. Approach the interior exit and press **E**.
6. Fade back to the exterior at its named return spawn.

The transition code, prompt routing, spawn routing, collision contract, and fade are reusable production infrastructure. The architecture in these two test scenes is deliberately labeled graybox and is not approved Steamtek final art.

## Test scene

Open and run:

`res://scenes/levels/surface_3d/ApartmentExterior_TransitionTest_v01.tscn`

Use **WASD** to move and **E** to interact.

## Installed files

- `res://scenes/interactions/steamtek_zone_door_3d.gd`
- `res://scenes/interactions/SteamtekZoneDoor3D.tscn`
- `res://scenes/levels/transition_tests/steamtek_transition_level_3d.gd`
- `res://scenes/levels/surface_3d/ApartmentExterior_TransitionTest_v01.tscn`
- `res://scenes/levels/apartment_3d/ApartmentInterior_TransitionTest_v01.tscn`
- `res://scenes/characters/validation/validate_apartment_transition_3d.gd`

## Collision standard used

- World geometry and closed door blockers: collision layer 1.
- Vesper: player collision contract already established by the production character scene.
- Interaction zones: collision layer 4 (numeric value 8).
- Door interaction is separate from physical door blocking.
- Exterior facade and interior front wall use split blocking around the doorway.

## Validation result

`APARTMENT_3D_ROUND_TRIP_OK=true`

The existing main scene was not modified.
