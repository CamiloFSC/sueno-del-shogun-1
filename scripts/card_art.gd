class_name CardArt
extends RefCounted
## Busca la imagen de una carta en res://assets/cartas/ (por número o por nombre).

const DIR := "res://assets/cartas/"
const EXTS := ["png", "jpg", "jpeg", "jfif", "webp"]
const MAX_H := 700   # alto máximo en memoria (las imágenes grandes se reducen al cargar)

static var _cache: Dictionary = {}

static func slug(s: String) -> String:
	var t := s.to_lower().strip_edges()
	for pair in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"], ["ū", "u"]]:
		t = t.replace(pair[0], pair[1])
	var out := ""
	for ch in t:
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif not out.ends_with("_"):
			out += "_"
	while out.ends_with("_"):
		out = out.left(out.length() - 1)
	return out

static var _index: Dictionary = {}     # {"id": {int: ruta}, "slug": {String: ruta}}

## Carpetas donde se buscan imágenes (la primera que tenga la carta gana).
static func folders() -> Array:
	var out := [DIR]
	out.append(OS.get_executable_path().get_base_dir().path_join("cartas") + "/")
	out.append(ProjectSettings.globalize_path("res://").path_join("cartas") + "/")
	out.append("user://cartas/")
	return out

static func _build_index() -> void:
	_index = {"id": {}, "slug": {}}
	for dir in folders():
		var da := DirAccess.open(dir)
		if da == null:
			continue
		for f in da.get_files():
			var f2: String = f.trim_suffix(".import")
			var ext := f2.get_extension().to_lower()
			if not (ext in EXTS):
				continue
			var base := f2.get_basename()
			var path: String = dir + f2
			var digits := ""
			for ch in base:
				if ch >= "0" and ch <= "9":
					digits += ch
				else:
					break
			if digits != "" and not _index.id.has(int(digits)):
				_index.id[int(digits)] = path
			var sg := slug(base)
			if sg != "" and not _index.slug.has(sg):
				_index.slug[sg] = path

static func _decode(bytes: PackedByteArray) -> Image:
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if bytes.size() > 4 and bytes[0] == 0xFF and bytes[1] == 0xD8:          # JPEG / JFIF
		err = img.load_jpg_from_buffer(bytes)
	elif bytes.size() > 4 and bytes[0] == 0x89 and bytes[1] == 0x50:        # PNG
		err = img.load_png_from_buffer(bytes)
	elif bytes.size() > 12 and bytes[0] == 0x52 and bytes[8] == 0x57:       # WEBP
		err = img.load_webp_from_buffer(bytes)
	return img if err == OK else null

static func _load_path(path: String) -> Texture2D:
	if ResourceLoader.exists(path):             # imagen importada por Godot (png/jpg/webp en res://)
		var r = load(path)
		if r is Texture2D:
			return r
	var bytes := FileAccess.get_file_as_bytes(path)   # cualquier archivo suelto: .jfif, .jpg, etc.
	if bytes.is_empty():
		return null
	var img := _decode(bytes)
	if img == null:
		return null
	if img.get_height() > MAX_H:
		var w := int(round(float(img.get_width()) * MAX_H / img.get_height()))
		img.resize(w, MAX_H, Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func get_texture(id: int) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	if _index.is_empty():
		_build_index()
	var tex: Texture2D = null
	var path := ""
	if _index.id.has(id):
		path = _index.id[id]
	else:
		var sg := slug(CardDB.cards[id].nombre)
		if _index.slug.has(sg):
			path = _index.slug[sg]
	if path != "":
		path = path.trim_suffix(".import")
		tex = _load_path(path)
	_cache[id] = tex
	return tex

static func clear_cache() -> void:
	_cache.clear()
	_index.clear()
