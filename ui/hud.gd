# res://ui/hud.gd
class_name HUD
extends Control

@onready var mined_label: Label = $ResourcePanel/MinedLabel
@onready var loot_label: Label  = $ResourcePanel/LootLabel
@onready var miner_button: Button = $MinerButton
@onready var result_label: Label = $ResultLabel

const MINER_SCENE := preload("res://entities/miner.tscn")

func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	_on_resources_changed(ResourceManager.get_mined(), ResourceManager.get_loot())
	miner_button.pressed.connect(_on_miner_button_pressed)
	result_label.visible = false
	EventBus.level_won.connect(_on_level_won)
	EventBus.level_lost.connect(_on_level_lost)
	
	
func _on_resources_changed(mined: int, loot: int) -> void:
	mined_label.text = "Mined: %d" % mined
	loot_label.text  = "Loot:  %d" % loot

func _on_miner_button_pressed() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("basic_miner")
	var cost: int = int(cfg.get("cost", 50))
	if not ResourceManager.spend_loot(cost):
		print("[HUD] Not enough loot for miner")
		return

	var player: Node = get_tree().get_first_node_in_group("player")
	var result: Dictionary = _find_miner_placement(player)

	var miner: Miner = MINER_SCENE.instantiate()
	var miners_container: Node2D = get_tree().get_first_node_in_group("miners_container")
	miner.global_position = Vector2(result["position"].x + randf_range(-30.0, 30.0), result["position"].y)
	miners_container.add_child(miner)
	miner.stationed_tower = result["tower_index"]
	EventBus.miner_purchased.emit(miner, result["tower_index"])
	print("[HUD] Miner placed at tower %d" % (result["tower_index"] + 1))

func _find_miner_placement(player: Node) -> Dictionary:
	var best_tower: Node = null
	var best_dist: float = INF
	for tower in get_tree().get_nodes_in_group("player_towers"):
		var dist: float = abs(tower.global_position.x - player.global_position.x)
		if dist < best_dist:
			best_dist = dist
			best_tower = tower
	if best_tower != null:
		return {"position": best_tower.global_position, "tower_index": best_tower.tower_index}
	var base: Node = get_tree().get_first_node_in_group("player_base")
	return {"position": base.global_position, "tower_index": -1}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_on_miner_button_pressed()

func _on_level_won() -> void:
	result_label.text = "VICTORY!"
	result_label.add_theme_color_override("font_color", Color("#44ff44"))
	result_label.visible = true


func _on_level_lost() -> void:
	result_label.text = "DEFEAT"
	result_label.add_theme_color_override("font_color", Color("#ff4444"))
	result_label.visible = true
