class_name Player
extends CharacterBody2D
@export_category("Heavy Mechanic")
@export var heavy_fall_multiplier: float = 2.5
@export var heavy_landing_scale: Vector2 = Vector2(1.5, 0.5)
@export var heavy_squash_speed: float = 12.0
var heavy_fall_active: bool = false
var heavy_active: bool = false
var gravity_direction: Vector2 = Vector2.DOWN
var last_direction: Vector2 = Vector2.RIGHT
var cannon_launch_timer: float = 0.0
var cannon_launch_velocity: Vector2 = Vector2.ZERO
@onready var outline_sprite: Sprite2D = $SpritePivot/Sprite2D2
var rainbow_offset: float = 0.0
var jump_hold_time: float = 0.0
var jump_holding: bool = false
@export var heavy_ground_scale: Vector2 = Vector2(1.3, 0.6)
var heavy_ground_active: bool = false
const JUMP_HOLD_MAX: float = 0.25
const JUMP_HOLD_GRAVITY: float = 0.4
@export var jump_locked: bool = false
@export var dash_locked: bool = false
var orb_was_active: bool = false
var can_act: bool = true
var cant_act_count : int = 5
var max_can_act : int = 5
enum PlayerState {
	NORMAL,
	ORB,
	DEAD,
	DASH_PREPARING,
	DASHING,
	ORB_PREPARING,
	SWING
}
@export_category("Orb Special Jump")
@export var heavy_jump_velocity: float = -1800.0
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var heavy_jump_timer: Timer = $HeavyJumpTimer

var heavy_jump_ready: bool = false
@export var orb_prepare_duration: float = 0.25
@export var orb_jump_multiplier: float = 2.0

var orb_prepare_timer: float = 0.0
enum TrailStyle {
	FADE,
	SOLID,
	FADE_AND_SCALE,
	GHOST
}

enum TrailType {
	NONE,
	SPRITE_2D,
	LINE_2D,
	TEXTURED_LINE
}


var state: PlayerState = PlayerState.NORMAL

var df_Max_dash: int = 3
var Max_dash: int = int(df_Max_dash)

@export var df_Max_jump: int = 1
var Max_jump: int = int(df_Max_jump)

var mechanic: Array[bool] = [true, true, true, true, true, true]

func is_mechanic_enabled(index: int) -> bool:
	if index < 0 or index >= mechanic.size():
		return false
	return mechanic[index]

func set_mechanic_enabled(index: int, enabled: bool) -> void:
	if index < 0 or index >= mechanic.size():
		PM.warning_print("Índice de mecánica inválido: " + str(index))
		return
	if mechanic[index] != enabled:
		mechanic[index] = enabled
		PM.info_print("Mecánica " + str(index) + " cambiada a: " + str(enabled))
		
		if index == 1 and not enabled:
			if dashing or dash_preparing:
				dashing = false
				dash_preparing = false
				dash_particles.emitting = false
				if state == PlayerState.DASHING or state == PlayerState.DASH_PREPARING:
					change_state(PlayerState.NORMAL)
		elif index == 2 and not enabled:
			if state == PlayerState.ORB_PREPARING:
				orb_prepare_timer = 0.0
				change_state(PlayerState.NORMAL)
		elif index == 3 and not enabled:
			if grapple_active:
				release_grapple()

const COYOTE_DURATION: float = 0.15


@export var gravity: float = 2000.0
@export var fall_gravity: float = 3000.0
@export var death_particles_scene: PackedScene
@export var MAX_SPEED: float = 1400.0
@export var ACCELERATION: float = 3560.0
@export var FRICTION: float = 2.0
@export var JUMP_VELOCITY: float = -1250.0
@export var MAX_SLOPE_SPEED: float = 1400.0


var can_dash: bool = false
var dashing: bool = false

@export var dash_speed: float = 2000.0
@export var dash_duration: float = 0.5

var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO


@export_category("Dash Preparation")

@export var dash_prepare_duration: float = 0.12

var dash_prepare_timer: float = 0.0
var dash_preparing: bool = false


@export_category("Time Slow")

@export_range(0.01, 1.0, 0.01)
var slow_time_multiplier: float = 0.25


@export_category("Trail")

@export var rainbow_trail: bool = true

@export var rainbow_speed: float = 0.5

@export var target_scale: float = 64.0

@export var trail_enabled: bool = true

@export var trail_type: TrailType = TrailType.LINE_2D

@export var trail_style: TrailStyle = TrailStyle.FADE

@export_range(1, 100, 1)
var trail_length: int = 20

@export_range(0.0, 100.0, 1.0)
var trail_spacing: float = 20.0

@export_range(0.0, 1.0, 0.01)
var trail_min_alpha: float = 0.0

@export_range(0.05, 2.0, 0.01)
var trail_min_scale: float = 0.35

@export_range(1.0, 100.0, 1.0)
var trail_width: float = 12.0

@export var trail_color: Color = Color(0.0, 1.0, 0.2)

@export var trail_texture: Texture2D

@export var trail_round_caps: bool = true


@export_category("Squash & Stretch")

@export var squash_stretch_enabled: bool = true

@export var fall_scale: Vector2 = Vector2(0.88, 1.12)
@export var jump_scale: Vector2 = Vector2(0.82, 1.18)
@export var jump_squash_scale: Vector2 = Vector2(1.25, 0.75)
@export var dash_scale: Vector2 = Vector2(1.30, 0.70)
@export var landing_scale: Vector2 = Vector2(1.35, 0.65)

