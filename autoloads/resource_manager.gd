extends Node

# =============================================================================
# ResourceManager — Dual-Currency Ledger
# =============================================================================
# Tracks Mined Resources and Monster Loot separately.
# They are NEVER interchangeable — each has dedicated sources and sinks.
#
# ALL currency changes must go through this manager.
# Direct variable mutation from outside is intentionally not possible.
#
# USAGE:
#   ResourceManager.add_mined(50)
#   ResourceManager.spend_mined(30)   # returns false if insufficient
#   ResourceManager.add_loot(20)
#   ResourceManager.spend_loot(50)    # returns false if insufficient
# =============================================================================


# -----------------------------------------------------------------------------
# Current Level Currency
# These reset at the start of each level.
# -----------------------------------------------------------------------------
var mined_resources: int = 0
var monster_loot: int = 0

# -----------------------------------------------------------------------------
# Overflow Currency (carries between levels)
# Banked at level end, used in the between-level shop.
# -----------------------------------------------------------------------------
var overflow_mined: int = 0
var overflow_loot: int = 0


# =============================================================================
# MINED RESOURCES
# Source: crystal node harvesting, miner passive ticks
# Sink:   playing cards from hand (card costs)
# =============================================================================

func add_mined(amount: int) -> void:
	if amount <= 0:
		return
	mined_resources += amount
	EventBus.resources_changed.emit(mined_resources, monster_loot)


func spend_mined(amount: int) -> bool:
	if amount <= 0:
		return true
	if mined_resources < amount:
		EventBus.insufficient_resources.emit("mined", amount, mined_resources)
		return false
	mined_resources -= amount
	EventBus.resources_changed.emit(mined_resources, monster_loot)
	return true


func get_mined() -> int:
	return mined_resources


# =============================================================================
# MONSTER LOOT
# Source: enemy creep deaths, boss kills
# Sink:   purchasing miners
# =============================================================================

func add_loot(amount: int) -> void:
	if amount <= 0:
		return
	monster_loot += amount
	EventBus.resources_changed.emit(mined_resources, monster_loot)


func spend_loot(amount: int) -> bool:
	if amount <= 0:
		return true
	if monster_loot < amount:
		EventBus.insufficient_resources.emit("loot", amount, monster_loot)
		return false
	monster_loot -= amount
	EventBus.resources_changed.emit(mined_resources, monster_loot)
	return true


func get_loot() -> int:
	return monster_loot


# =============================================================================
# LEVEL TRANSITIONS
# =============================================================================

## Called at level end — banks current resources into overflow before reset.
func bank_overflow() -> void:
	overflow_mined += mined_resources
	overflow_loot += monster_loot


## Called at the start of a new level — clears current currencies.
## Overflow is preserved until spent in the between-level shop.
func reset_for_new_level() -> void:
	mined_resources = 0
	monster_loot = 0
	EventBus.resources_changed.emit(mined_resources, monster_loot)


## Called when overflow is spent in the shop.
func spend_overflow_mined(amount: int) -> bool:
	if overflow_mined < amount:
		return false
	overflow_mined -= amount
	return true


func spend_overflow_loot(amount: int) -> bool:
	if overflow_loot < amount:
		return false
	overflow_loot -= amount
	return true


# =============================================================================
# DEBUG HELPERS
# Remove before shipping — only used with DebugOverlay (Task 31)
# =============================================================================

func debug_add_all(amount: int = 999) -> void:
	add_mined(amount)
	add_loot(amount)


func debug_print_state() -> void:
	print("[ResourceManager] Mined: %d | Loot: %d | Overflow Mined: %d | Overflow Loot: %d" \
		% [mined_resources, monster_loot, overflow_mined, overflow_loot])
