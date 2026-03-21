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
	collision_layer = 8  # Layer 4: enemy_creeps
	collision_mask = 1   # Layer 1: world/ground only
	max_hp      = creep_hp
	hp          = max_hp
	dps         = creep_dps
	move_speed  = creep_speed
	loot_amount = loot
	health_bar.value = 1.0
	add_to_group("enemy_creeps")
	add_to_group("enemy_creep")
	EventBus.unit_spawned.emit(self, "enemy_creep")
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		var dist: float = abs(_current_target.global_position.x - global_position.x)
		var dir: float = sign(_current_target.global_position.x - global_position.x)

		if dist <= MELEE_RANGE:
			velocity.x = 0.0
			if _attack_timer >= ATTACK_INTERVAL:
				_attack_timer = 0.0
				_do_attack()
		else:
			velocity.x = dir * move_speed
	else:
		velocity.x = -move_speed
	
	move_and_slide()



func _find_nearest_target() -> Node:
	var nearest: Node = null
	var nearest_dist: float = MELEE_RANGE + 150.0

	# Priority 1: player minions (includes garrisoned)
	for minion in get_tree().get_nodes_in_group("player_minions"):
		if not is_instance_valid(minion):
			continue
		var dist: float = abs(global_position.x - minion.global_position.x)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = minion

	# Priority 2: player tower bosses
	if nearest == null:
		nearest_dist = MELEE_RANGE + 150.0
		for boss in get_tree().get_nodes_in_group("player_bosses"):
			if not is_instance_valid(boss):
				continue
			var dist: float = abs(global_position.x - boss.global_position.x)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = boss

	# Priority 3: miners
	if nearest == null:
		nearest_dist = MELEE_RANGE + 150.0
		for miner in get_tree().get_nodes_in_group("miners"):
			if not is_instance_valid(miner):
				continue
			var dist: float = abs(global_position.x - miner.global_position.x)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = miner

	# Priority 4: player base
	if nearest == null:
		var base: Node = get_tree().get_first_node_in_group("player_base")
		if base != null and is_instance_valid(base):
			var dist: float = abs(global_position.x - base.global_position.x)
			if dist < MELEE_RANGE:
				nearest = base

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
