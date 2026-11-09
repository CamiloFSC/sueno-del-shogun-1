class_name FanHand
extends Control
## Mano en abanico: las cartas se abren como si alguien las sostuviera. La carta preseleccionada
## (ratón o teclado) se levanta, crece un poco y queda por encima de las demás.

const R := 1800.0           # radio del abanico (más grande = más plano)
const MAX_STEP := 0.10      # ángulo máximo entre cartas (rad)
const LIFT := 34.0
const BOTTOM_MARGIN := 44.0
const ROT_GAIN := 1.6       # las cartas giran más de lo que se desplazan: abanico marcado sin bajar los bordes

var kb_index := -1          # carta elegida con el teclado (-1 = manda el ratón)
var focus := -1             # carta levantada ahora
var _dirty := true

func _ready() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func(): _dirty = true)
	child_order_changed.connect(func(): _dirty = true)

func relayout() -> void:
	_dirty = true

func _process(_d: float) -> void:
	var f := kb_index if kb_index >= 0 else _pick_mouse()
	if f >= get_child_count():
		f = -1
	if f != focus:
		focus = f
		_dirty = true
	if _dirty:
		_dirty = false
		_layout()

func _pick_mouse() -> int:
	var m := get_global_mouse_position()
	if focus >= 0 and focus < get_child_count() and _hit(get_child(focus), m):
		return focus
	for i in range(get_child_count() - 1, -1, -1):
		if _hit(get_child(i), m):
			return i
	return -1

func _hit(c: Control, m: Vector2) -> bool:
	var p: Vector2 = c.get_global_transform().affine_inverse() * m
	return Rect2(Vector2.ZERO, c.size).has_point(p)

func _layout() -> void:
	var n := get_child_count()
	if n == 0:
		return
	var w0: float = (get_child(0) as Control).get_combined_minimum_size().x
	var step := minf(w0 * 0.62 / R, MAX_STEP)
	if n > 1:
		step = minf(step, (size.x - w0 - 80.0) / float(n - 1) / R)
	var cx := size.x * 0.5
	var base_y := size.y - BOTTOM_MARGIN
	for i in n:
		var c := get_child(i) as Control
		c.size = c.get_combined_minimum_size()
		var th := (float(i) - float(n - 1) / 2.0) * step
		var up := Vector2(sin(th), -cos(th))
		var anchor := Vector2(cx, base_y + R) + up * R
		c.pivot_offset = Vector2(c.size.x / 2.0, c.size.y)
		var lifted := i == focus
		var pos := anchor - c.pivot_offset + (up * LIFT if lifted else Vector2.ZERO)
		var sc := Vector2.ONE * (1.10 if lifted else 1.0)
		c.z_index = 80 if lifted else 10 + i
		if not c.has_meta("placed"):      # carta recién creada: se coloca de golpe (la mano se redibuja a menudo)
			c.set_meta("placed", true)
			c.position = pos
			c.rotation = th * ROT_GAIN
			c.scale = sc
			continue
		var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(c, "position", pos, 0.14)
		tw.tween_property(c, "rotation", th * ROT_GAIN, 0.14)
		tw.tween_property(c, "scale", sc, 0.14)
