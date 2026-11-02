class_name DeckBuilder
extends RefCounted
## Mazo de prueba: 50 cartas, máx. 3 copias por carta.
## Parejas de héroes + todas las acciones implementadas (1 copia) + completar con acciones al azar.

static func shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

static func random_deck(rng: RandomNumberGenerator) -> Array:
	var cheap := []
	var other := []
	var daimyos := []
	for id in CardDB.cards:
		if id >= CardDB.TOKEN_ID:
			continue
		var c = CardDB.cards[id]
		match c.categoria:
			"Guerrero":
				if c.costo_honor == 1: cheap.append(id)
				else: other.append(id)
			"Daimyo":
				daimyos.append(id)
	shuffle(cheap, rng)
	shuffle(other, rng)
	shuffle(daimyos, rng)
	var acts: Array = Effects.ACTIONS.duplicate()
	var pairs: int = (50 - acts.size() - 1) / 2          # héroes en parejas; el resto se completa con acciones
	var picks := cheap.slice(0, 5) + daimyos.slice(0, 2) + other.slice(0, pairs - 7)
	var deck := []
	for id in picks:
		deck.append(id)
		deck.append(id)
	deck.append_array(acts)
	shuffle(acts, rng)
	deck.append_array(acts.slice(0, 50 - deck.size()))
	assert(deck.size() == 50)
	return deck
