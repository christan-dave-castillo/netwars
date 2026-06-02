extends Node

# Deck Building System - allows players to select which cards they want to use
# Maximum 15 cards per deck (placeholder - expandable)

signal deck_updated(current_size: int, max_size: int)
signal card_equipped(card_name: String)
signal card_unequipped(card_name: String)
signal deck_full
signal deck_empty

const MAX_DECK_SIZE = 15
const MIN_DECK_SIZE = 1

var card_database_reference
var equipped_cards = []  # Cards selected for this deck
var available_cards = []  # All available cards in database
var current_deck_name = "Default Deck"

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	initialize_available_cards()

# Initialize list of all available cards from database
func initialize_available_cards() -> void:
	available_cards.clear()
	for card_name in card_database_reference.CARDS.keys():
		available_cards.append(card_name)
	available_cards.sort()

# Equip a card to the deck (add card to equipped list)
func equip_card(card_name: String) -> bool:
	# Check if card exists in database
	if card_name not in card_database_reference.CARDS:
		push_error("DeckManager: Card '" + card_name + "' not found in database")
		return false
	
	# Check if deck is full
	if equipped_cards.size() >= MAX_DECK_SIZE:
		emit_signal("deck_full")
		return false
	
	# Add card to equipped list (allow duplicates)
	equipped_cards.append(card_name)
	emit_signal("card_equipped", card_name)
	emit_signal("deck_updated", equipped_cards.size(), MAX_DECK_SIZE)
	return true

# Unequip a card from the deck (remove one instance)
func unequip_card(card_name: String) -> bool:
	# Check if card is in equipped list
	if card_name not in equipped_cards:
		push_error("DeckManager: Card '" + card_name + "' not in equipped deck")
		return false
	
	# Remove first instance of card (not all instances)
	var index = equipped_cards.find(card_name)
	if index != -1:
		equipped_cards.remove_at(index)
	emit_signal("card_unequipped", card_name)
	emit_signal("deck_updated", equipped_cards.size(), MAX_DECK_SIZE)
	
	if equipped_cards.size() == 0:
		emit_signal("deck_empty")
	
	return true

# Get count of specific card in equipped deck
func get_card_count(card_name: String) -> int:
	var count = 0
	for card in equipped_cards:
		if card == card_name:
			count += 1
	return count

# Get all equipped cards
func get_equipped_cards() -> Array:
	return equipped_cards.duplicate()

# Get all available cards
func get_available_cards() -> Array:
	return available_cards.duplicate()

# Check if deck is full
func is_deck_full() -> bool:
	return equipped_cards.size() >= MAX_DECK_SIZE

# Check if deck is empty
func is_deck_empty() -> bool:
	return equipped_cards.size() == 0

# Get remaining slots
func get_remaining_slots() -> int:
	return MAX_DECK_SIZE - equipped_cards.size()

# Get current deck size
func get_deck_size() -> int:
	return equipped_cards.size()

# Clear entire deck
func clear_deck() -> void:
	equipped_cards.clear()
	emit_signal("deck_updated", 0, MAX_DECK_SIZE)
	emit_signal("deck_empty")

# Validate deck is playable
func is_deck_valid() -> bool:
	return equipped_cards.size() >= MIN_DECK_SIZE and equipped_cards.size() <= MAX_DECK_SIZE

# Get deck composition (card name -> count)
func get_deck_composition() -> Dictionary:
	var composition = {}
	for card_name in equipped_cards:
		if card_name in composition:
			composition[card_name] += 1
		else:
			composition[card_name] = 1
	return composition

# Set deck name
func set_deck_name(new_name: String) -> void:
	current_deck_name = new_name

# Get deck name
func get_deck_name() -> String:
	return current_deck_name

# Get card stats from database
func get_card_stats(card_name: String) -> Array:
	if card_name in card_database_reference.CARDS:
		return card_database_reference.CARDS[card_name]
	return []

