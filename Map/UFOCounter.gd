extends Label

func _process(delta: float) -> void:
	if get_node('/root/Node3D').has_node("UFOs"):
		var ufoHolder = get_node("/root/Node3D/UFOs") as Node3D
		
		var count = ufoHolder.get_child_count()
		
		text = str(count - 1)
	else:
		text = ""
