extends Node3D

@export var amplitude = 1.0
@export var frequency = 1.0
@export var spawn_delay = 0.023 # Time in seconds between each spawn

# Preload the cube scenes
@export var cube_scenes: Array = [
	preload("res://scenes/beings/001.tscn"),
	preload("res://scenes/beings/002.tscn")
]

# Preload the Oscillator script
@export var OscillatorScript = preload("res://scripts/oscillate.gd")

# Preload the UI scene for name and health bar
@export var being_ui_scene: PackedScene = preload("res://scenes/ui/HUD_BeingUI.tscn")

# Define fixed spawn positions
var spawn_positions: Array = [
	Vector3(10, -4, 10),
	#Vector3(-10, -3, -10),
	#Vector3(15, -3, -15),
	#Vector3(-15, -3, 15),
	#Vector3(0, -3, 20)
]

@onready var camera = get_node("/root/Node3D/CharacterBody3D/Camera3D")
@onready var canvas_layer: CanvasLayer = get_node("/root/Node3D/CanvasLayer")

# Store references to UI and Cube instances
var cube_ui_pairs = []

func _ready() -> void:
	randomize()
	print("Spawning cubes")
	await spawn_cubes_with_delay()

# Asynchronous function to spawn cubes with a delay
func spawn_cubes_with_delay() -> void:
	for pos in spawn_positions:
		# Select a random scene and instantiate it
		var scene_index = randi() % cube_scenes.size()
		var cube_instance = cube_scenes[scene_index].instantiate()
		add_child(cube_instance)
		cube_instance.set_global_position(pos)

		# Instantiate the UI Scene
		var ui_instance = being_ui_scene.instantiate()

		# Add the UI instance to the CanvasLayer node
		canvas_layer.add_child(ui_instance)

		# Update the label based on the origin scene
		var label_node = ui_instance.get_node("VBoxContainer/Label")		
		if label_node:
			if scene_index == 0:
				label_node.text = "Fire Bra"
			elif scene_index == 1:
				label_node.text = "Water Ket"

		# Store the cube and corresponding UI pair
		cube_ui_pairs.append({'cube': cube_instance, 'ui': ui_instance})

		# Add and set up the oscillator for the cube
		var oscillator_instance = OscillatorScript.new()
		oscillator_instance.amplitude = amplitude
		oscillator_instance.frequency = frequency
		cube_instance.add_child(oscillator_instance)
		oscillator_instance.set_initial_position(pos)

		# Wait for the specified delay
		await get_tree().create_timer(spawn_delay).timeout

# Update UI position every frame
@onready var character = get_node("/root/Node3D/CharacterBody3D")  # Adjust the path as necessary
@export var max_display_distance = 15.0  # Maximum distance to display the label

func _process(delta: float) -> void:
	for pair in cube_ui_pairs:
		var cube = pair['cube']
		var ui_instance = pair['ui']
		if camera and cube and ui_instance:
			# Get the character's global position
			var character_position = character.global_position

			# Calculate distance between the character and the cube
			var distance_to_character = character_position.distance_to(cube.global_position)

			# Only update position if within distance
			if distance_to_character < max_display_distance:
				var screen_position = camera.unproject_position(cube.global_position + Vector3(0, 2.5, 0))
				if ui_instance is Control:
					ui_instance.visible = true
					ui_instance.position = screen_position
			else:
				if ui_instance is Control:
					ui_instance.visible = false