@export var squash_speed: float = 5.0
@export var jump_stretch_speed: float = 4.0
@export var jump_squash_speed: float = 8.0
@export var landing_recovery_speed: float = 2.0
@export var dash_squash_speed: float = 8.0

@export var jump_squash_duration: float = 0.12
@export var landing_duration: float = 0.35
@export var landing_velocity_scale: float = 0.0005
@export var max_landing_squash: float = 1.5


var squash_base_scale: Vector2 = Vector2.ONE
var was_on_floor: bool = false
var landing_timer: float = 0.0
var last_vertical_velocity: float = 0.0
var landing_scale_current: Vector2 = Vector2.ONE

var jump_squash_timer: float = 0.0
var jumping_visual: bool = false


# powerup[0] = ralentización de tiempo
# powerup[1] = libre
# powerup[2] = libre
var powerup: Array = [false, false, false]

var multiplier: float = 1.0

var can_move: bool = true
var jumping: bool = false
var coyote_time: float = 0.0
var orb: bool = false


var history: Array[Dictionary] = []

var trail_container: Node2D
var trail_sprites: Array[Sprite2D] = []


@onready var squash_visual: Node2D = $SpritePivot
@onready var sprite: Sprite2D = $SpritePivot/Sprite2D
@onready var sprite_line: Sprite2D = $SpritePivot/Sprite2D2
@onready var jump_audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var dash_audio: AudioStreamPlayer = $AudioStreamPlayer2
#@onready var pause_button: Button = $CanvasLayer/Button
@onready var dash_particles: GPUParticles2D = $Node2D2/GPUParticles2D
@onready var trail_line: Line2D = $Line2D
@export_category("Sprite")
@export var sprite_rotation: float = 0.0
@export_category("Grappling Hook")

@export var grapple_range: float = 600.0
@export var swing_gravity: float = 2000.0
@export var swing_acceleration: float = 1800.0

var grapple_anchor: Vector2 = Vector2.ZERO
var grapple_length: float = 0.0
var grapple_active: bool = false
@export var grapple_extra_length: float = 100.0
@export var grapple_jump_boost: float = 1250.0
@export var grapple_rope_segments: int = 12
@onready var rope_line: Line2D = $RopeLine
func _ready() -> void:
	rope_line.visible = false
	apply_global_config()
	PM.info_print("OSTIAASSSS, APARECI EN " + str(get_tree().current_scene.get_path() ))
	$AudioStreamPlayer.bus = "SFX"
	$Nick.text = Global.nickson

	if powerup[0]:
		multiplier = slow_time_multiplier
	else:
		multiplier = 1.0

	squash_base_scale = squash_visual.scale
	was_on_floor = is_on_floor()

	#var sets: Node = get_tree().get_first_node_in_group("set")
#
	#if not sets:
		#var escena: PackedScene = preload("res://Scenes/set.tscn")
		#var instancia: Node = escena.instantiate()
		#add_child(instancia)

	add_to_group("Player")

	floor_constant_speed = false
	floor_snap_length = 32.0

	Max_jump = df_Max_jump
	Max_dash = df_Max_dash

	dash_particles.emitting = false

	setup_trail()

	change_state(PlayerState.NORMAL)
	sprite.rotation = deg_to_rad(sprite_rotation)

func setup_trail() -> void:
	#PM.info_print("=== TRAIL DEBUG ===")
	#PM.info_print("Escena: " + str(get_tree().current_scene.scene_file_path))
	#PM.info_print("trail_enabled: " + str(trail_enabled))
	#PM.info_print("trail_type: " + str(trail_type))
	#PM.info_print("trail_length: " + str(trail_length))
	#PM.info_print("trail_spacing: " + str(trail_spacing))
	#PM.info_print("Trail Line válido: " + str(is_instance_valid(trail_line)))

	if not is_instance_valid(trail_line):
		#PM.error_print("TRAIL ERROR: Line2D no existe")
		return

	trail_line.clear_points()
	trail_line.width = trail_width
	trail_line.default_color = Color.WHITE
	trail_line.top_level = true

	if trail_round_caps:
		trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	else:
		trail_line.begin_cap_mode = Line2D.LINE_CAP_NONE
		trail_line.end_cap_mode = Line2D.LINE_CAP_NONE

	if trail_type == TrailType.TEXTURED_LINE:
		trail_line.texture = trail_texture
	else:
		trail_line.texture = null

	trail_line.visible = (
		trail_type == TrailType.LINE_2D
		or trail_type == TrailType.TEXTURED_LINE
	)

	PM.info_print("Line2D visible: " + str(trail_line.visible))
	PM.info_print("Line2D parent: " + str(trail_line.get_parent()))

	setup_sprite_trail()

	PM.info_print("Trail inicializado")


