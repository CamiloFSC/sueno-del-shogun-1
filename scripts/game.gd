class_name Game
extends RefCounted
## Motor de reglas (sin interfaz). Una UI o una IA solo llama a los métodos públicos.
## Fases: MAIN, DEFENDER_CHOICE, WINDOW, DISCARD, CHOICE (decisión de un efecto), OVER

signal changed

const HAND_LIMIT := 7
const CASTLE_SIZE := 7
const HONOR_MAX := 7             # tope de Honor de un jugador
const START_HAND := 7
const MAX_PASSIVE := 3

var players: Array = []
var turn_player := 0
var phase := "MAIN"
var winner := -1
var turn_number := 0
var warrior_played := false
var swapped_this_turn := false   # regla: una vez por turno, un pasivo toma el rol activo
var battle: Dictionary = {}
var log_lines: Array = []
var rng := RandomNumberGenerator.new()
var pending: Dictionary = {}     # decisión abierta por un efecto (fase CHOICE)
var pending_id := 0              # sube con cada decisión nueva (la UI lo usa para reiniciar la selección)
var bushi_count := [0, 0]        # Bushi jugados en este turno, por jugador
var _resume_phase := "MAIN"
var _steps: Array = []           # pasos de efectos pendientes (cada uno puede abrir una decisión)
var _done: Callable = Callable()
var ability_uses := [{}, {}]     # habilidades "una vez por turno" ya usadas este turno (id de carta -> veces)
var attacked_this_turn := false
var cost_tax: Array = []         # impuestos de Honor temporales (Yoshiharu): {player, clan, turn}
var duel_id := 0                # sube en cada duelo; la UI lo usa para animar
var last_duel: Dictionary = {}   # resultado del último duelo de dados (para la interfaz)
var first_player := -1           # -1 = al azar (el tutorial fuerza 0 = el jugador)
var ai_level := 1                # dificultad de la IA rival (jugador 1): 0 Fácil .. 3 Pesadilla (hace trampa)
var sfx_enabled := false         # la interfaz lo activa para recibir avisos de sonido
var sfx: Array = []              # sonidos pendientes: "dados", "espadas", "barajar", "robar", "descartar"
var toasts: Array = []           # mensajes emergentes pendientes (efectos giratorios revelados, etc.)
var bushi_ctx := {}              # contexto de la carta Bushi en curso (para la escena en primer plano)
var moves: Array = []            # movimientos de cartas para animar: {k: deck_hand|castle_hand|field_discard|hand_discard, p, id}

# ---------------------------------------------------------------- avisos para la interfaz

func _sfx(name: String) -> void:
	if sfx_enabled:
		sfx.append(name)

func _fx(kind: String, p: int, id: int = 0) -> void:
	if sfx_enabled:
		moves.append({"k": kind, "p": p, "id": id})
		if moves.size() > 40:
			moves.pop_front()

func toast(text: String) -> void:
	toasts.append(text)
	if toasts.size() > 6:
		toasts.pop_front()

## Rendirse (Harakiri): el jugador p pierde la partida.
func surrender(p: int) -> bool:
	if phase == "OVER":
		return false
	_lose(p, "se rindió con Honor (Harakiri)")
	changed.emit()
	return true

# ---------------------------------------------------------------- preparación

func setup(deck_a: Array, deck_b: Array, seed_value: int = 0, names: Array = ["Jugador 1", "Jugador 2"]) -> void:
	rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	players = [_new_player(names[0], deck_a), _new_player(names[1], deck_b)]
	for p in 2:
		DeckBuilder.shuffle(players[p].deck, rng)
		for i in START_HAND:
			players[p].hand.append(players[p].deck.pop_back())
		for i in CASTLE_SIZE:
			players[p].castle.append(players[p].deck.pop_back())
	turn_player = first_player if first_player >= 0 else rng.randi() % 2
	_sfx("barajar")
	_log("Empieza %s." % players[turn_player].name)
	_start_turn()

