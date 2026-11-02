class_name Effects
extends RefCounted
## Efectos de cartas. Las cartas sin efecto implementado funcionan como "vanilla" (solo ataque y costo).
## Regla de diseño: ningún efecto decide por el jugador. Si hay que elegir algo, se abre una decisión
## (Game.request_choice) y la IA responde con AI._choice. Solo es aleatorio lo que la carta dice que es aleatorio.

## Acciones (Bushi) ya implementadas.
const ACTIONS := [70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99]

## Bushi que se juegan después de lanzar los dados (ventana posterior al lanzamiento).
const POST_ROLL := [70, 72, 73, 76, 94]

## Dilema del cucu: ¿el cambio de clan dura para siempre (true) o hasta el final del turno (false)?
const DILEMA_PERMANENT := false
## Cartas boca abajo: máximo por jugador (una a cada lado del guerrero activo)
const FACEDOWN_MAX := 2
const TEMPLE_TURNS := 2

## Guerreros y daimyos con efecto implementado (solo para avisar en la interfaz).
const WARRIORS_WITH_EFFECT := [63, 67, 9, 52, 19, 33, 35, 36, 48, 900, 32, 58, 56, 11, 12, 18, 22, 25, 49, 50, 51, 55, 57, 62, 64, 66, 68, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 14, 15, 16, 17, 20, 21, 23, 24, 26, 27, 28, 29, 30, 31, 34, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 53, 54, 59, 60, 61, 65, 69]

static func is_implemented_action(id: int) -> bool:
	return id in ACTIONS

## Cartas que se quedan en juego al jugarlas (no van al pozo): el Complejo Enryaku-Ji.
static func stays_in_play(id: int) -> bool:
	return id == 90

static func ends_turn(id: int) -> bool:
	return id == 95  # Nobleza de espíritu

# ------------------------------------------------------------------ ayudas

static func _count_clan(g: Game, p: int, clan: String) -> int:
	var n := 0
	for id in g.heroes_in_play(p):
		if g.clan_of(p, id) == clan:
			n += 1
	return n

## Opciones de decisión a partir de una lista de ids de cartas.
static func _opts(g: Game, ids: Array) -> Array:
	var out := []
	for id in ids:
		out.append({"card": id, "label": g.card(id).nombre})
	return out

static func _hand_opts(g: Game, p: int) -> Array:
	return _opts(g, g.players[p].hand)

static func _ids_where(g: Game, ids: Array, pred: Callable) -> Array:
	var out := []
	for id in ids:
		if pred.call(id):
			out.append(id)
	return out

static func _discard_selected(g: Game, p: int, sel: Array) -> void:
	var pl = g.players[p]
	var names := []
	for o in sel:
		pl.hand.erase(o.card)
		pl.discard.append(o.card)
		g._fx("hand_discard", p, o.card)
		names.append(g.card(o.card).nombre)
	if not names.is_empty():
		g._sfx("descartar")
		g._log("%s descarta: %s." % [pl.name, ", ".join(names)])

## Mueve cartas del pozo a la mano.
static func _take_to_hand(g: Game, p: int, sel: Array, source: String) -> void:
	var pl = g.players[p]
	var names := []
	for o in sel:
		pl.discard.erase(o.card)
		pl.hand.append(o.card)
		names.append(g.card(o.card).nombre)
	if not names.is_empty():
		g._log("%s recupera del pozo: %s." % [source, ", ".join(names)])

# ------------------------------------------------------------------ ayudas de las acciones nuevas

const MARRIAGE_CAP := 6   # Matrimonio arreglado: tope de Honor total

## Combinaciones de 3 héroes en juego de distintos clanes (Ninja y Ronin cuentan como un "clan" cada uno).
static func _marriage_combos(g: Game, p: int) -> Array:
	var heroes: Array = g.heroes_in_play(p)
	var out := []
	for a in range(heroes.size()):
		for b in range(a + 1, heroes.size()):
			for c in range(b + 1, heroes.size()):
				var ca: String = g.clan_of(p, heroes[a])
				var cb: String = g.clan_of(p, heroes[b])
				var cc: String = g.clan_of(p, heroes[c])
				if ca != cb and ca != cc and cb != cc:
					out.append([heroes[a], heroes[b], heroes[c]])
	return out

## Hansei / Kansei: descartas `discards` cartas y bajas gratis un guerrero de coste `need` de tu mano.
## Bajar así no usa tu "guerrero por turno". Los efectos "al entrar en juego" sí se activan.
static func _free_entry(g: Game, p: int, need: int, discards: int, source: String) -> void:
	var pl = g.players[p]
	var warriors := _ids_where(g, pl.hand, func(c): return g.is_hero(c) and g.card(c).costo_honor == need)
	var cb := func(sel):
		var w: int = sel[0].card
		var others: Array = pl.hand.duplicate()
		others.erase(w)
		var cb2 := func(sel2):
			_discard_selected(g, p, sel2)
			pl.hand.erase(w)
			if pl.active == 0:
				pl.active = w
			else:
				pl.passive.append(w)
			g._log("%s: %s baja gratis a %s." % [source, pl.name, g.card(w).nombre])
			hero_entered(g, p, w)
			on_enter(g, p, w)
		g.request_choice(p, "%s: elige %d carta(s) de tu mano para descartar" % [source, discards], _opts(g, others), [discards], cb2, "give")
	g.request_choice(p, "%s: elige el guerrero de coste %d que bajarás gratis desde tu mano" % [source, need], _opts(g, warriors), [1], cb, "take")

## Lealtad: cada héroe que bajas avanza (o rompe) los compromisos abiertos de ese jugador.
static func hero_entered(g: Game, p: int, id: int) -> void:
	var pl = g.players[p]
	var keep := []
	for t in pl.lealtad:
		if g.clan_of(p, id) != t.clan:
			g._log("Lealtad: %s no es del clan %s, el compromiso de %s se pierde." % [g.card(id).nombre, t.clan, pl.name])
			continue
		t.left -= 1
		if t.left <= 0:
			pl.honor += 3
			g._log("Lealtad cumplida: %s genera 3 de Honor." % pl.name)
		else:
			g._log("Lealtad (%s): faltan %d héroe(s) del clan." % [t.clan, t.left])
			keep.append(t)
	pl.lealtad = keep

## Jugadas de la IA para las acciones nuevas (devuelven índices de las opciones de la decisión abierta).
static func _ai_strategist(g: Game, p: int) -> Array:
	var pl = g.players[p]
	var idx := []
	for i in pl.hand.size():
		if g.card_value(pl.hand[i]) <= 1 and idx.size() < 4:
			idx.append(i)
	return idx if idx.size() >= 2 else []

static func _ai_musha(g: Game, p: int) -> Array:
	var pl = g.players[p]
	var idx := []
	for i in pl.hand.size():
		if g.card(pl.hand[i]).clan == "Ronin" and idx.size() < 7:
			idx.append(i)
	return idx

static func _ai_lealtad(g: Game, p: int) -> Array:
	var pl = g.players[p]
	var opts := _clan_opts(g)
	var best := 0
	var best_n := -1
	for i in opts.size():
		var n := 0
		for c in pl.hand:
			if g.is_hero(c) and g.card(c).clan == opts[i].value:
				n += 1
		if n > best_n:
			best_n = n
			best = i
	return [best]

# ------------------------------------------------------------------ acciones

