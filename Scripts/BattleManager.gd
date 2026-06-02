extends Node

# Health signals - emitted when health changes
signal player_health_changed(new_health: int)
signal opponent_health_changed(new_health: int)

# Attack signals - emitted when attacks occur
signal direct_attack_occurred(attacking_card: Node, defender: String, damage: int)
signal card_attack_occurred(attacking_card: Node, defending_card: Node, damage: int)

# Card management signals
signal card_added_to_battlefield(card: Node, is_player_card: bool)

const CARD_SMALLER_SCALE = 1
const CARD_MOVE_SPEED = 0.4
const STARTING_HEALTH = 10
const BATTLE_POS_OFFSET = 25


var battle_timer
var empty_attack_cards_slots = []
var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var player_health
var opponent_health
var is_opponents_turn = false
var player_is_attacking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = get_parent().get_node_or_null("BattleTimer")
	if not battle_timer:
		push_error("BattleManager: BattleTimer node not found!")
		return
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	var enemy_slot_1 = get_parent().get_node_or_null("CardSlots/EnemyCardSlot")
	var enemy_slot_2 = get_parent().get_node_or_null("CardSlots/EnemyCardSlot2")
	var enemy_slot_3 = get_parent().get_node_or_null("CardSlots/EnemyCardSlot3")
	
	if enemy_slot_1:
		empty_attack_cards_slots.append(enemy_slot_1)
	if enemy_slot_2:
		empty_attack_cards_slots.append(enemy_slot_2)
	if enemy_slot_3:
		empty_attack_cards_slots.append(enemy_slot_3)

	player_health = STARTING_HEALTH
	var player_health_label = get_parent().get_node_or_null("PlayerHealth")
	if player_health_label:
		player_health_label.text = str(player_health)
	
	opponent_health = STARTING_HEALTH
	var opponent_health_label = get_parent().get_node_or_null("OpponentHealth")
	if opponent_health_label:
		opponent_health_label.text = str(opponent_health)
	
	# Connect to CardManager signals instead of being called directly
	var card_manager = get_parent().get_node_or_null("CardManager")
	if card_manager:
		if card_manager.is_connected("card_placed_on_battlefield", Callable(self, "_on_card_placed_on_battlefield")):
			card_manager.disconnect("card_placed_on_battlefield", Callable(self, "_on_card_placed_on_battlefield"))
		card_manager.connect("card_placed_on_battlefield", Callable(self, "_on_card_placed_on_battlefield"))
		
		if card_manager.is_connected("attack_card_played_this_turn", Callable(self, "_on_attack_card_played")):
			card_manager.disconnect("attack_card_played_this_turn", Callable(self, "_on_attack_card_played"))
		card_manager.connect("attack_card_played_this_turn", Callable(self, "_on_attack_card_played"))
	
	# Connect to InputManager signals
	var input_manager = get_parent().get_node_or_null("InputManager")
	if input_manager:
		if input_manager.is_connected("opponent_card_clicked", Callable(self, "_on_opponent_card_clicked")):
			input_manager.disconnect("opponent_card_clicked", Callable(self, "_on_opponent_card_clicked"))
		input_manager.connect("opponent_card_clicked", Callable(self, "_on_opponent_card_clicked"))

# Signal handler: called when CardManager places a card on battlefield
func _on_card_placed_on_battlefield(_card: Node, _slot: Node) -> void:
	# Add card to appropriate battlefield array
	# Note: Card is added by CardManager itself, so we just track the event here
	emit_signal("card_added_to_battlefield", _card, true)

# Signal handler: called when player plays an attack card
func _on_attack_card_played(_card: Node) -> void:
	# Add player attack card to battlefield tracking array
	if _card not in player_cards_on_battlefield:
		player_cards_on_battlefield.append(_card)

# Signal handler: called when opponent card is clicked for attack
func _on_opponent_card_clicked(defending_card: Node) -> void:
	var card_manager = get_parent().get_node_or_null("CardManager")
	if card_manager:
		var attacking_card = card_manager.selected_monster
		if attacking_card:
			if defending_card in opponent_cards_on_battlefield:
				if player_is_attacking == false:
					card_manager.selected_monster = null
					attack(attacking_card, defending_card, "Player")

func _on_end_turn_button_pressed() -> void:
	is_opponents_turn = true
	var card_manager = get_parent().get_node_or_null("CardManager")
	if card_manager:
		card_manager.unselect_selected_monster()
	player_cards_that_attacked_this_turn = []
	
	# Regenerate opponent energy at start of their turn
	var energy_manager = get_parent().get_node_or_null("EnergyManager")
	if energy_manager:
		energy_manager.regenerate_opponent_energy()
	
	opponent_turn()