func _new_player(pname: String, deck: Array) -> Dictionary:
	return {"name": pname, "deck": deck.duplicate(), "hand": [], "castle": [], "discard": [],
		"active": 0, "passive": [], "honor": 0, "mult": 1, "next_ninja": 0,
		"bb_dice": 0, "bb_points": 0, "bb_set": 0, "pick_num": 0, "lealtad": [],
		"six_next": 0, "kcopy": [], "facedown": [], "shadow": [], "perm_atk": {}, "temple": {}, "clan_flag": {}}

# ---------------------------------------------------------------- consultas

func card(id: int) -> Dictionary:
	return CardDB.cards[id]

func is_hero(id: int) -> bool:
	return card(id).categoria != "Accion"

func is_giratorio(id: int) -> bool:
	return card(id).get("giratorio", "") == "si" or id in Effects.FD_PLAY

## Clan efectivo de una carta de p (Dilema del cucu cambia el clan de sus héroes; Ninja y Ronin no).
func clan_of(p: int, id: int) -> String:
	var c: String = card(id).clan
	var f: Dictionary = players[p].clan_flag
	if not f.is_empty() and c != "Ninja" and c != "Ronin" and is_hero(id) and (Effects.DILEMA_PERMANENT or f.turn == turn_number):
		return f.clan
	return c

## Manda un héroe al pozo. Las fichas de Castillo de montaña revelan la carta que las respalda.
func send_to_discard(p: int, id: int) -> void:
	var pl = players[p]
	if id == CardDB.TOKEN_ID:
		if not pl.shadow.is_empty():
			var real: int = pl.shadow.pop_front()
			pl.discard.append(real)
			_log("La ficha de %s era %s (va al pozo boca arriba)." % [pl.name, card(real).nombre])
		return
	pl.discard.append(id)
	if not (id in heroes_in_play(p)):
		pl.perm_atk.erase(id)

## Total de cartas de un jugador en todas las zonas (para pruebas: debe sumar 100 entre ambos).
func card_total(p: int) -> int:
	var pl = players[p]
	var n: int = pl.deck.size() + pl.hand.size() + pl.castle.size() + pl.discard.size() + pl.facedown.size() + pl.shadow.size()
	for h in heroes_in_play(p):
		if h != CardDB.TOKEN_ID:
			n += 1
	if not pl.temple.is_empty():
		n += 1
		for t in pl.temple.heroes:
			if t.id != CardDB.TOKEN_ID:
				n += 1
	return n

func actor() -> int:
	match phase:
		"DEFENDER_CHOICE": return 1 - turn_player
		"WINDOW": return battle.priority
		"CHOICE": return pending.player
		_: return turn_player

func heroes_in_play(p: int) -> Array:
	var pl = players[p]
	var out := []
	if pl.active != 0:
		out.append(pl.active)
	out.append_array(pl.passive)
	return out

## Costo real de Honor para bajar un guerrero (algunos efectos lo reducen).
func entry_cost(p: int, id: int) -> int:
	return Effects.entry_cost(self, p, id)

func can_play_warrior(p: int, id: int) -> bool:
	var pl = players[p]
	if phase != "MAIN" or p != turn_player or not is_hero(id):   # sin tope por turno: solo el límite del campo (1 activo + 3 pasivos)
		return false
	if pl.honor < entry_cost(p, id):
		return false
	return pl.active == 0 or pl.passive.size() < MAX_PASSIVE

