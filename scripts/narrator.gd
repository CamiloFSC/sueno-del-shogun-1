class_name Narrator
extends Control
## Personajes de la campaña que irrumpen en la partida y comentan con un globo de cómic.
## Poses (archivos en assets/personajes/): <nombre>.png (con fondo), <nombre>_b.png (sin fondo),
## <nombre>_c.png (sin fondo, mirando al jugador: «cuarta pared»). Si falta una pose se usa la anterior.

const NAMES := {"tenzo": "Watanabe Tenzo", "mitsunari": "Ishida Mitsunari", "shingen": "Takeda Shingen", "kenshin": "Uesugi Kenshin",
	"nobunaga": "Oda Nobunaga", "tokugawa": "Tokugawa Ieyasu", "masamune": "Date Masamune", "hideyoshi": "Toyotomi Hideyoshi",
	"creador": "El Creador"}

## Pose en la que el personaje señala al jugador (cuarta pared). Por defecto "d"; Kenshin y Masamune solo tienen a/b/c.
const DIRECT_POSE := {"kenshin": "c", "masamune": "c"}

## Líneas por personaje y evento. «@» al inicio = dirigida al jugador (pose de cuarta pared).
## Eventos: start, first_blood, player_hurt, opp_hurt, low, opp_low, mid1, mid2, cheat (solo el Creador), win, lose.
const LINES := {
	"kenshin": {
		"start": ["Soy el Dragón de Echigo y Bishamonten me mira. Intenta no hacerlo quedar mal.", "@Una vez le mandé sal a Takeda cuando se la bloquearon. Pelear sí, pasar hambre no."],
		"first_blood": ["Primera herida. Hay que beber a su salud... y a la mía."],
		"player_hurt": ["La nieve de Echigo cae sobre los fuertes. Tu castillo también, al parecer.", "Dicen que mi peor enemigo es el sake. Ese golpe fue peor."],
		"opp_hurt": ["Un golpe limpio, sin deshonra. Lo anotaré en mi copa."],
		"low": ["@Tu castillo se agrieta. Piensa como en Kawanakajima: cargar al centro y rezar."],
		"opp_low": ["Termina esto con dignidad. Sin saltarte la cena."],
		"mid1": ["Esto va más lento que mi carga de 1561. Y esa duró toda la mañana."],
		"mid2": ["Si Shingen me mira otra vez con ese abanico, le devuelvo la sal."],
		"win": ["@Combatiste con honor. Esta noche el sake lo pago yo."],
		"lose": ["Hoy gana el Tigre. Mañana me quejo con Bishamonten."]},
	"shingen": {
		"start": ["Fūrin-kazan: rápido como el viento, tranquilo como el bosque, ardiente como el fuego, firme como la montaña.", "@¿Ves ese abanico? Con él paré la espada de Kenshin. Con tus cartas haré lo mismo."],
		"first_blood": ["Así empieza Kawanakajima. Nunca sabré quién ganó esa, por cierto."],
		"player_hurt": ["La gente es el castillo, la gente es el muro. Tu muro tiene goteras.", "Mi sombra, Kagemusha, ya habría entendido ese golpe."],
		"opp_hurt": ["Bien golpeado. Pero la montaña no se mueve y yo tampoco, por si Ieyasu pregunta."],
		"low": ["@Tu castillo cae. Eso me pasó a mí tres años... y nadie se enteró. Aprende discreción."],
		"opp_low": ["Aprovecha: su muralla está abierta como las puertas de Edo."],
		"mid1": ["Dicen que mi muerte la oculté tres años. Mi estrategia de tomarme el tiempo viene de ahí."],
		"mid2": ["Ieyasu huyó de Mikatagahara. Aún me río. Él, menos."],
		"win": ["@Tienes la fuerza de la montaña. Entra, que hay sopa de miso."],
		"lose": ["Rápido como el viento... y tú, demasiado lento. Por una vez."]},
	"masamune": {
		"start": ["Nací demasiado tarde. Por eso llego con más estilo que nadie.", "@¿El ojo? Lo veo todo con el otro. Y tus cartas se ven malísimas."],
		"first_blood": ["Primera sangre. Para Hideyoshi llegué tarde; para esto llegué a tiempo."],
		"player_hurt": ["Te duele, ¿eh? Ya llegué vestido de blanco, listo para el funeral. De mi rival, eso sí.", "Un dragón no pide disculpas. Pide sake."],
		"opp_hurt": ["¡Digno de un dragón! Y eso que no me han servido nada de cenar."],
		"low": ["@Tu castillo se tambalea. Yo le mandé una embajada al Papa. Tú mándame un refuerzo."],
		"opp_low": ["Ya casi. Rómpelo, tengo una cena de miso que cocinar."],
		"mid1": ["Dicen que cocino mejor de lo que peleo. No me ofendo: es verdad."],
		"mid2": ["Llegué tarde al Odawara y casi me cortan la cabeza. Esta partida la voy a ganar puntual."],
		"win": ["@Nada mal. Si hubiera nacido en tu época, habría peleado a tu lado."],
		"lose": ["El dragón ruge hoy. Mañana, con elegancia, vuelve."]},
	"tenzo": {
		"start": ["Si me ves, no soy ninja. Si no me ves... tampoco. Piénsalo.", "@No me mires tan fijo. Los ninja no posamos para fotos. Esto es un caso especial."],
		"first_blood": ["Primera sangre. Nobunaga arrasó Iga y nunca lo olvidamos. Los ninja somos rencorosos."],
		"player_hurt": ["Tu castillo cruje... en silencio, como me gusta.", "Ni te diste cuenta. Eso se llama oficio."],
		"opp_hurt": ["¿Lo oyes? Es mi castillo quejándose. Tranquilo, es de papel: se pliega y se esconde."],
		"low": ["@Tu castillo pende de un hilo. Y yo no suelto el hilo."],
		"opp_low": ["Un golpe más y desaparezco... pero con tu honor."],
		"mid1": ["Cuando acabe la partida, tu mano habrá cambiado. Ya revisé las cartas, por si acaso."],
		"mid2": ["¿Quién dijo que los ninja no hablan? Es que casi nunca nos invitan a nada."],
		"win": ["@Sobreviviste a la noche. Esta vez. Cuidado con tus sombras."],
		"lose": ["Las sombras ganan hoy. No pienses que fue por ti. O sí."]},
	"mitsunari": {
		"start": ["Ishida Mitsunari, administrador. Ya revisé el Honor de ambos lados. Tienes un déficit.", "@Te serviré tres tazas de té: caliente, tibia y fría. Es la prueba. Aprobarás o no."],
		"first_blood": ["Primera pérdida del libro de cuentas. Anotada."],
		"player_hurt": ["Un error de cálculo. Corrígelo ya, y con letra clara.", "Con esa defensa Hideyoshi no te habría contratado."],
		"opp_hurt": ["Bien. Ese golpe estaba en el presupuesto."],
		"low": ["@Tu castillo se agota. Piensa antes de gastar. Es el consejo más barato que recibirás hoy."],
		"opp_low": ["Su castillo es papel. Hagamos balance y cerremos el año fiscal."],
		"mid1": ["Dicen que soy antipático. Prefiero 'puntual' y 'honesto'."],
		"mid2": ["En Sekigahara me faltaron tres daimyo. Aquí te falta algo parecido: estrategia."],
		"win": ["@Honor y orden: así se gana. Prepárate, que la factura es el siguiente duelo."],
		"lose": ["Al menos no me ofrecieron un caqui antes de despedirme. Fue un buen día."]},
	"nobunaga": {
		"start": ["¡Arda el Monte Hiei! Hoy no hay clemencia para los monjes ni para el aburrimiento.", "@¿Cincuenta cartas? Mi canción favorita dice que la vida humana dura cincuenta años. Coincidencia, claro."],
		"first_blood": ["La primera chispa. Pronto será un incendio, como en Enryaku-ji."],
		"player_hurt": ["¡Más fuego! Que tu castillo conozca el miedo y el humo.", "Si no cantas, te mato. ¿Y si cantas desafinado? También."],
		"opp_hurt": ["¡Eso es! Quémalo todo. Reconstruimos luego, con balcón."],
		"low": ["@Tu castillo humea. ¿Piensas rendirte? Hasta mi té se enfría con más dignidad."],
		"opp_low": ["Sus muros arden. ¡Remata! Me sobran mechas."],
		"mid1": ["Mi capa extranjera es más cara que tu mazo. Y eso que ni se mira."],
		"mid2": ["Tengo que cuidarme de Akechi. Siempre me mira raro en esas reuniones de té."],
		"win": ["@Como en Azuchi: de las cenizas, un nuevo orden. Con pagoda, eso sí."],
		"lose": ["Ni el fuego salva a los débiles. Ni a los desprevenidos en un templo, pero esa es otra historia."]},
	"hideyoshi": {
		"start": ["De mozo de sandalias a Regente. Las calentaba en mi pecho; hoy me enfrío yo en tu contra.", "@El Mono ya pasó por todos los escalones. Tú, ¿al menos sabes subir uno?"],
		"first_blood": ["Primera sangre. Así se sube: carta a carta, sandalia a sandalia."],
		"player_hurt": ["Ja, ja. Tu castillo no durará ni una noche. El mío me salió en una.", "Si el cuco no canta, hazlo cantar. Tu castillo ya canta."],
		"opp_hurt": ["¡Bien! Me estás gustando. Aunque yo ya tengo té dorado, así que pierdes igual."],
		"low": ["@Tu castillo cae. Le hubieras puesto oro, como yo. Mira mi sala de té."],
		"opp_low": ["¡Ya casi eres Shogun! Aunque, entre nos, yo nunca pude serlo. Sangre de campesino."],
		"mid1": ["Me dicen Saru, el Mono. Tomo el insulto como cumplido: trepo mejor que tú."],
		"mid2": ["Tengo una espada para cada campesino de Japón. Nada personal, es una ley."],
		"win": ["@Inclino la cabeza ante el nuevo Shogun... pero no demasiado, que me duele la espalda."],
		"lose": ["El trono sigue siendo mío. O, al menos, mi sala de té."]},
	"tokugawa": {
		"start": ["Quien tiene paciencia, tiene el Shogunato. Yo esperé años. Mi familia, doscientos sesenta.", "@No me mires así. Aún guardo un retrato mío con cara de susto, por Mikatagahara. Aprendí."],
		"first_blood": ["Todavía queda mucho juego. Y, si no, almuerzo."],
		"player_hurt": ["Aguanta. El tiempo está de nuestra parte. Siempre lo estuvo.", "Calma. Si el cuco no canta, espero. Tu castillo ya se cayó, pero espero igual."],
		"opp_hurt": ["Despacio, sin prisa. Así se gana. Y así se come tempura."],
		"low": ["@Tu castillo está en peligro. Calma, y piensa. No hay tempura que lo salve."],
		"opp_low": ["Casi. No te precipites ahora: lo mío es llegar el último, pero llegar."],
		"mid1": ["Dicen que me morí por comer tempura. Mentira: murió mi mala suerte."],
		"mid2": ["Tengo halcones, buena salud y un castillo firme. ¿Tú qué tienes? Prisa."],
		"win": ["@Paciencia recompensada. Edo te recibe. Y el té va por mi cuenta."],
		"lose": ["Esperar no basta: hay que saber cuándo golpear. Lección gratis."]},
	"creador": {
		"start": ["Hola. Yo hice este juego. Yo escribí las reglas, dibujé las cartas y... también sé cuáles romper.", "@Sí, tú. Mírame. Voy a ganarte con las reglas que yo mismo inventé."],
		"first_blood": ["Primera sangre. Mi castillo no se rompe, se 'reajusta'."],
		"player_hurt": ["Ay. Me olvidé de contarte que mi mazo viene con descuento de Honor. Pequeña errata.", "No es trampa: es un 'ajuste de balance'."],
		"opp_hurt": ["Tranquilo, lo programé así. Para que te sintieras bien."],
		"low": ["@Tu castillo se cae. ¿Ya viste el reglamento? Cap. 1: pierde quien se queda sin castillo."],
		"opp_low": ["¿Mi castillo en peligro? Qué raro: lo diseñé más grande. Ah, no: era una descripción."],
		"mid1": ["Te regalo un consejo: no apuestes contra el que escribió el motor."],
		"mid2": ["Dibujé cada una de estas cartas. Y tú las usas... mal. Dolió un poquito."],
		"cheat": ["Robé una carta extra. Es mi juego, ¿me vas a demandar?", "Sumé un Honor al azar. Ok, no era al azar. Perdón. No."],
		"win": ["@Respeto. Eres el Shogun de verdad. Y yo, un mal perdedor: la próxima te arreglo el mazo."],
		"lose": ["@Jaja. Otra victoria mía. Vuelve cuando entiendas mi diseño."]},
}

