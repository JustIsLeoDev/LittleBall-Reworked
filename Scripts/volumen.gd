
extends Control

@onready var label: Label = $Label

var master_index: int = 0
var left_db: float = -100.0
var right_db: float = -100.0

func _ready() -> void:
	master_index = AudioServer.get_bus_index("Master")

func _process(_delta: float) -> void:
	left_db = AudioServer.get_bus_peak_volume_left_db(master_index, 0)
	right_db = AudioServer.get_bus_peak_volume_right_db(master_index, 0)

	label.text = "L: %.1f dB | R: %.1f dB" % [
		left_db,
		right_db
	]
