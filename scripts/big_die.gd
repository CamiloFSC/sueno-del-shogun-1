class_name BigDie
extends Control
## Dado de 6 caras dibujado (marfil con puntos). `value` 1..6; se puede girar con `rotation`.

var value := 1:
	set(v):
		value = v
		queue_redraw()
var tint := Color(1.0, 0.97, 0.88):
	set(c):
		tint = c
		queue_redraw()

const PIPS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.28, 0.28), Vector2(0.72, 0.72)],
	3: [Vector2(0.28, 0.28), Vector2(0.5, 0.5), Vector2(0.72, 0.72)],
	4: [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.28, 0.72), Vector2(0.72, 0.72)],
	5: [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.5, 0.5), Vector2(0.28, 0.72), Vector2(0.72, 0.72)],
	6: [Vector2(0.28, 0.25), Vector2(0.72, 0.25), Vector2(0.28, 0.5), Vector2(0.72, 0.5), Vector2(0.28, 0.75), Vector2(0.72, 0.75)],
}

func _init(sz: float = 80.0) -> void:
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	pivot_offset = Vector2(sz, sz) * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = tint
	sb.border_color = Color(0.25, 0.1, 0.05)
	sb.set_border_width_all(maxi(2, int(size.x * 0.045)))
	sb.set_corner_radius_all(int(size.x * 0.2))
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = int(size.x * 0.12)
	sb.shadow_offset = Vector2(0, size.x * 0.06)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var r := size.x * (0.105 if value != 1 else 0.17)
	var col := Color(0.75, 0.08, 0.08) if value == 1 else Color(0.12, 0.08, 0.06)
	for p in PIPS[clampi(value, 1, 6)]:
		draw_circle(p * size, r, col)
