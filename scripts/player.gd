extends CharacterBody2D
const SPEED = 100.0
const MAX_SHOOT_FORCE = 1500.0
const MIN_SHOOT_FORCE = 300.0
const GRAVITY = 1200.0
const TRAJECTORY_POINTS = 42
const MAX_TRAJECTORY_TIME = 5.0
const JETPACK_FORCE = 250.0  # Strong upward force for jetpack

const JETPACK_MAX_FUEL = 1.0  # 1.0 seconds of jetpack fuel per turn
const MaxMovementDistance = 200

var sprite: AnimatedSprite2D
var deathSprite: AnimatedSprite2D
var healthObj: Sprite2D
var labelObj: Label
var trajectoryLine: Line2D
var health: float = 100.0
var dead = false
var DistaceToMove := MaxMovementDistance

# Jetpack variables
@onready var fuel_bar = $FuelBar
var jetpack_active = false
var jetpack_fuel = JETPACK_MAX_FUEL
var jetpack_refilled = true  # Start with fuel available

@export var player_id = 1
@export var terrain_node_path: NodePath

var terrain_node
var shoot_cooldown = 0.0
var shoot_angle = -90

# Power shooting variables
var charging_power = false
var power_level = 0.0
var max_power = 1.0
var power_charge_rate = 1.0
var projectile_offset = Vector2()

func _ready() -> void:
	sprite = get_node("AnimatedSprite2D")
	deathSprite = get_node("DeathAnimationSprite")
	healthObj = get_node("Health")
	labelObj = get_node("PlayerLabel")
	
	labelObj.text = "Player " + str(player_id )	
	# Select a random animation for the projectile
	if sprite and sprite is AnimatedSprite2D:
		# Get all available animations
		var animations = sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			# Select a random animation
			var random_animation = animations[randi() % animations.size()]
			# Play the selected animation
			sprite.play(random_animation)
	
	# Set up trajectory line
	if has_node("TrajectoryLine"):
		trajectoryLine = get_node("TrajectoryLine")
	else:
		trajectoryLine = Line2D.new()
		trajectoryLine.name = "TrajectoryLine"
		trajectoryLine.width = 2.0
		trajectoryLine.default_color = Color(1, 1, 1, 0.5)  # Semi-transparent white
		trajectoryLine.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trajectoryLine.end_cap_mode = Line2D.LINE_CAP_ROUND
		trajectoryLine.antialiased = true
		add_child(trajectoryLine)
	
	trajectoryLine.visible = false
		
	if is_my_turn():
		update_trajectory()
		trajectoryLine.visible = true
	else:
		trajectoryLine.visible = false
		
	if terrain_node_path != null:
		terrain_node = get_node(terrain_node_path)
	print("Player " + str(player_id) + " initialized")
	

func die():
	dead = true
	health = 0
	sprite.visible = false
	trajectoryLine.visible = false
	deathSprite.play("explode")
	
	# Disable collision for the dead player
	collision_layer = 0
	collision_mask = 0
	
	# Disable all collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
	
	# If any Area2D nodes exist, disable their collision too
	for child in get_children():
		if child is Area2D:
			child.collision_layer = 0
			child.collision_mask = 0
			
			# Disable all collision shapes in the Area2D
			for area_child in child.get_children():
				if area_child is CollisionShape2D or area_child is CollisionPolygon2D:
					area_child.disabled = true
	
	TurnManager.mark_dead(player_id)
	if is_my_turn():
		TurnManager.switch_turn()
		
func damage(amount):
	health = max(0, health - amount)

func _process(delta: float) -> void:
	if(health <= 0 and not dead):
		die()
	
	# Update cooldown timer
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
		
	if is_my_turn() and not dead:
		var previous_angle = shoot_angle
		var previous_power = power_level
		
		update_trajectory()
		trajectoryLine.visible = true
		
		if Input.is_action_pressed("player_up") and shoot_angle < -10:
			shoot_angle += 30 * delta
		elif Input.is_action_pressed("player_down") and shoot_angle > -170:
			shoot_angle -= 30 * delta
		
		# Handle charging and shooting
		if Input.is_action_just_pressed("player_shoot"):
			# Start charging
			charging_power = true
			power_level = 0.0
			update_trajectory()  # Update with charging mode enabled
			
		elif charging_power and Input.is_action_pressed("player_shoot"):
			# Continue charging while button is held
			power_level = min(power_level + power_charge_rate * delta, max_power)
			
		elif charging_power and Input.is_action_just_released("player_shoot"):
			# Fire on release if we have enough power
			if power_level >= 0.05:  # Minimum power threshold
				do_shoot()
			
			# Reset charging state regardless
			charging_power = false
			update_trajectory()  # Update with charging mode disabled
		
		# Update trajectory if angle or power changed
		if previous_angle != shoot_angle || previous_power != power_level:
			update_trajectory()
	else:
		trajectoryLine.visible = false
	
	# Update jetpack fuel if active
	if jetpack_active:
		jetpack_fuel -= delta
		if jetpack_fuel <= 0:
			jetpack_active = false
			jetpack_fuel = 0

