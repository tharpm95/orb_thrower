extends Area3D

signal sphere_hit

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("beings"):
		emit_signal("sphere_hit")
		queue_free()
