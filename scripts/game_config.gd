class_name GameConfig
extends RefCounted
## Elección hecha en el menú para la próxima partida. Vacío = mazo al azar.

static var deck_me: Array = []
static var deck_opp: Array = []
static var name_me := "Mazo al azar"
static var name_opp := "Mazo al azar"
static var duel_anim := true      # escena 2D del duelo (se puede desactivar en la partida)
static var start_screen := ""      # pantalla con la que abre el menú ("campana" al volver de un duelo de campaña)
static var difficulty := 1         # 0 Fácil, 1 Normal, 2 Difícil, 3 Pesadilla
static var season := 0             # fondo: 0 al azar, 1 primavera, 2 verano, 3 otoño, 4 invierno
static var tutorial := false       # partida guiada de ~1 minuto con flechas
static var camp_alt := false      # duelo 1 de la campaña: true = tu aliado es Takeda (rival Uesugi)
static var campaign_level := 0     # 0 = partida normal; 1..7 = duelo de la Campaña Histórica
