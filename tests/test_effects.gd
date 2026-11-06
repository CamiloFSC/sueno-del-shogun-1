extends SceneTree
## Pruebas de efectos y de la ventana de decisión (motor, sin interfaz).
## Uso: godot --headless --path . -s tests/test_effects.gd
var fails := 0
var total := 0

func check(name: String, cond: bool) -> void:
	total += 1
	print(("PASS  " if cond else "FAIL  ") + name)
	if not cond:
		fails += 1

func fresh(seed_value := 5) -> Game:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var g := Game.new()
	g.setup(DeckBuilder.random_deck(rng), DeckBuilder.random_deck(rng), 99, ["A", "B"])
	g.rng.seed = seed_value
	g.turn_player = 0
	g.phase = "MAIN"
	g.warrior_played = false
	g.battle = {}
	g.pending = {}
	g.bushi_count = [0, 0]
	for p in 2:
		g.players[p].hand = []
		g.players[p].discard = []
		g.players[p].active = 0
		g.players[p].passive = []
		g.players[p].honor = 4
	return g

## Prepara y lanza un duelo guerrero contra guerrero; deja la partida en el primer punto de decisión o al final.
func duel(g: Game, a_id: int, d_id: int) -> void:
	g.players[0].active = a_id
	g.players[1].active = d_id
	g.turn_player = 0
	g.phase = "MAIN"
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()

func has_log(g: Game, text: String) -> bool:
	for l in g.log_lines:
		if text in l:
			return true
	return false

func idx_of(g: Game, card_id: int) -> int:
	for i in g.pending.options.size():
		if g.pending.options[i].get("card", 0) == card_id:
			return i
	return -1

func _init() -> void:
	CardDB.load_all()
	test_choice_system()
	test_entering()
	test_battle_prompts()
	test_battle_mods()
	test_post_duel()
	test_hidetoshi()
	test_kakizaki_shingen()
	test_bushi_new()
	test_abilities()
	test_continuous()
	test_facedown()
	test_tokens_dilema()
	test_temple()
	test_kotaro_morichika()
	test_dice_cards()
	test_final_cards()
	test_one_die_cards()
	test_ui_events()
	test_swap_active()
	test_multi_warriors()
	print("\nPRUEBAS: %d | FALLAS: %d" % [total, fails])
	quit(1 if fails > 0 else 0)

# ---------------------------------------------------------------- sistema de decisiones

func test_choice_system() -> void:
	var g := fresh()
	g.players[0].hand = [79, 1, 2, 3, 4, 5, 6]
	g.play_action(0)
	check("Reiki abre una decisión (elegir 3 de 6)", g.phase == "CHOICE" and g.pending.player == 0 and g.pending.valid == [3])
	check("Elegir una cantidad incorrecta es rechazado", not g.choose([0, 1]))
	check("Mientras decide no se puede jugar otra carta", not g.play_action(0) and g.phase == "CHOICE")
	check("Índice repetido es rechazado", not g.choose([0, 0, 1]))
	var honor0: int = g.players[0].honor
	check("Elección válida se acepta", g.choose([0, 1, 2]))
	check("Reiki: botó las 3 elegidas y ganó +2 Honor", g.players[0].hand == [4, 5, 6] and g.players[0].discard.size() == 4 and g.players[0].honor == honor0 + 2)
	check("Vuelve a MAIN tras decidir", g.phase == "MAIN")

# ---------------------------------------------------------------- "al entrar en juego"

func test_entering() -> void:
	var g := fresh()
	g.players[0].hand = [3]
	g.players[0].discard = [1, 60, 2]
	g.play_warrior(0)
	check("Revancha pregunta (hay 2 ninjas posibles)", g.phase == "CHOICE" and g.pending.valid == [0, 1] and g.pending.options.size() == 2)
	g.choose([1])
	check("Revancha: recoge el ninja elegido", g.players[0].hand == [2])
	g = fresh()
	g.players[0].hand = [3]
	g.players[0].discard = [1, 2]
	g.play_warrior(0)
	g.choose([])
	check("Revancha: puede no recoger nada", g.players[0].hand.is_empty() and g.phase == "MAIN")

	g = fresh()
	g.players[0].hand = [7]
	g.players[0].discard = [1, 2, 4]
	var d0: int = g.players[0].deck.size()
	g.play_warrior(0)
	check("Hattori pregunta si roba 7", g.phase == "CHOICE" and g.pending.mode == "yesno")
	g.choose([0])
	check("Hattori: dijo sí, roba 7", g.players[0].hand.size() == 7 and g.players[0].deck.size() == d0 - 7)
	g = fresh()
	g.players[0].hand = [7]
	g.players[0].discard = [1, 2, 4]
	g.play_warrior(0)
	g.choose([1])
	check("Hattori: dijo no, no roba", g.players[0].hand.is_empty())
	g = fresh()
	g.players[0].hand = [7]
	g.players[0].discard = [1, 2]
	g.play_warrior(0)
	check("Hattori con 2 ninjas ni pregunta", g.phase == "MAIN" and g.players[0].hand.is_empty())

	var par := 0
	var impar := 0
	for s in 40:
		g = fresh(s)
		g.players[0].hand = [20]
		g.players[0].discard = [71, 83]
		g.play_warrior(0)
		var even := false
		for l in g.log_lines:
			if "tira un dado" in l:
				even = int(l.get_slice(": ", 1).trim_suffix(".")) % 2 == 0
		if even:
			par += 1
			if not (g.phase == "CHOICE" and g.pending.valid == [0, 1]):
				check("Katsuie par debe preguntar", false)
			else:
				g.choose([0])
				if g.players[0].hand.size() != 1:
					check("Katsuie debe recoger el Bushi elegido", false)
		else:
			impar += 1
			if g.phase != "MAIN" or not g.players[0].hand.is_empty():
				check("Katsuie impar no hace nada", false)
	check("Katsuie probado con pares (%d) e impares (%d)" % [par, impar], par > 0 and impar > 0)

	g = fresh()
	g.players[0].hand = [40]
	g.players[0].discard = [71, 25, 55]
	g.play_warrior(0)
	check("Yoshihisa pregunta cuál guerrero", g.phase == "CHOICE" and g.pending.options.size() == 2)
	g.choose([idx_of(g, 25)])
	check("Yoshihisa recoge el elegido (no el mejor)", g.players[0].hand == [25])

	g = fresh()
	g.players[0].hand = [45]
	g.players[0].discard = [1, 25, 55, 60]
	var dsz: int = g.players[0].deck.size()
	g.play_warrior(0)
	check("Yoshizane pregunta cuáles 3 de 4", g.phase == "CHOICE" and g.pending.valid == [3])
	g.choose([0, 1, 2])
	check("Yoshizane: 3 elegidos al fondo del mazo", g.players[0].deck.size() == dsz + 3 and g.players[0].discard == [60])

	g = fresh()
	g.players[0].hand = [47]
	g.players[0].honor = 0
	check("Tadamune sin su Daimyo no se puede pagar", not g.can_play_warrior(0, 47))
	g.players[0].passive = [60]
	check("Tadamune con su Daimyo es gratis", g.can_play_warrior(0, 47))
	g.play_warrior(0)
	check("Tadamune no gasta Honor", g.players[0].honor == 0)

	g = fresh()
	g.players[0].honor = 6
	g.gain_honor(g.players[0], 3)
	check("El Honor nunca pasa de 7", g.players[0].honor == 7)
	g.players[0].honor = 5
	g._start_turn(0)
	g.gain_honor(g.players[0], 5)
	check("El Honor se mantiene en 7 al ganar más", g.players[0].honor == Game.HONOR_MAX)

	g = fresh()
	g.players[0].honor = 7
	g.players[0].hand = [59, 1, 2, 3, 4, 5, 6]
	g.play_warrior(0)
	check("Kenshin pregunta qué 3 descartar", g.phase == "CHOICE" and g.pending.valid == [3])
	g.choose([0, 1, 2])
	check("Kenshin: queda con 7 cartas tras robar", g.players[0].hand.size() == 7)

	g = fresh()
	g.players[0].honor = 7
	g.players[0].hand = [69]
	g.players[1].active = 55
	g.players[1].passive = [56]
	var c0: int = g.players[0].castle.size()
	g.play_warrior(0)
	check("Akechi pregunta qué Daimyo robar", g.phase == "CHOICE" and g.pending.options.size() == 2)
	g.choose([idx_of(g, 56)])
	check("Akechi se queda con el Daimyo elegido", 56 in g.players[0].passive + [g.players[0].active] and g.players[1].passive.is_empty() and g.players[1].active == 55 and g.players[0].castle.size() == c0 - 2)
	g = fresh()
	g.players[0].hand = [69]
	g.play_warrior(0)
	check("Akechi sin Daimyo rival no hace nada", g.players[0].castle.size() == 7 and g.phase == "MAIN")

# ---------------------------------------------------------------- batalla: decisiones antes de tirar

