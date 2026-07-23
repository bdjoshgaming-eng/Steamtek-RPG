import os
import sys

import bpy


if "--" not in sys.argv:
    raise SystemExit("Expected: -- <video> <output_dir> <frame_count>")

video_path, output_dir, requested_count = sys.argv[sys.argv.index("--") + 1 :]
requested_count = max(2, int(requested_count))
os.makedirs(output_dir, exist_ok=True)

scene = bpy.context.scene
editor = scene.sequence_editor_create()
strips = editor.strips if hasattr(editor, "strips") else editor.sequences
strips.new_movie("review_movie", video_path, channel=1, frame_start=1)

clip = bpy.data.movieclips.load(video_path)
duration = max(1, clip.frame_duration)
width, height = clip.size

scene.render.resolution_x = width
scene.render.resolution_y = height
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.use_file_extension = True
scene.render.film_transparent = False
scene.render.use_sequencer = True

sample_count = min(requested_count, duration)
frames = sorted(
    {
        1 + round(index * (duration - 1) / (sample_count - 1))
        for index in range(sample_count)
    }
)

for sample_number, frame in enumerate(frames, start=1):
    scene.frame_set(frame)
    scene.render.filepath = os.path.join(
        output_dir, f"sample_{sample_number:02d}_frame_{frame:04d}.png"
    )
    bpy.ops.render.render(write_still=True)

print("STK_EXTRACTED_FRAMES", duration, width, height, ",".join(map(str, frames)))
