
extends Node2D

@export var camera: Camera2D
@export var target: Node2D
@export var menu2: Node2D
@export var subviewport: SubViewport
@export var desaparecer: Array[CanvasItem]
var Actual_room = 1
enum STATE {
	BEFORE_TRANSITION,
	TRANSITIONING,
	AFTER_TRANSITION
}

@export var state: STATE = STATE.BEFORE_TRANSITION

var transition_started: bool = false


func _on_size_changed() -> void:
	_update_viewport_size()


func _update_viewport_size() -> void:
	subviewport.size = get_viewport().get_visible_rect().size
	print(subviewport.size)


func _ready() -> void:
	add_to_group("scene_transition")
	get_viewport().size_changed.connect(_on_size_changed)
	_update_viewport_size()

	PM.info_print("Transición inicializada")

	if not is_instance_valid(camera):
		PM.error_print("No se asignó Camera2D")
		return

	if not is_instance_valid(target):
		PM.error_print("No se asignó el target")
		return

	if not is_instance_valid(menu2):
		PM.error_print("No se asignó menu2")
		return

	PM.info_print("Referencias comprobadas correctamente")

	_apply_state()


func _apply_state() -> void:
	match state:
		STATE.BEFORE_TRANSITION:
			camera.zoom = Vector2.ONE
			menu2.modulate.a = 1.0

			for node: CanvasItem in desaparecer:
				if is_instance_valid(node):
					node.modulate.a = 1.0

			transition_started = false
			Actual_room = 1

		STATE.TRANSITIONING:
			$Nube.visible = true
			transition_started = true
			Actual_room = 1

		STATE.AFTER_TRANSITION:
			Actual_room = 2
			if $SubViewport/Node2D:
				$SubViewport/Node2D.queue_free()
			camera.zoom = Vector2(0.25, 0.25)
			menu2.modulate.a = 0.0

			for node: CanvasItem in desaparecer:
				if is_instance_valid(node):
					node.modulate.a = 0.0

			camera.mode = camera.MODE.FOLLOWX
			camera.target = target
			target.ID = 0
			Global.actual_player = 0

			transition_started = true


func set_state(new_state: STATE) -> void:
	state = new_state
	_apply_state()


func _process(_delta: float) -> void:
	if state != STATE.BEFORE_TRANSITION:
		return

	if Global.actual_player != 1:
		return

	set_state(STATE.TRANSITIONING)

	PM.info_print("Iniciando transición")

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		camera,
		"zoom",
		Vector2(0.25, 0.25),
		1.0
	)

	tween.tween_property(
		menu2,
		"modulate:a",
		0.0,
		1.0
	)

	for node: CanvasItem in desaparecer:
		if is_instance_valid(node):
			tween.tween_property(
				node,
				"modulate:a",
				0.0,
				1.0
			)

	PM.info_print("Tween iniciado")

	await tween.finished

	PM.info_print("Transición terminada")

	camera.mode = camera.MODE.FOLLOWX
	camera.target = target
	target.ID = 0
	Global.actual_player = 0

	set_state(STATE.AFTER_TRANSITION)

	PM.info_print("Nuevo target de cámara asignado")
