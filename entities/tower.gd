class_name Tower
extends Node2D

const BOSS_SCENE := preload("res://entities/tower_boss.tscn")
const CRYSTAL_SCENE := preload("res://entities/crystal_node.tscn")

var _first_capture: bool = true


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
var garrison_slots: Array = [null, null]
const GARRISON_OFFSETS: Array = [-40.0, 40.0]

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
	EventBus.unit_died.connect(_on_unit_died)
	$GarrisonLabel.text = "0/2"

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
	_update_garrison_label()
	
func _on_boss_died(idx: int, faction: int) -> void:
	if idx != tower_index:
		return
	_ungarrison_all()
	
	if faction == EventBus.Faction.ENEMY:
		owner_faction = EventBus.Faction.PLAYER
		EventBus.tower_captured.emit(tower_index)
		if _first_capture:
			_first_capture = false
			var pack_cards: Array = _generate_pack()
			EventBus.pack_opened.emit(pack_cards)
			print("[Tower] 🎴 Card pack dropped from tower %d!" % (tower_index + 1))
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

func has_garrison_slot() -> bool:
	for slot in garrison_slots:
		if slot == null:
			return true
	return false


func get_garrison_position() -> Vector2:
	for i in range(garrison_slots.size()):
		if garrison_slots[i] == null:
			return Vector2(global_position.x + GARRISON_OFFSETS[i], global_position.y - 48)
	return global_position


func add_garrison(minion: Node) -> int:
	for i in range(garrison_slots.size()):
		if garrison_slots[i] == null:
			garrison_slots[i] = minion
			EventBus.tower_garrison_changed.emit(tower_index, i, minion)
			print("[Tower] Garrison slot %d filled at tower %d" % [i, tower_index + 1])
			_update_garrison_label()
			return i
	return -1


func remove_garrison(minion: Node) -> void:
	for i in range(garrison_slots.size()):
		if garrison_slots[i] == minion:
			garrison_slots[i] = null
			EventBus.tower_garrison_changed.emit(tower_index, i, null)
			print("[Tower] Garrison slot %d cleared at tower %d" % [i, tower_index + 1])
			_update_garrison_label()
			return


func _ungarrison_all() -> void:
	for i in range(garrison_slots.size()):
		var minion = garrison_slots[i]
		if minion != null and is_instance_valid(minion):
			minion.ungarrison()
		garrison_slots[i] = null
	_update_garrison_label()


func _on_unit_died(entity: Node, _killer: Node) -> void:
	remove_garrison(entity)


func _update_garrison_label() -> void:
	var filled: int = 0
	for slot in garrison_slots:
		if slot != null and is_instance_valid(slot):
			filled += 1
	$GarrisonLabel.text = "%d/2" % filled


func _generate_pack() -> Array:
	var pack: Array = []
	var all_cards: Array = DataLoader.cards.values()
	for i in range(3):
		pack.append(all_cards[randi() % all_cards.size()])
	print("[Tower] Pack contains: %s" % ", ".join(pack.map(func(c): return c.display_name)))
	return pack
