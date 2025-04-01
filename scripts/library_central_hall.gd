# LibraryCentralHall.gd
extends Node3D

@export var amplitude = 1.0
@export var frequency = 1.0

@export var spawn_delay = 0.023  # Time in seconds between each spawn

# Preload the cube scenes
@export var cube_scenes: Array = [
	preload("res://scenes/beings/001.tscn"),
	preload("res://scenes/beings/002.tscn")
]

# Preload the Oscillator script
@export var OscillatorScript = preload("res://scripts/oscillate.gd")  # Ensure this is the correct path

# Define fixed spawn positions
var spawn_positions: Array = [
	Vector3(10, -3, 10),
	Vector3(-10, -3, -10),
	Vector3(15, -3, -15),
	Vector3(-15, -3, 15),
	Vector3(0, -3, 20)
]

func _ready() -> void:
	randomize()
	await spawn_cubes_with_delay()

# Asynchronous function to spawn cubes with a delay
func spawn_cubes_with_delay() -> void:
	for pos in spawn_positions:
		var cube_instance = cube_scenes[randi() % cube_scenes.size()].instantiate()
		add_child(cube_instance)
		cube_instance.set_global_position(pos)

		var oscillator_instance = OscillatorScript.new()
		oscillator_instance.amplitude = amplitude
		oscillator_instance.frequency = frequency
		cube_instance.add_child(oscillator_instance)
		oscillator_instance.set_initial_position(pos)
		
		# Wait for the specified delay
		await get_tree().create_timer(spawn_delay).timeout
