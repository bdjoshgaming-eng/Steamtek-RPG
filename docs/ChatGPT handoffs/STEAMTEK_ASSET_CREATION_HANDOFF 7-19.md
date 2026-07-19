# STEAMTEK ASSET CREATION HANDOFF

## Purpose

This handoff consolidates the full Steamtek asset-creation workflow developed in this conversation so work can continue on another computer or in another ChatGPT/GPT Work session without losing decisions, standards, or current progress.

---

# 1. STEAMTEK MASTER ART DIRECTION

## Core Style Mix

Use this default visual balance for all Steamtek assets:

- **40% cyberpunk**
- **20% neo-industrial**
- **20% modern steampunk**
- **20% Arcane-inspired painterly treatment**

## Core Identity

Steamtek is a gritty, hand-painted, stylized neo-industrial cyberpunk world with modern steam-tech mechanics and an Arcane-inspired painterly finish.

The world should feel:

- Industrial
- Mechanical
- Moody
- Lived-in
- Colorful
- Slightly cinematic
- Grounded in functional construction
- Visually energized by neon and emissive technology

## Neon Direction

Neon should be:

> Clearly visible and identity-defining, but balanced.

It should sit between subtle and prominent.

Preferred colors:

- Cyan
- Pink
- Magenta
- Bright green

Good uses:

- Monitor screens
- UI panels
- Status lights
- Emissive strips
- Signage
- Glowing tubes
- Tech seams
- Reflected color on metal and concrete

Avoid making the entire asset glow or allowing neon to overpower the industrial structure.

## Material Direction

Use:

- Gunmetal
- Dark steel
- Worn steel
- Concrete
- Oxidized metal
- Copper
- Brass
- Rubber
- Aged glass
- Industrial plastics
- Worn leather
- Matte painted surfaces

Materials should show chipped paint, grime, edge wear, oil stains, heat discoloration, scuffs, patched panels, and maintenance history.

## Shape Language

Use blocky industrial shapes, sturdy proportions, layered panels, armored housings, reinforced corners, functional details, believable thickness, and clear gameplay-readable silhouettes.

## Hard Avoids

Do not use:

- Victorian ornamentation
- Top hats
- Corsets
- Monocles
- Decorative gears
- Ornate filigree
- Old London styling
- Fantasy tavern aesthetics
- Brass overload
- Clean sterile white sci-fi
- Fully neon-saturated nightclub visuals

## One-Line Canon

> Steamtek is gritty hand-painted industrial cyberpunk with balanced cyan, pink, magenta, and bright-green neon, modern steam-tech mechanics, and an Arcane-inspired painterly finish, with no Victorian ornamentation.

---

# 2. ASSET CREATION PIPELINE

```text
ChatGPT / GPT image generation
→ clean orthographic asset views
→ Meshy Agent or Multi-view
→ retopology / remesh in Meshy
→ optimized GLB
→ GPT Work Godot plugin pipeline
→ automated Blender/DCC processing
→ QA
→ Production GLB
→ Godot
```

## This Chat / Image Generation

Use for concept design, Steamtek style enforcement, orthographic views, dimensions, geometry notes, material planning, Meshy prompts, GPT Work prompts, and color/texture direction.

## Meshy

Use for image-to-3D or Multi-view generation, Agent prompt control, initial texturing, remeshing, polygon reduction, and GLB export.

## GPT Work

Use for automated Blender/DCC processing, scale normalization, origin/orientation fixes, geometry QA, normals/material checks, collision generation, production GLB export, Godot scene creation, and QA reports.

---

# 3. MESHY REFERENCE IMAGE RULES

Prefer five clean, separate views:

1. Front
2. Back
3. Left
4. Right
5. Top

Each image should contain one isolated asset, orthographic or nearly orthographic, with the exact same design, neutral gray background, even lighting, no cast shadow, no floor plane, no arrows, labels, human silhouette, notes, environment, or extra props.

Do not upload a full multi-view presentation sheet as one Meshy image.

Use the front image as the main image, back/left/right as Multi-view references, and top if supported or needed.

---

# 4. GEOMETRY RULES

## Geometry Should Carry

- Overall silhouette
- Structural frames
- Large panels
- Handles
- Monitor housings
- Major pipes
- Valves
- Large cables
- Hinges
- Components affecting collision or interaction

## Texture Should Carry

- Scratches
- Rust
- Grime
- Labels
- Paint chips
- Small bolts
- Fine seams
- Brushwork
- Minor dents

## Standard Geometry Requirements

