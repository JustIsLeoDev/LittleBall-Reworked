
extends Control

@onready var update_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var http_request: HTTPRequest = $HTTPRequest

const RELEASE_URL: String = "https://api.github.com/repos/JustIsLeoDev/LittleBallVersions/releases/latest"

func _ready() -> void:
	http_request.request_completed.connect(
		_on_update_check_completed
	)

	check_for_updates()

func check_for_updates() -> void:
	var headers: PackedStringArray = [
		"User-Agent: LittleBall"
	]

	var error: Error = http_request.request(
		RELEASE_URL,
		headers,
		HTTPClient.METHOD_GET
	)

	if error != OK:
		return

func _on_update_check_completed(
	result: int,
	response_code: int,
	#headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		return

	if response_code != 200:
		return

	var body_text: String = body.get_string_from_utf8()
	var json: JSON = JSON.new()

	var parse_error: Error = json.parse(body_text)

	if parse_error != OK:
		return

	var data: Variant = json.data

	if not data is Dictionary:
		return

	var release: Dictionary = data

	var latest_version: String = str(
		release.get("tag_name", "")
	)

	if latest_version.is_empty():
		return

	var comparison: int = compare_versions(
		Global.version,
		latest_version
	)

	if comparison < 0:
		show_update_dialog(latest_version)
	elif comparison > 0:
		show_future_message()

func compare_versions(
	first: String,
	second: String
) -> int:
	var first_parts: PackedStringArray = first.split(".")
	var second_parts: PackedStringArray = second.split(".")

	var max_length: int = max(
		first_parts.size(),
		second_parts.size()
	)

	for i: int in range(max_length):
		var first_number: int = 0
		var second_number: int = 0

		if i < first_parts.size():
			first_number = int(first_parts[i])

		if i < second_parts.size():
			second_number = int(second_parts[i])

		if first_number < second_number:
			return -1

		if first_number > second_number:
			return 1

	return 0

func show_update_dialog(new_version: String) -> void:
	update_dialog.title = tr("LABELUPDATERTITULO")

	update_dialog.dialog_text = (
		tr("TEXTUPDATERVERSIONDISPONIBLE") + "\n\n"
		+ tr("LABELUPDATERVERSIONACTUAL") + " "
		+ Global.version
		+ "\n"
		+ tr("LABELUPDATERVERSIONNUEVA") + " "
		+ new_version
	)

	update_dialog.ok_button_text = tr("BUTTONUPDATERACTUALIZAR")
	update_dialog.cancel_button_text = tr("BUTTONUPDATERCANCELAR")

	if update_dialog.confirmed.is_connected(_on_future_message_selected):
		update_dialog.confirmed.disconnect(_on_future_message_selected)

	if update_dialog.canceled.is_connected(_on_future_message_selected):
		update_dialog.canceled.disconnect(_on_future_message_selected)

	if not update_dialog.confirmed.is_connected(_on_confirmation_dialog_confirmed):
		update_dialog.confirmed.connect(_on_confirmation_dialog_confirmed)

	if not update_dialog.canceled.is_connected(_on_confirmation_dialog_canceled):
		update_dialog.canceled.connect(_on_confirmation_dialog_canceled)

	update_dialog.popup_centered()

func show_future_message() -> void:
	update_dialog.title = "LittleBall"
	update_dialog.dialog_text = tr("TEXTUPDATERFUTUROPREGUNTA")

	update_dialog.ok_button_text = tr("BUTTONUPDATERFUTUROSI")
	update_dialog.cancel_button_text = tr("BUTTONUPDATERFUTUROSI")

	if update_dialog.confirmed.is_connected(_on_confirmation_dialog_confirmed):
		update_dialog.confirmed.disconnect(_on_confirmation_dialog_confirmed)

	if update_dialog.canceled.is_connected(_on_confirmation_dialog_canceled):
		update_dialog.canceled.disconnect(_on_confirmation_dialog_canceled)

	if not update_dialog.confirmed.is_connected(_on_future_message_selected):
		update_dialog.confirmed.connect(_on_future_message_selected)

	if not update_dialog.canceled.is_connected(_on_future_message_selected):
		update_dialog.canceled.connect(_on_future_message_selected)

	update_dialog.popup_centered()

func _on_future_message_selected() -> void:
	if update_dialog.confirmed.is_connected(_on_future_message_selected):
		update_dialog.confirmed.disconnect(_on_future_message_selected)

	if update_dialog.canceled.is_connected(_on_future_message_selected):
		update_dialog.canceled.disconnect(_on_future_message_selected)

	update_dialog.title = "LittleBall"
	update_dialog.dialog_text = tr("TEXTUPDATERFUTURORESPUESTA")

	update_dialog.ok_button_text = tr("BUTTONUPDATERFUTUROOK")
	update_dialog.cancel_button_text = tr("BUTTONUPDATERFUTUROELAOS")

	update_dialog.popup_centered()

func _on_confirmation_dialog_confirmed() -> void:
	var game_path: String = OS.get_executable_path()
	var game_directory: String = game_path.get_base_dir()
	var updater_path: String = game_directory.path_join("updater.exe")

	if not FileAccess.file_exists(updater_path):
		push_error(
			tr("ERRORUPDATERNOENCONTRADO") + " "
			+ updater_path
		)
		return

	var process_id: int = OS.create_process(
		updater_path,
		[
			"--version",
			Global.version,
			"--game",
			game_path
		]
	)

	if process_id == -1:
		push_error(tr("ERRORUPDATERNOINICIADO"))
		return

	get_tree().quit()

func _on_confirmation_dialog_canceled() -> void:
	pass
