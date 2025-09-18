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
@onready var HealthBar = $HealthBar
var labelObj: Label
var trajectoryLine: Line2D
var health: float = 100.0
var dead = false
var distaceToMove := MaxMovementDistance 
@onready var movementBar = $MovementBar 

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
var trajectory_dots: Array = []
var charging_power = false
var power_level = 0.0
var max_power = 1.0
var power_charge_rate = 1.0
var projectile_offset = Vector2()

# variables for weapons from global list 
var available_weapons: Array = []
var current_weapon_index: int = 0

# Variable for hud reference for weapon 
@onready var hud: CanvasLayer = get_tree().current_scene.get_node("HUD")

func _ready() -> void:
	sprite = get_node("AnimatedSprite2D")
	deathSprite = get_node("DeathAnimationSprite")
	labelObj = get_node("PlayerLabel")
	
	labelObj.text = "Player " + str(player_id )
	# Load weaponlist
	available_weapons = GlobalSettings.available_weapons
	_update_weapon_display()
	
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
	#sprite.visible = false
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
	if (health <= 0 and not dead):
		die()

	# Update cooldown timer
	if shoot_cooldown > 0:
		shoot_cooldown -= delta

	if is_my_turn() and not dead:
		var previous_angle = shoot_angle
		var previous_power = power_level

		update_trajectory()  # Punkte zeichnen

		if Input.is_action_pressed("player_up"):
			shoot_angle += 30 * delta
		if Input.is_action_pressed("player_down"):
			shoot_angle -= 30 * delta

		# Handle charging and shooting
		if Input.is_action_just_pressed("player_shoot"):
			charging_power = true
			power_level = 0.0
			update_trajectory()
		elif charging_power and Input.is_action_pressed("player_shoot"):
			power_level = min(power_level + power_charge_rate * delta, max_power)
		elif charging_power and Input.is_action_just_released("player_shoot"):
			if power_level >= 0.05:
				do_shoot()
			charging_power = false
			update_trajectory()

		if previous_angle != shoot_angle or previous_power != power_level:
			update_trajectory()
	else:
		# 👇 NEU: Alle Punkte löschen, wenn Spieler nicht am Zug ist
		var dot_container = get_node_or_null("TrajectoryDots")
		if dot_container:
			for child in dot_container.get_children():
				child.queue_free()

	if(health <= 0 and not dead):
		die()
	
	# Update cooldown timer
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
		
	if is_my_turn() and not dead:
		var previous_angle = shoot_angle
		var previous_power = power_level
		
		update_trajectory()
		
		if Input.is_action_pressed("player_up"):
			shoot_angle += 30 * delta
		if Input.is_action_pressed("player_down"):
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
	# --- ALTE PUNKTE LÖSCHEN ---
	for dot in trajectory_dots:
		dot.queue_free()
	trajectory_dots.clear()
	
	trajectoryLine.clear_points()
	
	var angle_rad = deg_to_rad(shoot_angle)
	var direction = Vector2.RIGHT.rotated(angle_rad)
	var time_step = 0.008
	
	# --------------------------------------------------------
	# 1. Wenn Spieler gerade auflädt -> volle Vorschau
	# --------------------------------------------------------
	if charging_power:
		var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
		var vel = direction * actual_force
		var pos = projectile_offset
		
		for i in range(1, TRAJECTORY_POINTS + 1):
			vel.y += GRAVITY * time_step
			pos += vel * time_step
			
			# --- Punkte erzeugen ---
			var dot = ColorRect.new()
			dot.color = Color(0.8, 0.8, 0.8, 1)  # grau
			var size = max(1.5, 6.0 - i * 0.20)   # Punkte schrumpfen
			dot.size = Vector2(size, size)
			dot.position = pos
			add_child(dot)
			trajectory_dots.append(dot)
	
	# --------------------------------------------------------
	# 2. Wenn Spieler NICHT auflädt -> kurze Richtungs-Vorschau
	# --------------------------------------------------------
	else:
		var preview_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * 0.75
		var vel = direction * preview_force
		var pos = projectile_offset
		
		for i in range(1, 6):  # nur 5 Punkte -> kurze Linie
			vel.y += GRAVITY * time_step
			pos += vel * time_step
			
			var dot = ColorRect.new()
			dot.color = Color(0.8, 0.8, 0.8, 1)
			
			# Punkte starten groß und verschwinden schnell
			var size = max(0.0, 6.0 - i * 1.5)
			if size <= 0:
				break
			
			dot.size = Vector2(size, size)
			dot.position = pos
			add_child(dot)
			trajectory_dots.append(dot)



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
	HealthBar.value = health

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
	
	if direction != 0 and distaceToMove > 0.0:
		# Strecke, die wir *würden* zurücklegen in diesem Frame
		var distance_this_frame: float = abs(velocity.x) * delta

		if distance_this_frame >= distaceToMove:
			# nur noch die restliche Distanz zulassen (verhindert negatives distaceToMove)
			var allowed_ratio := 0.0
			if distance_this_frame != 0.0:
				allowed_ratio = distaceToMove / distance_this_frame
			velocity.x = velocity.x * allowed_ratio
			distaceToMove = 0.0
		else:
			# normalen Move erlauben und Distanz reduzieren
			distaceToMove -= distance_this_frame
	else:
		velocity.x = 0.0
	
	movementBar.value = distaceToMove
	move_and_slide()


