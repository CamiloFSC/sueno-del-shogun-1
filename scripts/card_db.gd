class_name CardDB
extends RefCounted
## Carga data/cartas.csv. Cada carta es un Dictionary con:
## id, nombre, categoria (Guerrero/Daimyo/Accion), clan, ataque, costo_honor,
## duracion (A/B/C/D), frecuencia, tipo_efecto, efecto

const TOKEN_ID := 900

static var cards: Dictionary = {}

static func load_all(path: String = "res://data/cartas.csv") -> void:
	if not cards.is_empty():
		return
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "No se pudo abrir " + path)
	var header: PackedStringArray = f.get_csv_line()
	header[0] = header[0].trim_prefix("﻿")
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() < header.size():
			continue
		var d := {}
		for i in header.size():
			d[header[i]] = row[i]
		d["id"] = int(d["id"])
		d["ataque"] = int(d["ataque"]) if d["ataque"] != "" else 0
		d["costo_honor"] = int(d["costo_honor"]) if d["costo_honor"] != "" else 0
		d["giratorio"] = d.get("giratorio", "")
		cards[d["id"]] = d
	# Ficha de "Castillo de montaña": guerrero 1/1 Ronin sin efecto (no está en ningún mazo)
	cards[TOKEN_ID] = {"id": TOKEN_ID, "nombre": "Soldado del castillo", "categoria": "Guerrero", "clan": "Ronin",
		"ataque": 1, "costo_honor": 1, "duracion": "D", "frecuencia": "", "tipo_efecto": "", "giratorio": "",
		"efecto": "Ficha 1/1 Ronin sin efecto (Castillo de montaña). Al morir, la carta que la respalda va al pozo boca arriba."}
