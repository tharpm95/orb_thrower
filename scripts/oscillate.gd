# OscillateStaticBody.gd
extends Node3D  # Ensure this matches the type of node that should be oscillating

@export var amplitude = 1.0
@export var frequency = 1.0

var initial_position: Vector3

func set_initial_position(position: Vector3):
	initial_position = position

func _process(delta: float):
	var oscillation = amplitude * sin(2.0 * PI * frequency * Time.get_ticks_msec() / 1000.0)
	global_transform.origin = initial_position + Vector3(0, oscillation, 0)
