extends Control

# Vorrausgesetzt: Du hast vier TextureRects mit den Namen "KeyW", "KeyA", "KeyS" und "KeyD"
# und einen AnimationPlayer mit passenden Animationen eingerichtet.

func _input(event):
	if event is InputEventKey:
		# Key Press
		if event.pressed:
			match event.keycode:
				KEY_W:
					$VBoxContainer/Keyboard_W/WKeyAnimation.play("w_pressed")
				KEY_A:
					$VBoxContainer/Keyboard_A/AKeyAnimation.play("a_pressed")
				KEY_S:
					$VBoxContainer/Keyboard_S/SKeyAnimation.play("s_pressed")
				KEY_D:
					$VBoxContainer/Keyboard_D/DKeyAnimation.play("d_pressed")
				KEY_F1:
					$VBoxContainer/Keyboard_F1/F1KeyAnimation.play("f1_pressed")
					$".".visible = !$".".visible
				KEY_CTRL:
					$VBoxContainer/Keyboard_CTRL/CTRLKeyAnimation.play("ctrl_pressed")
				KEY_SPACE:
					$VBoxContainer/Keyboard_Space/SpaceKeyAnimation.play("space_pressed")
		else:
			match event.keycode:
				KEY_W:
					$VBoxContainer/Keyboard_W/WKeyAnimation.play("w_released")
				KEY_A:
					$VBoxContainer/Keyboard_A/AKeyAnimation.play("a_released")
				KEY_S:
					$VBoxContainer/Keyboard_S/SKeyAnimation.play("s_released")
				KEY_D:
					$VBoxContainer/Keyboard_D/DKeyAnimation.play("d_released")
				KEY_F1:
					$VBoxContainer/Keyboard_F1/F1KeyAnimation.play("f1_released")
				KEY_CTRL:
					$VBoxContainer/Keyboard_CTRL/CTRLKeyAnimation.play("ctrl_released")
				KEY_SPACE:
					$VBoxContainer/Keyboard_Space/SpaceKeyAnimation.play("space_released")
