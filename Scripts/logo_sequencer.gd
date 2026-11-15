
extends Control

@export var logo_textures: Array[Texture2D] = [
	preload("res://Sprites/logo/1000081652-Photoroom.png"),
	preload("res://Sprites/littleball2 - copia.png"),
]

@export_file("*.tscn") var target_scene: String = "res://Scenes/menu.tscn"

# Margen de seguridad para el logo
@export var screen_margin: float = 64.0

@onready var texture_rect: TextureRect = $TextureRect

var current_index: int = 0
var current_tween: Tween = null
var intro_finished: bool = false


func _ready() -> void:
	Global.can_pause = false
	Global.can_reset = false
	assert(texture_rect != null, "¡Falta el nodo TextureRect hijo!")

	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	texture_rect.offset_left = screen_margin
	texture_rect.offset_top = screen_margin
	texture_rect.offset_right = -screen_margin
	texture_rect.offset_bottom = -screen_margin

	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	texture_rect.modulate.a = 0.0

	_play_next_logo()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not intro_finished:
			_skip_intro()


func _play_next_logo() -> void:
	if intro_finished:
		return

	if current_index >= logo_textures.size():
		_finish_sequence()
		return

	texture_rect.texture = logo_textures[current_index]

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = create_tween()

	current_tween.tween_property(texture_rect, "modulate:a", 1.0, 1.0)
	current_tween.tween_interval(3.0)
	current_tween.tween_property(texture_rect, "modulate:a", 0.0, 1.0)

	current_tween.finished.connect(func():
		if intro_finished:
			return

		current_index += 1
		_play_next_logo()
	)


func _skip_intro() -> void:
	if intro_finished:
		return

	intro_finished = true

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	_change_to_menu()


func _finish_sequence() -> void:
	if intro_finished:
		return

	intro_finished = true

	await get_tree().create_timer(0.7).timeout

	_change_to_menu()


func _change_to_menu() -> void:
	Transition.change_scene(target_scene)
