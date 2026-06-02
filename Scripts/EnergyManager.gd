extends Node

# Emitted when player or opponent energy changes
signal player_energy_changed(current: int, max: int)
signal opponent_energy_changed(current: int, max: int)

const MAX_ENERGY = 10
const STARTING_ENERGY = 10
const ENERGY_REGENERATION = 2

var player_current_energy = STARTING_ENERGY
var opponent_current_energy = STARTING_ENERGY
var player_max_energy = MAX_ENERGY
var opponent_max_energy = MAX_ENERGY

var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	update_ui()

# Check if player has enough energy to play a card
func can_player_afford_card(card_name: String) -> bool:
	var card_energy_cost = get_card_energy_cost(card_name)
	return player_current_energy >= card_energy_cost

# Check if opponent has enough energy to play a card
func can_opponent_afford_card(card_name: String) -> bool:
	var card_energy_cost = get_card_energy_cost(card_name)
	return opponent_current_energy >= card_energy_cost

# Deduct energy when a card is played
func spend_player_energy(card_name: String) -> bool:
	var card_energy_cost = get_card_energy_cost(card_name)
	if can_player_afford_card(card_name):
		player_current_energy -= card_energy_cost
		player_current_energy = max(0, player_current_energy)
		update_ui()
		return true
	return false

# Deduct energy for opponent
func spend_opponent_energy(card_name: String) -> bool:
	var card_energy_cost = get_card_energy_cost(card_name)
	if can_opponent_afford_card(card_name):
		opponent_current_energy -= card_energy_cost
		opponent_current_energy = max(0, opponent_current_energy)
		update_ui()
		return true
	return false

# Get energy cost of a card
func get_card_energy_cost(card_name: String) -> int:
	if card_database_reference.CARDS.has(card_name):
		return card_database_reference.CARDS[card_name][2]
	return 0

# Regenerate energy at the end of turn
func regenerate_player_energy() -> void:
	player_current_energy = min(player_current_energy + ENERGY_REGENERATION, player_max_energy)
	update_ui()

func regenerate_opponent_energy() -> void:
	opponent_current_energy = min(opponent_current_energy + ENERGY_REGENERATION, opponent_max_energy)
	update_ui()

# Get current energy values
func get_player_energy() -> int:
	return player_current_energy

func get_opponent_energy() -> int:
	return opponent_current_energy

# Update UI labels and emit signals for listeners
func update_ui() -> void:
	# Emit signals so any listener can respond to energy changes
	emit_signal("player_energy_changed", player_current_energy, player_max_energy)
	emit_signal("opponent_energy_changed", opponent_current_energy, opponent_max_energy)
	
	# Also update UI labels directly as fallback
	var player_energy_label = get_parent().get_node_or_null("PlayerEnergy")
	var opponent_energy_label = get_parent().get_node_or_null("OpponentEnergy")
	
	if player_energy_label:
		player_energy_label.text = str(player_current_energy) + "/" + str(player_max_energy)
	if opponent_energy_label:
		opponent_energy_label.text = str(opponent_current_energy) + "/" + str(opponent_max_energy)

# Reset energy for new game
func reset_energy() -> void:
	player_current_energy = STARTING_ENERGY
	opponent_current_energy = STARTING_ENERGY
	update_ui()
