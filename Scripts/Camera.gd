
extends Camera2D

@export var target: Node2D

enum MODE {
	STATIC,
	FOLLOWXY,
	FOLLOWX,
	FOLLOWY,
	CINEMATIC
}


@export var ID_cam:String= "Cam"

@export var cinematic_points: Array[CameraPoint] = []
@export var mode: MODE = MODE.STATIC

@export_group("Drunk Effect")
@export var drunk_enabled: bool = false
@export_range(0.0, 3.0, 0.1) var drunk_intensity: float = 1.0
@export_range(0.1, 5.0, 0.1) var drunk_speed: float = 1.0
@export_range(0.0, 30.0, 0.5) var drunk_rotation_degrees: float = 3.0
@export_range(0.0, 50.0, 1.0) var drunk_movement: float = 12.0
@export_range(0.0, 0.1, 0.005) var drunk_zoom_amount: float = 0.015

@export_group("Drunk Window")
@export var drunk_window_enabled: bool = false
@export_range(0.0, 50.0, 1.0) var drunk_window_movement: float = 8.0
@export_range(0.1, 5.0, 0.1) var drunk_window_speed: float = 0.8

var drunk_time: float = 0.0
var drunk_offset: Vector2 = Vector2.ZERO
var base_zoom: Vector2 = Vector2.ONE
var base_rotation: float = 0.0

var window_time: float = 0.0
var window_base_position: Vector2i = Vector2i.ZERO
var window_last_position: Vector2i = Vector2i.ZERO
var window_last_offset: Vector2i = Vector2i.ZERO
var window_position_initialized: bool = false

var shake_intensity: float = 0.0
var time_passed: float = 0.0
var current_bpm: float = 120.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var initial_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

var cinematic_index: int = 0
var cinematic_timer: float = 0.0
var cinematic_start_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	if ID_cam != "Cam":
		add_to_group(str(ID_cam))
	else:
		add_to_group("Cam")

	base_zoom = zoom
	base_rotation = rotation

	window_base_position = DisplayServer.window_get_position()
	window_last_position = window_base_position
	window_position_initialized = true

	trigger_bpm_shake(80.0, 0.0, 180.0)



func _process(delta: float) -> void:
	match mode:
		MODE.STATIC:
			pass

		MODE.FOLLOWXY:
			if is_instance_valid(target):
				global_position = target.global_position

		MODE.FOLLOWX:
			if is_instance_valid(target):
				global_position.x = target.global_position.x

		MODE.FOLLOWY:
			if is_instance_valid(target):
				global_position.y = target.global_position.y

		MODE.CINEMATIC:
			process_cinematic(delta)

	process_shake(delta)
	process_drunk(delta)
	process_drunk_window(delta)

	offset = shake_offset + drunk_offset



func process_shake(delta: float) -> void:
	shake_offset = Vector2.ZERO

	if shake_timer > 0.0:
		time_passed += delta
		shake_timer = maxf(shake_timer - delta, 0.0)

		var life_ratio: float = 0.0

		if shake_duration > 0.0:
			life_ratio = shake_timer / shake_duration

		shake_intensity = initial_intensity * life_ratio

		var beat_duration: float = 60.0 / maxf(current_bpm, 1.0)
		var period: float = beat_duration * 4.0
		var angular_frequency: float = (2.0 * PI) / period

		var horizontal_shake: float = (
			sin(time_passed * angular_frequency) * shake_intensity
		)

		shake_offset = Vector2(horizontal_shake, 0.0)
	else:
		shake_intensity = 0.0
		time_passed = 0.0



func process_drunk(delta: float) -> void:
	if not drunk_enabled:
		drunk_offset = Vector2.ZERO
		rotation = base_rotation
		return

	drunk_time += delta * drunk_speed

	var intensity: float = drunk_intensity

	var horizontal: float = (
		sin(drunk_time * 1.3) * drunk_movement
		+ sin(drunk_time * 0.55) * drunk_movement * 0.6
	) * intensity

	var vertical: float = (
		sin(drunk_time * 0.8 + 1.2)
		+ sin(drunk_time * 1.7)
	) * drunk_movement * 0.5 * intensity

	drunk_offset = Vector2(horizontal, vertical)

	rotation = base_rotation + deg_to_rad(
		sin(drunk_time * 0.9)
		* drunk_rotation_degrees
		* intensity
	)

	var zoom_factor: float = 1.0 + (
		sin(drunk_time * 1.1)
		* drunk_zoom_amount
		* intensity
	)

	zoom = base_zoom * zoom_factor



func process_drunk_window(delta: float) -> void:
	if not window_position_initialized:
		return

	var current_position: Vector2i = (
		DisplayServer.window_get_position()
	)

	if not drunk_enabled or not drunk_window_enabled:
		# No restaurar una posición anterior: respetar la actual.
		window_base_position = current_position
		window_last_position = current_position
		window_last_offset = Vector2i.ZERO
		return

	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		window_last_position = current_position
		return

	# Compensar el movimiento manual de la ventana.
	# Restamos el desplazamiento del efecto anterior para no
	# confundirlo con un movimiento realizado por el usuario.
	#var expected_position: Vector2i = (
	#	window_base_position + window_last_offset
	#)

	if current_position != window_last_position:
		var external_movement: Vector2i = (
			current_position - window_last_position
		)

		window_base_position += external_movement

	window_time += delta * drunk_window_speed

	var movement: Vector2 = Vector2(
		sin(window_time * 1.3),
		sin(window_time * 0.8)
	) * drunk_window_movement * drunk_intensity

	var new_offset: Vector2i = Vector2i(
		roundi(movement.x),
		roundi(movement.y)
	)

	var new_position: Vector2i = (
		window_base_position + new_offset
	)

	if new_position != current_position:
		DisplayServer.window_set_position(new_position)

	window_last_offset = new_offset
	window_last_position = new_position


func process_cinematic(delta: float) -> void:
	if cinematic_points.is_empty():
		return

	if cinematic_index >= cinematic_points.size():
		return

	var point: CameraPoint = cinematic_points[cinematic_index]

	cinematic_timer += delta

	var progress: float = cinematic_timer / point.duration
	progress = clampf(progress, 0.0, 1.0)

	var destination: Vector2 = point.position + point.direction

	global_position = point.position.lerp(
		destination,
		progress
	)

	if progress >= 1.0:
		global_position = destination

		cinematic_index += 1
		cinematic_timer = 0.0

		if cinematic_index < cinematic_points.size():
			cinematic_start_position = (
				cinematic_points[cinematic_index].position
			)


func trigger_cinematic() -> void:
	if cinematic_points.is_empty():
		return

	cinematic_index = 0
	cinematic_timer = 0.0
	cinematic_start_position = cinematic_points[0].position

	global_position = cinematic_start_position


func trigger_bpm_shake(
	intensity: float,
	duration: float,
	bpm: float
) -> void:
	initial_intensity = intensity
	shake_intensity = intensity
	shake_duration = maxf(duration, 0.0)
	shake_timer = shake_duration
	current_bpm = maxf(bpm, 1.0)
