extends Node

# Backdoor ability: Attack opponent card or HP directly
const DAMAGE_DEALT = 3

func trigger_ability(battle_manager_reference, card_with_ability, input_manager_reference):
	
	input_manager_reference.input_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	
	await battle_manager_reference.wait(0.5)
	
	# Attack opponent card if available, otherwise attack HP
	if battle_manager_reference.opponent_cards_on_battlefield.size() > 0:
		# Attack a random opponent card
		var target_card = battle_manager_reference.opponent_cards_on_battlefield.pick_random()
		
		# Deal damage to the target card
		target_card.health = max(0, target_card.health - DAMAGE_DEALT)
		target_card.get_node("Health").text = str(target_card.health)
		battle_manager_reference.emit_signal("card_attack_occurred", card_with_ability, target_card, DAMAGE_DEALT)
		
		# Check if target card is destroyed
		if target_card.health == 0:
			battle_manager_reference.destroy_card(target_card, "Opponent")
			await battle_manager_reference.wait(1.0)
	else:
		# No opponent cards - attack HP directly
		battle_manager_reference.opponent_health = max(0, battle_manager_reference.opponent_health - DAMAGE_DEALT)
		battle_manager_reference.emit_signal("opponent_health_changed", battle_manager_reference.opponent_health)
		var opponent_health_label = battle_manager_reference.get_parent().get_node_or_null("OpponentHealth")
		if opponent_health_label:
			opponent_health_label.text = str(battle_manager_reference.opponent_health)
	
	await battle_manager_reference.wait(1.0)
	
	# Destroy the Backdoor card after ability resolves
	battle_manager_reference.destroy_card(card_with_ability, "Player")
	await battle_manager_reference.wait(1.0)
	
	battle_manager_reference.enable_end_turn_button(true)
	input_manager_reference.input_disabled = false
