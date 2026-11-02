class_name UiFont
extends RefCounted
## Fuente de toda la interfaz. Busca archivos .ttf/.otf en assets/fuentes/ (o fuentes/ junto al ejecutable
## o user://fuentes/). Se prefiere el que tenga «harukaze» en el nombre. Si falta algún carácter (tildes, ñ,
## números) se completa con la fuente por defecto. Sin archivos, se usa la fuente por defecto.

const EXTS := ["ttf", "otf", "woff", "woff2"]
static var _theme: Theme = null
static var _tried := false

static func folders() -> Array:
	var out := ["res://assets/fuentes/", "user://fuentes/"]
	out.append(OS.get_executable_path().get_base_dir().path_join("fuentes") + "/")
	return out

static func find_font_path() -> String:
	var best := ""
	for f in folders():
		for fn in DirAccess.get_files_at(f):
			var fname: String = fn
			if fname.ends_with(".import") or fname.ends_with(".remap"):
				fname = fname.trim_suffix(".import").trim_suffix(".remap")
			if fname.get_extension().to_lower() not in EXTS:
				continue
			var path: String = f + fname
			if "harukaze" in fname.to_lower():
				return path
			if best == "":
				best = path
	return best

static func load_font(path: String) -> Font:
	var fnt: Font = null
	if ResourceLoader.exists(path):
		fnt = load(path) as Font
	if fnt == null and FileAccess.file_exists(path):
		var ff := FontFile.new()
		ff.data = FileAccess.get_file_as_bytes(path)
		fnt = ff
	return fnt

static func theme() -> Theme:
	if _tried:
		return _theme
	_tried = true
	var path := find_font_path()
	if path == "":
		return null
	var fnt := load_font(path)
	if fnt == null:
		return null
	fnt.fallbacks = [ThemeDB.fallback_font]
	_theme = Theme.new()
	_theme.default_font = fnt
	return _theme

## Aplica la fuente a una raíz de interfaz (todos sus hijos la heredan).
static func apply(c: Control) -> void:
	var th := theme()
	if th != null:
		c.theme = th
