extends Area2D

@export var launch_direction: Vector2 = Vector2.RIGHT
@export var launch_speed: float = 2500.0
@export var launch_impulse: float = 150.0
@export var exit_jump_force: float = 1400.0
@export var directioncam: Vector2 = Vector2.RIGHT
@export var target_level: String
@export var alpha_hide_time: float = 2.0
@export var alpha_show_time: float = 0.35

@onready var cannon_sprite: Sprite2D = $Node2D/Canonpart1
@onready var colision1: CollisionShape2D = $Node2D/StaticBody2D/CollisionShape2D
@onready var colision2: CollisionShape2D = $Node2D/StaticBody2D/CollisionShape2D2
@onready var colision3: CollisionShape2D = $Node2D/StaticBody2D/CollisionShape2D3
@onready var collision_parent: Node2D = $Node2D

var cam

var target_alpha: float = 1.0
var launch_time: float = 0.0
var player: Node2D = null
var launching: bool = false
var rotated: bool = false
var rotation_start: float = 0.0
var rotation_target: float = 0.0
var rotation_progress: float = 0.0
var cannon_returning: bool = false
var cannon_return_time: float = 0.0
var cannon_start_rotation: float = 0.0

func _ready() -> void:
	cam = get_tree().get_first_node_in_group("CamDreamLevelSelectorMenu2")

	if cam == null:
		PM.error_print("No se encontró CamDreamLevelSelectorMenu2")
	else:
		print("Cámara seleccionada: ", cam.get_path())
	#var cameras: Array[Node] = get_tree().get_nodes_in_group("Cam")
#
	#for camera: Node in cameras:
	#	print("Cámara: ", camera.get_path())
	#	print("Escena: ", camera.scene_file_path)
#
	#	if camera.scene_file_path == get_tree().current_scene.scene_file_path:
	#		cam = camera
	#		break
#
	#if cam == null:
	#	PM.error_print("No se encontró la cámara de esta escena")
func _process(delta: float) -> void:
	var alpha_speed: float = 1.0 / alpha_hide_time
	if target_alpha > cannon_sprite.modulate.a:
		alpha_speed = 1.0 / alpha_show_time

	cannon_sprite.modulate.a = move_toward(
		cannon_sprite.modulate.a,
		target_alpha,
		alpha_speed * delta
	)

	if cannon_returning:
		cannon_return_time += delta
		var progress: float = minf(cannon_return_time / 1.5, 1.0)
		var smooth_progress: float = smoothstep(0.0, 1.0, progress)

		collision_parent.rotation = lerp_angle(
			cannon_start_rotation,
			0.0,
			smooth_progress
		)

		$CollisionShape2D.rotation = collision_parent.rotation

		if progress >= 1.0:
			cannon_returning = false

	if player == null or launching:
		$Label.text = ""
		rotated = false
		rotation_progress = 0.0
		return

	launch_time -= delta

	if launch_time <= 2.0 and not rotated:
		rotation_start = collision_parent.rotation
		var cannon_direction: Vector2 = -launch_direction.normalized()
		rotation_target = cannon_direction.angle() - PI / 2.0
		rotation_progress = 0.0
		rotated = true

	if rotated and launch_time > 0.0:
		rotation_progress += delta / 2.0
		rotation_progress = minf(rotation_progress, 1.0)
		var smooth_progress: float = smoothstep(0.0, 1.0, rotation_progress)

		collision_parent.rotation = lerp_angle(
			rotation_start,
			rotation_target,
			smooth_progress
		)

		$CollisionShape2D.rotation = collision_parent.rotation

	var seconds: int = int(maxf(launch_time, 0.0))
	var milliseconds: int = int((maxf(launch_time, 0.0) - seconds) * 100.0)

	$Label.text = "%02d:%02d" % [seconds, milliseconds]

	if launch_time <= 0.0:
		launch_player()

func launch_player() -> void:
	if launching or player == null:
		return

	launching = true
	target_alpha = 1.0

	var current_player: Node2D = player
	player = null
	launch_time = 0.0
	$Label.text = ""

	if not is_instance_valid(current_player):
		launching = false
		return

	if current_player.state != current_player.PlayerState.NORMAL:
		launching = false
		target_alpha = 1.0
		return

	var launch_vector: Vector2 = launch_direction.normalized()
	current_player.velocity = launch_vector * launch_speed
	current_player.velocity += launch_vector * launch_impulse
	current_player.dash_locked = true
	current_player.jump_locked = true
	current_player.can_move = false

	get_tree().create_timer(1.5).timeout.connect(_start_cannon_return)

	if cam:
		if directioncam == Vector2.RIGHT:
			colision2.disabled = true
			colision1.disabled = true
			cam.target = null
			cam.mode = cam.MODE.CINEMATIC

			var point: CameraPoint = CameraPoint.new()
			point.position = global_position + Vector2(500, 0)
			point.direction = directioncam
			point.duration = 1.0

			cam.cinematic_points.append(point)
			cam.trigger_cinematic()

			await get_tree().create_timer(1.0).timeout

			if is_instance_valid(current_player):
				current_player.queue_free()

			var escena: PackedScene = preload("res://Scenes/FakefallrightREAL.tscn")
			PM.info_print("escena es " + str(escena))

			var instancia: Node2D = escena.instantiate()
			instancia.global_position = global_position + Vector2(1000, -460)
			get_parent().add_child(instancia)

		elif directioncam == Vector2.LEFT:
			colision2.disabled = true
			colision1.disabled = true
			cam.target = null
			cam.mode = cam.MODE.CINEMATIC

			var point: CameraPoint = CameraPoint.new()
			point.position = global_position + Vector2(-500, 0)
			point.direction = directioncam
			point.duration = 1.0

			cam.cinematic_points.append(point)
			cam.trigger_cinematic()

			await get_tree().create_timer(1.0).timeout

			if is_instance_valid(current_player):
				current_player.queue_free()

			var escena: PackedScene = preload("res://Scenes/fakefallleft_real.tscn")
			PM.info_print("escena es " + str(escena))

			var instancia: Node2D = escena.instantiate()
			instancia.global_position = global_position + Vector2(-1000, -460)
			get_parent().add_child(instancia)
	else:
		PM.error_print("No se encontró camara")

	launching = false

func _start_cannon_return() -> void:
	if not is_instance_valid(collision_parent):
		return

	cannon_start_rotation = collision_parent.rotation
	cannon_return_time = 0.0
	cannon_returning = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.dash_locked = true

		if body.state == body.PlayerState.NORMAL:
			player = body
			launch_time = 5.0
			Global.Target_level = target_level
			target_alpha = 0.0

func _on_body_exited(body: Node2D) -> void:
	if body == player and not launching:
		var exit_player: Node2D = player

		player = null
		launch_time = 0.0
		$Label.text = ""
		rotated = false
		rotation_progress = 0.0

		if is_instance_valid(exit_player):
			exit_player.velocity.y = -exit_jump_force
			exit_player.dash_locked = false
			exit_player.jump_locked = false

		target_alpha = 1.0
		cannon_start_rotation = collision_parent.rotation
		cannon_return_time = 0.0
		cannon_returning = true