## Versión «aliado sabio» (duelo 1: el que elijas como aliado te trata como a un discípulo).
const ALLY_LINES := {
	"kenshin": {
		"start": ["Joven, hoy peleamos del mismo lado. Escucha: calma en el centro, filo en la mano.", "@Bishamonten te bendice. Mejor aún: yo te acompaño, y eso es más caro."],
		"first_blood": ["Una herida, sí. Pero se ve que sabes sangrar con estilo. Sigue."],
		"player_hurt": ["Duele, pero enseña. Dime qué aprendiste y te invito a sake.", "Aguanta, discípulo. La nieve cae y el pino sigue en pie."],
		"opp_hurt": ["¡Bien! Takeda ya sintió el golpe. Con respeto, eh: es mi mejor rival."],
		"low": ["@Tu castillo flaquea. Cuando así ocurre, respira. Y luego cargas al centro."],
		"opp_low": ["Su castillo cede. Termina con honor y sin ensañarte."],
		"mid1": ["Un consejo: gasta tu Honor como yo gasto el sake. Con medida... casi siempre."],
		"mid2": ["No olvides que Shingen te estudia. Mejor sorprenderlo: hazlo reír."],
		"win": ["@Ganamos. Sabía que eras de los míos. Aunque Shingen ya me debe sal."],
		"lose": ["Hoy nos tocó perder. Aprende, y mañana ganamos juntos."]},
	"shingen": {
		"start": ["Joven, hoy peleamos del mismo lado. Tu primer lema: viento, bosque, fuego, montaña.", "@Te lo aconsejo como a un hijo: un castillo se defiende con gente, no solo con muros."],
		"first_blood": ["Una herida. Normal. Hasta el Tigre sangra. Sigue en pie."],
		"player_hurt": ["Aguanta. La montaña no se mueve, pero cambia de plan.", "Lo vi venir. Pero me gusta que aprendas por ti mismo."],
		"opp_hurt": ["¡Excelente! Kenshin sentirá eso. Con cariño, claro."],
		"low": ["@Tu castillo cae. Respira. A veces la mejor estrategia es parecer que ya perdiste."],
		"opp_low": ["Su castillo cede. Un último golpe y tendré que pedirle sal a Kenshin."],
		"mid1": ["Un consejo: no ahorres tanto. Hasta un tigre gasta cuando debe."],
		"mid2": ["Si ves a Kenshin con espada, sonríe. Es el único idioma que respeta."],
		"win": ["@Ganamos. Sabía que eras de los míos. Entra, que hay sopa de miso."],
		"lose": ["Hoy nos tocó perder. Aprende, y mañana ganamos juntos."]},
}

