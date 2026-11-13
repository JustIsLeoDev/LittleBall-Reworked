extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	PM.info_print("Entró: " + str(body.name))

	if body.is_in_group("Player"):
		body.die()
