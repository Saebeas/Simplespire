# res://ui/card_hand_ui.gd
class_name CardHandUI
extends HBoxContainer

const SLOT_COUNT: int = 4

var _slots: Array = []  # Array of CardSlotUI nodes
@onready var deck_counter: Label = $DeckCounter
@onready var discard_counter: Label = $DiscardCounter

func _ready() -> void:
	var slots := []
	var i := 0
	for child in get_children():
		if child is CardSlotUI:
			child.setup(i)
			slots.append(child)
			i += 1
	setup_slots(slots)
	EventBus.card_drawn.connect(_on_card_drawn)
	EventBus.card_played.connect(_on_card_played)
	EventBus.summon_reticle_activated.connect(_on_reticle_activated)
	EventBus.summon_reticle_cancelled.connect(_on_reticle_cancelled)
	EventBus.insufficient_resources.connect(_on_insufficient_resources)
	EventBus.unit_died.connect(func(_e, _k): _refresh_capacity())


func _update_counters() -> void:
	var total: int = CardManager.deck.size() + CardManager.discard.size() + CardManager.get_hand().reduce(func(count, card): return count + (1 if card != null else 0), 0)
	deck_counter.text = "Deck\n%d/%d" % [CardManager.deck.size(), total]
	discard_counter.text = "Discard\n%d/%d" % [CardManager.discard.size(), total]

func setup_slots(slots: Array) -> void:
	_slots = slots
	_refresh_all()


func _refresh_all() -> void:
	var hand := CardManager.get_hand()
	for i in range(_slots.size()):
		_slots[i].set_card(hand[i])
		_slots[i].set_active(false)
	_update_counters()

func _refresh_capacity() -> void:
	var hand := CardManager.get_hand()
	for i in range(_slots.size()):
		var card = hand[i]
		if card != null:
			_slots[i].set_capacity_blocked(
				not GameManager.has_capacity_for(card.capacity_weight)
			)


func _on_card_drawn(_card: Resource, slot: int) -> void:
	if slot >= _slots.size():
		return
	_slots[slot].set_card(_card)
	_slots[slot].set_active(false)
	_update_counters()
	_refresh_capacity()


func _on_card_played(_card: Resource, slot: int, _mode: int) -> void:
	if slot >= _slots.size():
		return
	_slots[slot].set_card(null)
	_slots[slot].set_active(false)
	_update_counters()
	_refresh_capacity()


func _on_reticle_activated(hand_index: int) -> void:
	_refresh_capacity()
	for i in range(_slots.size()):
		_slots[i].set_active(i == hand_index)


func _on_reticle_cancelled() -> void:
	for slot in _slots:
		slot.set_active(false)


func _on_insufficient_resources(_type: String, _needed: int, _have: int) -> void:
	for slot in _slots:
		slot.flash_error()