var chars: Array = []
var _bubble: PanelContainer
var _txt: Label
var _name: Label
var _pic: TextureRect
var _tail: Control
var _tween: Tween
var _timer: Timer
var _turn_last := -99
var _said := {}
var count := 0
var _flip := 0

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 175
	visible = true

var allies: Array = []

func setup(list: Array, ally_list: Array = []) -> void:
	chars = list
	allies = ally_list
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pic.modulate.a = 0.0
	add_child(_pic)
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 0.96)
	sb.border_color = Color(0.1, 0.08, 0.06)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(26)
	sb.set_content_margin_all(16)
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.modulate.a = 0.0
	_bubble.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			hide_now())
	add_child(_bubble)
	var vb := VBoxContainer.new()
	_bubble.add_child(vb)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 15)
	_name.add_theme_color_override("font_color", Color(0.65, 0.12, 0.1))
	vb.add_child(_name)
	_txt = Label.new()
	_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_txt.custom_minimum_size = Vector2(360, 0)
	_txt.add_theme_font_size_override("font_size", 21)
	_txt.add_theme_color_override("font_color", Color(0.08, 0.06, 0.05))
	vb.add_child(_txt)
	_tail = Control.new()
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.modulate.a = 0.0
	_tail.draw.connect(func():
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(46, 22), Vector2(0, 46)])
		_tail.draw_colored_polygon(pts, Color(1, 1, 0.96))
		_tail.draw_polyline(PackedVector2Array([Vector2(0, 0), Vector2(46, 22), Vector2(0, 46)]), Color(0.1, 0.08, 0.06), 4.0))
	_tail.size = Vector2(50, 50)
	add_child(_tail)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(hide_now)
	add_child(_timer)

