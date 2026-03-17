# res://entities/player.gd
class_name Player
extends CharacterBody2D

enum State { IDLE, MOVING, CHANNELING, STUNNED }
var current_state: int = State.IDLE

var move_speed: float        = 200.0
var stun_duration: float     = 1.0
var jump_height: float         = 140.0
var time_to_peak: float        = 0.38
var time_to_fall: float        = 0.28
var coyote_time: float         = 0.12
var jump_buffer_time: float    = 0.12
var fast_fall_multiplier: float = 2.2

var _jump_velocity: float   = 0.0
var _jump_gravity: float    = 0.0
var _fall_gravity: float    = 0.0

var _stun_timer: float        = 0.0
var _coyote_timer: float      = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool       = false
var _jump_held: bool          = false
var _facing_right: bool       = true
var _channel_target: Node2D   = null

@onready var visual: ColorRect     = $Visual
@onready var stun_detector: Area2D = $StunDetector
@onready var laser_beam: Line2D    = %LaserBeam


func _ready() -> void:
	var cfg: Dictionary = DataLoader.get_balance_section("player")
	move_speed           = float(cfg.get("move_speed",           200.0))
	stun_duration        = float(cfg.get("stun_duration",        1.0))
	jump_height          = float(cfg.get("jump_height",          140.0))
	time_to_peak         = float(cfg.get("time_to_peak",         0.38))
	time_to_fall         = float(cfg.get("time_to_fall",         0.28))
	coyote_time          = float(cfg.get("coyote_time",          0.12))
	jump_buffer_time     = float(cfg.get("jump_buffer_time",     0.12))
	fast_fall_multiplier = float(cfg.get("fast_fall_multiplier", 2.2))

	_jump_velocity = -(2.0 * jump_height) / time_to_peak
	_jump_gravity  =  (2.0 * jump_height) / (time_to_peak * time_to_peak)
	_fall_gravity  =  (2.0 * jump_height) / (time_to_fall * time_to_fall)

	stun_detector.body_entered.connect(_on_stun_body_entered)
	add_to_group("player")

	# Enforce in code — Inspector alone isn't reliable across scene reloads
	input_pickable = false
	stun_detector.input_pickable = false

	print("[Player] Ready | Speed:%.0f JumpH:%.0f Rise:%.2fs Fall:%.2fs" % \
		[move_speed, jump_height, time_to_peak, time_to_fall])
	print("[Player] Derived | JumpVel:%.1f JumpGrav:%.1f FallGrav:%.1f" % \
		[_jump_velocity, _jump_gravity, _fall_gravity])


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	match current_state:
		State.STUNNED:
			_process_stun(delta)
		_:
			_process_normal(delta)

	_was_on_floor = is_on_floor()


func _process_normal(delta: float) -> void:
	_apply_gravity(delta)
	_update_coyote(delta)
	_update_jump_buffer(delta)
	_apply_jump()
	_apply_variable_jump_cut()
	_apply_horizontal_input()
	move_and_slide()
	_update_state_after_move()
	_update_laser()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
		return

	var grav: float
	if velocity.y < 0.0:
		grav = _jump_gravity
	else:
		grav = _fall_gravity
		if Input.is_action_pressed("move_down"):
			grav *= fast_fall_multiplier

	velocity.y += grav * delta


func _update_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_timer = coyote_time
	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	if is_on_floor():
		_coyote_timer = 0.0


func _can_coyote_jump() -> bool:
	return _coyote_timer > 0.0


func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("move_up"):
		_jump_buffer_timer = jump_buffer_time
		_jump_held = true
	if Input.is_action_just_released("move_up"):
		_jump_held = false
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta


func _has_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0


func _apply_jump() -> void:
	var can_jump: bool = is_on_floor() or _can_coyote_jump()
	if can_jump and _has_buffered_jump():
		velocity.y = _jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		if current_state != State.CHANNELING:
			current_state = State.MOVING


func _apply_variable_jump_cut() -> void:
	if Input.is_action_just_released("move_up") and velocity.y < 0.0:
		velocity.y *= 0.4


func _apply_horizontal_input() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * move_speed
		_facing_right = direction > 0.0
		if current_state != State.CHANNELING:
			current_state = State.MOVING
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		if is_on_floor() and current_state != State.CHANNELING:
			current_state = State.IDLE


func _update_state_after_move() -> void:
	if not is_on_floor() and current_state != State.STUNNED:
		visual.color = Color("#f0c040")
	elif current_state != State.STUNNED:
		visual.color = Color("#f0a500")


func apply_stun() -> void:
	if current_state == State.STUNNED:
		return
	current_state = State.STUNNED
	_stun_timer   = stun_duration
	velocity       = Vector2.ZERO
	visual.color  = Color("#e74c3c")
	EventBus.player_stun_started.emit()
	print("[Player] Stunned for %.1fs" % stun_duration)


func _process_stun(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	_stun_timer -= delta
	if _stun_timer <= 0.0:
		_end_stun()


func _end_stun() -> void:
	current_state = State.IDLE
	_stun_timer   = 0.0
	visual.color  = Color("#f0a500")
	EventBus.player_stun_ended.emit()
	print("[Player] Stun ended")


func _on_stun_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy_creep"):
		apply_stun()


func start_laser(target: Node2D) -> void:
	_channel_target = target
	laser_beam.visible = true
	laser_beam.set_point_position(0, Vector2(0, -24))
	laser_beam.set_point_position(1, to_local(target.global_position + Vector2(0, -20)))


func stop_laser() -> void:
	_channel_target = null
	laser_beam.visible = false
	laser_beam.set_point_position(1, Vector2(0, -24))


func _update_laser() -> void:
	if _channel_target == null or not laser_beam.visible:
		return
	laser_beam.set_point_position(1, to_local(_channel_target.global_position + Vector2(0, -20)))


func is_stunned() -> bool:
	return current_state == State.STUNNED


func is_channeling() -> bool:
	return current_state == State.CHANNELING


func set_channeling(value: bool) -> void:
	if value:
		current_state = State.CHANNELING
	else:
		if current_state == State.CHANNELING:
			current_state = State.IDLE


func get_facing_right() -> bool:
	return _facing_right
