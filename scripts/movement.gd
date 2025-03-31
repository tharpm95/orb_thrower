extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FALL_THRESHOLD = -100.0
const BASE_LAUNCH_FORCE = 5.0
const MAX_LAUNCH_FORCE = 50.0
const SPHERE_LIFETIME = 2.0 # Lifetime of a sphere in seconds
const MAX_CHARGE_TIME = 2.0 # Time in seconds to reach full charge

@onready var camera = $Camera3D
@onready var charge_bar = $HUD/ChargeProgressBar

var start_position: Vector3
var log_timer: float = 0.0 # Timer for logging
var log_interval: float = 1.0 # Interval to log character position
var charge_time: float = 0.0 # Time the left mouse button is held

# Load sphere mesh scene
@export var sphere_scene: PackedScene = preload("res://scenes/orb.tscn")

func _ready():
	start_position = global_transform.origin
	charge_bar.visible = false  # Start with the charge bar hidden
	charge_bar.value = 0.0

	# Create a StyleBoxFlat for customizing the background
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0, 0, 0, 0.5)  # Semi-transparent black background

	# Apply the style box for the background
	charge_bar.add_theme_stylebox_override("background", style_bg)

	# Create and apply a StyleBoxFlat for the foreground (fill)
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.5, 0, 0.5, 1)  # Purple for the foreground/fill

	charge_bar.add_theme_stylebox_override("fg", style_fg)

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

func _process(delta: float):
	if Input.is_action_pressed("LM"):
		charge_time += delta
		charge_bar.visible = true
		charge_bar.value = min(charge_time / MAX_CHARGE_TIME, 1.0) * 100
	else:
		charge_time = 0.0
		charge_bar.visible = false
		charge_bar.value = 0.0

func _input(event):
	if event.is_action_released("LM"):
		launch_sphere()

func launch_sphere():
	if sphere_scene:
		var sphere_instance = sphere_scene.instantiate()
		get_tree().root.add_child(sphere_instance)

		var start_position = camera.global_transform.origin - camera.basis.z * 2
		sphere_instance.global_transform.origin = start_position

		var sphere_rigidbody = sphere_instance.get_node("RigidBody3D") if sphere_instance else null
		if sphere_rigidbody:
			var camera_forward = -camera.basis.z.normalized()
			var launch_force = BASE_LAUNCH_FORCE + (charge_time / MAX_CHARGE_TIME) * (MAX_LAUNCH_FORCE - BASE_LAUNCH_FORCE)
			sphere_rigidbody.apply_impulse(camera_forward * launch_force)

			# Start a timer to remove the sphere after its lifetime
			var sphere_timer = Timer.new()
			sphere_timer.one_shot = true
			sphere_timer.wait_time = SPHERE_LIFETIME
			sphere_instance.add_child(sphere_timer)
			sphere_timer.start()

			# Connect the timeout to remove the sphere
			sphere_timer.timeout.connect(func() -> void:
				sphere_instance.queue_free()
			)

func _resurrect():
	global_transform.origin = start_position
	velocity = Vector3.ZERO
