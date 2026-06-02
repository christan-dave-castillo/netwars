extends Node2D

# Card placement signals - emitted when player places cards on battlefield
signal card_placed_on_battlefield(card: Node, _slot: Node)
signal support_card_activated(card: Node, ability_script: Node)

# Card state signals
signal attack_card_played_this_turn(card: Node)

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1
const DEFAULT_CARD_BIGGER_SCALE = 1.25

var screen_size
var card_being_dragged
var drag_offset = Vector2.ZERO
var currently_hovered_card = null
var player_hand_reference
var played_attack_card_this_turn = false
var selected_monster
var card_preview

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	
	# Connect to InputManager signals instead of having it call us directly
	var input_manager = get_parent().get_node_or_null("InputManager")
	if input_manager:
		if input_manager.is_connected("card_clicked", Callable(self, "_on_card_clicked")):
			input_manager.disconnect("card_clicked", Callable(self, "_on_card_clicked"))
		input_manager.connect("card_clicked", Callable(self, "_on_card_clicked"))
	
	$"../InputManager".connect("left_mouse_button_released", Callable(self, "on_left_click_released"))
	
	# Get reference to card preview from the scene
	var ui_layer = get_parent().get_node_or_null("UILayer")
	if ui_layer:
		card_preview = ui_layer.get_node_or_null("CardPreview")
	
	# Fallback: create preview if not found in scene
	if card_preview == null:
		card_preview = Control.new()
		card_preview.script = preload("res://Scripts/CardPreview.gd")
		if get_parent().has_node("UILayer"):
			get_parent().get_node("UILayer").add_child(card_preview)
		else:
			get_parent().add_child(card_preview)

# Signal handler: called when InputManager emits card_clicked signal
func _on_card_clicked(card: Node) -> void:
	card_clicked(card)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_position = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_position.x, 0, screen_size.x), 
		clamp(mouse_position.y, 0, screen_size.y))
		
		# Update slot indicators while dragging - only if card has required properties
		if "card_type" in card_being_dragged and "card_name" in card_being_dragged:
			update_slot_indicators(card_being_dragged)

func card_clicked(card):
	if card.card_slot_card_is_in:
		if $"../BattleManager".is_opponents_turn:
			return
		if $"../BattleManager".player_is_attacking:
			return
		if card in $"../BattleManager".player_cards_that_attacked_this_turn:
			return
		
		if card.card_type != "Attacker":
			return
		
		if $"../BattleManager".opponent_cards_on_battlefield.size() == 0:
			$"../BattleManager".direct_attack(card, "Player")
		else:
			select_card_for_battle(card)
	else:
		start_drag(card)

func select_card_for_battle(card):
	if selected_monster:
		if selected_monster == card:
			card.position.y += 20
			selected_monster = null
		else:
			selected_monster.position.y += 20
			selected_monster = card
			card.position.y -= 20
	else:
		selected_monster = card
		card.position.y -= 20

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	# Hide preview while dragging
	if card_preview:
		card_preview.hide_preview()

