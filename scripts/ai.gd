class_name AI
extends RefCounted
## IA simple por reglas. Cada llamada a act() hace UNA decisión del jugador al que le toca.

static func act(g: Game) -> void:
	match g.phase:
		"MAIN": _main(g)
		"DEFENDER_CHOICE": _defend(g)
		"WINDOW": _window(g)
		"DISCARD": _discard(g)
		"CHOICE": _choice(g)

static func _expected(g: Game, p: int, is_att: bool) -> float:
	var d := g.dice_for(p, is_att)
	return d.n * 3.5 + d.points

## Mayor cantidad de personajes de un mismo clan que tengo en juego.
static func _best_clan_in_play(g: Game, p: int) -> int:
	var cnt := {}
	for h in g.heroes_in_play(p):
		var c: String = g.clan_of(p, h)
		cnt[c] = int(cnt.get(c, 0)) + 1
	var best := 0
	for c in cnt:
		best = maxi(best, cnt[c])
	return best

static func _worth(g: Game, p: int, id: int) -> bool:
	var pl = g.players[p]
	match id:
		71, 91, 84: return true
		83: return Game.CASTLE_SIZE - pl.castle.size() >= 2
		88: return pl.castle.size() <= 4
		99: return pl.hand.size() <= 4
		79: return pl.hand.size() >= 7
		95: return pl.hand.size() <= 3
		74: return _best_clan_in_play(g, p) >= 2                 # El destino del clan: roba 1 por personaje del clan nombrado
		82: return Effects._ai_strategist(g, p).size() >= 2      # solo si hay cartas flojas que cambiar
		85: return pl.honor < 2 and pl.hand.size() >= 6          # tempo: bajar gratis cuando aún no puedes pagarlo
		86: return pl.honor < 3 and pl.hand.size() >= 7
		97: return _lealtad_clan_count(g, p) >= 3                # solo con 3 héroes de un mismo clan en la mano
		75: return pl.hand.size() <= 3
		96, 98, 72, 73, 81: return true                                      # trampas: colocarlas boca abajo
		77: return true                                          # Liderazgo: destruir una trampa rival
		80:                                                      # Dilema: solo para habilitar Liderazgo
			if not (77 in pl.hand) or g.players[1 - p].facedown.is_empty() or Effects._has_pair(g, p):
				return false
			return true
		89:                                                      # Castillo de montaña: cuando no puede bajar a nadie
			if pl.active != 0:
				return false
			for h in pl.hand:
				if g.can_play_warrior(p, h):
					return false
			return pl.deck.size() > 12
		90: return g.heroes_in_play(p).size() >= 2
		# 92 (Matrimonio arreglado): la IA no lo usa, desarma su propio tablero
	return false

static func _lealtad_clan_count(g: Game, p: int) -> int:
	var counts := {}
	var best := 0
	for c in g.players[p].hand:
		if g.is_hero(c) and g.card(c).clan != "Ninja" and g.card(c).clan != "Ronin":
			counts[g.card(c).clan] = counts.get(g.card(c).clan, 0) + 1
			best = maxi(best, counts[g.card(c).clan])
	return best

static func _ability_worth(g: Game, p: int, id: int) -> bool:
	var pl = g.players[p]
	match id:
		12: return pl.honor >= 3 and pl.hand.size() <= 5
		18, 49, 50, 51, 61, 62: return true
		67: return pl.honor >= 4 and pl.hand.size() <= 5
		9001: return not g.players[p].passive.is_empty() or g.heroes_in_play(p).size() >= 2
		9003: return pl.honor >= 8
		55: return pl.hand.size() <= 4 and pl.deck.size() > 12
		57: return pl.honor >= 3 and pl.hand.size() <= 5
		64:
			for h in pl.hand:
				if g.card_value(h) <= 1:
					return true
			return false
	return false   # Toshie: ordenar no aporta a esta IA

