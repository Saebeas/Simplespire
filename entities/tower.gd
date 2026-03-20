class_name Tower
extends Node2D

const BOSS_SCENE := preload("res://entities/tower_boss.tscn")

@export var tower_index: int = 0

var owner_faction: int = EventBus.Faction.ENEMY
var _boss: TowerBoss = null

@onready var visual: ColorRect = $Visual
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	_update_visuals()
	_spawn_boss()
	print("[Tower] Tower %d ready at x=%.0f" % [tower_index, global_position.x])
	EventBus.boss_died.connect(_on_boss_died)

func _spawn_boss() -> void:
	_boss = BOSS_SCENE.instantiate()
	_boss.global_position = Vector2(global_position.x, global_position.y - 48)
	var units: Node2D = get_tree().get_first_node_in_group("units_container")
	units.add_child(_boss)
	_boss.call_deferred("setup", tower_index, owner_faction)

func _update_visuals() -> void:
	name_label.text = "T%d" % (tower_index + 1)
	if owner_faction == EventBus.Faction.ENEMY:
		visual.color = Color("#661111")
	else:
		visual.color = Color("#113366")
	
func _on_boss_died(idx: int, faction: int) -> void:
	if idx != tower_index:
		return
	
	if faction == EventBus.Faction.ENEMY:
		owner_faction = EventBus.Faction.PLAYER
		EventBus.tower_captured.emit(tower_index)
		print("[Tower] Tower %d captured by player!" % (tower_index + 1))
	else:
		owner_faction = EventBus.Faction.ENEMY
		EventBus.tower_lost.emit(tower_index)
		print("[Tower] Tower %d lost to enemy!" % (tower_index + 1))
	
	_update_visuals()
	_spawn_boss()
