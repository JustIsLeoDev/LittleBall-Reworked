extends Area2D

@export var target_room: String = "res://Scenes/test_dream_transition.tscn"
@export var level_fade: float = 1.0

var fuente: FontFile = load("res://fonts/GeistPixel-Regular-VariableFont_ELSH.ttf")
var mostrar_mensaje: bool = false


func _on_body_entered(body: Node2D) -> void:
	PM.comment_print("[TRANSITION] Body entered: " + str(body.name))

	if not body.is_in_group("Player"):
		PM.comment_print("[TRANSITION] Ignorado: no es Player")
		return

	PM.comment_print("[TRANSITION] Player detectado")

	if target_room.is_empty():
		PM.comment_print("[TRANSITION] ERROR: target_room está vacío")
		PM.comment_print("JAJAKJAKJA, PELASTE CABRON")
		return

	PM.comment_print("[TRANSITION] Destino: " + target_room)

	var is_transition_scene: bool = target_room == "res://Scenes/test_dream_transition.tscn"

	PM.comment_print("[TRANSITION] ¿Es escena de transición?: " + str(is_transition_scene))

	if Points.is_timer_running():
		PM.comment_print("[POINTS] Timer activo")

		if Points.visible:
			PM.comment_print("[POINTS] Ocultando Points")
			Points._toggle_visible()

		PM.comment_print("[POINTS] Deteniendo timer")
		Points._stop_timer()

		PM.comment_print("[POINTS] Finalizando nivel")
		Points._end_level()

		PM.comment_print("[POINTS] Reiniciando Points")
		Points._reset()

		MusicManager.fade_time = level_fade
		PM.comment_print("[MUSIC] Fade time: " + str(level_fade))
	else:
		PM.comment_print("[POINTS] No hay timer activo")

	PM.comment_print("[TRANSITION] Iniciando cambio de escena")

	if is_transition_scene:
		await Transition.change_scene(target_room, 2)
	else:
		await Transition.change_scene(target_room)
