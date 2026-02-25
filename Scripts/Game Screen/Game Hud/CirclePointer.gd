extends Polygon2D

@export var circle_radius: float = 20.0

func _draw() -> void:
	draw_circle(Vector2(0, 0), circle_radius, color)
