extends Control

func _on_exit_pressed() -> void:
	print("Back to menu Pressed!")
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
	
func _on_player_vs_cpu_pressed() -> void:
	GlobalSettings.Player2Bot = true
	get_tree().change_scene_to_file("res://scenes/mapMenu.tscn")

func _on_player_vs_player_pressed() -> void:
	GlobalSettings.Player2Bot = false
	get_tree().change_scene_to_file("res://scenes/mapMenu.tscn")
