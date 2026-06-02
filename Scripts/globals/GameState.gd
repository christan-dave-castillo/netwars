extends Node
## Global game state autoload
## Stores persistent game settings, player data, and game mode information

# Game difficulty level: "easy", "medium", or "hard"
var difficulty: String = "easy"

# Game mode: "offline" or "online"
var game_mode: String = "offline"

# Authentication state
var is_authenticated: bool = false

# Player information
var player_name: String = ""

# Player selected deck from DeckBuilder
var player_selected_deck: Array = []

# Signal emitted when authentication status changes
signal authentication_changed(is_authenticated: bool)

# Signal emitted when difficulty changes
signal difficulty_changed(difficulty: String)

# Signal emitted when game mode changes
signal game_mode_changed(game_mode: String)


func _ready() -> void:
	# Ensure this node is not freed when scenes change
	set_name("GameState")


## Set the game difficulty and emit signal
func set_difficulty(new_difficulty: String) -> void:
	if new_difficulty in ["easy", "medium", "hard"]:
		difficulty = new_difficulty
		emit_signal("difficulty_changed", new_difficulty)
	else:
		push_error("Invalid difficulty: %s. Must be 'easy', 'medium', or 'hard'" % new_difficulty)


## Set the game mode and emit signal
func set_game_mode(new_mode: String) -> void:
	if new_mode in ["offline", "online"]:
		game_mode = new_mode
		emit_signal("game_mode_changed", new_mode)
	else:
		push_error("Invalid game mode: %s. Must be 'offline' or 'online'" % new_mode)


## Set authentication state and emit signal
func set_authenticated(authenticated: bool, player_name_arg: String = "") -> void:
	is_authenticated = authenticated
	if authenticated:
		player_name = player_name_arg
	else:
		player_name = ""
	emit_signal("authentication_changed", authenticated)


## Get display name for current difficulty
func get_difficulty_display_name() -> String:
	match difficulty:
		"easy":
			return "EASY"
		"medium":
			return "MEDIUM"
		"hard":
			return "HARD"
		_:
			return "UNKNOWN"


## Reset to default state
func reset() -> void:
	difficulty = "easy"
	game_mode = "offline"
	is_authenticated = false
	player_name = ""
