extends CanvasLayer

# Funktion, um die Waffe zu aktualisieren (vom Player aufgerufen)
func update_weapon(name: String, icon: Texture) -> void:
	$WeaponUI/Label.text = name
	$WeaponUI/Icon.texture = icon
	
	$WeaponUI/Icon.custom_minimum_size = Vector2(150, 150) # Größe von der Projektilen 
