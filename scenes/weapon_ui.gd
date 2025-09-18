extends Control

func update_weapon(name: String, icon: Texture) -> void:
	$WeaponUI/Label.text = name
	$WeaponUI/Icon.texture = icon
