extends Node
#################################################
# STEAMWORKS SCRIPT
#################################################
var app_id: int = 3557600
var is_low_violence: bool = false

signal steamworks_error

func _ready() -> void:
	if !initialize_steam():
		is_low_violence = true
		return
	print("Steamworks ready")
	
func _process(_delta: float) -> void:
	Steam.run_callbacks()

func initialize_steam() -> bool:
	var initialize_data: Dictionary = Steam.steamInitEx(true, app_id)
	print("Did Steam initialize?: %s " % initialize_data)
	if initialize_data['status'] != Steam.STEAM_API_INIT_RESULT_OK:
		# Should trigger a pop-up in boot process to inform user the game is shutting down instead of just closing
		print(name, "Failed to initialize Steam. Reason: %s" % initialize_data)
		steamworks_error.emit("Failed to initialized Steam!")
		return false
	return true
