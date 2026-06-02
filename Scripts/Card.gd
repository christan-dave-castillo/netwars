extends Node2D

# Hover feedback signals - emitted when mouse enters/exits card
signal hovered
signal hovered_off

# State change signals - emitted when card status changes
signal affordability_changed(can_afford: bool)

var first_position
var card_slot_card_is_in = null
var card_type
var card_name = ""
var health
var attack
var energy_cost = 0
var defeated = false
var ability_script
var can_afford = true
var is_drawing = false  # Flag to prevent preview during draw animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals to CardManager (which is a sibling of our parent PlayerHand/OpponentHand)
	var card_manager = get_parent().get_parent().get_node_or_null("CardManager")
	if card_manager and card_manager.has_method("connect_card_signals"):
		card_manager.connect_card_signals(self)
	position = Vector2(140, 955)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Only apply energy highlight to cards still in the player's hand
	# Don't apply to cards that have been placed or destroyed
	if card_slot_card_is_in or defeated:
		# Card is placed on board or destroyed - no energy highlighting
		modulate = Color.WHITE
		return
	
	# Check if card can be afforded and update visual feedback
	if get_parent().get_parent().has_node("EnergyManager"):
		var energy_manager = get_parent().get_parent().get_node("EnergyManager")
		if card_name != "":
			var previous_afford = can_afford
			can_afford = energy_manager.can_player_afford_card(card_name)
			
			# Emit signal only when affordability changes
			if can_afford != previous_afford:
				emit_signal("affordability_changed", can_afford)
			
			# Update modulation based on affordability
			if can_afford:
				modulate = Color.WHITE
			else:
				modulate = Color(0.5, 0.5, 0.5, 0.7)  # Grayed out


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