static func can_play(g: Game, p: int, id: int) -> bool:
	var pl = g.players[p]
	var op = g.players[1 - p]
	# Junyo (34): el rival no puede jugar más de 1 Bushi por turno
	if op.active == 34 and g.bushi_count[p] >= 1:
		return false
	var main: bool = g.phase == "MAIN"
	var rolled: bool = g.phase == "WINDOW" and g.battle.get("rolled", false)
	var win: bool = g.phase == "WINDOW" and not rolled     # ventana ANTES de lanzar los dados
	match id:
		70, 76:   # Conspiración / Intriga: hay dados lanzados que cambiar
			return rolled
		73:       # Deshonor: pagas 1 de Honor y el rival tiene algún dado mayor que 1
			return rolled and pl.honor >= 1 and _opp_has_reducible_die(g, p)
		75:       # El Nakasendo: solo con 3 cartas o menos en la mano (contándola)
			return main and pl.hand.size() <= 3
		81:       # (imagen 81) anula modificaciones: antes de lanzar, en un duelo (una sola vez por batalla)
			return win and g.battle.resisted and pl.active != 0 and not g.battle.get("plain", false)
		78:       # (imagen 78) el próximo dado vale 6: antes de lanzar, en un duelo
			return win and g.battle.resisted and pl.active != 0
		93:       # Coraje: un Daimyo solo en el campo de batalla
			return win and g.battle.resisted and pl.active != 0 and g.card(pl.active).categoria == "Daimyo" and pl.passive.is_empty()
		96, 98:   # giratorias: se colocan boca abajo (Nabe del rival lo impide)
			return main and pl.facedown.size() < FACEDOWN_MAX and op.active != 33
		77:       # Liderazgo: 2 héroes del mismo clan y una carta boca abajo rival
			return (main or win) and not op.facedown.is_empty() and _has_pair(g, p)
		80:       # Dilema del cucu: necesitas algún héroe que no sea Ninja ni Ronin
			if not (main or win):
				return false
			for h in g.heroes_in_play(p):
				if g.card(h).clan != "Ninja" and g.card(h).clan != "Ronin":
					return true
			return false
		89:       # Castillo de montaña: lugar para al menos 1 ficha y cartas en el mazo
			return main and _free_slots(g, p) >= 1 and not pl.deck.is_empty()
		90:
			return main and pl.temple.is_empty()
		71, 95:
			return main
		74:
			return main
		79:
			return main and pl.hand.size() >= 4
		82:   # El maestro estratega: necesitas al menos 1 carta más en la mano
			return main and pl.hand.size() >= 2
		85, 86:   # Hansei / Kansei: un guerrero del coste indicado + las cartas a descartar, y lugar para bajarlo
			var need: int = 2 if id == 85 else 3
			var disc: int = 3 if id == 85 else 4
			if not main or pl.hand.size() < disc + 2 or not (pl.active == 0 or pl.passive.size() < Game.MAX_PASSIVE):
				return false
			return not _ids_where(g, pl.hand, func(c): return g.is_hero(c) and g.card(c).costo_honor == need).is_empty()
		87:   # Musha Shugyo: solo luchando con un Ronin
			return win and g.battle.resisted and pl.active != 0 and g.card(pl.active).clan == "Ronin" and pl.hand.size() >= 2
		92:   # Matrimonio arreglado: 3 héroes de distintos clanes en juego y algo de Honor por ganar
			return main and pl.honor < MARRIAGE_CAP and pl.hand.size() >= 2 and not _marriage_combos(g, p).is_empty()
		97:
			return main
		83:
			return main and pl.castle.size() < Game.CASTLE_SIZE
		84:
			return main and not g.heroes_in_play(1 - p).is_empty()
		88:
			return main and pl.castle.size() < Game.CASTLE_SIZE and not pl.deck.is_empty()
		91:
			return main and _count_clan(g, p, "Ninja") >= 2
		94:   # Honestidad: duplica el resultado de UNO de tus dados (ya lanzados)
			return rolled and g.battle.resisted and pl.active != 0 and not g.battle.res[p].rolls.is_empty()
		72:   # Dominio de sí mismo: triplica el resultado de UNO de tus dados (ya lanzados)
			return rolled and g.battle.resisted and pl.active != 0 and pl.castle.size() >= op.castle.size() + 2 and not g.battle.res[p].rolls.is_empty()
		99:
			if not main:
				return false
			for c in pl.discard:
				if g.is_hero(c):
					return true
			return false
	return false

static func _opp_has_reducible_die(g: Game, p: int) -> bool:
	if not g.battle.has("res"):
		return false
	for v in g.battle.res[1 - p].rolls:
		if v > 1:
			return true
	return false

## ¿Tiene p en la mano una carta de dados que pueda jugar ahora?
static func has_post_roll_play(g: Game, p: int) -> bool:
	if g.phase == "OVER":
		return false
	for id in g.players[p].hand:
		if id in POST_ROLL and can_play_as(g, p, id):
			return true
	return false

## can_play suponiendo que ya se abrió la ventana posterior al lanzamiento (para decidir si abrirla).
static func can_play_as(g: Game, p: int, id: int) -> bool:
	var was: bool = g.battle.get("rolled", false)
	var ph: String = g.phase
	g.battle["rolled"] = true
	g.phase = "WINDOW"
	var ok := can_play(g, p, id)
	g.battle["rolled"] = was
	g.phase = ph
	return ok

## Dados lanzados de ambos como opciones de decisión (primero los de p).
static func _die_opts(g: Game, p: int) -> Array:
	var dice := []
	for who in [p, 1 - p]:
		for i in g.battle.res[who].rolls.size():
			dice.append({"label": "Tuyo" if who == p else "Del rival", "die": g.battle.res[who].rolls[i], "who": who, "i": i})
	return dice

static func _ai_die_pick(g: Game, p: int, id: int) -> int:
	var dice := _die_opts(g, p)
	var best := 0
	var best_gain := -99.0
	for k in dice.size():
		var v: int = dice[k].die
		var mine: bool = dice[k].who == p
		var target: float = 3.0 if id == 76 else 3.5
		var gain: float = (target - v) if mine else (v - target)
		if gain > best_gain:
			best_gain = gain
			best = k
	return best

static func _free_slots(g: Game, p: int) -> int:
	var pl = g.players[p]
	return (1 if pl.active == 0 else 0) + (Game.MAX_PASSIVE - pl.passive.size())

static func _has_pair(g: Game, p: int) -> bool:
	var seen := {}
	for h in g.heroes_in_play(p):
		var c: String = g.clan_of(p, h)
		if seen.has(c):
			return true
		seen[c] = true
	return false

