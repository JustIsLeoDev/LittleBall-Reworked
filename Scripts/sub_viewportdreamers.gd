extends SubViewport
func _ready() -> void:
	get_viewport().size_changed.connect(_on_size_changed)
	_update_viewport_size()

func _on_size_changed() -> void:
	_update_viewport_size()

func _update_viewport_size() -> void:
	size = get_viewport().get_visible_rect().size
