extends Area2D
@onready var spritecont : Sprite2D = $Sprite2D2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("grapple_points")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
