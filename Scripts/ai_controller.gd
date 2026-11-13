
extends Node

@export_category("Sensores")
@export var look_ahead: float = 100.0
@export var ground_check_depth: float = 350.0
@export var wall_check_distance: float = 65.0

@export_category("Aprendizaje")
@export var decision_interval: float = 0.2
@export var learning_rate: float = 0.15
@export var discount_factor: float = 0.9
@export var exploration: float = 0.3
@export var exploration_decay: float = 0.9995
@export var min_exploration: float = 0.03

const BRAIN_PATH: String = "user://littleball_ai.json"
const ACTION_COUNT: int = 4

var player: CharacterBody2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var q_table: Dictionary = {}
var observation: Dictionary = {}

var decision_timer: float = 0.0
var decisions: int = 0

var last_state: String = ""
var last_action: int = -1
var previous_x: float = 0.0

var current_action: int = 1


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	rng.randomize()
	load_brain()


func update_agent(delta: float) -> void:
	if not is_instance_valid(player):
		return

	player.ai_jump_just_pressed = false

	decision_timer -= delta

	if decision_timer > 0.0:
		return

	decision_timer = decision_interval

	var state_key: String = get_observation()

	var reward: float = -0.03

	if last_state != "":
		reward += (
			player.global_position.x - previous_x
		) * 0.02

		learn(
			last_state,
			last_action,
			reward,
			state_key
		)

	var action: int = choose_action(state_key)

	last_state = state_key
	last_action = action
	previous_x = player.global_position.x

	current_action = action

	# 0 = izquierda
	# 1 = derecha
	# 2 = saltar izquierda
	# 3 = saltar derecha

	match action:
		0:
			player.ai_direction = -1.0
		1:
			player.ai_direction = 1.0
		2:
			player.ai_direction = -1.0
		3:
			player.ai_direction = 1.0

	if action >= 2 and player.is_on_floor():
		player.ai_jump_just_pressed = true

	decisions += 1
	exploration = max(
		min_exploration,
		exploration * exploration_decay
	)

	if decisions % 20 == 0:
		save_brain()


func get_observation() -> String:
	var direction: float = player.ai_direction

	if direction == 0.0:
		direction = 1.0

	var ground_origin: Vector2 = (
		player.global_position
		+ Vector2(direction * look_ahead, 20.0)
	)

	var ground_hit: Dictionary = raycast(
		ground_origin,
		ground_origin + Vector2(0.0, ground_check_depth)
	)

	var wall_origin: Vector2 = (
		player.global_position + Vector2(0.0, -20.0)
	)

	var wall_hit: Dictionary = raycast(
		wall_origin,
		wall_origin + Vector2(direction * wall_check_distance, 0.0)
	)

	var platform_detected: bool = not ground_hit.is_empty()
	var wall_detected: bool = not wall_hit.is_empty()

	var vertical_state: int = 0

	if player.velocity.y < -30.0:
		vertical_state = -1
	elif player.velocity.y > 30.0:
		vertical_state = 1

	observation = {
		"platform_ahead": platform_detected,
		"wall_ahead": wall_detected,
		"on_floor": player.is_on_floor(),
		"vertical_state": vertical_state
	}

	return (
		str(int(platform_detected))
		+ str(int(wall_detected))
		+ str(int(player.is_on_floor()))
		+ str(vertical_state)
	)


func choose_action(state_key: String) -> int:
	var values: Array = get_q_values(state_key)

	if rng.randf() < exploration:
		return rng.randi_range(0, ACTION_COUNT - 1)

	var best_action: int = 0
	var best_value: float = -INF

	for i: int in range(ACTION_COUNT):
		if float(values[i]) > best_value:
			best_value = float(values[i])
			best_action = i

	return best_action


func learn(
	state_key: String,
	action: int,
	reward: float,
	next_state: String
) -> void:
	if action < 0:
		return

	var values: Array = get_q_values(state_key)
	var next_values: Array = get_q_values(next_state)

	var next_best: float = -INF

	for value: Variant in next_values:
		next_best = max(next_best, float(value))

	var old_value: float = float(values[action])

	var new_value: float = old_value + learning_rate * (
		reward
		+ discount_factor * next_best
		- old_value
	)

	values[action] = new_value
	q_table[state_key] = values


func get_q_values(state_key: String) -> Array:
	if not q_table.has(state_key):
		q_table[state_key] = [0.0, 0.0, 0.0, 0.0]

	var values: Array = q_table[state_key]
	return values


func register_death() -> void:
	if last_state != "" and last_action >= 0:
		learn(
			last_state,
			last_action,
			-100.0,
			last_state
		)

	last_state = ""
	last_action = -1

	save_brain()


func raycast(from: Vector2, to: Vector2) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = (
		PhysicsRayQueryParameters2D.create(
			from,
			to,
			player.collision_mask,
			[player.get_rid()]
		)
	)

	return player.get_world_2d().direct_space_state.intersect_ray(
		query
	)


func save_brain() -> void:
	var file: FileAccess = FileAccess.open(
		BRAIN_PATH,
		FileAccess.WRITE
	)

	if file == null:
		return

	file.store_string(JSON.stringify(q_table))
	file.close()


func load_brain() -> void:
	if not FileAccess.file_exists(BRAIN_PATH):
		return

	var file: FileAccess = FileAccess.open(
		BRAIN_PATH,
		FileAccess.READ
	)

	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		q_table = parsed
