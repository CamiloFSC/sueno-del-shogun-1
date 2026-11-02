class_name CardInfo
extends RefCounted
## Información de revisión de cada carta: texto del efecto, cómo lo interpreta el juego y si funciona.

static var _detalles: Dictionary = {}

static func _load() -> void:
	if not _detalles.is_empty():
		return
	var f := FileAccess.open("res://data/detalles.csv", FileAccess.READ)
	if f == null:
		return
	var header: PackedStringArray = f.get_csv_line()
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() >= 2 and row[0].strip_edges() != "":
			_detalles[int(row[0])] = row[1]

## Cómo funciona la carta en el juego (texto de interpretación del motor).
static func detail(id: int) -> String:
	_load()
	return _detalles.get(id, "(Sin descripción del motor.)")

## ¿Tiene su efecto implementado en el juego?
static func works(id: int) -> bool:
	var c: Dictionary = CardDB.cards[id]
	if c.categoria == "Accion":
		return Effects.is_implemented_action(id)
	return id in Effects.WARRIORS_WITH_EFFECT

static func status_text(id: int) -> String:
	if works(id):
		return "FUNCIONA en el juego"
	return "NO FUNCIONA: efecto sin implementar (juega solo con su ataque y coste)"

## Tipo legible: "Guerrero · Clan Takeda · Ataque 1 · Honor 1 · Efecto B (en batalla)".
static func header(id: int) -> String:
	var c: Dictionary = CardDB.cards[id]
	if c.categoria == "Accion":
		return "N° %d · Acción Bushi%s" % [id, " · Giratoria" if str(c.get("giratorio", "")) != "" else ""]
	return "N° %d · %s · Clan %s · Ataque %d · Honor %d · Efecto %s" % [id, c.categoria, c.clan, c.ataque, c.costo_honor, c.duracion]

## Ids de las 99 cartas reales, en orden de colección.
static func collection_ids() -> Array:
	var ids := []
	for id in CardDB.cards:
		if id < CardDB.TOKEN_ID:
			ids.append(id)
	ids.sort()
	return ids

static func working_count() -> int:
	var n := 0
	for id in collection_ids():
		if works(id):
			n += 1
	return n
