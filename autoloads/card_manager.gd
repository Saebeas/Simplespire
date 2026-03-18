# res://autoloads/card_manager.gd
extends Node

# =============================================================================
# CardManager — Deck, Hand, Draw & Play
# =============================================================================

const HAND_SIZE: int = 4

var deck: Array = []   # Array[CardResource]
var hand: Array = []   # Array[CardResource] — max HAND_SIZE slots (null = empty)
var _active_hand_index: int = -1


func _ready() -> void:
	hand.resize(HAND_SIZE)
	hand.fill(null)
	EventBus.summon_confirmed.connect(_on_summon_confirmed)
	EventBus.summon_reticle_cancelled.connect(_on_reticle_cancelled)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: activate_slot(0)
			KEY_2: activate_slot(1)
			KEY_3: activate_slot(2)
			KEY_4: activate_slot(3)
			KEY_ESCAPE: _cancel_reticle()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_reticle()

func build_and_draw() -> void:
	deck = DataLoader.build_starter_deck()
	deck.shuffle()
	print("[CardManager] Deck built — %d cards" % deck.size())
	for i in range(HAND_SIZE):
		_draw_into_slot(i)


func _draw_into_slot(slot: int) -> void:
	if deck.is_empty():
		print("[CardManager] Deck empty — nothing to draw")
		return
	var card = deck.pop_back()
	hand[slot] = card
	EventBus.card_drawn.emit(card, slot)
	print("[CardManager] Drew '%s' into slot %d" % [card.display_name, slot])


func activate_slot(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= HAND_SIZE:
		return
	if hand[hand_index] == null:
		return
	if _active_hand_index == hand_index:
		_cancel_reticle()
		return
	_active_hand_index = hand_index
	EventBus.summon_reticle_activated.emit(hand_index)
	print("[CardManager] Reticle active for slot %d" % hand_index)


func _cancel_reticle() -> void:
	_active_hand_index = -1
	EventBus.summon_reticle_cancelled.emit()


func _on_reticle_cancelled() -> void:
	_active_hand_index = -1


func _on_summon_confirmed(card: Resource, position: Vector2) -> void:
	if _active_hand_index == -1:
		return
	var slot := _active_hand_index
	var cost: int = card.cost
	if not ResourceManager.spend_mined(cost):
		print("[CardManager] Not enough resources to play '%s'" % card.display_name)
		_cancel_reticle()
		return
	hand[slot] = null
	_active_hand_index = -1
	EventBus.card_played.emit(card, slot, EventBus.PlayMode.PUSH)
	EventBus.minion_played.emit(card, position, EventBus.PlayMode.PUSH)
	print("[CardManager] Played '%s' from slot %d" % [card.display_name, slot])
	_draw_into_slot(slot)


func get_hand() -> Array:
	return hand
