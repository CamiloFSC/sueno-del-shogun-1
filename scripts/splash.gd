extends Control
## Pantalla de presentación: logo del juego y «presiona cualquier botón». Reemplaza assets/logo.png por el logo definitivo.

var _go := false
var _prompt: Label

func _ready() -> void:
	UiFont.apply(self)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bgtex: Texture2D = CardArt._load_path("res://assets/fondo.jpg")
	if bgtex != null:
		var pic := TextureRect.new()
		pic.texture = bgtex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.modulate = Color(0.38, 0.38, 0.45)
		add_child(pic)
	var logo_tex: Texture2D = CardArt._load_path("res://assets/logo.png")
	var logo: Control
	if logo_tex != null:
		var tr := TextureRect.new()
		tr.texture = logo_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo = tr
	else:
		var l := Label.new()
		l.text = "Sueño del Shogun"
		l.add_theme_font_size_override("font_size", 80)
		l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		logo = l
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.offset_left = 140
	logo.offset_right = -140
	logo.offset_top = 30
	logo.offset_bottom = -110
	logo.modulate.a = 0.0
	add_child(logo)
	_prompt = Label.new()
	_prompt.text = "Presiona cualquier botón para avanzar"
	_prompt.add_theme_font_size_override("font_size", 26)
	_prompt.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 8)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -86
	_prompt.offset_bottom = -40
	_prompt.modulate.a = 0.0
	add_child(_prompt)
	var tw := create_tween()
	tw.tween_property(logo, "modulate:a", 1.0, 1.4)
	tw.tween_property(_prompt, "modulate:a", 1.0, 0.6)
	tw.tween_callback(func():
		var pulse := create_tween().set_loops()
		pulse.tween_property(_prompt, "modulate:a", 0.25, 0.9)
		pulse.tween_property(_prompt, "modulate:a", 1.0, 0.9))

func _input(ev: InputEvent) -> void:
	if _go:
		return
	var press := false
	if ev is InputEventKey and ev.pressed and not ev.echo:
		press = true
	elif ev is InputEventMouseButton and ev.pressed:
		press = true
	elif ev is InputEventJoypadButton and ev.pressed:
		press = true
	elif ev is InputEventScreenTouch and ev.pressed:
		press = true
	if press:
		_go = true
		get_viewport().set_input_as_handled()
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