## Dados que tira el guerrero activo de p y puntos fijos que se suman al total.
func dice_for(p: int, is_attacker: bool) -> Dictionary:
	var pl = players[p]
	if pl.active == 0:
		return {"n": 0, "points": 0}
	var m: Dictionary = Effects.battle_mods(self, p, is_attacker)
	var plain: bool = battle.get("plain", false)
	var n: int = _raw_dice(p, m, plain)
	var q: int = 1 - p
	if players[q].active == 44 and not plain:   # Sessai Choro: el rival tira 1 dado menos
		n -= 1
	if pl.active == 44 and not plain and players[q].active != 0:
		# Sessai Choro: tira tantos dados como el rival (ya con su dado menos)
		var mq: Dictionary = Effects.battle_mods(self, q, not is_attacker)
		n = clampi(_raw_dice(q, mq, plain) - 1, 1, 30)
	return {"n": clampi(n, 1, 30), "points": m.points + pl.bb_points}

func _raw_dice(p: int, m: Dictionary, plain: bool) -> int:
	var pl = players[p]
	var base: int = (pl.bb_set if pl.bb_set > 0 else card(pl.active).ataque) + (0 if plain else pl.perm_atk.get(pl.active, 0))
	var n: int = max(base, m.set_min) + m.dice + pl.bb_dice
	return n * pl.mult

func card_value(id: int) -> int:
	var c = card(id)
	if c.categoria == "Accion":
		return 3 if Effects.is_implemented_action(id) else -1
	return c.ataque

# ---------------------------------------------------------------- acciones del jugador

func play_warrior(hand_index: int) -> bool:
	var p := actor()
	var pl = players[p]
	if phase != "MAIN" or hand_index < 0 or hand_index >= pl.hand.size():
		return false
	var id: int = pl.hand[hand_index]
	if not can_play_warrior(p, id):
		return false
	var cost := entry_cost(p, id)
	pl.hand.remove_at(hand_index)
	pl.honor -= cost
	warrior_played = true
	if pl.active == 0:
		pl.active = id
	else:
		pl.passive.append(id)
	_log("%s baja a %s (coste %d)." % [pl.name, card(id).nombre, cost])
	Effects.hero_entered(self, p, id)
	run_steps([func(): Effects.on_enter(self, p, id)], Callable())
	changed.emit()
	return true

func play_action(hand_index: int) -> bool:
	var p := actor()
	var pl = players[p]
	if phase != "MAIN" and phase != "WINDOW":
		return false
	if hand_index < 0 or hand_index >= pl.hand.size():
		return false
	var id: int = pl.hand[hand_index]
	if card(id).categoria != "Accion" or not Effects.can_play(self, p, id):
		return false
	pl.hand.remove_at(hand_index)
	bushi_count[p] += 1
	if is_giratorio(id):
		pl.facedown.append(id)
		_log("%s coloca una carta boca abajo." % pl.name)
		changed.emit()
		return true
	if not Effects.stays_in_play(id):
		pl.discard.append(id)
		_fx("hand_discard", p, id)
	_log("%s juega %s." % [pl.name, card(id).nombre])
	bushi_ctx = {"p": p, "id": id, "l0": log_lines.size(), "hand0": pl.hand.size(), "dice": []}
	_fx("bushi", p, id)
	run_steps([func(): Effects.apply(self, p, id)], func(): _finish_action(p, id))
	changed.emit()
	return true

## Juega una giratoria (72, 73, 81) que está boca abajo: se revela y hace su efecto.
func play_facedown(idx: int) -> bool:
	var p := actor()
	var pl = players[p]
	if phase != "MAIN" and phase != "WINDOW":
		return false
	if idx < 0 or idx >= pl.facedown.size():
		return false
	var id: int = pl.facedown[idx]
	if not (id in Effects.FD_PLAY) or not Effects.can_play_fd(self, p, id):
		return false
	pl.facedown.remove_at(idx)
	pl.discard.append(id)
	bushi_count[p] += 1
	_fx("hand_discard", p, id)
	_log("¡%s revela %s!" % [pl.name, card(id).nombre])
	toast("%s revela %s" % [pl.name, card(id).nombre])
	bushi_ctx = {"p": p, "id": id, "l0": log_lines.size(), "hand0": pl.hand.size(), "dice": []}
	_fx("bushi", p, id)
	run_steps([func(): Effects.apply(self, p, id)], func(): _finish_action(p, id))
	changed.emit()
	return true

