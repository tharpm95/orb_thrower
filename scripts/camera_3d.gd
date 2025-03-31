extends Camera3D

# Sensitivity for mouse movement
var mouse_sensitivity : float = 0.1

# Store the current rotation angles
var rotation_x = 0.0
var rotation_y = 0.0

func _ready():
	# Capture the mouse pointer
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Update rotation_y by the relative motion on x-axis and multiply by sensitivity
		rotation_y -= event.relative.x * mouse_sensitivity

		# Update rotation_x by the relative motion on y-axis and multiply by sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity

		# Clamp the x rotation to avoid flipping (usually between -90° and 90°)
		rotation_x = clamp(rotation_x, -90, 90)

		# Apply the rotations to the camera
		rotation_degrees.x = rotation_x
		rotation_degrees.y = rotation_y
