# res://entities/miner.gd
class_name Miner
extends Node2D

var max_hp: float = 75.0
var hp: float = 75.0
var output_per_tick: int = 5
var tick_interval: float = 3.0
var _tick_timer: float = 0.0

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


func _process(delta: float) -> void:
	if not GameManager.is_playing():
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
