extends Area3D

@export var speed = 0.25
var player = null
var ufoBoss = null
var selectedDir = null

func _ready():
	body_entered.connect(on_body_entered)
	
	ufoBoss = get_tree().root.get_node("Node3D/UFOBoss")
	player = get_tree().root.get_node("Node3D/Player")
	
	global_position = ufoBoss.global_position + Vector3(0, 6, 0)
	selectedDir = global_position.direction_to(player.position) + player.velocity * 0.01
	
	get_node("/root/Node3D/SoundFX/RubyAttack").play()
	
func _process(delta):
	position += selectedDir * delta * speed * 5 * 60

func on_body_entered(body: Node3D) -> void:
	if body is PlayerEntity:
		body.velocity = selectedDir * 150
		
		get_node("/root/Node3D/SoundFX/Bumper").play()
		# body.velocity.x *= -1
		# body.velocity.z *= -1
		
		queue_free()
	elif body is MapEntity:
		queue_free()
