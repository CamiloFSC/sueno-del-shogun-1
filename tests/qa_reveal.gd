extends SceneTree
func _init() -> void:
	CardDB.load_all()
	var keys := ["Se revela Cortesía", "Se revela Muerte Honorable", "Liderazgo:", "destruye la carta boca abajo", "El destino del clan:", "Matrimonio arreglado:"]
	var cnt := {}
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	for k in 1500:
		var g := Game.new()
		g.setup(DeckStore.preset_deck(k % 7), DeckStore.preset_deck((k / 7) % 7), 77 + k, ["A", "B"])
		var n := 0
		while g.phase != "OVER" and n < 6000:
			AI.act(g); n += 1
		for l in g.log_lines:
			for key in keys:
				if key in l: cnt[key] = cnt.get(key, 0) + 1
	print(cnt)
	quit()
