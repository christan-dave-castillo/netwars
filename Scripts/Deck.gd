extends Node2D

# Signals for deck events
signal deck_empty

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.14159
const STARTING_HAND_SIZE = 5

var player_deck = ["Virus", "Phishing", "Phishing", "Worm", "Trojan", "Worm", "Trojan"]
var card_database_reference
var drawn_card_this_turn = false
#
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Check if player selected a custom deck from DeckBuilder
	var game_state = get_node("/root/GameState")
	if game_state and game_state.player_selected_deck.size() > 0:
		player_deck = game_state.player_selected_deck.duplicate()
		print("Deck.gd: Using custom deck from GameState: ", player_deck)
	else:
		print("Deck.gd: Using default hardcoded deck")
	
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		drawn_card_this_turn = false
	drawn_card_this_turn = true
	
	# Connect to InputManager signal for deck clicks
	var input_manager = get_parent().get_node_or_null("InputManager")
	if input_manager:
		if input_manager.is_connected("deck_clicked", Callable(self, "_on_deck_clicked")):
			input_manager.disconnect("deck_clicked", Callable(self, "_on_deck_clicked"))
		input_manager.connect("deck_clicked", Callable(self, "_on_deck_clicked"))

# Signal handler: called when InputManager emits deck_clicked signal
func _on_deck_clicked() -> void:
	draw_card()

func draw_card():
	if drawn_card_this_turn:
		return
	
	if player_deck.size() == 0:
		return
	
	drawn_card_this_turn = true
	var card_drawn_name = player_deck[0]
	player_deck.remove_at(0)  # BUG FIX: erase() removes ALL instances, remove_at() removes only first
	
	if player_deck.size() == 0:
		if has_node("Area2D/CollisionShape2D"):
			$Area2D/CollisionShape2D.disabled = true
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.visible = false
		var label = get_node_or_null("RichTextLabel")
		if label:
			label.visible = false
		emit_signal("deck_empty")
		
	var deck_label = get_node_or_null("RichTextLabel")
	if deck_label:
		deck_label.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Assets/" + card_drawn_name + "Card.png")
	var card_image = new_card.get_node_or_null("CardImage")
	if card_image:
		card_image.texture = load(card_image_path)
	
	new_card.card_name = card_drawn_name
	new_card.energy_cost = card_database_reference.CARDS[card_drawn_name][2]
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][3]
	
	# Initialize attack and health for all cards (defaults to 0 for support cards)
	var card_attack = card_database_reference.CARDS[card_drawn_name][0]
	var card_health = card_database_reference.CARDS[card_drawn_name][1]
	new_card.attack = card_attack if card_attack != null else 0
	new_card.health = card_health if card_health != null else 0
	
	if new_card.card_type == "Attacker":
		var ability_node = new_card.get_node_or_null("Ability")
		if ability_node:
			ability_node.visible = false
		var attack_label = new_card.get_node_or_null("Attack")
		if attack_label:
			attack_label.text = str(new_card.attack)
		var health_label = new_card.get_node_or_null("Health")
		if health_label:
			health_label.text = str(new_card.health)
		var energy_label = new_card.get_node_or_null("Energy")
		if energy_label:
			energy_label.text = str(card_database_reference.CARDS[card_drawn_name][2])
	else:
		var ability_label = new_card.get_node_or_null("Ability")
		if ability_label:
			ability_label.visible = true
		var attack_node = new_card.get_node_or_null("Attack")
		if attack_node:
			attack_node.visible = false
		var health_node = new_card.get_node_or_null("Health")
		if health_node:
			health_node.visible = false
		var energy_node = new_card.get_node_or_null("Energy")
		if energy_node:
			energy_node.visible = true
		if ability_label:
			ability_label.text = card_database_reference.CARDS[card_drawn_name][4]
		var new_card_ability_script_path = card_database_reference.CARDS[card_drawn_name][5]
		if new_card_ability_script_path:
			new_card.ability_script = load(new_card_ability_script_path).new()


	var card_manager = get_parent().get_node_or_null("CardManager")
	if card_manager:
		card_manager.add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	drawn_card_this_turn = false
