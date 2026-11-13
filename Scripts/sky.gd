
extends Control

const SKY_COLORS: Dictionary = {
	0.0: Color("#080D26"),
	4.0: Color("#111B3B"),
	5.0: Color("#49365F"),
	6.0: Color("#F08A79"),
	7.0: Color("#F6C5A0"),
	8.0: Color("#80BDEB"),
	12.0: Color("#55B8F5"),
	16.0: Color("#78B5E8"),
	17.0: Color("#ECA17C"),
	18.0: Color("#F07870"),
	19.0: Color("#79547F"),
	20.0: Color("#29345E"),
	22.0: Color("#101832"),
	24.0: Color("#080D26")
}

@export var transition_speed: float = 2.0

@onready var sky: ColorRect = $Sky
@onready var debug_bar: HBoxContainer = $DebugBar
@onready var time_slider: HSlider = $TimeSlider
@onready var time_label: Label = $DebugBar/TimeLabel
@onready var debug_time_button: CheckButton = $DebugTimeButton

var current_color: Color = Color("#080D26")
var target_color: Color = Color("#080D26")
var debug_hour: float = 12.0


func _ready() -> void:
	debug_time_button.button_pressed = Global.debug
	debug_time_button.toggled.connect(_on_debug_time_toggled)
	time_slider.min_value = 0.0
	time_slider.max_value = 24.0
	time_slider.step = 0.25

	debug_hour = get_system_hour()
	time_slider.value = debug_hour

	time_slider.value_changed.connect(_on_time_changed)

	update_debug_bar()
	update_sky()


func _process(delta: float) -> void:
	var hour: float = debug_hour if Global.debug else get_system_hour()

	target_color = get_sky_color(hour)

	current_color = current_color.lerp(
		target_color,
		1.0 - exp(-transition_speed * delta)
	)

	sky.color = current_color

	update_debug_bar()


func get_system_hour() -> float:
	var time: Dictionary = Time.get_time_dict_from_system()

	return (
		float(time["hour"])
		+ float(time["minute"]) / 60.0
		+ float(time["second"]) / 3600.0
	)


func get_sky_color(hour: float) -> Color:
	var hours: Array = SKY_COLORS.keys()
	hours.sort()

	for i: int in range(hours.size() - 1):
		var start_hour: float = hours[i]
		var end_hour: float = hours[i + 1]

		if hour >= start_hour and hour <= end_hour:
			var start_color: Color = SKY_COLORS[start_hour]
			var end_color: Color = SKY_COLORS[end_hour]

			var weight: float = (
				(hour - start_hour) / (end_hour - start_hour)
			)

			return start_color.lerp(end_color, weight)

	return SKY_COLORS[24.0]


func _on_time_changed(value: float) -> void:
	debug_hour = value


func update_sky() -> void:
	var hour: float = debug_hour if Global.debug else get_system_hour()
	target_color = get_sky_color(hour)


func update_debug_bar() -> void:
	debug_bar.visible = Global.debug

	if Global.debug:
		var hour: float = time_slider.value
		var hours: int = int(floor(hour))
		var minutes: int = int(round((hour - float(hours)) * 60.0))

		if minutes >= 60:
			hours += 1
			minutes = 0

		time_label.text = "%02d:%02d" % [hours, minutes]
func _on_debug_time_toggled(enabled: bool) -> void:
	#Global.debug = enabled

	if enabled:
		debug_hour = get_system_hour()
		time_slider.value = debug_hour

	update_sky()
	update_debug_bar()
