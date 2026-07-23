class_name SteamtekGrenadeExplosion3D
extends Node3D

## One-shot grenade/blast impact VFX: a fire burst, a lingering smoke
## puff, and a quick light flash. Spawned and freed entirely at runtime
## by steamtek_humanoid_character_3d.gd's _resolve_aoe_damage() -- shared
## by both the Grenade Launcher bounce landing and any future instant
## "blast" weapon (Rocket Launcher/Arc Cannon).

const LIGHT_FADE_TIME := 0.25
const CLEANUP_DELAY := 1.6

@onready var fire_burst: GPUParticles3D = $FireBurst
@onready var smoke_puff: GPUParticles3D = $SmokePuff
@onready var flash_light: OmniLight3D = $FlashLight


func play(splash_radius: float) -> void:
	var scale_factor := clampf(splash_radius / 1.3, 0.5, 2.5)
	scale = Vector3.ONE * scale_factor
	fire_burst.restart()
	fire_burst.emitting = true
	smoke_puff.restart()
	smoke_puff.emitting = true
	flash_light.light_energy = 6.0
	var tween := create_tween()
	tween.tween_property(flash_light, "light_energy", 0.0, LIGHT_FADE_TIME)
	get_tree().create_timer(CLEANUP_DELAY).timeout.connect(queue_free)
