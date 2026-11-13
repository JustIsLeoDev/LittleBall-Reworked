extends CanvasLayer

@onready var language_selector: OptionButton = $Control2/OptionButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/Label.text = "Version: " + str(Global.version)
	Global.can_pause = false
	Global.pause = false
	Global.can_reset = false
	Global.actual_level = "Menu"
	Global.level_text = ""
	Global.is_in_level = false
	DiscordManager.actualizar_presence(
	"LittleBall",
	"En el menú principal",
	"icon_main",
    "LittleBall"
)
	language_selector.select(Global.indice_lan)
	pass # Replace with function body.





func _on_play_pressed() -> void:
	PM.info_print("Play button")
	#get_tree().change_scene_to_file("res://Scenes/Stage1LVL1.tscn")
	get_tree().change_scene_to_file("res://Scenes/Menu2.tscn")
	reiniciar_valores()

func _on_quit_pressed() -> void:
	PM.info_print("Quit button")
	get_tree().quit()

func _on_estadisticas_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/estadisticas.tscn")
func reiniciar_valores():
	Global.muertes = 0
	Global.can_pause = true


func _on_option_button_item_selected(index: int) -> void:
	Global.language_item_sel(index)