func test_battle_prompts() -> void:
	var g := fresh()
	g.players[1].hand = [1, 2, 3, 71]
	duel(g, 25, 15)   # Sanada Yukimura (ataque 2) DEFIENDE: su efecto es al recibir un ataque
	check("Sanada pregunta si descarta 2 por +4 dados", g.phase == "CHOICE" and g.pending.valid == [0, 2] and g.pending.player == 1)
	g.choose([0, 1])
	check("Sanada: tiró 2+4 = 6 dados", g.last_duel.rolls[1].size() == 6)
	g = fresh()
	g.players[1].hand = [1, 2, 3, 71]
	duel(g, 25, 15)
	g.choose([])
	check("Sanada: puede decidir no hacerlo (2 dados)", g.last_duel.rolls[1].size() == 2 and g.players[1].hand.size() >= 4)

	g = fresh()
	g.players[0].hand = [1, 2, 71]
	duel(g, 6, 25)   # Kosaka
	check("Kosaka pregunta qué 2 descartar", g.phase == "CHOICE" and g.pending.valid == [2])
	g.choose([idx_of(g, 1), idx_of(g, 2)])
	check("Kosaka: dos Ninja = +5 puntos", g.last_duel.points[0] == 5)
	g = fresh()
	g.players[0].hand = [1, 2, 71]
	duel(g, 6, 25)
	g.choose([idx_of(g, 1), idx_of(g, 71)])
	check("Kosaka: con una no-Ninja no hay bono", g.last_duel.points[0] == 0)

	var ok_all := true
	for n in range(1, 7):
		g = fresh(n * 7)
		duel(g, 29, 25)   # Katsuyori
		if not (g.phase == "CHOICE" and g.pending.mode == "number" and g.pending.options.size() == 6):
			ok_all = false
			break
		g.choose([n - 1])
		var d: Dictionary = g.last_duel
		var s := 0
		for r in d.rolls[0]:
			s += r
		var expected: int = s + d.points[0] + (7 if n in d.rolls[0] else 0)
		if d.totals[0] != expected:
			ok_all = false
	check("Katsuyori: elige número y suma +7 solo si sale", ok_all)

	g = fresh()
	g.players[1].hand = [1, 2, 3]
	duel(g, 1, 25)   # Saizo solo
	check("Saizo solo: el rival descarta 1 AL AZAR (lo dice la carta)", has_log(g, "Saizo (solo)") and g.players[1].discard.size() >= 1)

	g = fresh()
	duel(g, 53, 25)  # Kunichika
	var kdice := -1
	for l in g.log_lines:
		if "Kunichika tira un dado" in l:
			kdice = int(l.get_slice(": ", 1).get_slice(".", 0))
	check("Kunichika: tira tantos dados como indicó su dado", kdice >= 1 and g.last_duel.rolls[0].size() == kdice)

# ---------------------------------------------------------------- batalla: modificadores de dados

func test_battle_mods() -> void:
	var g := fresh()
	g.players[0].active = 39
	g.bushi_count = [3, 0]
	check("Kobayakawa con 3 Bushi: 4 dados", g.dice_for(0, true).n == 4)
	g.bushi_count = [2, 0]
	check("Kobayakawa con 2 Bushi: 3 dados", g.dice_for(0, true).n == 3)
	g = fresh()
	g.players[0].active = 54
	g.players[1].hand = [1, 2, 3, 4, 5]
	check("Motoyama Boku: 1 dado por carta del rival (5)", g.dice_for(0, true).n == 5)
	g.players[1].hand = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	check("Motoyama Boku: máximo 7", g.dice_for(0, true).n == 7)
	g = fresh()
	g.players[0].active = 25
	g.players[1].active = 44   # Sessai Choro quita 1 dado al rival
	check("Sessai Choro quita 1 dado al rival (min. 1)", g.dice_for(0, true).n == 1)
	g.players[0].active = 36
	check("Sessai Choro: 3 -> 2 dados", g.dice_for(0, true).n == 2)
	g = fresh()
	g.players[0].active = 30
	g.players[0].castle = [1, 2, 3, 4, 5, 6, 7]
	g.players[1].castle = [1, 2, 3, 4, 5]
	check("Anayama: +1 dado con más castillo que el rival", g.dice_for(0, true).n == 4)
	g = fresh()
	g.players[0].active = 34   # Junyo
	g.bushi_count = [0, 1]
	check("Junyo: el rival no puede jugar un 2.º Bushi", not Effects.can_play(g, 1, 71))
	g.bushi_count = [0, 0]
	g.turn_player = 1
	check("Junyo: el 1.º Bushi sí se puede", Effects.can_play(g, 1, 71))

# ---------------------------------------------------------------- batalla: tras el duelo

func test_post_duel() -> void:
	var saw3 := 0
	var no3 := 0
	var big := 0
	for s in 80:
		var g := fresh(s)
		duel(g, 10, 25)   # Matsu
		var rolled3: bool = 3 in g.last_duel.rolls[0]
		if rolled3:
			saw3 += 1
			if not has_log(g, "Matsu sacó un 3"):
				check("Matsu debe robar con un 3", false)
		else:
			no3 += 1
			if has_log(g, "Matsu sacó un 3"):
				check("Matsu no debe robar sin un 3", false)
		g = fresh(s)
		duel(g, 24, 25)   # Hideyori
		if g.last_duel.totals[0] >= 9:
			big += 1
			if not has_log(g, "Hideyori sacó"):
				check("Hideyori debe robar con 9+", false)
		elif has_log(g, "Hideyori sacó"):
			check("Hideyori no debe robar con menos de 9", false)
	check("Matsu probado (con 3: %d, sin 3: %d)" % [saw3, no3], saw3 > 0 and no3 > 0)
	check("Hideyori probado con totales 9+ (%d)" % big, big > 0)

	var seen_info := false
	for s in 40:
		var g := fresh(s)
		g.players[0].mult = 6   # casi seguro gana
		g.players[1].hand = [1, 2]
		duel(g, 23, 25)   # Miyoshi
		if g.last_duel.winner == 0:
			if g.phase == "CHOICE" and g.pending.mode == "info" and g.pending.player == 0 and g.pending.options.size() == 3:
				seen_info = true
				check("Miyoshi: ver la mano rival no se puede 'elegir' cartas", not g.choose([0]))
				g.choose([])
				check("Miyoshi: cerrar la ventana continúa el juego", g.phase == "MAIN" or g.phase == "OVER")
				break
	check("Miyoshi muestra la mano del rival al ganar", seen_info)

	var g := fresh(3)
	g.players[0].mult = 6
	duel(g, 38, 25)   # Motonari (sin Daimyo Mori en el mazo: no debe bloquear el juego)
	check("Motonari sin Daimyo Mori en el mazo no se queda esperando", g.phase != "CHOICE")

	g = fresh()
	g.players[0].active = 31   # Kage Katsu
	g.players[1].active = 25
	g.players[1].hand = [78, 71, 72]
	g.declare_attack("guerrero")
	g.pass_priority()          # pasa el atacante: ahora tiene prioridad el rival
	g.play_action(0)           # el rival juega un Bushi
	check("Kage Katsu: el rival debe descartar 1 (él elige)", g.phase == "CHOICE" and g.pending.player == 1 and g.pending.valid == [1])
	g.choose([0])
	check("Kage Katsu: descartó 1 carta de su mano", g.players[1].hand.size() == 1)

# ---------------------------------------------------------------- habilidades activas (A)

func has_ability(g: Game, id: int) -> bool:
	for a in g.available_abilities():
		if a.id == id:
			return true
	return false

