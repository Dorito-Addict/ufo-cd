extends Node

@onready var label = $Label
@onready var timer = $Timer

func _ready():
	timer.start()
	
func _process(_delta: float) -> void:
	label.text = str(int(timer.time_left))
	
	if timer.time_left < 1:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://Menu.tscn")
