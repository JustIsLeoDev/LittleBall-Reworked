
extends CanvasLayer
@onready var language_selector: OptionButton = $OptionButton
const CONFIG_PATH: String = "user://settings.cfg"
const DEFAULT_VOLUME: float = 100.0

@onready var music_slider: HSlider = $Control/VBoxContainer/Music
@onready var sfx_slider: HSlider = $Control/VBoxContainer/Sfx

var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var settings: ConfigFile = ConfigFile.new()
var loading_config: bool = false


func _ready() -> void:
	language_selector.select(Global.indice_lan)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	load_config()

	loading_config = true
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume
	loading_config = false

	apply_audio_config()


func load_config() -> void:
	var error: Error = settings.load(CONFIG_PATH)

	if error != OK:
		music_volume = DEFAULT_VOLUME
		sfx_volume = DEFAULT_VOLUME
		return

	music_volume = clampf(
		settings.get_value("audio", "music_volume", DEFAULT_VOLUME),
		0.0,
		100.0
	)

	sfx_volume = clampf(
		settings.get_value("audio", "sfx_volume", DEFAULT_VOLUME),
		0.0,
		100.0
	)


func save_config() -> void:
	settings.set_value("audio", "music_volume", music_volume)
	settings.set_value("audio", "sfx_volume", sfx_volume)

	var error: Error = settings.save(CONFIG_PATH)

	if error != OK:
		push_error("No se pudo guardar la configuración de audio.")


func apply_audio_config() -> void:
	apply_bus_volume("Music", music_volume)
	apply_bus_volume("SFX", sfx_volume)


func apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)

	if bus_index < 0:
		push_error("No se encontró el bus: " + bus_name)
		return

	var volume_db: float = -80.0

	if value > 0.0:
		volume_db = linear_to_db(value / 100.0) + 7.0

	AudioServer.set_bus_volume_db(bus_index, volume_db)


func _on_resume_pressed() -> void:
	toggle_pause()


func _on_quit_pressed() -> void:
	Global.pause = false
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	Points._cancel_level()


func toggle_pause() -> void:
	if not Global.can_pause:
		return
	Global.pause = not Global.pause
	get_tree().paused = Global.pause
	visible = Global.pause


func _on_music_value_changed(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	apply_bus_volume("Music", music_volume)

	if not loading_config:
		save_config()


func _on_sfx_value_changed(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 100.0)
	apply_bus_volume("SFX", sfx_volume)

	if not loading_config:
		save_config()


func _on_option_button_item_selected(index: int) -> void:
	Global.language_item_sel(index)
	pass # Replace with function body.
func is_music_muted() -> bool:
	return music_volume <= 0.0
