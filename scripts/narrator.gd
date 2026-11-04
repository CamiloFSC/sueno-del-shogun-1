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
