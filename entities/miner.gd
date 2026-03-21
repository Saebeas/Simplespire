# res://entities/miner.gd
class_name Miner
extends Node2D

var max_hp: float = 75.0
var hp: float = 75.0
var output_per_tick: int = 5
var tick_interval: float = 3.0
var _tick_timer: float = 0.0
var stationed_tower: int = -1
var _flee_target: Vector2 = Vector2.ZERO
var _is_fleeing: bool = false
var _move_speed: float = 60.0

@onready var visual: ColorRect = $Visual
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("basic_miner")
	max_hp = float(cfg.get("hp", 75))
	hp = max_hp
	output_per_tick = int(cfg.get("output_per_tick", 5))
	tick_interval = float(cfg.get("tick_interval", 3.0))
	health_bar.value = 1.0
	add_to_group("miners")
	print("[Miner] Spawned | HP:%.0f Output:%d every %.1fs" \
		% [max_hp, output_per_tick, tick_interval])
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_speed = float(DataLoader.get_balance_section("basic_miner").get("move_speed", 60))
	EventBus.tower_lost.connect(_on_tower_lost)
	EventBus.tower_captured.connect(_on_tower_captured)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	if _is_fleeing:
		var dir: float = sign(_flee_target.x - global_position.x)
		global_position.x += dir * _move_speed * delta
		if abs(global_position.x - _flee_target.x) < 5.0:
			global_position.x = _flee_target.x
			_is_fleeing = false
			print("[Miner] Arrived at new position x=%.0f" % global_position.x)
		return

	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		ResourceManager.add_mined(output_per_tick)

func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	health_bar.value = hp / max_hp
	if hp <= 0.0:
		_die()


func _die() -> void:
	print("[Miner] Died")
	queue_free()

func _on_tower_lost(tower_index: int) -> void:
	if tower_index != stationed_tower:
		return
	_recalculate_flee()
	
	var best_tower: Node = null
	var best_index: int = -1
	for tower in get_tree().get_nodes_in_group("player_towers"):
		if tower.tower_index != tower_index and tower.tower_index > best_index:
			best_index = tower.tower_index
			best_tower = tower

	if best_tower != null:
		stationed_tower = best_tower.tower_index
		_flee_target = Vector2(best_tower.global_position.x + randf_range(-30.0, 30.0), global_position.y)
		print("[Miner] Fleeing to tower %d" % (best_index + 1))
	else:
		var base: Node = get_tree().get_first_node_in_group("player_base")
		stationed_tower = -1
		_flee_target = Vector2(base.global_position.x + randf_range(30.0, 80.0), global_position.y)
		print("[Miner] Fleeing to base")

	_is_fleeing = true
	
func _on_tower_captured(tower_index: int) -> void:
	if not _is_fleeing:
		return
	# If a tower we're passing or heading toward was recaptured, stop there
	var tower: Node = _find_tower_by_index(tower_index)
	if tower == null:
		return
	var dist: float = abs(global_position.x - tower.global_position.x)
	var dist_to_current: float = abs(global_position.x - _flee_target.x)
	if dist < dist_to_current:
		stationed_tower = tower_index
		_flee_target = Vector2(tower.global_position.x + randf_range(-30.0, 30.0), global_position.y)
		print("[Miner] Rerouting to recaptured tower %d" % (tower_index + 1))

func _recalculate_flee() -> void:
	var best_tower: Node = null
	var best_index: int = -1
	for tower in get_tree().get_nodes_in_group("player_towers"):
		if tower.tower_index > best_index:
			best_index = tower.tower_index
			best_tower = tower

	if best_tower != null:
		stationed_tower = best_tower.tower_index
		_flee_target = Vector2(best_tower.global_position.x + randf_range(-30.0, 30.0), global_position.y)
		print("[Miner] Fleeing to tower %d" % (best_index + 1))
	else:
		var base: Node = get_tree().get_first_node_in_group("player_base")
		stationed_tower = -1
		_flee_target = Vector2(base.global_position.x + randf_range(30.0, 80.0), global_position.y)
		print("[Miner] Fleeing to base")

	_is_fleeing = true
	
func _find_tower_by_index(index: int) -> Node:
	for tower in get_tree().get_nodes_in_group("player_towers"):
		if tower.tower_index == index:
			return tower
	return null
