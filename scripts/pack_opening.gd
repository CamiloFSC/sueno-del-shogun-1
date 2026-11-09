class_name PackOpening
extends Control
## Apertura de un sobre de 5 cartas: haz clic en cada una para darle la vuelta. Los Daimyos holográficos brillan.

signal closed

const CARD_W := 196.0
const CARD_H := 276.0

var cards: Array = []
var news: Array = []
var _slots: Array = []      # {"id", "flipped", "root", "back", "front"}
var _done: Button
var _all: Button
var _hint: Label

func setup(ids: Array, new_ids: Array) -> void:
	cards = ids
	news = new_ids

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 400
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.95)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var t := Label.new()
	t.text = "¡Sobre de cartas!"
	t.add_theme_font_size_override("font_size", 44)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	t.offset_top = 22
	add_child(t)
	_hint = Label.new()
	_hint.text = "Haz clic en cada carta para revelarla"
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_top = 82
	add_child(_hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 150
	add_child(row)
	for i in cards.size():
		row.add_child(_make_slot(i))
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 14)
	bb.alignment = BoxContainer.ALIGNMENT_CENTER
	bb.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bb.offset_top = -86
	bb.offset_bottom = -30
	add_child(bb)
	_all = _btn("Revelar todas")
	_all.pressed.connect(func(): for i in _slots.size(): _flip(i))
	bb.add_child(_all)
	_done = _btn("Listo")
	_done.pressed.connect(_close)
	bb.add_child(_done)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _btn(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(200, 52)
	b.add_theme_font_size_override("font_size", 22)
	return b

func _make_slot(i: int) -> Control:
	var id: int = cards[i]
	var root := Control.new()
	root.custom_minimum_size = Vector2(CARD_W, CARD_H)
	root.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
	var back := Panel.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.45, 0.08, 0.10)
	sb.border_color = Color(1.0, 0.85, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	back.add_theme_stylebox_override("panel", sb)
	var q := Label.new()
	q.text = "将\n軍"
	q.add_theme_font_size_override("font_size", 64)
	q.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.add_child(q)
	root.add_child(back)
	var front := Control.new()
	front.set_anchors_preset(Control.PRESET_FULL_RECT)
	front.visible = false
	var tex := CardArt.get_texture(id)
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		CardFx.apply(img, id, true)
		front.add_child(img)
	else:
		var nm := Label.new()
		nm.text = CardDB.cards[id].nombre
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.set_anchors_preset(Control.PRESET_FULL_RECT)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		front.add_child(nm)
	root.add_child(front)
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(func(): _flip(i))
	root.add_child(hit)
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 8)
	wrap.add_child(root)
	var tag := Label.new()
	var is_new: bool = id in news
	tag.text = "¡NUEVA!" if is_new else "repetida"
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if is_new else Color(0.7, 0.7, 0.7))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.modulate.a = 0.0
	wrap.add_child(tag)
	_slots.append({"id": id, "flipped": false, "root": root, "back": back, "front": front, "tag": tag})
	return wrap

func _flip(i: int) -> void:
	var s: Dictionary = _slots[i]
	if s.flipped:
		return
	s.flipped = true
	var root: Control = s.root
	var tw := create_tween()
	tw.tween_property(root, "scale:x", 0.0, 0.14)
	tw.tween_callback(func():
		s.back.visible = false
		s.front.visible = true
		s.tag.modulate.a = 1.0)
	tw.tween_property(root, "scale:x", 1.0, 0.14)
	var all_up := true
	for o in _slots:
		if not o.flipped:
			all_up = false
	if all_up:
		_hint.text = "%d carta(s) nueva(s) en tu colección" % news.size()

func _close() -> void:
	closed.emit()
	queue_free()

## Teclado: Enter / Espacio / flecha derecha revelan la siguiente carta; con todas reveladas, cierran el sobre.
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT, KEY_D]:
		get_viewport().set_input_as_handled()
		for i in _slots.size():
			if not _slots[i].flipped:
				_flip(i)
				return
		_close()
