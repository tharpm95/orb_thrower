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
	await spawn_beings_with_delay()

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

@onready var character = get_node("/root/Node3D/CharacterBody3D") # Adjust the path as necessary
@export var max_display_distance = 25.0 # Maximum distance to display the label

func _process(delta: float) -> void:
	for i in range(being_instances.size()):
		var being_instance = being_instances[i]
		if camera and being_instance:
			var character_position = character.global_position
			var distance_to_character = character_position.distance_to(being_instance.global_position)
			print("Distance to being: ", distance_to_character, " Being index: ", i)

			var control_node: Control = being_instance.get_node("Control")
			if distance_to_character < max_display_distance:
				# Adjust position for the label
				var offset_position = being_instance.global_position + Vector3(0, 2.5, 0)
				
				# Transform the global position to camera space
				var camera_transform = camera.get_global_transform().affine_inverse()
				var relative_position = offset_position - camera_transform.origin
				var camera_basis_inverse = camera_transform.basis.transposed()

				# Coordinate transformation to camera space
				var view_x = camera_basis_inverse.x.dot(relative_position)
				var view_y = camera_basis_inverse.y.dot(relative_position)
				var view_z = camera_basis_inverse.z.dot(relative_position)

				# Prepare parameters for manual perspective transformation
				var near = camera.near
				var far = camera.far
				var fov = camera.fov
				var viewport_size = get_viewport().size
				var aspect_ratio = viewport_size.x / viewport_size.y
				var f = 1.0 / tan(fov * 0.5 * deg_to_rad(1.0))  # Ensure fov is in radians

				# Perform perspective division
				if view_z > 0.0:
					var clip_x = view_x * (f / aspect_ratio)
					var clip_y = view_y * f
					var clip_w = view_z  # Assuming a simplified projection keeps w consistent for view_z > 0

					# Normalized device coordinates (NDC)
					var ndc_x = clip_x / clip_w
					var ndc_y = clip_y / clip_w

					# Convert NDC to screen space
					var screen_x = (ndc_x * 0.5 + 0.5) * viewport_size.x
					var screen_y = (1.0 - (ndc_y * 0.5 + 0.5)) * viewport_size.y

					var screen_position = Vector2(screen_x, screen_y)
					print("Screen position: ", screen_position)

					control_node.position = screen_position
					control_node.visible = true
				else:
					control_node.visible = false
			else:
				control_node.visible = false