static func apply(g: Game, p: int, id: int) -> void:
	var pl = g.players[p]
	var op = g.players[1 - p]
	match id:
		70, 76:  # Conspiración (repite un dado) / Intriga (fija un dado en 3): tuyo o del rival
			var cb := func(sel):
				var o: Dictionary = sel[0]
				var r: Dictionary = g.battle.res[o.who]
				var oldv: int = r.rolls[o.i]
				var newv: int = g.rng.randi_range(1, 6) if id == 70 else 3
				r.rolls[o.i] = newv
				r.total += newv - oldv
				g._log("%s: un dado de %s pasa de %d a %d (total %d)." % [g.card(id).nombre, g.players[o.who].name, oldv, newv, r.total])
			g.request_choice(p, ("Conspiración: elige el dado que se vuelve a lanzar" if id == 70 else "Intriga: elige el dado que queda en 3"),
				_die_opts(g, p), [1], cb, "die", func(): return [_ai_die_pick(g, p, id)])
		73:  # Deshonor: pagas 1 de Honor; cada dado del rival baja 1 punto (mínimo 1 por dado)
			pl.honor -= 1
			var r: Dictionary = g.battle.res[1 - p]
			var n := 0
			for i in r.rolls.size():
				if r.rolls[i] > 1:
					r.rolls[i] -= 1
					r.total -= 1
					n += 1
			g._log("Deshonor: %s paga 1 de Honor; %d dado(s) de %s bajan 1 punto (total %d)." % [pl.name, n, op.name, r.total])
		75:  # El Nakasendo: lanzas un dado y robas esa cantidad de cartas
			var r: int = g.rng.randi_range(1, 6)
			g._log("El Nakasendo: %s lanza un dado: %d. Roba %d carta(s)." % [pl.name, r, r])
			g.draw(p, r)
		78:  # (imagen 78) tu primer dado del próximo lanzamiento vale 6
			pl.six_next = 1
			g._log("El camino: el primer dado de %s en el próximo lanzamiento valdrá 6." % pl.name)
		81:  # (imagen 81) se anulan todas las modificaciones de dados de esta batalla (y sus efectos de inicio)
			for q in 2:
				var o = g.players[q]
				o.bb_dice = 0
				o.bb_points = 0
				o.bb_set = 0
				o.mult = 1
				o.six_next = 0
				o.pick_num = 0
				o.kcopy = []
				o.next_ninja = 0
			g.battle["plain"] = true
			g._log("Rectitud Zen: todas las modificaciones de esta batalla quedan anuladas; cada guerrero lanza los dados de su carta.")
		93:  # Coraje: tu Daimyo solo en el campo de batalla +2 dados
			pl.bb_dice += 2
			g._log("Coraje: %s suma +2 dados." % pl.name)
		77:  # Liderazgo: destruyes una carta boca abajo del rival (a ciegas)
			var side := ["izquierda", "derecha"]
			var opts := []
			for i in op.facedown.size():
				opts.append({"label": "Carta boca abajo (%s)" % side[i], "value": i})
			var cb := func(sel):
				var c: int = op.facedown.pop_at(sel[0].value)
				op.discard.append(c)
				g._log("Liderazgo: %s destruye la carta boca abajo de %s: era %s." % [pl.name, op.name, g.card(c).nombre])
				g.toast("Liderazgo destruye una carta boca abajo de %s: era %s" % [op.name, g.card(c).nombre])
			g.request_choice(p, "Liderazgo: elige cuál carta boca abajo del rival destruyes (no sabes cuál es)", opts, [1], cb, "take")
		80:  # Dilema del cucu: nombras un clan; tus héroes (menos Ninja y Ronin) pasan a ese clan
			var cb := func(sel):
				pl.clan_flag = {"clan": sel[0].value, "turn": g.turn_number}
				g._log("Dilema del cucu: los héroes de %s pasan al clan %s%s." % [pl.name, sel[0].value, "" if DILEMA_PERMANENT else " hasta el final del turno"])
			g.request_choice(p, "Dilema del cucu: nombra el clan al que pasarán tus héroes (Ninja y Ronin no cambian)", _clan_opts(g), [1], cb, "dilema",
				func(): return _ai_dilema(g, p))
		89:  # Castillo de montaña: hasta 2 cartas del mazo entran como fichas 1/1 Ronin
			var k := mini(2, mini(_free_slots(g, p), pl.deck.size()))
			for i in k:
				pl.shadow.append(pl.deck.pop_back())
				if pl.active == 0:
					pl.active = CardDB.TOKEN_ID
				else:
					pl.passive.append(CardDB.TOKEN_ID)
			g._log("Castillo de montaña: %s pone %d ficha(s) Ronin 1/1." % [pl.name, k])
		90:  # Complejo Enryaku-Ji: queda en juego; los héroes entran con su habilidad
			pl.temple = {"heroes": []}
			g._log("%s construye el Complejo Enryaku-Ji (capacidad %d)." % [pl.name, temple_cap(g, p)])
		71:  # Ceremonia del té: roba 1, genera 1 de Honor (x2 con Yoshiteru en juego)
			var m := _yoshiteru(g, p)
			g.draw(p, m)
			pl.honor += m
		72, 94:  # Dominio de sí mismo (x3) / Honestidad (x2): multiplica el resultado de UN solo dado tuyo
			var mine := _die_opts(g, p).filter(func(d): return d.who == p)
			var k_mul: int = 3 if id == 72 else 2
			var cb72 := func(sel):
				var o: Dictionary = sel[0]
				var r: Dictionary = g.battle.res[p]
				var oldv: int = r.rolls[o.i]
				r.rolls[o.i] = oldv * k_mul
				r.total += oldv * (k_mul - 1)
				g._log("%s: un dado de %s pasa de %d a %d (total %d)." % [g.card(id).nombre, pl.name, oldv, oldv * k_mul, r.total])
			var best := 0
			for k in mine.size():
				if mine[k].die > mine[best].die:
					best = k
			g.request_choice(p, ("Dominio de sí mismo: elige UN dado tuyo para triplicar su resultado" if id == 72 else "Honestidad: elige UN dado tuyo para duplicar su resultado"),
				mine, [1], cb72, "die", func(): return [best])
		74:  # El destino del clan: nombras un clan; robas 1 por cada personaje en juego de ese clan (x2 con Yoshiteru)
			var cb := func(sel):
				var clan: String = sel[0].value
				var n := 0
				for q in 2:
					for h in g.heroes_in_play(q):
						if g.card(h).clan == clan:
							n += 1
				var total: int = n * _yoshiteru(g, p)
				g._log("El destino del clan: %s tiene %d personaje(s) en juego, %s roba %d." % [clan, n, pl.name, total])
				g.draw(p, total)
			g.request_choice(p, "El destino del clan: nombra un clan (robas 1 carta por cada personaje suyo en juego)", _clan_opts(g), [1], cb, "clan_help")
		79:  # Reiki: bota 3 cartas (a elección), +2 Honor
			var cb := func(sel):
				_discard_selected(g, p, sel)
				pl.honor += 2
			g.request_choice(p, "Reiki: elige 3 cartas de tu mano para botar (ganas +2 de Honor)", _hand_opts(g, p), [3], cb, "give")
		82:  # El maestro estratega: pones X cartas de tu mano al final del mazo y robas X
			var rng_counts: Array = range(0, pl.hand.size() + 1)
			var cb := func(sel):
				if sel.is_empty():
					g._log("El maestro estratega: %s decide no cambiar cartas." % pl.name)
					return
				var names := []
				for o in sel:
					pl.hand.erase(o.card)
					pl.deck.push_front(o.card)   # el "tope" del mazo es el final del arreglo
					names.append(g.card(o.card).nombre)
				g._log("El maestro estratega: %s manda %d carta(s) al fondo del mazo y roba %d." % [pl.name, sel.size(), sel.size()])
				g.draw(p, sel.size())
			g.request_choice(p, "El maestro estratega: elige las X cartas de tu mano que irán al final de tu mazo (luego robas X)", _hand_opts(g, p), rng_counts, cb, "give",
				func(): return _ai_strategist(g, p))
		85:
			_free_entry(g, p, 2, 3, "Hansei")
		86:
			_free_entry(g, p, 3, 4, "Kansei")
		87:  # Musha Shugyo: descartas X cartas; +1 de ataque (dado) por cada Ronin descartado (máx. 7)
			var cb := func(sel):
				var ronin := 0
				for o in sel:
					if g.card(o.card).clan == "Ronin":
						ronin += 1
				_discard_selected(g, p, sel)
				var bonus := mini(ronin, 7)
				if bonus > 0:
					pl.bb_dice += bonus
					g._log("Musha Shugyo: %d Ronin descartado(s), %s suma +%d de ataque." % [ronin, pl.name, bonus])
				else:
					g._log("Musha Shugyo: sin Ronin descartados, no hay bono.")
			g.request_choice(p, "Musha Shugyo: elige las cartas de tu mano que descartarás (+1 de ataque por cada Ronin descartado, máx. 7)", _hand_opts(g, p), range(0, pl.hand.size() + 1), cb, "give",
				func(): return _ai_musha(g, p))
		92:  # Matrimonio arreglado: descartas 3 héroes de distintos clanes, luego X cartas de la mano por X de Honor (tope 6)
			var combos := _marriage_combos(g, p)
			var opts := []
			for c in combos:
				var names := []
				for h in c:
					names.append(g.card(h).nombre)
				opts.append({"label": " + ".join(names), "value": c})
			var cb := func(sel):
				var trio: Array = sel[0].value
				for h in trio:
					if pl.active == h:
						pl.active = 0
					else:
						pl.passive.erase(h)
					g.send_to_discard(p, h)
				var names := []
				for h in trio:
					names.append(g.card(h).nombre)
				g._log("Matrimonio arreglado: %s descarta a %s." % [pl.name, ", ".join(names)])
				var cap: int = mini(pl.hand.size(), MARRIAGE_CAP - pl.honor)
				if cap <= 0:
					return
				var cb2 := func(sel2):
					if sel2.is_empty():
						return
					_discard_selected(g, p, sel2)
					pl.honor += sel2.size()
					g._log("Matrimonio arreglado: %s genera %d de Honor (tiene %d)." % [pl.name, sel2.size(), pl.honor])
				g.request_choice(p, "Matrimonio arreglado: ¿cuántas cartas de tu mano descartas? (generas 1 de Honor por carta; tu Honor total no puede pasar de %d, hoy tienes %d)" % [MARRIAGE_CAP, pl.honor],
					_hand_opts(g, p), range(0, cap + 1), cb2, "give", func(): return [])
			g.request_choice(p, "Matrimonio arreglado: elige los 3 héroes de distinto clan que descartarás", opts, [1], cb, "take")
		97:  # Lealtad: nombras un clan; si los próximos 3 héroes que bajas son de ese clan, +3 de Honor
			var cb := func(sel):
				pl.lealtad.append({"clan": sel[0].value, "left": 3})
				g._log("Lealtad: %s nombra al clan %s (los próximos 3 héroes que baje deben ser de ese clan)." % [pl.name, sel[0].value])
			g.request_choice(p, "Lealtad: nombra un clan. Si los próximos 3 héroes que bajas son de ese clan, generas 3 de Honor", _clan_opts(g), [1], cb, "clan_help",
				func(): return _ai_lealtad(g, p))
		83:  # El Tokaido: +1 Honor por cada carta que falte en el castillo
			pl.honor += Game.CASTLE_SIZE - pl.castle.size()
		84:  # Espía: 1 carta por guerrero rival, 2 por daimyo
			var n := 0
			for c in g.heroes_in_play(1 - p):
				n += 2 if g.card(c).categoria == "Daimyo" else 1
			g.draw(p, n)
		88:  # Reparadores: la próxima carta del mazo va al castillo (x2 con Yoshiteru; máx. 7)
			for k in _yoshiteru(g, p):
				if not pl.deck.is_empty() and pl.castle.size() < Game.CASTLE_SIZE:
					pl.castle.append(pl.deck.pop_back())
		91:  # Ninjutsu: roba 2 y +1 dado en la próxima batalla de un Ninja
			g.draw(p, 2)
			pl.next_ninja = 1
		95:  # Nobleza de espíritu: roba 5, el turno termina
			g.draw(p, 5)
		99:  # Reflexión y justicia: eliges hasta 3 héroes del pozo para tu mano
			var heroes := _ids_where(g, pl.discard, func(c): return g.is_hero(c))
			var cb := func(sel):
				_take_to_hand(g, p, sel, "Reflexión y justicia")
			g.request_choice(p, "Reflexión y justicia: elige %d héroe(s) del pozo para tu mano" % mini(3, heroes.size()), _opts(g, heroes), [mini(3, heroes.size())], cb, "take")

