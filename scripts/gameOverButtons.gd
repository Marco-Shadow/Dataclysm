extends Node


func _on_pressed_Restart() -> void:
	print("Restart Pressed!")
	if(GlobalSettings.selected_map == "NIGHT"):
		get_tree().change_scene_to_file("res://scenes/gameNight.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/gameDay.tscn")

func _on_pressed_MainMenu() -> void:
	print("Main Menu Pressed!")
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
	
