extends Area2D
@export var camera : Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.





func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		camera.mode = camera.MODE.CINEMATIC
		var point: CameraPoint = CameraPoint.new()
		point.position = global_position + Vector2(-800, 1900)
		point.direction = Vector2.LEFT
		point.duration = 1.0
	
	pass # Replace with function body.
