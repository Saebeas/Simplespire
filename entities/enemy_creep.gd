# res://entities/enemy_creep.gd
class_name EnemyCreep
extends CharacterBody2D

var max_hp: float = 40.0
var hp: float = 40.0
var dps: float = 10.0
var move_speed: float = 120.0
var loot_amount: int = 15

const GRAVITY: float = 980.0
const MELEE_RANGE: float = 40.0
const ATTACK_INTERVAL: float = 1.0

var _attack_timer: float = 0.0
var _current_target: Node = null

@onready var visual: ColorRect       = $Visual
@onready var health_bar: ProgressBar = $HealthBar


func setup(creep_hp: float, creep_dps: float, creep_speed: float, loot: int) -> void:
	max_hp      = creep_hp
	hp          = max_hp
	dps         = creep_dps
	move_speed  = creep_speed
	loot_amount = loot
	health_bar.value = 1.0
	add_to_group("enemy_creeps")
	EventBus.unit_spawned.emit(self, "enemy_creep")
	print("[EnemyCreep] Spawned | HP:%.0f DPS:%.1f SPD:%.0f Loot:%d" \
		% [max_hp, dps, move_speed, loot_amount])


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	_attack_timer += delta
	_current_target = _find_nearest_target()

	if _current_target != null:
		velocity.x = 0.0
		if _attack_timer >= ATTACK_INTERVAL:
			_attack_timer = 0.0
			_do_attack()
	else:
		velocity.x = -move_speed

	move_and_slide()

	if global_position.x <= 320.0:
		_damage_base()


func _find_nearest_target() -> Node:
	var nearest: Node = null
	var nearest_dist: float = MELEE_RANGE
	for minion in get_tree().get_nodes_in_group("player_minions"):
		if not is_instance_valid(minion):
			continue
		var dist: float = abs(global_position.x - minion.global_position.x)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = minion
	return nearest


func _do_attack() -> void:
	if not is_instance_valid(_current_target):
		_current_target = null
		return
	if _current_target.has_method("take_damage"):
		_current_target.take_damage(dps)


func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	health_bar.value = hp / max_hp
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.unit_died.emit(self, null)
	ResourceManager.add_loot(loot_amount)
	EventBus.loot_dropped.emit(loot_amount, global_position)
	print("[EnemyCreep] Died | +%d Loot" % loot_amount)
	queue_free()


func _damage_base() -> void:
	var base := get_tree().get_first_node_in_group("player_base")
	if base != null and base.has_method("take_damage"):
		base.take_damage(10)
	print("[EnemyCreep] Reached player base!")
	queue_free()