func is_my_turn() -> bool:
	return TurnManager.current_player_id == player_id

# This is now the internal implementation that actually creates the projectile
func do_shoot() -> void:
	if shoot_cooldown > 0 or dead:
		return
		
	# Calculate force
	var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
	
	# Aktuelle Waffe holen
	var weapon = available_weapons[current_weapon_index]
	
	print("Player " + str(player_id) + " creating projectile with force " + str(actual_force) + "with weapon: " + weapon["name"])
	#var proj_scene = preload("uid://b4kdm3lq2kp7a")
	#var projectile = proj_scene.instantiate()
	
	var projectile_scene = preload("res://scenes/projectile.tscn")
	var projectile = projectile_scene.instantiate()
	
	# set shooter infos settings
	projectile.shooter_id = player_id
	projectile.shooter_node = self
	
	projectile.terrain_node = terrain_node
	
	
	# Werte der Waffe ins Projektil übertragen
	projectile.weapon_name = weapon["name"];
	projectile.min_damage = weapon["min_damage"]
	projectile.max_damage = weapon["max_damage"]
	projectile.initial_speed = weapon["initial_speed"]
	projectile.gravity = weapon["gravity"]
	
	# Use the same offset as in trajectory calculation
	projectile.position = global_position + projectile_offset
	
	# Richtung berechnen
	var angle_rad = deg_to_rad(shoot_angle)
	var direction = Vector2.RIGHT.rotated(angle_rad)
	projectile.linear_velocity = direction * actual_force
	projectile.direction = direction.normalized()
	
	# Calculate direction auskommentiert drunter 
	# var angle_rad = deg_to_rad(shoot_angle)
	# Always use the same direction calculation regardless of player flip auskommentiert drunter
	# var direction = Vector2.RIGHT.rotated(angle_rad)
	
	# Apply initial velocity wurde auskommentiert
	# projectile.linear_velocity = direction * actual_force
	#projectile.direction = direction.normalized()
	#projectile.terrain_node = terrain_node 
	#projectile.shooter_id = player_id
	#projectile.shooter_node = self

	
	# Add projectile to scene
	get_tree().get_current_scene().add_child(projectile)
	
	# Set cooldown
	shoot_cooldown = 1.0
	
	# Mark that jetpack fuel should be refilled on next turn
	jetpack_refilled = false
	
	# Switch turns
	TurnManager.switch_turn()

# weapon functions
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_next"):
		_select_next_weapon()
	elif event.is_action_pressed("weapon_prev"):
		_select_previous_weapon()

# Waffenwechsel zuständige Funktionen
func _select_next_weapon() -> void:
	current_weapon_index += 1
	if current_weapon_index >= available_weapons.size():
		current_weapon_index = 0
	_update_weapon_display()


func _select_previous_weapon() -> void:
	current_weapon_index -= 1
	if current_weapon_index < 0:
		current_weapon_index = available_weapons.size() - 1
	_update_weapon_display()


func _update_weapon_display() -> void:
	# Aktuelle Waffe holen
	var weapon = available_weapons[current_weapon_index]
	# HUD aktualisieren
	hud.update_weapon(weapon["name"], weapon["icon"])


# Public function that the turn manager can call
func shoot_projectile() -> void:
	# This function is kept for compatibility but now does nothing
	# The shooting is fully handled by the player's input logic
	var weapon = available_weapons[current_weapon_index]

	# Projektil-Szene laden
	var projectile_scene = preload("res://scenes/projectile.tscn")
	var projectile = projectile_scene.instantiate()

	# Werte der aktuellen Waffe ins Projektil übertragen
	projectile.min_damage = weapon["min_damage"]
	projectile.max_damage = weapon["max_damage"]
	projectile.initial_speed = weapon["initial_speed"]
	projectile.gravity = weapon["gravity"]

	# Projektil in die Szene einfügen
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
