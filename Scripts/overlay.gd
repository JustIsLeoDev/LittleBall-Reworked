
extends CanvasLayer

@export var color_normal: Color = Color(0.18, 0.18, 0.18, 0.65)
@export var color_presionado: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var velocidad_transicion: float = 10.0

@onready var w: Label = $Control/HBoxContainer/W
@onready var a: Label = $Control/HBoxContainer/A
@onready var s: Label = $Control/HBoxContainer/S
@onready var d: Label = $Control/HBoxContainer/D
@onready var r: Label = $Control/HBoxContainer/R
@onready var space: Label = $Control/HBoxContainer/SPACE
@onready var shift: Label = $Control/HBoxContainer/SHIFT
@onready var lmb: Label = $Control/HBoxContainer/LEFTCLICK
@onready var rmb: Label = $Control/HBoxContainer/RIGHTCLICK


func _ready() -> void:
	w.text = "W"
	a.text = "A"
	s.text = "S"
	d.text = "D"
	r.text = "R"
	space.text = "SPACE"
	shift.text = "SHIFT"
	lmb.text = "LMB"
	rmb.text = "RMB"

	for tecla: Label in [w, a, s, d, r, space, shift, lmb, rmb]:
		tecla.modulate = color_normal


func _process(delta: float) -> void:
	var velocidad: float = 1.0 - exp(-velocidad_transicion * delta)

	actualizar_tecla(w, Input.is_key_pressed(KEY_W), velocidad)
	actualizar_tecla(a, Input.is_key_pressed(KEY_A), velocidad)
	actualizar_tecla(s, Input.is_key_pressed(KEY_S), velocidad)
	actualizar_tecla(d, Input.is_key_pressed(KEY_D), velocidad)
	actualizar_tecla(r, Input.is_key_pressed(KEY_R), velocidad)
	actualizar_tecla(space, Input.is_key_pressed(KEY_SPACE), velocidad)
	actualizar_tecla(shift, Input.is_key_pressed(KEY_SHIFT), velocidad)

	actualizar_tecla(lmb, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), velocidad)
	actualizar_tecla(rmb, Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT), velocidad)


func actualizar_tecla(tecla: Label, presionada: bool, velocidad: float) -> void:
	var color_objetivo: Color = color_presionado if presionada else color_normal

	tecla.modulate = tecla.modulate.lerp(color_objetivo, velocidad)