func setup_sprite_trail() -> void:
	#PM.info_print("=== SPRITE TRAIL DEBUG ===")
	#PM.info_print("Escena: " + str(get_tree().current_scene.scene_file_path))
	#PM.info_print("Tipo: " + str(trail_type))
	#PM.info_print("Activado: " + str(trail_enabled))
	#PM.info_print("Longitud: " + str(trail_length))
	#PM.info_print("Sprite válido: " + str(is_instance_valid(sprite)))

	if is_instance_valid(sprite):
		pass
		#PM.info_print("Textura del jugador: " + str(sprite.texture))

	for old_sprite: Sprite2D in trail_sprites:
		if is_instance_valid(old_sprite):
			old_sprite.queue_free()

	trail_sprites.clear()

	if trail_type != TrailType.SPRITE_2D:
		#PM.warning_print("SPRITE TRAIL: Tipo incorrecto")
		return

	if not trail_enabled:
		#PM.warning_print("SPRITE TRAIL: Desactivado")
		return

	trail_container = Node2D.new()
	trail_container.name = "SpriteTrail"
	trail_container.top_level = true
	trail_container.z_index = -1
	add_child(trail_container)

	#PM.info_print("Contenedor creado: " + str(trail_container.get_path()))
	#PM.info_print("Contenedor visible: " + str(trail_container.is_visible_in_tree()))

	for i: int in range(trail_length):
		var trail_sprite: Sprite2D = Sprite2D.new()
		trail_sprite.texture = sprite.texture
		trail_sprite.region_enabled = sprite.region_enabled
		trail_sprite.region_rect = sprite.region_rect
		trail_sprite.modulate = Color(
			trail_color.r,
			trail_color.g,
			trail_color.b,
			0.0
		)
		trail_sprite.z_index = -1
		trail_container.add_child(trail_sprite)
		trail_sprites.append(trail_sprite)

	#PM.info_print("Sprites creados: " + str(trail_sprites.size()))
	#PM.info_print("Textura primer trail: " + str(trail_sprites[0].texture))


func change_state(new_state: PlayerState) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		PlayerState.NORMAL:
			jumping = false

		PlayerState.ORB:
			jumping = false
		PlayerState.ORB_PREPARING:
			jumping = false
			dashing = false
			dash_preparing = false
			velocity = Vector2.ZERO
		PlayerState.DEAD:
			can_move = false
			velocity = Vector2.ZERO
			dashing = false
			dash_preparing = false
			dash_particles.emitting = false

		PlayerState.DASH_PREPARING:
			jumping = false
			dashing = false
			velocity = Vector2.ZERO

		PlayerState.DASHING:
			jumping = false
			dash_preparing = false

var current_grapple_target: Node2D = null

func _process(_delta: float) -> void:
	var target: Node2D = get_grapple_target()

	if current_grapple_target != target:
		if is_instance_valid(current_grapple_target):
			current_grapple_target.get_node("spritecont").visible = false

		current_grapple_target = target

		if is_instance_valid(current_grapple_target):
			current_grapple_target.get_node("spritecont").visible = true

	if target != null:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
func _physics_process(delta: float) -> void:
	if is_on_floor():
		cant_act_count = max_can_act
	can_act = cant_act_count > 0
	rainbow_offset = fmod(
	rainbow_offset + delta * rainbow_speed,
	1.0
)	
	if cannon_launch_timer > 0.0:
		cannon_launch_timer -= delta
		velocity = cannon_launch_velocity
	var input_direction: float = get_control_axis()#var input_direction: float = Input.get_axis("left", "right")
	if input_direction != 0.0:
		last_direction = Vector2(input_direction, 0.0).normalized()
	#rotation = gravity_direction.angle() + PI / 2.0
	var size: Vector2 = sprite.texture.get_size()
	sprite.scale = Vector2(
	128.0 / size.x,
	128.0 / size.y
)
	var outline_size: Vector2 = outline_sprite.texture.get_size()

	outline_sprite.scale = Vector2(
	135.0 / outline_size.x,
	135.0 / outline_size.y
)
	can_dash_process()
	if Global.is_online:
		$Nick.visible = true
	else:
		$Nick.visible = false

	if powerup[0]:
		multiplier = slow_time_multiplier
	else:
		multiplier = 1.0

	if Global.debug:
		$CanvasLayer/VBoxContainer/Label.text = PlayerState.keys()[state]
		$CanvasLayer/VBoxContainer/Label.visible = true
		$CanvasLayer/VBoxContainer/Label2.visible = true
		$CanvasLayer/VBoxContainer/Label2.text = str(Max_jump)
	else:
		$CanvasLayer/VBoxContainer/Label.visible = false
		$CanvasLayer/VBoxContainer/Label2.visible = false

	var time_scale: float = max(multiplier, 0.0)
	var time_delta: float = delta * time_scale

	
	if state == PlayerState.DEAD:
		process_dead_state(time_delta)
	else:
		if state == PlayerState.NORMAL and orb:
			change_state(PlayerState.ORB)
		elif state == PlayerState.ORB and not orb:
			change_state(PlayerState.NORMAL)

		match state:
			PlayerState.SWING:
				process_swing_state(time_delta)
			PlayerState.ORB_PREPARING:
				process_orb_prepare_state(delta)
			PlayerState.NORMAL:
				process_normal_state(time_delta)

			PlayerState.ORB:
				process_orb_state(time_delta)

			PlayerState.DASH_PREPARING:
				process_dash_prepare_state(delta)

			PlayerState.DASHING:
				process_dashing_state(time_delta)


	var physical_velocity: Vector2 = velocity

	last_vertical_velocity = physical_velocity.y

	velocity = physical_velocity * time_scale

	move_and_slide()
	update_grapple_rope()
	if dashing and get_slide_collision_count() > 0:
		for i: int in range(get_slide_collision_count()):
			var collision: KinematicCollision2D = get_slide_collision(i)
			var normal: Vector2 = collision.get_normal()

			if velocity.dot(normal) < 0.0:
				var slide_velocity: Vector2 = velocity.slide(normal)

				if slide_velocity.length() > 1.0:
					velocity = slide_velocity
					dash_direction = slide_velocity.normalized()
				else:
					dashing = false
					dash_timer = 0.0
					velocity = Vector2.ZERO
					dash_particles.emitting = false
					change_state(PlayerState.NORMAL)

				break

	if time_scale > 0.0:
		velocity /= time_scale
	else:
		velocity = Vector2.ZERO

	sprite.rotation += physical_velocity.x * 0.00025 * ( #0.00025
		time_delta * 10.0 if multiplier == slow_time_multiplier else 1.0
	)
	heavy_ground_active = (
	is_mechanic_enabled(4)
	and Input.is_action_pressed("heavy")
	and is_on_floor()
	and state == PlayerState.NORMAL
	and not dashing
	and not dash_preparing
)
	update_squash_stretch(delta)

	if trail_enabled and trail_type != TrailType.NONE:
		update_trail_history()
		update_trail()
	else:
		clear_trail()


