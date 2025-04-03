extends Control


func _on_normal_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/Normal.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_encore_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/Encore.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
