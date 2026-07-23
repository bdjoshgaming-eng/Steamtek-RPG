extends Node

# ============================================================
# SteamtekLive3DProgressStore -- autoload singleton
# ============================================================
# In-memory-only session state for the Live3D pipeline's per-scene
# progress dictionaries (steamtek_apartment.gd's crate/inventory/quest
# state, steamtek_lantern_playable_3d.gd's tutorial_state, the shared
# global inventory, and the shared global combat state).
#
# Deliberately NOT written to disk -- every launch starts a brand new
# game. It DOES survive scene transitions within one running session,
# because autoloads aren't torn down by change_scene_to_file -- that's
# what keeps items/equipped-weapon/health consistent as the player moves
# between the apartment, lantern, and surface scenes in a single sitting.
#
# Setup required once in the Godot editor:
#   Project Settings -> Autoload -> add this file, Node Name
#   "SteamtekLive3DProgressStore"
# ============================================================

const GLOBAL_INVENTORY_KEY := "steamtek_global_inventory"
const GLOBAL_COMBAT_STATE_KEY := "steamtek_global_combat_state"

var _cache: Dictionary = {}


# Returns a fresh copy of the named scene's progress, or an empty
# Dictionary if nothing has been set for it yet this session.
func get_progress(key: String) -> Dictionary:
	var stored: Variant = _cache.get(key, {})
	return (stored as Dictionary).duplicate(true) if stored is Dictionary else {}


func save_progress(key: String, data: Dictionary) -> void:
	_cache[key] = data.duplicate(true)


# The player's carried items/weapons/cogs/equipped-weapon -- shared across
# every Live3D scene (apartment, lantern, surface, ...) instead of each
# scene keeping its own disconnected copy.
func get_global_inventory() -> Dictionary:
	return get_progress(GLOBAL_INVENTORY_KEY)


func save_global_inventory(data: Dictionary) -> void:
	save_progress(GLOBAL_INVENTORY_KEY, data)


# The player's health/action pool -- shared the same way as the inventory
# above, so it survives scene transitions instead of resetting to full
# every time a new Live3D scene loads.
func get_global_combat_state() -> Dictionary:
	return get_progress(GLOBAL_COMBAT_STATE_KEY)


func save_global_combat_state(data: Dictionary) -> void:
	save_progress(GLOBAL_COMBAT_STATE_KEY, data)
