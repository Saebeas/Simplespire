# res://entities/minions/minion.gd
class_name Minion
extends CharacterBody2D

var display_name: String = ""
var max_hp: float = 100.0
var hp: float = 100.0
var dps: float = 10.0
var attack_range: float = 0.0
var move_speed: float = 120.0
var boss_damage_multiplier: float = 1.0
var role: int = 0
var _is_garrisoned: bool = false
var garrisoned_tower_index: int = -1
var _garrison_home: Vector2 = Vector2.ZERO
var _garrison_leash: float = 200.0
var _capacity_weight: int = 1

const MELEE_RANGE: float = 40.0
const ATTACK_INTERVAL: float = 1.0

var _attack_timer: float = 0.0
var _current_target: Node = null

const GRAVITY: float = 980.0

const MIN_SEPARATION: float = 18.0

@onready var visual: ColorRect   = $Visual
@onready var health_bar: ProgressBar = $HealthBar


func setup(card: CardResource) -> void:
	collision_layer = 4  # Layer 3: player_minions
	collision_mask = 1   # Layer 1: world/ground only
	display_name          = card.display_name
	max_hp                = float(card.hp)
	hp                    = max_hp
	dps                   = card.dps
	attack_range          = card.attack_range
	move_speed            = card.move_speed
	boss_damage_multiplier = card.boss_damage_multiplier
	_capacity_weight = card.capacity_weight
	role                  = card.role
	_apply_role_color()
	health_bar.value = 1.0
	add_to_group("player_minions")
	EventBus.unit_spawned.emit(self, display_name)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[Minion] Spawned: %s | HP:%.0f DPS:%.1f SPD:%.0f" \
		% [display_name, max_hp, dps, move_speed])


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	_attack_timer += delta
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = _find_nearest_target()

	if _is_garrisoned:
		if _current_target != null:
			var dist_to_target: float = abs(_current_target.global_position.x - global_position.x)
			var dist_from_home: float = abs(global_position.x - _garrison_home.x)
			var effective_range: float = attack_range if attack_range > 0.0 else MELEE_RANGE
			var dir: float = sign(_current_target.global_position.x - global_position.x)

			if dist_to_target <= effective_range:
				velocity.x = 0.0
				if _attack_timer >= ATTACK_INTERVAL:
					_attack_timer = 0.0
					_do_attack()
			elif dist_from_home < _garrison_leash:
				velocity.x = dir * move_speed
			else:
				velocity.x = 0.0
		else:
			var dist_home: float = global_position.x - _garrison_home.x
			if abs(dist_home) > 5.0:
				velocity.x = -sign(dist_home) * move_speed
			else:
				velocity.x = 0.0
				global_position.x = _garrison_home.x
	else:
		if _current_target != null:
			var drop_dist: float = abs(_current_target.global_position.x - global_position.x)
			if drop_dist > max(attack_range, MELEE_RANGE) + 200.0:
				_current_target = null
				velocity.x = move_speed
			else:
				var dist: float = abs(_current_target.global_position.x - global_position.x)
				var effective_range: float = attack_range if attack_range > 0.0 else MELEE_RANGE
				var dir: float = sign(_current_target.global_position.x - global_position.x)
				if dist <= effective_range:
					velocity.x = 0.0
					if _attack_timer >= ATTACK_INTERVAL:
						_attack_timer = 0.0
						_do_attack()
				else:
					velocity.x = dir * move_speed
		else:
			velocity.x = move_speed
	_apply_separation()
	move_and_slide()

func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	health_bar.value = hp / max_hp
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.unit_died.emit(self, null)
	print("[Minion] %s died" % display_name)
	if _is_garrisoned:
		EventBus.tower_garrison_changed.emit(garrisoned_tower_index, -1, null)
	queue_free()

func _find_nearest_target() -> Node:
	var nearest: Node = null
	var nearest_dist: float = INF
	var aggro_range: float = max(attack_range, 40.0) + 150.0

	for creep in get_tree().get_nodes_in_group("enemy_creeps"):
		if not is_instance_valid(creep):
			continue
		var dist: float = abs(global_position.x - creep.global_position.x)
		if dist < aggro_range and dist < nearest_dist:
			nearest_dist = dist
			nearest = creep
	return nearest

func _do_attack() -> void:
	if not is_instance_valid(_current_target):
		_current_target = null
		return
	var damage: float = dps
	if _current_target.is_in_group("tower_bosses") and boss_damage_multiplier > 1.0:
		damage *= boss_damage_multiplier
	if _current_target.has_method("take_damage"):
		_current_target.take_damage(damage)

func _apply_role_color() -> void:
	match role:
		CardResource.Role.TANK:      visual.color = Color("#4488ff")
		CardResource.Role.MELEE_DPS: visual.color = Color("#ff4444")
		CardResource.Role.RANGED:    visual.color = Color("#44ff88")
		CardResource.Role.SWARM:     visual.color = Color("#ffff44")
		CardResource.Role.SIEGE:     visual.color = Color("#ff8844")
		CardResource.Role.BRUISER:   visual.color = Color("#aa44ff")

func garrison(tower_idx: int, garrison_pos: Vector2) -> void:
	_is_garrisoned = true
	garrisoned_tower_index = tower_idx
	global_position = garrison_pos
	_garrison_home = garrison_pos
	print("[Minion] %s garrisoned at tower %d" % [display_name, tower_idx + 1])


func ungarrison() -> void:
	_is_garrisoned = false
	garrisoned_tower_index = -1
	print("[Minion] %s ungarrisoned — pushing forward" % display_name)

func _apply_separation() -> void:
	var push: float = 0.0
	for other in get_tree().get_nodes_in_group("player_minions"):
		if other == self or not is_instance_valid(other):
			continue
		var diff: float = global_position.x - other.global_position.x
		if abs(diff) < MIN_SEPARATION:
			var strength: float = (MIN_SEPARATION - abs(diff)) / MIN_SEPARATION
			if diff == 0.0:
				diff = randf_range(-1.0, 1.0)
			push += sign(diff) * strength * 3.0
	global_position.x += push
