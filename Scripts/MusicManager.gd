
extends Node

@onready var music_player_1: AudioStreamPlayer = $"Player 1"
@onready var music_player_2: AudioStreamPlayer = $"Player 2"
@onready var Album_texture: TextureRect = $CanvasLayer/Control/TextureRect
@onready var RichText: RichTextLabel = $CanvasLayer/Control/RichTextLabel

var settings: ConfigFile = ConfigFile.new()

var canciones: Array[AudioStream] = []
var nombres_canciones: Array[String] = []
var rutas_canciones: Array[String] = []
var rutas_por_cancion: Dictionary = {}

var album_saliendo: bool = false
var album_en_pantalla: bool = false

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

# Animación de salida del álbum.
@export_group("Animación de salida")

@export var tiempo_frenazo: float = 0.6
@export var angulo_frenazo: float = 15.0
@export var ciclos_frenazo: float = 2.0

@export var tiempo_impulso: float = 1.0
@export var angulo_impulso: float = 50.0
@export var intensidad_temblor: float = 2.0
@export var frecuencia_temblor: float = 12.0

@export var tiempo_regreso: float = 0.8

@export var tiempo_estabilizacion: float = 0.35
@export var angulo_estabilizacion: float = 2.0

@export var tiempo_bajada: float = 0.8

@export_group("Texto")

@export var texto_velocidad: float = 5.0
@export var texto_retraso: float = 0.035
@export var texto_duracion: float = 3.5

var album_offset_top: float = -40.0
var album_offset_bottom: float = 0.0

var album_rotando: bool = false
var album_actual: String = ""
var bpm_actual: float = 120.0

# Datos que conservamos para recuperar el álbum al quitar el mute.
var ultimo_titulo: String = ""
var ultimo_album_path: String = ""
var ultimo_album_rotable: bool = true
var album_configurado: bool = false

# Evita ejecutar la transición repetidamente.
var musica_silenciada: bool = false

var texto_id: int = 0
var texto_actual: String = ""

const VOLUMEN_SILENCIO_DB: float = -40.0


func _ready() -> void:
	_configurar_album()
	_configurar_texto()
	_cargar_musica()
	_comprobar_grupos()

	musica_silenciada = PauseMenu.is_music_muted()

	for player: AudioStreamPlayer in [music_player_1, music_player_2]:
		player.bus = "Music"
		player.volume_db = VOLUMEN_SILENCIO_DB
		player.stop()

	if not music_player_1.finished.is_connected(_on_player_1_finished):
		music_player_1.finished.connect(_on_player_1_finished)

	if not music_player_2.finished.is_connected(_on_player_2_finished):
		music_player_2.finished.connect(_on_player_2_finished)

	PM.info_print("MÚSICA: Señales finished conectadas.")

	player_actual = music_player_1
	player_siguiente = music_player_2

	PM.info_print("REPRODUCTORES: Inicial actual=" + player_actual.name + " | siguiente=" + player_siguiente.name)

	try_play_music_por_ruta("res://Music/s1222.ogg")


func _process(delta: float) -> void:
	# Rotación del álbum.
	if album_rotando and bpm_actual > 0.0 and bpm_referencia > 0.0:
		var velocidad_actual: float = velocidad_rotacion * (bpm_actual / bpm_referencia)
		Album_texture.rotation += velocidad_actual * delta

	# Comprobar el estado del volumen.
	var silenciada: bool = PauseMenu.is_music_muted()

	# No hacer nada si el estado no ha cambiado.
	if silenciada == musica_silenciada:
		return

	musica_silenciada = silenciada

	if silenciada:
		PM.info_print("MÚSICA: Silenciada. Ocultando álbum.")

		_ocultar_texto()

		if album_en_pantalla and not album_saliendo:
			album_salir()

	else:
		PM.info_print("MÚSICA: Volumen restaurado.")

		# Solo recuperar el álbum si todavía hay música reproduciéndose.
		if _hay_musica_reproduciendose() and album_configurado:
			PM.satisfactory_print("ÁLBUM: Recuperando álbum anterior.")

			album_entrar(
				ultimo_album_path,
				ultimo_album_rotable,
				ultimo_titulo
			)


