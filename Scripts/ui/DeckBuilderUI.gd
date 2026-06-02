extends Control

# Deck Builder UI - displays available cards and equipped cards with equip/unequip functionality

const CARD_BUTTON_SCENE = preload("res://Scenes/Card.tscn")

var deck_manager: Node
var card_database_reference
var selected_card = null

@onready var available_cards_container = $VBoxContainer/HBoxContainer/AvailableCardsContainer
@onready var equipped_cards_container = $VBoxContainer/HBoxContainer/EquippedCardsContainer
@onready var difficulty_label = $VBoxContainer/DifficultyLabel
@onready var deck_size_label = $VBoxContainer/DeckSizeLabel
@onready var card_details_label = $VBoxContainer/CardDetailsLabel
@onready var back_button = $VBoxContainer/HBoxContainer2/BackButton
@onready var equip_button = $VBoxContainer/HBoxContainer2/EquipButton
@onready var unequip_button = $VBoxContainer/HBoxContainer2/UnequipButton
@onready var clear_deck_button = $VBoxContainer/HBoxContainer2/ClearDeckButton
@onready var start_game_button = $VBoxContainer/HBoxContainer2/StartGameButton

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	deck_manager = get_node_or_null("/root/DeckManager")
	if not deck_manager:
		# Create DeckManager if it doesn't exist
		deck_manager = Node.new()
		deck_manager.script = preload("res://Scripts/DeckManager.gd")
		deck_manager.name = "DeckManager"
		add_child(deck_manager)
	
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	
	# Update difficulty label
	if difficulty_label:
		var game_state = get_node("/root/GameState")
		if game_state:
			difficulty_label.text = "Difficulty: " + game_state.difficulty.to_upper()
	
	# Connect deck manager signals
	if deck_manager:
		deck_manager.connect("deck_updated", Callable(self, "_on_deck_updated"))
		deck_manager.connect("card_equipped", Callable(self, "_on_card_equipped"))
		deck_manager.connect("card_unequipped", Callable(self, "_on_card_unequipped"))
		deck_manager.connect("deck_full", Callable(self, "_on_deck_full"))
	
	# Connect button signals
	if back_button:
		back_button.pressed.connect(Callable(self, "_on_back_pressed"))
	if equip_button:
		equip_button.pressed.connect(Callable(self, "_on_equip_pressed"))
	if unequip_button:
		unequip_button.pressed.connect(Callable(self, "_on_unequip_pressed"))
	if clear_deck_button:
		clear_deck_button.pressed.connect(Callable(self, "_on_clear_deck_pressed"))
	if start_game_button:
		start_game_button.pressed.connect(Callable(self, "_on_start_game_pressed"))
	
	# Populate UI
	refresh_ui()

# Refresh entire UI
func refresh_ui() -> void:
	populate_available_cards()
	populate_equipped_cards()
	update_deck_size_display()
	update_button_states()

# Populate available cards list
func populate_available_cards() -> void:
	if not available_cards_container:
		return
		
	# Clear existing items
	for child in available_cards_container.get_children():
		child.queue_free()
	
	# Add buttons for each available card
	for card_name in deck_manager.get_available_cards():
		var button = Button.new()
		button.text = card_name
		button.custom_minimum_size = Vector2(120, 40)
		button.pressed.connect(Callable(self, "_on_available_card_selected").bindv([card_name]))
		available_cards_container.add_child(button)

# Populate equipped cards list
func populate_equipped_cards() -> void:
	if not equipped_cards_container:
		return
		
	# Clear existing items
	for child in equipped_cards_container.get_children():
		child.queue_free()
	
	# Get deck composition (card name -> count)
	var composition = deck_manager.get_deck_composition()
	
	# Add display for each unique equipped card
	for card_name in composition.keys():
		var card_count = composition[card_name]
		var container = HBoxContainer.new()
		container.custom_minimum_size = Vector2(200, 40)
		
		# Card name label
		var name_label = Label.new()
		name_label.text = card_name + " x" + str(card_count)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(name_label)
		
		# Remove button
		var remove_button = Button.new()
		remove_button.text = "-"
		remove_button.custom_minimum_size = Vector2(40, 40)
		remove_button.pressed.connect(Callable(self, "_on_remove_equipped_card").bindv([card_name]))
		container.add_child(remove_button)
		
		equipped_cards_container.add_child(container)

# Update deck size display
func update_deck_size_display() -> void:
	if deck_size_label:
		var current_size = deck_manager.get_deck_size()
		var max_size = deck_manager.MAX_DECK_SIZE
		deck_size_label.text = "Deck Size: %d / %d" % [current_size, max_size]

# Update button states
func update_button_states() -> void:
	if equip_button:
		equip_button.disabled = (selected_card == null or deck_manager.is_deck_full())
	if unequip_button:
		unequip_button.disabled = (selected_card == null or deck_manager.get_card_count(selected_card) == 0)
	if start_game_button:
		start_game_button.disabled = not deck_manager.is_deck_valid()
	if clear_deck_button:
		clear_deck_button.disabled = deck_manager.is_deck_empty()

# Display card details
func show_card_details(card_name: String) -> void:
	if card_details_label:
		var stats = card_database_reference.CARDS.get(card_name, [])
		if stats.size() > 0:
			var attack = stats[0] if stats[0] != null else 0
			var health = stats[1] if stats[1] != null else 0
			var energy = stats[2]
			var card_type = stats[3]
			var ability = stats[4] if stats.size() > 4 else "None"
			
			card_details_label.text = """
%s
Type: %s | Energy: %d
Attack: %d | Health: %d
Ability: %s
In Deck: %d / MAX 3
			""" % [card_name, card_type, energy, attack, health, ability, deck_manager.get_card_count(card_name)]

# Signal handlers
func _on_available_card_selected(card_name: String) -> void:
	selected_card = card_name
	show_card_details(card_name)
	update_button_states()

func _on_back_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/ui/MainMenu.tscn")

func _on_equip_pressed() -> void:
	if selected_card and not deck_manager.is_deck_full():
		# Allow max 3 copies of same card (placeholder rule)
		if deck_manager.get_card_count(selected_card) < 3:
			if deck_manager.equip_card(selected_card):
				refresh_ui()
		else:
			card_details_label.text = "Maximum 3 copies of %s allowed!" % selected_card

func _on_unequip_pressed() -> void:
	if selected_card:
		if deck_manager.unequip_card(selected_card):
			refresh_ui()

func _on_remove_equipped_card(card_name: String) -> void:
	if deck_manager.unequip_card(card_name):
		selected_card = null
		refresh_ui()

func _on_clear_deck_pressed() -> void:
	deck_manager.clear_deck()
	selected_card = null
	refresh_ui()

func _on_deck_updated(current_size: int, max_size: int) -> void:
	update_deck_size_display()
	update_button_states()

func _on_card_equipped(card_name: String) -> void:
	populate_equipped_cards()

func _on_card_unequipped(card_name: String) -> void:
	populate_equipped_cards()

func _on_deck_full() -> void:
	card_details_label.text = "Deck is full! (15/15 cards)"

func _on_start_game_pressed() -> void:
	if deck_manager.is_deck_valid():
		# Save selected deck to GameState for Game scene to use
		var game_state = get_node("/root/GameState")
		if game_state:
			game_state.player_selected_deck = deck_manager.get_equipped_cards()
			print("Deck saved to GameState: ", game_state.player_selected_deck)
		# Transition to game
		get_tree().change_scene_to_file("res://Scenes/Game.tscn")
	else:
		card_details_label.text = "Invalid deck! Must have 1-15 cards."