func pose_tex(who: String, direct: bool) -> Texture2D:
	var order: Array = [DIRECT_POSE.get(who, "d"), "c", "b", "a"] if direct else ["b", "a"]
	for p in order:
		var path := "res://assets/personajes/%s_%s.png" % [who, p]
		if ResourceLoader.exists(path):
			return ExtraArt._tex(path)
	return null

## Dice una línea del evento (si el personaje la tiene). turn evita hablar demasiado seguido.
func say(event: String, turn: int, force: bool = false) -> bool:
	if chars.is_empty():
		return false
	if not force and (turn - _turn_last < 3 or count >= 9):
		return false
	if _said.has(event) and event != "player_hurt" and event != "opp_hurt":
		return false
	var who: String = chars[0]
	if chars.size() > 1:
		who = chars[0] if (_flip % 3 != 2) else chars[1]
	elif not allies.is_empty():
		who = allies[0]
	_flip += 1
	var table: Dictionary = ALLY_LINES if allies.has(who) else LINES
	var opts: Array = table.get(who, {}).get(event, [])
	if opts.is_empty():
		return false
	_said[event] = true
	var line: String = opts[randi() % opts.size()]
	var direct := line.begins_with("@")
	if direct:
		line = line.substr(1)
	_turn_last = turn
	count += 1
	_show(who, line, direct)
	return true

