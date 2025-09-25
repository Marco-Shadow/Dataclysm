extends Node

var selected_map: String = ""

func _ready():
	$Tag/MapButtonDay.pressed.connect(_on_day_pressed)
	$Nacht/MapButtonNight.pressed.connect(_on_night_pressed)
	$Random/MapButtonRandom.pressed.connect(_on_random_pressed)

func _on_day_pressed() -> void:
	GlobalSettings.selected_map = "DAY"
	get_tree().change_scene_to_file("res://scenes/gameDay.tscn")

func _on_night_pressed() -> void:
	GlobalSettings.selected_map = "NIGHT"
	get_tree().change_scene_to_file("res://scenes/gameNight.tscn")

func _on_random_pressed() -> void:
	var options = [
		"res://scenes/gameDay.tscn",
        "res://scenes/gameNight.tscn"
	]
	var choice = options.pick_random()
	
	if "gameDay" in choice:
		GlobalSettings.selected_map = "DAY"
	elif "gameNight" in choice:
		GlobalSettings.selected_map = "NIGHT"
	else:
		GlobalSettings.selected_map = "DAY"
	
	get_tree().change_scene_to_file(choice)
