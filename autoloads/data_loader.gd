extends Node

# =============================================================================
# DataLoader — Reads balance.json and builds typed CardResource instances.
# =============================================================================
# Runs once at startup. All other systems pull data from here.
#
# USAGE:
#   DataLoader.balance                          # full raw Dictionary
#   DataLoader.get_card("crystal_golem")        # returns CardResource
#   DataLoader.build_starter_deck()             # returns Array[CardResource]
#   DataLoader.get_balance_section("player")    # returns Dictionary
# =============================================================================

const BALANCE_PATH := "res://resources/cards_data/balance.json"

## Full parsed balance dictionary — available after _ready()
var balance: Dictionary = {}

## All card definitions keyed by id — e.g. cards["crystal_golem"]
var cards: Dictionary = {}

## True once loading completed without errors
var is_loaded: bool = false


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_balance()


func _load_balance() -> void:
	# -- Open file --
	if not FileAccess.file_exists(BALANCE_PATH):
		push_error("[DataLoader] balance.json not found at: " + BALANCE_PATH)
		return

	var file := FileAccess.open(BALANCE_PATH, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open balance.json")
		return

	var raw_text := file.get_as_text()
	file.close()

	# -- Parse JSON --
	var json := JSON.new()
	var result := json.parse(raw_text)
	if result != OK:
		push_error("[DataLoader] JSON parse error at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message()
		])
		return

	balance = json.data
	print("[DataLoader] balance.json loaded successfully")

	# -- Build card definitions --
	_build_card_definitions()
	is_loaded = true


func _build_card_definitions() -> void:
	if not balance.has("card_definitions"):
		push_error("[DataLoader] balance.json missing 'card_definitions' key")
		return

	var defs: Dictionary = balance["card_definitions"]
	for card_id in defs.keys():
		var d: Dictionary = defs[card_id]
		var card := CardResource.new()
		card.id             = card_id
		card.display_name   = d.get("display_name", card_id)
		card.role           = int(d.get("role", CardResource.Role.BRUISER))
		card.rarity         = int(d.get("rarity", CardResource.Rarity.COMMON))
		card.cost           = int(d.get("cost", 20))
		card.hp             = int(d.get("hp", 100))
		card.dps            = float(d.get("dps", 10.0))
		card.attack_range   = float(d.get("attack_range", 0.0))
		card.move_speed     = float(d.get("move_speed", 120.0))
		card.spawn_count    = int(d.get("spawn_count", 1))
		card.boss_damage_multiplier = float(d.get("boss_damage_multiplier", 1.0))
		cards[card_id] = card

	print("[DataLoader] Built %d card definitions" % cards.size())


# =============================================================================
# PUBLIC API
# =============================================================================

## Returns a CardResource by id, or null if not found.
func get_card(card_id: String) -> CardResource:
	if cards.has(card_id):
		return cards[card_id]
	push_warning("[DataLoader] Card not found: " + card_id)
	return null


## Returns a raw balance sub-dictionary by section name.
## e.g. get_balance_section("player") returns the player config block.
func get_balance_section(section: String) -> Dictionary:
	if balance.has(section):
		return balance[section]
	push_warning("[DataLoader] Balance section not found: " + section)
	return {}


## Builds and returns a flat Array[CardResource] representing the starter deck.
## Duplicates are included — e.g. Crystal Golem x3 = 3 entries pointing to
## the same CardResource instance (memory-efficient, safe since Resources
## are read-only data containers).
func build_starter_deck() -> Array:
	var deck: Array = []
	if not balance.has("starter_deck"):
		push_error("[DataLoader] balance.json missing 'starter_deck' key")
		return deck

	var entries: Array = balance["starter_deck"]
	for entry in entries:
		var card_id: String = entry.get("id", "")
		var count: int = int(entry.get("count", 1))
		var card := get_card(card_id)
		if card == null:
			continue
		for i in range(count):
			deck.append(card)

	print("[DataLoader] Starter deck built — %d cards" % deck.size())
	return deck
