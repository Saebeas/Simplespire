class_name ArmyCapacityBar
extends PanelContainer

@onready var fill_container: HBoxContainer = %FillContainer
@onready var total_label: Label = %TotalLabel
@onready var max_label: Label = %MaxLabel
@onready var flash_overlay: ColorRect = %FlashOverlay

var _max_capacity: int = 0
var _groups: Array = []
var _overflow_tween: Tween = null

# Distinct colors per card type
var _group_colors: Array = [
	Color("#3b82f6"), # blue
	Color("#ef4444"), # red
	Color("#22c55e"), # green
	Color("#eab308"), # yellow
	Color("#a855f7"), # purple
	Color("#f97316"), # orange
]

var _seg_widths: Array = []


func _ready() -> void:
	_max_capacity = GameManager.get_max_capacity()
	_update_labels()
	flash_overlay.visible = false

	# Wire to spawner (deferred — node may not be in tree yet)
	call_deferred("_connect_to_spawner")


func _connect_to_spawner() -> void:
	var spawner = get_tree().get_first_node_in_group("minion_spawner")
	if spawner != null:
		spawner.capacity_groups_changed.connect(_on_capacity_groups_changed)
		print("[ArmyCapacityBar] Connected to spawner")


func _on_capacity_groups_changed(groups: Array) -> void:
	_groups = groups
	_rebuild()


func show_overflow(weight: int) -> void:
	if _overflow_tween != null and _overflow_tween.is_valid():
		_overflow_tween.kill()

	# Calculate where overflow would start
	var used: int = 0
	for g in _groups:
		if g.has("capacity_weight"):
			used += g["capacity_weight"]

	var bar_w: float = fill_container.size.x
	var ratio: float = float(used) / float(_max_capacity) if _max_capacity > 0 else 0.0
	var overflow_ratio: float = float(weight) / float(_max_capacity) if _max_capacity > 0 else 0.0

	var start_x: float = bar_w * ratio
	var overflow_w: float = bar_w * overflow_ratio

	# Position and size the flash
	flash_overlay.offset_left = start_x
	flash_overlay.offset_right = start_x + overflow_w
	flash_overlay.offset_top = 0
	flash_overlay.offset_bottom = 0
	flash_overlay.color = Color(1, 0, 0, 0.7)
	flash_overlay.visible = true

	# Blink twice then disappear
	_overflow_tween = create_tween()
	_overflow_tween.tween_property(flash_overlay, "color:a", 0.0, 0.15)
	_overflow_tween.tween_property(flash_overlay, "color:a", 0.7, 0.15)
	_overflow_tween.tween_property(flash_overlay, "color:a", 0.0, 0.15)
	_overflow_tween.tween_property(flash_overlay, "color:a", 0.7, 0.15)
	_overflow_tween.tween_property(flash_overlay, "color:a", 0.0, 0.15)
	_overflow_tween.tween_callback(func(): flash_overlay.visible = false)


func _rebuild() -> void:
	_max_capacity = GameManager.get_max_capacity()

	# Clear old fills
	for child in fill_container.get_children():
		child.queue_free()
	_seg_widths.clear()

	var total_w: float = fill_container.size.x
	if total_w <= 0:
		total_w = 200.0

	# Build colored segments
	var color_idx: int = 0
	for group in _groups:
		var weight: int = group.get("capacity_weight", 1)
		var seg_w: float = (float(weight) / float(_max_capacity)) * total_w if _max_capacity > 0 else 0.0
		_seg_widths.append(seg_w)

		var fill: ColorRect = ColorRect.new()
		fill.custom_minimum_size = Vector2(seg_w, 0)
		fill.color = _group_colors[color_idx % _group_colors.size()]
		fill.size_flags_horizontal = Control.SIZE_FILL
		fill.size_flags_vertical = Control.SIZE_FILL
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill_container.add_child(fill)

		color_idx += 1

	_update_labels()


func _update_labels() -> void:
	var used: int = 0
	for g in _groups:
		if g.has("capacity_weight"):
			used += g["capacity_weight"]
	total_label.text = str(used)
	max_label.text = str(_max_capacity)
