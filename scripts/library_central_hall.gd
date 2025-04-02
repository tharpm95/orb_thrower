extends Node3D
@export var amplitude = 1.0
@export var frequency = 1.0
@export var spawn_delay = 0.023 # Time in seconds between each spawn

# Preload the being scenes, which now include their own UI elements
@export var being_scenes: Array = [
	preload("res://scenes/beings/001.tscn"),
	preload("res://scenes/beings/002.tscn")
]
var spawn_positions: Array = [
	Vector3(10, -4, 10),
	Vector3(-10, -4, -10),
	Vector3(15, -4, -15),
	Vector3(-15, -4, 15),
	Vector3(0, -4, 20)
]

@onready var camera = get_node("/root/Node3D/CharacterBody3D/Camera3D")
var being_instances = []

func _ready() -> void:
	randomize()
	print("Spawning beings")
	spawn_beings_with_delay()

# In your being management script
# In library_central_hall.gd

@onready var movement_node = get_node("/root/Node3D/CharacterBody3D")

func spawn_beings_with_delay() -> void:
	for pos in spawn_positions:
		var scene_index = randi() % being_scenes.size()
		var being_instance = being_scenes[scene_index].instantiate()
		add_child(being_instance)
		being_instance.set_global_position(pos)

		var control_node: Control = being_instance.get_node("StaticBody3D/Control")
		if control_node:
			being_instances.append(being_instance)
			control_node.visible = false

		var area3d = being_instance.get_node("StaticBody3D/MeshInstance3D/Area3D")
		if area3d:
			var timer = Timer.new()
			timer.wait_time = 0.5  # Adjust the wait time as needed
			timer.one_shot = true
			# Pass the instance itself and verify later if it's valid
			timer.connect("timeout", Callable(self, "_connect_sphere_hit_signal").bind(area3d, being_instance))
			being_instance.add_child(timer)
			timer.start()

# Function that connects the sphere_hit signal after the delay
func _connect_sphere_hit_signal(area3d, being_instance: Node) -> void:
	if is_instance_valid(area3d) and is_instance_valid(being_instance):
		var area3d_cast: Area3D = area3d as Area3D
		if area3d_cast:
			area3d_cast.connect("sphere_hit", Callable(movement_node, "_on_sphere_hit").bind(being_instance))
	else:
		printraw("Attempted to access a freed object.")
	
# Helper function to print hierarchy
func print_hierarchy(node: Node, level: int = 0) -> void:
	var indent = ""
	for i in range(level):
		indent += "\t"
	print(indent + node.name)
	for child in node.get_children():
		print_hierarchy(child, level + 1)

@onready var character = get_node("/root/Node3D/CharacterBody3D") # Adjust the path as necessary
@export var max_display_distance = 25.0 # Maximum distance to display the label

func _process(_delta: float) -> void:
	for i in range(being_instances.size()):
		var being_instance = being_instances[i]
		if camera and being_instance:
			var character_position = character.global_position
			var distance_to_character = character_position.distance_to(being_instance.global_position)
			

			var control_node: Control = being_instance.get_node("StaticBody3D/Control")
			if distance_to_character < max_display_distance:
				# Check if the position is behind the camera
				if not camera.is_position_behind(being_instance.global_position + Vector3(0, 2.5, 0)):
					var screen_position = camera.unproject_position(being_instance.global_position + Vector3(0, 2.5, 0))
					control_node.position = screen_position
					control_node.visible = true
				else:
					control_node.visible = false
