extends Node3D

var rotateSpeed = null

func _ready():
	rotateSpeed = get_node("/root/Control").rotateSpeed

func _process(delta): 
	rotate_y(rotateSpeed * delta)
