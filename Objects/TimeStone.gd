extends Area3D
var UFOObject = load("res://UFO/UFOHolder.tscn")

func _ready():
	self.body_entered.connect(onStoneEntered)

func onStoneEntered(body: Node3D):
	if body is PlayerEntity:
		var instance = UFOObject.instantiate()
		get_tree().root.get_node("Node3D").add_child(instance)
		var sound_respawn: AudioStreamPlayer = get_node("/root/Node3D/SoundFX/UFORespawn") as AudioStreamPlayer
		sound_respawn.play()
		queue_free()
