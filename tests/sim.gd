extends SceneTree
## Simula N partidas IA vs IA y comprueba invariantes. Uso:
## godot --headless --path . -s tests/sim.gd

func _count(pl: Dictionary) -> int:
	return pl.deck.size() + pl.hand.size() + pl.castle.size() + pl.discard.size() + pl.passive.size() + (1 if pl.active != 0 else 0)

func _init() -> void:
	CardDB.load_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n_games := 500
	var wins := [0, 0]
	var total_turns := 0
	var max_turns := 0
	var stuck := 0
	var broken := 0
	var reasons := {}
	for k in n_games:
		var g := Game.new()
		g.setup(DeckBuilder.random_deck(rng), DeckBuilder.random_deck(rng), 1000 + k, ["A", "B"])
		var guard := 0
		while g.phase != "OVER" and guard < 5000:
			AI.act(g)
			guard += 1
			# Akechi Mitsuhide (69) puede robar un Daimyo: el total de ambos jugadores debe seguir en 100.
			if g.card_total(0) + g.card_total(1) != 100:
				broken += 1
				if broken < 4:
					print("INVARIANTE ROTA partida ", k, " total = ", g.card_total(0) + g.card_total(1))
		if g.phase != "OVER":
			stuck += 1
			continue
		wins[g.winner] += 1
		total_turns += g.turn_number
		max_turns = max(max_turns, g.turn_number)
		var last: String = g.log_lines[-1]
		var key := "castillo" if "castillo" in last else "mazo"
		reasons[key] = reasons.get(key, 0) + 1
	print("Partidas: %d | atascadas: %d | invariantes rotas: %d" % [n_games, stuck, broken])
	print("Victorias A/B: %s | turnos medios: %.1f | máx: %d" % [str(wins), float(total_turns) / max(1, n_games - stuck), max_turns])
	print("Cómo terminan: ", reasons)
	quit()
