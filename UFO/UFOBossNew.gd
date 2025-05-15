extends CharacterBody3D

@onready var mapSize : float = 50 # This should be 1/2th of the width of the map
@onready var randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
@onready var bossSprite = $Sprite3D

@export var speed : float = 12.5
@export var texture : Texture2D 
@export var health : int = 12

func _ready():
	bossSprite.texture = load("res://UFO/UFOBoss.png")
	# $Area3D.body_entered.connect(on_body_entered)
	
