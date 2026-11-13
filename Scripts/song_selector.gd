
extends Control

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var song_list: VBoxContainer = $CanvasLayer/Panel/ScrollContainer/VBoxContainer
@onready var bypass_button: CheckButton = $CanvasLayer/Panel/MusicBypass

func _ready() -> void:
	canvas_layer.visible = false
	bypass_button.button_pressed = Global.music_bypass
	_actualizar_bypass()
	_cargar_lista_canciones()


func _cargar_lista_canciones() -> void:
	for datos: Array in Global.datos_canciones:
		if datos.size() < 5:
			PM.error_print("Datos incompletos en una canción")
			continue

		var titulo: String = str(datos[0])
		var ruta: String = str(datos[1])
		var bpm: float = float(datos[3])

		var boton: Button = Button.new()
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.text = titulo + " | " + str(bpm) + " BPM"
		boton.custom_minimum_size = Vector2(0, 50)

		boton.pressed.connect(_on_song_pressed.bind(ruta))

		song_list.add_child(boton)


func _on_song_pressed(ruta: String) -> void:
	MusicManager.try_play_music_por_ruta(ruta, true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("TAB"):
		if Global.debug:
			canvas_layer.visible = not canvas_layer.visible


func _on_music_bypass_pressed() -> void:
	Global.music_bypass = bypass_button.button_pressed
	_actualizar_bypass()


func _actualizar_bypass() -> void:
	bypass_button.text = "Music Bypass: " + str(Global.music_bypass)
