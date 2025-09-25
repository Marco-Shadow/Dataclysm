# JetpackFlames.gd
extends AnimatedSprite2D

@export var action_name: StringName = "player_jetpack"
@export var animation_name: StringName = "jetpackFlames"
@export var min_upward_speed: float = 1.0

var player: CharacterBody2D

func _ready() -> void:
	player = _find_player()
	visible = false
	if sprite_frames and sprite_frames.has_animation(String(animation_name)):
		animation = String(animation_name)
		frame = 0
		stop()

func _process(_delta: float) -> void:
	if player == null:
		return

	var my_turn: bool = TurnManager.current_player_id == player.player_id
	var active: bool = my_turn \
		and Input.is_action_pressed(action_name) \
		and player.jetpack_active \
		and player.velocity.y < -min_upward_speed

	if active:
		visible = true
		if not is_playing():
			play(String(animation_name))
	else:
		if is_playing():
			stop()
		visible = false
		frame = 0

func _find_player() -> CharacterBody2D:
	var n: Node = get_parent()
	while n:
		if n is CharacterBody2D:
			return n
		n = n.get_parent()
	return null
