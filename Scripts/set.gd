
extends Node2D

var fullscreen: bool = false
var lowpass: bool = false
var last_lowpass: bool = false

var effect: AudioEffectLowPassFilter
var filter_tween: Tween

var music_bus: int = -1
var effect_index: int = -1
var audit_timer: float = 0.0
var last_audited_cutoff: float = -1.0
var previous_global_pause: bool = false
var previous_tree_paused: bool = false
var previous_scene_path: String = ""
var previous_player_id: int = 0
var lowpass_request_count: int = 0
var focus_out_count: int = 0
var focus_in_count: int = 0

const CONFIG_PATH: String = "user://settings.cfg"
const DEFAULT_VOLUME: float = 100.0

@export var filter_time: float = 1.0
@export var lowpass_debug: bool = false
@export var audit_interval: float = 0.5


func _ready() -> void:
	#get_tree().debug_collisions_hint = true

	previous_global_pause = Global.pause
	previous_tree_paused = get_tree().paused

	if get_tree().current_scene:
		previous_scene_path = get_tree().current_scene.scene_file_path

	_log_lowpass("INIT", "Inicializando monitor de lowpass.")
	_log_lowpass("INIT", "Escena: %s" % previous_scene_path)
	_log_lowpass("INIT", "Global.pause: %s" % str(Global.pause))
	_log_lowpass("INIT", "SceneTree.paused: %s" % str(get_tree().paused))
	_log_lowpass("INIT", "Logs: %s (F6 para cambiar)" % str(lowpass_debug))

	music_bus = AudioServer.get_bus_index("Music")

	if music_bus < 0:
		_log_lowpass("ERROR", "No existe el bus Music.")
	else:
		_log_lowpass("INIT", "Bus Music: %d" % music_bus)

		var effect_count: int = AudioServer.get_bus_effect_count(music_bus)
		_log_lowpass("INIT", "Efectos en Music: %d" % effect_count)

		for i: int in range(effect_count):
			var bus_effect: AudioEffect = AudioServer.get_bus_effect(music_bus, i)

			_log_lowpass(
				"INIT",
				"Efecto %d: %s, habilitado=%s"
				% [
					i,
					bus_effect.get_class(),
					str(AudioServer.is_bus_effect_enabled(music_bus, i))
				]
			)

			if bus_effect is AudioEffectLowPassFilter:
				effect = bus_effect as AudioEffectLowPassFilter
				effect_index = i
				break

	if effect:
		effect.cutoff_hz = 20000.0
		last_audited_cutoff = effect.cutoff_hz
		_log_lowpass("INIT", "Lowpass encontrado.")
	else:
		_log_lowpass("ERROR", "No se encontró AudioEffectLowPassFilter en Music.")

	var sets_nodes: Array[Node] = get_tree().get_nodes_in_group("sets")

	_log_lowpass("INIT", "Nodos en grupo sets: %d" % sets_nodes.size())

	if sets_nodes.size() > 1:
		_log_lowpass("WARNING", "Hay varias instancias en el grupo sets.")

		for node: Node in sets_nodes:
			_log_lowpass("INIT", "sets: %s | ID=%d" % [str(node.get_path()), node.get_instance_id()])

	add_to_group("sets")

	load_window_mode()
	load_audio_settings()

	_log_lowpass("INIT", "Monitor inicializado.")


# --------------------------------------------------
# CONFIGURACIÓN DE VENTANA
# --------------------------------------------------

func save_window_mode() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value("Display", "fullscreen", fullscreen)

	var error: Error = config.save(CONFIG_PATH)

	if error != OK:
		PM.error_print("[DISPLAY] No se pudo guardar la configuración: %s" % error_string(error))


func load_window_mode() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(CONFIG_PATH)

	if error == OK:
		fullscreen = config.get_value("Display", "fullscreen", false)
	else:
		fullscreen = false

	set_window_mode()


func set_window_mode() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(640, 480))

		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_size: Vector2i = Vector2i(640, 480)

		var position_x: int = (screen_size.x - window_size.x) / 2
		var position_y: int = (screen_size.y - window_size.y) / 2

		DisplayServer.window_set_position(Vector2i(position_x, position_y))


# --------------------------------------------------
# CONFIGURACIÓN DE AUDIO
# Compatible con PauseMenu
# --------------------------------------------------

func load_audio_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(CONFIG_PATH)

	var music_volume: float = DEFAULT_VOLUME
	var sfx_volume: float = DEFAULT_VOLUME

	if error == OK:
		music_volume = clampf(
			config.get_value("audio", "music_volume", DEFAULT_VOLUME),
			0.0,
			100.0
		)

		sfx_volume = clampf(
			config.get_value("audio", "sfx_volume", DEFAULT_VOLUME),
			0.0,
			100.0
		)

	apply_bus_volume("Music", music_volume)
	apply_bus_volume("SFX", sfx_volume)


func apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)

	if bus_index < 0:
		_log_lowpass("ERROR", "No se encontró el bus: " + bus_name)
		return

	var volume_db: float = -80.0

	if value > 0.0:
		volume_db = linear_to_db(value / 100.0) + 5.0

	AudioServer.set_bus_volume_db(bus_index, volume_db)


# --------------------------------------------------
# DEPURACIÓN LOWPASS
# --------------------------------------------------

func _log_lowpass(category: String, message: String) -> void:
	if not lowpass_debug:
		return

	var formatted: String = "[LOWPASS][%s] %s" % [category, message]

	match category:
		"ERROR":
			PM.error_print(formatted)
		"WARNING":
			PM.warning_print(formatted)
		"INIT", "TWEEN":
			PM.info_print(formatted)
		"REQUEST", "STACK", "AUDIT", "STATE", "FOCUS", "SCENE", "PAUSE", "INPUT":
			PM.normal_print(formatted)
		_:
			PM.normal_print(formatted)


func _toggle_lowpass_logs() -> void:
	lowpass_debug = not lowpass_debug

	var message: String = "Logs de lowpass %s." % ("ACTIVADOS" if lowpass_debug else "DESACTIVADOS")

	if lowpass_debug:
		PM.satisfactory_print("[LOWPASS][LOGS] " + message)
		_log_lowpass("INIT", "Escena: %s" % str(get_tree().current_scene.scene_file_path) if get_tree().current_scene else "Escena: null")
		_log_lowpass("INIT", "Global.pause=%s | tree.paused=%s | lowpass=%s | last_lowpass=%s" % [str(Global.pause), str(get_tree().paused), str(lowpass), str(last_lowpass)])
		_log_lowpass("INIT", "Solicitudes=%d | focus out=%d | focus in=%d" % [lowpass_request_count, focus_out_count, focus_in_count])
	else:
		PM.info_print("[LOWPASS][LOGS] " + message)


func set_lowpass(cutoff: float) -> void:
	lowpass_request_count += 1

	_log_lowpass(
		"REQUEST",
		"#%d set_lowpass(%.1f Hz) | Global.pause=%s | lowpass=%s | tree.paused=%s | escena=%s"
		% [
			lowpass_request_count,
			cutoff,
			str(Global.pause),
			str(lowpass),
			str(get_tree().paused),
			str(get_tree().current_scene.scene_file_path) if get_tree().current_scene else "null"
		]
	)

	if lowpass_debug:
		_log_lowpass("STACK", "Pila de llamadas: %s" % str(get_stack()))

	if not effect:
		_log_lowpass("ERROR", "Solicitud ignorada: el efecto es null.")
		return

	if filter_tween and filter_tween.is_running():
		_log_lowpass("TWEEN", "Cancelando tween anterior. Cutoff actual=%.1f Hz" % effect.cutoff_hz)
		filter_tween.kill()

	filter_tween = create_tween()
	filter_tween.set_trans(Tween.TRANS_SINE)
	filter_tween.set_ease(Tween.EASE_IN_OUT)

	filter_tween.tween_property(effect, "cutoff_hz", cutoff, filter_time)

	_log_lowpass(
		"TWEEN",
		"Inicio: %.1f -> %.1f Hz | duración=%.2f s"
		% [effect.cutoff_hz, cutoff, filter_time]
	)

	filter_tween.finished.connect(_on_lowpass_tween_finished.bind(cutoff))


func _on_lowpass_tween_finished(target_cutoff: float) -> void:
	if not effect:
		return

	last_audited_cutoff = effect.cutoff_hz

	_log_lowpass(
		"TWEEN",
		"Finalizado. Objetivo=%.1f Hz | real=%.1f Hz | Global.pause=%s | lowpass=%s"
		% [target_cutoff, effect.cutoff_hz, str(Global.pause), str(lowpass)]
	)


func _audit_lowpass(delta: float) -> void:
	if not effect:
		return

	audit_timer += delta

	if audit_timer < audit_interval:
		return

	audit_timer = 0.0

	var current_cutoff: float = effect.cutoff_hz

	if filter_tween and filter_tween.is_running():
		return

	if not is_equal_approx(current_cutoff, last_audited_cutoff):
		_log_lowpass(
			"WARNING",
			"El cutoff cambió fuera de un tween registrado. Anterior=%.1f Hz | actual=%.1f Hz"
			% [last_audited_cutoff, current_cutoff]
		)

		last_audited_cutoff = current_cutoff


