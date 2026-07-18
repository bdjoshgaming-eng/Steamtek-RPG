# Steamtek Live-3D Graphics Direction Addendum

Date: 2026-07-17

Status: locked visual guidance for current live-3D environment production

This addendum supplements the existing holistic Steamtek surface-world
reference. It refines rendering character, color balance, atmosphere, and
material readability. It does not replace the dimensional scale, camera,
geometry, snap, pivot, collision, or C001 contracts.

## Added references

- `Steamtek_GraphicsDirection_PainterlyNeoIndustrial_Reference_A_2026-07-17.png`
  establishes the brighter painterly side of the target: readable brick and
  masonry, softened stylized forms, violet atmosphere, warm practical lamps,
  vivid cyan/magenta commercial light, steam, wet cobbles, and bold puddle
  reflections.
- `Steamtek_GraphicsDirection_WetBarDistrict_Reference_B_2026-07-17.png`
  establishes the denser neo-industrial side: dark but readable construction,
  heavy utility piping, restrained signage, source-linked amber/cyan/magenta
  lighting, saturated wet-street reflections, and a strong bar entrance focal
  hierarchy.
- `Steamtek_GraphicsDirection_DarkPanelBuildings_Reference_C_2026-07-17.png`
  is the primary building-material reference. It establishes dark panelized
  gunmetal and blackened-steel construction, squared modern-industrial
  massing, large warm-lit windows, integrated utility frames, rooftop
  equipment, pipes, vents, restrained colored accents, and wet street context.

Neither image is a structure to copy. They are holistic graphical references.

## Combined target

- Live 3D geometry with a high-fidelity painterly material treatment.
- The default building body is dark panelized neo-industrial construction,
  not predominantly red brick.
- Dark industrial construction remains readable instead of collapsing to
  featureless black.
- Saturated color comes from visible signs, windows, lamps, machinery, and
  their rain-wet reflections.
- Warm amber practical lighting balances cyan, magenta, pink, violet, and blue.
- Wet paving, pooled water, irregular water film, and convincing reflections
  are primary visual features rather than minor polish.
- Pipes, vents, roof equipment, steam, utilities, trims, and repairs create
  functional density without Victorian gears or ornamental steampunk drift.
- Buildings must work on both street axes. Reusable live-3D modules rotate in
  90-degree Y increments; asymmetrical or text-bearing parts receive authored
  handed variants instead of negative-scale mirroring.

## Approved tile direction

The user explicitly liked the current rain-polished street tiles shown on
2026-07-17:

- Texture: `STK_MAT_RainPolishedStreet_Albedo_Candidate_v03.png`
- Material: `STK_MAT_RainPolishedStreet_Candidate_v01.tres`
- Current triplanar scale: `Vector3(0.24, 0.24, 0.24)`

This locks the tile size and material character as an approved art-direction
candidate. Production promotion still requires a larger repeated surface test,
source-linked wet lighting, and gameplay-scale review. Do not silently replace
or rescale it.

## Brick placeholder decision

The current `STK_MAT_RainAgedBrick_Candidate_v01.tres` may remain in the
isolated material review as a temporary placeholder. The user explicitly said
to move forward because it is a placeholder. It is not the final building
material direction and must not override Reference C. Do not spend additional
production time repairing or promoting the brick unless the user later asks.

## Avoid

- Flat blockout materials presented as final artwork
- Predominantly red-brick buildings treated as the default district language
- Uniform gray or nearly black scenery with no readable material separation
- Generic glossy showroom 3D
- Colored lighting baked permanently into reusable neutral materials
- Neon on every surface with no source or hierarchy
- Fantasy cobblestone, decorative gears, Victorian ornament, or brass-heavy
  steampunk styling
- Copying reference-image architecture as production geometry

## Authority order

1. Locked live-3D scale, camera, C001, and measured environment contracts
2. Current geometry and snap/pivot/collision contracts
3. This graphical addendum and the existing holistic surface reference
4. Individual material and prop candidates after gameplay-scale approval