## Dado lanzado por una carta Bushi (la escena en primer plano lo muestra rodando).
## Suma Honor sin pasar del máximo (7). Todo el Honor que se gana pasa por aquí.
func gain_honor(pl: Dictionary, n: int) -> void:
	pl.honor = clampi(pl.honor + n, 0, HONOR_MAX)

func note_die(v: int) -> void:
	if not bushi_ctx.is_empty():
		bushi_ctx.dice.append(v)

func _finish_action(p: int, id: int) -> void:
	if not bushi_ctx.is_empty() and bushi_ctx.id == id and sfx_enabled:
		var lines: Array = log_lines.slice(bushi_ctx.l0)
		var drawn: int = maxi(0, players[p].hand.size() - bushi_ctx.hand0)
		moves.append({"k": "bushi_fx", "p": p, "id": id, "lines": lines, "dice": bushi_ctx.dice.duplicate(), "draw": drawn})
	bushi_ctx = {}
	if phase == "OVER":
		return
	run_steps(Effects.bushi_played_steps(self, p, id), func():
		if phase == "OVER":
			return
		if phase == "WINDOW":
			battle.passes = 0
			if battle.get("rolled", false):
				_skip_idle_priority()
		elif phase == "MAIN" and Effects.ends_turn(id):
			_end_turn_flow())

func declare_attack(target: String) -> bool:
	var p := turn_player
	var pl = players[p]
	var op = players[1 - p]
	if phase != "MAIN" or pl.active == 0:
		return false
	if target == "guerrero" and op.active == 0:
		return false
	if target != "guerrero" and target != "castillo":
		return false
	attacked_this_turn = true
	_sfx("espadas")
	battle = {"att": p, "target": target, "resisted": target == "guerrero", "passes": 0, "priority": p}
	if target == "castillo":
		if op.active != 0:
			phase = "DEFENDER_CHOICE"
			_log("%s ataca el castillo de %s con %s." % [pl.name, op.name, card(pl.active).nombre])
		else:
			_log("%s ataca el castillo de %s, que no tiene defensor." % [pl.name, op.name])
			_resolve_battle()
	else:
		phase = "WINDOW"
		_log("%s ataca a %s con %s." % [pl.name, card(op.active).nombre, card(pl.active).nombre])
	changed.emit()
	return true

func respond(resist: bool) -> bool:
	if phase != "DEFENDER_CHOICE":
		return false
	var d: int = 1 - turn_player
	if resist:
		battle.resisted = true
		phase = "WINDOW"
		_log("%s opone resistencia." % players[d].name)
	else:
		_log("%s deja pasar el ataque." % players[d].name)
		_resolve_battle()
	changed.emit()
	return true

func pass_priority() -> bool:
	if phase != "WINDOW":
		return false
	battle.passes += 1
	var rolled: bool = battle.get("rolled", false)
	if battle.passes >= 2:
		if rolled:
			battle.rolled = false
			_after_roll()
		else:
			_resolve_battle()
	else:
		battle.priority = 1 - battle.priority
		if rolled:
			_skip_idle_priority()
	changed.emit()
	return true

## Ventana después de lanzar los dados: quien no tiene una carta de dados jugable pasa solo.
func _skip_idle_priority() -> void:
	var guard := 0
	while phase == "WINDOW" and battle.get("rolled", false) and guard < 4:
		if Effects.has_post_roll_play(self, battle.priority):
			return
		guard += 1
		battle.passes += 1
		if battle.passes >= 2:
			battle.rolled = false
			_after_roll()
			return
		battle.priority = 1 - battle.priority

