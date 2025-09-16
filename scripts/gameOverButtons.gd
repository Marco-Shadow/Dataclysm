extends Node


func _on_pressed_Restart() -> void:
	print("Restart Pressed!")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_pressed_MainMenu() -> void:
	print("Main Menu Pressed!")
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
	
