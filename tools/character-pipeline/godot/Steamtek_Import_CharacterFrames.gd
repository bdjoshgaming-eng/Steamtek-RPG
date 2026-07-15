@tool
extends EditorScript

## Configure these project-relative paths, then run this EditorScript.
const CHARACTER_ID := "Steamtek_CXXX"
const ANIMATION := "walk"
const FRAMES_ROOT := "res://assets/characters/Steamtek_CXXX/production/walk"
const OUTPUT_RESOURCE := "res://assets/characters/Steamtek_CXXX/godot/Steamtek_CXXX_WalkFrames.tres"
const FPS := 8.0
const DIRECTIONS := [
	"south", "south_west", "west", "north_west",
	"north", "north_east", "east", "south_east"
]


func _run() -> void:
	var result := import_frames(FRAMES_ROOT, OUTPUT_RESOURCE, ANIMATION, FPS)
	if result != OK:
		push_error("Steamtek frame import failed with code %s" % result)
	else:
		print("Steamtek SpriteFrames saved: %s" % OUTPUT_RESOURCE)


func import_frames(frames_root: String, output_path: String, animation: String, fps: float) -> Error:
	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")

	for direction in DIRECTIONS:
		var animation_name := StringName("%s_%s" % [animation, direction])
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, fps)
		sprite_frames.set_animation_loop(animation_name, true)
		var directory_path := "%s/%s" % [frames_root, direction]
		var directory := DirAccess.open(directory_path)
		if directory == null:
			push_error("Missing direction folder: %s" % directory_path)
			return ERR_FILE_NOT_FOUND
		var files := PackedStringArray()
		directory.list_dir_begin()
		var file_name := directory.get_next()
		while file_name != "":
			if not directory.current_is_dir() and file_name.to_lower().ends_with(".png"):
				files.append(file_name)
			file_name = directory.get_next()
		directory.list_dir_end()
		files.sort()
		if files.is_empty():
			push_error("No PNG frames: %s" % directory_path)
			return ERR_FILE_NOT_FOUND
		for frame_file in files:
			var texture := load("%s/%s" % [directory_path, frame_file]) as Texture2D
			if texture == null:
				return ERR_CANT_OPEN
			sprite_frames.add_frame(animation_name, texture)

	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	return ResourceSaver.save(sprite_frames, output_path)