# ------------------------------------------------------------------ guerreros: modificadores de dados

## Modificadores al duelo de dados del guerrero activo de p.
## dice: dados extra. points: puntos fijos al total. set_min: mínimo de dados (reemplazo "en vez de tirar...").
static func battle_mods(g: Game, p: int, is_att: bool) -> Dictionary:
	var m := {"dice": 0, "points": 0, "set_min": 0}
	var pl = g.players[p]
	var op = g.players[1 - p]
	var id: int = pl.active
	if g.battle.get("plain", false):    # Rectitud Zen: sin modificadores
		return m
	var c: Dictionary = g.card(id)
	_mods_for(g, p, id, is_att, m)
	if id == 9:    # Kotaro: suma además los efectos de los Ninja que copia
		for cid in pl.kcopy:
			_mods_for(g, p, cid, is_att, m)
	if id != 0:
		if g.clan_of(p, id) == "Date" and 60 in g.heroes_in_play(p):
			m.dice += 2 if id == 48 else 1   # Terumune (48) dobla el efecto de su Daimyo
		if c.clan == "Ninja" and 61 in g.heroes_in_play(p):   # Watanabe Tenzo: todos tus Ninja +1 dado en duelo
			m.dice += 1
		if c.clan == "Ninja" and pl.next_ninja > 0:
			m.dice += 1
	return m

## Modificadores propios de la carta `id` (también se usan cuando Kotaro copia a otro Ninja).
static func _mods_for(g: Game, p: int, id: int, is_att: bool, m: Dictionary) -> void:
	var pl = g.players[p]
	var op = g.players[1 - p]
	var oc: Dictionary = g.card(op.active) if op.active != 0 else {}
	match id:
		63:  # Terumoto (Mori): +1 dado por cada otro guerrero Mori en juego (máx. 2)
			var n := 0
			for h in g.heroes_in_play(p):
				if h != id and g.clan_of(p, h) == "Mori":
					n += 1
			m.dice += mini(n, 2)
		4:  # Sin Honor: solo y sin Honor
			if pl.passive.is_empty() and pl.honor == 0:
				m.dice += 1
		5:  # Mochizuke: sin Honor, +3 vs Daimyo
			if pl.honor == 0 and oc.get("categoria", "") == "Daimyo":
				m.dice += 3
		8:  # Tenzo: rival con más Honor
			if op.honor > pl.honor:
				m.dice += 1
		13:  # Terror 7 mares: +1 dado por guerrero de coste 1 sin clan (Ronin), máx. 4
			var n13 := 0
			for h in g.heroes_in_play(p):
				if h != id and g.card(h).costo_honor == 1 and g.card(h).clan == "Ronin":
					n13 += 1
			m.dice += mini(n13, 4)
		14:  # Tachibana: +3 vs Ninja
			if oc.get("clan", "") == "Ninja":
				m.dice += 3
		16:  # Sasaki Kojiro: atacando, 1 dado por carta que falte en tu castillo
			if is_att:
				m.set_min = Game.CASTLE_SIZE - pl.castle.size()
		17:  # Musashi: 1 dado por cada 2 de Honor
			m.dice += pl.honor / 2
		21:  # Nobutada: +1 dado si no tienes cartas boca abajo
			if pl.facedown.is_empty():
				m.dice += 1
		26:  # Hidetada: +3 vs Ronin
			if oc.get("clan", "") == "Ronin":
				m.dice += 3
		27:  # Honda: defendiendo, 1 dado por carta que falte en tu castillo
			if not is_att:
				m.set_min = Game.CASTLE_SIZE - pl.castle.size()
		28:  # Kosaka Masanobu: +1 por daimyo en juego (máx. 4)
			var n := 0
			for q in 2:
				for h in g.heroes_in_play(q):
					if g.card(h).categoria == "Daimyo":
						n += 1
			m.dice += mini(n, 4)
		30:  # Anayama Baitetsu: +1 dado si tienes más cartas en tu castillo que el rival (texto cortado: por confirmar)
			if pl.castle.size() > op.castle.size():
				m.dice += 1
		32:  # Kakizaki Kageie: +1 dado si hay otro guerrero Uesugi o Ikko Ikki en juego
			for h in g.heroes_in_play(p):
				if h != id and (g.clan_of(p, h) == "Uesugi" or g.clan_of(p, h) == "Ikko Ikki"):
					m.dice += 1
					break
		37:  # Kikawa: rival con más cartas en mano
			if op.hand.size() > pl.hand.size():
				m.dice += 1
		39:  # Kobayakawa: si jugaste al menos 3 Bushi este turno, +1 dado
			if g.bushi_count[p] >= 3:
				m.dice += 1
		42:  # Shimazu: atacando, 1 dado por carta en tu castillo
			if is_att:
				m.set_min = pl.castle.size()
		43:  # Ujizane: +2 puntos
			m.points += 2
		46:  # Munezane: castillo con 7 cartas
			if pl.castle.size() == Game.CASTLE_SIZE:
				m.dice += 1
		54:  # Motoyama Boku: 1 dado por carta en la mano del rival (máx. 7)
			m.set_min = mini(7, op.hand.size())
		65:  # Yoshihiro: +2 vs guerreros
			if oc.get("categoria", "") == "Guerrero":
				m.dice += 2

## Se llama cuando el guerrero activo de `killer` derrota a `victim_id`.
static func on_kill(g: Game, killer: int, victim_id: int) -> void:
	var kp = g.players[killer]
	if kp.active == 1 and kp.passive.is_empty():   # Saizo: solo y mata a un oponente -> descarte AL AZAR
		var vp = g.players[1 - killer]
		if not vp.hand.is_empty():
			var c: int = vp.hand.pop_at(g.rng.randi() % vp.hand.size())
			vp.discard.append(c)
			g._log("Saizo (solo) mata y hace descartar al azar %s a %s." % [g.card(c).nombre, vp.name])
	if kp.active == 41 and g.is_hero(victim_id):  # Toshihisa: +1 Honor
		kp.honor += 1

# ------------------------------------------------------------------ guerreros: efectos de batalla (B)

## Pasos (efectos) que se ejecutan antes de tirar los dados, para el guerrero activo de p.
static func battle_start_steps(g: Game, p: int, is_att: bool) -> Array:
	var steps := []
	var pl = g.players[p]
	_start_for(g, p, is_att, pl.active, steps)
	if pl.active == 9 and is_att:    # Kotaro: primero elige a quién copia (los pasos copiados se agregan al elegir)
		steps.push_front(kotaro_step(g, p, true))
	return steps