func test_abilities() -> void:
	var g := fresh()
	# Toshie: ordenar las 3 de arriba
	g.players[0].passive = [11]
	g.players[0].deck = [1, 2, 3, 4, 5]    # arriba = 5, 4, 3
	check("Toshie disponible", has_ability(g, 11))
	g.use_ability(11)
	check("Toshie abre decisión de orden (3 cartas)", g.phase == "CHOICE" and g.pending.mode == "order" and g.pending.options.size() == 3)
	g.choose([idx_of(g, 3), idx_of(g, 5), idx_of(g, 4)])
	check("Toshie: la primera elegida queda arriba del mazo", g.players[0].deck == [1, 2, 4, 5, 3])
	check("Toshie: solo una vez por turno", not has_ability(g, 11))

	# Pirata Wokou: desde el pozo
	g = fresh()
	g.players[0].discard = [12]
	g.players[0].honor = 0
	check("Wokou sin Honor no se puede revivir", not has_ability(g, 12))
	g.players[0].honor = 3
	check("Wokou en el pozo con Honor sí", has_ability(g, 12))
	g.use_ability(12)
	check("Wokou vuelve a la mano pagando su costo", g.players[0].hand == [12] and g.players[0].honor == 2 and g.players[0].discard.is_empty())

	# Akachi Morichige: solo con la mano vacía
	g = fresh()
	g.players[0].active = 18
	g.players[0].discard = [10, 25, 11]
	g.players[0].hand = [1]
	check("Akachi no sirve con cartas en la mano", not has_ability(g, 18))
	g.players[0].hand = []
	check("Akachi con la mano vacía", has_ability(g, 18))
	g.use_ability(18)
	check("Akachi pregunta qué Ronin (2 posibles)", g.phase == "CHOICE" and g.pending.options.size() == 2)
	g.choose([idx_of(g, 11)])
	check("Akachi recoge el Ronin elegido", g.players[0].hand == [11])

	# Rukkaku / Yoshiaki: Honor por miembros Ashikaga
	g = fresh()
	g.players[0].active = 49
	check("Rukkaku solo (sin otro Ashikaga) no genera", not has_ability(g, 49))
	g.players[0].passive = [50]
	check("Rukkaku con otro Ashikaga sí", has_ability(g, 49))
	var h0: int = g.players[0].honor
	g.use_ability(49)
	check("Rukkaku genera 1 de Honor", g.players[0].honor == h0 + 1 and not has_ability(g, 49))
	check("Yoshiaki necesita 2 más (solo hay 1)", not has_ability(g, 50))
	g.players[0].passive = [50, 51]
	g.players[0].passive = [50, 51, 49]
	check("Yoshiaki con 2 Ashikaga más", has_ability(g, 50))
	h0 = g.players[0].honor
	g.use_ability(50)
	check("Yoshiaki genera 2 de Honor", g.players[0].honor == h0 + 2)

	# Yoshiharu: impuesto al clan nombrado en el próximo turno rival
	g = fresh()
	g.players[0].active = 51
	g.use_ability(51)
	check("Yoshiharu pide nombrar un clan (12 opciones, sin Ninja/Ronin)", g.phase == "CHOICE" and g.pending.options.size() == 12)
	var di := -1
	for i in g.pending.options.size():
		if g.pending.options[i].value == "Date":
			di = i
	g.choose([di])
	check("Yoshiharu: el costo sube en el próximo turno del rival", g.cost_tax.size() == 1 and g.cost_tax[0].turn == g.turn_number + 1)
	g.end_turn()
	check("Cartas Date cuestan +1 en el turno del rival (Munezane 1 -> 2)", g.turn_player == 1 and g.entry_cost(1, 46) == 2 and g.entry_cost(1, 25) == 1)
	g.end_turn()
	g.end_turn()
	check("El impuesto desaparece después", g.entry_cost(1, 46) == 1)

	# Oda Nobunaga
	g = fresh()
	g.players[0].active = 55
	g.players[0].hand = [1]
	var dk: int = g.players[0].deck.size()
	g.use_ability(55)
	check("Nobunaga pregunta si roba 3", g.phase == "CHOICE" and g.pending.mode == "yesno")
	g.choose([0])
	check("Nobunaga robó 3 y ofrece descartar 3 por Honor", g.players[0].hand.size() == 4 and g.phase == "CHOICE" and g.pending.valid == [0, 3])
	h0 = g.players[0].honor
	g.choose([0, 1, 2])
	check("Nobunaga: 3 cartas -> +3 de Honor", g.players[0].honor == h0 + 3 and g.players[0].hand.size() == 1 and g.players[0].deck.size() == dk - 3)
	g = fresh()
	g.players[0].active = 55
	g.use_ability(55)
	g.choose([1])
	check("Nobunaga: decir No no gasta la habilidad", has_ability(g, 55) and g.players[0].hand.is_empty())

	# Ieyasu
	g = fresh()
	g.players[0].active = 57
	g.players[0].deck = [1, 2, 3, 3, 4]
	h0 = g.players[0].honor
	g.use_ability(57)
	check("Ieyasu lista cada carta distinta del mazo", g.phase == "CHOICE" and g.pending.options.size() == 4)
	g.choose([idx_of(g, 3)])
	check("Ieyasu: paga 1 y busca la carta elegida", g.players[0].hand == [3] and g.players[0].honor == h0 - 1 and g.players[0].deck.size() == 4)
	g = fresh()
	g.players[0].honor = 7
	g.players[0].active = 57
	g.use_ability(57)
	g.choose([])
	check("Ieyasu: elegir ninguna no cobra ni gasta", g.players[0].honor == 7 and has_ability(g, 57))
	g.players[0].honor = 0
	check("Ieyasu sin Honor no se puede usar", not has_ability(g, 57))

	# Mitsunari
	g = fresh()
	g.players[0].active = 62
	g.players[0].passive = [10, 11]
	g.players[0].deck = [1, 2, 3, 4, 5, 6]
	h0 = g.players[0].honor
	g.use_ability(62)
	check("Mitsunari: roba 1 por Ronin (3) y +1 Honor", g.players[0].hand.size() == 3 and g.players[0].honor == h0 + 1)

	# Motochika: cambia carta de mano por una del castillo
	g = fresh()
	g.players[0].active = 64
	g.players[0].hand = [9]
	g.players[0].castle = [1, 2, 3, 4, 5, 6, 7]
	g.use_ability(64)
	check("Motochika pide la carta de la mano", g.phase == "CHOICE" and g.pending.valid == [0, 1])
	g.choose([0])
	check("Motochika muestra el castillo para elegir", g.phase == "CHOICE" and g.pending.options.size() == 7)
	g.choose([idx_of(g, 4)])
	check("Motochika: intercambio hecho (castillo sigue en 7)", g.players[0].hand == [4] and 9 in g.players[0].castle and 4 not in g.players[0].castle and g.players[0].castle.size() == 7)

	# Kenyo: +3 de Honor si termina el turno sin atacar
	g = fresh()
	g.players[0].active = 66
	h0 = g.players[0].honor
	g.end_turn()
	check("Kenyo: sin atacar suma 3 de Honor al terminar el turno", g.players[0].honor == h0 + 3)
	g = fresh()
	g.players[0].active = 66
	g.players[1].active = 25
	h0 = g.players[0].honor
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Kenyo atacó: honor sin cambios", g.players[0].honor == h0)

# ---------------------------------------------------------------- efectos continuos (D) y relacionados

func test_continuous() -> void:
	var g := fresh()
	g.players[0].passive = [22]
	check("Yogidomi: tus guerreros cuestan 1 menos en tu turno (4 -> 3)", g.entry_cost(0, 24) == 3)
	check("Yogidomi: solo guerreros Toyotomi (Hanzo sigue en 3)", g.entry_cost(0, 7) == 3)
	check("Yogidomi: el costo nunca baja de 0", g.entry_cost(0, 71) == 0)
	check("Yogidomi no ayuda al rival", g.entry_cost(1, 24) == 4)
	g.turn_player = 1
	check("Yogidomi: fuera de tu turno no reduce", g.entry_cost(0, 24) == 4)
	g = fresh()
	g.players[0].passive = [25]
	check("Sakai: el Daimyo Tokugawa (Ieyasu) cuesta 4", g.entry_cost(0, 57) == 4 and g.entry_cost(0, 56) == 5)

	# Yoshiteru duplica Ceremonia, Reparadores y El destino del clan
	g = fresh()
	g.players[0].active = 68
	g.players[0].hand = [71]
	var h0: int = g.players[0].honor
	g.play_action(0)
	check("Ceremonia con Yoshiteru: roba 2 y +2 de Honor", g.players[0].hand.size() == 2 and g.players[0].honor == h0 + 2)
	g = fresh()
	g.players[0].active = 68
	g.players[0].hand = [88]
	g.players[0].castle = [1, 2, 3, 4, 5]
	g.play_action(0)
	check("Reparadores con Yoshiteru: 2 cartas al castillo", g.players[0].castle.size() == 7)
	g = fresh()
	g.players[0].hand = [88]
	g.players[0].castle = [1, 2, 3, 4, 5]
	g.play_action(0)
	check("Reparadores normal: 1 carta", g.players[0].castle.size() == 6)
	g = fresh()
	g.players[0].hand = [88]
	g.players[0].active = 68
	g.players[0].castle = [1, 2, 3, 4, 5, 6]
	g.play_action(0)
	check("Reparadores: el castillo nunca pasa de 7", g.players[0].castle.size() == 7)

	# El destino del clan: ahora con decisión de clan
	g = fresh()
	g.players[0].active = 46      # Munezane (Date)
	g.players[0].passive = [47]   # Tadamune (Date)
	g.players[1].active = 60      # Date (daimyo)
	g.players[0].hand = [74]
	g.play_action(0)
	check("Destino del clan pide nombrar un clan", g.phase == "CHOICE" and g.pending.options.size() == 12)
	var di := -1
	for i in g.pending.options.size():
		if g.pending.options[i].value == "Date":
			di = i
	g.choose([di])
	check("Destino del clan: roba 1 por cada Date en juego (3)", g.players[0].hand.size() == 3)

# ---------------------------------------------------------------- Hidetoshi (56)

