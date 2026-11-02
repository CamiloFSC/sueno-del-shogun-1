## Aviso de descarte: signo de exclamación y mano abierta ("alto").
class_name AlertIcon
extends Control

func _init() -> void:
	custom_minimum_size = Vector2(160, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Dedo redondeado (cápsula vertical) con contorno.
func _finger(x: float, top: float, w: float, bottom: float, fill: Color, line: Color) -> void:
	var r := w * 0.5
	draw_circle(Vector2(x + r, top + r), r + 1.5, line)
	draw_rect(Rect2(x - 1.5, top + r, w + 3.0, bottom - top - r), line)
	draw_circle(Vector2(x + r, top + r), r, fill)
	draw_rect(Rect2(x, top + r, w, bottom - top - r), fill)

func _draw() -> void:
	var white := Color(1, 1, 1)
	var red := Color(0.86, 0.14, 0.14)
	# círculo con exclamación
	draw_circle(Vector2(40, 48), 38, white)
	draw_circle(Vector2(40, 48), 33, red)
	draw_rect(Rect2(34, 20, 12, 32), white)
	draw_circle(Vector2(40, 66), 6.5, white)
	# mano abierta, sencilla: palma + 4 dedos + pulgar
	var skin := Color(1.0, 0.84, 0.62)
	var line := Color(0.35, 0.2, 0.1)
	var x0 := 98.0
	var fw := 11.0
	var tops := [18.0, 8.0, 6.0, 14.0]
	for i in 4:
		_finger(x0 + i * (fw + 1.5), tops[i], fw, 66.0, skin, line)
	# palma
	draw_rect(Rect2(x0 - 1.5, 56.0, 4.0 * fw + 3.0 * 1.5 + 3.0, 34.0), line)
	draw_rect(Rect2(x0, 56.0, 4.0 * fw + 3.0 * 1.5, 32.5), skin)
	draw_circle(Vector2(x0 + 22.0, 88.0), 24.0, line)
	draw_circle(Vector2(x0 + 22.0, 88.0), 22.5, skin)
	draw_rect(Rect2(x0, 56.0, 4.0 * fw + 3.0 * 1.5, 30.0), skin)
	# pulgar
	var thumb := PackedVector2Array([Vector2(x0 + 2.0, 64.0), Vector2(x0 - 12.0, 50.0), Vector2(x0 - 24.0, 56.0), Vector2(x0 - 22.0, 66.0), Vector2(x0 - 4.0, 88.0), Vector2(x0 + 2.0, 84.0)])
	draw_colored_polygon(thumb, skin)
	draw_polyline(thumb, line, 2.0)
