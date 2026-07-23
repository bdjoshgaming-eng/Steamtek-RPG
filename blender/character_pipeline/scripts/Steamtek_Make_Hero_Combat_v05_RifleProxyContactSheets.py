from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
SOURCE_DIR = ROOT / "output" / "hero_combat_v05" / "rifle_proxy_review"
OUTPUT_DIR = ROOT / "output" / "hero_combat_v05" / "rifle_proxy_contact_sheets"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

groups = {}
for path in sorted(SOURCE_DIR.glob("STK_RIFLE_*.png")):
    action_name = path.name.rsplit("_", 2)[0]
    groups.setdefault(action_name, []).append(path)

created = []
for action_name, paths in sorted(groups.items()):
    images = [Image.open(path).convert("RGB") for path in paths]
    tile_width = 256
    tile_height = 256
    label_height = 30
    sheet = Image.new(
        "RGB",
        (tile_width * len(images), tile_height + label_height),
        (24, 24, 24),
    )
    draw = ImageDraw.Draw(sheet)
    for index, (image, path) in enumerate(zip(images, paths)):
        image.thumbnail((tile_width, tile_height))
        x = index * tile_width + (tile_width - image.width) // 2
        y = (tile_height - image.height) // 2
        sheet.paste(image, (x, y))
        draw.text(
            (index * tile_width + 6, tile_height + 7),
            path.stem.rsplit("_", 2)[-1],
            fill=(240, 240, 240),
        )
    output = OUTPUT_DIR / f"{action_name}_rifle_proxy_contact_sheet.jpg"
    sheet.save(output, quality=92)
    created.append((action_name, output))
    print(output)

master_width = 1180
label_width = 220
row_height = 214
master = Image.new(
    "RGB",
    (master_width, row_height * len(created)),
    (18, 18, 18),
)
master_draw = ImageDraw.Draw(master)
for row, (action_name, output) in enumerate(created):
    contact = Image.open(output).convert("RGB")
    contact.thumbnail((master_width - label_width, row_height))
    y = row * row_height
    master.paste(contact, (label_width, y))
    master_draw.text((8, y + 12), action_name, fill=(245, 245, 245))

master_path = OUTPUT_DIR / "STK_HERO_Combat_v05_RifleProxy_MasterContactSheet.jpg"
master.save(master_path, quality=92)
print(master_path)
