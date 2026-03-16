extends Node

# =============================================================================
# GameManager — Level State Machine & Central Orchestrator
# =============================================================================
# Owns the top-level level state (PLAYING / PAUSED / WON / LOST).
# Tracks wave number, towers owned, and triggers win/lose conditions.
# Does NOT contain game logic — it delegates to other systems via EventBus.
#
# Other systems call GameManager to query state:
#   GameManager.is_playing()
#   GameManager.get_wave_number()
#   GameManager.get_towers_owned()
# =============================================================================


# -----------------------------------------------------------------------------
# Level State
# -----------------------------------------------------------------------------
enum LevelState {
	PLAYING,
	PAUSED,
	WON,
	LOST
}

var current_state: int = LevelState.PLAYING

# -----------------------------------------------------------------------------
# Level Tracking
# -----------------------------------------------------------------------------
var wave_number: int = 0
var towers_owned: int = 0          ## How many towers the player currently controls
const TOTAL_TOWERS: int = 5


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Listen for win/lose triggers from other systems
	EventBus.level_won.connect(_on_level_won)
	EventBus.level_lost.connect(_on_level_lost)

	# Listen for tower changes to keep towers_owned accurate
	EventBus.tower_captured.connect(_on_tower_captured)
	EventBus.tower_lost.connect(_on_tower_lost)

	# Listen for wave spawns to track wave number
	EventBus.wave_spawned.connect(_on_wave_spawned)


# =============================================================================
# STATE QUERIES
# These are called by other systems to guard actions
# (e.g. WaveSpawner checks is_playing() before spawning)
# =============================================================================

func is_playing() -> bool:
	return current_state == LevelState.PLAYING


func is_paused() -> bool:
	return current_state == LevelState.PAUSED


func get_wave_number() -> int:
	return wave_number


func get_towers_owned() -> int:
	return towers_owned


## Returns a 0.0–1.0 ratio of towers owned.
## Used by EndBoss to scale its HP/damage down.
## 0 towers = 1.0 (full strength), 5 towers = 0.25 (weakest)
func get_end_boss_strength_ratio() -> float:
	# 15% reduction per tower owned, floored at 0.25 (never trivial)
	var reduction: float = towers_owned * 0.15
	return max(0.25, 1.0 - reduction)


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func pause_game() -> void:
	if current_state != LevelState.PLAYING:
		return
	current_state = LevelState.PAUSED
	get_tree().paused = true


func resume_game() -> void:
	if current_state != LevelState.PAUSED:
		return
	current_state = LevelState.PLAYING
	get_tree().paused = false


func _on_level_won() -> void:
	if current_state != LevelState.PLAYING:
		return
	current_state = LevelState.WON
	print("[GameManager] Level WON — Wave: %d | Towers held: %d/%d" \
		% [wave_number, towers_owned, TOTAL_TOWERS])
	# ResourceManager banks overflow before the level fully ends
	ResourceManager.bank_overflow()


func _on_level_lost() -> void:
	if current_state != LevelState.PLAYING:
		return
	current_state = LevelState.LOST
	print("[GameManager] Level LOST — Wave: %d | Towers held: %d/%d" \
		% [wave_number, towers_owned, TOTAL_TOWERS])


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_tower_captured(_tower_index: int) -> void:
	towers_owned = min(towers_owned + 1, TOTAL_TOWERS)
	print("[GameManager] Tower captured — towers owned: %d/%d" \
		% [towers_owned, TOTAL_TOWERS])


func _on_tower_lost(_tower_index: int) -> void:
	towers_owned = max(towers_owned - 1, 0)
	print("[GameManager] Tower lost — towers owned: %d/%d" \
		% [towers_owned, TOTAL_TOWERS])


func _on_wave_spawned(wave_num: int) -> void:
	wave_number = wave_num
	print("[GameManager] Wave %d began" % wave_number)


# =============================================================================
# LEVEL RESET
# Called when loading a new level in the campaign
# =============================================================================

func reset_for_new_level() -> void:
	current_state = LevelState.PLAYING
	wave_number = 0
	towers_owned = 0
	get_tree().paused = false
	ResourceManager.reset_for_new_level()
	print("[GameManager] Level reset — ready for new level")


# =============================================================================
# DEBUG
# =============================================================================

func debug_force_win() -> void:
	EventBus.level_won.emit()


func debug_force_lose() -> void:
	EventBus.level_lost.emit()
