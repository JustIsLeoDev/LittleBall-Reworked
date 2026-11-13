extends Node2D

@export var listener: Node2D
@export var audio: AudioStreamPlayer2D
@export var max_distance: float = 500.0

func _process(_delta: float) -> void:
	if not listener or not audio:
		return

	var difference := global_position.x - listener.global_position.x

	var pan := difference / max_distance
	pan = clamp(pan, -1.0, 1.0)

	audio.panning_strength = pan
