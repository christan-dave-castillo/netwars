extends Node2D

# ============================================================================
# SLOT STATE TRACKING - Used by AI deployment system
# ============================================================================

var card_in_slot = false
var occupied = false  # CRITICAL: AI system uses this to track slot availability
var card_type = "Attacker"  # Default type for opponent attack slots
var card_currently_in_slot = null

func _ready() -> void:
	# Determine card_type based on position or name
	# Support slots are at Y=250, Attack slots are at Y=400
	if position.y < 300:  # Support slots at Y=250
		card_type = "Support"
	else:  # Attack slots at Y=400
		card_type = "Attacker"

func reset_slot() -> void:
	card_in_slot = false
	occupied = false
	card_currently_in_slot = null
	if has_node("Area2D/CollisionShape2D"):
		get_node("Area2D/CollisionShape2D").disabled = false
	if has_node("Sprite2D"):
		get_node("Sprite2D").visible = true
