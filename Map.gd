class_name MapEntity extends GridMap

const BOUNCE_TILES: PackedInt32Array = [0, 2]
const SPRING_TILES = 3
const SPEED_TILES = 4

@export var bounce_wall_shape: Shape3D = null
@export var other_wall_shape: Shape3D = null

func _ready() -> void:
	cell_center_x = false
	cell_center_z = false
	
	var spring_pad_body: Area3D = Area3D.new()
	spring_pad_body.name = &"SpringPad"
	add_child(spring_pad_body)
	spring_pad_body.body_entered.connect(on_spring_entered)
	
	var bounce_wall_body: StaticBody3D = StaticBody3D.new()
	bounce_wall_body.name = &"BounceWall"
	add_child(bounce_wall_body)

	for cell_coord: Vector3i in self.get_used_cells():
		var cell_id: int = self.get_cell_item(cell_coord)
		if cell_id == GridMap.INVALID_CELL_ITEM:
			continue

		if BOUNCE_TILES.has(cell_id):
			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			bounce_wall_body.add_child(collision_shape)
			collision_shape.global_position = Vector3(
				float(cell_coord.x) * cell_size.x,
				0.0,
				float(cell_coord.z) * cell_size.z
			)

			collision_shape.shape = bounce_wall_shape
		
		if cell_id == SPRING_TILES:
			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			spring_pad_body.add_child(collision_shape)
			collision_shape.global_position = Vector3(
				float(cell_coord.x) * cell_size.x,
				0.0,
				float(cell_coord.z) * cell_size.z
			)

			collision_shape.shape = other_wall_shape
		
		if cell_id == SPEED_TILES:
			var boost_pad_body: BoostPadArea = BoostPadArea.new()
			add_child(boost_pad_body)
			boost_pad_body.body_entered.connect(
					func(body: Node3D) -> void: on_boost_pad_entered(boost_pad_body, body))
			
			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			boost_pad_body.add_child(collision_shape)
			collision_shape.global_position = Vector3(
				float(cell_coord.x) * cell_size.x,
				0.0,
				float(cell_coord.z) * cell_size.z
			)

			boost_pad_body.boost_vec = self.get_cell_item_basis(cell_coord) * Vector3.FORWARD

			collision_shape.shape = other_wall_shape


func on_spring_entered(body: Node3D) -> void:
	if body is PlayerEntity:
		if body.grounded:
			body.velocity.y = 15.0 * 2
		else:
			body.velocity.y = 15.0
			body.hasDash = true
		$"../SoundFX/Spring".play()

func on_boost_pad_entered(area: BoostPadArea, body: Node3D) -> void:
	if body is PlayerEntity:
		body.velocity += area.boost_vec * 20.0
		body.time_since_boost = 16
		$"../SoundFX/BoostPad".play()
		
