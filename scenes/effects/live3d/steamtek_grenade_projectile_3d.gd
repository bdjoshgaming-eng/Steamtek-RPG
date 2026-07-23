class_name SteamtekGrenadeProjectile3D
extends Node3D

## Spawned and fully driven at runtime by
## steamtek_humanoid_character_3d.gd's _launch_grenade(). Real per-frame
## ballistic simulation (gravity + bounce restitution/friction), not
## fixed-duration tweened hops -- Junkrat-frag-grenade style: it lands,
## bounces losing energy each bounce, settles, then calls on_landed.
##
## Damage is a DIRECT HIT, not a splash check at the rest position: every
## physics frame, for the ENTIRE flight (both the initial arc and any
## bounce), checks distance to every live member of enemy_group and
## detonates the instant one is within hit_radius. This is what actually
## fixes reliability -- checking only the final settled position meant a
## chasing enemy that moved during the ~0.5-1.5s flight, or simple aim
## imprecision, made most throws miss even when they looked close. A
## grenade that never touches anyone still lands/settles and calls
## on_landed with a null hit_enemy (a clean miss -- VFX plays, no damage).

var _velocity := Vector3.ZERO
var _gravity := 9.8
var _ground_y := 0.0
var _bounce_restitution := 0.4
var _bounce_friction := 0.6
var _bounces_remaining := 3
var _settle_speed := 0.5
var _max_flight_time := 4.0
var _flight_time := 0.0
var _enemy_group := ""
var _hit_radius := 0.5
var _on_landed: Callable
var _flying := false


func launch(
	start: Vector3,
	initial_velocity: Vector3,
	gravity: float,
	ground_y: float,
	bounce_restitution: float,
	bounce_friction: float,
	bounces: int,
	settle_speed: float,
	max_flight_time: float,
	enemy_group: String,
	hit_radius: float,
	on_landed: Callable
) -> void:
	global_position = start
	_velocity = initial_velocity
	_gravity = gravity
	_ground_y = ground_y
	_bounce_restitution = bounce_restitution
	_bounce_friction = bounce_friction
	_bounces_remaining = bounces
	_settle_speed = settle_speed
	_max_flight_time = max_flight_time
	_flight_time = 0.0
	_enemy_group = enemy_group
	_hit_radius = hit_radius
	_on_landed = on_landed
	_flying = true


func _physics_process(delta: float) -> void:
	if not _flying:
		return
	_flight_time += delta
	_velocity.y -= _gravity * delta
	global_position += _velocity * delta
	var hit_enemy := _find_enemy_contact()
	if hit_enemy != null:
		_land(hit_enemy)
		return
	if global_position.y > _ground_y and _flight_time < _max_flight_time:
		return
	global_position.y = _ground_y
	if _bounces_remaining <= 0 or absf(_velocity.y) < _settle_speed or _flight_time >= _max_flight_time:
		_land(null)
		return
	_velocity.y = -_velocity.y * _bounce_restitution
	_velocity.x *= _bounce_friction
	_velocity.z *= _bounce_friction
	_bounces_remaining -= 1


func _find_enemy_contact() -> Node:
	if _enemy_group.is_empty():
		return null
	for enemy_node in get_tree().get_nodes_in_group(_enemy_group):
		if not is_instance_valid(enemy_node) or not (enemy_node is Node3D):
			continue
		if enemy_node.has_method("is_alive") and not enemy_node.call("is_alive"):
			continue
		if global_position.distance_to((enemy_node as Node3D).global_position) <= _hit_radius:
			return enemy_node
	return null


func _land(hit_enemy: Node) -> void:
	_flying = false
	var final_position := global_position
	if _on_landed.is_valid():
		_on_landed.call(final_position, hit_enemy)
	queue_free()
