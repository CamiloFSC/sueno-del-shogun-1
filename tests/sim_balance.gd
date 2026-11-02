extends SceneTree
## Balance: IA vs IA con mazos aleatorios de 50 cartas (máx. 3 copias). Guarda una línea por partida:
## copiasA(99 valores) ; copiasB ; ganador(0=A,1=B) ; quién empezó ; turnos.
## Uso: SEED=1 N=15000 OUT=/ruta/salida.csv godot --headless -s tests/sim_balance.gd
func rand_deck(rng: RandomNumberGenerator) -> Array:
	var heroes := []
	var acts := []
	for id in CardDB.cards:
		if id >= CardDB.TOKEN_ID:
			continue
		var cat: String = CardDB.cards[id].categoria
		if cat == "Accion":
			if id in Effects.ACTIONS:
				for k in 3: acts.append(id)
		else:
			for k in 3: heroes.append(id)
	DeckBuilder.shuffle(heroes, rng)
	DeckBuilder.shuffle(acts, rng)
	var nh := rng.randi_range(22, 32)
	return heroes.slice(0, nh) + acts.slice(0, 50 - nh)

func _init() -> void:
	CardDB.load_all()
	var seed_v := int(OS.get_environment("SEED"))
	var n := int(OS.get_environment("N"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + seed_v
	var f := FileAccess.open(OS.get_environment("OUT"), FileAccess.WRITE)
	var stuck := 0
	for k in n:
		var da := rand_deck(rng)
		var db := rand_deck(rng)
		var g := Game.new()
		g.setup(da, db, seed_v * 1000000 + k, ["A", "B"])
		var first: int = g.turn_player
		var guard := 0
		while g.phase != "OVER" and guard < 6000:
			AI.act(g)
			guard += 1
		if g.phase != "OVER":
			stuck += 1
			continue
		var ca := PackedInt32Array()
		var cb := PackedInt32Array()
		ca.resize(100); cb.resize(100)
		for id in da: ca[id] += 1
		for id in db: cb[id] += 1
		var sa := []
		var sb := []
		for id in range(1, 100):
			sa.append(str(ca[id]))
			sb.append(str(cb[id]))
		f.store_line("%s;%s;%d;%d;%d" % [",".join(sa), ",".join(sb), g.winner, first, g.turn_number])
	f.close()
	print("hecho seed %d, atascadas %d" % [seed_v, stuck])
	quit()
