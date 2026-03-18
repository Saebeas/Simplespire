# res://ui/summon_reticle.gd
class_name SummonReticle
extends Node2D

var _active: bool = false
var _card: Resource = null
var _pulse: float = 0.0

const GROUND_Y:    float = 600.0
const RADIUS:      float = 32.0
const COLOR_RING:  Color = Color("#aa44ff")
const COLOR_FILL:  Color = Color(0.4, 0.1, 0.8, 0.25)


func _ready() -> void:
	visible = false
	EventBus.summon_reticle_activated.connect(_on_activated)
	EventBus.summon_reticle_cancelled.connect(_on_cancelled)
	EventBus.card_played.connect(_on_card_played)


func _on_activated(hand_index: int) -> void:
	_card = CardManager.get_hand()[hand_index]
	_active = true
	visible = true


func _on_cancelled() -> void:
	_active = false
	visible = false
	_card = null


func _on_card_played(_card: Resource, _slot: int, _mode: int) -> void:
	_active = false
	visible = false
	_card = null


func _process(delta: float) -> void:
	if not _active:
		return
	_pulse += delta * 3.0
	var mouse := get_global_mouse_position()
	global_position = Vector2(mouse.x, GROUND_Y)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var scale_factor := 1.0 + sin(_pulse) * 0.08
	var r := RADIUS * scale_factor
	draw_circle(Vector2.ZERO, r, COLOR_FILL)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, COLOR_RING, 2.0)
	draw_line(Vector2(-r - 6, 0), Vector2(-r + 10, 0), COLOR_RING, 1.5)
	draw_line(Vector2( r - 10, 0), Vector2( r + 6,  0), COLOR_RING, 1.5)
	draw_line(Vector2(0, -r - 6), Vector2(0, -r + 10), COLOR_RING, 1.5)
	draw_line(Vector2(0,  r - 10), Vector2(0,  r + 6), COLOR_RING, 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _card == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			EventBus.summon_confirmed.emit(_card, global_position)
