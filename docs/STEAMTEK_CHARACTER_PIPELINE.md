# Steamtek Character Pipeline v1

This pipeline creates consistent 8-direction 2D character animation from one controlled Blender character.

## Locked production contract

- Blender: 4.5 LTS
- Projection: same locked orthographic viewing direction as Steamtek environments
- Frame canvas: 512 x 512 RGBA
- Transparent film
- Direction rows: south, southwest, west, northwest, north, northeast, east, southeast
- Walk test: 8 frames per direction
- Root: `STK_CharacterRoot`
- Model forward axis: `-Y`
- Boots contact: Blender world `(0,0,0)`
- Godot character root: scale `(1,1)`, rotation `0`
- Standard adult visible height in Godot: 96-104 world units; target 100.5
- Compatibility reference: existing C001 Steamtek Runner at Sprite2D scale 0.09
- Visual intent: Shadowrun-like readability with higher-fidelity pre-rendered materials

The packer measures visible alpha height and writes a suggested internal Sprite2D scale into the JSON metadata. The CharacterBody2D root is never resized. `0.09` remains correct for the existing 1254x1254 C001 source; new fixed-cell sheets receive their own measured internal Visual scale.

## Portable Blender selection

Blender is resolved in this order:

1. `STEAMTEK_BLENDER_EXE` environment variable.
2. Untracked `tools/character-pipeline/blender.local.txt`.
3. Known Blender Foundation installation paths.
4. Latest `blender.exe` found beneath `C:\Program Files\Blender Foundation`.

Home-PC installation currently confirmed:

```text
C:\Program Files\Blender Foundation\Blender 4.5\blender.exe
Blender 4.5.11 LTS
```

On another PC, copy `blender.local.example.txt` to `blender.local.txt` and put that PC's full Blender path inside it. Do not commit `blender.local.txt`.

## Folder tree

```text
blender/character_pipeline
├── master
│   └── Steamtek_CharacterTemplate.blend
└── scripts
    ├── steamtek_character_standard.py
    ├── build_character_template.py
    └── render_character_8dir.py

tools/character-pipeline
├── Build_Character_Template.bat
├── Render_Proxy_Test.bat
├── find_blender.ps1
└── pack_character_sheet.py

assets/characters
└── CHARACTER_ID
    ├── source
    ├── renders
    ├── production
    └── metadata
```

## First validation

1. Run `Build_Character_Template.bat`.
2. Run `Render_Proxy_Test.bat`.
3. Confirm the resulting sheet has 8 rows and 8 columns.
4. Confirm the background is transparent.
5. Confirm each frame remains on the same boots-centered canvas.
6. The launcher generates a Godot 4 `.tres` SpriteFrames resource automatically.
7. The launcher finishes with `CHARACTER PIPELINE QA PASSED` or stops on failure.

The proxy is an engineering test, not final Steamtek art.

## Replacing the proxy with a real character

1. Open `Steamtek_CharacterTemplate.blend`.
2. Import the modeled and rigged character.
3. Parent the entire rig/model to `STK_CharacterRoot`.
4. Make the character face Blender `-Y` when rotation Z is zero.
5. Place the lowest boot contact at world Z = 0.
6. Remove or hide the `STK_Proxy_*` objects from rendering.
7. Assign the walk action and set the action frame range.
8. Save a character-specific `.blend` file; do not overwrite the template.
9. Render all directions with `render_character_8dir.py`.
10. Pack the frames with `pack_character_sheet.py`.

## Godot scene target

```text
C001_CharacterName (CharacterBody2D)
├── Visual (AnimatedSprite2D)
├── FeetCollision (CollisionShape2D)
└── AnimationTree                         [optional later]
```

The production importer must use the JSON row order and cell size. All directions share identical cell dimensions and boots-centered placement.

## One-click production build

Use this for each real modeled, rigged, and animated character:

```bat
tools\character-pipeline\Render_Character.bat "C:\path\Character.blend" C001_Player walk 1 8
```

Arguments are the character `.blend`, character ID, animation name, optional
first frame, and optional last frame. The command automatically:

1. Finds Blender on the current PC.
2. Renders every frame in all eight locked directions.
3. Packs a transparent 8-row atlas.
4. Writes scale and pivot metadata.
5. Creates a Godot 4 `SpriteFrames` `.tres`.
6. Runs the character pipeline QA gate.

Production output is written beneath:

```text
assets/characters/CHARACTER_ID/production/
```

The CharacterBody2D root remains scale `(1,1)`. Apply the suggested visual
scale from the generated JSON to the internal AnimatedSprite2D only.
