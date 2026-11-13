extends Node

const GAME_FOLDER: String = "LittleBallFunc"
const LOG_FOLDER_NAME: String = "logs"
const SESSION_FILE_NAME: String = "session_count.dat"

var base_path: String = ""
var log_folder: String = ""
var session_file: String = ""
var log_file_path: String = ""

var session_number: int = 0


func _ready() -> void:
	_initialize_logger()


func _initialize_logger() -> void:
	var appdata_path: String = OS.get_environment("LOCALAPPDATA")

	if appdata_path.is_empty():
		error_print("No se encontró LOCALAPPDATA.")
		return

	base_path = appdata_path.path_join(GAME_FOLDER)
	log_folder = base_path.path_join(LOG_FOLDER_NAME)
	session_file = base_path.path_join(SESSION_FILE_NAME)

	print("========================================")
	print("LOGGER")
	print("LOCALAPPDATA: " + appdata_path)
	print("BASE: " + base_path)
	print("LOGS: " + log_folder)
	print("SESSION: " + session_file)
	print("========================================")

	var directory_error: Error = DirAccess.make_dir_recursive_absolute(log_folder)

	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error(
			"No se pudo crear la carpeta de logs. Error: " +
			str(directory_error)
		)
		return

	_load_session_count()

	session_number += 1

	_save_session_count()

	var datetime: Dictionary = Time.get_datetime_dict_from_system()

	log_file_path = log_folder.path_join(
		"%04d-%02d-%02d.log" % [
			datetime.year,
			datetime.month,
			datetime.day
		]
	)

	_create_log_file()

	_write_session_header(datetime)


func _create_log_file() -> void:
	if FileAccess.file_exists(log_file_path):
		return

	var file: FileAccess = FileAccess.open(
		log_file_path,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"No se pudo crear el LOG: " +
			log_file_path +
			" | Error: " +
			str(FileAccess.get_open_error())
		)
		return

	file.store_string("")
	file.flush()
	file.close()

	print("LOG CREADO: " + log_file_path)


func _write_session_header(datetime: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(
		log_file_path,
		FileAccess.READ_WRITE
	)

	if file == null:
		push_error(
			"No se pudo abrir el LOG: " +
			log_file_path +
			" | Error: " +
			str(FileAccess.get_open_error())
		)
		return

	file.seek_end()

	file.store_line("")
	file.store_line("==================================================")
	file.store_line("INICIO DE SESION")
	file.store_line("Fecha: %04d-%02d-%02d" % [
		datetime.year,
		datetime.month,
		datetime.day
	])
	file.store_line("Hora: %02d:%02d:%02d" % [
		datetime.hour,
		datetime.minute,
		datetime.second
	])
	file.store_line("Sesion #: %d" % session_number)
	file.store_line("==================================================")
	file.store_line("")

	file.flush()
	file.close()


func _load_session_count() -> void:
	if not FileAccess.file_exists(session_file):
		session_number = 0
		return

	var file: FileAccess = FileAccess.open(
		session_file,
		FileAccess.READ
	)

	if file == null:
		session_number = 0
		return

	var content: String = file.get_as_text()

	if content.is_valid_int():
		session_number = content.to_int()
	else:
		session_number = 0

	file.close()


func _save_session_count() -> void:
	var file: FileAccess = FileAccess.open(
		session_file,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"No se pudo guardar session_count.dat. Error: " +
			str(FileAccess.get_open_error())
		)
		return

	file.store_string(str(session_number))
	file.flush()
	file.close()


func _write_log(level: String, message: String) -> void:
	if log_file_path.is_empty():
		return

	var datetime: Dictionary = Time.get_datetime_dict_from_system()

	var line: String = "[%02d:%02d:%02d] [%s] %s" % [
		datetime.hour,
		datetime.minute,
		datetime.second,
		level,
		message
	]

	var file: FileAccess = FileAccess.open(
		log_file_path,
		FileAccess.READ_WRITE
	)

	if file == null:
		push_error(
			"No se pudo escribir en el LOG. Error: " +
			str(FileAccess.get_open_error())
		)
		return

	file.seek_end()
	file.store_line(line)
	file.flush()
	file.close()


func normal_print(message: String) -> void:
	print(message)
	_write_log("LOG", message)


func info_print(message: String) -> void:
	print_rich(
		"[color=aqua]INFO " + message + "[/color] (PM)"
	)

	_write_log("INFO", message)


func error_print(message: String) -> void:
	print_rich(
		"[color=red]ERROR " + message + "[/color] (PM)"
	)

	_write_log("ERROR", message)


func satisfactory_print(message: String) -> void:
	print_rich(
		"[color=green]OK " + message + "[/color] (PM)"
	)

	_write_log("OK", message)


func warning_print(message: String) -> void:
	print_rich(
		"[color=yellow]WARNING " + message + "[/color] (PM)"
	)

	_write_log("WARNING", message)
func comment_print(message: String) -> void:
	print_rich(
		"[color=#FF00EA]Comment " + message + "[/color] (PM)"
	)

	_write_log("WARNING", message)
