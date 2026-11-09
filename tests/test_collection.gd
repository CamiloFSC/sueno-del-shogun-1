extends SceneTree
## Colección: mazo inicial, sobres (2 guerreros + 2 acciones + 1 daimyo), cartas nuevas primero, desbloqueo.
var fails := 0
var total := 0

func check(name: String, cond: bool) -> void:
	total += 1
	print(("PASS  " if cond else "FAIL  ") + name)
	if not cond:
		fails += 1

func _init() -> void:
	CardDB.load_all()
	CollectionStore.reset()
	var st := CollectionStore.starter_deck()
	check("Mazo inicial válido (%s)" % DeckStore.problem(st), DeckStore.problem(st) == "")
	check("Todas las cartas del mazo inicial están desbloqueadas", CollectionStore.deck_ok(st))
	check("Empieza con 17 cartas", CollectionStore.count() == 17)
	check("Sin sobres no se abre nada", CollectionStore.open_pack().is_empty())
	var opts := DeckStore.options_owned()
	check("Con la colección inicial solo hay mazo inicial", opts.size() == 1 and opts[0].label == "Mazo inicial")
	CollectionStore.add_pending(2)
	check("Sobres pendientes = 2", CollectionStore.pending() == 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var r := CollectionStore.open_pack(rng)
	var g := 0
	var a := 0
	var d := 0
	for id in r.cartas:
		match CardDB.cards[id].categoria:
			"Guerrero": g += 1
			"Accion": a += 1
			"Daimyo": d += 1
	check("Sobre: 2 guerreros, 2 bushi y 1 daimyo", g == 2 and a == 2 and d == 1 and r.cartas.size() == 5)
	check("Sobre nuevo: las 5 son cartas nuevas", r.nuevas.size() == 5)
	check("La colección crece a 22 y queda 1 sobre", CollectionStore.count() == 22 and CollectionStore.pending() == 1)
	var uniq := {}
	for id in r.cartas:
		uniq[id] = true
	check("Sin cartas repetidas dentro del sobre", uniq.size() == 5)
	CollectionStore.unlock_all()
	var r2 := CollectionStore.open_pack(rng)
	check("Con todo desbloqueado salen cartas repetidas, no nuevas", r2.nuevas.is_empty() and r2.cartas.size() == 5)
	check("Con todo desbloqueado hay todos los mazos temáticos", DeckStore.options_owned().size() >= DeckStore.PRESETS.size() + 1)
	check("Holográfico solo en Daimyos", CardFx.is_holo(55) and not CardFx.is_holo(10))
	CollectionStore.reset()
	check("Reiniciar vuelve a las 17 iniciales y 0 sobres", CollectionStore.count() == 17 and CollectionStore.pending() == 0)
	print("PRUEBAS: %d | FALLAS: %d" % [total, fails])
	quit(1 if fails > 0 else 0)
