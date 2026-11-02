class_name HonorBadge
extends Control
## Círculo amarillo con el Honor del jugador en el centro.

var value := 0:
	set(v):
		value = v
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(38, 38)
	tooltip_text = "Honor: se gana +1 cada turno y se gasta para bajar guerreros."

func _draw() -> void:
	var c := size / 2.0
	var rad := minf(size.x, size.y) / 2.0 - 2.0
	draw_circle(c, rad, Color(1.0, 0.85, 0.15))
	draw_arc(c, rad, 0.0, TAU, 48, Color(0.45, 0.30, 0.0), 3.0, true)
	var font := ThemeDB.fallback_font
	var fs := 20
	var txt := str(value)
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := c.y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	draw_string(font, Vector2(c.x - w / 2.0, base), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.BLACK)
