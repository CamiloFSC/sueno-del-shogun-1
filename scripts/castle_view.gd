class_name CastleView
extends Control
## Castillo dibujado con cartas: cada carta que queda en el castillo es una caja.
## Al robar del castillo desaparecen cajas (primero las de arriba).

var count := 7:
	set(v):
		count = v
		queue_redraw()

# Cada carta: [centro_x, centro_y (fracciones), ancho, alto (px), rotación]
const SLOTS := [
	[0.50, 0.57, 50.0, 30.0, 0.0],     # 0 centro (la última en caer; lleva el número)
	[0.50, 0.85, 50.0, 26.0, 0.0],     # 1 abajo centro
	[0.20, 0.76, 28.0, 44.0, 0.0],     # 2 abajo izquierda
	[0.80, 0.76, 28.0, 44.0, 0.0],     # 3 abajo derecha
	[0.50, 0.24, 30.0, 46.0, 0.0],     # 4 arriba centro
	[0.22, 0.33, 30.0, 46.0, -0.62],   # 5 arriba izquierda inclinada
	[0.78, 0.33, 30.0, 46.0, 0.62],    # 6 arriba derecha inclinada
]

func _init() -> void:
	custom_minimum_size = Vector2(140, 112)
	tooltip_text = "Castillo: cada caja es una carta. Si se vacía, pierdes."

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.90, 0.80))
	_dashed_border(Color(0.95, 0.65, 0.1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Color.BLACK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	# las cartas que quedan: índices 0..count-1 (se quitan desde el 6 hacia abajo)
	for i in range(min(count, SLOTS.size())):
		var s: Array = SLOTS[i]
		var c := Vector2(s[0] * size.x, s[1] * size.y)
		draw_set_transform(c, s[4], Vector2.ONE)
		draw_style_box(sb, Rect2(Vector2(-s[2] / 2.0, -s[3] / 2.0), Vector2(s[2], s[3])))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# contador
	var cc := Vector2(SLOTS[0][0] * size.x, SLOTS[0][1] * size.y)
	draw_circle(cc, 11.0, Color.WHITE)
	draw_arc(cc, 11.0, 0.0, TAU, 32, Color(0.95, 0.65, 0.1), 2.0, true)
	var font := ThemeDB.fallback_font
	var fs := 15
	var txt := str(count)
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := cc.y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	draw_string(font, Vector2(cc.x - w / 2.0, base), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.BLACK)

func _dashed_border(col: Color) -> void:
	var dash := 6.0
	var gap := 4.0
	var pts := [Vector2(1, 1), Vector2(size.x - 1, 1), Vector2(size.x - 1, size.y - 1), Vector2(1, size.y - 1), Vector2(1, 1)]
	for k in 4:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var len := a.distance_to(b)
		var dir := (b - a) / len
		var t := 0.0
		while t < len:
			draw_line(a + dir * t, a + dir * minf(t + dash, len), col, 2.0)
			t += dash + gap
