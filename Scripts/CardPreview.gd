extends Control

# Completely passive preview node - never touches input or affects other nodes
var current_preview_card = null
var preview_node: Node2D = null

func _ready() -> void:
	# Set to MOUSE_FILTER_IGNORE so this node never intercepts any mouse events
	mouse_filter = MOUSE_FILTER_IGNORE
	
	# Position and scale are fixed - set once and never changed
	# Larger scale (2.5x) requires position inset from edges to stay fully visible
	position = Vector2(1750, 880)
	scale = Vector2(3, 3)
	
	# Layer settings
	z_index = 100
	
	# Start hidden
	hide_preview()

func show_card_preview(card: Node) -> void:
	if card == null:
		return
	
	if current_preview_card == card:
		return  # Already showing this card
	
	current_preview_card = card
	
	# Clear old preview
	if preview_node:
		preview_node.queue_free()
	
	# Duplicate card's visual without script
	preview_node = card.duplicate(false)
	preview_node.set_script(null)
	preview_node.position = Vector2.ZERO
	preview_node.scale = Vector2(1.0, 1.0)
	
	# Reduce description text font size so it fits without scrolling (fix: description too large)
	if preview_node.has_node("Ability"):
		var ability_label = preview_node.get_node("Ability")
		if ability_label is RichTextLabel:
			# Set smaller font size for description text
			ability_label.add_theme_font_size_override("normal_font_size", 13)
			# Set description text color to black for readability (fix: description hard to read)
			ability_label.add_theme_color_override("font_color", Color.BLACK)
			ability_label.modulate = Color.WHITE
	
	# Remove interactive components
	if preview_node.has_node("Area2D"):
		preview_node.get_node("Area2D").queue_free()
	
	add_child(preview_node)
	visible = true

func hide_preview() -> void:
	current_preview_card = null
	visible = false
	
	if preview_node:
		preview_node.queue_free()
		preview_node = null
