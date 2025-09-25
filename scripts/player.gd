extends CharacterBody2D
const SPEED = 100.0
const MAX_SHOOT_FORCE = 800.0   # vorher 1500.0
const MIN_SHOOT_FORCE = 150.0   # vorher 300.0
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

#Bot variables
@export var is_bot: bool = false   # true = dieser Player ist ein Bot
var bot_has_shot: bool = false
var was_my_turn_last_frame: bool = false

# Jetpack variables
@onready var fuel_bar = $FuelBar
var jetpack_active = false
var jetpack_fuel = JETPACK_MAX_FUEL
var jetpack_refilled = true  # Start with fuel available

@export var player_id = 1
@export var terrain_node_path: NodePath

var terrain_node
var shoot_cooldown = 0.0
var shoot_delay = 0.5 # zwischen schüssen
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
		var animations = sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			var random_animation = animations[randi() % animations.size()]
			sprite.play(random_animation)
	
	# Set up trajectory line
	if has_node("TrajectoryLine"):
		trajectoryLine = get_node("TrajectoryLine")
	else:
		trajectoryLine = Line2D.new()
		trajectoryLine.name = "TrajectoryLine"
		trajectoryLine.width = 2.0
		trajectoryLine.default_color = Color(1, 1, 1, 0.5)
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
	trajectoryLine.visible = false
	deathSprite.play("explode")
	
	for child in get_children():
		if child is Area2D:
			child.collision_layer = 0
			child.collision_mask = 0
			for area_child in child.get_children():
				if area_child is CollisionShape2D or area_child is CollisionPolygon2D:
					area_child.disabled = true
	
	TurnManager.mark_dead(player_id)
	if is_my_turn():
		TurnManager.switch_turn()
		
func damage(amount):
	health = max(0, health - amount)

# ✅ FIX: hier war vorher "die()" → jetzt Health-Check
func _process(delta: float) -> void:
	if health <= 0.0 and not dead:
		die()
		
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	# --- Turn-Start-Erkennung nur für Bot ---
	if is_bot:
		var now_my_turn := is_my_turn()
		if now_my_turn and not was_my_turn_last_frame:
			bot_has_shot = false
		was_my_turn_last_frame = now_my_turn
	
	# --- Bot übernimmt hier ---
	if is_bot and is_my_turn() and not bot_has_shot and not dead and not TurnManager.turn_locked:
		print("Bot ist am Zug → _bot_tick wird aufgerufen")
		_bot_tick(delta)
		return

	# --- Spieler-Input ---
	if not is_bot and is_my_turn() and not dead and not TurnManager.turn_locked:
		var previous_angle = shoot_angle
		var previous_power = power_level

		update_trajectory()

		if Input.is_action_pressed("player_up"):
			shoot_angle += 30 * delta
		if Input.is_action_pressed("player_down"):
			shoot_angle -= 30 * delta

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
		charging_power = false
		trajectoryLine.visible = false
		for dot in trajectory_dots:
			dot.queue_free()
		trajectory_dots.clear()

	if jetpack_active:
		jetpack_fuel -= delta
		if jetpack_fuel <= 0:
			jetpack_active = false
			jetpack_fuel = 0

func update_trajectory():
	for dot in trajectory_dots:
		dot.queue_free()
	trajectory_dots.clear()
	
	trajectoryLine.clear_points()
	
	var angle_rad = deg_to_rad(shoot_angle)
	var direction = Vector2.RIGHT.rotated(angle_rad)
	var time_step = 0.008
	
	if charging_power:
		var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
		var vel = direction * actual_force
		var pos = projectile_offset
		
		for i in range(1, TRAJECTORY_POINTS + 1):
			vel.y += GRAVITY * time_step
			pos += vel * time_step
			
			var dot = ColorRect.new()
			dot.color = Color(0.8, 0.8, 0.8, 1)
			var size = max(1.5, 6.0 - i * 0.20)
			dot.size = Vector2(size, size)
			dot.position = pos
			add_child(dot)
			trajectory_dots.append(dot)
	else:
		var preview_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * 0.75
		var vel = direction * preview_force
		var pos = projectile_offset
		
		for i in range(1, 6):
			vel.y += GRAVITY * time_step
			pos += vel * time_step
			
			var dot = ColorRect.new()
			dot.color = Color(0.8, 0.8, 0.8, 1)
			var size = max(0.0, 6.0 - i * 1.5)
			if size <= 0:
				break
			
			dot.size = Vector2(size, size)
			dot.position = pos
			add_child(dot)
			trajectory_dots.append(dot)

