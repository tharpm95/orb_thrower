extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FALL_THRESHOLD = -100.0

@onready var camera = $Camera3D
@onready var raycast = $RayCast3D

var start_position: Vector3
var log_timer: float = 0.0 # Timer for logging
var log_interval: float = 1.0 # Interval to log character position

@export var max_distance: float = 500.0 # Maximum length of the line

# Load the particle effect scene
@export var impact_effect_scene: PackedScene = preload("res://scenes/fire_particles.tscn")

func _ready():
	start_position = global_transform.origin
	raycast.enabled = false

func _physics_process(delta: float) -> void:
	# Update the timer
	log_timer += delta
	if log_timer >= log_interval:
		print("Character position: ", global_transform.origin)
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
		print("Left mouse pressed: Emitting particles")  # Debugging print
		emit_particles()

func emit_particles():
	# Calculate the camera direction as a unit vector
	var camera_direction = camera.basis.z.normalized()
	
	var base_vector = Vector3(-5, 0, -5)
	
	# Calculate the appropriate position vector using the camera direction
	# This scales the base_vector taking into account the direction from the camera
	var particle_position = Vector3(
		base_vector.x * camera_direction.x,
		base_vector.y * camera_direction.y,
		base_vector.z * camera_direction.z
	)
	
	print("Emitting particles at calculated position:", particle_position)
	spawn_impact_effect(particle_position)

func spawn_impact_effect(position):
	if impact_effect_scene:
		print("Spawning Impact Effect at position: ", position)  # Debugging print
		var impact_instance = impact_effect_scene.instantiate()
		impact_instance.global_transform.origin = position

		if impact_instance.has_node("GPUParticles3D"):
			var particles = impact_instance.get_node("GPUParticles3D")
			particles.emitting = true  # Ensure particles start emitting

		add_child(impact_instance)
		await get_tree().create_timer(1.0).timeout
		impact_instance.queue_free()

func _resurrect():
	global_transform.origin = start_position
	velocity = Vector3.ZERO
	
	#The particles are showing up always relative to the location of the character but they actually need to show up relative to the direction the camera is facing (always in front of the camera). Start just by logging the direction of the camera in the same interval as the character position is logged. Represent the direction as a unit vector which is logged
