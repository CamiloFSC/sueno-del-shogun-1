class_name CardFx
extends RefCounted
## Efectos visuales de cartas: holográfico (algunos Daimyos) e incógnito (cartas aún no obtenidas).

## Daimyos con efecto holográfico.
const HOLO := [55, 56, 57, 58, 59, 60]

static var _holo: Shader
static var _inc: Shader

static func is_holo(id: int) -> bool:
	return id in HOLO

static func holo_material() -> ShaderMaterial:
	if _holo == null:
		_holo = load("res://assets/shaders/holo.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _holo
	return m

static func incognito_material() -> ShaderMaterial:
	if _inc == null:
		_inc = load("res://assets/shaders/incognito.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _inc
	return m

## Aplica a un TextureRect el efecto que le corresponde a la carta (o ninguno).
static func apply(rect: CanvasItem, id: int, owned: bool = true) -> void:
	if not owned:
		rect.material = incognito_material()
	elif is_holo(id):
		rect.material = holo_material()
	else:
		rect.material = null
