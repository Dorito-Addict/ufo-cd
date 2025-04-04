extends Area3D

@export var speed = 0.25
var player = null
var selectedPosition = null
func _ready():
	body_entered.connect(on_body_entered)
	player = get_node("/root/Node3D/Player")
	selectedPosition = player.position
	
func _process(delta):
	position += global_position.direction_to(selectedPosition) * delta * speed * 5 * 60

func on_body_entered(body: Node3D) -> void:
	if body is PlayerEntity:
		body.velocity.x *= -1
		body.velocity.z *= -1
		queue_free()