# ✅ FIX: Bot ignoriert hier Eingaben und bewegt sich nur über _bot_tick
func _physics_process(delta: float) -> void:
	HealthBar.value = health
	fuel_bar.value = jetpack_fuel

	if is_my_turn() and Input.is_action_pressed("player_jetpack") and jetpack_fuel > 0 and not is_bot:
		jetpack_active = true
		jetpack_fuel -= delta
	elif is_bot:
		pass # Bot steuert jetpack in _bot_tick()
	else:
		jetpack_active = false
		
	if jetpack_active:
		velocity.y = -JETPACK_FORCE
	elif not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if not is_my_turn() or TurnManager.turn_locked:
		velocity.x = 0
		move_and_slide()
		return
	
	if dead:
		return
	
	if not jetpack_refilled and is_my_turn():
		jetpack_fuel = JETPACK_MAX_FUEL
		jetpack_refilled = true

	# ✅ BOT ignoriert Player Input
	if is_bot:
		move_and_slide()
		return
	
	var direction := Input.get_axis("player_left", "player_right")
	
	if direction < 0:
		sprite.flip_h = true
	elif direction > 0:
		sprite.flip_h = false
		
	if direction != 0:
		velocity.x = direction * SPEED		
	else:
		velocity.x = 0
		
	if direction != 0 and distaceToMove > 0.0:
		var distance_this_frame: float = abs(velocity.x) * delta

		if distance_this_frame >= distaceToMove:
			var allowed_ratio := 0.0
			if distance_this_frame != 0.0:
				allowed_ratio = distaceToMove / distance_this_frame
			velocity.x = velocity.x * allowed_ratio
			distaceToMove = 0.0
		else:
			distaceToMove -= distance_this_frame
	else:
		velocity.x = 0.0
	
	movementBar.value = distaceToMove
	move_and_slide()

func is_my_turn() -> bool:
	return TurnManager.current_player_id == player_id

func do_shoot() -> void:
	if shoot_cooldown > 0.0 or dead or TurnManager.turn_locked:
		return
		 
	var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
	var weapon = available_weapons[current_weapon_index]
	
	print("Player " + str(player_id) + " creating projectile with force " + str(actual_force) + "with weapon: " + weapon["name"])
	
	var projectile_scene = preload("res://scenes/projectile.tscn")
	var projectile = projectile_scene.instantiate()
	
	projectile.shooter_id = player_id
	projectile.shooter_node = self
	projectile.terrain_node = terrain_node
	
	projectile.weapon_name = weapon["name"];
	projectile.min_damage = weapon["min_damage"]
	projectile.max_damage = weapon["max_damage"]
	projectile.initial_speed = weapon["initial_speed"]
	projectile.gravity = weapon["gravity"]
	
	projectile.position = global_position + projectile_offset
	
	var angle_rad = deg_to_rad(shoot_angle)
	var direction = Vector2.RIGHT.rotated(angle_rad)
	projectile.linear_velocity = direction * actual_force
	projectile.direction = direction.normalized()
		
	get_tree().get_current_scene().add_child(projectile)
	
	shoot_cooldown = 1.0
	jetpack_refilled = false
	charging_power = false
	TurnManager.lock_turn()

# ✅ FIX: Bot ignoriert _input komplett
func _input(event: InputEvent) -> void:
	if is_bot:
		return
	if event.is_action_pressed("weapon_next"):
		_select_next_weapon()
	elif event.is_action_pressed("weapon_prev"):
		_select_previous_weapon()

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
	var weapon = available_weapons[current_weapon_index]
	hud.update_weapon(weapon["name"], weapon["icon"])

# --- BOT FUNKTION bleibt unverändert ---
func _bot_tick(_delta: float) -> void:
	if not is_my_turn() or dead or TurnManager.turn_locked:
		return
	if bot_has_shot:
		return

	var target: CharacterBody2D = TurnManager.get_player(1)
	if target == null or target.dead:
		return

	# Kleine Bewegung Richtung Ziel
	var dx = target.global_position.x - global_position.x
	if abs(dx) > 50:
		if dx > 0:
			velocity.x = SPEED
		else:
			velocity.x = -SPEED
		jetpack_active = true
		jetpack_fuel = max(jetpack_fuel - _delta, 0.0)
		await get_tree().create_timer(0.7).timeout
		velocity.x = 0
		jetpack_active = false

	# Projektil-Parameter
	var weapon = available_weapons[current_weapon_index]
	var g: float = 1000.0
	if weapon.has("gravity"):
		g = float(weapon["gravity"])

	var v_min: float = MIN_SHOOT_FORCE
	var v_max: float = MAX_SHOOT_FORCE

	dx = target.global_position.x - global_position.x
	var dy: float = target.global_position.y - global_position.y

	var ax: float = abs(dx)
	var dy_math: float = -dy

	var found := false
	var theta_math := 0.0
	var chosen_power := 0.6

	for p in range(40, 101, 5):
		var power: float = float(p) / 100.0
		var v: float = v_min + (v_max - v_min) * power
		var v2: float = v * v

		var disc: float = v2 * v2 - g * (g * ax * ax + 2.0 * dy_math * v2)
		if disc < 0.0:
			continue

		var root: float = sqrt(disc)
		var theta_low := atan((v2 - root) / (g * ax))
		theta_math = theta_low

		if dx < 0.0:
			theta_math = PI - theta_low

		chosen_power = power
		found = true
		break

	if not found:
		var safe_dx: float = dx
		if dx == 0.0:
			safe_dx = 1.0
		shoot_angle = rad_to_deg(atan2(-220.0, safe_dx))
		power_level = 0.65
		do_shoot()
		bot_has_shot = true
		return

	var theta_godot := -theta_math
	shoot_angle = rad_to_deg(theta_godot)
	power_level = chosen_power

	do_shoot()
	bot_has_shot = true

	print("Bot Schuss -> angle:", shoot_angle, " power:", power_level, " g:", g, " dx:", dx, " dy:", dy)