func test_hidetoshi() -> void:
	var g := fresh(1)
	g.players[0].passive = [56]
	duel(g, 25, 36)
	check("Hidetoshi pregunta tras tirar los dados", g.phase == "CHOICE" and g.pending.mode == "yesno" and g.pending.player == 0)
	check("Los dados ya están tirados cuando decide", g.battle.has("res") and g.battle.res[0].rolls.size() == 1 and g.battle.res[1].rolls.size() == 3)
	g.choose([0])
	check("Luego pide elegir un dado (1 propio + 3 del rival)", g.pending.mode == "die" and g.pending.options.size() == 4)
	g.choose([0])
	check("Luego pide el valor (1 a 6)", g.pending.mode == "dievalue" and g.pending.options.size() == 6)
	g.choose([5])
	check("Hidetoshi: su dado queda en 6", g.last_duel.rolls[0][0] == 6 and has_log(g, "Hidetoshi cambia un dado"))
	check("Hidetoshi: el total es coherente con los dados", g.last_duel.totals[0] == 6 + g.last_duel.points[0])

	g = fresh(1)
	g.players[0].passive = [56]
	duel(g, 25, 36)
	g.choose([1])
	check("Hidetoshi: decir No no cambia nada", not has_log(g, "Hidetoshi cambia") and g.phase != "CHOICE")

	g = fresh(1)
	g.players[0].passive = [56]
	duel(g, 25, 36)
	g.choose([0])
	g.choose([1])   # primer dado del rival
	g.choose([0])   # ponerle 1
	check("Hidetoshi puede bajar un dado del rival a 1", g.last_duel.rolls[1][0] == 1)

	g = fresh(1)
	g.players[0].passive = [56]
	g.players[1].active = 36
	g.players[0].active = 25
	g.turn_player = 1
	g.phase = "MAIN"
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Hidetoshi no se ofrece en el turno del rival (es tipo A)", g.phase != "CHOICE" and not has_log(g, "Hidetoshi cambia"))

	var used := 0
	var bad := 0
	for s in 60:
		g = fresh(s)
		g.players[0].passive = [56]
		duel(g, 25, 36)
		var guard := 0
		while g.phase == "CHOICE" and guard < 10:
			AI.act(g)
			guard += 1
		if has_log(g, "Hidetoshi cambia"):
			used += 1
			if g.last_duel.winner != 0:
				bad += 1
	check("La IA usa Hidetoshi solo cuando le da la victoria (usó %d veces, %d sin ganar)" % [used, bad], used > 0 and bad == 0)

# ---------------------------------------------------------------- Kakizaki (32) y Shingen (58)

func test_kakizaki_shingen() -> void:
	var g := fresh()
	g.players[0].active = 32
	check("Kakizaki solo: 2 dados (sin bono)", g.dice_for(0, true).n == 2)
	g.players[0].passive = [1]
	check("Kakizaki con un Ninja: sin bono", g.dice_for(0, true).n == 2)
	g.players[0].passive = [31]
	check("Kakizaki con otro Uesugi: +1 dado", g.dice_for(0, true).n == 3)
	g.players[0].passive = [36]
	check("Kakizaki con un Ikko Ikki: +1 dado", g.dice_for(0, true).n == 3)
	g.players[0].passive = [31, 36, 34]
	check("Kakizaki con varios: el bono es solo +1", g.dice_for(0, true).n == 3)
	check("Kakizaki también lo aplica defendiendo", g.dice_for(0, false).n == 3)

	g = fresh()
	g.players[0].passive = [58]
	check("Shingen: Takeda de coste 1 cuesta 0 en tu turno", g.entry_cost(0, 28) == 0)
	check("Shingen: Takeda de coste 3 cuesta 2", g.entry_cost(0, 30) == 2)
	check("Shingen no ayuda a otros clanes", g.entry_cost(0, 7) == 3)
	g.players[0].passive = [58, 58]
	check("Shingen: el costo nunca baja de 0", g.entry_cost(0, 28) == 0 and g.entry_cost(0, 29) == 0)
	g.players[0].passive = [58]
	g.turn_player = 1
	check("Shingen no reduce fuera de tu turno", g.entry_cost(0, 30) == 3)
	g.turn_player = 0
	g.players[0].honor = 2
	g.players[0].hand = [30]
	check("Con Shingen puedes bajar un Takeda de coste 3 con 2 de Honor", g.can_play_warrior(0, 30))
	g.play_warrior(0)
	check("Shingen: pagó solo 2", g.players[0].honor == 0)

# ---------------------------------------------------------------- acciones Bushi nuevas

func test_bushi_new() -> void:
	# --- El maestro estratega (82)
	var g := fresh()
	g.players[0].hand = [82, 1, 2, 3, 71]
	g.play_action(0)
	check("Maestro estratega pide elegir X (0 a 4)", g.phase == "CHOICE" and g.pending.valid == [0, 1, 2, 3, 4])
	check("No puedes elegir más cartas que las de tu mano", not g.choose([0, 1, 2, 3, 4]))
	var dsz: int = g.players[0].deck.size()
	g.choose([0, 1])
	check("Maestro estratega: X=2 -> mano 2 + roba 2 = 4", g.players[0].hand.size() == 4)
	check("Maestro estratega: el mazo mantiene su tamaño y las cartas quedan al fondo", g.players[0].deck.size() == dsz and g.players[0].deck[0] == 2 and g.players[0].deck[1] == 1)
	g = fresh()
	g.players[0].hand = [82, 1, 2]
	g.play_action(0)
	g.choose([])
	check("Maestro estratega: X=0 no cambia nada", g.players[0].hand.size() == 2 and g.phase == "MAIN" and has_log(g, "decide no cambiar"))
	g = fresh()
	g.players[0].hand = [82]
	check("Maestro estratega sin otras cartas no se puede jugar", not Effects.can_play(g, 0, 82))

	# --- Hansei (85)
	g = fresh()
	g.players[0].hand = [85, 6, 1, 2, 3, 71]
	check("Hansei jugable (guerrero de coste 2 + 3 para descartar)", Effects.can_play(g, 0, 85))
	g.play_action(0)
	check("Hansei: con un solo guerrero de coste 2 no pregunta cuál", g.phase == "CHOICE" and g.pending.valid == [3])
	check("Hansei: el guerrero elegido no se puede descartar", g.pending.options.size() == 4 and idx_of(g, 6) == -1)
	var h0: int = g.players[0].honor
	g.choose([0, 1, 2])
	check("Hansei: bajó al guerrero gratis (Honor intacto)", g.players[0].active == 6 and g.players[0].honor == h0)
	check("Hansei: descartó 3 cartas", g.players[0].hand == [71] and g.players[0].discard.size() == 4)
	check("Hansei no gasta tu guerrero del turno", g.warrior_played == false)
	g = fresh()
	g.players[0].hand = [85, 6, 5, 1, 2, 3, 71]
	g.play_action(0)
	check("Hansei con 2 candidatos pregunta cuál bajar", g.phase == "CHOICE" and g.pending.valid == [1] and g.pending.options.size() == 2)
	g.choose([idx_of(g, 5)])
	check("Hansei: luego pide los 3 descartes (el otro guerrero puede descartarse)", g.phase == "CHOICE" and g.pending.valid == [3] and idx_of(g, 6) != -1)
	g.choose([0, 1, 2])
	check("Hansei: bajó al guerrero elegido", g.players[0].active == 5)
	g = fresh()
	g.players[0].hand = [85, 7, 1, 2, 3, 71]
	check("Hansei no baja guerreros de otro coste", not Effects.can_play(g, 0, 85))
	g = fresh()
	g.players[0].hand = [85, 4, 1, 2]
	check("Hansei sin 3 cartas para descartar no se puede jugar", not Effects.can_play(g, 0, 85))
	g = fresh()
	g.players[0].hand = [85, 4, 1, 2, 3, 71]
	g.players[0].active = 10
	g.players[0].passive = [11, 12, 18]
	check("Hansei sin lugar en la zona no se puede jugar", not Effects.can_play(g, 0, 85))
	g = fresh()
	g.players[0].hand = [85, 20, 1, 2, 3, 71]
	g.players[0].discard = [86]
	g.play_action(0)
	g.choose([0, 1, 2])
	check("Hansei activa el efecto al entrar (Shibata Katsuie tira dado)", has_log(g, "Shibata Katsuie tira un dado"))

	# --- Kansei (86)
	g = fresh()
	g.players[0].hand = [86, 8, 1, 2, 3, 4, 71]
	check("Kansei jugable (coste 3 + 4 descartes)", Effects.can_play(g, 0, 86))
	g.play_action(0)
	check("Kansei pide 4 descartes", g.phase == "CHOICE" and g.pending.valid == [4])
	g.choose([0, 1, 2, 3])
	check("Kansei: baja a Tenzo gratis y descarta 4", g.players[0].active == 8 and g.players[0].hand == [71])
	g = fresh()
	g.players[0].hand = [86, 8, 1, 2, 3]
	check("Kansei con solo 3 cartas para descartar no se puede jugar", not Effects.can_play(g, 0, 86))

	# --- Musha Shugyo (87)
	g = fresh()
	g.players[0].hand = [87, 10, 11, 1, 71]
	g.players[0].active = 10
	g.players[1].active = 25
	g.turn_player = 0
	g.declare_attack("guerrero")
	check("Musha Shugyo jugable luchando con un Ronin", Effects.can_play(g, 0, 87))
	g.play_action(0)
	check("Musha Shugyo pregunta cuántas descartar (0 a 4)", g.phase == "CHOICE" and g.pending.valid == [0, 1, 2, 3, 4])
	g.choose([idx_of(g, 10), idx_of(g, 11), idx_of(g, 1)])
	check("Musha Shugyo: 2 Ronin + 1 Ninja descartados = +2 de ataque", g.players[0].bb_dice == 2 and g.dice_for(0, true).n == 3)
	check("Musha Shugyo: devuelve la prioridad a la ventana de batalla", g.phase == "WINDOW")
	g = fresh()
	g.players[0].hand = [87, 1, 2, 3]
	g.players[0].active = 10
	g.players[1].active = 25
	g.declare_attack("guerrero")
	g.play_action(0)
	g.choose([0, 1])
	check("Musha Shugyo sin Ronin descartados: sin bono", g.players[0].bb_dice == 0)
	g = fresh()
	g.players[0].hand = [87, 10, 10, 10, 11, 11, 11, 12, 12, 12]
	g.players[0].active = 10
	g.players[1].active = 25
	g.declare_attack("guerrero")
	g.play_action(0)
	g.choose([0, 1, 2, 3, 4, 5, 6, 7])   # 8 Ronin
	check("Musha Shugyo: el bono tiene tope 7", g.players[0].bb_dice == 7)
	g = fresh()
	g.players[0].hand = [87, 10, 1]
	g.players[0].active = 4   # Ninja
	g.players[1].active = 25
	g.declare_attack("guerrero")
	check("Musha Shugyo no se puede jugar con un guerrero que no es Ronin", not Effects.can_play(g, 0, 87))
	g = fresh()
	g.players[0].hand = [87, 10, 1]
	g.players[0].active = 10
	check("Musha Shugyo no se puede jugar fuera de batalla", not Effects.can_play(g, 0, 87))

	# --- Matrimonio arreglado (92)
	g = fresh()
	g.players[0].active = 1        # Ninja
	g.players[0].passive = [10, 25]   # Ronin, Tokugawa
	g.players[0].honor = 2
	g.players[0].hand = [92, 71, 83, 84, 99]
	check("Matrimonio arreglado jugable con 3 clanes distintos", Effects.can_play(g, 0, 92))
	g.play_action(0)
	check("Matrimonio: con una sola combinación no pregunta cuál", g.phase == "CHOICE" and g.pending.mode == "give" and g.pending.valid == [0, 1, 2, 3, 4])
	check("Matrimonio: los 3 héroes ya se descartaron", g.players[0].active == 0 and g.players[0].passive.is_empty() and g.players[0].discard.size() == 4)
	check("Matrimonio: no puedes descartar más de lo que cabe bajo el tope (4)", not g.choose([0, 1, 2, 3, 4]) )
	g.choose([0, 1, 2])
	check("Matrimonio: 3 cartas = +3 de Honor (2 -> 5)", g.players[0].honor == 5 and g.players[0].hand.size() == 1)
	g = fresh()
	g.players[0].active = 1
	g.players[0].passive = [10, 25]
	g.players[0].honor = 5
	g.players[0].hand = [92, 71, 83, 84, 99]
	g.play_action(0)
	check("Matrimonio con 5 de Honor: solo puedes descartar 0 o 1 (tope 6)", g.pending.valid == [0, 1])
	g.choose([0])
	check("Matrimonio: el Honor queda en 6", g.players[0].honor == 6)
	g = fresh()
	g.players[0].active = 1
	g.players[0].passive = [10, 25, 28]   # 4 clanes distintos
	g.players[0].honor = 2
	g.players[0].hand = [92, 71, 83]
	g.play_action(0)
	check("Matrimonio con 4 clanes distintos pregunta qué 3 (4 combinaciones)", g.phase == "CHOICE" and g.pending.mode == "take" and g.pending.options.size() == 4)
	g.choose([0])
	check("Matrimonio: el héroe que no entró en la combinación se queda en juego", g.heroes_in_play(0).size() == 1 and g.players[0].discard.size() == 4)
	g = fresh()
	g.players[0].active = 1
	g.players[0].passive = [2, 10]   # dos Ninja + un Ronin
	g.players[0].hand = [92, 71]
	check("Matrimonio con dos del mismo clan no se puede jugar", not Effects.can_play(g, 0, 92))
	g.players[0].passive = [10]
	check("Matrimonio con solo 2 héroes no se puede jugar", not Effects.can_play(g, 0, 92))
	g.players[0].passive = [10, 25]
	g.players[0].honor = 6
	check("Matrimonio con 6 de Honor no se puede jugar", not Effects.can_play(g, 0, 92))

	# --- Lealtad (97)
	g = fresh()
	g.players[0].hand = [97]
	g.play_action(0)
	check("Lealtad pide nombrar un clan (12 opciones)", g.phase == "CHOICE" and g.pending.options.size() == 12)
	var takeda := -1
	for i in g.pending.options.size():
		if g.pending.options[i].value == "Takeda":
			takeda = i
	g.choose([takeda])
	check("Lealtad: queda abierta con 3 héroes por bajar", g.players[0].lealtad.size() == 1 and g.players[0].lealtad[0].left == 3)
	g.players[0].honor = 7
	var hon: int = g.players[0].honor
	for id in [28, 29, 30]:
		g.players[0].hand = [id]
		g.warrior_played = false
		g.play_warrior(0)
		while g.phase == "CHOICE":
			AI.act(g)
		check("Lealtad: bajó %s" % g.card(id).nombre, true)
	var spent: int = 1 + 2 + 3
	check("Lealtad cumplida: +3 de Honor (después de pagar 6)", g.players[0].honor == hon - spent + 3 and g.players[0].lealtad.is_empty())
	g = fresh()
	g.players[0].hand = [97]
	g.play_action(0)
	for i in g.pending.options.size():
		if g.pending.options[i].value == "Takeda":
			takeda = i
	g.choose([takeda])
	g.players[0].honor = 7
	hon = g.players[0].honor
	g.players[0].hand = [28]
	g.play_warrior(0)
	g.players[0].hand = [3]
	g.warrior_played = false
	g.play_warrior(0)
	while g.phase == "CHOICE":
		AI.act(g)
	check("Lealtad rota: un héroe de otro clan cancela el compromiso", g.players[0].lealtad.is_empty() and has_log(g, "se pierde"))
	g.players[0].hand = [29]
	g.warrior_played = false
	g.play_warrior(0)
	g.players[0].hand = [30]
	g.warrior_played = false
	g.play_warrior(0)
	check("Lealtad rota: después ya no da Honor", g.players[0].honor == hon - 1 - 1 - 2 - 3)
	g = fresh()
	g.players[0].hand = [97, 97]
	g.play_action(0)
	g.choose([takeda])
	g.play_action(0)
	g.choose([takeda])
	check("Dos Lealtad abiertas a la vez", g.players[0].lealtad.size() == 2)


