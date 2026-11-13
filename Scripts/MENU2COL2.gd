extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.debug:
		queue_free()
	pass # Replace with function body.