```text
- Use readable hard-surface forms.
- Use believable thickness.
- Keep modular boundaries clean.
- Avoid floating fragments.
- Avoid unnecessary hidden interior geometry.
- Avoid over-modeling scratches and surface wear.
- Preserve moving or separable parts as distinct geometry when required.
- Keep all floor-contact points aligned.
```

---

# 5. DIMENSION AND SCALE RULES

```text
1 Godot unit = 1 meter
```

Default orientation:

- Y-up
- Forward direction according to project convention
- Bottom-center origin
- Ground contact at floor level

GPT Work may recommend dimensions for generic standalone props and clutter. The user/project should define dimensions for doors, walls, floors, modular architecture, stairs, planned furniture, character equipment, gameplay-critical props, cover objects, and interactables.

---

# 6. COUCH ASSET WORKFLOW AND RESULT

## Asset

```text
STK_PROP_Couch_A
```

A clean five-view reference was created with two red leather seat cushions, two red leather back cushions, dark armored metal frame, copper accents, asymmetrical side details, one side vent, and a clean gray background.

## Meshy Outcome

The initial Multi-view result was usable but too soft and generic. Meshy Agent produced a much stronger Steamtek result with preserved hard-surface frame, red leather cushions, dark gunmetal base, copper trim, and cyber-industrial identity.

High-resolution source was approximately:

```text
488,264 faces
258,703 vertices
```

Accepted remeshed result:

```text
9,444 faces
10,314 vertices
```

## Couch Target Dimensions

```text
Width: 2.10 m
Depth: 0.90 m
Height: 0.90 m
Origin: Bottom center
```

## Couch Export Rule

```text
Format: GLB
Resize: On
Height: 0.90 m
Origin: Bottom
```

## Couch GPT Work Prompt

```text
Process this static Steamtek prop through the validated asset pipeline.

Source:
STK_PROP_Couch_A_Meshy.glb

Asset name:
STK_PROP_Couch_A

Asset type:
Static environment prop / furniture

Target dimensions:
Width: approximately 2.10 m
Depth: approximately 0.90 m
Height: 0.90 m

Scale standard:
1 Godot unit = 1 meter

Requirements:
- Preserve textures and UVs.
- Preserve the couch silhouette and hard-surface frame details.
- Verify geometry and manifold quality where practical.
- Remove floating fragments, duplicate geometry, and unnecessary hidden geometry.
- Verify normals and material assignments.
- Keep the optimized mesh near 9,444 triangles unless corrections require minor changes.
- Set the asset origin/pivot to bottom center.
- Place floor-contact points at ground level.
- Apply transforms.
- No rig or animations.
- Generate simple static collision.
- Use simplified box-based collision rather than the detailed render mesh.
- Export a validated production GLB.
- Generate a QA report.

Output:
STK_PROP_Couch_A_Production.glb
STK_PROP_Couch_A_QA.md
```

---

# 7. COMPUTER DESK / WORKSTATION ASSET

## Asset Name

```text
STK_PROP_Workstation_A
```

## Intended Design

- Heavy lower cabinet pedestals
- Open center leg space
- Thick industrial desktop
- Overhead gantry
- Multiple rugged monitors
- Integrated keyboard/control surface
- Dark gunmetal construction
- Cyan, pink, magenta, and green emissives
- Limited copper/brass accents

## Initial Problem

The first Meshy Agent result had too much steampunk influence: excessive brass pipes, large valve wheels, pressure cylinders, vintage lamp, cups/clutter, too much copper, and a workshop feel rather than a cyberpunk workstation.

## Corrected Style Rule

> Cyberpunk workstation first, neo-industrial second, with restrained functional steam-tech support.

Not:

> Steampunk workshop upgraded with screens.

## Revised Meshy Agent Prompt

