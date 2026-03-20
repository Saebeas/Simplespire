# res://ui/hud.gd
class_name HUD
extends Control

@onready var mined_label: Label = $ResourcePanel/MinedLabel
@onready var loot_label: Label  = $ResourcePanel/LootLabel
@onready var miner_button: Button = $MinerButton

const MINER_SCENE := preload("res://entities/miner.tscn")

func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	_on_resources_changed(ResourceManager.get_mined(), ResourceManager.get_loot())
	miner_button.pressed.connect(_on_miner_button_pressed)

func _on_resources_changed(mined: int, loot: int) -> void:
	mined_label.text = "Mined: %d" % mined
	loot_label.text  = "Loot:  %d" % loot

func _on_miner_button_pressed() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("basic_miner")
	var cost: int = int(cfg.get("cost", 50))
	if not ResourceManager.spend_loot(cost):
		print("[HUD] Not enough loot for miner")
		return
	var miner: Miner = MINER_SCENE.instantiate()
	var miners_container: Node2D = get_tree().get_first_node_in_group("miners_container")
	var base: Node2D = get_tree().get_first_node_in_group("player_base")
	# Stack miners near the base, offset each one slightly
	var miner_count: int = get_tree().get_nodes_in_group("miners").size()
	miner.global_position = Vector2(base.global_position.x + 60 + miner_count * 25, base.global_position.y)
	miners_container.add_child(miner)
	EventBus.miner_purchased.emit(miner, -1)
	print("[HUD] Miner purchased!")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_on_miner_button_pressed()
