extends SceneTree
## Simulación de estrés: mazos cargados con las acciones Bushi nuevas (82, 85, 86, 87, 92, 97) y héroes
## que las activan. Comprueba que no hay atascos ni cartas perdidas y cuenta cuántas veces se usan.
## Uso: godot --headless --path . -s tests/sim_bushi.gd

func _count(pl: Dictionary) -> int:
	return pl.deck.size() + pl.hand.size() + pl.castle.size() + pl.discard.size() + pl.passive.size() + (1 if pl.active != 0 else 0)

func _deck(rng: RandomNumberGenerator) -> Array:
	var acts := [82, 85, 86, 87, 92, 97]
	var deck := []
	for id in acts:
		for k in 3:
			deck.append(id)
	# Takeda (Lealtad), Ronin (Musha), costes 2 y 3 (Hansei/Kansei), clanes variados (Matrimonio)
	var heroes := [28, 29, 30, 58, 10, 11, 12, 13, 14, 15, 16, 17, 4, 5, 8, 9, 19, 22, 25, 49, 53, 54, 60, 61]
	var i := 0
	while deck.size() < 50:
		deck.append(heroes[i % heroes.size()])
		i += 1
	DeckBuilder.shuffle(deck, rng)
	return deck

func _init() -> void:
	CardDB.load_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var n := 400
	var stuck := 0
	var broken := 0
	var used := {"El maestro estratega:": 0, "baja gratis": 0, "Musha Shugyo:": 0, "Matrimonio arreglado:": 0, "Lealtad cumplida": 0, "Lealtad: ": 0}
	for k in n:
		var g := Game.new()
		g.setup(_deck(rng), _deck(rng), 7000 + k, ["A", "B"])
		var guard := 0
		while g.phase != "OVER" and guard < 6000:
			AI.act(g)
			guard += 1
			if g.card_total(0) + g.card_total(1) != 100:
				broken += 1
				break
		if g.phase != "OVER":
			stuck += 1
		for key in used:
			for l in g.log_lines:
				if key in l:
					used[key] += 1
					break
	print("Partidas: %d | atascadas: %d | cartas perdidas/duplicadas: %d" % [n, stuck, broken])
	print("Partidas donde se usó: ", used)
	quit()
