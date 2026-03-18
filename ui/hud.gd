# res://ui/hud.gd
class_name HUD
extends Control

@onready var mined_label: Label = $ResourcePanel/MinedLabel
@onready var loot_label: Label  = $ResourcePanel/LootLabel


func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	_on_resources_changed(ResourceManager.get_mined(), ResourceManager.get_loot())


func _on_resources_changed(mined: int, loot: int) -> void:
	mined_label.text = "Mined: %d" % mined
	loot_label.text  = "Loot:  %d" % loot
