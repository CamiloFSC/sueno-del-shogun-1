extends SceneTree
## Mazos: validación, mazos temáticos, guardado y partidas completas con cada mazo temático.
var fails := 0
var total := 0

func check(name: String, cond: bool) -> void:
	total += 1
	print(("PASS  " if cond else "FAIL  ") + name)
	if not cond:
		fails += 1

func _init() -> void:
	CardDB.load_all()
	for i in DeckStore.PRESETS.size():
		var d := DeckStore.preset_deck(i)
		check("Mazo temático «%s» válido (%s)" % [DeckStore.PRESETS[i].nombre, DeckStore.problem(d)], DeckStore.problem(d) == "")
	check("49 cartas es inválido", DeckStore.problem(DeckStore.preset_deck(0).slice(0, 49)) != "")
	var four := DeckStore.preset_deck(0).slice(0, 46) + [1, 1, 1, 1]
	check("4 copias es inválido", DeckStore.problem(four) != "")
	check("Mazo al azar del juego es válido", DeckStore.problem(DeckBuilder.random_deck(RandomNumberGenerator.new())) == "")
	# guardado
	var d := DeckStore.preset_deck(1)
	check("No guarda un mazo sin nombre", DeckStore.save_deck("  ", d) != "")
	check("No guarda un mazo incompleto", DeckStore.save_deck("Prueba", d.slice(0, 30)) != "")
	check("Guarda un mazo válido", DeckStore.save_deck("Prueba tests", d) == "")
	var saved := DeckStore.load_saved()
	check("El mazo guardado se recupera igual", saved.has("Prueba tests") and DeckStore.counts_of(saved["Prueba tests"]) == DeckStore.counts_of(d))
	var found := false
	for o in DeckStore.all_options():
		if o.label == "★ Prueba tests":
			found = true
	check("Aparece entre las opciones de partida", found)
	DeckStore.delete_deck("Prueba tests")
	check("Se puede borrar", not DeckStore.load_saved().has("Prueba tests"))
	# partidas completas: cada mazo temático contra otro (IA vs IA)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var stuck := 0
	var broken := 0
	var wins := {}
	for i in DeckStore.PRESETS.size():
		for j in DeckStore.PRESETS.size():
			for k in 6:
				var g := Game.new()
				g.setup(DeckStore.preset_deck(i), DeckStore.preset_deck(j), 100 + i * 100 + j * 10 + k, ["A", "B"])
				var guard := 0
				while g.phase != "OVER" and guard < 6000:
					AI.act(g)
					guard += 1
					if g.card_total(0) + g.card_total(1) != 100:
						broken += 1
				if g.phase != "OVER":
					stuck += 1
				else:
					var w: String = DeckStore.PRESETS[i].nombre if g.winner == 0 else DeckStore.PRESETS[j].nombre
					wins[w] = wins.get(w, 0) + 1
	check("Partidas con mazos temáticos: ninguna atascada", stuck == 0)
	check("Partidas con mazos temáticos: sin cartas perdidas", broken == 0)
	print("Victorias por mazo: ", wins)
	print("\nPRUEBAS: %d | FALLAS: %d" % [total, fails])
	quit(1 if fails > 0 else 0)