func _audit_state() -> void:
	if Global.pause != previous_global_pause:
		_log_lowpass(
			"PAUSE",
			"Global.pause cambió: %s -> %s | tree.paused=%s | lowpass=%s | escena=%s"
			% [
				str(previous_global_pause),
				str(Global.pause),
				str(get_tree().paused),
				str(lowpass),
				str(get_tree().current_scene.scene_file_path) if get_tree().current_scene else "null"
			]
		)

		previous_global_pause = Global.pause

	if get_tree().paused != previous_tree_paused:
		_log_lowpass(
			"PAUSE",
			"SceneTree.paused cambió: %s -> %s | Global.pause=%s"
			% [str(previous_tree_paused), str(get_tree().paused), str(Global.pause)]
		)

		previous_tree_paused = get_tree().paused

	if get_tree().current_scene:
		var scene_path: String = get_tree().current_scene.scene_file_path

		if scene_path != previous_scene_path:
			_log_lowpass(
				"SCENE",
				"Cambio de escena: %s -> %s | Global.pause=%s | lowpass=%s"
				% [previous_scene_path, scene_path, str(Global.pause), str(lowpass)]
			)

			previous_scene_path = scene_path

	var player: Node = get_tree().get_first_node_in_group("Player")
	var player_id: int = player.get_instance_id() if player else 0

	if player_id != previous_player_id:
		_log_lowpass(
			"STATE",
			"Player del grupo cambió: ID %d -> %d"
			% [previous_player_id, player_id]
		)

		previous_player_id = player_id


# --------------------------------------------------
# INPUT
# --------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		_toggle_lowpass_logs()
		return

	if event.is_action_released("F4"):
		fullscreen = not fullscreen
		set_window_mode()
		save_window_mode()

	if event.is_action_pressed("Pause") and Global.can_pause:
		_log_lowpass("INPUT", "Acción Pause recibida. Global.pause=%s" % str(Global.pause))
		PauseMenu.toggle_pause()
		_log_lowpass("INPUT", "PauseMenu.toggle_pause() ejecutado.")

	if Global.debug:
		if event.is_action_pressed("Reiniciar"):
			if Global.can_reset:
				var is_transition_scene: bool = false

				if is_instance_valid(get_tree().current_scene):
					is_transition_scene = get_tree().current_scene.scene_file_path == "res://Scenes/test_dream_transition.tscn"

				if is_transition_scene:
					var transition: Node = get_tree().get_first_node_in_group("scene_transition")

					if is_instance_valid(transition):
						if transition.Actual_room == 1:
							return

				Points._reset_key()

				get_tree().reload_current_scene()

				if is_transition_scene:
					await get_tree().scene_changed

					var transition: Node = get_tree().get_first_node_in_group("scene_transition")

					if is_instance_valid(transition):
						transition.set_state(transition.STATE.AFTER_TRANSITION)

				if Global.dificulty == "masoquista":
					Global.muertes += 1
					return

				Points._start_timer()

		if event.is_action_pressed("0"):
			MusicManager.try_play_music(MusicManager.s10)

		if event.is_action_pressed("F5"):
			Global.save_levels()

		if event.is_action_pressed("supr"):
			Points._toggle_visible()

		if event.is_action_pressed("inicio"):
			Points._start_timer()

		if event.is_action_pressed("fin"):
			Points._stop_timer()

		if event.is_action_pressed("avpag"):
			Points._end_level()

		if event.is_action_pressed("drug") and not event.is_echo():
			DrugManager.toggle_drug()

			var cam: Node = get_tree().get_first_node_in_group("Cam")
			var fog: Node = get_tree().get_first_node_in_group("FOG")
			var enabled: bool = DrugManager.target_intensity > 0.0

			DrugManager.minimum_pitch = 0.99
			DrugManager.wobble_amount = 0.003
			DrugManager.wobble_speed = 0.2

			if cam:
				cam.drunk_enabled = enabled

			if fog:
				fog.visible = enabled


# --------------------------------------------------
# NOTIFICACIONES
# --------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		lowpass = true
		focus_out_count += 1

		_log_lowpass(
			"FOCUS",
			"FOCUS_OUT #%d | Global.pause=%s | tree.paused=%s"
			% [focus_out_count, str(Global.pause), str(get_tree().paused)]
		)

	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		lowpass = false
		focus_in_count += 1

		_log_lowpass(
			"FOCUS",
			"FOCUS_IN #%d | Global.pause=%s | tree.paused=%s"
			% [focus_in_count, str(Global.pause), str(get_tree().paused)]
		)


# --------------------------------------------------
# PROCESS
# --------------------------------------------------

func _process(delta: float) -> void:
	_audit_state()

	var new_lowpass: bool = Global.pause or lowpass

	if new_lowpass != last_lowpass:
		_log_lowpass(
			"STATE",
			"Estado lowpass: %s -> %s | Global.pause=%s | foco_perdido=%s"
			% [str(last_lowpass), str(new_lowpass), str(Global.pause), str(lowpass)]
		)

		last_lowpass = new_lowpass

		if new_lowpass:
			set_lowpass(500.0)
		else:
			set_lowpass(21000.0)

	_audit_lowpass(delta)

	var player: Player = get_tree().get_first_node_in_group("Player") as Player

	if player == null:
		$CanvasLayer/Control/Label2.text = "Velocidad: 0.0 km/h"
		return

	var velocidad: float = player.velocity.length() * 0.036
	$CanvasLayer/Control/Label2.text = "Velocidad: %.1f km/h" % velocidad