## Tras lanzar los dados (y efectos como Hideyoshi): si alguien puede jugar una carta de dados, se abre una ventana.
func _post_roll_window() -> void:
	if phase == "OVER":
		return
	if not (Effects.has_post_roll_play(self, battle.att) or Effects.has_post_roll_play(self, 1 - battle.att)):
		_after_roll()
		return
	battle["rolled"] = true
	battle["passes"] = 0
	battle["priority"] = battle.att
	phase = "WINDOW"
	_skip_idle_priority()

func end_turn() -> bool:
	if phase != "MAIN":
		return false
	_end_turn_flow()
	changed.emit()
	return true

func discard_card(hand_index: int) -> bool:
	if phase != "DISCARD":
		return false
	var pl = players[turn_player]
	if hand_index < 0 or hand_index >= pl.hand.size():
		return false
	var id: int = pl.hand[hand_index]
	pl.hand.remove_at(hand_index)
	pl.discard.append(id)
	_fx("hand_discard", turn_player, id)
	_sfx("descartar")
	_log("%s descarta %s." % [pl.name, card(id).nombre])
	if pl.hand.size() <= HAND_LIMIT:
		_finish_turn()
	changed.emit()
	return true

## Regla: una vez por turno, un guerrero de la reserva pasiva toma el rol activo.
## El activo actual (si lo hay) pasa a ocupar su lugar en la reserva. Solo en la fase principal, antes de atacar.
func can_swap_active(p: int) -> bool:
	return phase == "MAIN" and p == turn_player and not swapped_this_turn and not attacked_this_turn \
		and not players[p].passive.is_empty()

func swap_active(passive_index: int) -> bool:
	var p := turn_player
	if not can_swap_active(p) or passive_index < 0 or passive_index >= players[p].passive.size():
		return false
	var pl = players[p]
	var incoming: int = pl.passive[passive_index]
	var outgoing: int = pl.active
	pl.active = incoming
	if outgoing != 0:
		pl.passive[passive_index] = outgoing
	else:
		pl.passive.remove_at(passive_index)
	swapped_this_turn = true
	_sfx("robar")
	_log("%s pasa a la zona activa%s." % [card(incoming).nombre, (" y %s a la reserva pasiva" % card(outgoing).nombre) if outgoing != 0 else ""])
	changed.emit()
	return true

## Ventana de decisión para elegir qué pasivo toma el rol activo (jugador humano).
func open_swap() -> bool:
	if not can_swap_active(turn_player):
		return false
	var opts := []
	for i in players[turn_player].passive.size():
		var id: int = players[turn_player].passive[i]
		opts.append({"card": id, "label": card(id).nombre, "value": i})
	var cb := func(sel):
		if not sel.is_empty():
			swap_active(sel[0].value)
	request_choice(turn_player, "Cambio de rol (una vez por turno): elige qué guerrero pasivo toma el rol activo.", opts, [0, 1], cb, "take")
	changed.emit()
	return true

# ---------------------------------------------------------------- habilidades activas (efectos tipo A)

## Habilidades "una vez por turno" que el jugador de turno puede usar ahora: [{id, text}].
func available_abilities() -> Array:
	if phase != "MAIN":
		return []
	return Effects.abilities(self, turn_player)

## Usa la habilidad de la carta `id` (debe estar entre las disponibles).
func use_ability(id: int) -> bool:
	var p := turn_player
	if phase != "MAIN" or not Effects.ability_ready(self, p, id):
		return false
	run_steps([func(): Effects.use_ability(self, p, id)], Callable())
	changed.emit()
	return true

## Abre la ventana para elegir cuál habilidad usar (para el jugador humano).
func open_abilities() -> bool:
	var list := available_abilities()
	if list.is_empty():
		return false
	var opts := []
	var lines := []
	for a in list:
		var nm: String = Effects.ability_name(a.id)
		if a.id >= 9000:
			opts.append({"label": nm, "value": a.id})
		else:
			opts.append({"card": a.id, "label": nm})
		lines.append("• %s: %s" % [nm, a.text])
	var cb := func(sel):
		if not sel.is_empty():
			use_ability(sel[0].get("card", sel[0].get("value", 0)))
	request_choice(turn_player, "Habilidades (una vez por turno cada una). Elige cuál usar:\n" + "\n".join(lines), opts, [0, 1], cb, "take")
	changed.emit()
	return true

