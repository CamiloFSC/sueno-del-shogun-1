class_name ExtraArt
extends RefCounted
## Arte extra: fondos por estación, castillo que se destruye, poses alternativas de Daimyo y el Shogun.

const SEASONS := ["Aleatoria", "Primavera", "Verano", "Otoño", "Invierno"]
const SEASON_KEY := ["", "pri", "ver", "oto", "inv"]
const ALT_POSE := {55: "nobunaga", 56: "hideyoshi", 57: "tokugawa", 58: "shingen", 59: "kenshin", 62: "mitsunari"}
static var _cache := {}

static func _tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = CardArt._load_path(path)
	return _cache[path]

## Estación elegida (0 = al azar; se resuelve con el generador dado).
static func resolve_season(season: int, rng: RandomNumberGenerator) -> int:
	return season if season > 0 else rng.randi_range(1, 4)

## kind: "campo" (campo abierto, imagen X1) o "castillo" (imagen X2).
static func season_bg(kind: String, season: int) -> Texture2D:
	if season < 1 or season > 4:
		return null
	return _tex("res://assets/fondos/%s%d.png" % [SEASON_KEY[season], 1 if kind == "campo" else 2])

## Imagen del castillo según cuántas cartas le quedan (7 = intacto ... 0 = en ruinas).
static func castle_stage(count: int) -> Texture2D:
	var idx: int = [7, 6, 6, 5, 4, 3, 2, 1][clampi(count, 0, 7)]
	return _tex("res://assets/castillo/c%d.png" % idx)

static func alt_pose(id: int) -> Texture2D:
	if not ALT_POSE.has(id):
		return null
	return _tex("res://assets/personajes/%s.png" % ALT_POSE[id])

static func shogun() -> Texture2D:
	return _tex("res://assets/personajes/shogun.png")

static func creator() -> Texture2D:
	return _tex("res://assets/personajes/creador.png")
