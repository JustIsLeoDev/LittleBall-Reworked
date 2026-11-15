
extends Node
var indice_lan: int = 0
var levels: Array[String] = []
var level_stats: Dictionary = {}

var actual_level: String = ""

var music_bypass: bool = false

var levels_path: String = ""
const CONFIG_PATH: String = "user://config.cfg"

var actual_player = 0

func save_levels() -> void:
	var data: Dictionary = {
		"levels": levels,
		"level_stats": level_stats
	}

	var file: FileAccess = FileAccess.open(levels_path, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_levels() -> void:
	if not FileAccess.file_exists(levels_path):
		save_levels()
		return

	var file: FileAccess = FileAccess.open(levels_path, FileAccess.READ)

	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()

		if parsed is Dictionary:
			levels.assign(parsed.get("levels", []))
			level_stats = parsed.get("level_stats", {})


func finish_level(points: int, time: float) -> bool:
	if actual_level.is_empty():
		return false

	if not levels.has(actual_level):
		levels.append(actual_level)

	var new_stats: Dictionary = {
		"points": points,
		"time": time
	}

	if compare_level_stats(points, time):
		level_stats[actual_level] = new_stats
		save_levels()
		return true

	return false


func compare_level_stats(new_points: int, new_time: float) -> bool:
	if not level_stats.has(actual_level):
		return true

	var old_stats: Dictionary = level_stats[actual_level]
	var old_points: int = int(old_stats.get("points", 0))
	var old_time: float = float(old_stats.get("time", INF))

	if new_points > old_points:
		return true

	if new_points < old_points:
		return false

	return new_time < old_time


var Target_level = null
var stageact: int = 0
var muertes: int = 0
var debug: bool = true
var version: String = "1.1.0"
var is_online: bool = false
var can_reset: bool = true
var can_pause: bool = true
var pause: bool = false
var nickson: String = "JustIsLeonardoIsr"


func _ready() -> void:
	load_levels()
	load_config()


func language_item_sel(_index: int) -> void:
	indice_lan = _index

	match _index:
		0:
			set_language("es")
			PM.info_print("Idioma español")

		1:
			set_language("en")
			PM.info_print("Idioma inglés")


func set_language(nuevo_idioma: String) -> void:
	if nuevo_idioma != "es" and nuevo_idioma != "en":
		return

	TranslationServer.set_locale(nuevo_idioma)

	var config: ConfigFile = ConfigFile.new()
	var error_carga: Error = config.load(CONFIG_PATH)

	if error_carga != OK and error_carga != ERR_FILE_NOT_FOUND:
		PM.error_print("No se pudo cargar la configuración.")
		return

	config.set_value("general", "idioma", nuevo_idioma)
	config.set_value("general", "indice_lan", indice_lan)

	var error_guardado: Error = config.save(CONFIG_PATH)

	if error_guardado != OK:
		PM.error_print("No se pudo guardar el idioma.")


func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error_carga: Error = config.load(CONFIG_PATH)

	if error_carga == OK:
		var idioma_guardado: String = config.get_value(
			"general",
			"idioma",
			"es"
		)

		indice_lan = int(config.get_value("general", "indice_lan", 0))

		if indice_lan < 0 or indice_lan > 1:
			indice_lan = 0

		if idioma_guardado == "es" or idioma_guardado == "en":
			TranslationServer.set_locale(idioma_guardado)
		else:
			TranslationServer.set_locale("es")
			indice_lan = 0
	else:
		TranslationServer.set_locale("es")
		indice_lan = 0

var player_sprite_texture: Texture2D = preload("res://Sprites/145_sin_titulo_0000-06-39_20261022191242.png")
var player_outline_texture: Texture2D = preload("res://Sprites/Bola.png")
var player_sprite_rotation: float = 0.0

var player_squash_stretch_enabled: bool = true
var player_fall_scale: Vector2 = Vector2(0.88, 1.12)
var player_jump_scale: Vector2 = Vector2(0.82, 1.18)
var player_jump_squash_scale: Vector2 = Vector2(1.25, 0.75)
var player_dash_scale: Vector2 = Vector2(1.30, 0.70)
var player_landing_scale: Vector2 = Vector2(1.35, 0.65)

var player_squash_speed: float = 5.0
var player_jump_stretch_speed: float = 4.0
var player_jump_squash_speed: float = 8.0
var player_landing_recovery_speed: float = 2.0
var player_dash_squash_speed: float = 8.0

var player_jump_squash_duration: float = 0.12
var player_landing_duration: float = 0.35
var player_landing_velocity_scale: float = 0.0005
var player_max_landing_squash: float = 1.5

# Trail
var player_rainbow_trail: bool = true
var player_rainbow_speed: float = 0.5
var player_target_scale: float = 64.0
var player_trail_enabled: bool = true
var is_in_level = false
var dificulty = "facil" #masoquista, facil, normal, dificil
var player_trail_type: int = 1
var player_trail_style: int = 0
var level_text
var player_trail_length: int = 20
var player_trail_spacing: float = 20.0
var player_trail_min_alpha: float = 0.0
var player_trail_min_scale: float = 0.35
var player_trail_width: float = 12.0
var player_trail_color: Color = Color(0.0, 1.0, 0.2)
var player_trail_texture: Texture2D = null
var player_trail_round_caps: bool = true






# [titulo, ruta_audio, album, bpm, rotable]
var datos_canciones: Array[Array] = [
	["Bolita", "res://Music/Bolita.ogg", "", 185.0, true],
	["Genesis", "res://Music/Genesis.ogg", "", 60.0, true],
	["Hero motiv", "res://Music/Hero motiv.ogg", "", 60.0, true],
	["LittleBall stage 6", "res://Music/LittleBall stage 6.ogg", "", 165.0, true],
	["S13", "res://Music/S13.ogg", "", 185.0, true],
	["S13(S20)", "res://Music/S13(S20).ogg", "", 185.0, true],
	["S3_1", "res://Music/S3_1.ogg", "", 165.0, true],
	["S67", "res://Music/S67.ogg", "", 185.0, true],
	["Stage 5", "res://Music/Stage 5.ogg", "", 185.0, true],
	["Stage 5 reverb", "res://Music/Stage 5 reverb.ogg", "", 185.0, true],
	["Sya me canse de ahcer canciones para la bolita", "res://Music/Sya me canse de ahcer canciones para la bolita.ogg", "", 185.0, true],
	["Tone1", "res://Music/Tone1.ogg", "", 175.0, true],
	["bolita 2", "res://Music/bolita 2.ogg", "", 185.0, true],
	["cancion jefe final bolita meme canela miedo", "res://Music/cancion jefe final bolita meme canela miedo.ogg", "", 185.0, true],
	["jkhglig", "res://Music/jkhglig.ogg", "", 185.0, true],
	["littleball", "res://Music/littleball.ogg", "", 185.0, true],
	["littleball2", "res://Music/littleball2.ogg", "", 185.0, true],
	["no que no", "res://Music/no que no.ogg", "", 165.0, true],
	["pe causa", "res://Music/pe causa.ogg", "", 10000.0, true],
	["pongase pilas mijo", "res://Music/pongase pilas mijo.ogg", "", 120.0, true],
	["s11", "res://Music/s11.ogg", "", 185.0, true],
	["La cancion que más odio", "res://Music/s112.ogg", "", 185.0, true],
	["s1222", "res://Music/s1222.ogg", "", 165.0, true],
	["silent", "res://Music/silent.ogg", "", 185.0, true],
	["stage 7", "res://Music/stage 7.ogg", "", 185.0, true],
	["Genesis 2", "res://Music/genesis2.ogg", "", 64, true]
]




func get_levels_path() -> String:
	var appdata: String = OS.get_environment("LOCALAPPDATA")
	var folder: String = appdata.path_join("LittleBallFunc/logs")

	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)

	return folder.path_join("levels.json")
