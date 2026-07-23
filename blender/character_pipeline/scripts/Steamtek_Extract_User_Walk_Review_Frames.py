import bpy
from pathlib import Path


VIDEO_PATH = Path(
    r"C:\Users\bdjos\AppData\Local\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe"
    r"\TempState\Recordings\20260723-1556-36.4702860.mp4"
)
OUTPUT_DIR = Path(
    r"C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\user_review_video"
)


OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

scene = bpy.context.scene
scene.sequence_editor_clear()
sequence_editor = scene.sequence_editor_create()
strips = getattr(sequence_editor, "strips", None)
if strips is None:
    strips = sequence_editor.sequences

movie = strips.new_movie(
    name="UserWalkReview",
    filepath=str(VIDEO_PATH),
    channel=1,
    frame_start=1,
)

width = movie.elements[0].orig_width
height = movie.elements[0].orig_height
duration = movie.frame_final_duration
first_frame = movie.frame_final_start
last_frame = movie.frame_final_end - 1

scene.render.resolution_x = width
scene.render.resolution_y = height
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.use_file_extension = True
scene.render.film_transparent = False
scene.render.use_sequencer = True

sample_count = min(12, duration)
if sample_count <= 1:
    sample_frames = [first_frame]
else:
    sample_frames = [
        round(first_frame + index * (last_frame - first_frame) / (sample_count - 1))
        for index in range(sample_count)
    ]

for index, frame in enumerate(sample_frames):
    scene.frame_set(frame)
    scene.render.filepath = str(OUTPUT_DIR / f"walk_review_{index:02d}_frame_{frame:04d}.png")
    bpy.ops.render.render(write_still=True)

print(f"VIDEO_WIDTH={width}")
print(f"VIDEO_HEIGHT={height}")
print(f"VIDEO_DURATION_FRAMES={duration}")
print(f"VIDEO_FIRST_FRAME={first_frame}")
print(f"VIDEO_LAST_FRAME={last_frame}")
print("SAMPLED_FRAMES=" + ",".join(str(frame) for frame in sample_frames))