func update_trail_history() -> void:
	history.push_back({
		"position": global_position,
		"rotation": sprite.global_rotation,
		"scale": squash_visual.global_scale
	})

	var max_history: int = max(
		trail_length * 10,
		trail_length
	)

	while history.size() > max_history:
		history.pop_front()


func clear_trail() -> void:
	trail_line.clear_points()

	for trail_sprite: Sprite2D in trail_sprites:
		if is_instance_valid(trail_sprite):
			trail_sprite.modulate.a = 0.0


func update_trail() -> void:
	if not trail_enabled:
		clear_trail()
		return

	if history.is_empty():
		clear_trail()
		return

	match trail_type:
		TrailType.SPRITE_2D:
			update_sprite_trail()

		TrailType.LINE_2D:
			update_line_trail(false)

		TrailType.TEXTURED_LINE:
			update_line_trail(true)

		TrailType.NONE:
			clear_trail()


func get_trail_points() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var current_position: Vector2 = global_position
	var history_index: int = history.size() - 1

	for i: int in range(trail_length):
		var found_point: bool = false

		for j: int in range(history_index, -1, -1):
			var data: Dictionary = history[j]

			var point_position: Vector2 = data["position"]

			var distance: float = current_position.distance_to(
				point_position
			)

			if i == 0 or distance >= trail_spacing:
				history_index = j
				current_position = point_position
				found_point = true
				break

		if not found_point:
			break

		result.append(history[history_index])

	return result


func update_sprite_trail() -> void:
	trail_line.clear_points()

	var trail_points: Array[Dictionary] = get_trail_points()

	for i: int in range(trail_sprites.size()):
		var trail_sprite: Sprite2D = trail_sprites[i]

		if i >= trail_points.size():
			trail_sprite.modulate.a = 0.0
			continue

		var data: Dictionary = trail_points[i]

		var world_position: Vector2 = data["position"]
		var rotation_value: float = data["rotation"]
		var original_scale: Vector2 = data["scale"]

		trail_sprite.global_position = world_position
		trail_sprite.global_rotation = rotation_value

		var progress: float = 1.0 - (
			float(i) /
			max(float(trail_sprites.size() - 1), 1.0)
		)

		var alpha: float = get_trail_alpha(progress)
		var scale_factor: float = get_trail_scale(progress)
		var texture_size: Vector2 = trail_sprite.texture.get_size()
		var target_size: Vector2 = Vector2(target_scale, target_scale)
		var target_factor: Vector2 = target_size / texture_size

		trail_sprite.scale = (target_factor * original_scale) * Vector2(2, 2)


		if rainbow_trail:
			var hue: float = fmod(rainbow_offset + (float(i) / float(trail_sprites.size())), 1.0)
			trail_sprite.modulate = Color.from_hsv(hue, 1.0, 1.0, alpha)
		else:
			trail_sprite.modulate = Color(
				trail_color.r,
				trail_color.g,
				trail_color.b,
				alpha
			)
		
	

func update_line_trail(textured: bool) -> void:
	trail_line.visible = true

	if textured:
		trail_line.texture = trail_texture
	else:
		trail_line.texture = null

	var trail_points: Array[Dictionary] = get_trail_points()

	var points: PackedVector2Array = PackedVector2Array()

	for data: Dictionary in trail_points:
		var world_position: Vector2 = data["position"]
		points.append(world_position)

	if trail_points.size() < 2:
		PM.warning_print(
			"TRAIL: Pocos puntos. History: "
			+ str(history.size())
			+ " | Trail points: "
			+ str(trail_points.size())
		)
	trail_line.points = points
	if points.size() >= 2 and not trail_line.visible:
		PM.error_print("TRAIL ERROR: Hay puntos, pero Line2D está invisible")
	trail_line.width = trail_width
	trail_line.default_color = Color.WHITE

	update_line_style()


func update_line_style() -> void:
	var gradient: Gradient = Gradient.new()

	if rainbow_trail:
		gradient.offsets = PackedFloat32Array([
			0.0,
			0.16,
			0.33,
			0.50,
			0.66,
			0.83,
			1.0
		])

		gradient.colors = PackedColorArray([
			Color(1.0, 0.0, 0.0, 1.0),
			Color(1.0, 0.5, 0.0, 1.0),
			Color(1.0, 1.0, 0.0, 1.0),
			Color(0.0, 1.0, 0.0, 1.0),
			Color(0.0, 1.0, 1.0, 1.0),
			Color(0.0, 0.0, 1.0, 1.0),
			Color(1.0, 0.0, 1.0, 1.0)
		])
	else:
		match trail_style:
			TrailStyle.FADE:
				gradient.colors = PackedColorArray([
					Color(trail_color.r, trail_color.g, trail_color.b, trail_min_alpha),
					Color(trail_color.r, trail_color.g, trail_color.b, 1.0)
				])

			TrailStyle.SOLID:
				gradient.colors = PackedColorArray([
					Color(trail_color.r, trail_color.g, trail_color.b, 1.0),
					Color(trail_color.r, trail_color.g, trail_color.b, 1.0)
				])

			TrailStyle.FADE_AND_SCALE:
				gradient.colors = PackedColorArray([
					Color(trail_color.r, trail_color.g, trail_color.b, trail_min_alpha),
					Color(trail_color.r, trail_color.g, trail_color.b, 1.0)
				])

			TrailStyle.GHOST:
				gradient.colors = PackedColorArray([
					Color(trail_color.r, trail_color.g, trail_color.b, 0.05),
					Color(trail_color.r, trail_color.g, trail_color.b, 0.45)
				])

	trail_line.gradient = gradient

	var width_curve: Curve = Curve.new()

	width_curve.min_value = 0.0
	width_curve.max_value = 1.0

	match trail_style:
		TrailStyle.FADE_AND_SCALE:
			width_curve.add_point(Vector2(0.0, trail_min_scale))
			width_curve.add_point(Vector2(1.0, 1.0))

		TrailStyle.GHOST:
			width_curve.add_point(Vector2(0.0, 0.8))
			width_curve.add_point(Vector2(1.0, 1.0))

		_:
			width_curve.add_point(Vector2(0.0, 1.0))
			width_curve.add_point(Vector2(1.0, 1.0))

	trail_line.width_curve = width_curve

