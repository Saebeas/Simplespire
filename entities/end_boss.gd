class_name EndBoss
extends CharacterBody2D

var max_hp: float = 2000.0
var hp: float = 2000.0
var dps: float = 50.0
var attack_range: float = 80.0
var move_speed: float = 90.0

const GRAVITY: float = 980.0
const ATTACK_INTERVAL: float = 1.0

var _attack_timer: float = 0.0
var _current_target: Node = null
var _is_dead: bool = false
var home_position: Vector2 = Vector2.ZERO
var leash_radius: float = 300.0
var aggro_radius: float = 350.0

@onready var visual: ColorRect = $Visual
@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("end_boss")
	var strength: float = GameManager.get_end_boss_strength_ratio()

	max_hp = float(cfg.get("base_hp", 2000)) * strength
	hp = max_hp
	dps = float(cfg.get("base_dps", 50)) * strength
	home_position = global_position

	collision_layer = 8
	collision_mask = 1

	health_bar.value = 1.0
	name_label.text = "END BOSS"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_to_group("enemy_creeps")
	add_to_group("enemy_creep")

	print("[EndBoss] Spawned | Strength:%.0f%% HP:%.0f DPS:%.1f" \
		% [strength * 100, max_hp, dps])


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if _is_dead:
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
	var nearest: Node = null
	var nearest_dist: float = aggro_radius
	for unit in get_tree().get_nodes_in_group("player_minions"):
		if not is_instance_valid(unit):
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
	print("[EndBoss] DEFEATED!")
	EventBus.level_won.emit()
	queue_free()
