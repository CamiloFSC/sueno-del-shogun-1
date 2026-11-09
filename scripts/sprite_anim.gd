class_name SpriteAnim
extends TextureRect
## Reproduce una animación desde una HOJA DE SPRITES (todos los fotogramas del mismo tamaño en una cuadrícula).
## Convención de nombre: <animacion>_<columnas>x<filas>.png  (ej. ataque_3x2.png = 3 columnas, 2 filas, 6 fotogramas).
## Orden de lectura: de izquierda a derecha y de arriba abajo.

signal finished

var fps := 9.0
var loop := true
var ping_pong := false
var frame_count := 0
var _cols := 1
var _rows := 1
var _sheet: Texture2D
var _atlas := AtlasTexture.new()
var _t := 0.0
var _playing := false
var _order: Array = []

## Crea la animación a partir del archivo; las columnas y filas salen del nombre.
static func from_file(path: String, fps_: float = 9.0, loop_: bool = true, ping_pong_: bool = false) -> SpriteAnim:
	var a := SpriteAnim.new()
	var rx := RegEx.new()
	rx.compile("_(\\d+)x(\\d+)\\.png$")
	var m := rx.search(path)
	var cols := 1
	var rows := 1
	if m != null:
		cols = int(m.get_string(1))
		rows = int(m.get_string(2))
	a.setup(load(path), cols, rows, fps_, loop_, ping_pong_)
	return a

func setup(sheet: Texture2D, cols: int, rows: int, fps_: float = 9.0, loop_: bool = true, ping_pong_: bool = false) -> void:
	_sheet = sheet
	_cols = maxi(cols, 1)
	_rows = maxi(rows, 1)
	fps = fps_
	loop = loop_
	ping_pong = ping_pong_
	frame_count = _cols * _rows
	_order = range(frame_count)
	if ping_pong and frame_count > 2:
		for i in range(frame_count - 2, 0, -1):
			_order.append(i)
	_atlas.atlas = _sheet
	texture = _atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(_sheet.get_width() / float(_cols), _sheet.get_height() / float(_rows))
	_show(0)

func play() -> void:
	_t = 0.0
	_playing = true
	_show(0)

func stop() -> void:
	_playing = false

func _show(i: int) -> void:
	var f: int = _order[clampi(i, 0, _order.size() - 1)]
	var fw: float = _sheet.get_width() / float(_cols)
	var fh: float = _sheet.get_height() / float(_rows)
	_atlas.region = Rect2((f % _cols) * fw, (f / _cols) * fh, fw, fh)

func _process(delta: float) -> void:
	if not _playing or _sheet == null:
		return
	_t += delta
	var i := int(_t * fps)
	if i >= _order.size():
		if loop:
			_t = fmod(_t, _order.size() / fps)
			i = int(_t * fps)
		else:
			_playing = false
			_show(_order.size() - 1)
			finished.emit()
			return
	_show(i)