func opponent_turn():
	# Regenerate available attack card slots
	empty_attack_cards_slots.clear()
	var card_slots = get_parent().get_node_or_null("CardSlots")
	if card_slots:
		for child in card_slots.get_children():
			if child.name.begins_with("EnemyCardSlot") and not child.card_in_slot:
				empty_attack_cards_slots.append(child)
	
	var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
	if end_turn_button:
		end_turn_button.disabled = true
		end_turn_button.visible = false
	
	var opponent_deck = get_parent().get_node_or_null("OpponentDeck")
	if opponent_deck and opponent_deck.opponent_deck.size() != 0:
		opponent_deck.draw_card()
		
		if battle_timer:
			battle_timer.start()
			await battle_timer.timeout

	# AI deploys ONE card per turn (attack first, then support)
	if empty_attack_cards_slots.size() != 0:
		# Try to deploy an attack card
		var card_deployed = await try_deploy_attack_card()
		
		# If no attack card deployed, try support card
		if not card_deployed:
			await try_deploy_support_card()
	
	# After card deployment phase, AI attacks with all cards on battlefield
	# Must attack opponent cards first if they exist, otherwise attack HP
	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "Opponent")
			else:
				direct_attack(card, "Opponent")
	end_opponent_turn()


func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
		if end_turn_button:
			end_turn_button.disabled = true
			end_turn_button.visible = false
		player_is_attacking = true
		new_pos_y = 0
		player_cards_that_attacked_this_turn.append(attacking_card)
	
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.attack)
		emit_signal("player_health_changed", player_health)
		var player_health_label = get_parent().get_node_or_null("PlayerHealth")
		if player_health_label:
			player_health_label.text = str(player_health)
		emit_signal("direct_attack_occurred", attacking_card, "Player", attacking_card.attack)
		# CHECK WIN CONDITION
		if player_health <= 0:
			await wait(1.0)
			end_game("Opponent")
			return
	else:
		opponent_health = max(0, opponent_health - attacking_card.attack)
		emit_signal("opponent_health_changed", opponent_health)
		var opponent_health_label = get_parent().get_node_or_null("OpponentHealth")
		if opponent_health_label:
			opponent_health_label.text = str(opponent_health)
		emit_signal("direct_attack_occurred", attacking_card, "Opponent", attacking_card.attack)
		# CHECK WIN CONDITION
		if opponent_health <= 0:
			await wait(1.0)
			end_game("Player")
			return
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	attacking_card.z_index = 0
	await wait(1.0)
	if attacker == "Player":
		player_is_attacking = false
		var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
		if end_turn_button:
			end_turn_button.disabled = false
			end_turn_button.visible = true
	

func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
		if end_turn_button:
			end_turn_button.disabled = true
			end_turn_button.visible = false
		player_is_attacking = true
		$"../CardManager".selected_monster = null
		player_cards_that_attacked_this_turn.append(attacking_card)
	
	attacking_card.z_index = 5
	
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	emit_signal("card_attack_occurred", attacking_card, defending_card, attacking_card.attack)
	
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	emit_signal("card_attack_occurred", defending_card, attacking_card, defending_card.attack)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	
	if attacking_card.health == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else: 
			destroy_card(defending_card, "Player")
		card_was_destroyed = true
	
	if card_was_destroyed:
		await wait(1.0)
	
	if attacker == "Player":
		player_is_attacking = false
		var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
		if end_turn_button:
			end_turn_button.disabled = false
			end_turn_button.visible = true

func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		card.defeated = true
		if card.has_node("Area2D/CollisionShape2D"):
			card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerDiscard".position
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
			if card.card_slot_card_is_in:
				if card.card_slot_card_is_in.has_node("Area2D/CollisionShape2D"):
					card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false
				card.card_slot_card_is_in.card_in_slot = false
				card.card_slot_card_is_in.visible = true
				card.card_slot_card_is_in = null
	else:
		# OPPONENT CARD DESTROY - properly clean up slot
		new_pos = $"../OpponentDiscard".position
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
			# Clean up slot so it becomes available again
			if card.card_slot_card_is_in:
				card.card_slot_card_is_in.card_in_slot = false
				card.card_slot_card_is_in = null
	
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)

func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_monster
	if attacking_card:
		if defending_card in opponent_cards_on_battlefield:
			if player_is_attacking == false:
				$"../CardManager".selected_monster = null
				attack(attacking_card, defending_card, "Player")


func try_play_card_with_highest_attack():
	# This function is deprecated - use try_deploy_attack_card() instead
	# Kept for backwards compatibility
	pass