static func _main(g: Game) -> void:
	var p := g.turn_player
	var pl = g.players[p]
	var op = g.players[1 - p]
	# 1) acciones útiles (nivel Fácil: la IA no usa cartas Bushi ni habilidades)
	for i in pl.hand.size():
		if g.ai_level == 0 and p == 1:
			break
		var id: int = pl.hand[i]
		if g.card(id).categoria == "Accion" and Effects.can_play(g, p, id) and _worth(g, p, id):
			g.play_action(i)
			return
	# 1b) habilidades activas (una vez por turno)
	for ab in ([] if (g.ai_level == 0 and p == 1) else g.available_abilities()):
		if _ability_worth(g, p, ab.id):
			g.use_ability(ab.id)
			return
	# 2) el mejor guerrero que pueda pagar
	var best := -1
	var want_clan := ""
	if not pl.lealtad.is_empty():
		want_clan = pl.lealtad[0].clan       # Lealtad abierta: priorizar héroes de ese clan
	for i in pl.hand.size():
		var id: int = pl.hand[i]
		if not g.can_play_warrior(p, id):
			continue
		if best == -1:
			best = i
			continue
		var cur: Dictionary = g.card(pl.hand[best])
		var cand: Dictionary = g.card(id)
		if want_clan != "" and (cand.clan == want_clan) != (cur.clan == want_clan):
			if cand.clan == want_clan:
				best = i
		elif cand.costo_honor > cur.costo_honor:
			best = i
	if best != -1:
		g.play_warrior(best)
		return
	# 2b) cambio de rol: si un pasivo tiene claramente más ataque que el activo
	if g.can_swap_active(p) and pl.active != 0:
		var bi := -1
		var bv: int = g.card(pl.active).ataque
		for k in pl.passive.size():
			if g.card(pl.passive[k]).ataque > bv:
				bv = g.card(pl.passive[k]).ataque
				bi = k
		if bi != -1:
			g.swap_active(bi)
			return
	# 3) atacar
	if pl.active != 0 and not g.battle.has("att") and not _already_attacked(g):
		var target := "castillo"
		if op.active != 0 and _expected(g, p, true) >= _expected(g, 1 - p, false) - 0.5:
			target = "guerrero"
		g.declare_attack(target)
		return
	g.end_turn()

static func _already_attacked(_g: Game) -> bool:
	return false  # un ataque siempre termina el turno, no hace falta registrar nada

static func _defend(g: Game) -> void:
	var d := g.actor()
	g.respond(_expected(g, d, false) >= _expected(g, 1 - d, true))

static func _window(g: Game) -> void:
	var p := g.actor()
	var pl = g.players[p]
	if g.ai_level == 0 and p == 1:
		g.pass_priority()
		return
	for i in pl.hand.size():
		var id: int = pl.hand[i]
		if (id == 78 or id == 93) and Effects.can_play(g, p, id):
			g.play_action(i)
			return
		if id == 81 and Effects.can_play(g, p, id):    # Rectitud Zen: solo si anular los modificadores me favorece
			var plain_me: float = g.card(pl.active).ataque * 3.5
			var plain_op: float = g.card(g.players[1 - p].active).ataque * 3.5
			var cur: float = _expected(g, p, g.battle.att == p) - _expected(g, 1 - p, g.battle.att != p)
			if plain_me - plain_op > cur + 1.0:
				g.play_action(i)
				return
		if id in Effects.POST_ROLL and Effects.can_play(g, p, id) and _post_roll_worth(g, p, id):
			g.play_action(i)
			return
		if id == 87 and Effects.can_play(g, p, id) and _expected(g, p, g.battle.att == p) < _expected(g, 1 - p, g.battle.att != p) + 4:
			var ronin := 0
			for c in pl.hand:
				if g.card(c).clan == "Ronin":
					ronin += 1
			if ronin >= 2:                       # Musha Shugyo: solo vale la pena descartando 2+ Ronin
				g.play_action(i)
				return
	for j in pl.facedown.size():
		var fid: int = pl.facedown[j]
		if not (fid in Effects.FD_PLAY) or not Effects.can_play_fd(g, p, fid):
			continue
		var go := false
		if fid == 81:
			var plain_me: float = g.card(pl.active).ataque * 3.5
			var plain_op: float = g.card(g.players[1 - p].active).ataque * 3.5
			var cur: float = _expected(g, p, g.battle.att == p) - _expected(g, 1 - p, g.battle.att != p)
			go = plain_me - plain_op > cur + 1.0
		elif g.battle.get("rolled", false):
			go = _post_roll_worth(g, p, fid)
		if go:
			g.play_facedown(j)
			return
	g.pass_priority()