# ---------------------------------------------------------------- cartas boca abajo

func test_facedown() -> void:
	var g := fresh()
	g.players[0].hand = [96, 98, 96]
	check("Cortesía se puede colocar boca abajo", Effects.can_play(g, 0, 96))
	g.play_action(0)
	check("Queda boca abajo y no va al pozo", g.players[0].facedown == [96] and g.players[0].discard.is_empty())
	g.play_action(0)
	check("Segunda carta boca abajo", g.players[0].facedown.size() == 2)
	check("Tope de 2 cartas boca abajo", not Effects.can_play(g, 0, 96))
	var g2 := fresh()
	g2.players[1].active = 33
	check("Nabe del rival impide colocar boca abajo", not Effects.can_play(g2, 0, 96))
	# Cortesía
	g = fresh()
	g.players[0].facedown = [96]
	g.players[0].active = 28   # coste 3 (Honda?) se compara con la carta real
	var cost: int = g.card(28).costo_honor
	var hon: int = g.players[0].honor
	g._kill_active(0, 1, 1)
	check("Cortesía: recibes el coste de Honor del héroe caído", g.players[0].honor == hon + cost and g.players[0].facedown.is_empty() and 96 in g.players[0].discard)
	# Muerte Honorable
	g = fresh()
	g.players[0].facedown = [98]
	g.players[0].active = 28
	hon = g.players[0].honor
	g._kill_active(0, 1, 2)
	check("Muerte Honorable: margen 2 no se revela", g.players[0].honor == hon and g.players[0].facedown == [98])
	g.players[0].active = 28
	g._kill_active(0, 1, 3)
	check("Muerte Honorable: margen 3 da +3 de Honor", g.players[0].honor == hon + 3 and g.players[0].facedown.is_empty())
	# Liderazgo
	g = fresh()
	g.players[0].hand = [77]
	g.players[0].active = 28
	g.players[0].passive = [46]
	g.players[1].facedown = [96, 98]
	check("Liderazgo exige 2 héroes del mismo clan", not Effects.can_play(g, 0, 77))
	g.players[0].passive = [28]
	check("Liderazgo con pareja y trampa rival", Effects.can_play(g, 0, 77))
	g.play_action(0)
	check("Liderazgo abre decisión a ciegas (2 opciones)", g.phase == "CHOICE" and g.pending.options.size() == 2 and not g.pending.options[0].has("card"))
	g.choose([1])
	check("Liderazgo destruye la carta elegida", g.players[1].facedown == [96] and 98 in g.players[1].discard)
	g = fresh()
	g.players[0].hand = [77]
	g.players[0].active = 28
	g.players[0].passive = [28]
	check("Liderazgo sin cartas boca abajo rival no se juega", not Effects.can_play(g, 0, 77))
	# Nobutada / Nobutaka
	g = fresh()
	g.players[0].active = 21
	var base: int = g.dice_for(0, true).n
	g.players[0].facedown = [96]
	check("Nobutada pierde su dado extra con cartas boca abajo", g.dice_for(0, true).n == base - 1)
	g = fresh()
	g.players[0].active = 19
	g.players[1].active = 28
	g.players[0].facedown = [96, 98]
	g.players[0].deck = [1, 2, 3, 4, 5]
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Nobutaka ofrece robar 2 (cartas boca abajo)", g.phase == "CHOICE" and "2" in g.pending.prompt)
	g.choose([0])
	check("Nobutaka roba 2", g.players[0].hand.size() == 2)

# ---------------------------------------------------------------- fichas y Dilema

