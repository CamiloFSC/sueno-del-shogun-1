## Aviso de descarte: signo de exclamación y mano abierta ("alto").
class_name AlertIcon
extends Control

func _init() -> void:
	custom_minimum_size = Vector2(160, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var white := Color(1, 1, 1)
	var red := Color(0.86, 0.14, 0.14)
	# círculo con exclamación
	draw_circle(Vector2(40, 48), 38, white)
	draw_circle(Vector2(40, 48), 33, red)
	draw_rect(Rect2(34, 20, 12, 32), white)
	draw_circle(Vector2(40, 66), 6.5, white)
	# mano abierta
	draw_set_transform(Vector2(18, 0))
	var skin := Color(1.0, 0.84, 0.62)
	var line := Color(0.35, 0.2, 0.1)
	var palm := Rect2(96, 46, 40, 36)
	for f in [[96.0, 18.0], [106.0, 10.0], [116.0, 8.0], [126.0, 16.0]]:     # dedos [x, y superior]
		var r := Rect2(f[0], f[1], 9.0, 46.0 - (f[1] - 8.0) * 0.0 + 8.0 - (f[1] - 8.0) + 0.0)
		r.size.y = 50.0 - (f[1] - 8.0)
		draw_rect(r, skin)
		draw_rect(r, line, false, 1.5)
	draw_rect(palm, skin)
	draw_rect(palm, line, false, 1.5)
	var thumb := PackedVector2Array([Vector2(98, 66), Vector2(80, 54), Vector2(76, 62), Vector2(92, 80)])
	draw_colored_polygon(thumb, skin)
	draw_polyline(thumb, line, 1.5)
