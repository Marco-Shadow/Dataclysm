extends Node

var config_file = ConfigFile.new()
var config_path: String

# Map selection
var selected_map: String = "DAY"

# Gloabl weaponlist => can be called everywhere with globalSettings.available_weapons
var available_weapons: Array = [
	{
		"name": "cd",
		"min_damage": 5, "max_damage": 15,
		"min_velocity_for_damage": 50, "max_velocity_for_damage": 500,
		"initial_speed": 700.0,
		"gravity": 900.0,
		"rotation_speed_multiplier": 0.02,
		"enable_trace": true,
		"trace_dot_interval": 0.04, "trace_dot_lifetime": 0.8,
		"trace_dot_size": 3.0, "trace_dot_color": Color(0.6, 0.8, 1, 0.7),
		"icon": preload("res://assets/projectiles/cd.png")
	},
	{
		"name": "controller",
		"min_damage": 15, "max_damage": 30,
		"min_velocity_for_damage": 80, "max_velocity_for_damage": 700,
		"initial_speed": 800.0,
		"gravity": 1000.0,
		"rotation_speed_multiplier": 0.015,
		"enable_trace": true,
		"trace_dot_interval": 0.06, "trace_dot_lifetime": 1.2,
		"trace_dot_size": 5.0, "trace_dot_color": Color(0.9, 0.6, 0.2, 0.7),
		"icon": preload("res://assets/projectiles/controller.png")
	},
	{
		"name": "headphones",
		"min_damage": 8, "max_damage": 20,
		"min_velocity_for_damage": 60, "max_velocity_for_damage": 600,
		"initial_speed": 750.0,
		"gravity": 950.0,
		"rotation_speed_multiplier": 0.02,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 4.0, "trace_dot_color": Color(1, 0.4, 0.6, 0.7),
		"icon": preload("res://assets/projectiles/headphones.png")
	},
	{
		"name": "joystick",
		"min_damage": 20, "max_damage": 45,
		"min_velocity_for_damage": 100, "max_velocity_for_damage": 800,
		"initial_speed": 900.0,
		"gravity": 1100.0,
		"rotation_speed_multiplier": 0.012,
		"enable_trace": false,
		"icon": preload("res://assets/projectiles/joystick.png")
	},
	{
		"name": "keyboard",
		"min_damage": 25, "max_damage": 60,
		"min_velocity_for_damage": 120, "max_velocity_for_damage": 900,
		"initial_speed": 950.0,
		"gravity": 750.0,
		"rotation_speed_multiplier": 0.025,
		"enable_trace": true,
		"trace_dot_interval": 0.07, "trace_dot_lifetime": 1.4,
		"trace_dot_size": 6.0, "trace_dot_color": Color(0.2, 1, 0.2, 0.7),
		"icon": preload("res://assets/projectiles/keyboard.png")
	},
	{
		"name": "laptop",
		"min_damage": 40, "max_damage": 80,
		"min_velocity_for_damage": 150, "max_velocity_for_damage": 1000,
		"initial_speed": 850.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.008,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 8.0, "trace_dot_color": Color(0.5, 0.5, 1, 0.7),
		"icon": preload("res://assets/projectiles/laptop.png")
	},
	{
		"name": "mainboard",
		"min_damage": 30, "max_damage": 70,
		"min_velocity_for_damage": 120, "max_velocity_for_damage": 900,
		"initial_speed": 800.0,
		"gravity": 1000.0,
		"rotation_speed_multiplier": 0.01,
		"enable_trace": false,
		"icon": preload("res://assets/projectiles/mainboard.png")
	},
	{
		"name": "mic",
		"min_damage": 12, "max_damage": 35,
		"min_velocity_for_damage": 60, "max_velocity_for_damage": 700,
		"initial_speed": 750.0,
		"gravity": 900.0,
		"rotation_speed_multiplier": 0.02,
		"enable_trace": true,
		"trace_dot_interval": 0.03, "trace_dot_lifetime": 0.7,
		"trace_dot_size": 3.0, "trace_dot_color": Color(1, 1, 0.3, 0.7),
		"icon": preload("res://assets/projectiles/mic.png")
	},
	{
		"name": "monitor",
		"min_damage": 50, "max_damage": 100,
		"min_velocity_for_damage": 180, "max_velocity_for_damage": 1200,
		"initial_speed": 950.0,
		"gravity": 1300.0,
		"rotation_speed_multiplier": 0.005,
		"enable_trace": true,
		"trace_dot_interval": 0.1, "trace_dot_lifetime": 2.0,
		"trace_dot_size": 10.0, "trace_dot_color": Color(1, 0, 0, 0.7),
		"icon": preload("res://assets/projectiles/monitor.png")
	},
	{
		"name": "mouse",
		"min_damage": 8, "max_damage": 25,
		"min_velocity_for_damage": 40, "max_velocity_for_damage": 500,
		"initial_speed": 700.0,
		"gravity": 850.0,
		"rotation_speed_multiplier": 0.03,
		"enable_trace": true,
		"trace_dot_interval": 0.02, "trace_dot_lifetime": 0.5,
		"trace_dot_size": 2.0, "trace_dot_color": Color(1, 1, 1, 0.7),
		"icon": preload("res://assets/projectiles/mouse.png")
	},
	{
		"name": "pc",
		"min_damage": 60, "max_damage": 120,
		"min_velocity_for_damage": 180, "max_velocity_for_damage": 1400,
		"initial_speed": 1000.0,
		"gravity": 1400.0,
		"rotation_speed_multiplier": 0.004,
		"enable_trace": true,
		"trace_dot_interval": 0.1, "trace_dot_lifetime": 2.5,
		"trace_dot_size": 12.0, "trace_dot_color": Color(0.3, 0.3, 1, 0.7),
		"icon": preload("res://assets/projectiles/pc.png")
	},
	{
		"name": "ram",
		"min_damage": 20, "max_damage": 50,
		"min_velocity_for_damage": 80, "max_velocity_for_damage": 800,
		"initial_speed": 800.0,
		"gravity": 950.0,
		"rotation_speed_multiplier": 0.015,
		"enable_trace": true,
		"trace_dot_interval": 0.04, "trace_dot_lifetime": 0.9,
		"trace_dot_size": 4.0, "trace_dot_color": Color(0.6, 1, 0.6, 0.7),
		"icon": preload("res://assets/projectiles/ram.png")
	},
	{
		"name": "rtx",
		"min_damage": 80, "max_damage": 150,
		"min_velocity_for_damage": 200, "max_velocity_for_damage": 1500,
		"initial_speed": 1100.0,
		"gravity": 1200.0,
		"rotation_speed_multiplier": 0.006,
		"enable_trace": true,
		"trace_dot_interval": 0.08, "trace_dot_lifetime": 1.8,
		"trace_dot_size": 9.0, "trace_dot_color": Color(0, 1, 1, 0.7),
		"icon": preload("res://assets/projectiles/rtx.png")
	},
	{
		"name": "smartphone",
		"min_damage": 18, "max_damage": 45,
		"min_velocity_for_damage": 80, "max_velocity_for_damage": 800,
		"initial_speed": 850.0,
		"gravity": 950.0,
		"rotation_speed_multiplier": 0.012,
		"enable_trace": true,
		"trace_dot_interval": 0.05, "trace_dot_lifetime": 1.0,
		"trace_dot_size": 5.0, "trace_dot_color": Color(1, 0.7, 0, 0.7),
		"icon": preload("res://assets/projectiles/smartphone.png")
	},
	{
		"name": "usb",
		"min_damage": 10, "max_damage": 20,
		"min_velocity_for_damage": 30, "max_velocity_for_damage": 400,
		"initial_speed": 650.0,
		"gravity": 800.0,
		"rotation_speed_multiplier": 0.03,
		"enable_trace": true,
		"trace_dot_interval": 0.02, "trace_dot_lifetime": 0.6,
		"trace_dot_size": 2.0, "trace_dot_color": Color(0.8, 0.8, 0.8, 0.7),
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