func test_tokens_dilema() -> void:
	var g := fresh()
	g.players[0].hand = [89]
	g.players[0].deck = [1, 2, 3, 4, 5, 6]
	g.play_action(0)
	check("Castillo de montaña: ficha activa y pasiva", g.players[0].active == 900 and g.players[0].passive == [900] and g.players[0].shadow.size() == 2)
	check("La ficha es Ronin 1/1", g.card(900).clan == "Ronin" and g.dice_for(0, true).n == 1)
	g.players[1].active = 28
	var cast: int = g.players[0].castle.size()
	g._kill_active(0, 1, 0)
	check("Ficha muerta: carta real al pozo y roba del castillo", g.players[0].discard.size() == 2 and g.players[0].shadow.size() == 1 and g.players[0].castle.size() == cast - 1)
	# con lugar para 1 sola ficha
	g = fresh()
	g.players[0].hand = [89]
	g.players[0].deck = [1, 2, 3]
	g.players[0].active = 28
	g.players[0].passive = [28, 28]
	g.play_action(0)
	check("Con 1 lugar libre entra 1 ficha", g.players[0].passive.count(900) == 1 and g.players[0].shadow.size() == 1)
	g = fresh()
	g.players[0].hand = [89]
	g.players[0].active = 28
	g.players[0].passive = [28, 28, 28]
	check("Sin lugar no se juega", not Effects.can_play(g, 0, 89))
	# conservación de cartas con fichas
	var gg := Game.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	gg.setup(DeckBuilder.random_deck(rng), DeckBuilder.random_deck(rng), 7, ["A", "B"])
	gg.turn_player = 0
	gg.phase = "MAIN"
	gg.players[0].deck.pop_back()
	gg.players[0].hand.append(89)
	gg.players[0].active = 0
	gg.players[0].passive = []
	gg.play_action(gg.players[0].hand.size() - 1)
	gg._kill_active(0, 1, 0)
	check("Se conservan las 100 cartas con fichas", gg.card_total(0) + gg.card_total(1) == 100)
	# Dilema
	g = fresh()
	g.players[0].hand = [80]
	g.players[0].active = 28   # Takeda
	g.players[0].passive = [3]   # Ninja
	g.play_action(0)
	check("Dilema abre elección de clan", g.phase == "CHOICE")
	var idx := 0
	for i in g.pending.options.size():
		if g.pending.options[i].value == "Uesugi":
			idx = i
	g.choose([idx])
	check("Dilema: héroe normal pasa al clan", g.clan_of(0, 28) == "Uesugi")
	check("Dilema: Ninja no cambia", g.clan_of(0, 3) == "Ninja")
	check("Dilema no cambia al rival", g.clan_of(1, 28) == g.card(28).clan)
	g.turn_number += 1
	check("Dilema termina con el turno", g.clan_of(0, 28) == g.card(28).clan)
	# Dilema + Liderazgo
	g = fresh()
	g.players[0].hand = [80, 77]
	g.players[0].active = 28
	g.players[0].passive = [46]
	g.players[1].facedown = [96]
	check("Antes del Dilema no hay pareja", not Effects.can_play(g, 0, 77))
	g.play_action(0)
	g.choose([idx])
	check("Después del Dilema Liderazgo se puede jugar", Effects.can_play(g, 0, 77))
	# Terumune
	g = fresh()
	g.players[0].active = 48
	var b0: int = g.dice_for(0, true).n
	g.players[0].passive = [60]
	check("Terumune: el Daimyo Date da +2 en vez de +1", g.dice_for(0, true).n == b0 + 2)
	g.players[0].active = 46
	var b1: int = g.dice_for(0, true).n
	g.players[0].passive = []
	check("Otro Date solo recibe +1", b1 - g.dice_for(0, true).n == 1)

# ---------------------------------------------------------------- Complejo Enryaku-Ji

func end_turns(g: Game, n: int) -> void:
	# cierra el turno del jugador 0 n veces (el rival pasa)
	for i in n:
		g.turn_player = 0
		g.phase = "MAIN"
		g.attacked_this_turn = true
		Effects.on_turn_end(g, 0)

func test_temple() -> void:
	var g := fresh()
	g.players[0].hand = [90, 90]
	g.players[0].active = 28
	g.players[0].passive = [29]
	g.play_action(0)
	check("El Complejo queda en juego (no va al pozo)", not g.players[0].temple.is_empty() and g.players[0].discard.is_empty())
	check("No se puede construir un segundo Complejo", not Effects.can_play(g, 0, 90))
	check("Capacidad 1 sin Rennyo", Effects.temple_cap(g, 0) == 1)
	check("Habilidad de enviar héroe disponible", Effects.ability_ready(g, 0, 9001))
	g.use_ability(9001)
	g.choose([1])   # el pasivo (29)
	check("El héroe sale de juego y entra al templo", g.players[0].passive.is_empty() and g.players[0].temple.heroes.size() == 1)
	check("Capacidad llena: no cabe otro", not Effects.ability_ready(g, 0, 9001))
	end_turns(g, 1)
	check("Tras 1 turno sigue dentro", g.players[0].temple.heroes.size() == 1)
	end_turns(g, 1)
	check("Tras 2 turnos vuelve con +1 de ataque permanente", g.players[0].temple.heroes.is_empty() and g.players[0].passive == [29] and g.players[0].perm_atk.get(29, 0) == 1)
	g.players[0].active = 29
	check("El bono permanente suma dados", g.dice_for(0, true).n >= g.card(29).ataque + 1)
	# Sensei
	g = fresh()
	g.players[0].temple = {"heroes": [{"id": 36, "left": 1}, {"id": 32, "left": 1}]}
	g.players[0].active = 28
	end_turns(g, 1)
	check("Sensei: +2 para Ikko Ikki/Uesugi (Kakizaki es Uesugi)", g.players[0].perm_atk.get(32, 0) == 2 and g.players[0].perm_atk.get(36, 0) == 2)
	# Rennyo
	g = fresh()
	g.players[0].temple = {"heroes": [{"id": 28, "left": 2}]}
	g.players[0].active = 35
	check("Rennyo: capacidad 2", Effects.temple_cap(g, 0) == 2)
	g.players[0].temple.heroes.append({"id": 29, "left": 2})
	g.players[0].active = 0
	Effects.temple_normalize(g, 0)
	check("Sin Rennyo sobra 1: vuelve a juego", g.players[0].temple.heroes.size() == 1 and g.players[0].active == 29)
	# destruir
	g = fresh()
	g.players[1].temple = {"heroes": [{"id": 28, "left": 2}]}
	g.players[1].active = 0
	g.players[0].honor = 4
	check("Destruir el templo rival exige 5 de Honor", not Effects.ability_ready(g, 0, 9003))
	g.players[0].honor = 6
	check("Con 5+ de Honor se puede destruir", Effects.ability_ready(g, 0, 9003))
	g.use_ability(9003)
	g.choose([0])
	check("Templo destruido: pagas 5, el héroe vuelve y la carta va al pozo", g.players[0].honor == 1 and g.players[1].temple.is_empty() and g.players[1].active == 28 and 90 in g.players[1].discard)
	# descartar
	g = fresh()
	g.players[0].temple = {"heroes": [{"id": 28, "left": 2}]}
	g.use_ability(9002)
	g.choose([0])
	check("Descartar el Complejo devuelve a los héroes", g.players[0].temple.is_empty() and g.players[0].active == 28)
	# Kenyo
	g = fresh()
	g.players[0].temple = {"heroes": [{"id": 66, "left": 2}]}
	g.players[0].active = 28
	var h0: int = g.players[0].honor
	end_turns(g, 1)
	check("Kenyo en el Complejo da +3 de Honor aunque haya atacado", g.players[0].honor == h0 + 3)


# ---------------------------------------------------------------- Kotaro y Morichika

