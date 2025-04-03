class_name PlayerEntity extends CharacterBody3D

@onready var camera = $Head

@export var mouse_sens: float = 0.0015
@export var friction: float = 4
@export var accel: float = 12
# 4 for quake 2/3 40 for quake 1/source
@export var accel_air: float = 40
@export var top_speed_ground: float = 15
# 15 for quake 2/3, 2.5 for quake 1/source
@export var top_speed_air: float = 2.5
# linearize friction below this speed value
@export var lin_friction_speed: float = 10
@export var jump_force: float = 7
@export var projected_speed: float = 0
@export var extraVelMulti : float = 100
var grounded_prev: bool = true
var grounded: bool = true
var hasDash: bool = true
var wish_dir: Vector3 = Vector3.ZERO
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_since_boost: int = 0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://Menu.tscn")
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			self.rotate_y(-event.relative.x * mouse_sens)
			camera.rotate_x(-event.relative.y * mouse_sens)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func clip_velocity(normal: Vector3, overbounce: float, _delta) -> void:
	var correction_amount: float = 0
	var correction_dir: Vector3 = Vector3.ZERO
	var move_vector: Vector3 = get_velocity().normalized()
	
	correction_amount = move_vector.dot(normal) * overbounce
	
	correction_dir = normal * correction_amount
	velocity -= correction_dir
	# this is only here cause I have the gravity too high by default
	# with a gravity so high, I use this to account for it and allow surfing
	velocity.y -= correction_dir.y * (gravity/20)

func apply_friction(delta):
	var speed_scalar: float = 0
	var friction_curve: float = 0
	var speed_loss: float = 0
	var current_speed: float = 0
	
	# using projected velocity will lead to no friction being applied in certain scenarios
	# like if wish_dir is perpendicular
	# if wish_dir is obtuse from movement it would create negative friction and fling players
	current_speed = velocity.length()
	
	if(current_speed < 0.1):
		velocity.x = 0
		velocity.y = 0
		return
	
	friction_curve = clampf(current_speed, lin_friction_speed, INF)
	speed_loss = friction_curve * friction * delta * 1.0 if time_since_boost <= 0 else 0.0
	speed_scalar = clampf(current_speed - speed_loss, 0, INF)
	speed_scalar /= clampf(current_speed, 1, INF)
	
	velocity *= speed_scalar

func apply_acceleration(acceleration: float, top_speed: float, delta):
	var speed_remaining: float = 0
	var accel_final: float = 0
	
	speed_remaining = (top_speed * wish_dir.length()) - projected_speed
	
	if speed_remaining <= 0:
		return
	
	accel_final = acceleration * delta * top_speed
	
	clampf(accel_final, 0, speed_remaining)
	
	velocity.x += accel_final * wish_dir.x
	velocity.z += accel_final * wish_dir.z

func air_move(delta):
	if Input.is_action_just_pressed("jump") and hasDash == true and has_node("Head/Camera3D/Point"):
		$"../SoundFX/HyperRing".play()
		# $"../SoundFX/Charge".play()
		$"../SoundFX/BoostPad".play()
		$"../ColorRect".flash()
		velocity = (camera.global_transform.origin - $Head/Camera3D/Point.global_transform.origin).normalized() * extraVelMulti * -1
		hasDash = false

	apply_acceleration(accel_air, top_speed_air, delta)
	
	clip_velocity(get_wall_normal(), 14, delta)
	clip_velocity(get_floor_normal(), 14, delta)

	velocity.y -= gravity * delta

func ground_move(delta):
	floor_snap_length = 0.4
	apply_acceleration(accel, top_speed_ground, delta)
	
	if Input.is_action_pressed("jump"):
		velocity.y = jump_force
		if grounded:
			$"../SoundFX/Jump".play()
			hasDash = true
	
	if grounded == grounded_prev:
		apply_friction(delta)
	
	if is_on_wall:
		clip_velocity(get_wall_normal(), 1, delta)

func _physics_process(delta):
	if time_since_boost > 0: time_since_boost -= 1
	
	grounded_prev = grounded
	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "back")
	wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	projected_speed = (velocity * Vector3(1, 0, 1)).dot(wish_dir)
	
	
	# Add the gravity.
	if not is_on_floor():
		grounded = false
		air_move(delta)
	if is_on_floor():
		if velocity.y > 10:
			grounded = false
			air_move(delta)
		else:
			grounded = true
			ground_move(delta)
	
	move_and_slide()
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		
		if collision.get_collider().name == &"BounceWall":
			velocity = collision.get_normal() * 25.0
			velocity.y = 3
			$"../SoundFX/Bumper".play()
