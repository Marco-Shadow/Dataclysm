extends RigidBody2D

# Rotation
@export var rotation_speed_multiplier: float = 0.01

# Trace settings
@export var enable_trace: bool = true
@export var trace_dot_interval: float = 0.05
@export var trace_dot_lifetime: float = 1.0
@export var trace_dot_size: float = 4.0
@export var trace_dot_color: Color = Color(1, 1, 1, 0.7)

# Damage scaling
@export var min_velocity_for_damage: float = 50.0
@export var max_velocity_for_damage: float = 800.0

# Shooter
var direction: Vector2
var shooter_id: int
var shooter_node: Node2D
var terrain_node: Node2D

# Misc
var spin_direction: int = 1
var trace_timer: float = 0.0

# Weapon values
var min_damage: int = 0
var max_damage: int = 0
var initial_speed: float = 0.0
var gravity: float = 0.0

var weapon_name: String = "cd"
var velocity: Vector2 = Vector2.ZERO

# Turn-Abschluss
var turn_finished: bool = false

# --- Schaden-Delay ---
@export var damage_activation_delay: float = 0.5   # Gegner ab 0,5s
@export var self_damage_delay: float = 1.5         # Eigenschaden ab 1,5s
var damage_timer: float = 0.0
var damage_active: bool = false
var self_damage_active: bool = false

# --- Out-of-bounds Timer ---
@export var out_of_bounds_lifetime: float = 1.5
var out_of_bounds_timer: float = -1.0

func _ready() -> void:
	add_to_group("projectiles")
	connect("body_entered", Callable(self, "_on_body_entered"))

	var animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite and animated_sprite is AnimatedSprite2D:
		if animated_sprite.sprite_frames.has_animation(weapon_name):
			animated_sprite.play(weapon_name)

	if linear_velocity == Vector2.ZERO and direction != Vector2.ZERO:
		linear_velocity = direction.normalized() * initial_speed

	spin_direction = 1 if direction.x >= 0 else -1

	# Schützen kurz ignorieren
	if shooter_node:
		add_collision_exception_with(shooter_node)
		await get_tree().create_timer(0.2).timeout
		remove_collision_exception_with(shooter_node)

	# Terrain kurz ignorieren
	if terrain_node:
		add_collision_exception_with(terrain_node)
		await get_tree().create_timer(0.1).timeout
		remove_collision_exception_with(terrain_node)

func _physics_process(delta: float) -> void:
	# Gravitation
	linear_velocity.y += gravity * delta

	# Rotation
	var vmag = linear_velocity.length()
	var rotation_amount = vmag * rotation_speed_multiplier * spin_direction * delta
	rotate(rotation_amount)

	# Schaden-Delays
	damage_timer += delta
	if not damage_active and damage_timer >= damage_activation_delay:
		damage_active = true
	if not self_damage_active and damage_timer >= self_damage_delay:
		self_damage_active = true

	# Out-of-bounds check (links/rechts)
	var outside_horizontally = false
	if terrain_node and terrain_node.has_method("get_used_rect"):
		var world_rect: Rect2 = terrain_node.get_used_rect()
		outside_horizontally = (
			global_position.x < world_rect.position.x or
			global_position.x > world_rect.position.x + world_rect.size.x
		)
	else:
		var vp = get_viewport().get_visible_rect()
		var margin = 400.0
		outside_horizontally = (
			global_position.x < vp.position.x - margin or
			global_position.x > vp.position.x + vp.size.x + margin
		)

	if outside_horizontally:
		if out_of_bounds_timer < 0.0:
			print("⚠️ Projectile left world horizontally, starting despawn timer")
			out_of_bounds_timer = out_of_bounds_lifetime
	else:
		out_of_bounds_timer = -1.0

	if out_of_bounds_timer > 0.0:
		out_of_bounds_timer -= delta
		if out_of_bounds_timer <= 0.0:
			print("💥 Projectile despawned after out-of-bounds delay")
			_end_turn_and_free()

	# Trace
	if enable_trace:
		trace_timer += delta
		if trace_timer >= trace_dot_interval:
			spawn_trace_dot()
			trace_timer = 0.0

# Trace-Dot
func spawn_trace_dot() -> void:
	var dot = Sprite2D.new()
	var dot_texture = create_dot_texture(trace_dot_size, trace_dot_color)
	dot.texture = dot_texture
	dot.global_position = global_position
	get_parent().add_child(dot)

	var tween = get_tree().create_tween()
	tween.tween_property(dot, "modulate", Color(trace_dot_color.r, trace_dot_color.g, trace_dot_color.b, 0), trace_dot_lifetime)
	tween.tween_callback(dot.queue_free)

func create_dot_texture(size: float, color: Color) -> ImageTexture:
	var image = Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2
	for x in range(int(size)):
		for y in range(int(size)):
			if Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

# Damage-Berechnung
func calculate_damage() -> float:
	var current_speed = linear_velocity.length()
	if current_speed < min_velocity_for_damage:
		return 0.0
	var t = clamp(
		(current_speed - min_velocity_for_damage) / max(1.0, (max_velocity_for_damage - min_velocity_for_damage)),
		0.0, 1.0
	)
	return lerp(min_damage, max_damage, t)

# Turn beenden
func _end_turn_and_free() -> void:
	if turn_finished:
		return
	turn_finished = true
	print(">>> Projectile ended turn, unlocking")
	TurnManager.unlock_turn()
	queue_free()

# Kollisionsabfrage
func _on_body_entered(body: Node) -> void:
	if turn_finished:
		return

	if body.is_in_group("Terrain"):
		if terrain_node:
			terrain_node.emit_signal("carve_requested", terrain_node.to_local(global_position), 50.0)
		_end_turn_and_free()
		return

	if body.is_in_group("Players"):
		var damage_amount = calculate_damage()

		# Eigenschaden
		if body.player_id == shooter_id:
			if self_damage_active:
				if damage_amount > 0.0:
					body.damage(damage_amount)
					print("💥 Self-damage dealt to Player ", body.player_id)
			else:
				print("⚠️ Projectile hit shooter but self-damage not active yet")
		else:
			# Gegner
			if damage_active:
				if damage_amount > 0.0:
					body.damage(damage_amount)
					print("💥 Damage dealt to Player ", body.player_id)
			else:
				print("⚠️ Projectile hit other player but damage delay not reached")

		_end_turn_and_free()
		return

# Sicherheitsleine
func _exit_tree() -> void:
	if not turn_finished:
		print("⚠️ Projectile removed unexpectedly, unlocking as fallback")
		TurnManager.unlock_turn()
		turn_finished = true
