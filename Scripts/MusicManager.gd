
extends Node

@onready var music_player_1: AudioStreamPlayer = $"Player 1"
@onready var music_player_2: AudioStreamPlayer = $"Player 2"
@onready var Album_texture: TextureRect = $CanvasLayer/Control/TextureRect
@onready var RichText: RichTextLabel = $CanvasLayer/Control/RichTextLabel

var canciones: Array[AudioStream] = []
var nombres_canciones: Array[String] = []
var rutas_canciones: Array[String] = []
var rutas_por_cancion: Dictionary = {}

var player_actual: AudioStreamPlayer
var player_siguiente: AudioStreamPlayer

var tween_fade: Tween
var album_tween: Tween
var texto_tween: Tween

var efecto_aparecer: FadeCharacter = FadeCharacter.new()
var efecto_desaparecer: FadeCharacter = FadeCharacter.new()

var groups: Array[Array] = []

@export var fade_time: float = 0.5
@export var volumen_maximo_db: float = 0.0
@export var velocidad_rotacion: float = 0.8
@export var bpm_referencia: float = 120.0
@export var distancia_icono: float = 150.0
@export var tiempo_meneo: float = 0.12

@export var texto_velocidad: float = 5.0
@export var texto_retraso: float = 0.035
@export var texto_duracion: float = 3.5

var album_offset_top: float = -40.0
var album_offset_bottom: float = 0.0

var album_rotando: bool = false
var album_actual: String = ""
var bpm_actual: float = 120.0

var texto_id: int = 0
var texto_actual: String = ""

const VOLUMEN_SILENCIO_DB: float = -40.0


func _ready() -> void:
	_configurar_album()
	_configurar_texto()
	_cargar_musica()
	_comprobar_grupos()

	for player: AudioStreamPlayer in [music_player_1, music_player_2]:
		player.bus = "Music"
		player.volume_db = VOLUMEN_SILENCIO_DB
		player.stop()

	player_actual = music_player_1
	player_siguiente = music_player_2

	try_play_music_por_ruta("res://Music/s1222.ogg")


func _process(delta: float) -> void:
	if album_rotando and bpm_actual > 0.0 and bpm_referencia > 0.0:
		var velocidad_actual: float = velocidad_rotacion * (bpm_actual / bpm_referencia)
		Album_texture.rotation += velocidad_actual * delta


func _configurar_album() -> void:
	Album_texture.anchor_left = 0.9
	Album_texture.anchor_top = 0.9
	Album_texture.anchor_right = 0.9
	Album_texture.anchor_bottom = 0.9

	Album_texture.offset_left = -40.0
	Album_texture.offset_top = -40.0
	Album_texture.offset_right = 0.0
	Album_texture.offset_bottom = 0.0

	Album_texture.pivot_offset = Vector2(20.0, 20.0)
	Album_texture.rotation = 0.0

	album_offset_top = Album_texture.offset_top
	album_offset_bottom = Album_texture.offset_bottom

	Album_texture.offset_top += distancia_icono
	Album_texture.offset_bottom += distancia_icono


func _configurar_texto() -> void:
	efecto_aparecer.bbcode = "fadein"
	efecto_aparecer.fade_out = false
	efecto_aparecer.velocidad = texto_velocidad
	efecto_aparecer.retraso_caracter = texto_retraso

	efecto_desaparecer.bbcode = "fadeout"
	efecto_desaparecer.fade_out = true
	efecto_desaparecer.velocidad = texto_velocidad
	efecto_desaparecer.retraso_caracter = texto_retraso

	RichText.install_effect(efecto_aparecer)
	RichText.install_effect(efecto_desaparecer)

	RichText.visible_characters = -1


func _cargar_musica() -> void:
	var dir: DirAccess = DirAccess.open("res://Music")

	if dir == null:
		PM.error_print("No se pudo abrir res://Music")
		return

	dir.list_dir_begin()
	var archivo: String = dir.get_next()

	while archivo != "":
		if not dir.current_is_dir() and archivo.to_lower().ends_with(".ogg"):
			var ruta: String = "res://Music/" + archivo
			var cancion: AudioStream = load(ruta)

			if cancion != null:
				canciones.append(cancion)
				nombres_canciones.append(archivo.get_basename())
				rutas_canciones.append(ruta)
				rutas_por_cancion[cancion] = ruta

		archivo = dir.get_next()

	dir.list_dir_end()
	PM.satisfactory_print("Canciones cargadas: " + str(canciones.size()))


