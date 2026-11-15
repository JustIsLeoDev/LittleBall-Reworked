
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


func change_scene(path: String, initial_state: int = -1) -> void:
	if transitioning:
		PM.comment_print("[TRANSITION] ERROR: Ya existe una transición")
		return

	transitioning = true
	PM.comment_print("[TRANSITION] Pausando árbol")

	get_tree().paused = true

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished

	PM.comment_print("[TRANSITION] Cargando: " + path)

	var error: Error = get_tree().change_scene_to_file(path)

	if error != OK:
		PM.error_print("[TRANSITION] Error cargando escena: " + str(error))
		get_tree().paused = false
		transitioning = false
		return

	await get_tree().scene_changed

	if initial_state != -1:
		var scene_transition: Node = get_tree().get_first_node_in_group("scene_transition")

		if is_instance_valid(scene_transition):
			scene_transition.set_state(initial_state)

	PM.comment_print("[TRANSITION] Nueva escena cargada")

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
	PM.comment_print("[TRANSITION] Transición finalizada")
