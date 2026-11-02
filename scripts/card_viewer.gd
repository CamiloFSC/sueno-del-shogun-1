class_name CardViewer
extends Control
## Visor a pantalla completa de una carta: imagen grande, texto del efecto, cómo lo interpreta el juego y si funciona.
## Navegación con ◀ ▶ (o flechas del teclado) por la lista recibida; Esc o «Cerrar» para salir.

var ids: Array = []
var index := 0
var _pic: TextureRect
var _fallback: Label
var _title: Label
var _meta: Label
var _text: RichTextLabel
var _status: Label
var _pos: Label

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 300
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 28)
	add_child(root)
	# imagen
	var left := Control.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.2
	root.add_child(left)
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	left.add_child(_pic)
	_fallback = Label.new()
	_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback.add_theme_font_size_override("font_size", 30)
	_fallback.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left.add_child(_fallback)
	# texto
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_title)
	_meta = Label.new()
	_meta.add_theme_font_size_override("font_size", 18)
	_meta.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_meta)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 22)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_status)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.add_theme_font_size_override("bold_font_size", 20)
	right.add_child(_text)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	right.add_child(nav)
	nav.add_child(_btn("◀  Anterior", func(): step(-1)))
	_pos = Label.new()
	_pos.add_theme_font_size_override("font_size", 20)
	_pos.custom_minimum_size = Vector2(110, 0)
	_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(_pos)
	nav.add_child(_btn("Siguiente  ▶", func(): step(1)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(sp)
	nav.add_child(_btn("Cerrar (Esc)", close))

func _btn(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(140, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	return b

func open(list: Array, start_index: int = 0) -> void:
	ids = list
	index = clampi(start_index, 0, maxi(ids.size() - 1, 0))
	visible = true
	_show_card()

func close() -> void:
	visible = false

func step(d: int) -> void:
	if ids.is_empty():
		return
	index = posmod(index + d, ids.size())
	_show_card()

func _show_card() -> void:
	if ids.is_empty():
		return
	var id: int = ids[index]
	var c: Dictionary = CardDB.cards[id]
	var tex := CardArt.get_texture(id)
	_pic.texture = tex
	_fallback.visible = tex == null
	_fallback.text = "%s\n\n(sin imagen)" % c.nombre if tex == null else ""
	_title.text = c.nombre
	_meta.text = CardInfo.header(id)
	var ok := CardInfo.works(id)
	_status.text = ("✔  " if ok else "✘  ") + CardInfo.status_text(id)
	_status.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55) if ok else Color(1.0, 0.45, 0.35))
	_text.clear()
	_text.append_text("[b]Texto de la carta[/b]\n%s\n\n[b]Cómo lo interpreta el juego[/b]\n%s" % [c.efecto, CardInfo.detail(id)])
	_pos.text = "%d / %d" % [index + 1, ids.size()]

func _gui_input(ev: InputEvent) -> void:
	accept_event()

func _unhandled_key_input(ev: InputEvent) -> void:
	if not visible or not (ev is InputEventKey) or not ev.pressed:
		return
	match ev.keycode:
		KEY_ESCAPE: close()
		KEY_LEFT: step(-1)
		KEY_RIGHT: step(1)
		_: return
	get_viewport().set_input_as_handled()
