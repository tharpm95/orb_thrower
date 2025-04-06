extends Node3D

@export var amplitude = 1.0
@export var frequency = 1.0
@export var spawn_delay = 0.023

# Preload the being scenes, which now include their own UI elements
@export var being_scenes: Dictionary = {
	"Fire Bra": preload("res://scenes/beings/fire_bra.tscn"),
	"Water Ket": preload("res://scenes/beings/water_ket.tscn")
}

# Preload the new dialog scene
@export var dialog_scene = preload("res://scenes/dialog/positron_01/positron_01.tscn")

var spawn_chances: Dictionary = {
	Vector3(-9, 2, -18): [{"being": "Fire Bra", "chance": 100}],
	Vector3(5, 2, -19): [{"being": "Fire Bra", "chance": 100}],
	Vector3(-9, 2, -33): [{"being": "Fire Bra", "chance": 70}, {"being": "Water Ket", "chance": 30}],
	Vector3(5, 2, -42): [{"being": "Fire Bra", "chance": 70}, {"being": "Water Ket", "chance": 30}],
	Vector3(-9, 2, -50): [{"being": "Water Ket", "chance": 50}]
}

@onready var camera = get_node("/root/Node3D/CharacterBody3D/Camera3D")
@onready var movement_node = get_node("/root/Node3D/CharacterBody3D")
var being_instances = []

func _ready() -> void:
	randomize()
	print("Spawning beings")
	spawn_beings_with_chance()

	if movement_node:
		movement_node.connect("request_respawn", Callable(self, "_on_request_respawn"))
	else:
		print("CharacterBody3D node not found")

	# Add the dialog instance
	add_dialog_instance()

func spawn_beings_with_chance() -> void:
	for position in spawn_chances.keys():
		var beings_data = spawn_chances[position]
		var selected_being = select_being_for_position(beings_data)
		if selected_being != "":
			var being_instance = being_scenes[selected_being].instantiate()
			add_child(being_instance)
			being_instance.set_global_position(position)

			var control_node = being_instance.get_node("StaticBody3D/Control")
			if is_instance_valid(being_instance) and control_node:
				being_instances.append(being_instance)
				control_node.visible = false

			var area3d = being_instance.get_node("StaticBody3D/MeshInstance3D/Area3D")
			if area3d:
				var timer = Timer.new()
				timer.wait_time = 0.5
				timer.one_shot = true
				timer.connect("timeout", Callable(self, "_connect_sphere_hit_signal").bind(area3d, being_instance))
				being_instance.add_child(timer)
				timer.start()

func select_being_for_position(beings_data: Array) -> String:
	var random_value = randi() % 100
	var cumulative_chance = 0
	for being_data in beings_data:
		cumulative_chance += being_data["chance"]
		if random_value < cumulative_chance:
			return being_data["being"]
	return ""  # Return an empty string if no being is selected

func _connect_sphere_hit_signal(area3d, being_instance: Node) -> void:
	if is_instance_valid(area3d) and is_instance_valid(being_instance):
		var area3d_cast: Area3D = area3d as Area3D
		if area3d_cast:
			area3d_cast.connect("sphere_hit", Callable(movement_node, "_on_sphere_hit").bind(being_instance))
	else:
		printraw("Attempted to access a freed object.")

func print_hierarchy(node: Node, level: int = 0) -> void:
	var indent = ""
	for i in range(level):
		indent += "\t"
	print(indent + node.name)
	for child in node.get_children():
		print_hierarchy(child, level + 1)

@onready var character = get_node("/root/Node3D/CharacterBody3D")
@export var max_display_distance = 25.0

func _process(_delta: float) -> void:
	for being_instance in being_instances:
		if is_instance_valid(camera) and is_instance_valid(being_instance):
			var character_position = character.global_position
			print(character_position)
			var distance_to_character = character_position.distance_to(being_instance.global_position)

			if distance_to_character < max_display_distance:
				if being_instance.has_node("StaticBody3D/Control"):
					var control_node = being_instance.get_node("StaticBody3D/Control")
					if control_node is Control:
						if not camera.is_position_behind(being_instance.global_position + Vector3(0, 2.5, 0)):
							var screen_position = camera.unproject_position(being_instance.global_position + Vector3(0, 2.5, 0))
							control_node.position = screen_position
							control_node.visible = true
						else:
							control_node.visible = false
					else:
						printraw("Node is not a Control instance.")
				else:
					printraw("Control node path not found in being_instance.")

# Function to add the dialog instance
func add_dialog_instance() -> void:
	var dialog_instance = dialog_scene.instantiate()
	add_child(dialog_instance)
	dialog_instance.set_global_position(character.global_position + Vector3(5, -.5, 5))  # Place 5 units away from the character
