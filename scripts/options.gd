extends Control

var config_file = ConfigFile.new()
var config_path: String
var fullscreen_toggle: CheckButton

func _ready() -> void:
	# Set the config path based on OS
	if OS.get_name() == "Windows":
		config_path = "user://options.cfg"
	elif OS.get_name() == "Linux":
		config_path = "user://options.cfg"
	else:
		config_path = "user://options.cfg"
	
	# Get UI elements
	fullscreen_toggle = $VBoxContainer/FullscreenToggle
	
	# Load saved options
	load_options()
	
	# Connect signals
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

# Load options from config file
func load_options() -> void:
	var err = config_file.load(config_path)
	
	if err == OK:
		# Load fullscreen setting
		var is_fullscreen = config_file.get_value("display", "fullscreen", true) # Default to true
		fullscreen_toggle.button_pressed = is_fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# Set defaults and save them
		fullscreen_toggle.button_pressed = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		save_options()

# Save options to config file
func save_options() -> void:
	# Save fullscreen setting
	config_file.set_value("display", "fullscreen", fullscreen_toggle.button_pressed)
	
	# Save the file
	config_file.save(config_path)

# Back button pressed
func _on_back_pressed() -> void:
	save_options()
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

# Fullscreen toggle changed
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