func finish_drag():	
	var card_slot_found = raycast_check_for_card_slot()
	
	if not card_slot_found:
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Determine card type for special handling
	var is_attack_card = card_being_dragged.card_type == "Attacker"
	var slot_is_occupied = card_slot_found.card_in_slot
	
	# RULE: Support cards CAN go on occupied slots, attack cards CANNOT
	if is_attack_card and slot_is_occupied:
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Check slot type matches card type (support cards don't have matching slots, so skip this for them)
	if is_attack_card and card_being_dragged.card_type != card_slot_found.card_type:
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Check if already played an attack card this turn (only for attack cards)
	if is_attack_card and played_attack_card_this_turn:
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Check if it's opponent's turn
	if $"../BattleManager".is_opponents_turn:
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Check if player is attacking
	if $"../BattleManager".player_is_attacking:
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Check if player has enough energy
	if not $"../EnergyManager".can_player_afford_card(card_being_dragged.card_name):
		reset_all_slot_indicators()
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
		return
	
	# Emit signal to notify listeners that card will be placed (e.g., spend energy)
	emit_signal("card_placed_on_battlefield", card_being_dragged, card_slot_found)
	
	# Spend player energy
	$"../EnergyManager".spend_player_energy(card_being_dragged.card_name)
	
	card_being_dragged.card_slot_card_is_in = card_slot_found
	player_hand_reference.remove_card_from_hand(card_being_dragged)
	card_being_dragged.position = card_slot_found.position
	# Reset card scale to normal after placement
	card_being_dragged.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	
	if is_attack_card:
		# ATTACK CARD: Stays on slot
		card_slot_found.card_in_slot = true
		if card_slot_found.has_node("Area2D/CollisionShape2D"):
			card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
		# Emit signal instead of directly appending to array
		emit_signal("attack_card_played_this_turn", card_being_dragged)
		played_attack_card_this_turn = true
		# Reset indicators after attack card is placed
		reset_all_slot_indicators()
	else:
		# SUPPORT CARD: Activates immediately, then destroyed (slot becomes available)
		card_slot_found.card_in_slot = true
		if card_slot_found.has_node("Area2D/CollisionShape2D"):
			card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
		
		# Emit signal for support card activation
		emit_signal("support_card_activated", card_being_dragged, card_being_dragged.ability_script)
		
		# Trigger ability immediately
		if "ability_script" in card_being_dragged and card_being_dragged.ability_script:
			card_being_dragged.ability_script.trigger_ability($"../BattleManager", card_being_dragged, $"../InputManager")
		
		# Wait 0.5 seconds before destroying support card (slot becomes available)
		await get_tree().create_timer(0.5).timeout
		
		# Destroy support card after ability triggers
		$"../BattleManager".destroy_card(card_being_dragged, "Player")
		
		# Reset indicators AFTER support card is destroyed
		reset_all_slot_indicators()
	
	card_being_dragged = null
	

func unselect_selected_monster():
	if selected_monster:
		selected_monster.position.y += 20
		selected_monster = null
	# Also clear hovered card state when unselecting
	if currently_hovered_card:
		highlight_card(currently_hovered_card, false)
		currently_hovered_card = null

func connect_card_signals(card):
	# Disconnect any existing connections to prevent multiple signal connections
	if card.is_connected("hovered", Callable(self, "on_hovered_over_card")):
		card.disconnect("hovered", Callable(self, "on_hovered_over_card"))
	if card.is_connected("hovered_off", Callable(self, "on_hovered_off_card")):
		card.disconnect("hovered_off", Callable(self, "on_hovered_off_card"))
	
	card.connect("hovered", Callable(self, "on_hovered_over_card"))
	card.connect("hovered_off", Callable(self, "on_hovered_off_card"))

func on_left_click_released():
	if card_being_dragged:
		finish_drag()


func on_hovered_over_card(card):
	if card.card_slot_card_is_in:
		return
	# Block hover if card is still being drawn
	if "is_drawing" in card and card.is_drawing:
		return
	
	# If already hovering a different card, scale it back down
	if currently_hovered_card != null and currently_hovered_card != card:
		currently_hovered_card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		currently_hovered_card.z_index = 1
	
	# Scale this card up
	currently_hovered_card = card
	card.scale = Vector2(DEFAULT_CARD_BIGGER_SCALE, DEFAULT_CARD_BIGGER_SCALE)
	card.z_index = 2
	
	# Show card preview
	if card_preview:
		card_preview.show_card_preview(card)

func on_hovered_off_card(card):
	# Only reset if this is the currently hovered card
	if currently_hovered_card == card:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1
		currently_hovered_card = null
		# Hide card preview
		if card_preview:
			card_preview.hide_preview()

func highlight_card(card, hovered):
	if card.card_slot_card_is_in:
		return
	if hovered:
		card.scale = Vector2(DEFAULT_CARD_BIGGER_SCALE, DEFAULT_CARD_BIGGER_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return card_with_highest_z_index(result)
	return null

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	
	# Get all results and filter by card type match and availability
	if result.size() > 0:
		# First, try to find a slot that matches the dragged card type AND is available
		if card_being_dragged and "card_type" in card_being_dragged:
			for ray_result in result:
				var slot = ray_result.collider.get_parent()
				# Check: slot must match card type AND be unoccupied
				if "card_type" in slot and slot.card_type == card_being_dragged.card_type:
					if "card_in_slot" in slot and not slot.card_in_slot:
						return slot
		
		# No available matching slot found - return null
		return null
	return null

func card_with_highest_z_index(card):
	var highest_z_card = card[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, card.size()):
		var current_card = card[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card


func reset_played_attack():
	played_attack_card_this_turn = false

# Update slot indicators based on card type and validity (PLAYER SIDE ONLY)
func update_slot_indicators(card) -> void:
	if card == null:
		reset_all_slot_indicators()
		return
	
	reset_all_slot_indicators()
	
	# Get all card slots
	var card_slots = $"../CardSlots".get_children()
	
	for slot in card_slots:
		# IMPORTANT: Only show indicators for PLAYER slots, not enemy slots
		if slot.name.begins_with("EnemyCardSlot"):
			continue
		
		# Skip slots that don't have card_type property
		if not "card_type" in slot:
			continue
		
		if not slot.has_node("CardSlotIndicator"):
			continue
		
		var indicator = slot.get_node("CardSlotIndicator")
		
		# Check if slot matches card type
		if slot.card_type != card.card_type:
			indicator.set_invalid()
			continue
		
		# Check if slot is already occupied (attack cards cannot go on occupied slots)
		if card.card_type == "Attacker" and "card_in_slot" in slot and slot.card_in_slot:
			indicator.set_invalid()
			continue
		
		# Support cards CAN go on occupied slots, so skip this check for them
		
		# Check if player has enough energy
		if not $"../EnergyManager".can_player_afford_card(card.card_name):
			indicator.set_invalid()
			continue
		
		# Check if it's opponent's turn
		if $"../BattleManager".is_opponents_turn:
			indicator.set_invalid()
			continue
		
		# Check if player is attacking
		if $"../BattleManager".player_is_attacking:
			indicator.set_invalid()
			continue
		
		# Check if already played attack card this turn
		if card.card_type == "Attacker" and played_attack_card_this_turn:
			indicator.set_invalid()
			continue
		
		# All checks passed - slot is valid
		indicator.set_valid()

# Reset all slot indicators to neutral (PLAYER SIDE ONLY)
func reset_all_slot_indicators() -> void:
	var card_slots = $"../CardSlots".get_children()
	for slot in card_slots:
		# Only reset indicators on player slots
		if slot.name.begins_with("EnemyCardSlot"):
			continue
		
		if slot.has_node("CardSlotIndicator"):
			var indicator = slot.get_node("CardSlotIndicator")
			indicator.reset()
