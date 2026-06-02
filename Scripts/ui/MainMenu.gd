extends Control
## Main Menu Controller
## Manages menu navigation, submenus, and transitions using signals and Tweens

# Submenu states
enum MenuState {
	MAIN,
	PLAY,
	OFFLINE_PLAY,
	ONLINE_PLAY,
	SETTINGS,
	DECK_MANAGER
}

# Current menu state
var current_menu_state: MenuState = MenuState.MAIN

# Previous menu state for back button
var previous_menu_state: MenuState = MenuState.MAIN

# References to submenu containers
var main_menu: Control
var play_menu: Control
var offline_play_menu: Control
var online_play_menu: Control

# Animation speed for menu transitions
const ANIMATION_SPEED = 0.3

# Color palette for cyber theme
const COLOR_EASY = Color.GREEN
const COLOR_MEDIUM = Color.YELLOW
const COLOR_HARD = Color.RED
const COLOR_ONLINE = Color.CYAN
const COLOR_PRIMARY = Color.WHITE
const COLOR_EXIT = Color.RED


func _ready() -> void:
	# Get references to all submenu nodes
	main_menu = get_node_or_null("MainMenu")
	play_menu = get_node_or_null("PlayMenu")
	offline_play_menu = get_node_or_null("OfflinePlayMenu")
	online_play_menu = get_node_or_null("OnlinePlayMenu")
	
	# Validate all menu nodes exist
	if not main_menu:
		push_error("MainMenu: MainMenu node not found!")
		return
	if not play_menu:
		push_error("MainMenu: PlayMenu node not found!")
		return
	if not offline_play_menu:
		push_error("MainMenu: OfflinePlayMenu node not found!")
		return
	if not online_play_menu:
		push_error("MainMenu: OnlinePlayMenu node not found!")
		return
	
	# Hide all submenus except main
	play_menu.hide()
	offline_play_menu.hide()
	online_play_menu.hide()
	
	# Connect to all button signals
	_connect_button_signals()
	
	# Start with main menu visible
	current_menu_state = MenuState.MAIN