func get_trail_alpha(progress: float) -> float:
	match trail_style:
		TrailStyle.FADE:
			return lerp(
				trail_min_alpha,
				1.0,
				progress
			)

		TrailStyle.SOLID:
			return 1.0

		TrailStyle.FADE_AND_SCALE:
			return lerp(
				trail_min_alpha,
				1.0,
				progress
			)

		TrailStyle.GHOST:
			return lerp(
				0.05,
				0.45,
				progress
			)

	return 1.0


func get_trail_scale(progress: float) -> float:
	match trail_style:
		TrailStyle.FADE_AND_SCALE:
			return lerp(
				trail_min_scale,
				1.0,
				progress
			)

		TrailStyle.GHOST:
			return lerp(
				0.8,
				1.0,
				progress
			)

	return 1.0


func update_squash_stretch(delta: float) -> void:
	if not squash_stretch_enabled:
		#update_collision_scale()
		return

	var currently_on_floor: bool = is_on_floor()
	if heavy_ground_active:
		squash_visual.scale = squash_visual.scale.lerp(
			squash_base_scale * heavy_ground_scale,
			min(heavy_squash_speed * delta, 1.0)
		)
		was_on_floor = currently_on_floor
		#return
	if heavy_ground_active:
		if heavy_jump_timer.is_stopped() and not heavy_jump_ready:
			heavy_jump_timer.start()
	else:
		if not heavy_jump_ready:
			heavy_jump_timer.stop()
	var normal_interpolation: float = min(
		squash_speed * delta,
		1.0
	)

	if state == PlayerState.DASHING:
		squash_visual.scale = squash_visual.scale.lerp(
			squash_base_scale * dash_scale,
			min(dash_squash_speed * delta, 1.0)
		)

		was_on_floor = currently_on_floor
		#update_collision_scale()
		return

	if state == PlayerState.DASH_PREPARING:
		squash_visual.scale = squash_visual.scale.lerp(
			squash_base_scale,
			min(squash_speed * delta, 1.0)
		)

		was_on_floor = currently_on_floor
		#update_collision_scale()
		return

	if currently_on_floor and not was_on_floor:
		var impact_strength: float = clamp(
			abs(last_vertical_velocity) *
			landing_velocity_scale,
			0.0,
			1.0
		)

		var impact_scale: Vector2 = Vector2(
			lerp(
				1.0,
				landing_scale.x,
				impact_strength
			),
			lerp(
				1.0,
				landing_scale.y,
				impact_strength
			)
		)

		impact_scale.x = min(
			impact_scale.x,
			max_landing_squash
		)

		landing_scale_current = impact_scale
		landing_timer = landing_duration

		jumping_visual = false

	if landing_timer > 0.0:
		landing_timer -= delta

		squash_visual.scale = squash_visual.scale.lerp(
			squash_base_scale * landing_scale_current,
			normal_interpolation
		)

		was_on_floor = currently_on_floor
		#update_collision_scale()
		return

	if jump_squash_timer > 0.0:
		jump_squash_timer -= delta

		squash_visual.scale = squash_visual.scale.lerp(
			squash_base_scale * jump_squash_scale,
			min(jump_squash_speed * delta, 1.0)
		)

		was_on_floor = currently_on_floor
		return

	if jumping_visual and not currently_on_floor:
		squash_visual.scale = squash_visual.scale.lerp(
			squash_base_scale * jump_scale,
			min(jump_stretch_speed * delta, 1.0)
		)

		if velocity.y > 0.0:
			jumping_visual = false

		was_on_floor = currently_on_floor
		#update_collision_scale()
		return

	if not currently_on_floor:
		if velocity.y > 0.0:
			var desired_scale: Vector2 = (
				squash_base_scale *
				fall_scale
			)

			squash_visual.scale = squash_visual.scale.lerp(
				desired_scale,
				normal_interpolation
			)
		else:
			squash_visual.scale = squash_visual.scale.lerp(
				squash_base_scale,
				normal_interpolation
			)

		was_on_floor = currently_on_floor
		#update_collision_scale()
		return

	squash_visual.scale = squash_visual.scale.lerp(
		squash_base_scale,
		min(landing_recovery_speed * delta, 1.0)
	)
	#collision_shape.scale = squash_visual.scale / squash_base_scale
	was_on_floor = currently_on_floor



