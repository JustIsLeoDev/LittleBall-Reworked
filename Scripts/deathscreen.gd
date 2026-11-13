extends CanvasLayer

@onready var reiniciar_rchtxt: RichTextLabel = $Control2/RichTextLabel2
@onready var muerte_txt: RichTextLabel = $Control2/RichTextLabel

var activo: bool = false
var escribiendo: bool = false
var velocidad: float = 30.0
var caracteres: float = 0.0
var tiempo_espera: float = 0.0

func _ready() -> void:
	reset()

func reset() -> void:
	activo = false
	escribiendo = false
	caracteres = 0.0
	tiempo_espera = 0.0

	visible = false
	muerte_txt.visible = false
	reiniciar_rchtxt.visible = false
	reiniciar_rchtxt.visible_characters = 0

func _toggle() -> void:
	activo = true
	escribiendo = true
	caracteres = 0.0
	tiempo_espera = 1.5

	visible = true
	muerte_txt.visible = true
	reiniciar_rchtxt.visible = true
	reiniciar_rchtxt.visible_characters = 0

func _process(delta: float) -> void:
	if not activo:
		return

	if tiempo_espera > 0.0:
		tiempo_espera -= delta
		return

	if escribiendo:
		caracteres += velocidad * delta
		reiniciar_rchtxt.visible_characters = int(caracteres)

		if reiniciar_rchtxt.visible_characters >= reiniciar_rchtxt.get_total_character_count():
			reiniciar_rchtxt.visible_characters = -1
			escribiendo = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Reiniciar") and activo:
		reset()
		#get_tree().reload_current_scene()
