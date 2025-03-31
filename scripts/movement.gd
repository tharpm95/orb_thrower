extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FALL_THRESHOLD = -100.0
const LAUNCH_FORCE = 10.0

@onready var camera = $Camera3D

var start_position: Vector3
var log_timer: float = 0.0 # Timer for logging
var log_interval: float = 1.0 # Interval to log character position

# Load sphere mesh scene
@export var sphere_scene: PackedScene = preload("res://scenes/orb.tscn")

func _ready():
	start_position = global_transform.origin

func _physics_process(delta: float) -> void:
	# Update the timer
	log_timer += delta
	if log_timer >= log_interval:
		print("Character position: ", global_transform.origin)
		print("Camera direction: ", camera.basis.z.normalized()) # Log camera direction
		log_timer = 0.0 # Reset the timer

	if global_transform.origin.y < FALL_THRESHOLD:
		_resurrect()

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if Input.is_action_just_pressed("Space") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("W"):
		input_dir.z -= 1
	if Input.is_action_pressed("S"):
		input_dir.z += 1
	if Input.is_action_pressed("A"):
		input_dir.x -= 1
	if Input.is_action_pressed("D"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()

	# Rotate the direction vector based on the camera's orientation
	var camera_basis = camera.basis
	var direction = (camera_basis.x * input_dir.x) + (camera_basis.z * input_dir.z)
	direction = direction.normalized()
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	move_and_slide()

func _input(event):
	if event.is_action_pressed("LM"):
		print("Left mouse pressed: Launching sphere")  # Debugging print
		launch_sphere()

func launch_sphere():
	if sphere_scene:
		var sphere_instance = sphere_scene.instantiate()
		add_child(sphere_instance)

		# Position the sphere slightly in front of the camera, in the direction the camera is facing
		var start_position = camera.global_transform.origin - camera.basis.z * 2  # Adjusted to move forward in the camera's view
		sphere_instance.global_transform.origin = start_position
		print("Sphere initialized at: ", sphere_instance.global_transform.origin)

		# Hardcoded impulse direction
		var hardcoded_direction = Vector3(1, 0, 1).normalized()
		print("Applying impulse: ", hardcoded_direction)

		# Apply force to the sphere in this hardcoded direction
		var sphere_rigidbody = sphere_instance as RigidBody3D
		if sphere_rigidbody:
			sphere_rigidbody.apply_central_impulse(hardcoded_direction * LAUNCH_FORCE)
			print("Sphere velocity after impulse: ", sphere_rigidbody.linear_velocity)

func _resurrect():
	global_transform.origin = start_position
	velocity = Vector3.ZERO
