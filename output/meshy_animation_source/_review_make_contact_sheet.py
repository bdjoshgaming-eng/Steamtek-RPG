import sys
from pathlib import Path

from PIL import Image, ImageDraw


source_dir = Path(sys.argv[1])
output_path = Path(sys.argv[2])
files = sorted(source_dir.glob("sample_*.png"))

columns = 4
rows = (len(files) + columns - 1) // columns
thumb_width = 217
thumb_height = 296
label_height = 24

sheet = Image.new(
    "RGB",
    (columns * thumb_width, rows * (thumb_height + label_height)),
    (28, 28, 28),
)
draw = ImageDraw.Draw(sheet)

for index, file_path in enumerate(files):
    image = Image.open(file_path).convert("RGB")
    image.thumbnail((thumb_width, thumb_height))
    column = index % columns
    row = index // columns
    x = column * thumb_width + (thumb_width - image.width) // 2
    y = row * (thumb_height + label_height)
    sheet.paste(image, (x, y))
    draw.text(
        (column * thumb_width + 5, y + thumb_height + 5),
        file_path.stem,
        fill=(240, 240, 240),
    )

sheet.save(output_path)
print(output_path)
