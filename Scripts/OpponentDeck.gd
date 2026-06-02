extends Node2D

# Signals for opponent deck events
signal deck_empty

const CARD_SCENE_PATH = "res://Scenes/OpponentCard.tscn"
const CARD_DRAW_SPEED = 0.14159
const STARTING_HAND_SIZE = 5

var opponent_deck = ["Virus", "Worm", "Trojan", "Trojan", "Trojan", "Backdoor"]
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Generate randomized opponent deck from available cards
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	opponent_deck = _generate_random_opponent_deck()
	print("OpponentDeck: Generated random deck: ", opponent_deck)
	
	opponent_deck.shuffle()
	$RichTextLabel.text = str(opponent_deck.size())
	
	# Draw starting hand (5 cards)
	for i in range(STARTING_HAND_SIZE):
		draw_card()

# Generate a random opponent deck with varied composition
func _generate_random_opponent_deck() -> Array:
	var cards_available = ["Virus", "Phishing", "Worm", "Trojan", "Backdoor"]
	var new_deck = []
	var max_deck_size = 7  # Slightly larger than starting 5 cards
	
	# Pick random cards with limit of 3 copies per card
	for i in range(max_deck_size):
		var random_card = cards_available.pick_random()
		var count = new_deck.count(random_card)
		# If this card already has 3 copies, pick a different one
		while count >= 3:
			random_card = cards_available.pick_random()
			count = new_deck.count(random_card)
		new_deck.append(random_card)
	
	return new_deck

func draw_card():
	if opponent_deck.size() == 0:
		return
	
	var card_drawn_name = opponent_deck[0]
	opponent_deck.remove_at(0)  # BUG FIX: erase() removes ALL instances, remove_at() removes only first
	
	if opponent_deck.size() == 0:
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.visible = false
		var label = get_node_or_null("RichTextLabel")
		if label:
			label.visible = false
		emit_signal("deck_empty")
		
	var deck_label = get_node_or_null("RichTextLabel")
	if deck_label:
		deck_label.text = str(opponent_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Assets/" + card_drawn_name + "Card.png")
	var card_image = new_card.get_node_or_null("CardImage")
	if card_image:
		card_image.texture = load(card_image_path)
	new_card.card_name = card_drawn_name
	new_card.energy_cost = card_database_reference.CARDS[card_drawn_name][2]
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][3]
	
	# Initialize attack and health, handling null values for support cards
	var card_attack = card_database_reference.CARDS[card_drawn_name][0]
	var card_health = card_database_reference.CARDS[card_drawn_name][1]
	new_card.attack = card_attack if card_attack != null else 0
	new_card.health = card_health if card_health != null else 0
	
	# Set up UI based on card type
	if new_card.card_type == "Attacker":
		var attack_label = new_card.get_node_or_null("Attack")
		if attack_label:
			attack_label.text = str(new_card.attack)
		var health_label = new_card.get_node_or_null("Health")
		if health_label:
			health_label.text = str(new_card.health)
		var ability_node = new_card.get_node_or_null("Ability")
		if ability_node:
			ability_node.visible = false
	else:
		# Support card
		var attack_node = new_card.get_node_or_null("Attack")
		if attack_node:
			attack_node.visible = false
		var health_node = new_card.get_node_or_null("Health")
		if health_node:
			health_node.visible = false
		var ability_label = new_card.get_node_or_null("Ability")
		if ability_label:
			ability_label.visible = true
			ability_label.text = card_database_reference.CARDS[card_drawn_name][4]
		var card_ability_script_path = card_database_reference.CARDS[card_drawn_name][5]
		if card_ability_script_path:
			new_card.ability_script = load(card_ability_script_path).new()
	
	var energy_label = new_card.get_node_or_null("Energy")
	if energy_label:
		energy_label.text = str(card_database_reference.CARDS[card_drawn_name][2])
	
	var card_manager = get_parent().get_node_or_null("CardManager")
	if card_manager:
		card_manager.add_child(new_card)
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
