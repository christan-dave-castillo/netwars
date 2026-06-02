extends Node2D

const VALID_COLOR = Color(0, 1, 0, 0.3)  # Green with transparency
const INVALID_COLOR = Color(1, 0, 0, 0.3)  # Red with transparency
const NEUTRAL_COLOR = Color(1, 1, 1, 0)  # Transparent (default)

var parent_slot
var indicator_rect: ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_slot = get_parent()
	
	# Create the indicator rectangle
	indicator_rect = ColorRect.new()
	add_child(indicator_rect)
	indicator_rect.size = Vector2(100, 150)  # Adjust based on card slot size
	indicator_rect.position = Vector2(-50, -75)  # Center it on the slot
	indicator_rect.color = NEUTRAL_COLOR
	indicator_rect.z_index = 10

# Set the indicator to valid (green)
func set_valid() -> void:
	if indicator_rect:
		indicator_rect.color = VALID_COLOR

# Set the indicator to invalid (red)
func set_invalid() -> void:
	if indicator_rect:
		indicator_rect.color = INVALID_COLOR

# Reset the indicator to neutral (transparent)
func reset() -> void:
	if indicator_rect:
		indicator_rect.color = NEUTRAL_COLOR
