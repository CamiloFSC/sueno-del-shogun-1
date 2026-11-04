class_name CampaignMap
extends Control
## Mapa de la campaña: 8 puntos unidos por un camino. Se desbloquean al ganar.

signal picked(level: int)

const POS := [Vector2(0.07, 0.66), Vector2(0.20, 0.30), Vector2(0.33, 0.66), Vector2(0.46, 0.30), Vector2(0.59, 0.66), Vector2(0.72, 0.30), Vector2(0.84, 0.66), Vector2(0.93, 0.30)]
const R := 40.0

var progress := 0:
	set(v):
		progress = v
		_rebuild()
var _nodes: Array = []
var _pulse: Tween = null

func _init() -> void:
	resized.connect(_layout)

func _pt(i: int) -> Vector2:
	return Vector2(POS[i].x * size.x, POS[i].y * size.y)

func _rebuild() -> void:
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	for i in CampaignStore.count():
		var level := i + 1
		var done := level <= progress
		var open := level == progress + 1
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(R * 2, R * 2)
		b.size = Vector2(R * 2, R * 2)
		b.text = ("✔" if done else str(level)) if (done or open) else str(level)
		b.add_theme_font_size_override("font_size", 34)
		var fill := Color(0.25, 0.25, 0.28)
		var border := Color(0.45, 0.45, 0.5)
		if done:
			fill = Color(0.18, 0.5, 0.26)
			border = Color(0.7, 1.0, 0.7)
		elif open:
			fill = Color(0.85, 0.65, 0.12)
			border = Color(1, 1, 0.75)
		b.add_theme_color_override("font_color", Color.WHITE if (done or open) else Color(0.6, 0.6, 0.62))
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = fill.lightened(0.15) if st == "hover" and (done or open) else fill
			sb.border_color = border
			sb.set_border_width_all(4)
			sb.set_corner_radius_all(int(R))
			b.add_theme_stylebox_override(st, sb)
		b.disabled = not (done or open)
		b.pressed.connect(func(): picked.emit(level))
		var cap := Label.new()
		cap.text = "%d. %s\n%s" % [level, CampaignStore.LEVELS[i].titulo, CampaignStore.LEVELS[i].lugar if (done or open) else "Bloqueado"]
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 16)
		cap.add_theme_color_override("font_color", Color.WHITE if (done or open) else Color(0.62, 0.62, 0.66))
		cap.add_theme_color_override("font_outline_color", Color.BLACK)
		cap.add_theme_constant_override("outline_size", 6)
		cap.custom_minimum_size = Vector2(190, 0)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cap)
		add_child(b)
		_nodes.append(b)
		if open:
			_pulse = create_tween().set_loops()
			_pulse.tween_property(b, "modulate", Color(1.35, 1.25, 0.8), 0.7)
			_pulse.tween_property(b, "modulate", Color.WHITE, 0.7)
	_layout()
	queue_redraw()

func _layout() -> void:
	for i in _nodes.size():
		var b: Control = _nodes[i]
		b.position = _pt(i) - Vector2(R, R)
		var cap: Control = b.get_child(0)
		cap.position = Vector2(R - 95.0, R * 2 + 4.0)
	queue_redraw()

func _draw() -> void:
	for i in range(POS.size() - 1):
		var a := _pt(i)
		var b := _pt(i + 1)
		var done := i + 1 <= progress
		draw_line(a, b, Color(0.05, 0.04, 0.03, 0.9), 12.0, true)
		if done:
			draw_line(a, b, Color(1.0, 0.82, 0.25), 6.0, true)
		else:
			var d := (b - a).length()
			var dir := (b - a) / d
			var t := 0.0
			while t < d:
				draw_line(a + dir * t, a + dir * minf(t + 14.0, d), Color(0.6, 0.6, 0.65), 5.0, true)
				t += 26.0