## Pasos de inicio de batalla de la carta `id` (también los usa Kotaro al copiar).
static func _start_for(g: Game, p: int, is_att: bool, id: int, steps: Array) -> void:
	var pl = g.players[p]
	var op = g.players[1 - p]
	match id:
		1:  # Saizo: el descarte ocurre al matar (ver on_kill)
			pass
		6:  # Kosaka: descarta 2; si ambas son Ninja, +5 puntos
			var st := func():
				if pl.hand.size() < 2:
					return
				var cb := func(sel):
					var all_ninja := true
					for o in sel:
						if g.card(o.card).clan != "Ninja":
							all_ninja = false
					_discard_selected(g, p, sel)
					if all_ninja:
						pl.bb_points += 5
						g._log("Kosaka: ¡ambas cartas eran Ninja! +5 puntos.")
				g.request_choice(p, "Kosaka: descarta 2 cartas de tu mano (si ambas son Ninja, +5 puntos a tu tirada)", _hand_opts(g, p), [2], cb, "give")
			steps.append(st)
		15:  # Sanada Yukimura: al atacar, puede descartar 2 cartas para sumar 4 dados
			if (not is_att) and op.active != 0:   # Sanada: al RECIBIR un ataque
				var st := func():
					if pl.hand.size() < 2:
						return
					var cb := func(sel):
						if sel.is_empty():
							return
						_discard_selected(g, p, sel)
						pl.bb_dice += 4
						g._log("Sanada Yukimura suma 4 dados.")
					g.request_choice(p, "Sanada Yukimura: ¿descartas 2 cartas para sumar 4 dados? (elige 2, o ninguna para no hacerlo)", _hand_opts(g, p), [0, 2], cb, "give")
				steps.append(st)
		19:  # Nobutaka: puedes robar 1 carta por cada carta que tengas boca abajo
			var st := func():
				var n: int = pl.facedown.size()
				if n == 0:
					return
				var cb := func(sel):
					if sel[0].value:
						g._log("Nobutaka: %s roba %d carta(s) por sus cartas boca abajo." % [pl.name, n])
						g.draw(p, n)
				g.request_choice(p, "Nobutaka: tienes %d carta(s) boca abajo. ¿Robas %d?" % [n, n],
					[{"label": "Sí, robar %d" % n, "value": true}, {"label": "No", "value": false}], [1], cb, "yesno")
			steps.append(st)
		29:  # Katsuyori: elige un número de 1 a 6
			var st := func():
				var nums := []
				for n in range(1, 7):
					nums.append({"label": str(n), "value": n})
				var cb := func(sel):
					pl.pick_num = sel[0].value
					g._log("Katsuyori elige el número %d." % pl.pick_num)
				g.request_choice(p, "Katsuyori: elige un número del 1 al 6 (si sale en tus dados, +7 al total)", nums, [1], cb, "number")
			steps.append(st)
		53:  # Kunichika: tira 1 dado; el resultado es la cantidad de dados de su duelo
			var st := func():
				var r: int = g.rng.randi_range(1, 6)
				pl.bb_set = r
				g._log("Kunichika tira un dado: %d. Tirará %d dado(s) en el duelo." % [r, r])
			steps.append(st)

## Kotaro (9): al atacar copia el efecto de batalla de hasta 2 Ninja que tengas en juego.
## duel=false: ataque al castillo sin defensor (solo importa Sasuke, que hace robar 2).
static func kotaro_step(g: Game, p: int, duel: bool) -> Callable:
	return func():
		var pl = g.players[p]
		if pl.active != 9:
			return
		var inplay: Array = pl.hand   # la imagen: 2 Ninja distintos DE LA MANO
		var cand := []
		for cid in ([8, 5, 4, 6, 1, 2] if duel else [2]):
			if cid in inplay and not (cid in cand):
				cand.append(cid)
		if cand.is_empty():
			g._log("Kotaro no tiene ningún Ninja %s en tu mano para copiar." % ("con efecto de batalla" if duel else "con efecto contra el castillo (solo Sasuke) "))
			return
		var cb := func(sel):
			pl.kcopy = []
			var names := []
			for o in sel:
				pl.kcopy.append(o.card)
				names.append(g.card(o.card).nombre)
			if names.is_empty():
				g._log("Kotaro no copia a nadie.")
				return
			g._log("Kotaro copia el efecto de: %s." % ", ".join(names))
			if duel:
				var extra := []
				for cid in pl.kcopy:
					_start_for(g, p, true, cid, extra)
				g._steps = extra + g._steps
		g.request_choice(p, "Kotaro: elige hasta 2 Ninja distintos de tu mano para copiar su efecto de batalla", _opts(g, cand), [0, 1, 2], cb, "take",
			func(): return range(mini(2, cand.size())))

## Pasos tras el duelo y la muerte del perdedor. info: {ids, rolls, totals, winner, loser} (indexados por jugador).
static func post_duel_steps(g: Game, info: Dictionary) -> Array:
	var steps := []
	for s in 2:
		var pl = g.players[s]
		var op = g.players[1 - s]
		match info.ids[s]:
			10:  # Matsu: si sale un 3 en un dado, roba 1
				if 3 in info.rolls[s]:
					var st := func():
						g._log("Matsu sacó un 3: roba 1 carta.")
						g.draw(s, 1)
					steps.append(st)
			24:  # Hideyori: si el resultado es 9 o más, roba 3
				if info.totals[s] >= 9:
					var st := func():
						g._log("Hideyori sacó %d: roba 3 cartas." % info.totals[s])
						g.draw(s, 3)
					steps.append(st)
			23:  # Miyoshi Hidetsugu: si gana, puede mirar la mano rival
				if info.winner == s:
					var st := func():
						g.request_choice(s, "Miyoshi Hidetsugu: así es la mano de %s" % op.name, _hand_opts(g, 1 - s), [0], func(_sel): pass, "info")
					steps.append(st)
			38:  # Motonari: si mata, puede buscar al Daimyo Mori en el mazo
				if info.winner == s:
					var st := func():
						var found := _ids_where(g, pl.deck, func(c): return g.card(c).categoria == "Daimyo" and g.card(c).clan == "Mori")
						var cb := func(sel):
							for o in sel:
								pl.deck.erase(o.card)
								pl.hand.append(o.card)
								g._log("Motonari busca a %s en el mazo." % g.card(o.card).nombre)
							g._sfx("barajar")
							DeckBuilder.shuffle(pl.deck, g.rng)
						g.request_choice(s, "Motonari: ¿buscas al Daimyo del clan Mori en tu mazo?", _opts(g, found), [0, 1], cb, "take")
					steps.append(st)
	return steps

## Pasos que se disparan cuando alguien juega una carta Bushi.
static func bushi_played_steps(g: Game, p: int, id: int) -> Array:
	var steps := []
	if g.phase != "WINDOW":
		return steps
	for s in 2:
		if g.players[s].active == 31:  # Kage Katsu: el rival de su dueño descarta 1 carta (la elige él)
			var victim := p   # quien usa la carta Bushi descarta de su propia mano
			var st := func():
				var cb := func(sel):
					_discard_selected(g, victim, sel)
				g.request_choice(victim, "Kage Katsu: usaste una carta Bushi, descarta 1 carta de tu mano", _hand_opts(g, victim), [1], cb, "give")
			steps.append(st)
	return steps

# ------------------------------------------------------------------ guerreros: al entrar en juego (C)

## Costo de Honor al bajar un guerrero.
static func entry_cost(g: Game, p: int, id: int) -> int:
	if id == 47 and 60 in g.heroes_in_play(p):  # Tadamune: gratis si su Daimyo (Date) está en juego
		return 0
	if id == 52:  # Morichika: gratis si tienes un Ronin con "Pirata" en su nombre
		for h in g.heroes_in_play(p):
			if g.card(h).clan == "Ronin" and "Pirata" in g.card(h).nombre:
				return 0
	var cost: int = g.card(id).costo_honor
	var mine: Array = g.heroes_in_play(p)
	if g.turn_player == p:
		if g.clan_of(p, id) == "Toyotomi":
			cost -= mine.count(22)           # Yogidomi (D): -1 al costo de tus guerreros Toyotomi durante tu turno
	if id == 57:
		cost -= mine.count(25)               # Sakai Tadatsugu: -1 al costo del Daimyo Tokugawa
	if g.turn_player == p and g.clan_of(p, id) == "Takeda":
		cost -= mine.count(58)               # Shingen (D): tus guerreros Takeda cuestan 1 menos en tu turno
	for t in g.cost_tax:                     # Yoshiharu: +1 al costo del clan nombrado
		if t.player == p and t.turn == g.turn_number and t.clan == g.clan_of(p, id):
			cost += 1
	return maxi(cost, 0)

