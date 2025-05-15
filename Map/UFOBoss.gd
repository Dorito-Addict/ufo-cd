extends CharacterBody3D

@onready var mapSize : float = 50 # This should be 1/2th of the width of the map
@onready var randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
@onready var bossSprite = $Sprite3D
@onready var phantomRuby = preload("res://Objects/PhantomRuby.tscn")

@export var speed : float = 12.5
@export var texture : Texture2D 
@export var attackDurationMax : float = 120.0
@export var attackDuration : float = 120.0
@export var health : int = 12

var attackCounter : int = 0
var bossProjectile = preload("res://UFO/BossProjectile.tscn")

func _ready():
	bossSprite.texture = load("res://UFO/UFOBoss.png")
	$Area3D.body_entered.connect(on_body_entered)
	
func _process(delta):
	velocity = Vector3(0,0,0)
	
	if health == 0:
		var instance = phantomRuby.instantiate()
		get_tree().root.get_node("Node3D").add_child(instance)
		
		queue_free()
	
	if attackCounter == 0: # Roaming Attack
		var player = get_node("/root/Node3D/Player")
		bossSprite.texture = load("res://UFO/UFOBoss.png")
		bossSprite.position = Vector3(0.0, 10.0, 0.0)
		$Area3D.position = Vector3(0.0, 13.25, 0.0)
		
		if (abs(randomPos.x - global_position.x) <= 5 and abs(randomPos.z - global_position.z) <= 5):
			randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
			attackCounter = 1
			attackDuration = attackDurationMax
		else:
			var direction = randomPos - global_position
			direction = direction.normalized()
			velocity = global_position.direction_to(Vector3(randomPos.x, player.global_position.y * 1, randomPos.z)) * delta * speed * 2
			
			if $Timer.time_left <= (1 * delta):
				var instance = bossProjectile.instantiate()
				get_tree().root.get_node("Node3D").add_child(instance)
			
			move_and_collide(velocity)
			
	if attackCounter == 1: # Chasing Attack
		bossSprite.position = Vector3(0.0, 4.0, 0.0)
		$Area3D.position = Vector3(0.0, 3.25, 0.0)
		bossSprite.texture = load("res://UFO/UFOBossGrab.png")
		var player = get_node("/root/Node3D/Player")
		
		randomPos = player.position
		if (attackDuration < 1.0):
			attackCounter = 0
			randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
		else:
			velocity = global_position.direction_to(randomPos) * delta * speed * 5
			move_and_collide(velocity)
			attackDuration -= 1 + delta 
			
func on_body_entered(body: Node3D) -> void:
	if body is PlayerEntity:
		
		if attackCounter == 1:
			body.velocity *= -1
			get_node("/root/Node3D/SoundFX/Bumper").play()
			attackDuration = 1
		else:
			body.velocity *= -1 * 0.5
			get_node("/root/Node3D/SoundFX/Destroy").play()
			health -= 1
		


#func attack_chase(delta):
	#var player = get_node("/root/Node3D/Player")
	#bossSprite.position = Vector3(0.0, 4.0, 0.0)
	#$Area3D.position = Vector3(0.0, 3.25, 0.0)
	#bossSprite.texture = load("res://UFO/UFOBossGrab.png")
	#randomPos = player.position
	#if (abs(randomPos.x - global_position.x) <= 0.5 and abs(randomPos.z - global_position.z) <= 0.5):
		#randomPos = player.position
	#else:
		#velocity = global_position.direction_to(randomPos) * delta * speed * 3
		#move_and_collide(velocity)
#
#func attack_roam(delta):
	#bossSprite.texture = load("res://UFO/UFOBoss.png")
	#bossSprite.position = Vector3(0.0, 10.0, 0.0)
	#$Area3D.position = Vector3(0.0, 13.25, 0.0)
	#randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
	#if (abs(randomPos.x - global_position.x) <= 5 and abs(randomPos.z - global_position.z) <= 5):
		#randomPos = Vector3(randf_range(-mapSize, mapSize), position.y, randf_range(-mapSize, mapSize))
	#else:
		#var direction = randomPos - global_position
		#direction = direction.normalized()
		#velocity = global_position.direction_to(randomPos) * delta * speed
		#
		#move_and_collide(velocity)
