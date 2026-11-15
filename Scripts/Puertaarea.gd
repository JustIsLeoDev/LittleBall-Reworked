extends Area2D

@export var target_room: String = "res://Scenes/test_dream_transition.tscn"
@export var level_fade: float = 1.0

var fuente: FontFile = load("res://fonts/GeistPixel-Regular-VariableFont_ELSH.ttf")
var mostrar_mensaje: bool = false


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	if target_room.is_empty():
		PM.comment_print("JAJAKJAKJA, PELASTE CABRON")
		return

	var is_transition_scene: bool = target_room == "res://Scenes/test_dream_transition.tscn"

	if Points.is_timer_running():
		if Points.visible:
			Points._toggle_visible()

		Points._stop_timer()
		Points._end_level()
		Points._reset()
		MusicManager.fade_time = level_fade

	await Transition.change_scene(target_room)

	if is_transition_scene:
		var transition: Node = get_tree().get_first_node_in_group("scene_transition")

		if is_instance_valid(transition):
			transition.set_state(transition.STATE.AFTER_TRANSITION)
