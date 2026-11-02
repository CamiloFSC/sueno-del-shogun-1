extends SceneTree
## QA: MODE=rand|preset N= SEED= OUT=. Estadísticas de atascos, invariante, turnos y cobertura de cartas.
func rand_deck(rng: RandomNumberGenerator) -> Array:
	var heroes := []
	var acts := []
	for id in CardDB.cards:
		if id >= CardDB.TOKEN_ID:
			continue
		if CardDB.cards[id].categoria == "Accion":
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
	var mode := OS.get_environment("MODE")
	var seed_v := int(OS.get_environment("SEED"))
	var n := int(OS.get_environment("N"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5000 + seed_v
	var names := {}
	for id in CardDB.cards:
		if id < CardDB.TOKEN_ID: names[id] = CardDB.cards[id].nombre
	var order := names.keys()
	order.sort_custom(func(a, b): return names[a].length() > names[b].length())
	var plays := {}; var mentions := {}; var indeck := {}; var fd_set := {}
	var stuck := 0; var broken := 0; var broken_games := []; var over200 := 0; var maxturn := 0; var turns_sum := 0; var short := 0
	var stuck_seeds := []; var wins := [0, 0]; var done := 0
	var np := DeckStore.PRESETS.size()
	for k in n:
		var da: Array; var db: Array
		if mode == "preset":
			da = DeckStore.preset_deck(k % np); db = DeckStore.preset_deck((k / np) % np)
		else:
			da = rand_deck(rng); db = rand_deck(rng)
		var g := Game.new()
		g.setup(da, db, seed_v * 1000000 + k + 1, ["A", "B"])
		for id in da + db: indeck[id] = indeck.get(id, 0) + 1
		var guard := 0; var bad := false; var lastfd := 0
		while g.phase != "OVER" and guard < 6000:
			AI.act(g)
			guard += 1
			if g.card_total(0) + g.card_total(1) != 100 and not bad:
				bad = true; broken += 1
				if broken_games.size() < 5: broken_games.append("%s seed=%d k=%d paso=%d tot=%d" % [mode, seed_v, k, guard, g.card_total(0) + g.card_total(1)])
		if g.phase != "OVER":
			stuck += 1
			if stuck_seeds.size() < 5: stuck_seeds.append("%s seed=%d k=%d fase=%s" % [mode, seed_v, k, g.phase])
		else:
			wins[g.winner] += 1
		done += 1
		maxturn = maxi(maxturn, g.turn_number); turns_sum += g.turn_number
		if g.turn_number > 200: over200 += 1
		if g.turn_number < 6: short += 1
		for l in g.log_lines:
			if l.begins_with("— Turno"): continue
			for id in order:
				var nm: String = names[id]
				if l.begins_with(nm + " ") or l.begins_with(nm + ":") or l.contains(" " + nm + ": ") or l.begins_with("¡" + nm) or l.begins_with("¡Se revela " + nm) or l.contains(" " + nm + " (") and not l.contains("baja a"):
					if not (l.begins_with(nm + " es derrotado") or l.begins_with(nm + " pasa a la zona") or l.begins_with(nm + " ataca") or l.begins_with(nm + " entra al") or l.begins_with(nm + " sale del")):
						mentions[id] = mentions.get(id, 0) + 1
			if l.contains(" baja a "):
				for id in order:
					if l.contains(" baja a " + names[id] + " ("): plays[id] = plays.get(id, 0) + 1
			if l.contains(" juega "):
				for id in order:
					if l.ends_with(" juega " + names[id] + "."): plays[id] = plays.get(id, 0) + 1
	var f := FileAccess.open(OS.get_environment("OUT"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"games": done, "stuck": stuck, "broken": broken, "broken_games": broken_games, "stuck_seeds": stuck_seeds, "over200": over200, "maxturn": maxturn, "turns_sum": turns_sum, "short": short, "wins": wins, "plays": plays, "mentions": mentions, "indeck": indeck, "facedown_set": fd_set}))
	f.close()
	print("fin %s seed %d" % [mode, seed_v])
	quit()
