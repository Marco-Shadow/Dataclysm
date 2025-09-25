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

# Weapon values (überschrieben vom Player)
var min_damage: int = 0
var max_damage: int = 0
var initial_speed: float = 0.0
var gravity: float = 0.0

var weapon_name: String = "cd"
var velocity: Vector2 = Vector2.ZERO

# Turn-Abschluss-Flag (verhindert doppeltes Freigeben/Wechseln)
var turn_finished: bool = false

func _ready() -> void:
	var animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite and animated_sprite is AnimatedSprite2D:
		if animated_sprite.sprite_frames.has_animation(weapon_name):
			animated_sprite.play(weapon_name)
	
	# Falls linear_velocity noch 0 ist, mit initial_speed starten
	if linear_velocity == Vector2.ZERO and direction != Vector2.ZERO:
		linear_velocity = direction.normalized() * initial_speed
	
	spin_direction = 1 if direction.x >= 0 else -1
	
	# Kurzzeitige Kollisionsausnahme für den Schützen
	if shooter_node:
		add_collision_exception_with(shooter_node)
		await get_tree().create_timer(0.2).timeout
		remove_collision_exception_with(shooter_node)

	# Terrain 0.1 Sekunden lang ignorieren (gegen Kanten-Kollision beim Spawn)
	if terrain_node:
		add_collision_exception_with(terrain_node)
		await get_tree().create_timer(0.1).timeout
		remove_collision_exception_with(terrain_node)

func _physics_process(delta: float) -> void:
	# Waffenabhängige Gravitation anwenden
	linear_velocity.y += gravity * delta
	
	var velocity_magnitude = linear_velocity.length()
	var rotation_amount = velocity_magnitude * rotation_speed_multiplier * spin_direction * delta
	rotate(rotation_amount)
	
	# --- Bildschirmgrenzen prüfen ---
	var viewport_rect = get_viewport().get_visible_rect()
	
	# Oben raus -> nichts tun, Projektil soll zurückfallen
	if global_position.y < viewport_rect.position.y:
		pass
	# Links / Rechts / Unten raus -> Turn beenden
	elif global_position.x < viewport_rect.position.x \
	or global_position.x > viewport_rect.position.x + viewport_rect.size.x \
	or global_position.y > viewport_rect.position.y + viewport_rect.size.y:
		_end_turn_and_free()
	
	# Trace-Effekt
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
	var max_speed = max(initial_speed, 1.0)
	var t = clamp(current_speed / max_speed, 0.0, 1.0)
	var damage = lerp(min_damage, max_damage, t)
	return max(damage, 0.0)

# Hilfsfunktion: Turn beenden und Projektil entfernen
func _end_turn_and_free() -> void:
	if turn_finished:
		return
	turn_finished = true
	print(">>> Projectile ended turn, unlocking")
	TurnManager.unlock_turn()  # unlock_turn macht auch switch_turn()
	queue_free()

# Kollisionsabfrage
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Terrain"):
		if terrain_node:
			terrain_node.emit_signal("carve_requested", terrain_node.to_local(global_position), 50.0)
		_end_turn_and_free()
		return
	
	if body.is_in_group("Players"):
		var player_id = body.player_id
		var player = TurnManager.get_player(player_id)
		if player:
			var damage_amount = calculate_damage()
			player.damage(damage_amount)
		_end_turn_and_free()
		return

# Projektil endgültig verschwunden (Sicherheitsleine)
func _exit_tree() -> void:
	if not turn_finished:
		TurnManager.unlock_turn()
		turn_finished = true
