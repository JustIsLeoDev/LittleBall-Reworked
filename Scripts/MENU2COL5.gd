extends Area2D

@export var camera: Camera2D

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	camera.mode = camera.MODE.FOLLOWX
	camera.target = body
