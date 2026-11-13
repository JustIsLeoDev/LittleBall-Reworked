
extends CanvasLayer

var points: int = 0
var show_points: int = 0

var timer_running: bool = false
var elapsed_time: float = 0.0

var points_animation_speed: float = 350.0
var points_color_speed: float = 5.0
var points_scale_speed: float = 8.0

var points_label: RichTextLabel

var current_points_color: Color = Color.WHITE
var target_points_color: Color = Color.WHITE

var points_scale: float = 1.0
var target_points_scale: float = 1.0


func _ready() -> void:
	points_label = $Control/RichTextLabel
	points_label.pivot_offset = points_label.size / 2.0

	visible = false


func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta
	$Control3/RichTextLabel.text = tr("LABELPOINTSMUERTES") + ": " + str(Global.muertes)
	if show_points != points:
		var difference: int = points - show_points
		var change: int = maxi(
			int(points_animation_speed * delta),
			1
		)

		if abs(difference) <= change:
			show_points = points
		else:
			show_points += change * sign(difference)

		target_points_scale = 1.15

		if difference > 0:
			target_points_color = Color.LIME_GREEN
		else:
			target_points_color = Color.TOMATO
	else:
		target_points_color = Color.WHITE
		target_points_scale = 1.0

	current_points_color = current_points_color.lerp(
		target_points_color,
		clampf(points_color_speed * delta, 0.0, 1.0)
	)

	points_scale = lerpf(
		points_scale,
		target_points_scale,
		clampf(points_scale_speed * delta, 0.0, 1.0)
	)

	points_label.text = str(show_points)
	points_label.add_theme_color_override(
		"default_color",
		current_points_color
	)
	points_label.scale = Vector2.ONE * points_scale

	$Control2/RichTextLabel.text = _get_time_text()


func _start_timer() -> void:
	
	timer_running = true
	elapsed_time = 0.0


func _stop_timer() -> void:
	timer_running = false


func _end_level() -> void:
	_stop_timer()
	Global.muertes = 0
	Global.finish_level(points, elapsed_time)
	visible = false


func _get_time_text() -> String:
	var total_milliseconds: int = int(elapsed_time * 1000.0)

	var milliseconds: int = total_milliseconds % 1000
	var total_seconds: int = total_milliseconds / 1000

	var seconds: int = total_seconds % 60
	var total_minutes: int = total_seconds / 60

	var minutes: int = total_minutes % 60
	var total_hours: int = total_minutes / 60

	var hours: int = total_hours % 24
	var total_days: int = total_hours / 24

	var days: int = total_days % 7
	var total_weeks: int = total_days / 7

	var weeks: int = total_weeks % 4
	var months: int = total_weeks / 4

	var years: int = months / 12
	months %= 12

	if years > 0:
		return "%dy %dmo %dw %dd %02d:%02d:%02d:%03d" % [
			years, months, weeks, days,
			hours, minutes, seconds, milliseconds
		]

	if months > 0:
		return "%dmo %dw %dd %02d:%02d:%02d:%03d" % [
			months, weeks, days,
			hours, minutes, seconds, milliseconds
		]

	if total_days > 0:
		return "%dd %02d:%02d:%02d:%03d" % [
			total_days, hours, minutes, seconds, milliseconds
		]

	if total_hours > 0:
		return "%02d:%02d:%02d:%03d" % [
			hours, minutes, seconds, milliseconds
		]

	return "%02d:%02d:%03d" % [
		minutes, seconds, milliseconds
	]


func _toggle_visible() -> void:
	visible = not visible
func _cancel_level() -> void:
	timer_running = false
	elapsed_time = 0.0
	points = 0
	show_points = 0
	visible = false
func is_timer_running() -> bool:
	return timer_running
func _reset_key():
	if Global.dificulty == "masoquista":
		if points > 0:
			points = 0
	else:
		points = 0
func _reset():
	Global.muertes = 0
	points = 0
