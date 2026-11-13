
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PM.info_print("Player entró en la orbe: " + str(body))
		body.orb = true
	else:
		PM.warning_print("La orbe detectó otro cuerpo: " + str(body))


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PM.info_print("Player salió de la orbe: " + str(body))
		body.orb = false
