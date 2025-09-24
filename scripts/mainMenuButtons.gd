extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide exit button if running on web platform
	if OS.has_feature("web"):
		if name == "Button3" or text.strip_edges() == "Exit":
			visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	print("Start Pressed!")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_settings_pressed() -> void:
	print("Settings Pressed!")
	get_tree().change_scene_to_file("res://scenes/options.tscn")
	
func _on_exit_pressed() -> void:
	print("Exit Pressed!")
	get_tree().quit()
