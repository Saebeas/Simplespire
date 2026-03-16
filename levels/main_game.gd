extends Node2D

# =============================================================================
# MainGame — Root scene for one level.
# Provides lane layout constants and world-space position helpers.
# All spawned entities go into the typed container children of World.
# =============================================================================

## Pixel offset of the player base from the left world edge.
## Gives visual breathing room so the base isn't clipped at the camera limit.
const PLAYER_BASE_X: float = 300.0

## Total pixel width of the lane (Player Base at 0 → Enemy Base at 8960)
const LANE_WIDTH: int = 8960

## Y position of the top surface of the ground (physics + visual)
const GROUND_Y: float = 600.0

## Normalized positions for each lane landmark (0.0–1.0)
const POS_PLAYER_BASE: float = 0.0
const POS_TOWERS: Array = [0.15, 0.30, 0.50, 0.70, 0.85]
const POS_ENEMY_BASE: float = 1.0

# ---------------------------------------------------------------------------
# Cached container references — systems spawn their nodes into these
# ---------------------------------------------------------------------------
@onready var units_container: Node2D = %Units
@onready var towers_container: Node2D = %Towers
@onready var crystal_nodes_container: Node2D = %CrystalNodes
@onready var miners_container: Node2D = %Miners
@onready var bases_container: Node2D = %Bases
@onready var camera: Camera2D = %Camera2D


func _ready() -> void:
	_setup_camera()
	print("[MainGame] Scene ready | Lane: %dpx | Ground Y: %.0f" % [LANE_WIDTH, GROUND_Y])
	_print_landmark_positions()
	# Wire camera to player once player is in scene
	_attach_camera_to_player()


func _attach_camera_to_player() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("[MainGame] No player found to attach camera to")
		return
	# Re-parent camera to player so it follows automatically
	camera.reparent(player)
	camera.position = Vector2.ZERO
	print("[MainGame] Camera attached to player")

# =============================================================================
# PUBLIC HELPERS — called by other systems to get world-space positions
# =============================================================================

## Converts a normalized lane position (0.0–1.0) to world X in pixels.
## Example: get_world_x(0.15) → 1344.0  (Tower 1's X coordinate)
func get_world_x(normalized_pos: float) -> float:
	return normalized_pos * float(LANE_WIDTH)


## Returns the Y coordinate of the ground surface.
func get_ground_y() -> float:
	return GROUND_Y


## Returns the world-space Vector2 at the base of tower[index] (0–4).
func get_tower_position(tower_index: int) -> Vector2:
	if tower_index < 0 or tower_index >= POS_TOWERS.size():
		push_error("[MainGame] Tower index out of range: %d" % tower_index)
		return Vector2.ZERO
	return Vector2(get_world_x(POS_TOWERS[tower_index]), GROUND_Y)


## Returns world X of the player base (left end of lane).
func get_player_base_x() -> float:
	return PLAYER_BASE_X


## Returns world X of the enemy base (right end of lane).
func get_enemy_base_x() -> float:
	return get_world_x(POS_ENEMY_BASE)


# =============================================================================
# PRIVATE
# =============================================================================

func _setup_camera() -> void:
	camera.limit_left   = 0
	camera.limit_right  = LANE_WIDTH
	camera.limit_top    = -400   # Headroom above ground for platformer jumps
	camera.limit_bottom = 720
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed   = 6.0


func _print_landmark_positions() -> void:
	print("  Player Base → x=%.0f" % get_player_base_x())
	for i: int in range(POS_TOWERS.size()):
		var pos: Vector2 = get_tower_position(i)
		print("  Tower %d     → x=%.0f, y=%.0f" % [i + 1, pos.x, pos.y])
	print("  Enemy Base  → x=%.0f" % get_enemy_base_x())
