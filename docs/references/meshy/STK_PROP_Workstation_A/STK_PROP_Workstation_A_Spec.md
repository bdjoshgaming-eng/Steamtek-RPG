# STK_PROP_Workstation_A

## Asset intent

Static Steamtek computer desk/workstation for apartment, workshop, control-room, and industrial-office environments. The core workstation is one game-readable asset. No chair is included. Preserve the supplied integrated desktop controls, keyboard, display hardware, pressure equipment, and visible small workstation components consistently across the reference views.

## Canonical style

- 40% cyberpunk
- 20% neo-industrial
- 20% modern steampunk
- 20% Arcane-inspired painterly finish

Functional, gritty, hand-painted, stylized, and readable at isometric gameplay distance. Neon is identity-defining but balanced. Copper and brass support the design without overwhelming its industrial construction. No Victorian ornamentation or decorative gears.

## Target dimensions

- Overall width: 2.00 m
- Overall depth: 0.85 m
- Overall height: 1.40 m
- Work-surface height: 0.78 m
- Work-surface depth: approximately 0.60 m
- Clear knee bay: approximately 1.00 m wide × 0.65 m high

The overall dimensions include the equipment spine, monitor housings, side cabinets, rear service components, plinth, and feet.

## Orthographic reference requirements

- Front, back, left, right, and top views
- Identical geometry and proportions in every view
- Neutral medium-gray background
- Even neutral lighting
- No perspective distortion
- No cast shadows or floor plane
- Asset centered and fully visible
- Tight framing without cutting off feet, pipes, housings, monitors, or frame
- No chair, loose props, room elements, people, or overlapping text

## Major geometry

- Reinforced dark-steel floor plinth and short recessed feet
- Structural desk frame with believable material thickness
- Thick work surface with armored front edge
- Two grounded side storage/service cabinets
- Clear central knee bay
- Full rear service spine and cable-management housing
- Three separate rugged monitor housings on mechanical mounts
- Central control/interface module
- Upper equipment rail with compact task-light housing
- Restrained copper/brass pressure line
- One functional valve and pressure regulator
- Large ventilation and maintenance panels
- Protected cable conduits and a small number of large readable cables
- Clearly separated access doors, screen faces, and service modules

## Texture-only detail

- Chipped paint
- Localized rust and oxidation
- Grime in recesses
- Worn work-surface edges
- Soot or oil staining
- Faded hazard markings and labels
- Fine panel seams
- Small fasteners and rivets
- Minor dents and scratches
- Painterly brushwork and controlled edge highlights

## Material regions

1. Dark gunmetal and blue-black painted steel: primary frame, cabinets, housings, and service spine.
2. Worn charcoal work surface: matte, scuffed, oil-marked, and practical.
3. Copper/brass: restrained pressure line, regulator, brackets, and service accents.
4. Rubber and industrial plastic: cable sleeves, control surrounds, feet, and protective trim.
5. Aged glass: monitor and interface faces.
6. Emissive accents: cyan primary screens, limited magenta/pink secondary signals, and a very small bright-green status indicator.

Emissive elements must be visibly powered components. Do not add arbitrary glowing trim across every edge.

## Construction requirements

- Genuine three-dimensional geometry on every side
- Complete back, sides, underside, work surface, cabinets, monitor housings, and service spine
- Believable thickness; no paper-thin panels
- No flat cards or billboard monitors
- No floating fragments
- No hidden room or floor geometry
- No deeply recessed details that cannot remain consistent across all views
- Modular floor-contact boundary must remain straight and unobstructed
- Screens and access-panel faces should be separate readable material regions
- Maintain identical geometry and asymmetry in every reference view

## Technical contract

- 1 Godot unit = 1 meter
- Y axis up
- Front faces +Z
- Origin/pivot at bottom center of the floor-contact footprint
- Lowest floor-contact point at Y = 0
- Root scale 1,1,1 after export
- Apply rotation and scale before export
- No rig or animations
- Preserve UVs and material assignments
- Final Blender bounding box: exactly 2.00 × 0.85 × 1.40 m
- Suggested final render-mesh target: 10,000–16,000 triangles after cleanup
- Simplified collision: desk/plinth box, left cabinet box, right cabinet box, rear-spine box, optional upper-equipment box

## Meshy and Blender pipeline notes

Use front, back, left, and right orthographic images for the initial Meshy multi-image reconstruction. Add the top view if a fifth slot is available. Disable animation and character-oriented options. Preserve hard-surface structure and screen placement during generation.

In Blender: remove floating fragments and duplicate internal geometry, repair normals, make manifold where practical, preserve the silhouette and UVs, optimize without erasing large panel breaks, scale to the exact target dimensions, place the pivot at bottom center, generate simple box collision, and validate the exported GLB by reimporting it.

## Game-ready definition

The finished asset must remain readable from Steamtek's locked isometric gameplay camera, retain a strong industrial silhouette, separate powered cyberpunk elements from non-emissive construction, and support placement as an independent modular furniture scene in Godot.