func process_normal_state(time_delta: float) -> void:

	if is_mechanic_enabled(3) and Input.is_action_just_pressed("grapple"):
		try_grapple()

		if grapple_active:
			return
	if not is_on_floor():
		coyote_time -= time_delta

		var current_gravity: float = gravity

		if velocity.y > 0.0:
			current_gravity = fall_gravity
		if is_mechanic_enabled(3) and Input.is_action_just_pressed("grapple"):
			try_grapple()
		heavy_active = (true if is_mechanic_enabled(4) and Input.is_action_pressed("heavy") else false)

		if heavy_active and velocity.y > 0.0:
			current_gravity *= heavy_fall_multiplier
			heavy_fall_active = true

		if (
			is_mechanic_enabled(0)
			and jump_holding
			and Input.is_action_pressed("space")
			and jump_hold_time < JUMP_HOLD_MAX
			and velocity.dot(gravity_direction) < 0.0
		):
			current_gravity *= JUMP_HOLD_GRAVITY
			jump_hold_time += time_delta
		else:
			jump_holding = false

		velocity += gravity_direction * current_gravity * time_delta

	else:
		Max_jump = df_Max_jump
		Max_dash = df_Max_dash
		coyote_time = COYOTE_DURATION

		var normal: Vector2 = get_floor_normal()

		if abs(normal.x) > 0.001:
			var tangent: Vector2 = Vector2(
				normal.y,
				-normal.x
			)

			var gravity_vector: Vector2 = Vector2(
				0.0,
				gravity
			)

			var slope_gravity: Vector2 = (
				tangent *
				gravity_vector.dot(tangent)
			)

			velocity += slope_gravity * time_delta

	if not can_move:
		return

	if is_mechanic_enabled(1) and Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
		return

	if jump_locked:
		process_horizontal_movement(time_delta)
		return

	if is_mechanic_enabled(0) and Input.is_action_just_pressed("space"):
		if coyote_time > 0:
			if heavy_jump_ready:
				velocity.y = heavy_jump_velocity
				heavy_jump_ready = false
				heavy_jump_timer.stop()
			else:
				velocity.y = JUMP_VELOCITY
			#velocity.y = JUMP_VELOCITY
			jump_hold_time = 0.0
			jump_holding = true
			coyote_time = 0.0
			jumping = true

			jump_squash_timer = jump_squash_duration
			jumping_visual = true

			play_jump()

		elif Max_jump > 0:
			if heavy_jump_ready:
				velocity.y = heavy_jump_velocity
				heavy_jump_ready = false
				heavy_jump_timer.stop()
			else:
				velocity.y = JUMP_VELOCITY
			#velocity.y = JUMP_VELOCITY
			jump_hold_time = 0.0
			jump_holding = true
			Max_jump -= 1
			jumping = true

			jump_squash_timer = jump_squash_duration
			jumping_visual = true

			play_jump()

	process_horizontal_movement(time_delta)



func process_horizontal_movement(time_delta: float) -> void:
	var dir: float = get_control_axis()
	#var dir: float = Input.get_axis(
	#	"left",
	#	"right"
	#)

	if dir:
		velocity.x = move_toward(
			velocity.x,
			dir * MAX_SPEED,
			ACCELERATION * time_delta
		)
	else:
		var friction: float = FRICTION

		if is_on_floor():
			var normal: Vector2 = get_floor_normal()

			if abs(normal.x) > 0.001:
				friction *= 0.2

		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * time_delta
		)

	velocity.x = clamp(
		velocity.x,
		-MAX_SLOPE_SPEED,
		MAX_SLOPE_SPEED
	)


func start_dash() -> void:
	if not is_mechanic_enabled(1):
		return

	if not can_dash:
		return

	if Max_dash <= 0:
		return

	var input_direction: float = get_control_axis()
	#var input_direction: float = Input.get_axis(
	#	"left",
	#	"right"
	#)

	if input_direction != 0.0:
		dash_direction = Vector2(
			input_direction,
			0.0
		).normalized()
	elif abs(velocity.x) > 0.1:
		dash_direction = Vector2(
			sign(velocity.x),
			0.0
		).normalized()
	else:
		dash_direction = last_direction

	velocity = Vector2.ZERO

	dash_preparing = true
	dash_prepare_timer = dash_prepare_duration

	change_state(PlayerState.DASH_PREPARING)


func process_dash_prepare_state(delta: float) -> void:
	if not is_mechanic_enabled(1) or not can_move:
		dash_preparing = false
		change_state(PlayerState.NORMAL)
		return


	velocity = Vector2.ZERO



	dash_prepare_timer -= delta

	if dash_prepare_timer <= 0.0:
		begin_dash()


func begin_dash() -> void:
	if not is_mechanic_enabled(1) or not can_move:
		dash_preparing = false
		change_state(PlayerState.NORMAL)
		return

	if Max_dash <= 0:
		dash_preparing = false
		change_state(PlayerState.NORMAL)
		return

	dash_preparing = false
	dashing = true
	dash_timer = dash_duration
	Max_dash -= 1
	dash_audio.play()

	if is_on_floor():
		var floor_normal: Vector2 = get_floor_normal()
		var dash_velocity: Vector2 = Vector2(dash_direction.x, 0.0)
		dash_velocity = dash_velocity.slide(floor_normal)

		if dash_velocity.length() > 0.0:
			dash_direction = dash_velocity.normalized()
			velocity = dash_direction * dash_speed
	else:
		velocity = dash_direction * dash_speed

	dash_particles.restart()
	dash_particles.emitting = true

	change_state(PlayerState.DASHING)


