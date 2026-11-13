extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.actual_level = "Level02"
	Global.can_pause = true
	Global.can_reset = true
	Global.level_text = "LVL2"
	Global.is_in_level = true
	MusicManager.try_play_music_por_ruta("res://Music/S13(S20).ogg")
	if not Points.is_timer_running():
		Points._start_timer()
	if not Points.visible:
		Points._toggle_visible()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
