extends Area2D
# Initial speed (magnitude) of the projectile.
@export var initial_speed: float = 600.0
# Gravity strength in pixels per second^2.
@export var pGravity: float = 1200.0
# Rotation speed multiplier
@export var rotation_speed_multiplier: float = 0.01
# Trace settings
@export var enable_trace: bool = true
@export var trace_dot_interval: float = 0.05  # Time between dots in seconds
@export var trace_dot_lifetime: float = 1.0  # How long each dot lasts
@export var trace_dot_size: float = 4.0  # Size of the dots
@export var trace_dot_color: Color = Color(1, 1, 1, 0.7)  # Color of the dots
# Damage settings
@export var min_damage: float = 5.0
@export var max_damage: float = 40
@export var min_velocity_for_damage: float = 100.0  # Minimum velocity to deal min_damage
@export var max_velocity_for_damage: float = 1500.0  # Velocity at which max_damage is dealt

# Which direction the projectile is fired (usually normalized).
var direction: Vector2
# The projectile's current velocity (initially zero; set it up in _ready).
var velocity: Vector2 = Vector2.ZERO
# Reference to the terrain node (with the carve_requested signal).
var terrain_node: Node2D

var shooter_id: int
# Direction of rotation (1 for clockwise, -1 for counter-clockwise)
var spin_direction: int = 1
# Timer for dot trace
var trace_timer: float = 0.0

func _ready() -> void:
	# Select a random animation for the projectile
	var animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite and animated_sprite is AnimatedSprite2D:
		# Get all available animations
		var animations = animated_sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			# Select a random animation
			var random_animation = animations[randi() % animations.size()]
			# Play the selected animation
			animated_sprite.play(random_animation)
	
	# DO NOT override velocity if it's already been set
	# This is crucial - otherwise we lose our power settings
	if velocity == Vector2.ZERO:
		# Only set default velocity if none was provided
		velocity = direction.normalized() * initial_speed
		
	# Determine spin direction based on horizontal movement
	# If throwing right, spin clockwise (positive)
	# If throwing left, spin counter-clockwise (negative)
	spin_direction = 1 if direction.x >= 0 else -1

func _physics_process(delta: float) -> void:
	# Apply gravity to the projectile's vertical velocity.
	velocity.y += pGravity * delta
	# Update the projectile's position.
	position += velocity * delta
	
	# Calculate rotation speed based on the projectile's velocity magnitude
	var velocity_magnitude = velocity.length()
	var rotation_amount = velocity_magnitude * rotation_speed_multiplier * spin_direction * delta
	
	# Apply rotation based on throw direction and velocity
	rotate(rotation_amount)
	
	# Handle trace dots
	if enable_trace:
		trace_timer += delta
		if trace_timer >= trace_dot_interval:
			spawn_trace_dot()
			trace_timer = 0.0

# Spawn a trace dot at the current position
func spawn_trace_dot() -> void:
	var dot = Sprite2D.new()
	
	# Create a small circular texture for the dot
	var dot_texture = create_dot_texture(trace_dot_size, trace_dot_color)
	dot.texture = dot_texture
	
	# Set the dot's position to the projectile's current position
	dot.global_position = global_position
	
	# Add the dot to the scene tree
	get_tree().get_root().add_child(dot)
	
	# Set up the fade-out and removal of the dot
	var tween = get_tree().create_tween()
	tween.tween_property(dot, "modulate", Color(trace_dot_color.r, trace_dot_color.g, trace_dot_color.b, 0), trace_dot_lifetime)
	tween.tween_callback(dot.queue_free)

# Create a circular texture for the dot
func create_dot_texture(size: float, color: Color) -> ImageTexture:
	var image = Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent background
	
	# Draw a filled circle
	var center = Vector2(size/2, size/2)
	var radius = size/2
	
	for x in range(int(size)):
		for y in range(int(size)):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

# Calculate damage based on current velocity
func calculate_damage() -> float:
	var current_speed = velocity.length()
	
	print("current_speed" + str(current_speed))
	
	# Clamp the speed within our defined range
	current_speed = clamp(current_speed, min_velocity_for_damage, max_velocity_for_damage)
	
	# Calculate damage: linearly interpolate between min and max damage based on speed
	var t = (current_speed - min_velocity_for_damage) / (max_velocity_for_damage - min_velocity_for_damage)
	var damage = lerp(min_damage, max_damage, t)
	
	# Ensure we always return at least min_damage
	return max(damage, min_damage)

func _on_body_entered(body: Node2D) -> void:
	# This signal is triggered when the projectile overlaps a PhysicsBody2D or another Area2D.
	print(body)  # Debug what we're colliding with
	
	# Check if we're hitting terrain
	if body.is_in_group("Terrain"):
		terrain_node.emit_signal(
			"carve_requested", 
			terrain_node.to_local(global_position), 
			50.0
		)
		queue_free()
		
	if body.is_in_group("Players"):
		print("player")
		var player_id = body.player_id
		if shooter_id == player_id:
			return
		
		var player = TurnManager.get_player(player_id)
		if player:
			# Apply damage based on velocity
			var damage_amount = calculate_damage()
			print("Projectile hit with speed: ", velocity.length(), ", dealing damage: ", damage_amount)
			player.damage(damage_amount)
		queue_free()
