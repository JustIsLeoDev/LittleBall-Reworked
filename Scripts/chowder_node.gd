extends Node2D

@export var pattern_texture: Texture2D
@export var pattern_scale: float = 32.0

var shader_material: ShaderMaterial


func _ready() -> void:
	clear_visuals()
	create_shader_material()
	generate_visuals()


func clear_visuals() -> void:
	for child: Node in get_children():
		if child is Polygon2D and child.name.begins_with("__generated_"):
			child.queue_free()


func create_shader_material() -> void:
	var shader: Shader = Shader.new()

	shader.code = """
	shader_type canvas_item;

	uniform sampler2D pattern : source_color, repeat_enable;
	uniform float pattern_scale = 32.0;

	varying vec2 world_pos;

	void vertex() {
		world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	}

	void fragment() {
		vec2 uv = world_pos / pattern_scale;
		COLOR = texture(pattern, uv);
	}
	"""

	shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	if pattern_texture:
		shader_material.set_shader_parameter(
			"pattern",
			pattern_texture
		)

	shader_material.set_shader_parameter(
		"pattern_scale",
		pattern_scale
	)


func generate_visuals() -> void:
	for child: Node in get_children_recursive(self):
		if child is CollisionShape2D:
			create_visual_for_shape(child)


func get_children_recursive(node: Node) -> Array:
	var result: Array = []

	for child: Node in node.get_children():
		result.append(child)
		result.append_array(get_children_recursive(child))

	return result


func create_visual_for_shape(collision: CollisionShape2D) -> void:
	if collision.shape == null:
		return

	var shape: Shape2D = collision.shape

	if shape is RectangleShape2D:
		create_rectangle(collision, shape)

	elif shape is CircleShape2D:
		create_circle(collision, shape)

	elif shape is CapsuleShape2D:
		create_capsule(collision, shape)

	elif shape is ConvexPolygonShape2D:
		create_convex_polygon(collision, shape)


func setup_visual(
	polygon: Polygon2D,
	collision: CollisionShape2D
) -> void:

	polygon.name = "__generated_" + collision.name
	polygon.material = shader_material
	polygon.z_index = -1

	var uvs: PackedVector2Array = PackedVector2Array()

	for point: Vector2 in polygon.polygon:
		uvs.append(point)

	polygon.uv = uvs


func create_rectangle(
	collision: CollisionShape2D,
	shape: RectangleShape2D
) -> void:

	var polygon: Polygon2D = Polygon2D.new()

	var half: Vector2 = shape.size / 2.0

	polygon.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2( half.x, -half.y),
		Vector2( half.x,  half.y),
		Vector2(-half.x,  half.y)
	])

	polygon.transform = collision.global_transform

	add_child(polygon)
	setup_visual(polygon, collision)


func create_circle(
	collision: CollisionShape2D,
	shape: CircleShape2D
) -> void:

	var polygon: Polygon2D = Polygon2D.new()

	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 64

	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)

		points.append(
			Vector2(cos(angle), sin(angle)) * shape.radius
		)

	polygon.polygon = points
	polygon.transform = collision.global_transform

	add_child(polygon)
	setup_visual(polygon, collision)


func create_capsule(
	collision: CollisionShape2D,
	shape: CapsuleShape2D
) -> void:

	var polygon: Polygon2D = Polygon2D.new()

	var points: PackedVector2Array = PackedVector2Array()

	var radius: float = shape.radius
	var height: float = shape.height
	var half_height: float = height / 2.0
	var segments: int = 32

	for i: int in range(segments + 1):
		var angle: float = PI + PI * float(i) / float(segments)

		points.append(
			Vector2(
				cos(angle) * radius,
				-half_height + sin(angle) * radius
			)
		)

	for i: int in range(segments + 1):
		var angle: float = PI * float(i) / float(segments)

		points.append(
			Vector2(
				cos(angle) * radius,
				half_height + sin(angle) * radius
			)
		)

	polygon.polygon = points
	polygon.transform = collision.global_transform

	add_child(polygon)
	setup_visual(polygon, collision)


func create_convex_polygon(
	collision: CollisionShape2D,
	shape: ConvexPolygonShape2D
) -> void:

	var polygon: Polygon2D = Polygon2D.new()

	polygon.polygon = shape.points
	polygon.transform = collision.global_transform

	add_child(polygon)
	setup_visual(polygon, collision)
