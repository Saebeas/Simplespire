# res://entities/player_base.gd
class_name PlayerBase
extends Node2D

# Emitted each time HP changes — HUD will listen to this later
signal hp_changed(current_hp: int, max_hp: int)

var max_hp: int = 1000
var current_hp: int = 0
var _is_destroyed: bool = false


func _ready() -> void:
	# Load HP from balance.json (data-driven)
	var base_data: Dictionary = DataLoader.get_balance_section("base")
	max_hp = int(base_data.get("hp", 1000))
	current_hp = max_hp
	print("[PlayerBase] Initialized | HP: %d/%d" % [current_hp, max_hp])
	$Visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$NameLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# DEBUG: simulate two damage hits — remove after verifying
	# call_deferred("_debug_damage_test")


## Called by EnemyCreep (Task 12) when it reaches the base
func take_damage(amount: int) -> void:
	if _is_destroyed:
		return

	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	print("[PlayerBase] Took %d damage | HP: %d/%d" % [amount, current_hp, max_hp])

	if current_hp <= 0:
		_is_destroyed = true
		print("[PlayerBase] DESTROYED — emitting level_lost")
		EventBus.level_lost.emit()


## Returns HP as a 0.0–1.0 ratio for health bars
func get_hp_ratio() -> float:
	return float(current_hp) / float(max_hp)


func _debug_damage_test() -> void:
	print("[PlayerBase DEBUG] Simulating damage hits...")
	take_damage(600)   # should survive → 400 HP
	take_damage(401)   # should destroy → 0 HP → level_lost