## Se llama justo después de que un guerrero entra en juego desde la mano.
static func on_enter(g: Game, p: int, id: int) -> void:
	var pl = g.players[p]
	var op = g.players[1 - p]
	match id:
		3:  # Revancha: puedes recoger 1 ninja del pozo
			var ninjas := _ids_where(g, pl.discard, func(c): return g.card(c).clan == "Ninja")
			var cb := func(sel):
				_take_to_hand(g, p, sel, "Revancha")
			g.request_choice(p, "Revancha: ¿recoges un ninja del pozo a tu mano?", _opts(g, ninjas), [0, 1], cb, "take")
		7:  # Hattori Hanzo: con 3+ ninjas en el pozo, PUEDES robar 7
			var n := 0
			for c in pl.discard:
				if g.card(c).clan == "Ninja":
					n += 1
			if n >= 3:
				var cb := func(sel):
					if sel[0].value:
						var falta: int = 7 - pl.hand.size()
						g._log("Hattori Hanzo: %d ninjas en el pozo, roba hasta tener 7 cartas en la mano (%d)." % [n, maxi(falta, 0)])
						if falta > 0:
							g.draw(p, falta)
					else:
						g._log("Hattori Hanzo: decide no robar.")
				g.request_choice(p, "Hattori Hanzo: hay %d ninjas en tu pozo. ¿Robas hasta tener 7 cartas en la mano?" % n,
					[{"label": "Sí, robar hasta 7", "value": true}, {"label": "No", "value": false}], [1], cb, "yesno")
		20:  # Shibata Katsuie: dado; si sale par, puedes recoger un Bushi del pozo
			var r: int = g.rng.randi_range(1, 6)
			g._log("Shibata Katsuie tira un dado: %d." % r)
			if r % 2 == 0:
				var bushis := _ids_where(g, pl.discard, func(c): return g.card(c).categoria == "Accion")
				var cb := func(sel):
					_take_to_hand(g, p, sel, "Shibata Katsuie")
				g.request_choice(p, "Shibata Katsuie (salió %d, par): ¿recoges una carta Bushi del pozo?" % r, _opts(g, bushis), [0, 1], cb, "take")
		40:  # Yoshihisa: recoge 1 guerrero del pozo
			var heroes := _ids_where(g, pl.discard, func(c): return g.is_hero(c))
			var cb := func(sel):
				_take_to_hand(g, p, sel, "Yoshihisa")
			g.request_choice(p, "Yoshihisa: elige 1 guerrero del pozo para tu mano", _opts(g, heroes), [1], cb, "take")
		45:  # Yoshizane: 3 guerreros del pozo al final del mazo
			var heroes := _ids_where(g, pl.discard, func(c): return g.is_hero(c))
			var k := mini(3, heroes.size())
			var cb := func(sel):
				var names := []
				for o in sel:
					pl.discard.erase(o.card)
					pl.deck.push_front(o.card)  # el "tope" del mazo es el final del arreglo
					names.append(g.card(o.card).nombre)
				g._log("Yoshizane manda al fondo del mazo: %s." % ", ".join(names))
			g.request_choice(p, "Yoshizane: elige %d guerrero(s) del pozo para ponerlos al final de tu mazo" % k, _opts(g, heroes), [k], cb, "take")
		59:  # Kenshin: descarta 3, revuelve la mano en el mazo y roba 7
			var k := mini(3, pl.hand.size())
			var cb := func(sel):
				_discard_selected(g, p, sel)
				pl.deck.append_array(pl.hand)
				pl.hand.clear()
				g._sfx("barajar")
				DeckBuilder.shuffle(pl.deck, g.rng)
				g._log("Kenshin revuelve la mano en el mazo y roba 7.")
				g.draw(p, 7)
			g.request_choice(p, "Kenshin: elige %d carta(s) de tu mano para descartar (luego revuelves el resto en el mazo y robas 7)" % k, _hand_opts(g, p), [k], cb, "give")
		69:  # Akechi Mitsuhide: roba 2 del castillo para quitarle un Daimyo al rival
			var daimyos := _ids_where(g, g.heroes_in_play(1 - p), func(c): return g.card(c).categoria == "Daimyo")
			if daimyos.is_empty() or pl.castle.size() <= 2:
				g._log("Akechi Mitsuhide no puede traicionar (sin Daimyo rival o castillo muy frágil).")
				return
			var cb := func(sel):
				var target: int = sel[0].card
				g.castle_draw(p, 2)
				if g.phase == "OVER":
					return
				if op.active == target:
					op.active = 0
				else:
					op.passive.erase(target)
				if pl.passive.size() < Game.MAX_PASSIVE:   # «en guardia»: zona de guerreros pasivos
					pl.passive.append(target)
				else:
					pl.discard.append(target)
				g._log("¡Traición! %s pasa al bando de %s." % [g.card(target).nombre, pl.name])
			g.request_choice(p, "Akechi Mitsuhide: elige el Daimyo rival que pasará a tu bando (pagas 2 cartas de tu castillo)", _opts(g, daimyos), [1], cb, "take")

# ------------------------------------------------------------------ cartas boca abajo (trampas)

## Un héroe de p murió en duelo. `margin` = diferencia de puntos con la que perdió.
static func on_hero_died(g: Game, p: int, id: int, margin: int) -> void:
	var pl = g.players[p]
	for fd in pl.facedown.duplicate():
		match fd:
			96:  # Cortesía: recibes el coste de Honor del héroe caído
				pl.facedown.erase(96)
				pl.discard.append(96)
				var cost: int = g.card(id).costo_honor
				pl.honor += cost
				g._log("¡Se revela Cortesía! %s recibe %d de Honor por %s." % [pl.name, cost, g.card(id).nombre])
				g.toast("Cortesía se revela: %s recibe %d de Honor" % [pl.name, cost])
			98:  # Muerte Honorable: derrotado por más de 2 de diferencia
				if margin > 2:
					pl.facedown.erase(98)
					pl.discard.append(98)
					pl.honor += 3
					g._log("¡Se revela Muerte Honorable! %s recibe 3 de Honor (perdió por %d)." % [pl.name, margin])
					g.toast("Muerte Honorable se revela: %s recibe 3 de Honor" % pl.name)

static func _ai_dilema(g: Game, p: int) -> Array:
	var opts := _clan_opts(g)
	for h in g.heroes_in_play(p):
		var c: String = g.card(h).clan
		for i in opts.size():
			if opts[i].value == c:
				return [i]
	return [0]

# ------------------------------------------------------------------ Complejo Enryaku-Ji

static func temple_cap(g: Game, p: int) -> int:
	return 1 + (1 if 35 in g.heroes_in_play(p) else 0)   # Rennyo (35): +1 miembro

## Devuelve un héroe del templo a la zona de juego (o a la mano si no hay lugar).
static func _temple_return(g: Game, p: int, id: int) -> void:
	var pl = g.players[p]
	if pl.active == 0:
		pl.active = id
	elif pl.passive.size() < Game.MAX_PASSIVE:
		pl.passive.append(id)
	elif id == CardDB.TOKEN_ID:
		g.send_to_discard(p, id)
	else:
		pl.hand.append(id)
		g._log("%s no tiene lugar: %s vuelve a su mano." % [pl.name, g.card(id).nombre])

## Cierra el templo: los héroes vuelven (sin bono) y la carta va al pozo.
static func temple_close(g: Game, p: int, why: String) -> void:
	var pl = g.players[p]
	if pl.temple.is_empty():
		return
	var back: Array = pl.temple.heroes.duplicate()
	pl.temple = {}
	pl.discard.append(90)
	g._log("El Complejo Enryaku-Ji de %s %s." % [pl.name, why])
	for t in back:
		_temple_return(g, p, t.id)

## Si Rennyo se fue, los miembros que sobran vuelven a la mano.
static func temple_normalize(g: Game, p: int) -> void:
	var pl = g.players[p]
	if pl.temple.is_empty():
		return
	while pl.temple.heroes.size() > temple_cap(g, p):
		var t: Dictionary = pl.temple.heroes.pop_back()
		_temple_return(g, p, t.id)

static func _temple_progress(g: Game, p: int) -> void:
	var pl = g.players[p]
	if pl.temple.is_empty():
		return
	var sensei := false
	for t in pl.temple.heroes:
		if t.id == 36:
			sensei = true
	var stay := []
	var out := []
	for t in pl.temple.heroes:
		t.left -= 1
		if t.left <= 0:
			out.append(t.id)
		else:
			stay.append(t)
	pl.temple.heroes = stay
	for id in out:
		var bonus := 1
		var clan: String = g.card(id).clan
		if sensei and (clan == "Ikko Ikki" or clan == "Uesugi"):
			bonus = 2
		if id != CardDB.TOKEN_ID:
			pl.perm_atk[id] = pl.perm_atk.get(id, 0) + bonus
		g._log("%s sale del Complejo con +%d de ataque permanente." % [g.card(id).nombre, bonus])
		_temple_return(g, p, id)

# ------------------------------------------------------------------ habilidades activas (A) y efectos continuos (D)

## Multiplicador de Yoshiteru (D): duplica Reparadores, Ceremonia del té y El destino del clan.
static func _yoshiteru(g: Game, p: int) -> int:
	return 2 if 68 in g.heroes_in_play(p) else 1

## Clanes "de verdad" (sin Ninja ni Ronin, que son tipos) como opciones de decisión.
static func _clan_opts(g: Game) -> Array:
	var seen := {}
	for id in CardDB.cards:
		var c: Dictionary = CardDB.cards[id]
		if c.categoria != "Accion" and c.clan != "" and c.clan != "Ninja" and c.clan != "Ronin":
			seen[c.clan] = true
	var names: Array = seen.keys()
	names.sort()
	var out := []
	for n in names:
		out.append({"label": n, "value": n})
	return out

