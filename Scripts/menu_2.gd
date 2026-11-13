extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.can_pause = false
	Global.can_reset = false
	Global.actual_level = "Menu"
	Global.level_text = ""
	Global.is_in_level = false
	DiscordManager.actualizar_presence(
	"LittleBall",
	"Selector de modo",
	"icon_main",
    "LittleBall"
)
