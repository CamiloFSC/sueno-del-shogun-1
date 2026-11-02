extends SceneTree
## Fuzzer: jugadas legales aleatorias (no la IA). N=partidas SEED=semilla. Revisa invariantes de estado.
var rng := RandomNumberGenerator.new()

func rand_deck() -> Array:
	var heroes := []; var acts := []
	for id in CardDB.cards:
		if id >= CardDB.TOKEN_ID: continue
		if CardDB.cards[id].categoria == "Accion":
			if id in Effects.ACTIONS:
				for k in 3: acts.append(id)
		else:
			for k in 3: heroes.append(id)
	DeckBuilder.shuffle(heroes, rng); DeckBuilder.shuffle(acts, rng)
	var nh := rng.randi_range(20, 30)
	return heroes.slice(0, nh) + acts.slice(0, 50 - nh)

func check(g: Game) -> String:
	if g.card_total(0) + g.card_total(1) != 100: return "total=%d" % (g.card_total(0) + g.card_total(1))
	for p in 2:
		var pl = g.players[p]
		if pl.passive.size() > 3: return "pasivos>3 p%d" % p
		if pl.active == 0 and not pl.passive.is_empty() and g.phase == "WINDOW": return "activo vacio con pasivos en ventana"
		var tok := 0
		for h in g.heroes_in_play(p): if h == CardDB.TOKEN_ID: tok += 1
		if not pl.temple.is_empty():
			for t in pl.temple.heroes: if t.id == CardDB.TOKEN_ID: tok += 1
		if tok != pl.shadow.size(): return "fichas=%d shadow=%d p%d" % [tok, pl.shadow.size(), p]
		for h in pl.passive: if h == 0: return "pasivo 0"
		if pl.honor < 0: return "honor<0 p%d (%d)" % [p, pl.honor]
		for c in pl.hand + pl.deck + pl.castle + pl.discard: if not CardDB.cards.has(c) or c == CardDB.TOKEN_ID: return "carta invalida %d" % c
		if pl.facedown.size() > 2: return "facedown>2"
	return ""

func step(g: Game) -> void:
	var p := g.actor()
	var pl = g.players[p]
	match g.phase:
		"MAIN":
			var opts := []
			for i in pl.hand.size():
				var id: int = pl.hand[i]
				if g.card(id).categoria == "Accion":
					if Effects.can_play(g, p, id): opts.append(["a", i])
				elif g.can_play_warrior(p, id): opts.append(["w", i])
			for ab in g.available_abilities(): opts.append(["u", ab.id])
			if g.can_swap_active(p): opts.append(["s", rng.randi() % pl.passive.size()])
			if pl.active != 0:
				opts.append(["t", "castillo"]); 
				if g.players[1 - p].active != 0: opts.append(["t", "guerrero"])
			opts.append(["e", 0])
			var o = opts[rng.randi() % opts.size()]
			var ok := true
			match o[0]:
				"a": ok = g.play_action(o[1])
				"w": ok = g.play_warrior(o[1])
				"u": ok = g.use_ability(o[1])
				"s": ok = g.swap_active(o[1])
				"t": ok = g.declare_attack(o[1])
				"e": ok = g.end_turn()
			if not ok: print("ACCION RECHAZADA ", o, " fase=", g.phase)
		"DEFENDER_CHOICE": g.respond(rng.randi() % 2 == 0)
		"WINDOW":
			var opts := []
			for i in pl.hand.size():
				var id: int = pl.hand[i]
				if g.card(id).categoria == "Accion" and Effects.can_play(g, p, id): opts.append(i)
			if not opts.is_empty() and rng.randf() < 0.6:
				g.play_action(opts[rng.randi() % opts.size()])
			else:
				g.pass_priority()
		"DISCARD": g.discard_card(rng.randi() % g.players[g.turn_player].hand.size())
		"CHOICE":
			var pd: Dictionary = g.pending
			var k: int = pd.valid[rng.randi() % pd.valid.size()]
			var idx := range(pd.options.size())
			idx.shuffle()
			if not g.choose(idx.slice(0, k)): print("CHOICE RECHAZADA ", pd.prompt)

func _init() -> void:
	CardDB.load_all()
	var seed_v := int(OS.get_environment("SEED")); var n := int(OS.get_environment("N"))
	rng.seed = 900 + seed_v
	var played := {}; var bugs := {}; var stuck := 0; var maxt := 0; var done := 0
	for k in n:
		var g := Game.new()
		g.setup(rand_deck(), rand_deck(), seed_v * 100000 + k + 1, ["A", "B"])
		var guard := 0
		var last_log := 0
		while g.phase != "OVER" and guard < 6000:
			step(g); guard += 1
			var msg := check(g)
			if msg != "":
				var key := msg.split(" p")[0]
				if not bugs.has(key): bugs[key] = "seed=%d k=%d paso=%d fase=%s :: %s" % [seed_v, k, guard, g.phase, g.log_lines.slice(-4)]
				break
		if g.phase != "OVER" and guard >= 6000: stuck += 1; bugs["STUCK"] = "seed=%d k=%d fase=%s %s" % [seed_v, k, g.phase, g.log_lines.slice(-3)]
		maxt = maxi(maxt, g.turn_number); done += 1
		for l in g.log_lines:
			if " juega " in l:
				var id := -1
				for c in CardDB.cards:
					if c < 900 and l.ends_with(" juega " + CardDB.cards[c].nombre + "."): id = c
				if id >= 0: played[id] = played.get(id, 0) + 1
	print("FUZZ games=%d stuck=%d maxturn=%d" % [done, stuck, maxt])
	for b in bugs: print("BUG ", b, " -> ", bugs[b])
	var miss := []
	for id in range(70, 100):
		if not played.has(id): miss.append(id)
	print("acciones nunca jugadas: ", miss, " 74=", played.get(74, 0), " 92=", played.get(92, 0))
	quit()
