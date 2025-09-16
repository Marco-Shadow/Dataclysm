extends Node
var playerCount = 2
var players: PackedInt32Array = []

var playerInstances = {}

var deadplayers: PackedInt32Array = []
var current_player_id: int = 1
var game: Node2D
var world: Node2D
var player_scene: PackedScene
var camera: Camera2D
var changedToGameover = false

func initialize(p_game: Node2D, p_world: Node2D, p_player_scene: PackedScene, 
				p_camera: Camera2D) -> void:
	game = p_game
	world = p_world
	player_scene = p_player_scene
	camera = p_camera
	
	players.clear()
	deadplayers.clear()
	playerInstances.clear()
	
	current_player_id = 1
	changedToGameover = false
	
	# Now we can start the turn manager
	start()

func start() -> void:
	# Initialize random number generator
	randomize()
	
	# Wait a bit to ensure the world has been generated
	await get_tree().create_timer(0.5).timeout
	
	# Spawn players at random positions
	for i in range(playerCount):
		var playerId = i + 1
		spawn_player(playerId)
		print("Spawned player ", playerId)
		
	# Ensure we start with a valid player
	current_player_id = 1
	print("Initial turn: Player ", current_player_id)

func spawn_player(id: int) -> void:
	# Create instance of player scene
	var player_instance = player_scene.instantiate()
	
	player_instance.add_to_group("Players")
	
	# Set random position on the terrain
	var spawn_position = world.find_player_spawnpoint(camera, id - 1, playerCount)
	player_instance.position = spawn_position
	
	# Set player ID
	player_instance.player_id = id
	
	# Set turn manager and terrain references
	player_instance.terrain_node_path = world.get_path()
	
	# Add to players array
	players.append(id)
	
	playerInstances[id] = player_instance
	
	# Add player to the game scene
	game.add_child(player_instance)
	
	print("Kill area path: ", "KillArea")
	var kill_area = game.get_node_or_null("KillArea")
	print("Found kill area: ", kill_area != null)
	if kill_area != null:
		kill_area.body_entered.connect(func(body):
			if body == player_instance:
				player_instance.die()
		)
		
func _process(delta: float) -> void:
	if one_player_remaining() and not changedToGameover:
		get_tree().change_scene_to_file("res://scenes/gameOver.tscn")
		changedToGameover = true
		return

func switch_turn():
	if one_player_remaining():
		return
		
	# Get the current player's ID before switching
	var previous_player_id = current_player_id
	
	# Find the next alive player
	var next_player_found = false
	var try_player_id = current_player_id
	
	# Try up to playerCount times to find an alive player
	for i in range(playerCount):
		# Move to the next player (looping back to 1 if necessary)
		try_player_id = (try_player_id % playerCount) + 1
		
		# If this player is alive, we've found our next player
		if not deadplayers.has(try_player_id):
			current_player_id = try_player_id
			next_player_found = true
			break
	
	# Only announce the switch if we actually changed players
	if next_player_found and previous_player_id != current_player_id:
		print("Switched turn to player ", current_player_id)

# Helper function to check if all players are dead
func all_players_dead() -> bool:
	for id in players:
		if not deadplayers.has(id):
			return false
	return true
	
func one_player_remaining() -> bool:
	var remaining = 0
	for id in players:
		if not deadplayers.has(id):
			remaining += 1
	return remaining == 1
	
func get_winner() -> int:
	var aliveId = 0
	for id in players:
		if not deadplayers.has(id):
			aliveId = id
			
	return aliveId
	
func get_player(id):
	if deadplayers.has(id):
		return null
		
	if not playerInstances.has(id):
		return null
		
	return playerInstances[id]

func mark_dead(id):
	if not deadplayers.has(id):
		deadplayers.append(id)
		print("Player ", id, " marked as dead")