```text
Create one complete static Steamtek computer workstation from the uploaded orthographic reference images.

STYLE PRIORITY:
The asset must read clearly as cyberpunk first.

Style balance:
40% cyberpunk
20% neo-industrial
20% modern steampunk
20% Arcane-inspired painterly finish

CYBERPUNK DIRECTION:
- Dark gunmetal and charcoal industrial construction
- Multiple rugged digital monitors
- Cyan, pink, magenta, and bright-green emissive displays
- Integrated control panels
- Clean cable routing
- Futuristic technical housings
- Strong cyberpunk silhouette and visual identity

NEO-INDUSTRIAL DIRECTION:
- Heavy steel cabinets
- Thick work surface
- Reinforced corners
- Utility panels
- Vents
- Structural gantry
- Functional, believable construction

MODERN STEAMPUNK DIRECTION:
Use only restrained functional steam-tech details:
- One or two small copper pipes
- One compact pressure regulator
- Limited brass fittings
- No decorative steam components

REMOVE OR AVOID:
- No large valve wheels
- No vintage desk lamp
- No decorative brass pipe networks
- No pressure cylinders used as focal points
- No cups, tools, loose clutter, or extra props
- No decorative gears
- No Victorian ornamentation
- No excessive copper trim
- No old-fashioned machinery styling

GEOMETRY:
- Two lower cabinet pedestals
- Open center leg space
- Thick industrial desktop
- Overhead gantry
- Two or three separate monitor housings
- Distinct monitor support arms
- Central control module
- Simplified rear conduits
- Flat base with aligned feet
- Hard-surface paneling with clear readable forms

MATERIALS:
- Dominant dark gunmetal and worn steel
- Limited copper and brass accents
- Dark industrial plastic and rubber
- Emissive cyan, pink, magenta, and bright green
- Painterly hand-finished game-art texture treatment

IMPORTANT:
The workstation must feel like a cyberpunk computer station with subtle steam-tech engineering, not a steampunk workshop.
```

## Accepted Final Meshy Result

```text
Faces: 17,925
Vertices: 23,515
```

Accepted because cyberpunk reads first, gunmetal dominates, neon balance is correct, large valves/excessive brass are removed, screens and gantry carry the identity, open center leg space is preserved, and lower cabinets are cleaner and reusable.

## Workstation Target Dimensions

```text
Width: 2.10 m
Depth: 0.85 m
Overall height: 1.50 m
Target work-surface height: approximately 0.80 m
```

## Meshy Export Settings

```text
Resize: On
Overall height: 1.50 m
Origin: Bottom
Format: GLB
```

Source filename:

```text
STK_PROP_Workstation_A_Meshy.glb
```

---

# 8. FINAL GPT WORK PROMPT FOR WORKSTATION

```text
Process this Meshy-generated Steamtek workstation through the validated static-prop pipeline for Godot.

SOURCE ASSET
- Source file: [attach or select the downloaded Meshy GLB]
- Asset name: STK_PROP_Workstation_A
- Asset type: Static environment prop
- Current topology: approximately 17,925 triangles
- No rig
- No animation

ART DIRECTION
Steamtek style:
- 40% cyberpunk
- 20% neo-industrial
- 20% modern steampunk
- 20% Arcane-inspired painterly finish

Preserve:
- Dark gunmetal and industrial steel construction
- Cyan, pink, magenta, and bright-green emissive accents
- Three monitor housings
- Monitor support arms
- Integrated keyboard/control surface
- Overhead gantry
- Open center leg space
- Lower cabinet pedestals
- Limited functional conduit details

Do not add:
- Victorian ornamentation
- Decorative gears
- Large valve wheels
- Extra brass pipe networks
- Cups, lamps, tools, or loose clutter
- Additional screens or props

TARGET DIMENSIONS
Use metric scale:
- Width: 2.10 meters
- Depth: 0.85 meters
- Overall height: 1.50 meters
- Target work-surface height: approximately 0.80 meters
- 1 Godot unit = 1 meter

GEOMETRY QA
- Preserve the current silhouette and approximately 18k triangle budget.
- Do not perform another aggressive remesh unless required to repair invalid geometry.
- Remove floating fragments, duplicate faces, isolated vertices, and hidden debris.
- Remove unnecessary internal geometry only where safe.
- Check for non-manifold geometry and repair practical issues.
- Verify face normals and recalculate incorrect normals.
- Preserve the monitors, arms, gantry, keyboard, cabinet forms, and open leg space.
- Maintain readable hard-surface edges.
- Do not smooth or collapse the industrial panel shapes.
- Apply all object transforms.

ORIGIN AND ORIENTATION
- Place all floor-contact points on the ground plane.
- Set the origin/pivot to the bottom center of the complete workstation.
- Use the project’s established Godot forward orientation.
- Confirm the model imports upright and faces the intended direction.

MATERIALS AND TEXTURES
- Preserve the source UVs and textures.
- Preserve the hand-painted texture treatment.
- Verify base color, normal, roughness, metallic, and emission maps.
- Confirm that the cyan, pink, magenta, and green areas use emission appropriately.
- Keep gunmetal and dark steel as the dominant materials.
- Keep copper/brass limited to supporting accents.
- Correct broken texture paths or material assignments.
- Avoid excessive gloss on the desk body.
- Ensure monitor screens remain readable in Godot.

COLLISION
Create simplified static collision. Do not use the detailed render mesh as collision.

Recommended collision arrangement:
- One box or convex shape for the left cabinet pedestal
- One box or convex shape for the right cabinet pedestal
- One thin box for the desktop
- One simplified box or convex shape for the overhead gantry
- Optional simplified shapes for monitor assemblies only if needed for gameplay

Keep the open center leg space open in the collision.

GODOT OUTPUT
Create:
- STK_PROP_Workstation_A_Production.glb
- STK_PROP_Workstation_A.tscn
- STK_PROP_Workstation_A_QA.md

The Godot scene should:
- Use the validated production GLB
- Include the simplified static collision
- Be ready to instance as an apartment or interior environment prop
- Use a StaticBody3D-based setup where appropriate
- Preserve the bottom-center placement origin
- Contain no cameras, lights, animation players, or unused nodes

QA REPORT
Report:
- Final dimensions
- Final triangle and vertex count
- Material count
- Texture maps found
- Whether emission imported correctly
- Normal and manifold checks
- Collision shape count and type
- Origin and ground-contact validation
- Any repairs performed
- Any remaining warnings

Do not place the raw source GLB directly into the final production asset folder. Keep it as an intake/source file and export a validated production GLB.
```

