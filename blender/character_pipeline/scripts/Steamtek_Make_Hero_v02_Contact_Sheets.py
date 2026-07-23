from pathlib import Path

from PIL import Image, ImageDraw


folder = Path(
    r"C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\review_v02_walk_cycle"
)
target = (320, 320)

for pattern, output_name in (
    ("stk_walk_*.png", "STK_WALK_v02_contact_sheet.jpg"),
    ("stk_run_*.png", "STK_RUN_v02_contact_sheet.jpg"),
):
    paths = sorted(folder.glob(pattern))
    sheet = Image.new(
        "RGB",
        (target[0] * 3, target[1] * 3 + 72),
        (28, 28, 28),
    )
    draw = ImageDraw.Draw(sheet)

    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGB").resize(target)
        x = (index % 3) * target[0]
        y = (index // 3) * (target[1] + 24)
        sheet.paste(image, (x, y))
        draw.text((x + 6, y + target[1] + 4), path.stem, fill=(255, 255, 255))

    sheet.save(folder / output_name, quality=94)


angle_folder = Path(
    r"C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\review_v02_angles"
)
angle_paths = sorted(angle_folder.glob("*.png"))
angle_sheet = Image.new("RGB", (320 * 4, 320 * 2), (28, 28, 28))

for index, path in enumerate(angle_paths):
    image = Image.open(path).convert("RGB").resize((320, 320))
    angle_sheet.paste(image, ((index % 4) * 320, (index // 4) * 320))

angle_sheet.save(angle_folder / "STK_v02_angle_contact_sheet.jpg", quality=94)


solid_folder = Path(
    r"C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\review_v03_solid"
)
solid_paths = sorted(solid_folder.glob("*.png"))
solid_sheet = Image.new("RGB", (320 * 3, 320 * 3), (28, 28, 28))

for index, path in enumerate(solid_paths):
    image = Image.open(path).convert("RGB").resize((320, 320))
    solid_sheet.paste(image, ((index % 3) * 320, (index // 3) * 320))

solid_sheet.save(solid_folder / "STK_WALK_v03_solid_contact_sheet.jpg", quality=94)


solid_v04_folder = Path(
    r"C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\review_v04_solid"
)
for pattern, output_name in (
    ("stk_walk_*.png", "STK_WALK_v04_solid_contact_sheet.jpg"),
    ("stk_run_*.png", "STK_RUN_v04_solid_contact_sheet.jpg"),
):
    solid_v04_paths = sorted(solid_v04_folder.glob(pattern))
    solid_v04_sheet = Image.new("RGB", (320 * 3, 320 * 3), (28, 28, 28))

    for index, path in enumerate(solid_v04_paths):
        image = Image.open(path).convert("RGB").resize((320, 320))
        solid_v04_sheet.paste(image, ((index % 3) * 320, (index // 3) * 320))

    solid_v04_sheet.save(solid_v04_folder / output_name, quality=94)
