# Steamtek V4 Graphical Direction Lock

Status: **Approved production direction**  
Approval: User reviewed the playable V4 apartment/alley slice and approved the graphical direction.

## Camera and lattice

- Fixed orthographic 2.5D camera.
- Locked off-axis view: 60 degree azimuth, 30 degree elevation.
- No dynamic camera rotation.
- Lattice Axis A: `Vector2(313.534, -90.509)`.
- Lattice Axis B: `Vector2(-181.020, -156.768)`.
- Storey rise: `Vector2(0, -219)`.
- Placeable scene root scale: `Vector2(1, 1)`.

## Approved material language

- Gritty, functional, lived-in neo-industrial construction.
- Concrete, blackened steel, iron, weathered wood, copper pressure lines, rubber, and dirty glass.
- Surfaces should be less polished and less pristine than the early Surface Kit imagery.
- Technology must look engineered and purposeful.
- No Victorian ornament, decorative gears, fantasy-steampunk styling, top hats, or period architecture.

## Lighting contract

- Base architecture stays neutral.
- Cyan, magenta, and amber color comes from Godot lights and small emission-mask nodes.
- No baked cyan, baked magenta, or baked amber environmental light spill in production sprites.
- Do not bake broad colored light spill into wall, roof, ground, or prop artwork.
- Rain, steam, wetness, and atmospheric light are separate effects whenever practical.

## Modular production contract

- Buildings are assembled from reusable wall, door, window, utility, side-wall, roof, cap, and corner scenes.
- Major pieces remain independently placeable and replaceable.
- Snap markers use the locked Axis A / Axis B / storey-rise values.
- Decorative details inside a module remain grouped; individual bricks and tiny pipes are not separate nodes.
- Buildings may face both supported axis families. Do not fake the second orientation by arbitrarily rotating a finished image.
- Exterior doors zone to separate interior scenes; exterior buildings do not contain their interiors.

## Collision and sorting

- World bodies: collision layer 1, mask 2.
- Player: collision layer 2, mask 1.
- Zone/interact areas: collision layer 16, mask 2.
- Place the player and placeable world objects under one Y-sorted parent.
- Collision follows ground-contact footprints, not the full visible height of artwork.

Any new asset or scene that violates this document requires an explicit art-direction decision before it enters the production library.
