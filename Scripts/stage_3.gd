extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.actual_level = "Level03"
	Global.can_pause = true
	Global.can_reset = true
	Global.level_text = "LVL3"
	Global.is_in_level = true
	if not Points.is_timer_running():
		Points._start_timer()
	if not Points.visible:
		Points._toggle_visible()
	MusicManager.try_play_music_por_ruta("res://Music/Tone1.ogg")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
