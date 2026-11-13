
extends RichTextEffect
class_name FadeCharacter

var bbcode: String = "fadein"
var fade_out: bool = false

var velocidad: float = 5.0
var retraso_caracter: float = 0.035

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var retraso: float = float(char_fx.relative_index) * retraso_caracter
	var progreso: float = clampf((char_fx.elapsed_time - retraso) * velocidad, 0.0, 1.0)

	if fade_out:
		progreso = 1.0 - progreso

	char_fx.color.a *= progreso

	return true
