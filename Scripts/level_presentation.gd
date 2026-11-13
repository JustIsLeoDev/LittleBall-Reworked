
extends CanvasLayer

var level_actual: String = ""
var mostrar_titulo: bool = false
var estado_animacion: int = 0
var posicion_original: float = 0.0
var target_position_y: float = 0.0
var tiempo_visible: float = 0.0

@onready var text: RichTextLabel = $Control/RichTextLabel


func _ready() -> void:
	posicion_original = text.position.y
	target_position_y = posicion_original - 50.0
	level_actual = "nivel nada que ver"
	text.modulate.a = 0.0
	visible = false


func _process(delta: float) -> void:
	if not is_instance_valid(text):
		return

	if level_actual != Global.actual_level:
		level_actual = Global.actual_level
		mostrar_titulo = true
		text.text = str(Global.level_text) if Global.level_text != null else ""
		estado_animacion = 1
		tiempo_visible = 0.0

		visible = true
		text.position.y = posicion_original + 50.0
		text.modulate.a = 1.0

	if not mostrar_titulo:
		return

	match estado_animacion:
		1:
			text.position.y = move_toward(
				text.position.y,
				posicion_original,
				delta * 180.0
			)

			if is_equal_approx(text.position.y, posicion_original):
				estado_animacion = 2

		2:
			tiempo_visible += delta

			if tiempo_visible >= 1.5:
				estado_animacion = 3

		3:
			text.modulate.a = move_toward(
				text.modulate.a,
				0.0,
				delta * 2.0
			)

			if is_zero_approx(text.modulate.a):
				mostrar_titulo = false
				estado_animacion = 0
				visible = false
