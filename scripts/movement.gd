extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FALL_THRESHOLD = -100.0
const BASE_LAUNCH_FORCE = 5.0
const MAX_LAUNCH_FORCE = 50.0
const SPHERE_LIFETIME = 2.0
const MAX_CHARGE_TIME = 2.0
const PARTICLES_LIFETIME = 0.5

@onready var camera = $Camera3D
@onready var charge_bar = $HUD/ChargeProgressBar
@onready var qubits_label = $HUD/QubitsLabel
@onready var panel = $"/root/Node3D/Control/Panel"

var start_position: Vector3
var log_timer: float = 0.0
var log_interval: float = 1.0
var charge_time: float = 0.0
var qubits_count: int = 0
var max_display_distance = 25.0

# Load scenes
@export var sphere_scene: PackedScene = preload("res://scenes/items/orb.tscn")
@export var info_particles_scene: PackedScene = preload("res://scenes/effects/info_particles.tscn")

signal request_respawn

func _ready():
	start_position = global_transform.origin
	charge_bar.visible = true
	charge_bar.value = 100.0
	panel.visible = false  # Initially invisible

	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0, 0, 0, 0.5)
	charge_bar.add_theme_stylebox_override("background", style_bg)

	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.5, 0, 0.5, 1)
	charge_bar.add_theme_stylebox_override("fg", style_fg)

	update_qubits_count()

func update_qubits_count():
	qubits_label.text = "Qubits: %d" % qubits_count

func _physics_process(delta: float) -> void:
	log_timer += delta
	if log_timer >= log_interval:
		log_timer = 0.0

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
	var camera_basis = camera.basis
	var direction = (camera_basis.x * input_dir.x) + (camera_basis.z * input_dir.z)
	direction = direction.normalized()
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

func _process(delta: float):
	if Input.is_action_just_pressed("E"):
		panel.visible = not panel.visible  # Toggles visibility

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

		start_position = camera.global_transform.origin - camera.basis.z * 2
		sphere_instance.global_transform.origin = start_position

		var sphere_rigidbody = sphere_instance.get_node("RigidBody3D") if sphere_instance else null
		if sphere_rigidbody:
			var camera_forward = -camera.basis.z.normalized()
			var launch_force = BASE_LAUNCH_FORCE + (charge_time / MAX_CHARGE_TIME) * (MAX_LAUNCH_FORCE - BASE_LAUNCH_FORCE)
			sphere_rigidbody.apply_impulse(camera_forward * launch_force)

			sphere_instance.get_node("RigidBody3D/Area3D").connect("sphere_hit", Callable(self, "_on_sphere_hit").bind(sphere_instance))

			var sphere_timer = Timer.new()
			sphere_timer.one_shot = true
			sphere_timer.wait_time = SPHERE_LIFETIME
			sphere_instance.add_child(sphere_timer)
			sphere_timer.start()

			sphere_timer.timeout.connect(func():
				sphere_instance.queue_free())

func _on_sphere_hit(being_instance, sphere_instance, _other):
	print("Being information acquired")
	increase_qubits_count()

	if being_instance:
		var progress_bar = being_instance.get_node("Control/VBoxContainer2/ProgressBar")
		if progress_bar:
			progress_bar.value = max(progress_bar.value - 100, 0)
			if progress_bar.value == 0:
				trigger_info_particles(being_instance)
		else:
			print("ProgressBar not found for the being_instance")

	if sphere_instance:
		sphere_instance.queue_free()

func trigger_info_particles(being_instance):
	if not being_instance:
		return

	var info_particles_instance = info_particles_scene.instantiate()
	get_tree().root.add_child(info_particles_instance)
	info_particles_instance.global_transform.origin = being_instance.global_transform.origin
	print("Info particles triggered")
	
	var particles_timer = Timer.new()
	particles_timer.one_shot = true
	particles_timer.wait_time = PARTICLES_LIFETIME
	info_particles_instance.add_child(particles_timer)
	particles_timer.start()

	particles_timer.timeout.connect(func():
		info_particles_instance.queue_free())
	
	being_instance.queue_free()

func find_and_print_nearest_location(position: Vector3) -> Vector3:
	var spawn_data_node = get_node("/root/Node3D/LibraryCentralHall") # Modify the path according to your scene structure
	var chances = spawn_data_node.spawn_chances
	print(chances)

	var closest_position: Vector3
	var min_distance: float = INF

	for loc in chances.keys():
		var loc_vector = Vector3(loc) # Assume loc is a tuple or similar that can unpack to a Vector3
		var distance = position.distance_to(loc_vector)
		if distance < min_distance:
			min_distance = distance
			closest_position = loc_vector

	print("Closest location:", closest_position)
	return closest_position
	
func print_hierarchy(node: Node, level: int = 0) -> void:
	var indent = ""
	for i in range(level):
		indent += "\t"
	print(indent + node.name)
	for child in node.get_children():
		print_hierarchy(child, level + 1)

func increase_qubits_count():
	qubits_count += 1
	update_qubits_count()

func _resurrect():
	global_transform.origin = start_position
	velocity = Vector3.ZERO
