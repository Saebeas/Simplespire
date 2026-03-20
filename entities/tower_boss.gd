class_name TowerBoss
extends CharacterBody2D

var max_hp: float = 500.0
var hp: float = 500.0
var dps: float = 25.0
var attack_range: float = 80.0
var faction: int = EventBus.Faction.ENEMY
var tower_index: int = -1

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
	velocity.x = 0.0
	move_and_slide()

	_attack_timer += delta
	_current_target = _find_nearest_target()

	if _current_target != null and _attack_timer >= ATTACK_INTERVAL:
		_attack_timer = 0.0
		_do_attack()


func _find_nearest_target() -> Node:
	var target_group: String
	if faction == EventBus.Faction.ENEMY:
		target_group = "player_minions"
	else:
		target_group = "enemy_creeps"

	var nearest: Node = null
	var nearest_dist: float = attack_range
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
	hp = max(0.0, hp - amount)
	health_bar.value = hp / max_hp
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.boss_died.emit(tower_index, faction)
	print("[TowerBoss] Died at tower %d" % tower_index)
	queue_free()
