
extends Node

const APPLICATION_ID: String = "1563344131483242617"

var _is_ready: bool = false

var _start_timestamp: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicializar_presence()


func _inicializar_presence() -> void:
	if Engine.has_singleton("DiscordRPC") or has_node("/root/DiscordRPC"):
		DiscordRPC.app_id = int(APPLICATION_ID)

		_start_timestamp = int(Time.get_unix_time_from_system())

		actualizar_presence(
			"Menu",
			"En el menú",
			"icon_main",
			"LittleBall"
		)

		_is_ready = true
	else:
		push_warning("El autoload global 'DiscordRPC' del plugin no está activo o configurado.")


func actualizar_presence(
	details: String = "LittleBall",
	state: String = "",
	large_image: String = "icon_main",
	large_image_text: String = "LittleBall",
	small_image: String = "",
	small_image_text: String = "",
	restablecer_tiempo: bool = false
) -> void:
	if not (Engine.has_singleton("DiscordRPC") or has_node("/root/DiscordRPC")):
		return

	if restablecer_tiempo or _start_timestamp == 0:
		_start_timestamp = int(Time.get_unix_time_from_system())

	DiscordRPC.details = details
	DiscordRPC.state = state

	DiscordRPC.large_image = large_image
	DiscordRPC.large_image_text = large_image_text

	DiscordRPC.small_image = small_image
	DiscordRPC.small_image_text = small_image_text

	DiscordRPC.start_timestamp = _start_timestamp

	DiscordRPC.refresh()


func cambiar_detalles(details: String) -> void:
	actualizar_presence(
		details,
		DiscordRPC.state,
		DiscordRPC.large_image,
		DiscordRPC.large_image_text,
		DiscordRPC.small_image,
		DiscordRPC.small_image_text
	)


func cambiar_estado(state: String) -> void:
	actualizar_presence(
		DiscordRPC.details,
		state,
		DiscordRPC.large_image,
		DiscordRPC.large_image_text,
		DiscordRPC.small_image,
		DiscordRPC.small_image_text
	)


func cambiar_imagen_grande(
	image: String,
	texto: String = "LittleBall"
) -> void:
	actualizar_presence(
		DiscordRPC.details,
		DiscordRPC.state,
		image,
		texto,
		DiscordRPC.small_image,
		DiscordRPC.small_image_text
	)


func cambiar_imagen_pequena(
	image: String = "",
	texto: String = ""
) -> void:
	actualizar_presence(
		DiscordRPC.details,
		DiscordRPC.state,
		DiscordRPC.large_image,
		DiscordRPC.large_image_text,
		image,
		texto
	)


func reiniciar_tiempo() -> void:
	_start_timestamp = int(Time.get_unix_time_from_system())

	actualizar_presence(
		DiscordRPC.details,
		DiscordRPC.state,
		DiscordRPC.large_image,
		DiscordRPC.large_image_text,
		DiscordRPC.small_image,
		DiscordRPC.small_image_text
	)
