class_name TutorialOverlay
extends Control
## Tutorial de ~1 minuto: señala con flechas las partes del tablero real. Avanza solo (o con clic / botones).

signal finished

const STEP_SEC := 8.5
var steps: Array = []     # {target: Control, text: String, dir: "up"|"down"|"left"}
var idx := -1
var _frame: Panel
var _arrow: Label
var _box: PanelContainer
var _txt: Label
var _count: Label
var _bar: ProgressBar
var _tween: Tween
var _elapsed := 0.0
var _arrow_t := 0.0

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 170

func start(list: Array) -> void:
	steps = list
	_frame = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.85, 0.2, 0.10)
	sb.border_color = Color(1.0, 0.85, 0.2)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	_frame.add_theme_stylebox_override("panel", sb)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_arrow = Label.new()
	_arrow.add_theme_font_size_override("font_size", 72)
	_arrow.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_arrow.add_theme_color_override("font_outline_color", Color.BLACK)
	_arrow.add_theme_constant_override("outline_size", 10)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow)
	_box = PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.06, 0.05, 0.04, 0.96)
	bs.border_color = Color(1.0, 0.85, 0.2)
	bs.set_border_width_all(3)
	bs.set_corner_radius_all(12)
	bs.set_content_margin_all(14)
	_box.add_theme_stylebox_override("panel", bs)
	_box.custom_minimum_size = Vector2(520, 0)
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_box.add_child(vb)
	_count = Label.new()
	_count.add_theme_font_size_override("font_size", 15)
	_count.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	vb.add_child(_count)
	_txt = Label.new()
	_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_txt.custom_minimum_size = Vector2(490, 0)
	_txt.add_theme_font_size_override("font_size", 20)
	vb.add_child(_txt)
	_bar = ProgressBar.new()
	_bar.max_value = STEP_SEC
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 8)
	vb.add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	for def in [["◀", -1], ["▶", 1]]:
		var b := Button.new()
		b.text = def[0]
		b.focus_mode = Control.FOCUS_NONE
		var d: int = def[1]
		b.pressed.connect(func(): _go(idx + d))
		row.add_child(b)
	var sk := Button.new()
	sk.text = "Saltar tutorial"
	sk.focus_mode = Control.FOCUS_NONE
	sk.pressed.connect(_end)
	row.add_child(sk)
	_go(0)

func _go(i: int) -> void:
	if i < 0:
		i = 0
	if i >= steps.size():
		_end()
		return
	idx = i
	_elapsed = 0.0
	var st: Dictionary = steps[i]
	_txt.text = st.text
	_count.text = "Tutorial · paso %d de %d" % [i + 1, steps.size()]
	await get_tree().process_frame
	var t: Control = st.target
	var S := get_viewport_rect().size
	var r := t.get_global_rect().grow(6.0)
	_frame.position = r.position
	_frame.size = r.size
	var dir: String = st.dir
	_arrow.text = {"up": "▲", "down": "▼", "left": "◀", "right": "▶"}[dir]
	_arrow.size = Vector2(60, 90)
	var ap: Vector2
	match dir:
		"up": ap = Vector2(r.position.x + r.size.x * 0.5 - 30.0, r.end.y + 4.0)
		"down": ap = Vector2(r.position.x + r.size.x * 0.5 - 30.0, r.position.y - 86.0)
		"left": ap = Vector2(r.end.x + 4.0, r.position.y + r.size.y * 0.5 - 45.0)
		_: ap = Vector2(r.position.x - 64.0, r.position.y + r.size.y * 0.5 - 45.0)
	ap.x = clampf(ap.x, 4.0, S.x - 64.0)
	ap.y = clampf(ap.y, 4.0, S.y - 94.0)
	_arrow.position = ap
	_arrow.set_meta("base", ap)
	# el cuadro de texto va donde no tape el objetivo
	_box.reset_size()
	var bw: float = _box.size.x
	var bh: float = _box.size.y
	var cands := [Vector2(S.x * 0.5 - bw * 0.5, 90.0), Vector2(S.x * 0.5 - bw * 0.5, S.y - bh - 90.0),
		Vector2(16.0, 90.0), Vector2(16.0, S.y - bh - 90.0), Vector2(S.x - bw - 16.0, 90.0)]
	var best: Vector2 = cands[0]
	for c in cands:
		var cr := Rect2(c, Vector2(bw, bh))
		if not cr.intersects(r.grow(70.0)):
			best = c
			break
	_box.position = Vector2(clampf(best.x, 4.0, S.x - bw - 4.0), best.y)

func _process(dt: float) -> void:
	if steps.is_empty() or idx < 0:
		return
	_elapsed += dt
	_bar.value = _elapsed
	_arrow_t += dt * 6.0
	if _arrow.has_meta("base"):
		var b: Vector2 = _arrow.get_meta("base")
		var off := sin(_arrow_t) * 10.0
		var d: String = steps[idx].dir
		_arrow.position = b + (Vector2(0, off) if d in ["up", "down"] else Vector2(off, 0))
	if _elapsed >= STEP_SEC:
		_go(idx + 1)

func _end() -> void:
	set_process(false)
	finished.emit()
	queue_free()
