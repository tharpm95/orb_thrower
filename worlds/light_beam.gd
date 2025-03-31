extends CharacterBody3D

# Assume `RayCast3D` is a child of this node.
@export var max_distance: float = 500.0
@onready var raycast = $RayCast3D

func _ready():
	# Ensure the RayCast3D is initially disabled
	raycast.enabled = false
	raycast.cast_to = Vector3.ZERO # Initial setting

func _input(event):
	# Check if the left mouse button is pressed
	if event.is_action_pressed("ui_select"):  # Replace "ui_select" with your specific input action if different
		emit_line()

func emit_line():
	# Align the raycast to the camera's direction
	var camera = get_viewport().get_camera_3d()
	var ray_start = global_transform.origin + Vector3.RIGHT * 0.5 # Adjust this based on your character's structure
	raycast.global_transform.origin = ray_start
	raycast.cast_to = camera.global_transform.basis.z * max_distance

	# Enable raycast and check for collision
	raycast.enabled = true
	raycast.force_raycast_update()  # Ensures a raycast update
	if raycast.is_colliding():
		draw_line(raycast.get_collision_point())
	else:
		draw_line(ray_start + raycast.cast_to)

	# Disable the raycast immediately after obtaining the collision
	raycast.enabled = false

func draw_line(to_point):
	# Get the local translation of the character to ensure the line begins at the character
	var line_start = global_transform.origin + Vector3.RIGHT * 0.5 # Adjust this further if necessary

	# Draw or update a Line2D node, or your preferred method to visualize the line, between line_start and to_point.
	var line = Line2D.new()
	add_child(line)
	line.points = [Vector2(line_start.x, line_start.z), Vector2(to_point.x, to_point.z)]
	line.width = 2
	line.default_color = Color(1, 0, 1)  # A solid purple color, adjust as needed
	
	# Optionally, remove the line after a short delay
	yield(get_tree().create_timer(0.2), "timeout")
	line.queue_free()