# ---------------------------------------------------------------- decisiones de efectos

## Abre una decisión para el jugador p.
## options: [{"label": String, "card": id (opcional)}]. valid: cantidades de opciones permitidas, ej. [1], [0, 1], [3].
## cb recibe las opciones elegidas. mode orienta a la IA: "take", "give", "number", "info".
## Si no hay nada que decidir (sin opciones, o la cantidad obligada es "todas"), se resuelve sin preguntar.
func request_choice(p: int, prompt: String, options: Array, valid: Array, cb: Callable, mode: String = "take", ai_pick: Callable = Callable()) -> void:
	var counts := []
	for c in valid:
		if c <= options.size():
			counts.append(c)
	if counts.is_empty():
		cb.call([])
		return
	counts.sort()
	if mode == "info":
		if options.is_empty():
			cb.call([])
			return
	elif counts == [0]:
		cb.call([])
		return
	elif counts.size() == 1 and counts[0] == options.size() and (mode != "order" or options.size() <= 1):
		cb.call(options.duplicate())
		return
	if phase != "CHOICE":
		_resume_phase = phase
	phase = "CHOICE"
	pending_id += 1
	pending = {"player": p, "prompt": prompt, "options": options, "valid": counts, "cb": cb, "mode": mode, "ai": ai_pick}

## Responde la decisión abierta con los índices de las opciones elegidas.
func choose(indices: Array) -> bool:
	if phase != "CHOICE" or pending.is_empty():
		return false
	var seen := {}
	for i in indices:
		if i < 0 or i >= pending.options.size() or seen.has(i):
			return false
		seen[i] = true
	if not (indices.size() in pending.valid):
		return false
	var sel := []
	for i in indices:
		sel.append(pending.options[i])
	var cb: Callable = pending.cb
	pending = {}
	phase = _resume_phase
	cb.call(sel)
	if pending.is_empty():
		_advance()
	changed.emit()
	return true

## Ejecuta pasos de efectos en orden; si uno abre una decisión, se detiene hasta que se responda.
func run_steps(steps: Array, done: Callable) -> void:
	_steps = steps.duplicate()
	_done = done
	_advance()

func _advance() -> void:
	while not _steps.is_empty():
		var s: Callable = _steps.pop_front()
		s.call()
		if phase == "OVER":
			_steps.clear()
			_done = Callable()
			return
		if phase == "CHOICE":
			return
	var d := _done
	_done = Callable()
	if d.is_valid():
		d.call()

# ---------------------------------------------------------------- utilidades de efectos

func draw(p: int, n: int) -> void:
	var pl = players[p]
	if n > 0:
		_sfx("robar")
	for i in n:
		if phase == "OVER":
			return
		if pl.deck.is_empty():
			_lose(p, "se quedó sin cartas en el mazo")
			return
		pl.hand.append(pl.deck.pop_back())
		_fx("deck_hand", p)

## "Robar del castillo": el castillo pasa cartas a la mano. Vacío = derrota.
func castle_draw(p: int, n: int) -> void:
	var pl = players[p]
	_sfx("robar")
	for i in n:
		if pl.castle.is_empty():
			break
		pl.hand.append(pl.castle.pop_back())
		_fx("castle_hand", p)
	_log("%s roba %d del castillo (quedan %d)." % [pl.name, n, pl.castle.size()])
	if pl.castle.is_empty():
		_lose(p, "su castillo se derrumbó")

