class_name Tower
extends Node2D

const BOSS_SCENE := preload("res://entities/tower_boss.tscn")
const CRYSTAL_SCENE := preload("res://entities/crystal_node.tscn")

const ZONE_MAP: Dictionary = {
	0: "t1_t2_zone",
	1: "t1_t2_zone",
	2: "t3_zone",
	3: "t4_t5_zone",
	4: "t4_t5_zone"
}

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
	_spawn_crystal_nodes()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _spawn_boss() -> void:
	if _boss != null and is_instance_valid(_boss):
		_boss.queue_free()
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
	if owner_faction == EventBus.Faction.PLAYER:
		if not is_in_group("player_towers"):
			add_to_group("player_towers")
	else:
		if is_in_group("player_towers"):
			remove_from_group("player_towers")
	
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
	
func _spawn_crystal_nodes() -> void:
	var crystal_container: Node2D = get_tree().get_first_node_in_group("crystal_nodes_container")
	if crystal_container == null:
		crystal_container = get_parent()
	var zone_name: String = ZONE_MAP.get(tower_index, "t1_t2_zone")
	for offset in [-50.0, 50.0]:
		var node: CrystalNode = CRYSTAL_SCENE.instantiate()
		node.global_position = Vector2(global_position.x + offset, global_position.y)
		node.zone = zone_name
		crystal_container.add_child(node)
