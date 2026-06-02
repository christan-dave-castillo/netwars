extends Node2D

# Mouse button signals
signal left_mouse_button_clicked
signal left_mouse_button_released

# Input action signals - emitted when specific objects are clicked
# Prevents tight coupling between InputManager and target nodes
signal card_clicked(card: Node)
signal deck_clicked
signal opponent_card_clicked(card: Node)

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4
const COLLISION_MASK_OPPONENT_CARD = 8

var card_manager_reference
var deck_reference
var input_disabled


func _ready() -> void:
	card_manager_reference = get_parent().get_node_or_null("CardManager")
	deck_reference = get_parent().get_node_or_null("Deck")
	if not card_manager_reference:
		push_error("InputManager: CardManager node not found!")
	if not deck_reference:
		push_error("InputManager: Deck node not found!")



func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			emit_signal("left_mouse_button_clicked")
			raycast_at_cursor()
		else:
			emit_signal("left_mouse_button_released")


func raycast_at_cursor():
	if input_disabled:
		return
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_CARD:
			var card_found = result[0].collider.get_parent()
			if card_found:
				# Emit signal instead of calling card_manager.card_clicked() directly
				emit_signal("card_clicked", card_found)
		elif result_collision_mask == COLLISION_MASK_DECK:
			# Emit signal instead of calling deck.draw_card() directly
			emit_signal("deck_clicked")
		elif result_collision_mask == COLLISION_MASK_OPPONENT_CARD:
			# Emit signal instead of calling battle_manager.enemy_card_selected() directly
			emit_signal("opponent_card_clicked", result[0].collider.get_parent())
