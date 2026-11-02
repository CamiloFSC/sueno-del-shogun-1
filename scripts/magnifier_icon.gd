## Lupa dibujada (los emoticonos no se ven en la fuente por defecto).
class_name MagnifierIcon
extends Control

func _init() -> void:
	custom_minimum_size = Vector2(22, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c := Color(1, 0.92, 0.6)
	draw_arc(Vector2(9, 9), 6.5, 0, TAU, 28, c, 2.4, true)
	draw_line(Vector2(14, 14), Vector2(20, 20), c, 3.2, true)
