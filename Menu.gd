extends Control

@export var rotateSpeed = 0.35
@onready var level_sub_viewport: SubViewport = $SubViewportContainer/SubViewport

func _ready():
	$VBoxContainer/Normal.connect(&"mouse_entered", func(): _display_level(&"Normal"))
	$VBoxContainer/Normal.connect(&"mouse_exited", func(): _display_level(&""))

	$VBoxContainer/Encore.connect(&"mouse_entered", func(): _display_level(&"Encore"))
	$VBoxContainer/Encore.connect(&"mouse_exited", func(): _display_level(&""))

	$VBoxContainer/ERZ.connect(&"mouse_entered", func(): _display_level(&"Extra"))
	$VBoxContainer/ERZ.connect(&"mouse_exited", func(): _display_level(&""))
		
	_display_level(&"")

func _display_level(id: StringName):
	for child: Node3D in level_sub_viewport.get_children() as Array[Node3D]:
		child.visible = (child.name == id)

func _on_normal_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/Normal.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_encore_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/Encore.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_erz_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/Extra.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
