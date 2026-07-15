# Steamtek Apartment Service Alley Fidelity Brief

Date locked: 2026-07-15

Optional asset-fidelity references:

- `docs/references/Apartment_Service_Alley_Layout_Fidelity_Reference.png`
- `docs/references/NeoIndustrial_Alley_Asset_Fidelity_Reference.png`

These references may inform individual asset fidelity and family coverage. They
do not govern level layout. The level designer chooses the alley location,
direction, width, architecture, lighting, and props in Godot using the modular
builder. Steamtek keeps the approved apartment exterior's blue-black metal
construction, copper details, neo-industrial hardware, and established 2:1
dimetric projection.

The second reference particularly supports future asset families for brick and
metal façade variation, large functional pipe networks, wall-mounted practical
lamps, service doors, vents, signage, drains, puddles, and wet material response.
These are palette targets only; they do not prescribe a finished level layout.

## Correct scope

The asset kit must support service environments without pre-authoring them.
New V4 environments use the locked 60-degree basis: front step
`(313.534, -90.509)`, side step `(-181.020, -156.768)`, and storey rise
`(0, -219)`. The former 256x128/64x32 lattice is legacy-only.

The reusable asset families may include:

- A continuous service lane with useful player and NPC clearance
- Narrow gutters, thresholds, drainage, and building-edge buildup
- Tall façades defining both sides and compressing the view
- Doors, windows, panels, signs, pipes, conduits, vents, and utility boxes
- Crates, barrels, refuse/service clutter, puddles, repairs, and debris zones
- Neutral practical fixtures with cyan, magenta, amber, and emergency colors supplied by Godot lighting
- Rain haze, steam, wet reflections, and controlled distant atmospheric depth

## Fidelity hierarchy

1. Existing apartment exterior establishes architectural language.
2. Large geometry establishes enclosure, depth, and navigation.
3. Pipes, doors, windows, utilities, and signs establish functional density.
4. Ground transitions, drainage, repairs, clutter, and decals establish history.
5. Godot lighting, steam, rain, and reflections bind the scene together.

Do not attempt to reach the target by increasing noise on individual floor
diamonds. Detail must occur at building, corridor, and district scales.

## Modular strategy

- Use the two locked V4 basis vectors for every snap socket and macro assembly.
- Build macro assemblies from exact front-axis and side-axis bay steps.
- Use multi-bay façade runs and utility clusters so detail does not restart on
  every cell.
- Keep all colored lighting, glow, and wet reflection overlays in Godot. Do not bake those colors into base asset PNGs.
- Preserve independent gameplay collision, navigation, interaction, and props.

The macro assembly is reusable layout infrastructure. Blender supplies camera,
geometry, silhouette, masks, pivots, and placement guides. Final neutral 2D
environment art is approved separately and all colored illumination is built
and verified in Godot.