func update_trajectory():
	trajectoryLine.clear_points()
	
	var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
	
	var angle_rad = deg_to_rad(shoot_angle)
	# Always use the same direction calculation regardless of player flip
	var direction = Vector2.RIGHT.rotated(angle_rad)
	
	# Initial velocity and position
	var vel = direction * actual_force
	var pos = projectile_offset  # Starting position offset
	var time_step = 0.05  # Fixed time step for prediction
	
	# Add starting point
	trajectoryLine.add_point(pos)
	
	if charging_power:
		# Generate full trajectory when charging
		for i in range(1, TRAJECTORY_POINTS + 1):
			# Update velocity (apply gravity)
			vel.y += GRAVITY * time_step
			
			# Update position
			pos += vel * time_step
			
			# Add point
			trajectoryLine.add_point(pos)
		
		# Make trajectory dotted
		apply_dotted_effect()
	else:
		# When not charging, just add a second point to create a short direction line
		vel.y += GRAVITY * time_step
		pos += vel * time_step * 2  # Slightly longer line for better visibility
		
		# Add the second point for direction indication
		trajectoryLine.add_point(pos)

func apply_dotted_effect():
	var points = trajectoryLine.get_point_count()
	var visible_points = []
	
	for i in range(points):
		if i % 2 == 0:  # Only keep even-indexed points
			visible_points.append(trajectoryLine.get_point_position(i))
	
	trajectoryLine.clear_points()
	for point in visible_points:
		trajectoryLine.add_point(point)

func _physics_process(delta: float) -> void:
	healthObj.scale.x = (0.135 / 100) * health

	fuel_bar.value = jetpack_fuel

	# Check if jetpack is activated
	if is_my_turn() and Input.is_action_pressed("player_jetpack") and jetpack_fuel > 0:
		jetpack_active = true
		jetpack_fuel -= delta   # hier wird Treibstoff abgezogen
	else:
		jetpack_active = false
		
	# Apply jetpack force when active
	if jetpack_active:
		velocity.y = -JETPACK_FORCE
	elif not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Return early if it's not this player's turn
	if not is_my_turn():
		velocity.x = 0
		move_and_slide()
		return
	
	if dead:
		return
	
	# Check if this is a new turn for the player
	if not jetpack_refilled and is_my_turn():
		jetpack_fuel = JETPACK_MAX_FUEL
		jetpack_refilled = true
	
	# ---- ORIGINAL MOVEMENT CODE FROM YOUR SCRIPT ----
	var direction := Input.get_axis("player_left", "player_right")
	
	var was_flipped = sprite.flip_h
	
	if direction < 0:
		sprite.flip_h = true
	elif direction > 0:
		sprite.flip_h = false
		
	# No need to update trajectory when player flips anymore
	
	if direction != 0:
		velocity.x = direction * SPEED		
	else:
		velocity.x = 0
		
	# Richtung als -1 / 0 / 1
	
	if direction != 0 and DistaceToMove > 0.0:
		# Strecke, die wir *würden* zurücklegen in diesem Frame
		var distance_this_frame: float = abs(velocity.x) * delta

		if distance_this_frame >= DistaceToMove:
			# nur noch die restliche Distanz zulassen (verhindert negatives DistaceToMove)
			var allowed_ratio := 0.0
			if distance_this_frame != 0.0:
				allowed_ratio = DistaceToMove / distance_this_frame
			velocity.x = velocity.x * allowed_ratio
			DistaceToMove = 0.0
		else:
			# normalen Move erlauben und Distanz reduzieren
			DistaceToMove -= distance_this_frame
	else:
		velocity.x = 0.0
			
	move_and_slide()


func is_my_turn() -> bool:
	return TurnManager.current_player_id == player_id

# This is now the internal implementation that actually creates the projectile
func do_shoot() -> void:
	if shoot_cooldown > 0:
		return
		
	if dead:
		return
	
	# Calculate force
	var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
	
	print("Player " + str(player_id) + " creating projectile with force " + str(actual_force))
	var proj_scene = preload("uid://b4kdm3lq2kp7a")
	var projectile = proj_scene.instantiate()
	
	projectile.shooter_id = player_id
	projectile.shooter_node = self

	
	projectile.shooter_id = player_id
	
	# Use the same offset as in trajectory calculation
	projectile.position = global_position + projectile_offset
	
	# Calculate direction
	var angle_rad = deg_to_rad(shoot_angle)
	# Always use the same direction calculation regardless of player flip
	var direction = Vector2.RIGHT.rotated(angle_rad)
	
	# Apply initial velocity
	projectile.linear_velocity = direction * actual_force
	projectile.direction = direction.normalized()
	projectile.terrain_node = terrain_node 
	projectile.shooter_id = player_id
	projectile.shooter_node = self

	
	# Add projectile to scene
	get_tree().get_current_scene().add_child(projectile)
	
	# Set cooldown
	shoot_cooldown = 1.0
	
	# Mark that jetpack fuel should be refilled on next turn
	jetpack_refilled = false
	
	# Switch turns
	TurnManager.switch_turn()

# Public function that the turn manager can call
func shoot_projectile() -> void:
	# This function is kept for compatibility but now does nothing
	# The shooting is fully handled by the player's input logic
	pass
