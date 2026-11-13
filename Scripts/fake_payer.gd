extends RigidBody2D

@export var max_speed: float = 5000.0
@export var target_scale: float = 128.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("HOLASOYFALSOXDDDD")
	var size: Vector2 = sprite.texture.get_size()

	sprite.scale = Vector2(
		target_scale / size.x,
		target_scale / size.y
	)

	gravity_scale = 1.0


func _physics_process(delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed


func _process(delta: float) -> void:
	scale -= Vector2.ONE * 0.25 * delta

	if scale.x <= 0.0:
		get_tree().change_scene_to_file(str(Global.Target_level))
