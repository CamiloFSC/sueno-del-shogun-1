extends SceneTree
## Simula partidas IA vs IA y cuenta cuántas veces se usan las cartas boca abajo, fichas, Dilema y Complejo.
func _init() -> void:
	CardDB.load_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var keys := ["coloca una carta boca abajo", "Se revela Cortesía", "Se revela Muerte Honorable", "Liderazgo:", "Dilema del cucu:", "Castillo de montaña:", "construye el Complejo", "entra al Complejo", "sale del Complejo", "Complejo Enryaku-Ji de", "Conspiración:", "Deshonor:", "El Nakasendo:", "Intriga:", "Rectitud Zen:", "El camino:", "Coraje:", "Yoshimoto"]
	var seen := {}
	var stuck := 0
	var broken := 0
	for k in 400:
		var g := Game.new()
		g.setup(DeckBuilder.random_deck(rng), DeckBuilder.random_deck(rng), 3000 + k, ["A", "B"])
		var guard := 0
		var used := {}
		while g.phase != "OVER" and guard < 6000:
			AI.act(g)
			guard += 1
			if g.card_total(0) + g.card_total(1) != 100:
				broken += 1
		if g.phase != "OVER":
			stuck += 1
		for l in g.log_lines:
			for key in keys:
				if key in l:
					used[key] = true
		for key in used:
			seen[key] = seen.get(key, 0) + 1
	print("Partidas: 400 | atascadas: %d | cartas perdidas/duplicadas: %d" % [stuck, broken])
	print("Partidas donde apareció: ", seen)
	quit()