func _show(who: String, line: String, direct: bool) -> void:
	var S := get_viewport_rect().size
	_name.text = NAMES.get(who, who)
	_txt.text = line
	var tex := pose_tex(who, direct)
	_pic.texture = tex
	var ph := minf(S.y * 0.55, 420.0)
	var pw := ph * 0.62 if tex == null else ph * float(tex.get_width()) / float(tex.get_height())
	_pic.size = Vector2(pw, ph)
	_pic.position = Vector2(S.x - pw - 8.0, S.y - ph - 130.0)
	_bubble.reset_size()
	_bubble.position = Vector2(_pic.position.x - _bubble.size.x - 40.0, _pic.position.y + 30.0)
	_tail.position = Vector2(_bubble.position.x + _bubble.size.x - 6.0, _bubble.position.y + 50.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	var p0: Vector2 = _pic.position
	_pic.position = p0 + Vector2(60, 0)
	_tween.tween_property(_pic, "position", p0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for n in [_pic, _bubble, _tail]:
		_tween.tween_property(n, "modulate:a", 1.0, 0.3)
	_timer.start(7.5)

func hide_now() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	for n in [_pic, _bubble, _tail]:
		_tween.tween_property(n, "modulate:a", 0.0, 0.25)

# ------------------------------------------------------------------ cameos: el personaje aparece cuando sale su carta (o la de su familia / rivales)
## Carta de Daimyo de cada personaje (el Creador no tiene carta).
const CARD_OF := {"nobunaga": 55, "hideyoshi": 56, "tokugawa": 57, "shingen": 58, "kenshin": 59, "masamune": 60, "tenzo": 61, "mitsunari": 62}
## Cartas de su familia / clan / séquito: reaccionan con las líneas "kin".
const KIN := {
	"nobunaga": [19, 20, 21], "hideyoshi": [22, 23, 24], "tokugawa": [25, 26, 27], "shingen": [28, 29, 30],
	"kenshin": [31, 32, 33, 34, 35, 36, 66], "masamune": [46, 47, 48], "tenzo": [1, 2, 3, 4, 5, 6, 7, 8, 9],
	"mitsunari": [10, 11, 12, 13, 14, 15, 16, 17, 18]}
## Rivales o conocidos (ids de carta) que provocan un comentario especial: {personaje: {carta: [líneas]}}. {n} = nombre de la carta.
const RIVAL_LINES := {
	"nobunaga": {69: ["¿{n}? Mira nada más. Siempre supe que con ese té había gato encerrado.", "{n} otra vez. Si lo ves con una antorcha, avísame."], 58: ["{n}... el Tigre de Kai. Le gusta hacerse el difícil."], 59: ["{n}. Me ganó en Tedorigawa... ah no, esa la gané yo."], 56: ["{n}, mi viejo Mono. ¿Aún me calientas las sandalias?"], 66: ["{n}: monjes, templos... ¿alguien trajo antorchas?"]},
	"hideyoshi": {57: ["{n}, el que esperó. Ya veremos quién se sienta al final."], 62: ["{n}, mi querido administrador. Me trajo té tres veces. Se le perdona todo."], 55: ["{n}, mi señor... ¡qué recuerdos! Sandalias tibias."], 69: ["{n}. Lo vencí en Yamazaki. Fue un día de campo."], 60: ["{n}: llegó tarde y vestido de blanco. Qué dramático."]},
	"tokugawa": {58: ["{n}. Mikatagahara... mejor no hablemos del tema."], 56: ["{n}: el Mono. Me mandó a Edo. Y ahí me quedé. Gracias."], 62: ["{n}: te vi llegar a Sekigahara. Ya sabías cómo acaba."], 60: ["{n}: me caes bien... desde lejos."]},
	"shingen": {59: ["{n}. Si trae sal, que se la quede. Si trae sake, que pase."], 57: ["{n}: lo hice correr en Mikatagahara. Aún me río."], 55: ["{n}: me teme. Sé que me teme."]},
	"kenshin": {58: ["{n}, mi rival favorito. Nos vemos otra vez... con respeto."], 55: ["{n}: arderá como arde un bosque seco. Que no se acerque a Echigo."]},
	"masamune": {56: ["{n}: llegué tarde a su fiesta, es verdad. Pero lo hice con estilo."], 57: ["{n}: el que ganó al final. Qué paciencia, qué aburrimiento."], 62: ["{n}: tan serio. ¿Nadie le dijo que hay sake?"]},
	"tenzo": {55: ["{n}: arrasó Iga. Los ninja no olvidamos... ni perdonamos."], 57: ["{n}: cruzó Iga huyendo, con nuestra ayuda. Y nadie nos agradeció."]},
	"mitsunari": {57: ["{n}: Sekigahara... mejor no hablemos de mi cuenta de resultados."], 56: ["{n}: mi señor. Todo lo que soy, se lo debo. Y el té."], 15: ["{n}: el ronin más valiente. Me cae bien."]}}
## Líneas cuando sale la carta del propio personaje: "me" = la juegas tú, "foe" = el rival.
const CAMEO_SELF := {
	"nobunaga": {"me": ["¡Otra vez sin mí no sabes ganar! Así me gusta: dependiente.", "Me bajas porque sabes que arde mejor con fuego."], "foe": ["¿Mi carta en manos del rival? Cuida el castillo: voy a visitarlo."]},
	"hideyoshi": {"me": ["¡Veo que de nuevo no podías abordar esta batalla sin mí, jugador!", "Trepé de sandalias a Regente. Tú de mano a campo: bienvenido."], "foe": ["Esa soy yo... pero con otro jefe. Un ascenso doble."]},
	"tokugawa": {"me": ["La paciencia paga: me dejaste para el final y llegué igual.", "Me bajaste. No me apuro. Pero ya estoy aquí."], "foe": ["Mi carta en la mesa del rival. Esperaré, claro."]},
	"shingen": {"me": ["¿Necesitas al Tigre de Kai? Está bien, pero no me mires tanto el abanico.", "Rápido como el viento... y tú llamándome tarde."], "foe": ["Que el rival me use es un honor. Y un error."]},
	"kenshin": {"me": ["Bishamonten me mira y tú me bajas. Buen gusto, discípulo.", "¡Aquí está el Dragón de Echigo! Pero no traigo sal."], "foe": ["Mi carta con el rival... Que beba con honor."]},
	"masamune": {"me": ["¡Llegué! A tiempo esta vez. Tarde llegué a la historia, no a tu mano.", "Un ojo basta para ver que me necesitabas."], "foe": ["Ese dragón es mío, pero te lo presto. Sin garantía."]},
	"tenzo": {"me": ["Ya estoy aquí. Llevo un rato detrás de ti. Tranquilo.", "¿Me llamaste? Nunca te fallo... pero tampoco me ves."], "foe": ["Me usa el rival. Pronto cambiará de opinión."]},
	"mitsunari": {"me": ["Perfecto, es lo único que faltaba en el balance. Gracias por contar conmigo.", "Que quede en actas: pediste mi presencia y yo cumplí."], "foe": ["El rival me usa. Espero que sepa de contabilidad."]}}
## Líneas cuando sale un pariente o miembro de su clan: {n} = nombre de la carta.
const CAMEO_KIN := {
	"nobunaga": ["¡{n}! Sangre de mi sangre. Que arda con el resto.", "{n} entra en la mesa. Qué orgullo (y qué miedo)."],
	"hideyoshi": ["¡{n}! Parte de mi dinastía. Al menos esta carta me hace honor.", "{n} ha entrado. Mi castillo de oro se alegra."],
	"tokugawa": ["{n}, de los míos. Calma, que el tiempo juega a favor.", "{n} se une. Siempre hay lugar para la paciencia."],
	"shingen": ["{n} se baja. Ese es de mi caballería, no lo olviden.", "¡{n}! Que el viento y el fuego lo acompañen."],
	"kenshin": ["{n} está de mi lado. Que la justicia lo guíe.", "Mi gente, {n}, a la batalla. Con honor, por favor."],
	"masamune": ["{n}, de mi clan. Estilo Date, siempre.", "¡Ahí viene {n}! Que lo vean bien: somos elegantes."],
	"tenzo": ["{n} se aparece. Ninja de mi gente. Nadie lo oyó llegar.", "{n} está en el campo. Tranquilos, no lo van a ver."],
	"mitsunari": ["{n}, un ronin. Pagan poco, pero pelean bien.", "{n}: hay que anotar su paga. Honor, 1."]}

var _cameo_turn := -99
var cameo_count := 0
var _cameo_ids := {}

## Reacciona a que una carta entra en juego. Devuelve true si algún personaje salió a comentar.
func cameo(card_id: int, card_name: String, mine: bool, turn: int) -> bool:
	if _cameo_ids.has(card_id) or cameo_count >= 12 or turn - _cameo_turn < 2 or _timer.time_left > 0.0:
		return false
	var cands: Array = []
	for who in CARD_OF:
		if CARD_OF[who] == card_id:
			cands.append([who, CAMEO_SELF[who]["me" if mine else "foe"]])
		elif RIVAL_LINES[who].has(card_id):
			cands.append([who, RIVAL_LINES[who][card_id]])
		elif KIN[who].has(card_id):
			cands.append([who, CAMEO_KIN[who]])
	if cands.is_empty():
		return false
	# solo cartas «de personaje» propias o parientes: prioriza al dueño de la carta
	cands.sort_custom(func(a, b): return int(CARD_OF[a[0]] == card_id) > int(CARD_OF[b[0]] == card_id))
	var pick: Array = cands[0] if CARD_OF.get(cands[0][0], -1) == card_id else cands[randi() % cands.size()]
	var line: String = pick[1][randi() % pick[1].size()].replace("{n}", card_name)
	_cameo_ids[card_id] = true
	_cameo_turn = turn
	cameo_count += 1
	_show(pick[0], line, CARD_OF[pick[0]] == card_id and mine)
	return true
