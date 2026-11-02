class_name CampaignStore
extends RefCounted
## Modo Campaña Histórica: 7 duelos que se desbloquean al ganar. Progreso en user://campana.json.

const SAVE_PATH := "user://campana.json"

## Orden de la campaña: nombre del mazo temático (DeckStore.PRESETS) y texto del duelo.
const LEVELS := [
	{"mazo": "Sombras Ninja", "lugar": "Provincia de Iga", "texto": "Los shinobi acechan en la oscuridad. Quien baja la guardia pierde cartas antes de ver al enemigo."},
	{"mazo": "Espadas Ronin", "lugar": "Caminos de Kyoto", "texto": "Samuráis sin amo venden su espada al mejor postor. Cada Ronin vale por muchos dados."},
	{"mazo": "Kai contra Echigo", "lugar": "Kawanakajima", "texto": "Takeda y Uesugi se enfrentan en la llanura. Trampas boca abajo y duelos de honor."},
	{"mazo": "Templo de Enryaku-Ji", "lugar": "Monte Hiei", "texto": "Los monjes guerreros del Ikko Ikki entrenan héroes en su Complejo y ganan Honor con paciencia."},
	{"mazo": "Casa y Trono", "lugar": "Castillo de Edo", "texto": "Ashikaga, Tokugawa y Chosokabe disputan el trono: Honor, habilidades y control del ritmo."},
	{"mazo": "Alianza del Oeste", "lugar": "Sekigahara", "texto": "Date, Mori y Shimazu forman la gran alianza. Castillos fuertes y guerreros que escalan su ataque."},
	{"mazo": "Unificadores", "lugar": "Castillo de Azuchi", "texto": "Oda y Toyotomi, los unificadores del país. Para ser Shogun hay que vencerlos."},
]

static func count() -> int:
	return LEVELS.size()

## Duelos ganados (0..7). El siguiente punto disponible es progress() + 1.
static func progress() -> int:
	return int(_load().get("progreso", 0))

static func last_deck() -> String:
	return str(_load().get("mazo", ""))

static func _load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

static func _save(d: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))

## Registra la victoria del duelo `level` (1..7). Devuelve true si desbloquea un punto nuevo.
static func complete(level: int) -> bool:
	var d := _load()
	var cur := int(d.get("progreso", 0))
	if level != cur + 1 or level > LEVELS.size():
		return false
	d["progreso"] = level
	_save(d)
	return true

static func remember_deck(label: String) -> void:
	var d := _load()
	d["mazo"] = label
	_save(d)

static func reset() -> void:
	var d := _load()
	d["progreso"] = 0
	_save(d)

## Mazo temático del duelo `level` (1..7).
static func rival_deck(level: int) -> Array:
	var nm: String = LEVELS[level - 1].mazo
	for i in DeckStore.PRESETS.size():
		if DeckStore.PRESETS[i].nombre == nm:
			return DeckStore.preset_deck(i)
	return []

static func rival_desc(level: int) -> String:
	var nm: String = LEVELS[level - 1].mazo
	for i in DeckStore.PRESETS.size():
		if DeckStore.PRESETS[i].nombre == nm:
			return DeckStore.PRESETS[i].desc
	return ""