func process_dashing_state(time_delta: float) -> void:
	if not is_mechanic_enabled(1) or not can_move:
		dashing = false
		dash_particles.emitting = false
		change_state(PlayerState.NORMAL)
		return

	if is_mechanic_enabled(0) and Input.is_action_just_pressed("space"):
		dashing = false
		dash_timer = 0.0

		dash_particles.emitting = false

		if Max_jump > 0:
			velocity.x = 0.0
			velocity.y = JUMP_VELOCITY
			jump_hold_time = 0.0
			jump_holding = true

			Max_jump = max(Max_jump - 1, 0)

			jumping = true
			orb = false

			jump_squash_timer = jump_squash_duration
			jumping_visual = true

			play_jump()

			change_state(PlayerState.NORMAL)
			return

	dash_timer -= time_delta

	if is_on_floor():
		var floor_normal: Vector2 = get_floor_normal()
		var dash_velocity: Vector2 = Vector2(dash_direction.x, 0.0)
		dash_velocity = dash_velocity.slide(floor_normal)

		if dash_velocity.length() > 0.0:
			dash_direction = dash_velocity.normalized()
			velocity = dash_direction * dash_speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = dash_direction * dash_speed

	if dash_timer <= 0.0:
		dashing = false
		dash_particles.emitting = false

		velocity.x = dash_direction.x * MAX_SPEED

		change_state(PlayerState.NORMAL)


func process_orb_state(time_delta: float) -> void:
	if not can_move:
		return

	
	if not is_on_floor():
		coyote_time -= time_delta

		var current_gravity: float = gravity

		if velocity.y > 0.0:
			current_gravity = fall_gravity

		if (
			is_mechanic_enabled(0)
			and jump_holding
			and Input.is_action_pressed("space")
			and jump_hold_time < JUMP_HOLD_MAX
			and velocity.dot(gravity_direction) < 0.0
		):
			current_gravity *= JUMP_HOLD_GRAVITY
			jump_hold_time += time_delta
		else:
			jump_holding = false

		velocity += gravity_direction * current_gravity * time_delta
	else:
		Max_jump = df_Max_jump
		Max_dash = df_Max_dash
		coyote_time = COYOTE_DURATION
		jump_holding = false

		var normal: Vector2 = get_floor_normal()

		if abs(normal.x) > 0.001:
			var tangent: Vector2 = Vector2(
				normal.y,
				-normal.x
			)

			var gravity_vector: Vector2 = Vector2(
				0.0,
				gravity
			)

			var slope_gravity: Vector2 = (
				tangent *
				gravity_vector.dot(tangent)
			)

			velocity += slope_gravity * time_delta


	if is_mechanic_enabled(1) and Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
		return

	if is_mechanic_enabled(2) and Input.is_action_just_pressed("space"):
		velocity.y = JUMP_VELOCITY * 1.5
		jump_hold_time = 0.0
		jump_holding = true
		velocity.x *= 0.7
		jumping = true

		jump_squash_timer = jump_squash_duration
		jumping_visual = true

		play_jump()
		Points.points -= 500
		return
	if is_mechanic_enabled(2) and Input.is_action_just_pressed("act") and can_act:
		#can_act = false
		cant_act_count -= 1
		start_orb_jump()
	return

	process_horizontal_movement(time_delta)
	


func process_dead_state(_time_delta: float) -> void:
	velocity = Vector2.ZERO


func die() -> void:
	if state == PlayerState.DEAD:
		return

	change_state(PlayerState.DEAD)

	$GPUParticles2D.emitting = true

	await get_tree().create_timer(0.5).timeout

	Global.muertes += 1
	visible = false
	Deathscreen._toggle()

func play_jump() -> void:
	jump_audio.pitch_scale = randf_range(
		3.8,
		4.2
	)
#
	jump_audio.play()
#
	#dash_particles.restart()
	dash_particles.emitting = true
#
	await get_tree().create_timer(0.25).timeout
#
	if not dashing and not dash_preparing:
		dash_particles.emitting = false
	pass

func can_dash_process() -> void:
	can_dash = false

	if not is_mechanic_enabled(1):
		return

	if dash_locked:
		return

	if state == PlayerState.DEAD:
		return

	if state == PlayerState.DASHING:
		return

	if state == PlayerState.DASH_PREPARING:
		return

	if Max_dash <= 0:
		return

	can_dash = true
func apply_global_config() -> void:
	sprite.texture = Global.player_sprite_texture
	outline_sprite.texture = Global.player_outline_texture
	sprite_rotation = Global.player_sprite_rotation

	squash_stretch_enabled = Global.player_squash_stretch_enabled

	fall_scale = Global.player_fall_scale
	jump_scale = Global.player_jump_scale
	jump_squash_scale = Global.player_jump_squash_scale
	dash_scale = Global.player_dash_scale
	landing_scale = Global.player_landing_scale

	squash_speed = Global.player_squash_speed
	jump_stretch_speed = Global.player_jump_stretch_speed
	jump_squash_speed = Global.player_jump_squash_speed
	landing_recovery_speed = Global.player_landing_recovery_speed
	dash_squash_speed = Global.player_dash_squash_speed

	jump_squash_duration = Global.player_jump_squash_duration
	landing_duration = Global.player_landing_duration
	landing_velocity_scale = Global.player_landing_velocity_scale
	max_landing_squash = Global.player_max_landing_squash

	rainbow_trail = Global.player_rainbow_trail
	rainbow_speed = Global.player_rainbow_speed
	target_scale = Global.player_target_scale
	#trail_enabled = Global.player_trail_enabled

	trail_type = Global.player_trail_type
	trail_style = Global.player_trail_style

	trail_length = Global.player_trail_length
	trail_spacing = Global.player_trail_spacing
	trail_min_alpha = Global.player_trail_min_alpha
	trail_min_scale = Global.player_trail_min_scale
	trail_width = Global.player_trail_width
	trail_color = Global.player_trail_color
	trail_texture = Global.player_trail_texture
	trail_round_caps = Global.player_trail_round_caps