func _hay_musica_reproduciendose() -> bool:
	return music_player_1.playing or music_player_2.playing


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

	PM.info_print("REPRODUCCIÓN: Solicitud: " + nueva_cancion.resource_path)
	PM.info_print("REPRODUCCIÓN: Álbum='" + album_path + "' | Título='" + song_title + "'")

	if not player_actual.playing and player_siguiente.playing:
		PM.info_print("REPRODUCCIÓN: Corrigiendo referencias de reproductores.")
		_intercambiar_reproductores()

	if cambiar_album and not _album_esta_oculto():
		album_salir()

	player_siguiente.stop()
	player_siguiente.stream = nueva_cancion
	player_siguiente.volume_db = VOLUMEN_SILENCIO_DB

	tween_fade = create_tween().set_parallel(true)

	if player_actual.playing:
		var tiempo_actual: float = player_actual.get_playback_position()

		PM.info_print("CROSSFADE: " + player_actual.name + " -> " + player_siguiente.name)
		PM.info_print("CROSSFADE: Nuevo stream=" + nueva_cancion.resource_path + " | posición=" + str(tiempo_actual))

		player_siguiente.play(tiempo_actual)

		PM.satisfactory_print("CROSSFADE: " + player_siguiente.name + " inició. Playing=" + str(player_siguiente.playing))

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
				ultimo_titulo = song_title
				ultimo_album_rotable = rotable
				album_rotando = rotable and bpm_actual > 0.0
				_mostrar_texto(song_title)
		)

	else:
		player_actual.stream = nueva_cancion
		player_actual.volume_db = VOLUMEN_SILENCIO_DB
		player_actual.play()

		PM.satisfactory_print("REPRODUCCIÓN: " + player_actual.name + " inició " + nueva_cancion.resource_path + ". Playing=" + str(player_actual.playing))

		tween_fade.tween_property(
			player_actual,
			"volume_db",
			volumen_maximo_db,
			fade_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if cambiar_album or album_actual == "":
			album_entrar(album_path, rotable, song_title)
		else:
			ultimo_titulo = song_title
			ultimo_album_rotable = rotable
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
	# Guardar siempre los datos del último álbum.
	ultimo_album_path = album_path
	ultimo_album_rotable = rotable
	ultimo_titulo = song_title
	album_configurado = true

	album_actual = album_path

	# Si está muteado, conservar los datos pero no mostrar el álbum.
	if PauseMenu.is_music_muted():
		album_saliendo = false
		album_en_pantalla = false
		album_rotando = false

		if album_tween and album_tween.is_running():
			album_tween.kill()

		Album_texture.offset_top = album_offset_top + distancia_icono
		Album_texture.offset_bottom = album_offset_bottom + distancia_icono

		return

	# Cancelar una posible animación de salida.
	album_saliendo = false

	if album_tween and album_tween.is_running():
		album_tween.kill()

	if album_path != "" and ResourceLoader.exists(album_path):
		var nueva_textura: Texture2D = load(album_path)

		if nueva_textura != null:
			Album_texture.texture = nueva_textura

	album_en_pantalla = true

	PM.satisfactory_print("ÁLBUM: Entrada iniciada. Ruta='" + album_path + "'")

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
	if album_saliendo:
		PM.error_print("ÁLBUM: Ya está saliendo.")
		return

	PM.satisfactory_print("ÁLBUM: Iniciando animación de frenazo.")

	album_saliendo = true
	album_rotando = false

	if album_tween and album_tween.is_running():
		album_tween.kill()

	var rotacion_inicial: float = wrapf(
		Album_texture.rotation,
		-PI,
		PI
	)

	Album_texture.rotation = rotacion_inicial

	var sentido_giro: float = signf(velocidad_rotacion * bpm_actual)

	if is_zero_approx(sentido_giro):
		sentido_giro = 1.0

	album_tween = create_tween()

	# 1. Frenazo.
	album_tween.tween_method(
		Callable(self, "_animar_frenazo").bind(
			rotacion_inicial,
			deg_to_rad(angulo_frenazo)
		),
		0.0,
		tiempo_frenazo,
		tiempo_frenazo
	).set_trans(Tween.TRANS_LINEAR)

	# 2. Impulso.
	var rotacion_impulso: float = (
		rotacion_inicial
		+ sentido_giro * deg_to_rad(angulo_impulso)
	)

	album_tween.tween_method(
		Callable(self, "_animar_impulso").bind(
			rotacion_inicial,
			rotacion_impulso,
			deg_to_rad(intensidad_temblor)
		),
		0.0,
		tiempo_impulso,
		tiempo_impulso
	).set_trans(Tween.TRANS_LINEAR)

	# 3. Regreso.
	album_tween.tween_property(
		Album_texture,
		"rotation",
		0.0,
		tiempo_regreso
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 4. Estabilización.
	album_tween.tween_method(
		Callable(self, "_animar_estabilizacion").bind(
			deg_to_rad(angulo_estabilizacion)
		),
		0.0,
		tiempo_estabilizacion,
		tiempo_estabilizacion
	).set_trans(Tween.TRANS_LINEAR)

	# 5. Bajar el icono.
	album_tween.tween_property(
		Album_texture,
		"offset_top",
		album_offset_top + distancia_icono,
		tiempo_bajada
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	album_tween.parallel().tween_property(
		Album_texture,
		"offset_bottom",
		album_offset_bottom + distancia_icono,
		tiempo_bajada
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# 6. Finalizar.
	album_tween.tween_callback(func() -> void:
		album_saliendo = false
		album_en_pantalla = false

		# IMPORTANTE:
		# No borrar album_actual ni los datos guardados.
		# Se necesitan para recuperar el álbum al quitar el mute.

		PM.satisfactory_print("ÁLBUM: Icono escondido. Salida completada.")
	)


func _animar_frenazo(
	tiempo: float,
	base: float,
	amplitud: float
) -> void:
	var progreso: float = tiempo / maxf(tiempo_frenazo, 0.001)

	var oscilacion: float = sin(
		progreso * TAU * ciclos_frenazo
	)

	var amortiguacion: float = 1.0 - progreso

	Album_texture.rotation = (
		base + oscilacion * amplitud * amortiguacion
	)


func _animar_impulso(
	tiempo: float,
	inicio: float,
	destino: float,
	amplitud: float
) -> void:
	var progreso: float = tiempo / maxf(tiempo_impulso, 0.001)

	var rotacion_base: float = lerpf(
		inicio,
		destino,
		progreso
	)

	var temblor: float = (
		sin(tiempo * TAU * frecuencia_temblor)
		* amplitud
		* sin(progreso * PI)
	)

	Album_texture.rotation = rotacion_base + temblor


func _animar_estabilizacion(
	tiempo: float,
	amplitud: float
) -> void:
	var progreso: float = (
		tiempo / maxf(tiempo_estabilizacion, 0.001)
	)

	var oscilacion: float = sin(
		progreso * TAU * 3.0
	)

	Album_texture.rotation = (
		oscilacion
		* amplitud
		* (1.0 - progreso)
	)


func _ocultar_texto() -> void:
	PM.satisfactory_print("TEXTO: Iniciando desaparición del título: " + texto_actual)

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

		_comprobar_salir_album()
	)


func _intercambiar_reproductores() -> void:
	var temp: AudioStreamPlayer = player_actual
	player_actual = player_siguiente
	player_siguiente = temp

	PM.info_print("REPRODUCTORES: Actual=" + player_actual.name + " | Siguiente=" + player_siguiente.name)


func _comprobar_salir_album() -> void:
	PM.info_print("MÚSICA: Comprobando final de reproducción.")

	_debug_reproductor(music_player_1)
	_debug_reproductor(music_player_2)

	if album_saliendo:
		PM.info_print("MÚSICA: La salida del álbum ya está en curso.")
		return

	if music_player_1.playing or music_player_2.playing:
		PM.info_print("MÚSICA: Otro reproductor continúa activo.")
		return

	if not album_en_pantalla:
		PM.info_print("MÚSICA: No hay un álbum visible que ocultar.")
		return

	PM.satisfactory_print("MÚSICA: Ambos reproductores están detenidos. Cerrando álbum.")

	_ocultar_texto()
	album_salir()


func _on_player_1_finished() -> void:
	PM.satisfactory_print("FINISHED: Player 1 terminó: " + (music_player_1.stream.resource_path if music_player_1.stream != null else "sin stream"))
	_comprobar_salir_album()


func _on_player_2_finished() -> void:
	PM.satisfactory_print("FINISHED: Player 2 terminó: " + (music_player_2.stream.resource_path if music_player_2.stream != null else "sin stream"))
	_comprobar_salir_album()


func _debug_reproductor(player: AudioStreamPlayer) -> void:
	var nombre_stream: String = "Sin stream"
	var duracion: float = 0.0
	var posicion: float = 0.0

	if player.stream != null:
		nombre_stream = player.stream.resource_path
		duracion = player.stream.get_length()
		posicion = player.get_playback_position()

	PM.info_print(
		player.name
		+ " | Playing: " + str(player.playing)
		+ " | Stream: " + nombre_stream
		+ " | Posición: " + str(snappedf(posicion, 0.01))
		+ " / " + str(duracion)
	)
