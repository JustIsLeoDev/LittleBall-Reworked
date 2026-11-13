extends Area2D

@export var camera: Camera2D
@export var zoom_target: Vector2 = Vector2(0.25, 0.25)
@export var zoom_speed: float = 5.0

var zooming: bool = false

func _process(delta: float) -> void:
	if zooming and camera:
		camera.zoom = camera.zoom.lerp(zoom_target, zoom_speed * delta)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PM.info_print("SE ENCONTRO PLAYER")

		if camera:
			PM.info_print("SE ENCONTRO CAMARA")
			PM.info_print("LA ESCALA DE LA CAMARA ES 0 " + str(camera.zoom))

			zooming = true

			PM.info_print("LA ESCALA DE LA CAMARA ES 1 " + str(camera.zoom))
