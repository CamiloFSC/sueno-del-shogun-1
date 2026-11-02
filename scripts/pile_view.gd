class_name PileView
extends Control
## Mazo o pozo de descarte dibujado como una pila de cartas con su cantidad.

signal clicked

var kind := "mazo"            # "mazo" (cartas boca abajo) o "pozo" (se ve la carta de arriba)
var title := ""
var count := 0:
	set(v):
		count = v
		queue_redraw()
var top_id := 0:
	set(v):
		top_id = v
		queue_redraw()
var top_tex: Texture2D = null:
	set(v):
		top_tex = v
		queue_redraw()
var top_name := ""

const CARD := Vector2(54, 74)

func _init(k: String = "mazo", t: String = "") -> void:
	kind = k
	title = t
	custom_minimum_size = Vector2(84, 96)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var base := Vector2(6, 16)
	var layers := clampi(count / 8, 0, 4)
	if count <= 0:
		draw_rect(Rect2(base, CARD), Color(1, 1, 1, 0.35), false, 2.0)
		draw_string(font, base + Vector2(8, 44), "vacío", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.5))
	else:
		for i in range(layers, 0, -1):         # cartas de abajo de la pila
			var o := Vector2(i * 2.0, -i * 2.0)
			draw_rect(Rect2(base + o, CARD), Color(0.22, 0.2, 0.18))
			draw_rect(Rect2(base + o, CARD), Color(0.7, 0.6, 0.35), false, 1.0)
		var r := Rect2(base, CARD)
		if kind == "mazo":
			draw_rect(r, Color(0.42, 0.08, 0.1))
			draw_rect(r, Color(0.95, 0.8, 0.35), false, 2.0)
			var c := r.get_center()
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -20), c + Vector2(15, 0), c + Vector2(0, 20), c + Vector2(-15, 0)]), Color(0.95, 0.8, 0.35))
			draw_circle(c, 7, Color(0.42, 0.08, 0.1))
		elif top_tex != null:
			draw_texture_rect(top_tex, r, false)
			draw_rect(r, Color(0.95, 0.8, 0.35), false, 1.5)
		else:
			draw_rect(r, Color(0.26, 0.26, 0.34))
			draw_rect(r, Color(0.95, 0.8, 0.35), false, 1.5)
			draw_string(font, r.position + Vector2(4, 28), top_name.left(9), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, 11, Color.WHITE)
		# cantidad
		var bc := r.position + Vector2(r.size.x - 4, r.size.y - 2)
		draw_circle(bc, 12, Color(0, 0, 0, 0.8))
		draw_circle(bc, 12, Color(1.0, 0.85, 0.3), false, 1.5)
		draw_string(font, bc + Vector2(-12, 5), str(count), HORIZONTAL_ALIGNMENT_CENTER, 24, 14, Color.WHITE)
	draw_string(font, Vector2(0, 11), title, HORIZONTAL_ALIGNMENT_LEFT, size.x, 12, Color(1, 0.9, 0.6))
