extends Node

# ============================================================
# SteamtekLive3DProgressStore -- autoload singleton
# ============================================================
# Real, on-disk persistence for the Live3D pipeline's per-scene progress
# dictionaries (steamtek_apartment.gd's crate/inventory/quest state,
# steamtek_lantern_playable_3d.gd's tutorial_state, and any future
# SteamtekTransitionLevel3D subclass). Replaces the old
# get_tree().root.set_meta()/get_meta() pattern, which only lived in
# RAM and was wiped by any process restart (editor Stop/Play, F8 quit
# + relaunch, a packaged build closing) -- exactly the bug reported:
# looted crate items vanishing because they were never written anywhere
# durable.
#
# Every scene keeps its own top-level key (the same string it used to
# pass to get_meta/set_meta, e.g. "steamtek_apartment_progress"), all
# stored together in one JSON file so there's a single load/save point.
#
# Setup required once in the Godot editor:
#   Project Settings -> Autoload -> add this file, Node Name
#   "SteamtekLive3DProgressStore"
# ============================================================

const SAVE_PATH := "user://steamtek_live3d_progress.json"

var _cache: Dictionary = {}
var _loaded := false


func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(SAVE_PATH):
		_cache = {}
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SteamtekLive3DProgressStore: could not open %s for reading" % SAVE_PATH)
		_cache = {}
		return
	var text = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	_cache = parsed if parsed is Dictionary else {}


# Returns a fresh copy of the named scene's saved progress, or an empty
# Dictionary if nothing has been saved for it yet.
func get_progress(key: String) -> Dictionary:
	_ensure_loaded()
	var stored: Variant = _cache.get(key, {})
	return (stored as Dictionary).duplicate(true) if stored is Dictionary else {}


# Writes the named scene's progress and immediately flushes the whole
# store to disk. Called every time a scene's own _save_progress() is
# called (item taken/stored, quest flag set, etc.) -- infrequent enough
# in practice that writing the full file each time is simplest and safe
# against a mid-session crash losing more than the last action.
func save_progress(key: String, data: Dictionary) -> void:
	_ensure_loaded()
	_cache[key] = data.duplicate(true)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SteamtekLive3DProgressStore: could not open %s for writing -- progress not saved" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_cache))
	file.close()