const ABILITY_TEXT := {
	61: "roba 1 carta extra (todos tus Ninja tiran 1 dado extra en duelo mientras esté en juego)",
	11: "mira las 3 cartas de arriba de tu mazo y ordénalas",
	12: "si está en tu pozo, paga su costo y vuelve a tu mano",
	18: "sin cartas en la mano, recoge un Ronin del pozo",
	49: "genera 1 de Honor (necesitas otro miembro del clan Ashikaga en juego)",
	50: "genera 2 de Honor (necesitas 2 miembros más del clan Ashikaga en juego)",
	51: "nombra un clan: sus cartas cuestan 1 Honor más en el próximo turno rival",
	55: "roba 3 cartas; luego puedes descartar 3 para generar 3 de Honor",
	57: "paga 1 de Honor para buscar una carta en tu mazo",
	62: "roba 1 carta por cada Ronin en juego (máx. 3) y genera 1 de Honor",
	64: "cambia 1 carta de tu mano por una carta de tu castillo",
	67: "paga 2 de Honor para recoger un guerrero Imagawa de tu pozo a tu mano",
	9001: "manda un héroe en juego al Complejo Enryaku-Ji (vuelve en 2 de tus turnos con +1 de ataque permanente; no ataca ni defiende)",
	9002: "descarta tu Complejo Enryaku-Ji (sus héroes vuelven a juego)",
	9003: "paga 5 de Honor para destruir el Complejo Enryaku-Ji del rival (sus héroes vuelven a su zona)",
}

static func ability_name(id: int) -> String:
	match id:
		9001: return "Enviar un héroe al Complejo"
		9002: return "Descartar tu Complejo"
		9003: return "Destruir el Complejo rival (5 Honor)"
	return CardDB.cards[id].nombre

static func _copies(g: Game, p: int, id: int) -> int:
	if id == 12:
		return g.players[p].discard.count(12)   # Pirata Wokou se usa desde el pozo
	return g.heroes_in_play(p).count(id)

static func _used(g: Game, p: int, id: int) -> int:
	return g.ability_uses[p].get(id, 0)

static func _mark_used(g: Game, p: int, id: int) -> void:
	g.ability_uses[p][id] = _used(g, p, id) + 1

static func _others_in_clan(g: Game, p: int, clan: String, except_id: int) -> int:
	var n := 0
	for h in g.heroes_in_play(p):
		if g.clan_of(p, h) == clan and h != except_id:
			n += 1
	return n

## ¿Puede el jugador p usar ahora la habilidad de la carta id?
static func ability_ready(g: Game, p: int, id: int) -> bool:
	if g.phase != "MAIN" or p != g.turn_player or not ABILITY_TEXT.has(id):
		return false
	var pl = g.players[p]
	match id:
		9001: return not pl.temple.is_empty() and pl.temple.heroes.size() < temple_cap(g, p) and not g.heroes_in_play(p).is_empty()
		9002: return not pl.temple.is_empty()
		9003: return not g.players[1 - p].temple.is_empty() and pl.honor >= 5
	if _used(g, p, id) >= _copies(g, p, id):
		return false
	match id:
		11: return pl.deck.size() >= 2
		61: return not pl.deck.is_empty()
		12: return pl.honor >= g.card(12).costo_honor
		18: return pl.hand.is_empty() and not _ids_where(g, pl.discard, func(c): return g.card(c).clan == "Ronin").is_empty()
		49: return _others_in_clan(g, p, "Ashikaga", 49) >= 1
		50: return _others_in_clan(g, p, "Ashikaga", 50) >= 2
		51: return true
		55: return pl.deck.size() >= 3
		57: return pl.honor >= 1 and not pl.deck.is_empty()
		62: return not pl.deck.is_empty()
		64: return not pl.hand.is_empty() and not pl.castle.is_empty()
		67: return pl.honor >= 2 and not _ids_where(g, pl.discard, func(c): return g.card(c).categoria == "Guerrero" and g.card(c).clan == "Imagawa").is_empty()
	return false

static func abilities(g: Game, p: int) -> Array:
	var out := []
	var ids: Array = []
	for id in g.heroes_in_play(p) + [12]:
		if not (id in ids):
			ids.append(id)
	ids.append_array([9001, 9002, 9003])
	for id in ids:
		if ability_ready(g, p, id):
			out.append({"id": id, "text": ABILITY_TEXT[id]})
	return out

static func use_ability(g: Game, p: int, id: int) -> void:
	var pl = g.players[p]
	var op = g.players[1 - p]
	match id:
		9001:  # enviar un héroe al templo
			var cb := func(sel):
				var h: int = sel[0].card
				if pl.active == h:
					pl.active = 0
				else:
					pl.passive.erase(h)
				pl.temple.heroes.append({"id": h, "left": TEMPLE_TURNS})
				g._log("%s entra al Complejo Enryaku-Ji (%d turnos)." % [g.card(h).nombre, TEMPLE_TURNS])
			g.request_choice(p, "Complejo Enryaku-Ji: elige el héroe que entra al templo (no podrá atacar ni defender; vuelve en %d de tus turnos con +1 de ataque permanente)" % TEMPLE_TURNS,
				_opts(g, g.heroes_in_play(p)), [1], cb, "temple", func(): return [_ai_temple_pick(g, p)])
		9002:
			var cb := func(sel):
				if sel[0].value:
					temple_close(g, p, "es descartado")
			g.request_choice(p, "¿Descartas tu Complejo Enryaku-Ji? Sus héroes vuelven a juego sin el bono.", [{"label": "Sí, descartar", "value": true}, {"label": "No", "value": false}], [1], cb, "yesno", func(): return [1])
		9003:
			var cb := func(sel):
				if sel[0].value:
					pl.honor -= 5
					g._log("%s paga 5 de Honor para destruir el Complejo de %s." % [pl.name, op.name])
					temple_close(g, 1 - p, "es destruido")
					temple_normalize(g, 1 - p)
			g.request_choice(p, "¿Pagas 5 de Honor para destruir el Complejo Enryaku-Ji de %s? (los personajes no se pierden)" % op.name, [{"label": "Sí, pagar 5", "value": true}, {"label": "No", "value": false}], [1], cb, "yesno")
		67:  # Yoshimoto: paga 2 de Honor y recoge un guerrero Imagawa del pozo
			var imagawa := _ids_where(g, pl.discard, func(c): return g.card(c).categoria == "Guerrero" and g.card(c).clan == "Imagawa")
			var cb := func(sel):
				if sel.is_empty():
					return
				_mark_used(g, p, id)
				pl.honor -= 2
				_take_to_hand(g, p, sel, "Yoshimoto (paga 2 de Honor)")
			g.request_choice(p, "Yoshimoto: elige un guerrero Imagawa del pozo para tu mano (pagas 2 de Honor), o ninguno", _opts(g, imagawa), [0, 1], cb, "take")
		61:  # Watanabe Tenzo: roba 1 carta extra
			_mark_used(g, p, id)
			g.draw(p, 1)
			g._log("Watanabe Tenzo: %s roba 1 carta extra." % pl.name)
		11:  # Toshie: ordena las 3 cartas de arriba del mazo
			_mark_used(g, p, id)
			var k := mini(3, pl.deck.size())
			var top := []
			for i in k:
				top.append(pl.deck[pl.deck.size() - 1 - i])   # índice 0 = la de más arriba
			var cb := func(sel):
				for i in k:
					pl.deck.pop_back()
				for i in range(sel.size() - 1, -1, -1):
					pl.deck.append(sel[i].card)           # la primera elegida queda arriba
				g._log("%s ordena las %d cartas de arriba de su mazo." % [pl.name, k])
			g.request_choice(p, "Toshie: elige las %d cartas en el orden en que quedarán (la PRIMERA que elijas quedará arriba del mazo)" % k, _opts(g, top), [k], cb, "order")
		12:  # Pirata Wokou: paga su costo y vuelve a la mano
			_mark_used(g, p, id)
			pl.honor -= g.card(12).costo_honor
			pl.discard.erase(12)
			pl.hand.append(12)
			g._log("%s paga %d de Honor: Pirata Wokou vuelve a su mano." % [pl.name, g.card(12).costo_honor])
		18:  # Akachi Morichige: sin cartas en mano, recoge un Ronin del pozo
			_mark_used(g, p, id)
			var ronin := _ids_where(g, pl.discard, func(c): return g.card(c).clan == "Ronin")
			var cb := func(sel):
				_take_to_hand(g, p, sel, "Akachi Morichige")
			g.request_choice(p, "Akachi Morichige: elige un Ronin del pozo para tu mano", _opts(g, ronin), [1], cb, "take")
		49, 50:  # Rukkaku Yoshikata / Yoshiaki: Honor por miembros del clan Ashikaga
			_mark_used(g, p, id)
			var n: int = 1 if id == 49 else 2
			pl.honor += n
			g._log("%s genera %d de Honor." % [g.card(id).nombre, n])
		51:  # Yoshiharu: el clan nombrado cuesta +1 de Honor en el próximo turno del rival
			_mark_used(g, p, id)
			var cb := func(sel):
				var clan: String = sel[0].value
				g.cost_tax.append({"player": 1 - p, "clan": clan, "turn": g.turn_number + 1})
				g._log("Yoshiharu: las cartas del clan %s cuestan +1 de Honor en el próximo turno de %s." % [clan, op.name])
			g.request_choice(p, "Yoshiharu: nombra un clan (sus cartas costarán 1 Honor más en el próximo turno del rival)", _clan_opts(g), [1], cb, "clan_hurt")
		55:  # Oda Nobunaga: roba 3; si lo haces, puedes descartar 3 para 3 de Honor
			var cb := func(sel):
				if not sel[0].value:
					return
				_mark_used(g, p, id)
				g.draw(p, 3)
				if g.phase == "OVER":
					return
				var cb2 := func(sel2):
					if sel2.is_empty():
						return
					_discard_selected(g, p, sel2)
					pl.honor += 3
					g._log("Oda Nobunaga convierte 3 cartas en 3 de Honor.")
				g.request_choice(p, "Oda Nobunaga: ¿descartas 3 cartas para generar 3 de Honor? (elige 3, o ninguna)", _hand_opts(g, p), [0, 3], cb2, "give")
			g.request_choice(p, "Oda Nobunaga: ¿robas 3 cartas?", [{"label": "Sí, robar 3", "value": true}, {"label": "No", "value": false}], [1], cb, "yesno")
		57:  # Ieyasu: paga 1 de Honor para buscar una carta
			var ids: Array = []
			for c in pl.deck:
				if not (c in ids):
					ids.append(c)
			var cb := func(sel):
				if sel.is_empty():
					return
				_mark_used(g, p, id)
				pl.honor -= 1
				pl.deck.erase(sel[0].card)
				pl.hand.append(sel[0].card)
				g._sfx("barajar")
				DeckBuilder.shuffle(pl.deck, g.rng)
				g._log("Ieyasu: %s paga 1 de Honor y busca a %s en su mazo." % [pl.name, g.card(sel[0].card).nombre])
			g.request_choice(p, "Ieyasu: elige una carta de tu mazo para tu mano (pagas 1 de Honor), o ninguna", _opts(g, ids), [0, 1], cb, "take")
		62:  # Mitsunari: 1 carta por cada Ronin en juego (máx. 3) y 1 de Honor
			_mark_used(g, p, id)
			var n := mini(3, _count_clan(g, p, "Ronin"))
			g._log("Mitsunari: %d Ronin en juego, %s roba %d y genera 1 de Honor." % [_count_clan(g, p, "Ronin"), pl.name, n])
			g.draw(p, n)
			pl.honor += 1
		64:  # Motochika: cambia 1 carta de la mano por una del castillo
			var cb := func(sel):
				if sel.is_empty():
					return
				var from_hand: int = sel[0].card
				var cb2 := func(sel2):
					_mark_used(g, p, id)
					var from_castle: int = sel2[0].card
					pl.hand.erase(from_hand)
					pl.castle.erase(from_castle)
					pl.castle.append(from_hand)
					pl.hand.append(from_castle)
					g._log("Motochika: %s cambia %s de su mano por una carta de su castillo." % [pl.name, g.card(from_hand).nombre])
				g.request_choice(p, "Motochika: tus cartas del castillo están a la vista. Elige cuál pasa a tu mano", _opts(g, pl.castle), [1], cb2, "take")
			g.request_choice(p, "Motochika: elige la carta de tu mano que irá al castillo (o ninguna)", _hand_opts(g, p), [0, 1], cb, "give")

