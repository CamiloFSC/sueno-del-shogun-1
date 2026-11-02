extends SceneTree
## QA: Rennyo (35) puede entrar al propio Complejo y dejar 2 miembros con capacidad 1; Matrimonio arreglado tampoco normaliza.
func fresh() -> Game:
	CardDB.load_all()
	var g := Game.new()
	g.setup(DeckStore.preset_deck(3), DeckStore.preset_deck(3), 5, ["A", "B"])
	g.turn_player = 0; g.phase = "MAIN"
	return g

func pick(g: Game, card_id: int) -> void:
	for i in g.pending.options.size():
		if g.pending.options[i].get("card", 0) == card_id:
			g.choose([i]); return
	print("  (no hay opción ", card_id, ")")

func _init() -> void:
	# Caso 1: Rennyo se mete al templo cuando ya hay otro miembro
	var g := fresh()
	var pl = g.players[0]
	pl.active = 35; pl.passive = [34, 36]
	pl.temple = {"heroes": []}
	g.use_ability(9001); pick(g, 36)
	print("Tras entrar 36: miembros=", pl.temple.heroes.size(), " cap=", Effects.temple_cap(g, 0))
	g.ability_uses = [{}, {}]
	var ok := g.use_ability(9001)
	if ok and g.phase == "CHOICE": pick(g, 35)
	print("Tras entrar Rennyo: miembros=", pl.temple.heroes.size(), " cap=", Effects.temple_cap(g, 0), " -> BUG si miembros > cap")
	# Caso 2: Matrimonio descarta a Rennyo con 2 miembros dentro
	g = fresh(); pl = g.players[0]
	pl.active = 35; pl.passive = [10, 28, 36]
	pl.temple = {"heroes": [{"id": 34, "left": 2}, {"id": 37, "left": 2}]}
	pl.hand = [92, 1, 2, 3]
	g.play_action(0)
	print("fase=", g.phase)
	if g.phase == "CHOICE":
		for i in g.pending.options.size():
			if 35 in g.pending.options[i].value: g.choose([i]); break
	print("Caso2 tras Matrimonio: miembros=", pl.temple.heroes.size(), " cap=", Effects.temple_cap(g, 0), " Rennyo en juego=", 35 in g.heroes_in_play(0))
	quit()