func start_orb_jump() -> void:
	if not is_mechanic_enabled(2):
		return

	if state != PlayerState.ORB:
		return

	velocity = Vector2.ZERO
	orb_prepare_timer = orb_prepare_duration

	change_state(PlayerState.ORB_PREPARING)
	Points.points += 100


func process_orb_prepare_state(delta: float) -> void:
	if not is_mechanic_enabled(2):
		orb_prepare_timer = 0.0
		change_state(PlayerState.NORMAL)
		return

	velocity = Vector2.ZERO

	orb_prepare_timer -= delta

	if orb_prepare_timer <= 0.0:
		velocity.y = JUMP_VELOCITY * orb_jump_multiplier
		jump_hold_time = 0.0
		jump_holding = true
		velocity.x = 0.0

		jumping = true
		jump_squash_timer = jump_squash_duration
		jumping_visual = true

		play_jump()
		change_state(PlayerState.NORMAL)

var grapple_margin: float = 320

func try_grapple() -> void:
	if not is_mechanic_enabled(3):
		return

	var best_anchor: Node2D = get_grapple_target()

	if best_anchor == null:
		return

	grapple_anchor = best_anchor.global_position
	grapple_length = global_position.distance_to(grapple_anchor) + grapple_extra_length
	grapple_active = true
	change_state(PlayerState.SWING)
func process_swing_state(time_delta: float) -> void:
	if not is_mechanic_enabled(3) or not grapple_active:
		release_grapple()
		change_state(PlayerState.NORMAL)
		return

	# Interrumpir la cuerda con dash
	#if Input.is_action_just_pressed("dash"):
		#release_grapple()
		#change_state(PlayerState.DASH_PREPARING)
		#return


	if Input.is_action_just_pressed("act"):
		release_grapple()
		change_state(PlayerState.ORB_PREPARING)
		return


	if Input.is_action_just_pressed("grapple") or Input.is_action_just_pressed("dash"):
		release_grapple()
		return


	if is_mechanic_enabled(0) and Input.is_action_just_pressed("space"):
		velocity += -gravity_direction.normalized() * grapple_jump_boost
		release_grapple()
		return

	var anchor_offset: Vector2 = global_position - grapple_anchor
	var distance: float = anchor_offset.length()

	velocity += gravity_direction * swing_gravity * time_delta
	var horizontal_input: float = get_control_axis()
	#var horizontal_input: float = Input.get_axis("left", "right")

	if distance > 0.001:
		var radial_direction: Vector2 = anchor_offset / distance
		var tangent_direction: Vector2 = Vector2(radial_direction.y, -radial_direction.x)

		velocity += tangent_direction * horizontal_input * swing_acceleration * time_delta

		if distance >= grapple_length:
			global_position = grapple_anchor + radial_direction * grapple_length

			var radial_velocity: float = velocity.dot(radial_direction)

			if radial_velocity > 0.0:
				velocity -= radial_direction * radial_velocity
func update_grapple_rope() -> void:
	if not grapple_active or not is_mechanic_enabled(3):
		rope_line.visible = false
		rope_line.clear_points()
		return

	rope_line.visible = true
	rope_line.clear_points()

	var rope_start: Vector2 = rope_line.to_local(global_position)
	var rope_end: Vector2 = rope_line.to_local(grapple_anchor)
	var distance: float = global_position.distance_to(grapple_anchor)
	var slack: float = max(grapple_length - distance, 0.0)
	var sag: float = min(slack * 0.5, 120.0)

	for i: int in range(grapple_rope_segments + 1):
		var t: float = float(i) / float(grapple_rope_segments)
		var point: Vector2 = rope_start.lerp(rope_end, t)
		point += rope_line.to_local(global_position + gravity_direction.normalized() * sag * 4.0 * t * (1.0 - t)) - rope_start
		rope_line.add_point(point)


func release_grapple() -> void:
	grapple_active = false
	rope_line.clear_points()
	rope_line.visible = false
	if state == PlayerState.SWING:
		change_state(PlayerState.NORMAL)
func get_grapple_target() -> Node2D:
	if not is_mechanic_enabled(3):
		return null

	var mouse_position: Vector2 = get_global_mouse_position()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var best_anchor: Node2D = null
	var best_distance: float = grapple_margin

	for point: Node in get_tree().get_nodes_in_group("grapple_points"):
		if not point is Node2D:
			continue

		var anchor: Node2D = point as Node2D
		var distance_to_mouse: float = anchor.global_position.distance_to(mouse_position)

		if distance_to_mouse > best_distance:
			continue

		if global_position.distance_to(anchor.global_position) > grapple_range:
			continue

		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position,
			anchor.global_position
		)
		query.exclude = [get_rid()]
		query.collide_with_areas = true
		query.collide_with_bodies = true

		var result: Dictionary = space_state.intersect_ray(query)

		if not result.is_empty():
			var hit_node: Node = result["collider"] as Node

			while hit_node != null and hit_node != anchor:
				hit_node = hit_node.get_parent()

			if hit_node != anchor:
				continue

		best_distance = distance_to_mouse
		best_anchor = anchor

	return best_anchor


func _on_heavy_jump_timer_timeout() -> void:
	heavy_jump_ready = true
func update_collision_scale() -> void:
	collision_shape.scale = squash_visual.scale / squash_base_scale
func get_control_axis() -> float:
	return Input.get_axis("left", "right")