## Try to deploy ONE attack card (AI)
## Returns true if card was deployed, false otherwise
func try_deploy_attack_card() -> bool:
	var opponent_hand = $"../OpponentHand".opponent_hand
	var energy_manager = get_parent().get_node_or_null("EnergyManager")
	
	if opponent_hand.size() == 0 or empty_attack_cards_slots.size() == 0:
		return false
	
	# Find the best affordable attack card
	var best_attack_card = null
	var highest_attack = -1
	
	for card in opponent_hand:
		# Only consider attack cards
		if not ("card_type" in card and card.card_type == "Attacker"):
			continue
		
		# Check if opponent can afford this card
		if energy_manager and not energy_manager.can_opponent_afford_card(card.card_name):
			continue
		
		# Track card with highest attack
		if "attack" in card and card.attack > highest_attack:
			best_attack_card = card
			highest_attack = card.attack
	
	# If no affordable attack card found, return false
	if best_attack_card == null:
		return false
	
	# Deploy the card to a random empty slot
	var target_slot = empty_attack_cards_slots.pick_random()
	empty_attack_cards_slots.erase(target_slot)
	
	# Spend energy
	if energy_manager:
		energy_manager.spend_opponent_energy(best_attack_card.card_name)
	
	# Animate card to slot
	var tween = get_tree().create_tween()
	tween.tween_property(best_attack_card, "position", target_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(best_attack_card, "scale", Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE), CARD_MOVE_SPEED)
	best_attack_card.get_node("AnimationPlayer").play("card_flip")
	
	# Move card from hand to battlefield
	$"../OpponentHand".remove_card_from_hand(best_attack_card)
	best_attack_card.card_slot_card_is_in = target_slot
	opponent_cards_on_battlefield.append(best_attack_card)
	
	await wait(1.0)
	return true

## Try to deploy ONE support card (AI)
## Returns true if card was deployed, false otherwise
func try_deploy_support_card() -> bool:
	var opponent_hand = $"../OpponentHand".opponent_hand
	var energy_manager = get_parent().get_node_or_null("EnergyManager")
	
	if opponent_hand.size() == 0:
		return false
	
	# Find first affordable support card
	var support_card = null
	
	for card in opponent_hand:
		# Only consider support cards
		if not ("card_type" in card and card.card_type == "Support"):
			continue
		
		# Check if opponent can afford this card
		if energy_manager and energy_manager.can_opponent_afford_card(card.card_name):
			support_card = card
			break
	
	# If no affordable support card found, return false
	if support_card == null:
		return false
	
	# Spend energy
	if energy_manager:
		energy_manager.spend_opponent_energy(support_card.card_name)
	
	# Remove from hand (support cards don't stay on battlefield)
	$"../OpponentHand".remove_card_from_hand(support_card)
	
	# Trigger support card ability if it exists
	if "ability_script" in support_card and support_card.ability_script:
		await support_card.ability_script.trigger_ability(self, support_card, get_parent().get_node_or_null("InputManager"))
	
	await wait(0.5)
	return true

func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_attack()
	is_opponents_turn = false
	
	# Regenerate player energy at start of their turn
	var energy_manager = get_parent().get_node_or_null("EnergyManager")
	if energy_manager:
		energy_manager.regenerate_player_energy()
	
	var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
	if end_turn_button:
		end_turn_button.disabled = false
		end_turn_button.visible = true

func enable_end_turn_button(is_enabled):
	var end_turn_button = get_parent().get_node_or_null("UILayer/EndTurnButton")
	if not end_turn_button:
		return
	
	if is_enabled:
		end_turn_button.disabled = false
		end_turn_button.visible = true
	else:
		end_turn_button.disabled = true
		end_turn_button.visible = false

func end_game(winner: String) -> void:
	# Disable all input and UI
	var input_manager = get_parent().get_node_or_null("InputManager")
	if input_manager:
		input_manager.input_disabled = true
	
	# Show game end message (you can customize this)
	var game_end_label = get_parent().get_node_or_null("GameEndLabel")
	if not game_end_label:
		# Create a label if it doesn't exist
		game_end_label = Label.new()
		game_end_label.name = "GameEndLabel"
		get_parent().add_child(game_end_label)
		game_end_label.anchor_left = 0.5
		game_end_label.anchor_top = 0.5
		game_end_label.offset_left = -100
		game_end_label.offset_top = -50
		game_end_label.size = Vector2(200, 100)
	
	game_end_label.text = winner + " Wins!"
	game_end_label.add_theme_font_size_override("font_size", 32)
	game_end_label.visible = true
	
	# You can add transition to end game scene here
	await wait(2.0)
	# For now, just return to main menu
	get_tree().change_scene_to_file("res://Scenes/ui/MainMenu.tscn")