func auto_discard(p: int, n: int) -> void:
	var pl = players[p]
	_sfx("descartar")
	for i in n:
		if pl.hand.is_empty():
			return
		var worst := 0
		for k in pl.hand.size():
			if card_value(pl.hand[k]) < card_value(pl.hand[worst]):
				worst = k
		pl.discard.append(pl.hand.pop_at(worst))

# ---------------------------------------------------------------- flujo interno

func _log(s: String) -> void:
	log_lines.append(s)

func _lose(p: int, reason: String) -> void:
	if phase == "OVER":
		return
	winner = 1 - p
	phase = "OVER"
	_log("%s pierde: %s. %s" % [players[p].name, reason, ("¡Ganas tú!" if players[winner].name == "Tú" else "¡Gana %s!" % players[winner].name)])

func _start_turn() -> void:
	turn_number += 1
	var pl = players[turn_player]
	gain_honor(pl, 1)
	warrior_played = false
	swapped_this_turn = false
	bushi_count = [0, 0]
	ability_uses = [{}, {}]
	attacked_this_turn = false
	cost_tax = cost_tax.filter(func(t): return t.turn >= turn_number)
	battle = {}
	phase = "MAIN"
	_log("— Turno %d: %s (Honor %d)" % [turn_number, pl.name, pl.honor])
	draw(turn_player, 1)
	if phase == "OVER":
		return
	if ai_level >= 3 and turn_player == 1:     # Pesadilla: la IA hace trampa (y lo dice)
		draw(1, 1)
		gain_honor(pl, 1)
		_log("¡%s hace trampa! Roba 1 carta extra y gana 1 de Honor extra." % pl.name)
		if phase == "OVER":
			return
	if pl.active == 0 and not pl.passive.is_empty():
		pl.active = pl.passive.pop_front()
		_log("%s pasa a la zona activa." % card(pl.active).nombre)

func _end_turn_flow() -> void:
	battle = {}
	if players[turn_player].hand.size() > HAND_LIMIT:
		phase = "DISCARD"
		_log("%s debe descartar hasta tener %d cartas." % [players[turn_player].name, HAND_LIMIT])
	else:
		_finish_turn()

func _finish_turn() -> void:
	Effects.on_turn_end(self, turn_player)
	for pl in players:
		pl.mult = 1
		pl.next_ninja = 0     # Ninjutsu: «por este turno»
	turn_player = 1 - turn_player
	_start_turn()

func _roll(p: int, is_att: bool) -> Dictionary:
	var d := dice_for(p, is_att)
	var pl = players[p]
	var rolls := []
	var total: int = d.points
	for i in d.n:
		var r := rng.randi_range(1, 6)
		rolls.append(r)
		total += r
	if pl.six_next > 0 and not rolls.is_empty():   # El camino: el primer dado vale 6
		total += 6 - rolls[0]
		rolls[0] = 6
		_log("Rectitud Zen: el primer dado de %s vale 6." % pl.name)
	if pl.active == 29 and pl.pick_num in rolls:   # Katsuyori: acertó el número elegido
		total += 7
		_log("¡Katsuyori acierta el %d! +7 al total." % pl.pick_num)
	return {"total": total, "rolls": rolls, "points": d.points}

func _resolve_battle() -> void:
	var a: int = battle.att
	var d := 1 - a
	if not battle.resisted:
		run_steps([Effects.kotaro_step(self, a, false)], func():
			var pa = players[a]
			var cnt: int = 2 if (pa.active == 2 or (pa.active == 9 and 2 in pa.kcopy)) else 1
			if sfx_enabled:    # escena de ataque directo al castillo (solo con interfaz)
				moves.append({"k": "castle_hit", "p": a, "id": pa.active, "d": d, "before": players[d].castle.size(), "n": mini(cnt, players[d].castle.size())})
			castle_draw(d, cnt)
			_battle_end())
		return
	var steps := []
	if not battle.get("plain", false):    # Rectitud Zen anula los efectos de inicio de batalla
		steps.append_array(Effects.battle_start_steps(self, a, true))
		steps.append_array(Effects.battle_start_steps(self, d, false))
	run_steps(steps, _battle_roll)

