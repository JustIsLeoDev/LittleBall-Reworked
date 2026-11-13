extends CanvasLayer

const SCENES_PATH := "res://Scenes/"

var selector_ui: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if Global.get("debug") == true and event.is_action_pressed("DebugMenu"):
		if selector_ui == null:
			_setup_room_selector()
		else:
			selector_ui.visible = not selector_ui.visible

func _setup_room_selector() -> void:
	selector_ui = Control.new()
	selector_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selector_ui.mouse_filter = Control.MOUSE_FILTER_STOP 
	get_tree().root.add_child(selector_ui)

	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 10
	panel.offset_top = 10
	panel.custom_minimum_size = Vector2(250, 300)
	selector_ui.add_child(panel)

	var vbox_main = VBoxContainer.new()
	panel.add_child(vbox_main)

	var label = Label.new()
	label.text = "--- SELECTOR DE SALAS ---"
	vbox_main.add_child(label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox_main.add_child(scroll)

	var vbox_scenes = VBoxContainer.new()
	vbox_scenes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox_scenes)

	var scenes := _get_scene_files(SCENES_PATH)
	for scene_name in scenes:
		var btn = Button.new()
		btn.text = scene_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var path = SCENES_PATH + scene_name
		btn.pressed.connect(func(): 
			selector_ui.queue_free()
			selector_ui = null
			_change_scene(path)
		)
		vbox_scenes.add_child(btn)

func _get_scene_files(path: String) -> Array:
	var scenes: Array = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				scenes.append(file_name)
			file_name = dir.get_next()
	return scenes

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
	queue_free()
