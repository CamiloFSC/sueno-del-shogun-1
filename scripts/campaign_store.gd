class_name CampaignStore
extends RefCounted
## Modo Campaña Histórica: 8 duelos que se desbloquean al ganar. Progreso en user://campana.json.

const SAVE_PATH := "user://campana.json"

## Orden de la campaña: nombre del mazo temático (DeckStore.PRESETS) y texto del duelo.
const LEVELS := [
	{"titulo": "Kenshin contra Takeda", "mazo": "Clan Takeda", "mazo_alt": "Uesugi e Ikko Ikki", "bando": true, "chars": ["kenshin", "shingen"], "lugar": "Kawanakajima",
		"texto": "El Dragón de Echigo y el Tigre de Kai se miran por última vez. Esta vez TÚ eliges bando: tu aliado te aconsejará como un sabio y el otro será tu rival."},
	{"titulo": "Date Masamune", "mazo": "Clan Date", "chars": ["masamune"], "lugar": "Castillo de Sendai",
		"texto": "El Dragón de un solo ojo y su clan: castillos reforzados y mucho estilo. Llegó tarde a la fiesta de la historia, pero llegó con armadura brillante."},
	{"titulo": "Watanabe Tenzo", "mazo": "Sombras Ninja", "chars": ["tenzo"], "lugar": "Provincia de Iga",
		"texto": "El jefe de los ninja. Todos sus guerreros son shinobi: roban, recuperan del pozo y golpean con muchos dados. No lo verás venir (a veces ni mientras lo miras)."},
	{"titulo": "Ishida Mitsunari", "mazo": "Espadas Ronin", "chars": ["mitsunari"], "lugar": "Caminos de Kyoto",
		"texto": "El administrador más terco del Japón reúne ronin sin amo. Musha Shugyo, Hansei y Kansei para bajar guerreros gratis."},
	{"titulo": "Oda Nobunaga", "mazo": "Clan Oda", "chars": ["nobunaga"], "lugar": "Castillo de Azuchi",
		"texto": "El Demonio del Sexto Cielo. Todo su mazo es Oda: roba cartas, espía y arrasa antes de que termines tu té."},
	{"titulo": "Toyotomi Hideyoshi", "mazo": "Clan Toyotomi", "chars": ["hideyoshi"], "lugar": "Castillo de Osaka",
		"texto": "De mozo de sandalias a Regente. Honor, intriga y recuperar guerreros del pozo: el ascenso social hecho mazo."},
	{"titulo": "Tokugawa Ieyasu", "mazo": "Clan Tokugawa", "chars": ["tokugawa"], "lugar": "Castillo de Edo",
		"texto": "El pájaro que esperó a que cantara. Ceremonia del té, castillo firme y paciencia infinita. Aquí se decide el Shogunato."},
	{"titulo": "El Creador", "mazo": "El Creador", "chars": ["creador"], "boss": true, "lugar": "Más allá de la carta",
		"texto": "El autor de este juego en persona. Su mazo tiene las mejores cartas, juega al máximo nivel, hace trampa... y se burlará de ti. Vencerlo te convierte en Shogun."},
]

static func count() -> int:
	return LEVELS.size()

## Duelos ganados (0..8). El siguiente punto disponible es progress() + 1.
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

## Registra la victoria del duelo `level` (1..8). Devuelve true si desbloquea un punto nuevo.
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

## Mazo temático del duelo `level` (1..8).
static func rival_deck(level: int, alt: bool = false) -> Array:
	var nm: String = _deck_name(level, alt)
	for i in DeckStore.PRESETS.size():
		if DeckStore.PRESETS[i].nombre == nm:
			return DeckStore.preset_deck(i)
	return []

static func rival_name(level: int, alt: bool = false) -> String:
	return _deck_name(level, alt)

static func rival_desc(level: int, alt: bool = false) -> String:
	var nm: String = _deck_name(level, alt)
	for i in DeckStore.PRESETS.size():
		if DeckStore.PRESETS[i].nombre == nm:
			return DeckStore.PRESETS[i].desc
	return ""

## Nombre del mazo rival. En el duelo 1 (con elección de bando) `alt` = tu aliado es Takeda, así que el rival es Uesugi.
static func _deck_name(level: int, alt: bool) -> String:
	var info: Dictionary = LEVELS[level - 1]
	return info.mazo_alt if (alt and info.has("mazo_alt")) else info.mazo