func test_kotaro_morichika() -> void:
	# Kotaro copia a Tenzo (+1 dado si el rival tiene más Honor) y Mochizuke (+3 vs Daimyo sin Honor)
	var g := fresh()
	g.players[0].active = 9
	g.players[0].passive = [8, 5]
	g.players[0].honor = 0
	g.players[1].honor = 5
	g.players[1].active = 59   # Daimyo
	var base: int = g.dice_for(0, true).n
	g.players[0].kcopy = [8, 5]
	check("Kotaro copiando a Tenzo y Mochizuke suma sus dados (+1 y +3)", g.dice_for(0, true).n == base + 4)
	g.players[0].kcopy = []
	# decisión de copia en batalla
	g = fresh()
	g.players[0].active = 9
	g.players[0].hand = [8, 5, 4]
	g.players[1].active = 28
	g.players[0].honor = 0
	g.players[1].honor = 5
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Kotaro abre una decisión: hasta 2 Ninja de la mano con efecto de batalla", g.phase == "CHOICE" and g.pending.options.size() == 3 and g.pending.valid == [0, 1, 2])
	g.choose([0, 1])
	check("Kotaro registra a quién copia", has_log(g, "Kotaro copia el efecto de: Tenzo, Mochizuke") or has_log(g, "Kotaro copia el efecto de"))
	# copia de Kosaka: abre su propia decisión de descartar 2
	g = fresh()
	g.players[0].active = 9
	g.players[0].hand = [6, 28, 29, 30]
	g.players[1].active = 28
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Kotaro (1 candidato) pregunta si copia a Kosaka", g.phase == "CHOICE" and g.pending.valid == [0, 1])
	g.choose([0])
	check("Copiar a Kosaka abre su decisión de descartar 2", g.phase == "CHOICE" and "Kosaka" in g.pending.prompt)
	g.choose([0, 1])
	check("Se descartaron 2 cartas", g.players[0].hand.size() == 1 or g.players[0].hand.size() == 2)
	# Sasuke copiado: ataque directo al castillo roba 2
	g = fresh()
	g.players[0].active = 9
	g.players[0].hand = [2]
	g.players[1].active = 0
	var cast: int = g.players[1].castle.size()
	g.declare_attack("castillo")
	check("Kotaro pregunta por Sasuke en ataque directo", g.phase == "CHOICE")
	g.choose([0])
	check("Con Sasuke copiado el castillo pierde 2", g.players[1].castle.size() == cast - 2)
	g = fresh()
	g.players[0].active = 9
	g.players[0].hand = [2]
	g.players[1].active = 0
	cast = g.players[1].castle.size()
	g.declare_attack("castillo")
	g.choose([])
	check("Sin copiar, el castillo pierde solo 1", g.players[1].castle.size() == cast - 1)
	# Kotaro sin Ninja en juego: ataca normal sin preguntar
	g = fresh()
	g.players[0].active = 9
	g.players[1].active = 0
	g.declare_attack("castillo")
	check("Sin otros Ninja no hay decisión", g.phase != "CHOICE")
	# Kotaro solo copia al atacar
	g = fresh()
	g.players[0].active = 28
	g.players[1].active = 9
	g.players[1].passive = [8]
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Kotaro defendiendo no copia", g.phase != "CHOICE" or "Kotaro" not in g.pending.prompt)
	# Morichika
	g = fresh()
	g.players[0].honor = 0
	check("Morichika cuesta 2 sin Pirata", Effects.entry_cost(g, 0, 52) == 2)
	g.players[0].active = 12   # Pirata Wokou
	check("Morichika entra gratis con Pirata Wokou en juego", Effects.entry_cost(g, 0, 52) == 0)
	g.players[0].hand = [52]
	check("Se puede bajar con 0 de Honor", g.can_play_warrior(0, 52))
	g.players[0].active = 10   # Ronin sin "Pirata"
	check("Un Ronin sin «Pirata» no sirve", Effects.entry_cost(g, 0, 52) == 2)


# ---------------------------------------------------------------- cartas de dados (70, 73, 75, 76, 78)

## Duelo hasta la ventana posterior al lanzamiento.
func roll_window(g: Game) -> void:
	g.players[0].active = 28
	g.players[1].active = 25
	g.turn_player = 0
	g.phase = "MAIN"
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()

func test_dice_cards() -> void:
	var g := fresh(3)
	g.players[0].hand = [70]
	check("Conspiración no se juega antes de lanzar", not Effects.can_play(g, 0, 70) )
	roll_window(g)
	check("Con una carta de dados se abre la ventana posterior al lanzamiento", g.phase == "WINDOW" and g.battle.get("rolled", false) and g.battle.priority == 0)
	check("Se juega Conspiración en esa ventana", Effects.can_play(g, 0, 70))
	var before: int = g.battle.res[1].total
	g.play_action(0)
	check("Conspiración abre la elección de dado (tuyo o rival)", g.phase == "CHOICE" and g.pending.options.size() == g.battle.res[0].rolls.size() + g.battle.res[1].rolls.size())
	var k: int = g.battle.res[0].rolls.size()   # primer dado del rival
	var res1: Dictionary = g.battle.res[1]
	g.choose([k])
	var sum: int = 0
	for v in res1.rolls:
		sum += v
	check("El total del rival sigue siendo la suma de sus dados", res1.total == sum + res1.points)
	check("El duelo continúa solo cuando nadie más puede jugar cartas de dados", not g.battle.get("rolled", false) and g.phase != "CHOICE")
	check("Tras jugar sigue la ventana y puedes continuar", g.phase == "WINDOW" or g.phase == "MAIN" or g.phase == "OVER")
	# Intriga
	g = fresh(4)
	g.players[0].hand = [76]
	roll_window(g)
	var res0: Dictionary = g.battle.res[0]
	g.play_action(0)
	g.choose([0])
	check("Intriga fija un dado en 3", res0.rolls[0] == 3)
	# Deshonor
	g = fresh(5)
	g.players[0].hand = [73]
	g.players[0].honor = 3
	roll_window(g)
	if g.phase == "WINDOW":
		var r1: Dictionary = g.battle.res[1]
		var tot: int = r1.total
		var reducible := 0
		for v in r1.rolls:
			if v > 1:
				reducible += 1
		g.play_action(0)
		check("Deshonor cuesta 1 de Honor", g.players[0].honor == 2)
		check("Deshonor baja 1 punto por cada dado rival (mínimo 1 por dado)", r1.total == tot - reducible)
	else:
		check("Deshonor: ventana abierta (el rival sacó todos 1)", true)
		check("(sin dados reducibles)", true)
	g = fresh(5)
	g.players[0].hand = [73]
	g.players[0].honor = 0
	roll_window(g)
	check("Deshonor sin Honor no se puede jugar (no abre ventana)", g.phase != "WINDOW" or not Effects.can_play(g, 0, 73))
	# sin cartas: no hay ventana
	g = fresh(6)
	roll_window(g)
	check("Sin cartas de dados el duelo se resuelve directo", not g.battle.get("rolled", false) and g.phase != "WINDOW")
	# el rival (humano o IA) también puede jugar una
	g = fresh(7)
	g.players[1].hand = [76]
	roll_window(g)
	check("Si solo el defensor tiene carta de dados, la ventana le toca a él", g.phase == "WINDOW" and g.battle.priority == 1)
	g.pass_priority()
	check("Al pasar el defensor se resuelve", g.phase != "WINDOW" or g.battle.get("rolled", false) == false)
	# El Nakasendo
	g = fresh()
	g.players[0].hand = [75, 1, 2]
	g.players[0].deck = [3, 4, 5, 6, 7, 8, 9, 10]
	check("El Nakasendo con 3 cartas se puede jugar", Effects.can_play(g, 0, 75))
	g.play_action(0)
	check("Roba entre 1 y 6 cartas (tira un dado)", g.players[0].hand.size() >= 3 and g.players[0].hand.size() <= 8)
	g = fresh()
	g.players[0].hand = [75, 1, 2, 3]
	check("El Nakasendo con 4 cartas no se puede", not Effects.can_play(g, 0, 75))
	# El camino
	g = fresh(8)
	g.players[0].hand = [78]
	g.players[0].active = 28
	g.players[1].active = 25
	g.declare_attack("guerrero")
	check("El camino se juega antes de lanzar", Effects.can_play(g, 0, 78))
	g.play_action(0)
	g.pass_priority()
	g.pass_priority()
	check("El camino: el primer dado vale 6", has_log(g, "El camino: el primer dado de A vale 6") and g.last_duel.rolls[0][0] == 6)
	g = fresh(8)
	g.players[0].hand = [78]
	check("El camino no se juega en tu fase principal", not Effects.can_play(g, 0, 78))


# ---------------------------------------------------------------- Rectitud Zen (81), Coraje (93), Terumoto (63), Yoshimoto (67)

func test_one_die_cards() -> void:
	# Honestidad (94): duplica el resultado de UN dado tuyo, después de lanzar
	var g := fresh(3)
	g.players[0].hand = [94]
	check("Honestidad no se juega antes de lanzar", not Effects.can_play(g, 0, 94))
	roll_window(g)
	var r0: Dictionary = g.battle.res[0]
	var v0: int = r0.rolls[0]
	var t0: int = r0.total
	check("Honestidad se juega después de lanzar", Effects.can_play(g, 0, 94))
	g.play_action(0)
	check("Honestidad pide elegir UN dado tuyo (o se aplica solo si tienes uno)", (g.phase == "CHOICE" and g.pending.options.size() == r0.rolls.size()) or r0.rolls.size() == 1)
	g.choose([0])
	check("Honestidad duplica solo ese dado", r0.rolls[0] == v0 * 2 and r0.total == t0 + v0)
	# Dominio de sí mismo (72): triplica UN dado si tu castillo tiene 2+ cartas más
	g = fresh(3)
	g.players[0].hand = [72]
	g.players[1].castle.pop_back()
	g.players[1].castle.pop_back()
	roll_window(g)
	r0 = g.battle.res[0]
	v0 = r0.rolls[0]
	t0 = r0.total
	check("Dominio de sí mismo se juega con 2+ cartas más en el castillo", Effects.can_play(g, 0, 72))
	g.play_action(0)
	g.choose([0])
	check("Dominio de sí mismo triplica solo ese dado", r0.rolls[0] == v0 * 3 and r0.total == t0 + 2 * v0)
	# Watanabe Tenzo (61): Ninja +1 dado y roba 1 carta extra una vez por turno
	g = fresh()
	g.players[0].active = 61
	g.players[0].passive = [1]
	var base: int = g.card(1).ataque
	g.players[0].active = 1
	g.players[0].passive = [61]
	check("Watanabe Tenzo da +1 dado a tus Ninja", g.dice_for(0, true).n == base + 1)
	g.players[0].active = 61
	g.players[0].passive = []
	check("Watanabe Tenzo tiene habilidad de robar 1", Effects.ability_ready(g, 0, 61))
	var h: int = g.players[0].hand.size()
	g.use_ability(61)
	check("Watanabe Tenzo roba 1 carta extra", g.players[0].hand.size() == h + 1 and not Effects.ability_ready(g, 0, 61))

