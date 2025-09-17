extends Node

var config_file = ConfigFile.new()
var config_path: String

func _ready() -> void:
	# Set the config path based on OS
	if OS.get_name() == "Windows":
		config_path = "user://options.cfg"
	elif OS.get_name() == "Linux":
		config_path = "user://options.cfg"
	else:
		config_path = "user://options.cfg"
	
	# Load and apply settings
	load_and_apply_settings()

# Load and apply settings from config file
func load_and_apply_settings() -> void:
	var err = config_file.load(config_path)
	
	if err == OK:
		# Apply fullscreen setting
		var is_fullscreen = config_file.get_value("display", "fullscreen", true) # Default to true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# Set defaults and save them
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		# Save the defaults
		config_file.set_value("display", "fullscreen", true)
		config_file.save(config_path)
