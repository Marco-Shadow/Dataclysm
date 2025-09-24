extends Node

var config_file = ConfigFile.new()
var config_path: String

# Map selection
var selected_map: String = "DAY"

# Gloabl weaponlist => can be called everywhere with globalSettings.available_weapons
var available_weapons: Array = [
	{
		"name": "cd",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/cd.png")
	},
	{
		"name": "controller",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/controller.png")
	},
	{
		"name": "headphones",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/headphones.png")
	},
	{
		"name": "joystick",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/joystick.png")
	},
	{
		"name": "keyboard",
		"min_damage": 20, "max_damage": 60,
		"min_velocity_for_damage": 200, "max_velocity_for_damage": 1500,
		"initial_speed": 800.0,
		"gravity": 900.0,
		"rotation_speed_multiplier": 0.02,
		"enable_trace": false,
		"icon": preload("res://assets/projectiles/keyboard.png")
	},
	{
		"name": "laptop",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/laptop.png")
	},
	{
		"name": "mainboard",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/mainboard.png")
	},
	{
		"name": "mic",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/mic.png")
	},
	{
		"name": "monitor",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/monitor.png")
	},
	{
		"name": "mouse",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/mouse.png")
	},
	{
		"name": "pc",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/pc.png")
	},
	{
		"name": "ram",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/ram.png")
	},
	{
		"name": "rtx",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/rtx.png")
	},
	{
		"name": "smartphone",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/smartphone.png")
	},
	{
		"name": "usb",
		"min_damage": 10, "max_damage": 40,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 1200,
		"initial_speed": 600.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1,1,1,0.7),
		"icon": preload("res://assets/projectiles/usb.png")
	}
]



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
