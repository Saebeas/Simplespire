# res://entities/minions/minion_spawner.gd
extends Node

const MINION_SCENE := preload("res://entities/minions/minion.tscn")
const SWARM_SPREAD: float = 20.0

@onready var units_container: Node2D = get_tree().get_first_node_in_group("units_container")


func _ready() -> void:
	EventBus.minion_played.connect(_on_minion_played)


func _on_minion_played(card: CardResource, position: Vector2, mode: int) -> void:
	var count: int = card.spawn_count
	for i in range(count):
		var minion: Minion = MINION_SCENE.instantiate()
		var spawn_pos := position
		if mode == EventBus.PlayMode.PUSH and count > 1:
			spawn_pos.x += i * SWARM_SPREAD
		minion.global_position = spawn_pos
		units_container.add_child(minion)
		minion.setup(card)
		GameManager.register_minion()

		if mode == EventBus.PlayMode.GARRISON:
			var tower: Node = _find_tower_at(position)
			if tower != null:
				var slot: int = tower.add_garrison(minion)
				if slot >= 0:
					minion.garrison(tower.tower_index, position)

func _find_tower_at(pos: Vector2) -> Node:
	for tower in get_tree().get_nodes_in_group("player_towers"):
		if abs(tower.global_position.x - pos.x) < 100.0:
			return tower
	return null
