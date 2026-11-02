class_name DieFace
extends Control
## Un dado: cuadro blanco, contorno negro y puntos negros. Puede animarse al "rodar".

var value := 1
var _final := 1
var _time_left := 0.0
var _acc := 0.0
var _rolling := false
var _wobble := 0.0

func _init(v: int = 1, px: int = 36) -> void:
	value = v
	_final = v
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

## Muestra caras al azar durante `duration` segundos y termina en `final_value`.
func start_roll(final_value: int, duration: float) -> void:
	_final = final_value
	_time_left = duration
	_rolling = true
	set_process(true)

func _process(delta: float) -> void:
	_time_left -= delta
	_acc += delta
	if _time_left <= 0.0:
		_rolling = false
		value = _final
		_wobble = 0.0
		set_process(false)
		queue_redraw()
		return
	if _acc >= 0.06:
		_acc = 0.0
		value = randi_range(1, 6)
		_wobble = randf_range(-0.35, 0.35)
		queue_redraw()

func _draw() -> void:
	var o := -size / 2.0
	draw_set_transform(size / 2.0, _wobble if _rolling else 0.0, Vector2.ONE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(size.x * 0.2))
	draw_style_box(sb, Rect2(o, size))
	var lo := 0.28
	var mi := 0.5
	var hi := 0.72
	var pips: Array = []
	match value:
		1: pips = [[mi, mi]]
		2: pips = [[lo, lo], [hi, hi]]
		3: pips = [[lo, lo], [mi, mi], [hi, hi]]
		4: pips = [[lo, lo], [hi, lo], [lo, hi], [hi, hi]]
		5: pips = [[lo, lo], [hi, lo], [mi, mi], [lo, hi], [hi, hi]]
		_: pips = [[lo, lo], [lo, mi], [lo, hi], [hi, lo], [hi, mi], [hi, hi]]
	for p in pips:
		draw_circle(o + Vector2(p[0] * size.x, p[1] * size.y), size.x * 0.085, Color.BLACK)
