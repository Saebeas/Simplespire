class_name TowerBoss
extends CharacterBody2D

var max_hp: float = 500.0
var hp: float = 500.0
var dps: float = 25.0
var attack_range: float = 80.0
var faction: int = EventBus.Faction.ENEMY
var tower_index: int = -1
var home_position: Vector2 = Vector2.ZERO
var leash_radius: float = 200.0
var aggro_radius: float = 250.0
var move_speed: float = 90.0
var _is_dead: bool = false

const GRAVITY: float = 980.0
const ATTACK_INTERVAL: float = 1.0

var _attack_timer: float = 0.0
var _current_target: Node = null

@onready var visual: ColorRect = $Visual
@onready var health_bar: ProgressBar = $HealthBar


func setup(p_tower_index: int, p_faction: int) -> void:
	tower_index = p_tower_index
	faction = p_faction

	var cfg: Dictionary = DataLoader.get_balance_section("tower_boss")
	max_hp = float(cfg.get("hp", 500))
	hp = max_hp
	dps = float(cfg.get("dps", 25))
	attack_range = float(cfg.get("attack_range", 80))

	collision_layer = 16
	collision_mask = 1

	health_bar.value = 1.0
	_update_groups()
	_update_faction_visuals()
	home_position = global_position
	leash_radius = float(cfg.get("leash_radius", 200))
	aggro_radius = float(cfg.get("aggro_radius", 250))
	move_speed = float(cfg.get("move_speed", 90))
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[TowerBoss] Spawned at tower %d | Faction:%d HP:%.0f DPS:%.1f" \
		% [tower_index, faction, max_hp, dps])


func _update_groups() -> void:
	for g in ["enemy_creeps", "enemy_creep", "player_minions", "tower_bosses"]:
		if is_in_group(g):
			remove_from_group(g)
	add_to_group("tower_bosses")
	if faction == EventBus.Faction.ENEMY:
		add_to_group("enemy_creeps")
		add_to_group("enemy_creep")
	else:
		add_to_group("player_minions")


func _update_faction_visuals() -> void:
	if faction == EventBus.Faction.ENEMY:
		visual.color = Color("#cc2222")
	else:
		visual.color = Color("#2266cc")


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
		var dist_to_target: float = abs(global_position.x - _current_target.global_position.x)
		var dist_from_home: float = abs(global_position.x - home_position.x)
		var dir: float = sign(_current_target.global_position.x - global_position.x)

		if dist_to_target <= attack_range:
			velocity.x = 0.0
			if _attack_timer >= ATTACK_INTERVAL:
				_attack_timer = 0.0
				_do_attack()
		elif dist_from_home < aggro_radius:
			velocity.x = dir * move_speed
		else:
			velocity.x = 0.0
	else:
		var dist_home: float = global_position.x - home_position.x
		if abs(dist_home) > 5.0:
			velocity.x = -sign(dist_home) * move_speed
		else:
			velocity.x = 0.0
			global_position.x = home_position.x

	move_and_slide()

func _find_nearest_target() -> Node:
	var target_group: String
	if faction == EventBus.Faction.ENEMY:
		target_group = "player_minions"
	else:
		target_group = "enemy_creeps"

	var nearest: Node = null
	var nearest_dist: float = aggro_radius
	for unit in get_tree().get_nodes_in_group(target_group):
		if not is_instance_valid(unit):
			continue
		if unit == self:
			continue
		var dist: float = abs(global_position.x - unit.global_position.x)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = unit
	return nearest

func _do_attack() -> void:
	if not is_instance_valid(_current_target):
		_current_target = null
		return
	if _current_target.has_method("take_damage"):
		_current_target.take_damage(dps)


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	hp = max(0.0, hp - amount)
	health_bar.value = hp / max_hp
	if hp <= 0.0:
		_die()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	EventBus.boss_died.emit(tower_index, faction)
	print("[TowerBoss] Died at tower %d" % tower_index)
	queue_free()