## Connect all button signals to handlers
func _connect_button_signals() -> void:
	# Main menu buttons
	var play_btn = main_menu.get_node_or_null("PlayButton")
	var deck_btn = main_menu.get_node_or_null("DeckManagerButton")
	var settings_btn = main_menu.get_node_or_null("SettingsButton")
	var exit_btn = main_menu.get_node_or_null("ExitButton")
	
	if play_btn:
		if not play_btn.pressed.is_connected(Callable(self, "_on_play_pressed")):
			play_btn.pressed.connect(Callable(self, "_on_play_pressed"))
	if deck_btn:
		if not deck_btn.pressed.is_connected(Callable(self, "_on_deck_manager_pressed")):
			deck_btn.pressed.connect(Callable(self, "_on_deck_manager_pressed"))
	if settings_btn:
		if not settings_btn.pressed.is_connected(Callable(self, "_on_settings_pressed")):
			settings_btn.pressed.connect(Callable(self, "_on_settings_pressed"))
	if exit_btn:
		if not exit_btn.pressed.is_connected(Callable(self, "_on_exit_pressed")):
			exit_btn.pressed.connect(Callable(self, "_on_exit_pressed"))
	
	# Play menu buttons
	var offline_btn = play_menu.get_node_or_null("OfflineButton")
	var online_btn = play_menu.get_node_or_null("OnlineButton")
	var play_back_btn = play_menu.get_node_or_null("BackButton")
	
	if offline_btn:
		if not offline_btn.pressed.is_connected(Callable(self, "_on_offline_pressed")):
			offline_btn.pressed.connect(Callable(self, "_on_offline_pressed"))
	if online_btn:
		if not online_btn.pressed.is_connected(Callable(self, "_on_online_pressed")):
			online_btn.pressed.connect(Callable(self, "_on_online_pressed"))
	if play_back_btn:
		if not play_back_btn.pressed.is_connected(Callable(self, "_on_back_pressed")):
			play_back_btn.pressed.connect(Callable(self, "_on_back_pressed"))
	
	# Offline play menu buttons
	var easy_btn = offline_play_menu.get_node_or_null("EasyButton")
	var medium_btn = offline_play_menu.get_node_or_null("MediumButton")
	var hard_btn = offline_play_menu.get_node_or_null("HardButton")
	var offline_back_btn = offline_play_menu.get_node_or_null("BackButton")
	
	if easy_btn:
		if not easy_btn.pressed.is_connected(Callable(self, "_on_easy_pressed")):
			easy_btn.pressed.connect(Callable(self, "_on_easy_pressed"))
	if medium_btn:
		if not medium_btn.pressed.is_connected(Callable(self, "_on_medium_pressed")):
			medium_btn.pressed.connect(Callable(self, "_on_medium_pressed"))
	if hard_btn:
		if not hard_btn.pressed.is_connected(Callable(self, "_on_hard_pressed")):
			hard_btn.pressed.connect(Callable(self, "_on_hard_pressed"))
	if offline_back_btn:
		if not offline_back_btn.pressed.is_connected(Callable(self, "_on_back_pressed")):
			offline_back_btn.pressed.connect(Callable(self, "_on_back_pressed"))
	
	# Online play menu buttons
	var host_btn = online_play_menu.get_node_or_null("HostButton")
	var join_btn = online_play_menu.get_node_or_null("JoinButton")
	var login_btn = online_play_menu.get_node_or_null("LoginButton")
	var online_back_btn = online_play_menu.get_node_or_null("BackButton")
	
	if host_btn:
		if not host_btn.pressed.is_connected(Callable(self, "_on_host_pressed")):
			host_btn.pressed.connect(Callable(self, "_on_host_pressed"))
	if join_btn:
		if not join_btn.pressed.is_connected(Callable(self, "_on_join_pressed")):
			join_btn.pressed.connect(Callable(self, "_on_join_pressed"))
	if login_btn:
		if not login_btn.pressed.is_connected(Callable(self, "_on_login_pressed")):
			login_btn.pressed.connect(Callable(self, "_on_login_pressed"))
	if online_back_btn:
		if not online_back_btn.pressed.is_connected(Callable(self, "_on_back_pressed")):
			online_back_btn.pressed.connect(Callable(self, "_on_back_pressed"))


## Transition to a new menu with animation
func _transition_menu(new_state: MenuState) -> void:
	previous_menu_state = current_menu_state
	
	# Hide current menu with fade out
	_animate_menu_hide(current_menu_state)
	
	# Show new menu with fade in
	await get_tree().create_timer(ANIMATION_SPEED * 0.5).timeout
	_animate_menu_show(new_state)
	
	current_menu_state = new_state


## Animate menu fade out
func _animate_menu_hide(menu_state: MenuState) -> void:
	var menu = _get_menu_node(menu_state)
	if menu:
		var tween = create_tween()
		tween.tween_property(menu, "modulate:a", 0.0, ANIMATION_SPEED)
		tween.tween_callback(menu.hide)


## Animate menu fade in
func _animate_menu_show(menu_state: MenuState) -> void:
	var menu = _get_menu_node(menu_state)
	if menu:
		menu.show()
		menu.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(menu, "modulate:a", 1.0, ANIMATION_SPEED)


## Get menu node for a given state
func _get_menu_node(menu_state: MenuState) -> Control:
	match menu_state:
		MenuState.MAIN:
			return main_menu
		MenuState.PLAY:
			return play_menu
		MenuState.OFFLINE_PLAY:
			return offline_play_menu
		MenuState.ONLINE_PLAY:
			return online_play_menu
		_:
			return null


# ============ SIGNAL HANDLERS ============

func _on_play_pressed() -> void:
	_transition_menu(MenuState.PLAY)


func _on_offline_pressed() -> void:
	get_node("/root/GameState").set_game_mode("offline")
	_transition_menu(MenuState.OFFLINE_PLAY)


