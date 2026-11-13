
extends CanvasLayer

var fade: ColorRect
var transitioning: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0

	add_child(fade)

func change_scene(path: String) -> void:
	if transitioning:
		return

	transitioning = true
	get_tree().paused = true

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "modulate:a", 0.5, 0.25)
	await tween.finished
	if not Global.pause:
		get_tree().paused = false

	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "modulate:a", 0.0, 0.25)
	await tween.finished

	transitioning = false
