extends Camera3D

var mouse_sensitivity : float = 0.1

var rotation_x = 0.0
var rotation_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = rotation_x
		rotation_degrees.y = rotation_y
