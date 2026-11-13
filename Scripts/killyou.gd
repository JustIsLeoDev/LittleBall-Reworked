
extends Node2D

@export var speed: float = 10.0
@export var camera: Camera2D
@export var horizontal: bool = true
@export var thickness: float = 300.0
@export var offset_from_edge: float = 150.0
@export var collision_offset_y: float = 15.0

enum LAVAMODE {
	left,
	right,
	up,
	down,
	stop
}

@export var mode: LAVAMODE = LAVAMODE.up

@onready var area: Area2D = $Area2D
@onready var sprite: TextureRect = $Area2D/TextureRect
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

var bounds: Rect2
var left: float
var right: float
var up: float
var down: float


func _ready() -> void:
	update_size()


func _process(delta: float) -> void:
	update_bounds()
	update_size()

	if mode == LAVAMODE.stop:
		return

	match mode:
		LAVAMODE.up:
			global_position.x = camera.get_screen_center_position().x

			if global_position.y > up - offset_from_edge:
				global_position.y -= speed * delta * 30.0

		LAVAMODE.down:
			global_position.x = camera.get_screen_center_position().x

			if global_position.y < down + offset_from_edge:
				global_position.y += speed * delta * 30.0

		LAVAMODE.left:
			global_position.y = camera.get_screen_center_position().y

			if global_position.x > left - offset_from_edge:
				global_position.x -= speed * delta * 30.0

		LAVAMODE.right:
			global_position.y = camera.get_screen_center_position().y

			if global_position.x < right + offset_from_edge:
				global_position.x += speed * delta * 30.0


func update_bounds() -> void:
	bounds = get_visible_bounds()

	left = bounds.position.x
	right = bounds.end.x
	up = bounds.position.y
	down = bounds.end.y


func get_visible_bounds() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var visible_size: Vector2 = viewport_size / camera.zoom
	var center: Vector2 = camera.get_screen_center_position()

	return Rect2(
		center - visible_size / 2.0,
		visible_size
	)



func update_size() -> void:
	update_bounds()

	var visible_size: Vector2 = bounds.size
	var size: Vector2

	if horizontal:
		size = Vector2(
			visible_size.x,
			thickness
		)
	else:
		size = Vector2(
			thickness,
			visible_size.y + offset_from_edge * 2.0
		)

	area.position = Vector2.ZERO

	sprite.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sprite.position = -size / 2.0
	sprite.size = size

	var rect_shape: RectangleShape2D = collision.shape as RectangleShape2D

	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		collision.shape = rect_shape
	elif not rect_shape.resource_local_to_scene:
		rect_shape = rect_shape.duplicate()
		collision.shape = rect_shape

	collision.position = Vector2(
		0.0,
		collision_offset_y
	)

	rect_shape.size = size
