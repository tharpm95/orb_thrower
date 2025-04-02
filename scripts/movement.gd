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
@onready var qubits_label = $HUD/QubitsLabel

var start_position: Vector3
var log_timer: float = 0.0 # Timer for logging
var log_interval: float = 1.0 # Interval to log character position
var charge_time: float = 0.0 # Time the left mouse button is held
var qubits_count: int = 0 # Initialize the qubits counter

# Load sphere mesh scene
@export var sphere_scene: PackedScene = preload("res://scenes/items/orb.tscn")

func _ready():
	start_position = global_transform.origin
	charge_bar.visible = true # Initially show the charge bar
	charge_bar.value = 100.0

	# Create a StyleBoxFlat for customizing the background
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0, 0, 0, 0.5) # Semi-transparent black background

	# Apply the style box for the background
	charge_bar.add_theme_stylebox_override("background", style_bg)

	# Create and apply a StyleBoxFlat for the foreground (fill)
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.5, 0, 0.5, 1) # Purple for the foreground/fill

	charge_bar.add_theme_stylebox_override("fg", style_fg)

	# Initialize qubits count display
	update_qubits_count()

func update_qubits_count():
	# Updates the visible qubits count on the HUD
	qubits_label.text = "Qubits: %d" % qubits_count

func _physics_process(delta: float) -> void:
	# Update the log timer
	log_timer += delta
	if log_timer >= log_interval:
		log_timer = 0.0 # Reset the timer

	# Check if the character has fallen below the threshold
	if global_transform.origin.y < FALL_THRESHOLD:
		_resurrect()

	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Jump if space is pressed and on floor
	if Input.is_action_just_pressed("Space") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Calculate input direction
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
	
	# Set velocity
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Move the character
	move_and_slide()

func _process(delta: float):
	# Update charge bar based on left mouse button press
	if Input.is_action_pressed("LM"):
		charge_time += delta
		charge_bar.visible = true
		charge_bar.value = min(charge_time / MAX_CHARGE_TIME, 1.0) * 100
	else:
		charge_time = 0.0
		charge_bar.visible = false
		charge_bar.value = 0.0

func _input(event):
	# Launch sphere upon releasing the left mouse button
	if event.is_action_released("LM"):
		launch_sphere()

func launch_sphere():
	# Instantiate and launch a sphere
	if sphere_scene:
		var sphere_instance = sphere_scene.instantiate()
		get_tree().root.add_child(sphere_instance)

		# Positioning the sphere
		start_position = camera.global_transform.origin - camera.basis.z * 2
		sphere_instance.global_transform.origin = start_position

		# Apply impulse to the sphere
		var sphere_rigidbody = sphere_instance.get_node("RigidBody3D") if sphere_instance else null
		if sphere_rigidbody:
			var camera_forward = -camera.basis.z.normalized()
			var launch_force = BASE_LAUNCH_FORCE + (charge_time / MAX_CHARGE_TIME) * (MAX_LAUNCH_FORCE - BASE_LAUNCH_FORCE)
			sphere_rigidbody.apply_impulse(camera_forward * launch_force)

			# Connect the sphere's `sphere_hit` signal to a handler with the sphere instance as additional argument
			sphere_instance.get_node("RigidBody3D/Area3D").connect("sphere_hit", Callable(self, "_on_sphere_hit").bind(sphere_instance))

			# Set timer to remove the sphere after its lifetime
			var sphere_timer = Timer.new()
			sphere_timer.one_shot = true
			sphere_timer.wait_time = SPHERE_LIFETIME
			sphere_instance.add_child(sphere_timer)
			sphere_timer.start()

			# Connect timeout signal to remove the sphere
			sphere_timer.timeout.connect(func() -> void:
				sphere_instance.queue_free()
			)

# In movement.gd

func _on_sphere_hit(being_instance, sphere_instance, _other):
	print("Being information acquired")
	increase_qubits_count()

	if being_instance:
		var progress_bar = being_instance.get_node("Control/VBoxContainer2/ProgressBar")
		if progress_bar:
			progress_bar.value = max(progress_bar.value - 10, 0)  # Adjust the decrement as necessary
		else:
			print("ProgressBar not found for the being_instance")

	if sphere_instance:
		sphere_instance.queue_free()

# Helper function to print node hierarchy
func print_hierarchy(node: Node, level: int = 0) -> void:
	var indent = ""
	for i in range(level):
		indent += "\t"
	print(indent + node.name)
	for child in node.get_children():
		print_hierarchy(child, level + 1)

func increase_qubits_count():
	# Increase qubits count and update display
	qubits_count += 1
	update_qubits_count()

func _resurrect():
	# Reset position and velocity after fall
	global_transform.origin = start_position
	velocity = Vector3.ZERO