## Cartas de dados: se juegan si con ellas se puede ganar (o empatar a favor) un duelo que va perdido.
static func _post_roll_worth(g: Game, p: int, id: int) -> bool:
	var mine: Dictionary = g.battle.res[p]
	var opp: Dictionary = g.battle.res[1 - p]
	var need: int = opp.total - mine.total          # puntos que faltan para empatar
	if need < 0:
		return false
	var gain := 0
	match id:
		73:
			for v in opp.rolls:
				if v > 1:
					gain += 1
			return gain > need
		76:
			var dice := Effects._die_opts(g, p)
			var k: int = Effects._ai_die_pick(g, p, 76)
			var v: int = dice[k].die
			gain = (3 - v) if dice[k].who == p else (v - 3)
			return gain > need
		70:
			return need <= 3 and need >= 0
		72, 94:
			var top := 0
			for v in mine.rolls:
				top = maxi(top, v)
			return top * (2 if id == 72 else 1) > need
	return false

static func _discard(g: Game) -> void:
	var pl = g.players[g.turn_player]
	var worst := 0
	for k in pl.hand.size():
		if g.card_value(pl.hand[k]) < g.card_value(pl.hand[worst]):
			worst = k
	g.discard_card(worst)

## Responde una decisión abierta por un efecto (g.pending). Modos: take, give, number, yesno, info.
static func _choice(g: Game) -> void:
	var pd: Dictionary = g.pending
	var opts: Array = pd.options
	var valid: Array = pd.valid
	var idx: Array = []
	if pd.has("ai") and pd.ai.is_valid():     # el propio efecto sabe qué le conviene a la IA
		idx = pd.ai.call()
		if idx.size() in valid:
			g.choose(idx)
			return
		idx = []
	match pd.mode:
		"info":
			idx = []
		"number":
			idx = [g.rng.randi() % opts.size()]
		"yesno":
			idx = [0]   # la primera opción es siempre "sí"
		"clan_hurt", "clan_help":
			var me: int = pd.player
			var best := 0
			var best_n := -1
			for i in opts.size():
				var n := 0
				var who: Array = [1 - me] if pd.mode == "clan_hurt" else [0, 1]
				for q in who:
					for h in g.heroes_in_play(q) + (g.players[q].hand if pd.mode == "clan_hurt" else []):
						if g.card(h).clan == opts[i].value:
							n += 1
				if n > best_n:
					best_n = n
					best = i
			idx = [best]
		"give":    # hay que descartar: se van las cartas de menos valor
			var order := _by_value(g, opts, true)
			var k: int = valid.max()
			if 0 in valid:   # descarte opcional (costo de un efecto): solo si las cartas son prescindibles
				var ok: bool = order.size() >= k
				for i in range(mini(k, order.size())):
					if g.card_value(opts[order[i]].card) > 2:
						ok = false
				idx = order.slice(0, k) if ok else []
			else:
				idx = order.slice(0, valid[0])
		_:         # take: se llevan las cartas de más valor
			var order := _by_value(g, opts, false)
			idx = order.slice(0, valid.max())
	if not (idx.size() in valid):
		idx = range(valid[0])
	g.choose(idx)

## Índices de las opciones ordenados por valor de carta (ascendente o descendente).
static func _by_value(g: Game, opts: Array, ascending: bool) -> Array:
	var order := range(opts.size())
	order.sort_custom(func(a, b):
		var va: int = g.card_value(opts[a].card) if opts[a].has("card") else 0
		var vb: int = g.card_value(opts[b].card) if opts[b].has("card") else 0
		return va < vb if ascending else va > vb)
	return order