var _roll_guard := 0

func _battle_roll() -> void:
	_roll_guard = 0
	_do_roll()

## Tira los dados de ambos; luego da paso a efectos que modifican la tirada (Hideyoshi) antes de decidir.
func _do_roll() -> void:
	if phase == "OVER":
		return
	var a: int = battle.att
	var d := 1 - a
	_sfx("dados")
	var ra := _roll(a, true)
	var rb := _roll(d, false)
	_log_duel(a, ra, d, rb)
	battle["res"] = [ra, rb] if a == 0 else [rb, ra]   # resultados indexados por jugador
	battle["rolled"] = false
	for pl in players:
		pl.six_next = 0
	run_steps(Effects.post_roll_steps(self), _post_roll_window)

func _after_roll() -> void:
	if phase == "OVER":
		return
	var a: int = battle.att
	var d := 1 - a
	var ra: Dictionary = battle.res[a]
	var rb: Dictionary = battle.res[d]
	if ra.total == rb.total and _roll_guard < 50:
		_roll_guard += 1
		_log("Empate: se repite el lanzamiento.")
		_do_roll()
		return
	var guard := _roll_guard
	for pl in players:
		if pl.active != 0 and card(pl.active).clan == "Ninja":
			pl.next_ninja = 0
	var rolls := [[], []]
	var pts := [0, 0]
	var tot := [0, 0]
	var names := ["", ""]
	var ids := [0, 0]
	rolls[a] = ra.rolls; rolls[d] = rb.rolls
	pts[a] = ra.points; pts[d] = rb.points
	tot[a] = ra.total; tot[d] = rb.total
	names[a] = card(players[a].active).nombre; names[d] = card(players[d].active).nombre
	ids[a] = players[a].active; ids[d] = players[d].active
	var win := a if ra.total > rb.total else d
	last_duel = {"rolls": rolls, "points": pts, "totals": tot, "names": names, "winner": win, "ties": guard}
	duel_id += 1
	if sfx_enabled:    # escena de duelo (solo con interfaz)
		moves.append({"k": "duel", "p": win, "id": ids[win], "ids": ids, "rolls": rolls, "points": pts, "totals": tot, "att": a})
	_kill_active(1 - win, win, absi(ra.total - rb.total))
	if phase == "OVER":
		return
	var info := {"ids": ids, "rolls": rolls, "totals": tot, "winner": win, "loser": 1 - win}
	run_steps(Effects.post_duel_steps(self, info), _battle_end)

func _battle_end() -> void:
	for pl in players:
		pl.mult = 1
		pl.bb_dice = 0
		pl.bb_points = 0
		pl.bb_set = 0
		pl.pick_num = 0
		pl.kcopy = []
		pl.six_next = 0
	if phase == "OVER":
		return
	_end_turn_flow()

func _log_duel(a: int, ra: Dictionary, d: int, rb: Dictionary) -> void:
	_log("Duelo: %s %s%s = %d  vs  %s %s%s = %d" % [
		card(players[a].active).nombre, str(ra.rolls), (" +%d" % ra.points) if ra.points > 0 else "", ra.total,
		card(players[d].active).nombre, str(rb.rolls), (" +%d" % rb.points) if rb.points > 0 else "", rb.total])

func _kill_active(victim: int, killer: int, margin: int = 0) -> void:
	var pl = players[victim]
	var id: int = pl.active
	pl.active = 0
	_fx("field_discard", victim, id)
	send_to_discard(victim, id)
	_log("%s es derrotado." % card(id).nombre)
	Effects.on_kill(self, killer, id)
	Effects.on_hero_died(self, victim, id, margin)
	Effects.temple_normalize(self, victim)
	castle_draw(victim, 2 if card(id).categoria == "Daimyo" else 1)
