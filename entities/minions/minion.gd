# res://entities/minions/minion.gd
class_name Minion
extends CharacterBody2D

var display_name: String = ""
var max_hp: float = 100.0
var hp: float = 100.0
var dps: float = 10.0
var attack_range: float = 0.0
var move_speed: float = 120.0
var boss_damage_multiplier: float = 1.0
var role: int = 0

const GRAVITY: float = 980.0

@onready var visual: ColorRect   = $Visual
@onready var health_bar: ProgressBar = $HealthBar


func setup(card: CardResource) -> void:
	display_name          = card.display_name
	max_hp                = float(card.hp)
	hp                    = max_hp
	dps                   = card.dps
	attack_range          = card.attack_range
	move_speed            = card.move_speed
	boss_damage_multiplier = card.boss_damage_multiplier
	role                  = card.role
	_apply_role_color()
	health_bar.value = 1.0
	add_to_group("player_minions")
	EventBus.unit_spawned.emit(self, display_name)
	print("[Minion] Spawned: %s | HP:%.0f DPS:%.1f SPD:%.0f" \
		% [display_name, max_hp, dps, move_speed])


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	velocity.x = move_speed
	move_and_slide()


func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	health_bar.value = hp / max_hp
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.unit_died.emit(self, null)
	print("[Minion] %s died" % display_name)
	queue_free()


func _apply_role_color() -> void:
	match role:
		CardResource.Role.TANK:      visual.color = Color("#4488ff")
		CardResource.Role.MELEE_DPS: visual.color = Color("#ff4444")
		CardResource.Role.RANGED:    visual.color = Color("#44ff88")
		CardResource.Role.SWARM:     visual.color = Color("#ffff44")
		CardResource.Role.SIEGE:     visual.color = Color("#ff8844")
		CardResource.Role.BRUISER:   visual.color = Color("#aa44ff")