---

# 9. STATIC PROP FORMAT RULE

```text
Characters, rigs, animations:
FBX intake → Blender/GPT Work → Production GLB → Godot

Static props and environment assets:
GLB intake → GPT Work automated DCC pipeline → Production GLB → Godot
```

The validated final Godot asset should generally be GLB.

---

# 10. TRIANGLE GUIDELINES

| Asset type | Triangle range |
|---|---:|
| Tiny clutter | 300–1,500 |
| Standard prop | 1,500–6,000 |
| Large furniture/machinery | 5,000–12,000 |
| Hero environment prop | 10,000–25,000 |
| Modular wall/floor | 500–4,000 |
| Simple pipe section | 300–2,000 |
| Weapon | 5,000–15,000 |
| Main character | 12,000–20,000 |

Accepted examples:

- Couch: ~9.4k triangles
- Workstation: ~17.9k triangles

---

# 11. COLLISION RULES

Do not use detailed render meshes as collision.

## Couch

Suggested:

- Base box
- Backrest box
- Left arm box
- Right arm box

## Workstation

Suggested:

- Left cabinet pedestal
- Right cabinet pedestal
- Desktop
- Gantry
- Optional monitor proxies only if needed

Preserve open leg spaces.

---

# 12. CURRENT PROJECT STATUS

## Completed

- Steamtek master style updated and finalized
- Neon balance finalized
- `STEAMPUNK_STYLE_MEMORY.md` created
- Couch successfully generated in Meshy
- Couch successfully reduced to game-appropriate topology
- Couch GLB workflow defined
- Workstation five-view concept generated
- Workstation Meshy Agent prompts developed
- Workstation style corrected from too-steampunk to cyberpunk-first
- Workstation reduced to ~17,925 faces
- Final GPT Work production prompt created

## Immediate Next Step

Take:

```text
STK_PROP_Workstation_A_Meshy.glb
```

and run it through GPT Work using the final workstation prompt in Section 8.

---

# 13. MASTER SHORT PROMPTS

## Short Steamtek Asset Prompt

```text
Steamtek style: 40% cyberpunk, 20% neo-industrial, 20% modern steampunk, and 20% Arcane-inspired painterly treatment. Use a gritty, hand-painted, stylized game-art look. Industrial materials should remain dominant: gunmetal, steel, concrete, copper, brass, vents, pipes, valves, pressure-tech details, and practical machinery. Neon accents in cyan, pink, magenta, and bright green should be clearly visible and important, but balanced rather than overwhelming. Avoid Victorian ornamentation, decorative gears, and sterile sci-fi minimalism.
```

## Meshy-Friendly Steamtek Prompt

```text
Create a Steamtek asset using a 40% cyberpunk, 20% neo-industrial, 20% modern steampunk, and 20% Arcane-inspired painterly style. The asset should be functional, industrial, and game-readable, with grounded construction and a strong silhouette. Use materials such as gunmetal, worn steel, concrete, copper, brass, rubber, leather, and industrial plastics. Include balanced neon accents in cyan, pink, magenta, and bright green through emissive details, status lights, panels, or small glowing elements. Add restrained modern steam-tech flavor through limited pipes, valves, and pressure components, but avoid Victorian ornamentation and decorative gears. Keep the design practical, rugged, cyberpunk-first, and visually clear.
```

---

# 14. FILES CREATED DURING THIS CONVERSATION

Reusable style file:

```text
STEAMPUNK_STYLE_MEMORY.md
```

This should be supplied to future GPT Work or ChatGPT sessions when needed.

---

# END OF HANDOFF