## IA: qué héroe manda al templo (Kenyo si puede; si no, un pasivo; el activo solo si no queda otro).
static func _ai_temple_pick(g: Game, p: int) -> int:
	var heroes: Array = g.heroes_in_play(p)
	var best := 0
	var best_s := -999
	for i in heroes.size():
		var h: int = heroes[i]
		var sc: int = g.card(h).ataque
		if h == 66:
			sc += 50
		if h == g.players[p].active:
			sc -= 20
		if sc > best_s:
			best_s = sc
			best = i
	return best

## Al terminar el turno de p (antes de pasar al rival).
static func on_turn_end(g: Game, p: int) -> void:
	var pl = g.players[p]
	var kenyo_in_temple := false
	if not pl.temple.is_empty():
		for t in pl.temple.heroes:
			if t.id == 66:
				kenyo_in_temple = true
	if (pl.active == 66 and not g.attacked_this_turn) or kenyo_in_temple:   # Kenyo: no atacó o está en el templo -> +3 de Honor
		pl.honor += 3
		g._log("Kenyo %s: %s suma 3 de Honor." % ["está en el Complejo" if kenyo_in_temple else "no atacó este turno", pl.name])
	_temple_progress(g, p)

# ------------------------------------------------------------------ Hidetoshi (56): modifica el resultado de un dado

## Pasos tras tirar los dados y antes de decidir el ganador del duelo.
static func post_roll_steps(g: Game) -> Array:
	var steps := []
	var s: int = g.turn_player          # tipo A: solo en el turno de su dueño
	if not g.battle.has("res") or not (56 in g.heroes_in_play(s)):
		return steps
	if _used(g, s, 56) >= _copies(g, s, 56):
		return steps
	steps.append(func(): _hidetoshi(g, s))
	return steps

## Mejor jugada de la IA: [usar?, índice del dado, valor]. Los dados se listan primero los del dueño y luego los del rival.
static func _hidetoshi_plan(g: Game, s: int) -> Dictionary:
	var mine: Dictionary = g.battle.res[s]
	var opp: Dictionary = g.battle.res[1 - s]
	var best_gain := -1
	var best_idx := 0
	var best_val := 6
	for i in mine.rolls.size():
		if 6 - mine.rolls[i] > best_gain:
			best_gain = 6 - mine.rolls[i]
			best_idx = i
			best_val = 6
	for i in opp.rolls.size():
		if opp.rolls[i] - 1 > best_gain:
			best_gain = opp.rolls[i] - 1
			best_idx = mine.rolls.size() + i
			best_val = 1
	var diff: int = mine.total - opp.total
	return {"use": diff <= 0 and best_gain + diff > 0, "idx": best_idx, "val": best_val}

static func _hidetoshi(g: Game, s: int) -> void:
	var plan := _hidetoshi_plan(g, s)
	var res: Array = g.battle.res
	var mine: Dictionary = res[s]
	var opp: Dictionary = res[1 - s]
	var cb := func(sel):
		if not sel[0].value:
			return
		var dice := []
		for who in [s, 1 - s]:
			for i in res[who].rolls.size():
				dice.append({"label": "Tú" if who == s else "Rival", "die": res[who].rolls[i], "who": who, "i": i})
		var cb2 := func(sel2):
			var o: Dictionary = sel2[0]
			var vals := []
			for v in range(1, 7):
				vals.append({"label": "Poner %d" % v, "die": v, "value": v})
			var cb3 := func(sel3):
				_mark_used(g, s, 56)
				var r: Dictionary = g.battle.res[o.who]
				var oldv: int = r.rolls[o.i]
				var newv: int = sel3[0].value
				r.rolls[o.i] = newv
				r.total += newv - oldv
				g._log("Hidetoshi cambia un dado de %s: %d → %d (total %d)." % [g.players[o.who].name, oldv, newv, r.total])
			g.request_choice(s, "Hidetoshi: ¿qué valor pones en ese dado?", vals, [1], cb3, "dievalue", func(): return [plan.val - 1])
		g.request_choice(s, "Hidetoshi: elige el dado cuyo resultado quieres cambiar", dice, [1], cb2, "die", func(): return [plan.idx])
	var yn := [{"label": "Sí, modificar un dado", "value": true}, {"label": "No", "value": false}]
	g.request_choice(s, "Hidetoshi (una vez por turno): ¿modificas el resultado de un dado?\nTus dados: %s = %d   ·   Rival: %s = %d" % [str(mine.rolls), mine.total, str(opp.rolls), opp.total],
		yn, [1], cb, "yesno", func(): return [0 if plan.use else 1])
