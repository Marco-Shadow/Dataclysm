extends Label

var hue: float = 0.0

func _process(delta: float) -> void:
	# Hue-Wert (Farbwinkel) erhöhen
	hue += delta * 0.1   # langsamer Wechsel
	if hue > 1.0:
		hue -= 1.0
	
	# Weniger Sättigung (0.4) und leicht gedimmte Helligkeit (0.8)
	var color = Color.from_hsv(hue, 0.4, 0.8)
	self.modulate = color
