extends Node

var winnerlabel: Label

func _ready() -> void:
	winnerlabel = get_node("VBoxContainer/WinnerLabel")

	var winner = TurnManager.get_winner()
	
	if winner == 0:
		winnerlabel.text = "Draw!"
		return
	
	winnerlabel.text = "Player " + str(winner) + " won!"
