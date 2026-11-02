extends SceneTree
## Simulación de estrés: mazos cargados de cartas con habilidades (A/D) para comprobar que la IA
## las usa sin atascarse ni perder cartas. Uso: godot --headless --path . -s tests/sim_ability.gd

func _count(pl: Dictionary) -> int:
	return pl.deck.size() + pl.hand.size() + pl.castle.size() + pl.discard.size() + pl.passive.size() + (1 if pl.active != 0 else 0)

func _deck(rng: RandomNumberGenerator) -> Array:
	var pool := [11, 12, 18, 22, 25, 49, 50, 51, 55, 57, 62, 64, 66, 68, 71, 74, 88, 10, 54, 59]
	var deck := []
	for id in pool:
		deck.append(id)
		deck.append(id)
	var extra := [3, 7, 20, 40, 45, 46, 47, 56, 58, 60]
	while deck.size() < 50:
		deck.append(extra[deck.size() % extra.size()])
	DeckBuilder.shuffle(deck, rng)
	return deck

func _init() -> void:
	CardDB.load_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var stuck := 0
	var broken := 0
	var used := 0
	var n := 300
	for k in n:
		var g := Game.new()
		g.setup(_deck(rng), _deck(rng), 3000 + k, ["A", "B"])
		var guard := 0
		while g.phase != "OVER" and guard < 6000:
			AI.act(g)
			guard += 1
			if g.card_total(0) + g.card_total(1) != 100:
				broken += 1
		if g.phase != "OVER":
			stuck += 1
		for l in g.log_lines:
			if "genera" in l and ("Honor" in l) and ("Rukkaku" in l or "Yoshiaki" in l or "Mitsunari" in l or "Ieyasu" in l):
				used += 1
				break
	print("Partidas: %d | atascadas: %d | invariantes rotas: %d | partidas donde se usaron habilidades: %d" % [n, stuck, broken, used])
	quit()
