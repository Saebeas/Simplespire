# res://autoloads/card_manager.gd
extends Node

# =============================================================================
# CardManager — Deck, Hand, Draw & Play
# =============================================================================

const HAND_SIZE: int = 4

var deck: Array = []   # Array[CardResource]
var hand: Array = []   # Array[CardResource] — max HAND_SIZE slots (null = empty)
var discard: Array = []
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
		if discard.is_empty():
			print("[CardManager] Deck and discard both empty — nothing to draw")
			return
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
		print("[CardManager] Reshuffled %d cards from discard into deck" % deck.size())
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
	print("[CardManager] CONFIRMED: %s | capacity_weight: %d" % [card.display_name, card.capacity_weight])
	if _active_hand_index == -1:
		return
	var slot := _active_hand_index
	var cost: int = card.cost
	if not ResourceManager.spend_mined(cost):
		print("[CardManager] Not enough resources to play '%s'" % card.display_name)
		_cancel_reticle()
		return
	GameManager.register_minion(card.capacity_weight)
	print("[DEBUG] used: %d, max: %d, can_play: %s" % \
		[GameManager.get_minion_count(), GameManager.get_max_capacity(), GameManager.has_capacity_for(0)])
	if not GameManager.has_capacity_for(0):
		print("[CardManager] Army at capacity! (%d/%d)" % \
			[GameManager.get_minion_count(), GameManager.get_max_capacity()])
		ResourceManager.add_mined(cost)
		_cancel_reticle()
		GameManager.unregister_minion(card.capacity_weight)
		return
	discard.append(card)
	hand[slot] = null
	_active_hand_index = -1
	var garrison_tower: Node = _find_garrison_tower(position)
	if garrison_tower != null:
		var garrison_pos: Vector2 = garrison_tower.get_garrison_position()
		EventBus.card_played.emit(card, slot, EventBus.PlayMode.GARRISON)
		EventBus.minion_played.emit(card, garrison_pos, EventBus.PlayMode.GARRISON)
	else:
		EventBus.card_played.emit(card, slot, EventBus.PlayMode.PUSH)
		EventBus.minion_played.emit(card, position, EventBus.PlayMode.PUSH)
	print("[CardManager] Played '%s' from slot %d" % [card.display_name, slot])
	_draw_into_slot(slot)


func get_hand() -> Array:
	return hand

func _find_garrison_tower(pos: Vector2) -> Node:
	var closest: Node = null
	var closest_dist: float = 80.0
	for tower in get_tree().get_nodes_in_group("player_towers"):
		if not tower.has_garrison_slot():
			continue
		var dist: float = abs(tower.global_position.x - pos.x)
		if dist < closest_dist:
			closest_dist = dist
			closest = tower
	return closest