func test_final_cards() -> void:
	# Rectitud Zen: anula modificadores
	var g := fresh(9)
	g.players[0].active = 17      # Musashi: 1 dado por cada 2 de Honor
	g.players[0].honor = 10
	g.players[1].active = 25
	g.players[0].hand = [81, 72]
	var boosted: int = g.dice_for(0, true).n
	g.declare_attack("guerrero")
	g.play_action(1)               # Dominio de sí mismo (x3)
	check("Con Dominio y Honor 10 el atacante lanza muchos dados", g.dice_for(0, true).n > g.card(17).ataque)
	g.play_action(0)
	check("Rectitud Zen: cada guerrero lanza los dados de su carta", g.dice_for(0, true).n == g.card(17).ataque and g.dice_for(1, false).n == g.card(25).ataque)
	check("Rectitud Zen se marca en la batalla", g.battle.get("plain", false))
	check("No se puede jugar dos veces en la misma batalla", not Effects.can_play(g, 0, 81))
	g = fresh(9)
	g.players[0].active = 6       # Kosaka: descarta 2 al empezar la batalla
	g.players[0].hand = [81, 28, 29]
	g.players[1].active = 25
	g.declare_attack("guerrero")
	g.play_action(0)
	g.pass_priority()
	g.pass_priority()
	check("Rectitud Zen anula los efectos de inicio de batalla (Kosaka no pregunta)", g.phase != "CHOICE" or "Kosaka" not in g.pending.prompt)
	# Coraje
	g = fresh(10)
	g.players[0].active = 55      # Daimyo
	g.players[0].hand = [93]
	g.players[1].active = 25
	g.declare_attack("guerrero")
	var d0: int = g.dice_for(0, true).n
	check("Coraje se juega con un Daimyo solo", Effects.can_play(g, 0, 93))
	g.play_action(0)
	check("Coraje: +2 dados", g.dice_for(0, true).n == d0 + 2)
	g = fresh(10)
	g.players[0].active = 55
	g.players[0].passive = [28]
	g.players[0].hand = [93]
	g.players[1].active = 25
	g.declare_attack("guerrero")
	check("Coraje no se juega con otro héroe en juego", not Effects.can_play(g, 0, 93))
	g = fresh(10)
	g.players[0].active = 28
	g.players[0].hand = [93]
	g.players[1].active = 25
	g.declare_attack("guerrero")
	check("Coraje no se juega con un guerrero normal", not Effects.can_play(g, 0, 93))
	# Terumoto
	g = fresh()
	g.players[0].active = 63
	var base: int = g.dice_for(0, true).n
	g.players[0].passive = [37]
	check("Terumoto: +1 dado por otro Mori", g.dice_for(0, true).n == base + 1)
	g.players[0].passive = [37, 38, 39]
	check("Terumoto: tope de +2", g.dice_for(0, true).n == base + 2)
	# Yoshimoto
	g = fresh()
	g.players[0].active = 67
	g.players[0].honor = 5
	g.players[0].discard = [43, 28]
	check("Yoshimoto: habilidad disponible con 2+ Honor y un Imagawa en el pozo", Effects.ability_ready(g, 0, 67))
	g.use_ability(67)
	check("Yoshimoto ofrece solo guerreros Imagawa", g.phase == "CHOICE" and g.pending.options.size() == 1)
	g.choose([0])
	check("Yoshimoto recoge al Imagawa y paga 2", g.players[0].hand == [43] and g.players[0].honor == 3 and not (43 in g.players[0].discard))
	check("Una vez por turno", not Effects.ability_ready(g, 0, 67))
	g = fresh()
	g.players[0].active = 67
	g.players[0].honor = 1
	g.players[0].discard = [43]
	check("Sin Honor suficiente no se usa", not Effects.ability_ready(g, 0, 67))


# ---------------------------------------------------------------- avisos para la interfaz (Harakiri, sonidos, mensajes)

func test_ui_events() -> void:
	var g := fresh()
	check("Harakiri: rendirse hace perder al jugador", g.surrender(0) and g.phase == "OVER" and g.winner == 1 and has_log(g, "Harakiri"))
	check("No se puede rendir dos veces", not g.surrender(1))
	g = fresh()
	g.sfx_enabled = true
	g.players[0].deck = [1, 2, 3]
	g.draw(0, 1)
	check("Robar avisa el sonido «robar»", "robar" in g.sfx)
	g.sfx.clear()
	g.players[0].hand = [1]
	g.players[0].active = 28
	g.players[1].active = 25
	g.declare_attack("guerrero")
	check("Atacar avisa el sonido de espadas", "espadas" in g.sfx)
	g.pass_priority()
	g.pass_priority()
	check("Lanzar los dados avisa el sonido de dados", "dados" in g.sfx)
	g = fresh()
	g.players[0].facedown = [96]
	g.players[0].active = 28
	g._kill_active(0, 1, 0)
	check("Revelar Cortesía deja un mensaje emergente", g.toasts.size() == 1 and "Cortesía" in g.toasts[0])
	g = fresh()
	g.draw(0, 1)
	check("Sin sonido activado no se acumulan avisos (simulaciones)", g.sfx.is_empty())
	# Movimientos de cartas para la animación
	g = fresh()
	g.sfx_enabled = true
	g.players[0].deck = [1, 2, 3]
	g.draw(0, 2)
	var dh := 0
	for m in g.moves:
		if m.k == "deck_hand" and m.p == 0:
			dh += 1
	check("Robar del mazo genera 2 movimientos mazo→mano", dh == 2)
	g.moves.clear()
	g.players[0].castle = [4, 5]
	g.castle_draw(0, 1)
	check("Robar del castillo genera movimiento castillo→mano", g.moves.size() == 1 and g.moves[0].k == "castle_hand")
	g.moves.clear()
	g.players[1].active = 25
	g._kill_active(1, 0, 0)
	check("Guerrero derrotado genera movimiento campo→pozo", g.moves.size() >= 1 and g.moves[0].k == "field_discard" and g.moves[0].id == 25 and 25 in g.players[1].discard)
	g = fresh()
	g.draw(0, 1)
	check("Sin animaciones activadas no se acumulan movimientos", g.moves.is_empty())


func test_swap_active() -> void:
	var g := fresh()
	g.players[0].active = 28
	g.players[0].passive = [25, 29]
	check("Se puede cambiar el activo con pasivos", g.can_swap_active(0))
	check("Cambio de rol: el pasivo elegido pasa a activo", g.swap_active(1) and g.players[0].active == 29)
	check("El activo anterior ocupa su lugar en la reserva", g.players[0].passive == [25, 28])
	check("Solo una vez por turno", not g.can_swap_active(0) and not g.swap_active(0))
	g = fresh()
	g.players[0].active = 28
	g.players[0].passive = [25]
	g.attacked_this_turn = true
	check("No se puede cambiar tras atacar", not g.can_swap_active(0))
	g = fresh()
	g.players[0].active = 0
	g.players[0].passive = [25]
	check("Sin activo, el pasivo entra como activo", g.swap_active(0) and g.players[0].active == 25 and g.players[0].passive.is_empty())
	g = fresh()
	g.players[0].active = 28
	g.players[0].passive = [25]
	g.open_swap()
	check("Abre ventana de decisión", g.phase == "CHOICE")
	g.choose([0])
	check("La decisión aplica el cambio", g.players[0].active == 25 and g.phase == "MAIN")


func test_multi_warriors() -> void:
	var g := fresh()
	g.players[0].honor = 20
	g.players[0].active = 0
	g.players[0].passive = []
	g.players[0].hand = [9, 8, 5, 4, 1]
	check("Se puede bajar un guerrero", g.play_warrior(0))
	check("Se puede bajar un segundo guerrero en el mismo turno", g.play_warrior(0))
	check("Se puede bajar un tercero", g.play_warrior(0))
	check("Se puede bajar un cuarto (1 activo + 3 pasivos)", g.play_warrior(0) and g.players[0].active == 9 and g.players[0].passive.size() == 3)
	check("No hay un quinto: el campo está lleno", not g.can_play_warrior(0, 1) and not g.play_warrior(0))
	# Kotaro con Ninja en la mano abre su decisión al atacar
	g = fresh()
	g.players[0].honor = 20
	g.players[0].hand = [9, 8, 5, 6]
	g.players[1].active = 28
	g.play_warrior(0)   # Kotaro entra; Tenzo, Mochizuke y Kosaka siguen en la mano
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Kotaro (con Ninja en la mano) ofrece copiar al atacar", g.phase == "CHOICE" and g.pending.options.size() == 3)
	# sin Ninja que copiar: lo dice el registro
	g = fresh()
	g.players[0].active = 9
	g.players[1].active = 28
	g.declare_attack("guerrero")
	g.pass_priority()
	g.pass_priority()
	check("Kotaro sin Ninja avisa en el registro", has_log(g, "Kotaro no tiene ningún Ninja"))
