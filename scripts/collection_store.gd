class_name CollectionStore
extends RefCounted
## Colección del jugador: qué cartas tiene desbloqueadas y cuántos sobres sin abrir.
## Se empieza con un mazo inicial; cada duelo de campaña ganado por primera vez da un sobre.
## Guardado en user://coleccion.json.

const SAVE_PATH := "user://coleccion.json"

## Mazo inicial (50 cartas): [[id, copias], ...]. Las cartas distintas de este mazo forman la colección inicial.
const STARTER := [[10, 3], [11, 3], [12, 3], [16, 3], [17, 3], [18, 3], [62, 3],
	[71, 3], [74, 3], [79, 3], [82, 3], [83, 3], [84, 3], [88, 3], [95, 3], [99, 3], [72, 2]]
const PACK_WARRIORS := 2
const PACK_ACTIONS := 2
const PACK_DAIMYOS := 1

static func starter_deck() -> Array:
	return DeckStore.from_pairs(STARTER)

static func _starter_ids() -> Array:
	var ids := []
	for p in STARTER:
		ids.append(p[0])
	return ids

static func _load() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
	return {"cartas": _starter_ids(), "sobres": 0}

static func _save(d: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))

## Ids de cartas que el jugador tiene, como diccionario {id: true}.
static func owned() -> Dictionary:
	var out := {}
	for v in _load().get("cartas", []):
		out[int(v)] = true
	return out

static func has(id: int) -> bool:
	return owned().has(id)

static func count() -> int:
	return owned().size()

static func total() -> int:
	return CardInfo.collection_ids().size()

static func pending() -> int:
	return int(_load().get("sobres", 0))

static func add_pending(n: int = 1) -> void:
	var d := _load()
	d["sobres"] = int(d.get("sobres", 0)) + n
	_save(d)

static func unlock_all() -> void:
	var d := _load()
	d["cartas"] = CardInfo.collection_ids()
	_save(d)

static func reset() -> void:
	_save({"cartas": _starter_ids(), "sobres": 0})

## ¿Todas las cartas del mazo están desbloqueadas?
static func deck_ok(deck: Array) -> bool:
	var o := owned()
	for id in deck:
		if not o.has(id):
			return false
	return true

## Elige `n` cartas de la categoría, prefiriendo las que aún no se tienen (sin repetir dentro del sobre).
static func _draw(rng: RandomNumberGenerator, cat: String, n: int, have: Dictionary) -> Array:
	var fresh := []
	var old := []
	for id in CardInfo.collection_ids():
		if CardDB.cards[id].categoria != cat:
			continue
		if have.has(id):
			old.append(id)
		else:
			fresh.append(id)
	DeckBuilder.shuffle(fresh, rng)
	DeckBuilder.shuffle(old, rng)
	return (fresh + old).slice(0, n)

## Abre un sobre: devuelve {"cartas": [ids], "nuevas": [ids]} o {} si no hay sobres.
static func open_pack(rng: RandomNumberGenerator = null) -> Dictionary:
	var d := _load()
	if int(d.get("sobres", 0)) <= 0:
		return {}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var have := owned()
	var cards := []
	cards.append_array(_draw(rng, "Guerrero", PACK_WARRIORS, have))
	cards.append_array(_draw(rng, "Accion", PACK_ACTIONS, have))
	cards.append_array(_draw(rng, "Daimyo", PACK_DAIMYOS, have))
	var news := []
	for id in cards:
		if not have.has(id):
			news.append(id)
			have[id] = true
	d["cartas"] = have.keys()
	d["sobres"] = int(d["sobres"]) - 1
	_save(d)
	return {"cartas": cards, "nuevas": news}
