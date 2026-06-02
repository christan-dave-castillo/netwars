extends Control
## Settings Scene

func _ready() -> void:
	var back_button = get_node_or_null("BackButton")
	if back_button and not back_button.pressed.is_connected(Callable(self, "_on_back_pressed")):
		back_button.pressed.connect(Callable(self, "_on_back_pressed"))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ui/MainMenu.tscn")
