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
func spawn_beings_with_delay() -> void:
	for pos in spawn_positions:
		var scene_index = randi() % being_scenes.size()
		var being_instance = being_scenes[scene_index].instantiate()
		add_child(being_instance)
		being_instance.set_global_position(pos)
		
		var control_node: Control = being_instance.get_node("Control")
		if control_node:
			being_instances.append(being_instance)
			control_node.visible = false
		
		# Connect the sphere_hit signal from each being to the _on_sphere_hit callback which should be in this script
		being_instance.connect("sphere_hit", Callable(character, "_on_sphere_hit"))

@onready var character = get_node("/root/Node3D/CharacterBody3D") # Adjust the path as necessary
@export var max_display_distance = 25.0 # Maximum distance to display the label

func _process(_delta: float) -> void:
	for i in range(being_instances.size()):
		var being_instance = being_instances[i]
		if camera and being_instance:
			var character_position = character.global_position
			var distance_to_character = character_position.distance_to(being_instance.global_position)

			# Commenting the global position of the being instance and its index
			print("Distance to being: ", distance_to_character, " Being index: ", i)

			var control_node: Control = being_instance.get_node("Control")
			if distance_to_character < max_display_distance:
				# Check if the position is behind the camera
				if not camera.is_position_behind(being_instance.global_position + Vector3(0, 2.5, 0)):
					var screen_position = camera.unproject_position(being_instance.global_position + Vector3(0, 2.5, 0))
					print("Screen position: ", screen_position)
					control_node.position = screen_position
					control_node.visible = true
				else:
					control_node.visible = false
