extends Area2D

@export var target_room: String = "res://Scenes/level_selector.tscn"
@export var level_fade: float = 1.0
var fuente: FontFile = load("res://fonts/GeistPixel-Regular-VariableFont_ELSH.ttf")
var mostrar_mensaje: bool = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	if target_room:
		Transition.change_scene(target_room)
		if Points.is_timer_running():
			if Points.visible:
				Points._toggle_visible()
			Points._stop_timer()
			Points._end_level()
			Points._reset()
			MusicManager.fade_time = level_fade
		
	else:
		PM.comment_print("JAJAKJAKJA, PELASTE CABRON")