func _comprobar_grupos() -> void:
	for numero_grupo: int in range(groups.size()):
		var grupo: Array = groups[numero_grupo]
		var duracion_mayor: float = 0.0
		var duracion_menor: float = INF
		var audio_mayor: AudioStream = null
		var audio_menor: AudioStream = null

		for audio: AudioStream in grupo:
			if audio == null:
				continue

			var duracion: float = audio.get_length()

			if duracion > duracion_mayor:
				duracion_mayor = duracion
				audio_mayor = audio

			if duracion < duracion_menor:
				duracion_menor = duracion
				audio_menor = audio

		if is_equal_approx(duracion_mayor, duracion_menor):
			PM.satisfactory_print("Grupo " + str(numero_grupo) + ": OK")
		else:
			PM.error_print("Grupo " + str(numero_grupo) + ":")
			PM.error_print("  Más largo: " + str(audio_mayor) + " → " + str(duracion_mayor) + " segundos")
			PM.error_print("  Más corto: " + str(audio_menor) + " → " + str(duracion_menor) + " segundos")


func get_music_path(audio: AudioStream) -> String:
	return str(rutas_por_cancion.get(audio, ""))


func play_music(
	nueva_cancion: AudioStream,
	album_path: String = "",
	rotable: bool = true,
	song_title: String = "PlaceHolder",
	bpm: float = 120.0
) -> void:
	if nueva_cancion == null:
		PM.error_print("No se encontró la canción")
		return

	if player_actual.playing and player_actual.stream == nueva_cancion:
		return

	if player_siguiente.playing and player_siguiente.stream == nueva_cancion:
		return

	bpm_actual = maxf(bpm, 0.0)

	_ocultar_texto()

	if tween_fade and tween_fade.is_running():
		tween_fade.kill()

	var cambiar_album: bool = album_actual != album_path and album_path != ""

	if cambiar_album and not _album_esta_oculto():
		album_salir()

	player_siguiente.stop()
	player_siguiente.stream = nueva_cancion
	player_siguiente.volume_db = VOLUMEN_SILENCIO_DB

	tween_fade = create_tween().set_parallel(true)

	if player_actual.playing:
		var tiempo_actual: float = player_actual.get_playback_position()
		player_siguiente.play(tiempo_actual)

		tween_fade.tween_property(
			player_actual,
			"volume_db",
			VOLUMEN_SILENCIO_DB,
			fade_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		tween_fade.tween_property(
			player_siguiente,
			"volume_db",
			volumen_maximo_db,
			fade_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		tween_fade.chain().tween_callback(func() -> void:
			player_actual.stop()
			_intercambiar_reproductores()

			if cambiar_album:
				album_entrar(album_path, rotable, song_title)
			else:
				album_rotando = rotable and bpm_actual > 0.0
				_mostrar_texto(song_title)
		)
	else:
		player_actual.stream = nueva_cancion
		player_actual.volume_db = VOLUMEN_SILENCIO_DB
		player_actual.play()

		tween_fade.tween_property(
			player_actual,
			"volume_db",
			volumen_maximo_db,
			fade_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if cambiar_album or album_actual == "":
			album_entrar(album_path, rotable, song_title)
		else:
			album_rotando = rotable and bpm_actual > 0.0
			_mostrar_texto(song_title)


func try_play_music(
	nueva_cancion: AudioStream,
	album_path: String = "",
	rotable: bool = true,
	song_title: String = "PlaceHolder",
	bpm: float = 120.0
) -> void:
	if Global.music_bypass:
		return

	play_music(nueva_cancion, album_path, rotable, song_title, bpm)


func try_play_music_por_ruta(ruta: String, desde_player: bool = false) -> void:
	if Global.music_bypass and not desde_player:
		return

	for datos: Array in Global.datos_canciones:
		if datos.size() < 5:
			continue

		if str(datos[1]) == ruta:
			var titulo: String = str(datos[0])
			var album: String = str(datos[2])
			var bpm: float = float(datos[3])
			var rotable: bool = bool(datos[4])
			var cancion: AudioStream = load(ruta)

			if cancion == null:
				PM.error_print("No se pudo cargar: " + ruta)
				return

			play_music(cancion, album, rotable, titulo, bpm)
			return

	PM.error_print("Canción no registrada en Global: " + ruta)


func album_entrar(album_path: String, rotable: bool, song_title: String) -> void:
	if album_tween and album_tween.is_running():
		album_tween.kill()

	if album_path != "" and ResourceLoader.exists(album_path):
		var nueva_textura: Texture2D = load(album_path)

		if nueva_textura != null:
			Album_texture.texture = nueva_textura

	album_actual = album_path
	album_rotando = false
	Album_texture.rotation = 0.0

	Album_texture.offset_top = album_offset_top + distancia_icono
	Album_texture.offset_bottom = album_offset_bottom + distancia_icono

	album_tween = create_tween().set_parallel(true)

	album_tween.tween_property(
		Album_texture,
		"offset_top",
		album_offset_top,
		fade_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	album_tween.tween_property(
		Album_texture,
		"offset_bottom",
		album_offset_bottom,
		fade_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	album_tween.chain().tween_callback(func() -> void:
		album_rotando = rotable and bpm_actual > 0.0
		_mostrar_texto(song_title)
	)


func album_salir() -> void:
	album_rotando = false

	if album_tween and album_tween.is_running():
		album_tween.kill()

	album_tween = create_tween()

	album_tween.tween_property(
		Album_texture,
		"rotation",
		deg_to_rad(12.0),
		tiempo_meneo
	)

	album_tween.tween_property(
		Album_texture,
		"rotation",
		deg_to_rad(-12.0),
		tiempo_meneo
	)

	album_tween.tween_property(
		Album_texture,
		"rotation",
		0.0,
		tiempo_meneo
	)

	album_tween.set_parallel(true)

	album_tween.tween_property(
		Album_texture,
		"offset_top",
		album_offset_top + distancia_icono,
		fade_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	album_tween.tween_property(
		Album_texture,
		"offset_bottom",
		album_offset_bottom + distancia_icono,
		fade_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _ocultar_texto() -> void:
	texto_id += 1
	var id_actual: int = texto_id

	if texto_tween and texto_tween.is_running():
		texto_tween.kill()

	if texto_actual.is_empty():
		RichText.clear()
		return

	texto_tween = create_tween()
	RichText.text = "[fadeout]" + texto_actual + "[/fadeout]"
	RichText.visible_characters = -1

	var cantidad: int = RichText.get_total_character_count()
	var duracion: float = float(cantidad) * texto_retraso + (1.0 / texto_velocidad)

	texto_tween.tween_interval(duracion)

	texto_tween.tween_callback(func() -> void:
		if id_actual != texto_id:
			return

		RichText.clear()
		texto_actual = ""
		texto_tween = null
	)


func _mostrar_texto(titulo: String) -> void:
	texto_id += 1
	var id_actual: int = texto_id

	if texto_tween and texto_tween.is_running():
		texto_tween.kill()

	texto_actual = titulo
	RichText.text = "[fadein]" + titulo + "[/fadein]"
	RichText.visible_characters = -1

	var cantidad: int = RichText.get_total_character_count()
	var duracion: float = float(cantidad) * texto_retraso + (1.0 / texto_velocidad)

	texto_tween = create_tween()
	texto_tween.tween_interval(duracion)
	texto_tween.tween_interval(texto_duracion)

	texto_tween.tween_callback(func() -> void:
		if id_actual != texto_id:
			return

		_ocultar_texto()
	)


func _album_esta_oculto() -> bool:
	return is_equal_approx(
		Album_texture.offset_top,
		album_offset_top + distancia_icono
	)


func stop_music() -> void:
	if tween_fade and tween_fade.is_running():
		tween_fade.kill()

	if album_tween and album_tween.is_running():
		album_tween.kill()

	_ocultar_texto()
	album_rotando = false

	tween_fade = create_tween().set_parallel(true)

	for player: AudioStreamPlayer in [player_actual, player_siguiente]:
		if player.playing:
			tween_fade.tween_property(
				player,
				"volume_db",
				VOLUMEN_SILENCIO_DB,
				fade_time
			)

	tween_fade.chain().tween_callback(func() -> void:
		player_actual.stop()
		player_siguiente.stop()
	)


func _intercambiar_reproductores() -> void:
	var temp: AudioStreamPlayer = player_actual
	player_actual = player_siguiente
	player_siguiente = temp
