extends CharacterBody2D

const SPEED = 100.0
const MAX_SHOOT_FORCE = 800.0
const MIN_SHOOT_FORCE = 150.0
const GRAVITY = 1200.0          # Spieler Schwerkraft, nicht fürs Projektil
const TRAJECTORY_POINTS = 42
const MAX_TRAJECTORY_TIME = 5.0
const JETPACK_FORCE = 250.0

const JETPACK_MAX_FUEL = 1.0
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

@onready var fuel_bar = $FuelBar
var jetpack_active = false
var jetpack_fuel = JETPACK_MAX_FUEL
var jetpack_refilled = true

@export var player_id = 1
@export var terrain_node_path: NodePath

var terrain_node
var shoot_cooldown = 0.0
var shoot_delay = 0.5
var shoot_angle = -90.0

# Power shooting
var trajectory_dots: Array = []
var charging_power = false
var power_level = 0.0
var max_power = 1.0
var power_charge_rate = 1.0
var projectile_offset = Vector2()

# Waffen
var available_weapons: Array = []
var current_weapon_index: int = 0

# HUD
@onready var hud: CanvasLayer = get_tree().current_scene.get_node("HUD")

# Character Auswahl
var all_characters := ["prostitute", "adventurer", "female", "player", "soldier", "zombie"]
@export var fixed_character_name: String = ""   # optional fix per Inspector
var character_name: String = ""

func _ready() -> void:
	sprite = get_node("AnimatedSprite2D")
	deathSprite = get_node("DeathAnimationSprite")
	labelObj = get_node("PlayerLabel")

	labelObj.text = "Player " + str(player_id)
	available_weapons = GlobalSettings.available_weapons
	_update_weapon_display()

	# stabiler Charakter, kein Random in _ready
	if fixed_character_name != "":
		character_name = fixed_character_name
	else:
		character_name = GlobalSettings.ensure_player_character(player_id, all_characters)

	_init_character_pose()

	# Trajectory Line Setup
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

	print("Player " + str(player_id) + " initialized as " + character_name)

func _init_character_pose() -> void:
	var base_anim := character_name + "_move"
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(base_anim):
		sprite.animation = base_anim
		sprite.frame = 0
		sprite.stop()

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

func _process(delta: float) -> void:
	if health <= 0 and not dead:
		die()

	# Cooldown
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

	# Zielen und Schießen
	if is_my_turn() and not dead and not TurnManager.turn_locked:
		var previous_angle = shoot_angle
		var previous_power = power_level

		update_trajectory()

		if Input.is_action_pressed("player_up"):
			shoot_angle += 30.0 * delta
		if Input.is_action_pressed("player_down"):
			shoot_angle -= 30.0 * delta

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

	# Jetpack Fuel
	if jetpack_active:
		jetpack_fuel -= delta
		if jetpack_fuel <= 0.0:
			jetpack_active = false
			jetpack_fuel = 0.0

func update_trajectory():
	for dot in trajectory_dots:
		dot.queue_free()
	trajectory_dots.clear()
	trajectoryLine.clear_points()

	var weapon = available_weapons[current_weapon_index]
	var angle_rad = deg_to_rad(shoot_angle)
	var direction = Vector2.RIGHT.rotated(angle_rad)
	var time_step = 0.008

	# volle Vorschau beim Laden
	if charging_power:
		var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
		var vel = direction * (weapon["initial_speed"] * (actual_force / MAX_SHOOT_FORCE))
		var pos = projectile_offset
		for i in range(1, TRAJECTORY_POINTS + 1):
			vel.y += weapon["gravity"] * time_step
			pos += vel * time_step
			var dot = ColorRect.new()
			dot.color = Color(0.8, 0.8, 0.8, 1)
			var size = max(1.5, 6.0 - i * 0.20)
			dot.size = Vector2(size, size)
			dot.position = pos
			add_child(dot)
			trajectory_dots.append(dot)
	# kurze Vorschau sonst
	else:
		var preview_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * 0.75
		var vel = direction * (weapon["initial_speed"] * (preview_force / MAX_SHOOT_FORCE))
		var pos = projectile_offset
		for i in range(1, 6):
			vel.y += weapon["gravity"] * time_step
			pos += vel * time_step
			var dot = ColorRect.new()
			dot.color = Color(0.8, 0.8, 0.8, 1)
			var size = max(0.0, 6.0 - i * 1.5)
			if size <= 0.0:
				break
			dot.size = Vector2(size, size)
			dot.position = pos
			add_child(dot)
			trajectory_dots.append(dot)

