STEAMTEK GROUND ATLASES — FINAL

TileSet configuration
---------------------
Tile Shape:       Isometric
Tile Layout:      Diamond Down
Tile Offset Axis: Horizontal
Tile Size:        256 x 128
Atlas Region:     256 x 128
TileMapLayer:     Scale 1,1

Files
-----
G001_WetConcrete_Atlas_8x1.png
  8 walkable concrete variants. Use for randomized base ground.

G002_DrainGrate_Special_1x1.png
  1 special drain tile. Paint sparingly over the ground layout.

G003_SteelPlate_Atlas_4x1.png
  4 steel plate orientations.

G004_HazardStripes_Special_1x1.png
  1 special hazard marker tile.

G005_PuddleReflections_Atlas_8x1.png
  8 reflection orientations and subtle tonal variants.

Godot installation
------------------
1. Remove the five temporary single-tile atlas sources if desired.
2. Drag each PNG into TileSet > Tile Sources.
3. Choose "Create tiles automatically."
4. Verify G001 and G005 create 8 cells, G003 creates 4 cells,
   and G002/G004 create 1 cell each.
5. Paint base floors from G001/G003. Use G002/G004 sparingly.
6. G005 currently replaces the complete ground cell; it is not a
   puddle-only transparent overlay.

QC
--
Every atlas cell is exactly 256 x 128 pixels.
No chroma-green pixels remain.
Every tile has transparent corners and a full 2:1 diamond footprint.
