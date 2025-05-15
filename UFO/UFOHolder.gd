extends Node3D

var timeStone = preload("res://Objects/TimeStone.tscn")

func timeStoneCheck():
	await get_tree().process_frame
	if get_child_count() == 1:	
		var instance = timeStone.instantiate()
		get_tree().root.get_node("Node3D").add_child(instance)
		
		get_node("/root/Node3D/SoundFX/TimeStone").play()
		queue_free()
