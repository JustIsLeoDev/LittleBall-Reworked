
extends Node

@export var bus_name: String = "Drug"

@export_group("Transition")
@export var transition_speed: float = 0.6

@export_group("Pitch")
@export_range(0.1, 2.0, 0.01) var minimum_pitch: float = 0.65
@export_range(0.0, 1.0, 0.01) var wobble_amount: float = 0.12
@export_range(0.0, 5.0, 0.01) var wobble_speed: float = 0.7

var drug_intensity: float = 0.0
var target_intensity: float = 0.0

var bus_index: int = -1
var pitch_effect: AudioEffectPitchShift

var elapsed_time: float = 0.0


func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_error("DrugManager: no existe el bus '%s'." % bus_name)
		set_process(false)
		return

	var effect_count: int = AudioServer.get_bus_effect_count(bus_index)

	for i: int in range(effect_count):
		var effect: AudioEffect = AudioServer.get_bus_effect(
			bus_index,
			i
		)

		if effect is AudioEffectPitchShift:
			pitch_effect = effect as AudioEffectPitchShift
			break

	if pitch_effect == null:
		push_error(
            "DrugManager: no se encontró AudioEffectPitchShift en Drug."
		)
		set_process(false)
		return

	pitch_effect.pitch_scale = 1.0


func _process(delta: float) -> void:
	elapsed_time += delta

	drug_intensity = move_toward(
		drug_intensity,
		target_intensity,
		transition_speed * delta
	)

	update_pitch()


func update_pitch() -> void:
	if pitch_effect == null:
		return

	var base_pitch: float = lerp(
		1.0,
		minimum_pitch,
		drug_intensity
	)

	var wobble: float = sin(
		elapsed_time * TAU * wobble_speed
	) * wobble_amount * drug_intensity

	pitch_effect.pitch_scale = clampf(
		base_pitch + wobble,
		0.1,
		2.0
	)


func set_drug(intensity: float) -> void:
	target_intensity = clampf(intensity, 0.0, 1.0)


func enable_drug() -> void:
	set_drug(1.0)


func disable_drug() -> void:
	set_drug(0.0)


func toggle_drug() -> void:
	if target_intensity > 0.0:
		disable_drug()
	else:
		enable_drug()


func set_transition_speed(speed: float) -> void:
	transition_speed = maxf(speed, 0.01)


func get_intensity() -> float:
	return drug_intensity
