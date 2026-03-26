# res://ui/card_slot_ui.gd
class_name CardSlotUI
extends PanelContainer

@onready var name_label: Label    = $VBox/NameLabel
@onready var cost_label: Label    = $VBox/CostLabel
@onready var role_label: Label    = $VBox/RoleLabel
@onready var key_label:  Label    = $VBox/KeyLabel

var _card: Resource = null
var _slot_index: int = 0
var _flash_timer: float = 0.0
var _is_flashing: bool = false

const COLOR_NORMAL:   Color = Color("#1a1a2e")
const COLOR_ACTIVE:   Color = Color("#4a2080")
const COLOR_EMPTY:    Color = Color("#0d0d1a")
const COLOR_ERROR:    Color = Color("#7a1010")
const COLOR_NO_FUNDS: Color = Color("#3a1010")


func setup(slot_index: int) -> void:
	_slot_index = slot_index
	key_label.text = "  [%d]" % (slot_index + 1)
	set_card(null)


func set_card(card: Resource) -> void:
	_card = card
	if card == null:
		name_label.text = "— Empty —"
		cost_label.text = ""
		role_label.text = ""
		_set_bg_color(COLOR_EMPTY)
	else:
		name_label.text = card.display_name
		cost_label.text = "Cost: %d" % card.cost
		role_label.text = card.get_role_name()
		_set_bg_color(COLOR_NORMAL)


func set_active(active: bool) -> void:
	if _is_flashing:
		return
	if active:
		_set_bg_color(COLOR_ACTIVE)
	else:
		_set_bg_color(COLOR_NORMAL if _card != null else COLOR_EMPTY)


func flash_error() -> void:
	_is_flashing = true
	_flash_timer = 0.4
	_set_bg_color(COLOR_ERROR)


func _process(delta: float) -> void:
	if not _is_flashing:
		return
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_is_flashing = false
		_set_bg_color(COLOR_NORMAL if _card != null else COLOR_EMPTY)

func _set_bg_color(color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color("#6633cc")
	add_theme_stylebox_override("panel", style)
	

func set_capacity_blocked(blocked: bool) -> void:
	if _card == null:
		return
	if blocked:
		name_label.text = _card.display_name + " ✕"
		cost_label.text = "No room!"
	else:
		name_label.text = _card.display_name
		cost_label.text = "Cost: %d" % _card.cost