func _on_online_pressed() -> void:
	get_node("/root/GameState").set_game_mode("online")
	_transition_menu(MenuState.ONLINE_PLAY)


func _on_easy_pressed() -> void:
	get_node("/root/GameState").set_difficulty("easy")
	_start_game()


func _on_medium_pressed() -> void:
	get_node("/root/GameState").set_difficulty("medium")
	_start_game()


func _on_hard_pressed() -> void:
	get_node("/root/GameState").set_difficulty("hard")
	_start_game()


func _on_host_pressed() -> void:
	if get_node("/root/GameState").is_authenticated:
		print("Hosting multiplayer game...")
		# Create game session and wait for opponent
		# For now, just start the game
		_start_game()
	else:
		push_error("Must be logged in to host a game")


func _on_join_pressed() -> void:
	if get_node("/root/GameState").is_authenticated:
		print("Joining multiplayer game...")
		# Connect to game session and start
		# For now, just start the game
		_start_game()
	else:
		push_error("Must be logged in to join a game")


func _on_login_pressed() -> void:
	print("Opening login dialog...")
	# Show login dialog as popup
	var login_dialog = load("res://Scenes/ui/LoginDialog.tscn").instantiate()
	add_child(login_dialog)
	
	# Connect dialog buttons
	var login_btn = login_dialog.get_node_or_null("DialogPanel/VBoxContainer/ButtonContainer/LoginButton")
	var cancel_btn = login_dialog.get_node_or_null("DialogPanel/VBoxContainer/ButtonContainer/CancelButton")
	var username_input = login_dialog.get_node_or_null("DialogPanel/VBoxContainer/UsernameInput")
	
	if login_btn and not login_btn.pressed.is_connected(Callable(self, "_on_login_dialog_confirmed").bindv([login_dialog, username_input])):
		login_btn.pressed.connect(Callable(self, "_on_login_dialog_confirmed").bindv([login_dialog, username_input]))
	
	if cancel_btn and not cancel_btn.pressed.is_connected(Callable(self, "_on_login_dialog_cancelled").bindv([login_dialog])):
		cancel_btn.pressed.connect(Callable(self, "_on_login_dialog_cancelled").bindv([login_dialog]))


func _on_deck_manager_pressed() -> void:
	print("Opening deck builder...")
	get_tree().change_scene_to_file("res://Scenes/DeckBuilder.tscn")


func _on_settings_pressed() -> void:
	print("Opening settings...")
	get_tree().change_scene_to_file("res://Scenes/ui/Settings.tscn")


func _on_exit_pressed() -> void:
	print("Exiting game...")
	get_tree().quit()


func _on_back_pressed() -> void:
	# Return to previous menu or main menu
	if current_menu_state != MenuState.MAIN:
		if current_menu_state == MenuState.OFFLINE_PLAY or current_menu_state == MenuState.ONLINE_PLAY:
			_transition_menu(MenuState.PLAY)
		else:
			_transition_menu(MenuState.MAIN)


## Start the game with current settings - route through deck builder
func _start_game() -> void:
	print("Starting game with difficulty: %s, mode: %s" % [get_node("/root/GameState").difficulty, get_node("/root/GameState").game_mode])
	get_tree().change_scene_to_file("res://Scenes/DeckBuilder.tscn")


## Handle login dialog confirmation
func _on_login_dialog_confirmed(login_dialog: Control, username_input: LineEdit) -> void:
	var username = username_input.text.strip_edges()
	if username.is_empty():
		push_error("Username cannot be empty")
		return
	
	print("User logged in as: %s" % username)
	get_node("/root/GameState").set_authenticated(true, username)
	
	# Close the dialog
	if login_dialog:
		login_dialog.queue_free()


## Handle login dialog cancellation
func _on_login_dialog_cancelled(login_dialog: Control) -> void:
	print("Login cancelled")
	if login_dialog:
		login_dialog.queue_free()
