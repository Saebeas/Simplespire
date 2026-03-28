# res://entities/minions/minion_spawner.gd
extends Node

const MINION_SCENE := preload("res://entities/minions/minion.tscn")
const SWARM_SPREAD: float = 20.0

var _capacity_groups: Array = []   # [{ "card": CardResource, "members": [Node, ...] }]

signal capacity_groups_changed(groups: Array)

@onready var _ready_done: bool = false

@onready var units_container: Node2D = get_tree().get_first_node_in_group("units_container")


func _ready() -> void:
	EventBus.minion_played.connect(_on_minion_played)
	EventBus.unit_died.connect(_on_unit_died)
	add_to_group("minion_spawner")


func _on_minion_played(card: CardResource, position: Vector2, mode: int) -> void:
	var count: int = card.spawn_count
	var spawned: Array = []
	for i in range(count):
		var minion: Minion = MINION_SCENE.instantiate()
		var spawn_pos := position
		if mode == EventBus.PlayMode.PUSH and count > 1:
			spawn_pos.x += i * SWARM_SPREAD
		minion.global_position = spawn_pos
		units_container.add_child(minion)
		minion.setup(card)
		spawned.append(minion)

		if mode == EventBus.PlayMode.GARRISON:
			var tower: Node = _find_tower_at(position)
			if tower != null:
				var slot: int = tower.add_garrison(minion)
				if slot >= 0:
					minion.garrison(tower.tower_index, position)

	_capacity_groups.append({"card": card, "members": spawned})
	capacity_groups_changed.emit(_get_group_data())


func _on_unit_died(entity: Node, _killer: Node) -> void:
	if not entity.is_in_group("player_minions"):
		return
	for i in range(_capacity_groups.size() - 1, -1, -1):
		var group: Dictionary = _capacity_groups[i]
		var idx: int = group["members"].find(entity)
		if idx != -1:
			group["members"].remove_at(idx)
			if group["members"].is_empty():
				GameManager.unregister_minion(group["card"].capacity_weight)
				_capacity_groups.remove_at(i)
			capacity_groups_changed.emit(_get_group_data())
			return


func _find_tower_at(pos: Vector2) -> Node:
	for tower in get_tree().get_nodes_in_group("player_towers"):
		if abs(tower.global_position.x - pos.x) < 100.0:
			return tower
	return null

func _get_group_data() -> Array:
	var data: Array = []
	for group in _capacity_groups:
		data.append({
			"card_id": group["card"].id,
			"capacity_weight": group["card"].capacity_weight
		})
	return data