func apply_dotted_effect():
	var points = trajectoryLine.get_point_count()
	var visible_points: Array[Vector2] = []
	for i in range(points):
		if i % 2 == 0:
			visible_points.append(trajectoryLine.get_point_position(i))
	trajectoryLine.clear_points()
	for point in visible_points:
		trajectoryLine.add_point(point)

func _physics_process(delta: float) -> void:
	HealthBar.value = health
	fuel_bar.value = jetpack_fuel

	# Jetpack
	if is_my_turn() and Input.is_action_pressed("player_jetpack") and jetpack_fuel > 0.0:
		jetpack_active = true
		jetpack_fuel -= delta
	else:
		jetpack_active = false

	if jetpack_active:
		velocity.y = -JETPACK_FORCE
	elif not is_on_floor():
		velocity.y += GRAVITY * delta

	# Bewegung sperren wenn nicht dran
	if not is_my_turn() or TurnManager.turn_locked:
		velocity.x = 0.0
		move_and_slide()
		return

	if dead:
		return

	# Fuel nach Zugwechsel auffüllen
	if not jetpack_refilled and is_my_turn():
		jetpack_fuel = JETPACK_MAX_FUEL
		jetpack_refilled = true

	var direction := Input.get_axis("player_left", "player_right")

	# Spiegeln
	if direction < 0.0:
		sprite.flip_h = true
	elif direction > 0.0:
		sprite.flip_h = false

	# Bewegung
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0.0

	# Distanzlimit
	if direction != 0.0 and distaceToMove > 0.0:
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

	# Laufanimation
	var moving: bool = abs(velocity.x) > 0.1 and not TurnManager.turn_locked and is_my_turn() and not dead and not jetpack_active
	var move_anim := character_name + "_move"
	if moving:
		if sprite.animation != move_anim or not sprite.is_playing():
			if sprite.sprite_frames and sprite.sprite_frames.has_animation(move_anim):
				sprite.play(move_anim)
	else:
		if sprite.animation != move_anim:
			sprite.animation = move_anim
		if sprite.is_playing() or sprite.frame != 0:
			sprite.frame = 0
			sprite.stop()

	move_and_slide()

func is_my_turn() -> bool:
	return TurnManager.current_player_id == player_id

# Projektil erzeugen
func do_shoot() -> void:
	if shoot_cooldown > 0.0 or dead or TurnManager.turn_locked:
		return

	var actual_force = MIN_SHOOT_FORCE + (MAX_SHOOT_FORCE - MIN_SHOOT_FORCE) * power_level
	var weapon = available_weapons[current_weapon_index]

	print("Player " + str(player_id) + " creating projectile with force " + str(actual_force) + " with weapon: " + weapon["name"])

	var projectile_scene = preload("res://scenes/projectile.tscn")
	var projectile = projectile_scene.instantiate()

	projectile.shooter_id = player_id
	projectile.shooter_node = self
	projectile.terrain_node = terrain_node

	projectile.weapon_name = weapon["name"]
	projectile.min_damage = weapon["min_damage"]
	projectile.max_damage = weapon["max_damage"]
	projectile.initial_speed = weapon["initial_speed"]
	projectile.gravity = weapon["gravity"]

	projectile.position = global_position + projectile_offset

	var angle_rad = deg_to_rad(shoot_angle)
	var direction = Vector2.RIGHT.rotated(angle_rad)

	# Geschwindigkeit = initial_speed mal Ladungsfaktor
	var normalized_force = actual_force / MAX_SHOOT_FORCE
	projectile.linear_velocity = direction * weapon["initial_speed"] * normalized_force
	projectile.direction = direction.normalized()

	get_tree().get_current_scene().add_child(projectile)

	shoot_cooldown = 1.0
	jetpack_refilled = false
	charging_power = false
	TurnManager.lock_turn()

# Waffenwechsel
func _input(event: InputEvent) -> void:
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
