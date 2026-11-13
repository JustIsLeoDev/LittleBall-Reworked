extends Area2D

@export var camera: Camera2D
@export var colision: CollisionShape2D
@export var colision2: CollisionShape2D

func _ready() -> void:
	if colision2:
		colision2.disabled = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.jump_locked = true
		body.dash_locked = true

		if colision:
			colision.position = Vector2(1000,1000)

		if colision2:
			colision2.set_deferred("disabled", false)

		if camera:
			camera.mode = camera.MODE.FOLLOWY
