extends CharacterBody3D

@onready var mapSize : float = 50 # This should be 1/2th of the width of the map
@onready var randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))

@export var speed : float = 12.5
@export var texture : Texture2D 
var attackCounter = 0

func _process(delta):
	#if (abs(randomPos.x - global_position.x) <= 5 and abs(randomPos.z - global_position.z) <= 5):
		#randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
		#attackCounter = 3
	#else:
		#var direction = randomPos - global_position
		#direction = direction.normalized()
		#velocity = global_position.direction_to(randomPos) * delta * speed
		#
		#move_and_collide(velocity)
	
	
	var player = get_node("/root/Node3D/Player")
	velocity = global_position.direction_to(player.position) * delta * speed * 2
	move_and_collide(velocity)
		

func _ready():
	$Sprite3D.texture = texture
	$Area3D.body_entered.connect(on_body_entered)

func on_body_entered(body: Node3D) -> void:
	if body is PlayerEntity:
		var sound_destroy: AudioStreamPlayer = get_node("/root/Node3D/SoundFX/Destroy") as AudioStreamPlayer
		sound_destroy.play()
		
		body.velocity *= -1 * 0.5
		body.hasDash = true
