# res://systems/wave_spawner.gd
extends Node

const ENEMY_SCENE := preload("res://entities/enemy_creep.tscn")

var _wave_timer: float = 0.0
var _wave_number: int = 0
var _spawn_queue: Array = []
var _stagger_timer: float = 0.0

var _interval: float = 15.0
var _base_count: int = 3
var _base_hp: float = 40.0
var _base_dps: float = 10.0
var _base_speed: float = 120.0
var _base_loot_min: int = 15
var _base_loot_max: int = 20
var _scaling_rate: float = 0.10
var _spawn_stagger: float = 0.5
var _max_creeps: int = 10

var _grace_period: bool = true

@onready var units_container: Node2D = get_tree().get_first_node_in_group("units_container")


func _ready() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("waves")
	_interval       = float(cfg.get("interval", 15.0))
	_base_count     = int(cfg.get("base_creep_count", 3))
	_base_hp        = float(cfg.get("base_creep_hp", 40.0))
	_base_dps       = float(cfg.get("base_creep_dps", 10.0))
	_base_speed     = float(cfg.get("base_creep_speed", 120.0))
	_base_loot_min  = int(cfg.get("base_loot_min", 15))
	_base_loot_max  = int(cfg.get("base_loot_max", 20))
	_scaling_rate   = float(cfg.get("scaling_rate", 0.10))
	_spawn_stagger  = float(cfg.get("spawn_stagger", 0.5))
	_max_creeps     = int(cfg.get("max_creeps_per_wave", 10))

	# Spawn first wave after a short delay so player can settle in
	_wave_timer = 0.0
	_grace_period = true
	print("[WaveSpawner] Ready | Interval:%.0fs BaseHP:%.0f Scaling:%.0f%%" \
		% [_interval, _base_hp, _scaling_rate * 100.0])
	EventBus.tower_captured.connect(_on_tower_captured)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	if _grace_period:
		return
	_wave_timer += delta
	if _wave_timer >= _interval:
		_wave_timer = 0.0
		_wave_number += 1
		_queue_wave(_wave_number)
		EventBus.wave_spawned.emit(_wave_number)

	if _spawn_queue.size() > 0:
		_stagger_timer += delta
		if _stagger_timer >= _spawn_stagger:
			_stagger_timer = 0.0
			_spawn_one(_spawn_queue.pop_front())


func _queue_wave(wave_num: int) -> void:
	var count: int = mini(_base_count + int(wave_num / 3), _max_creeps)
	var scale: float = pow(1.0 + _scaling_rate, wave_num)
	var hp: float = _base_hp * scale
	var dps: float = _base_dps * scale
	var speed: float = _base_speed

	print("[WaveSpawner] Wave %d | Count:%d HP:%.0f DPS:%.1f" \
		% [wave_num, count, hp, dps])

	for i in range(count):
		_spawn_queue.append({
			"hp": hp,
			"dps": dps,
			"speed": speed,
			"loot": randi_range(_base_loot_min, _base_loot_max)
		})


func _spawn_one(data: Dictionary) -> void:
	var creep: EnemyCreep = ENEMY_SCENE.instantiate()
	# Spawn at right side of lane, on the ground
	creep.global_position = Vector2(8960.0, 552.0)
	units_container.add_child(creep)
	creep.setup(data["hp"], data["dps"], data["speed"], data["loot"])

func _on_tower_captured(_tower_index: int) -> void:
	if _grace_period:
		_grace_period = false
		_wave_timer = _interval - 5.0
		print("[WaveSpawner] Grace period ended — first wave in 5 seconds")
