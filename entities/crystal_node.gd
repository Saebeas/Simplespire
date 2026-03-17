# res://entities/crystal_node.gd
class_name CrystalNode
extends Node2D

@export_enum("base_zone", "t1_t2_zone", "t3_zone", "t4_t5_zone", "enemy_zone") \
	var zone: String = "base_zone"

@onready var interaction_zone: Area2D  = $InteractionZone
@onready var click_zone: Area2D        = $ClickZone
@onready var channel_bar: ProgressBar  = $ProgressBarContainer/ChannelBar
@onready var visual: ColorRect         = $Visual

var _channel_time: float     = 2.0
var _channel_progress: float = 0.0
var _is_channeling: bool     = false
var _player_in_range: bool   = false
var _player_ref: Node        = null

var _yield_amount: int  = 10
var _pack_chance: float = 0.01


func _ready() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("crystal_nodes")
	if cfg.has(zone):
		var zone_data: Dictionary = cfg[zone]
		_yield_amount = int(zone_data.get("yield", 10))
		_pack_chance  = float(zone_data.get("pack_chance", 0.01))

	var player_cfg: Dictionary = DataLoader.get_balance_section("player")
	_channel_time = float(player_cfg.get("channel_time", 2.0))

	channel_bar.value   = 0.0
	channel_bar.visible = false

	# InteractionZone — proximity detection only (no input_event)
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

	# ClickZone — click detection only, exactly matches the visual rect
	click_zone.input_event.connect(_on_click_zone_input)

	EventBus.player_stun_started.connect(_on_player_stunned)

	print("[CrystalNode] Ready | Zone: %s | Yield: %d | PackChance: %.1f%%" % \
		[zone, _yield_amount, _pack_chance * 100.0])


func _on_click_zone_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_channel()
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not _is_channeling:
		return

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_cancel_channel()
		return

	if not _player_in_range:
		_cancel_channel()
		return

	_channel_progress += delta
	channel_bar.value = _channel_progress / _channel_time

	if _channel_progress >= _channel_time:
		_complete_channel()


func _start_channel() -> void:
	if _is_channeling or not _player_in_range:
		return
	if not GameManager.is_playing():
		return

	_is_channeling    = true
	_channel_progress = 0.0
	channel_bar.value   = 0.0
	channel_bar.visible = true
	EventBus.channel_started.emit(self)

	if _player_ref != null and _player_ref.has_method("start_laser"):
		_player_ref.start_laser(self)

	print("[CrystalNode] Channel started")


func _cancel_channel() -> void:
	if not _is_channeling:
		return

	_is_channeling    = false
	_channel_progress = 0.0
	channel_bar.value   = 0.0
	channel_bar.visible = false
	EventBus.channel_interrupted.emit(self)

	if _player_ref != null and _player_ref.has_method("stop_laser"):
		_player_ref.stop_laser()

	print("[CrystalNode] Channel cancelled")


func _complete_channel() -> void:
	_is_channeling    = false
	_channel_progress = 0.0
	channel_bar.value   = 0.0
	channel_bar.visible = false

	ResourceManager.add_mined(_yield_amount)
	EventBus.resource_mined.emit(_yield_amount, self)

	var pack_dropped: bool = false
	if randf() < _pack_chance:
		pack_dropped = true
		print("[CrystalNode] 🎴 Card pack dropped!")

	EventBus.channel_completed.emit(self, _yield_amount, pack_dropped)

	if _player_ref != null and _player_ref.has_method("stop_laser"):
		_player_ref.stop_laser()

	print("[CrystalNode] Channel complete! +%d Mined Resources" % _yield_amount)

	if _player_in_range and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_start_channel()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_player_ref      = body
		visual.color     = Color("#a855f7")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		visual.color     = Color("#7b2fff")
		if _is_channeling:
			_cancel_channel()
		_player_ref = null


func _on_player_stunned() -> void:
	if _is_channeling:
		_cancel_channel()
