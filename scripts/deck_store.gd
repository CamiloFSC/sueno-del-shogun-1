class_name DeckStore
extends RefCounted
## Mazos: validación (50 cartas exactas, máx. 3 copias), mazos temáticos y mazos guardados del jugador.
## Un mazo es un Array de ids de carta (con repeticiones).

const SIZE := 50
const MAX_COPIES := 3
const SAVE_PATH := "user://mazos.json"

## Mazos temáticos prearmados: cartas = [[id, copias], ...]
const PRESETS := [
	{"nombre": "Sombras Ninja", "desc": "Ninjas veloces: roban, recuperan del pozo y golpean con muchos dados.", "cartas": [[1, 3], [2, 3], [3, 3], [4, 2], [5, 2], [6, 2], [7, 3], [8, 3], [61, 2], [71, 3], [72, 1], [74, 2], [79, 3], [82, 2], [83, 2], [84, 2], [88, 1], [91, 3], [94, 1], [95, 3], [97, 2], [99, 2]]},
	{"nombre": "Espadas Ronin", "desc": "Ronin sin amo: Musha Shugyo, Hansei y Kansei para bajar guerreros gratis.", "cartas": [[10, 3], [11, 3], [12, 3], [13, 2], [14, 2], [15, 2], [16, 3], [17, 3], [18, 3], [62, 3], [69, 2], [71, 2], [72, 1], [74, 1], [79, 1], [82, 2], [83, 1], [84, 2], [85, 3], [86, 3], [87, 3], [99, 2]]},
	{"nombre": "Kai contra Echigo", "desc": "Takeda y Uesugi: trampas boca abajo y duelos de honor.", "cartas": [[28, 3], [29, 3], [30, 3], [31, 3], [32, 3], [33, 3], [58, 3], [59, 2], [71, 2], [72, 2], [74, 1], [77, 3], [83, 1], [84, 2], [88, 2], [94, 2], [95, 2], [96, 3], [97, 2], [98, 3], [99, 2]]},
	{"nombre": "Templo de Enryaku-Ji", "desc": "Ikko Ikki: construye el Complejo, entrena héroes y gana Honor con Kenyo.", "cartas": [[31, 2], [32, 2], [33, 2], [34, 3], [35, 3], [36, 3], [59, 2], [66, 3], [71, 3], [72, 2], [74, 2], [82, 2], [83, 2], [84, 2], [88, 2], [89, 2], [90, 3], [94, 1], [95, 2], [96, 2], [98, 2], [99, 3]]},
	{"nombre": "Unificadores", "desc": "Oda y Toyotomi: robo de cartas, Nobutaka y Hidetoshi controlando los dados.", "cartas": [[19, 3], [20, 3], [21, 3], [22, 3], [23, 3], [24, 3], [55, 3], [56, 3], [71, 3], [72, 1], [74, 3], [79, 2], [82, 2], [83, 2], [84, 2], [88, 2], [94, 1], [95, 2], [96, 2], [97, 1], [98, 2], [99, 1]]},
	{"nombre": "Alianza del Oeste", "desc": "Date, Mori y Shimazu: castillos fuertes y guerreros que escalan el ataque.", "cartas": [[37, 3], [38, 3], [39, 3], [40, 3], [41, 3], [42, 2], [46, 3], [47, 3], [48, 3], [60, 3], [65, 2], [71, 2], [72, 1], [74, 2], [82, 3], [83, 2], [84, 1], [88, 3], [94, 1], [95, 2], [99, 2]]},
	{"nombre": "Casa y Trono", "desc": "Ashikaga, Tokugawa, Chosokabe: Honor, habilidades y control del ritmo.", "cartas": [[25, 3], [26, 3], [27, 3], [49, 3], [50, 3], [51, 3], [53, 3], [54, 3], [57, 3], [64, 2], [68, 3], [71, 3], [72, 1], [74, 2], [82, 2], [83, 2], [84, 1], [88, 2], [94, 1], [95, 1], [97, 2], [99, 1]]},
]

## Texto con el problema del mazo, o "" si es válido para jugar.
static func problem(deck: Array) -> String:
	if deck.size() != SIZE:
		return "El mazo tiene %d cartas: necesita exactamente %d." % [deck.size(), SIZE]
	var counts := counts_of(deck)
	for id in counts:
		if not CardDB.cards.has(id) or id >= CardDB.TOKEN_ID:
			return "Carta desconocida: %d." % id
		if counts[id] > MAX_COPIES:
			return "%s tiene %d copias (máximo %d)." % [CardDB.cards[id].nombre, counts[id], MAX_COPIES]
	return ""

static func counts_of(deck: Array) -> Dictionary:
	var c := {}
	for id in deck:
		c[id] = c.get(id, 0) + 1
	return c

static func from_pairs(pairs: Array) -> Array:
	var deck := []
	for p in pairs:
		for i in p[1]:
			deck.append(p[0])
	return deck

static func preset_deck(i: int) -> Array:
	return from_pairs(PRESETS[i].cartas)

## Mazos guardados por el jugador: {nombre: [ids]}.
static func load_saved() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(SAVE_PATH):
		return out
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return out
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for nm in data:
		var deck := []
		for pair in data[nm]:
			for i in int(pair[1]):
				deck.append(int(pair[0]))
		out[nm] = deck
	return out

static func save_all(saved: Dictionary) -> bool:
	var data := {}
	for nm in saved:
		var pairs := []
		var counts := counts_of(saved[nm])
		var ids: Array = counts.keys()
		ids.sort()
		for id in ids:
			pairs.append([id, counts[id]])
		data[nm] = pairs
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true

## Guarda un mazo válido con ese nombre (reemplaza si existía).
static func save_deck(name: String, deck: Array) -> String:
	var nm := name.strip_edges()
	if nm == "":
		return "Ponle un nombre al mazo."
	var err := problem(deck)
	if err != "":
		return err
	var saved := load_saved()
	saved[nm] = deck.duplicate()
	if not save_all(saved):
		return "No se pudo guardar el archivo."
	return ""

static func delete_deck(name: String) -> void:
	var saved := load_saved()
	saved.erase(name)
	save_all(saved)

## Lista de opciones para elegir mazo: [{label, deck}] (guardados, luego temáticos).
static func all_options() -> Array:
	var out := []
	var saved := load_saved()
	var names: Array = saved.keys()
	names.sort()
	for nm in names:
		if problem(saved[nm]) == "":
			out.append({"label": "★ " + nm, "deck": saved[nm], "desc": "Tu mazo guardado."})
	for i in PRESETS.size():
		out.append({"label": PRESETS[i].nombre, "deck": preset_deck(i), "desc": PRESETS[i].desc})
	return out
