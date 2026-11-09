# Sueño del Shogun — Especificación de reglas para el motor (v0.1)

Fuente: Reglamento_del_juego_SdelShogun.pdf + planilla de cartas corregida.
Alcance del prototipo: **90 cartas** (54 guerreros, 13 daimyos, 23 acciones Bushi). Las 9 cartas "Disponible"/"CAMBIAR" quedan fuera: Terumoto (63), Yoshimoto (67), Conspiración (70), Deshonor (73), El Nakasendo (75), Intriga (76), Rectitud Zen (78), El camino (81), Coraje (93).

## 1. Objetivo
Dos jugadores. Gana quien destruye el castillo rival: el castillo son 7 cartas; cada vez que un jugador "roba del castillo" pasa una carta del castillo a su mano. Pierde quien roba 7 cartas del castillo (castillo vacío) **o** quien se queda sin cartas en el mazo.

## 2. Tipos de carta
- **Guerrero**: ataque (1-4), costo de Honor, clan, efecto con frecuencia. Si muere, su dueño roba 1 carta del castillo.
- **Daimyo**: igual que guerrero, pero si muere el dueño roba **2** del castillo. (Costo 4.)
- **Bushi (Acción)**: efecto rápido, se descarta tras usarse. Puede jugarse al instante o colocarse **boca abajo** en uno de los 2 espacios laterales del guerrero activo (prioridad máxima en batalla). Algunas tienen "Efecto Giratorio": solo funcionan si están boca abajo.

## 3. Frecuencia del efecto (columna Duración)
| Letra | Significado |
|---|---|
| A | Una vez durante tu turno |
| B | Una vez durante tu batalla |
| C | Cuando entra en juego |
| D | Durante tu turno (efecto continuo) |

## 4. Zonas (por jugador)
1. Mazo  2. Pozo de descarte  3. Zona activa: 1 guerrero/daimyo central + 2 espacios para Bushi boca abajo  4. Zona pasiva: hasta 6 guerreros esperando  5. Castillo: 7 cartas  (+ zona de Honor).

## 5. Inicio de partida
Cada jugador roba 7 cartas a la mano y coloca 7 cartas del mazo como castillo.

## 6. Turno
1. Genera +1 de Honor.
2. Roba 1 carta.
3. Puede bajar un guerrero boca arriba pagando su costo de Honor. Si no tiene ninguno en juego, debe bajarlo a la zona activa.
4. Puede jugar cartas Bushi (inmediata o boca abajo).
5. Fase de batalla: ataca al guerrero activo rival **o** al castillo rival.
   - Contra el castillo: el defensor decide si opone resistencia con su guerrero (→ batalla) o deja pasar el ataque (→ roba 1 carta del castillo; ver carta Sasuke).
   - Contra el guerrero: batalla obligatoria.
6. Fin de turno. Máximo 7 cartas en mano: se descarta el exceso.

## 7. Batalla
- Se calcula el daño total de cada guerrero. Se juegan primero las cartas boca abajo (prioridad máxima) y luego Bushi desde la mano.
- Mayor daño final gana y se queda. El perdedor muere: su dueño roba 1 carta del castillo (2 si es daimyo) y el guerrero va al pozo.
- Salvar a un guerrero: antes de morir, su dueño puede robar 1 carta extra del castillo para salvarlo (1 sola vez por personaje). *(mecánica exacta por confirmar)*
- Empate: ambos mueren y cada jugador roba 1 del castillo.

## 8. Decisiones confirmadas (20-oct)
- **Duelo de dados**: cada guerrero tira tantos dados como su Ataque (más/menos por efectos). Gana el total más alto. Empate: se repite el lanzamiento. "+5 a 1 dado" = suma 5 puntos al total.
- **Honor**: +1 al inicio de cada turno y se acumula (sin tope por ahora).
- **Mazo**: 50 cartas, máximo 3 copias de cada una.
- **Zonas**: 1 guerrero activo + máximo 3 pasivos. (Se cambió de 6 a 3.)
- **Ejércitos eliminados**: hay que reescribir las cartas 32, 52 y 58.
- **Efecto Giratorio**: se activa solo con la carta boca abajo, a izquierda o derecha del activo. Falta definir qué Bushi lo tienen.

## 9. Supuestos del prototipo (confirmar)
- Se pueden bajar hasta 4 guerreros por turno, limitados solo por el campo (1 activo + 3 pasivos) y por el Honor. Un guerrero pasivo pasa a activo solo al inicio del turno de su dueño, si no tiene activo.
- Atacar termina el turno. Ataque al castillo sin resistencia = el defensor roba 1 del castillo.
- Cartas de costo 4 Ninja/Ronin (61, 62, 69) tratadas como Daimyo.
- Quien parte lo decide el azar y también roba en su primer turno.
- Salvar a un guerrero robando una carta extra: aún no implementado.

## 10. Pendientes
- Reescribir 32, 52, 58 (sin ejércitos); definir Bushi con Efecto Giratorio; reglas de la zona pasiva→activa.

## 11. Efectos "al entrar en juego" (C) implementados (21-oct)
Revancha (3), Hattori Hanzo (7), Shibata Katsuie (20), Yoshihisa (40), Yoshizane (45), Tadamune (47), Kenshin (59), Akechi Mitsuhide (69).
Pendiente: Morichika (52) depende de "ejército" (reescribir).
Supuestos: "guerrero" incluye daimyos; al recoger del pozo se elige la carta de más ataque; Akechi toma el daimyo activo rival (si no, el primer pasivo) y exige que su castillo tenga más de 2 cartas; Kenshin descarta 3 automáticamente antes de revolver.

## 12. Ventana de decisión y efectos de batalla (21-oct)
**Regla de diseño:** ningún efecto decide por el jugador. Todo lo que implique elegir (cartas, objetivos, números, sí/no) abre la ventana de decisión. Solo es aleatorio lo que la carta dice que es aleatorio (Saizo, dados). Si no hay nada que decidir (ej. hay que elegir 5 de 5 cartas, o no hay opciones) el efecto se resuelve solo. La IA responde con su propio criterio.

Decisiones ya conectadas: Reiki, Reflexión y justicia, Revancha, Hattori Hanzo (sí/no), Shibata Katsuie, Yoshihisa, Yoshizane, Kenshin, Akechi Mitsuhide (qué Daimyo), Kosaka, Sanada Yukimura, Katsuyori (número), Motonari, Miyoshi (ver mano rival), Kage Katsu.

Efectos de batalla (B) implementados: 1, 2, 4, 5, 6, 8, 10, 13, 14, 15, 16, 17, 21, 23, 24, 26, 27, 28, 29, 30, 31, 34, 37, 38, 39, 41, 42, 43, 44, 46, 53, 60, 61, 65 (+ 54 Kunichika).
Sin implementar aún: Kotaro (9), Nobutaka (19), Nabe Kanetsugu (33), Terumune (48) y el resto de efectos de tipo A y D.

### Interpretaciones a confirmar
- **Anayama (30):** el texto está cortado en la planilla ("...más cartas en tu castillo, que t"). Se asumió "que tu oponente" → +1 dado.
- **Kosaka (6):** "Descarta 2" es obligatorio al entrar en duelo (si ambas son Ninja, +5 puntos a la tirada).
- **Sanada (15):** opcional, al atacar: descarta 2 cartas para sumar 4 dados.
- **Kage Katsu (31):** cada vez que alguien juega un Bushi en el duelo, el rival del dueño de Kage descarta 1 carta (la elige él).
- **Kobayakawa (39):** cuenta los Bushi jugados por ese jugador durante el turno.
- **Nobutaka (19) y Nabe (33)** dependen de cartas boca abajo (efecto giratorio), aún no implementado.

## 13. Efectos tipo A y D (22-oct)
**Tipo A (una vez por turno)** se usan desde el botón «★ Habilidades» (turno propio, fase principal). Cada una pide sus decisiones en la ventana. Implementadas:
Toshie (11, ordenar 3 del mazo), Pirata Wokou (12, revive del pozo pagando su costo), Akachi Morichige (18, con la mano vacía recoge un Ronin), Rukkaku Yoshikata (49) y Yoshiaki (50) (generan Honor con otros miembros Ashikaga), Yoshiharu (51, nombra un clan: cuesta +1 el próximo turno rival), Oda Nobunaga (55, roba 3 y puede descartar 3 por 3 de Honor), Ieyasu (57, paga 1 Honor y busca una carta), Mitsunari (62), Motochika (64, cambia una carta de la mano por una del castillo), Sakai Tadatsugu (25, reduce 1 el costo del Daimyo Tokugawa).
**Tipo D (durante tu turno)** son continuos: Yogidomi (22, tus guerreros cuestan 1 menos en tu turno, mínimo 0), Kenyo (66, +3 Honor al terminar tu turno si no atacó), Yoshiteru (68, duplica Ceremonia del té, Reparadores y Destino del clan).
Acción nueva: **Destino del clan (74)**.

### Siguen sin implementar (5 cartas A/D)
- **Kakizaki Kageie (32)** y **Shingen (58)**: mencionan "ejércitos" (eliminados). Hay que reescribir el texto.
- **Rennyo (35)** y **Sensei de Enryaku-Ji (36)**: dependen de la acción Complejo Enryaku-Ji (90), aún sin implementar.
- **Hidetoshi (56)**: "Modifica el resultado de un dado" necesita definir la regla exacta.
- También pendientes: Kotaro (9), Nobutaka (19), Nabe (33), Terumune (48), Morichika (52) y 12 acciones Bushi (77, 80, 82, 85, 86, 87, 89, 90, 92, 96, 97, 98).

## 14. Hidetoshi implementado; propuestas para las cartas con "ejército" (23-oct)
**Hidetoshi (56), tipo A, Daimyo Toyotomi:** una vez por turno, en un duelo de TU turno, después de tirar los dados y antes de decidir el ganador, puedes elegir 1 dado (tuyo o del rival) y poner en él el valor que quieras (1 a 6). Funciona estando en la zona activa o pasiva. No se ofrece en el turno del rival. La IA solo lo usa si con eso gana el duelo.
Detalle del motor: el duelo ahora tiene una pausa entre "tirar" y "decidir" (`Effects.post_roll_steps`), reutilizable para otros efectos que cambien tiradas.

**Propuestas pendientes de aprobación** (no implementadas):
- **Kakizaki Kageie (32, A):** "Una vez por turno: si tienes otro guerrero del clan Uesugi o Ikko Ikki en juego, Kakizaki tira 1 dado extra."
- **Shingen (58, D):** "Durante tu turno, tus guerreros del clan Takeda cuestan 1 Honor menos (mínimo 0)."
Aún sin implementar de A/D: Rennyo (35) y Sensei de Enryaku-Ji (36), que dependen de la acción Complejo Enryaku-Ji (90).

## 15. Kakizaki, Shingen y acciones Bushi (23-oct)
**Textos aprobados (actualiza también tu planilla Excel):**
- **Kakizaki Kageie (32, A):** "Si tienes otro guerrero del clan Uesugi o Ikko Ikki en juego, Kakizaki tira 1 dado extra." Se aplica en el duelo donde Kakizaki pelea (atacando o defendiendo); como cada turno tiene un solo duelo, equivale a "una vez por turno". El bono es +1 aunque haya varios.
- **Shingen (58, D):** "Durante tu turno, tus guerreros del clan Takeda cuestan 1 Honor menos (mínimo 0)."
- **Reiki (79):** ahora dice "Bota 5 cartas de tu mano y +2 de Honor" (ya estaba en el CSV; falta en el Excel).

**Acciones implementadas (todas abren la ventana de decisión):**
- **El maestro estratega (82):** eliges X cartas de tu mano (de 0 a todas), van al final del mazo y robas X.
- **Hansei (85) / Kansei (86):** descartas 3 / 4 cartas y bajas gratis un guerrero de coste 2 / 3 de tu mano (eliges cuál, y luego qué descartar). Bajarlo así **no gasta tu "guerrero del turno"** y activa los efectos "al entrar en juego". Hay que tener lugar en tu zona.
- **Musha Shugyo (87):** solo en un duelo y solo si peleas con un Ronin. Eliges cuántas cartas de tu mano descartar; por cada **Ronin** descartado, +1 de ataque (dado), máximo 7.
- **Matrimonio arreglado (92):** requiere 3 héroes en juego de distinto clan. Descartas esos 3 (si tienes 4 eliges cuáles), luego descartas X cartas de tu mano y generas X de Honor. Tu Honor total no puede pasar de 6.
- **Lealtad (97):** nombras un clan (sin Ninja ni Ronin). Si los próximos 3 héroes que bajas desde la mano son de ese clan, generas 3 de Honor; si bajas uno de otro clan, el compromiso se pierde. Puedes tener varias abiertas.

**Supuestos a confirmar:**
- "Ninja" y "Ronin" cuentan como clanes distintos para Matrimonio arreglado.
- Si descartas a tu guerrero activo con Matrimonio, el siguiente pasivo solo pasa a activo al inicio de tu próximo turno (tu castillo queda sin defensor ese turno).
- Lealtad cuenta héroes bajados con coste normal, Hansei y Kansei; no cuenta el daimyo robado por Akechi.
- La IA no usa Matrimonio arreglado (desarma su propio tablero) y solo usa Lealtad si tiene 3 héroes del mismo clan en la mano.

## 16. Cartas boca abajo, fichas, Dilema y Complejo Enryaku-Ji (24-oct) — confirmado por ti

**Cartas giratorias (columna `giratorio` del CSV: hoy 96 y 98; edítala si cambia).** Al hacer clic en ellas en tu turno se colocan boca abajo (máx. 2, "una a cada lado" del activo). Cuentan como un Bushi jugado (Junyo). No se activan a mano: se revelan solas.
- **Cortesía (96):** cuando un héroe tuyo muere en duelo, recibes su coste de Honor. Se revela y va al pozo.
- **Muerte Honorable (98):** si pierdes un duelo por **más de 2 puntos de diferencia**, +3 Honor. Si la diferencia es 2 o menos, sigue boca abajo.
- **Liderazgo (77):** carta normal (mano, en tu turno o en ventana de batalla). Requiere 2 héroes tuyos del mismo clan (Ninja y Ronin cuentan como clan propio) y que el rival tenga cartas boca abajo; eliges **a ciegas** cuál destruir (izquierda/derecha).
- **Nobutaka (19):** al entrar en duelo puedes robar 1 por cada carta boca abajo tuya (te pregunta).
- **Nobutada (21):** +1 dado solo si no tienes cartas boca abajo.
- **Nabe (33):** mientras sea el activo del rival, este no puede colocar cartas boca abajo. *(Interpretación: no afecta a las ya colocadas. ¿Quieres que también las silencie?)*

**Castillo de montaña (89):** pones hasta 2 cartas de lo alto de tu mazo como fichas "Soldado del castillo" (1/1 Ronin, sin efecto). Pueden ser el activo y ocupan espacios pasivos (entran las que quepan). Al morir, la carta real va al pozo boca arriba, cuentan como guerrero derrotado (roban del castillo, Cortesía da 1 Honor, Toshihisa suma).

**Dilema del cucu (80):** nombras un clan; todos tus héroes (guerreros y daimyos, salvo Ninja y Ronin) pertenecen a ese clan **hasta el final del turno** (constante `Effects.DILEMA_PERMANENT` para volverlo permanente). Se puede jugar en tu turno o en una ventana de batalla.

**Terumune (48):** si el Daimyo Date (60) está en juego, Terumune recibe +2 dados en vez de +1.

**Complejo Enryaku-Ji (90):** queda en juego (no va al pozo); uno por jugador. Se usa desde "★ Habilidades":
- *Enviar un héroe al Complejo:* sale de su zona; no ataca ni defiende. Capacidad 1 (+1 con Rennyo en juego). Vuelve tras **2 finales de tus turnos** con **+1 de ataque permanente**; con Sensei (36) dentro, Ikko Ikki y Uesugi reciben **+2**. Vuelve a activo/pasivo si hay lugar, si no a la mano.
- *Descartar tu Complejo:* los héroes vuelven sin bono.
- *Destruir el Complejo rival:* pagas 5 de Honor en tu turno; sus héroes vuelven a su zona.
- Si Rennyo se va, los miembros sobrantes vuelven a la mano. Kenyo (66): +3 Honor al final de tu turno si no atacó **o** está en el Complejo.
- Limitación: el ataque permanente se guarda por carta, no por copia (si juegas dos copias iguales comparten el bono).

**Aún sin implementar:** Kotaro (9; propuesta: copia el efecto de batalla de hasta 2 Ninja en juego) y Morichika (52, hay que reescribirlo porque mencionaba ejércitos).

## 17. Menú y constructor de mazos (24-oct)
- La pantalla inicial ahora es un menú: **Jugar contra la IA**, **Constructor de mazos**, **Salir**. Dentro de la partida, el botón ☰ vuelve al menú.
- **Mazos:** exactamente 50 cartas, máx. 3 copias de cada una (estricto: no se puede guardar ni jugar un mazo incompleto). Se guardan en el archivo `mazos.json` de la carpeta de datos del usuario de Godot.
- **7 mazos temáticos prearmados** (`DeckStore.PRESETS`): Sombras Ninja, Espadas Ronin, Kai contra Echigo, Templo de Enryaku-Ji, Unificadores, Alianza del Oeste, Casa y Trono. Se pueden elegir para ti o para el rival, o cargarlos en el constructor como base para modificarlos.
- Las cartas sin efecto implementado (Kotaro, Morichika) aparecen marcadas "(sin efecto)"; "Completar al azar" solo usa cartas que ya funcionan.
- Pruebas: `tests/test_decks.gd` (validación, guardado y 294 partidas IA vs IA con los mazos temáticos).

## 18. Kotaro y Morichika (25-oct) — SdS1: 90 de 90 cartas funcionando
- **Kotaro (9):** cuando ataca, eliges hasta 2 Ninja en tu zona de juego y copia su efecto de batalla (Saizo, Sasuke, Sin Honor, Mochizuke, Kosaka, Tenzo, Momochi). Los efectos con decisión (Kosaka) abren su propia ventana. Solo al atacar, no al defender. Sasuke copiado en un ataque al castillo sin defensor hace robar 2.
- **Morichika (52):** entra sin pagar Honor si tienes en juego un Ronin con "Pirata" en su nombre (hoy: Pirata Wokou).
- Confirmados por ti: Anayama Baitetsu (30) y Dilema del cucu (80) quedan como están.
- Pendientes: las 9 cartas finales (ids 63, 67, 70, 73, 75, 76, 78, 81, 93) hasta llegar a 99; en el Excel solo tienen nombre y falta su efecto.

## 19. Cartas de dados: 70, 73, 75, 76, 78 (25-oct) — 95 cartas
**Ventana posterior al lanzamiento (nueva):** después de lanzar los dados (y de Hidetoshi), si alguno de los dos jugadores tiene en la mano una carta de dados jugable, se abre una ventana: primero el atacante, luego el defensor; quien no tiene una carta jugable pasa solo. Cuando ambos pasan, se decide el duelo. Si nadie puede jugar nada, el duelo sigue sin pausas.
- **Conspiración (70):** repite el lanzamiento de un dado, tuyo o del rival (eliges cuál; sale un valor nuevo al azar).
- **Intriga (76):** fijas un dado (tuyo o del rival) en 3.
- **Deshonor (73):** pagas 1 de Honor; cada dado del rival baja 1 punto. *Supuesto: un dado nunca baja de 1.*
- **El Nakasendo (75):** en tu turno, solo con 3 cartas o menos en la mano (contándola): lanzas un dado y robas esa cantidad de cartas.
- **Rectitud Zen (78, primera línea):** antes de lanzar, en un duelo: el primer dado de tu próximo lanzamiento vale 6. *Supuesto: afecta tus dados y solo al primer lanzamiento (no a los re-lanzamientos por empate).*
- **Corrección posterior (confirmada por ti):** la línea "el próximo lanzamiento vale 6" es **El camino (81)**, no Rectitud Zen.

## 20. Últimas cartas: 78, 81, 93, 63, 67 — SdS1 completo: 99 de 99 (25-oct)
- **Rectitud Zen (78):** antes de lanzar, en un duelo: se anulan todas las modificaciones de esta batalla. Cada guerrero lanza solo los dados de su carta (sin bonos de efectos, Bushi previos, ataque permanente ni Sessai Choro), y los efectos de inicio de batalla (Kosaka, Saizo, Kotaro…) no ocurren. Las cartas jugadas después de ella sí cuentan. Una vez por batalla. *Supuesto: no cambia el valor de los dados ya lanzados (Hidetoshi, Intriga, etc.).*
- **El camino (81):** el primer dado de tu próximo lanzamiento vale 6 (antes lo tenía el 78).
- **Coraje (93):** antes de lanzar: si tu Daimyo activo está solo en tu zona (sin pasivos), +2 dados.
- **Terumoto (63, Daimyo Mori, tipo B)** — *propuesta mía*: +1 dado por cada otro guerrero Mori en juego (máx. 2).
- **Yoshimoto (67, Daimyo Imagawa, tipo A)** — *propuesta mía*: una vez por turno, paga 2 de Honor para recoger un guerrero Imagawa de tu pozo a tu mano.

## 21. Imágenes de cartas (25-oct)
- `CardArt` carga imágenes sueltas en **jfif, jpg, jpeg, png o webp** (detecta el formato por el contenido, no por la extensión). Las grandes se reducen a 700 px de alto al cargar.
- Carpetas donde busca: `assets/cartas/`, una carpeta `cartas/` junto al juego (o junto al ejecutable) y `user://cartas/`.
- El nombre del archivo debe **empezar con el número de la carta** (`5.jfif`, `05.jfif`, `12 Pirata Wokou.jfif`) o ser el nombre de la carta (`saizo.jfif`).

## 22. Mejoras de interfaz (25-oct)
- **Harakiri:** botón en la barra de acciones (al pasar el mouse dice «¡Rendirse con Honor!»), pide confirmación y hace perder la partida (`Game.surrender`).
- **Columna derecha:** solo el registro de la partida, los marcadores de Honor, el mensaje de estado y los dados; la descripción de la carta se ve en la vista ampliada al pasar el mouse.
- **Cartas más grandes:** 185 px de alto en el tablero y 180 en la mano. Las zonas con muchas cartas tienen scroll horizontal.
- **Fondo:** `assets/fondo.jpg` en el tablero y el menú, con paneles translúcidos para que se lea.
- **Sonidos** (`assets/sonidos/*.wav`, generados; puedes reemplazarlos por los tuyos con el mismo nombre): dados al lanzar, espadas al empezar una batalla, barajar (inicio, búsquedas en el mazo), robar, descartar, aviso de descarte, efecto giratorio, victoria y derrota. Botón «Sonido: sí/no».
- **Aviso de descarte:** panel con exclamación y mano cuando tienes más de 7 cartas.
- **Victoria / Derrota:** pantalla grande al terminar, con opciones Nueva partida, Menú o Ver el tablero.
- **Ver el tablero** dentro de una ventana de decisión, con botón «Volver a la decisión».
- **Mensaje emergente** «¡Efecto giratorio!» cuando se revela Cortesía, Muerte Honorable o se destruye una carta boca abajo con Liderazgo.
- **Aumentos de daño:** el guerrero activo muestra una insignia ⚔ con los dados reales que lanza ahora (verde si hay aumento, rojo si baja), actualizada con cada efecto. *Interpretación mía de «actualización de los aumentos de daño»: confírmame si querías otra cosa.*

## 23. Mazos, pozos de descarte y movimiento de cartas

- A la izquierda de la zona de cada jugador (y del rival) hay un **MAZO** (reverso, con la cantidad de cartas) y un **POZO** (muestra la última carta descartada y la cantidad). Hacer clic en un pozo abre un visor con todas las cartas descartadas (la más reciente primero).
- Animaciones (0,5 s, escalonadas): **a)** mazo → mano al robar; **b)** campo → pozo cuando un guerrero es derrotado en batalla; **c)** castillo → mano al robar del castillo. También vuela al pozo toda carta descartada de la mano.
- El motor solo registra los movimientos en `g.moves` (`{k, p, id}`) cuando `g.sfx_enabled` es verdadero; las simulaciones no acumulan nada. Tipos: `deck_hand`, `castle_hand`, `field_discard`, `hand_discard`.
- Código: `scripts/pile_view.gd`, `Main._play_moves`, `Main._fly`, `Main._open_pile`.

## 24. Cambio de rol (activo ↔ pasivo)

Una vez por turno, en la fase principal y antes de atacar, un guerrero de la reserva pasiva toma el rol activo; el activo anterior ocupa su lugar en la reserva. Botón «Cambiar activo» (abre ventana de decisión). La IA lo usa si un pasivo tiene más ataque que su activo. Código: `Game.can_swap_active`, `swap_active`, `open_swap`.

## 25. Zoom de cartas

Al pasar el mouse sobre cualquier carta aparece un botón «Zoom» con una lupa. Al hacer clic, la carta se muestra a pantalla completa (con su imagen; sin imagen, con nombre y efecto en grande). Se cierra con clic o Esc. Código: `Main._build_zoom`, `_zoom_show`, `_open_zoom`, `scripts/magnifier_icon.gd`.

## 26. Escena 2D del duelo (nivel 1)

Cuando dos guerreros se enfrentan, tras decidirse el duelo se muestra una escena a pantalla completa: las dos cartas entran, aparecen los dados y totales, chocan (destello, temblor, sonido de espadas), el ganador golpea y el perdedor se tiñe de rojo, se rompe en chispas y se desvanece («¡DERROTADO!» / «¡GANA!»). Dura ~4 s; un clic la salta. Botón «Duelo 2D: sí/no» en la columna derecha para desactivarla. Es solo presentación: el motor ya resolvió el duelo (evento `duel` en `g.moves`), y la IA espera a que termine (`duel_busy`). No se muestra en simulaciones ni en modo headless. Código: `scripts/duel_scene.gd`, `Main._play_duel`. Nivel 2 (golpes distintos por clan) queda para una versión sucesiva.

## 27. Ataque directo al castillo (escena) y fuente de la interfaz

- **Escena de ataque al castillo:** cuando un ataque al castillo no es resistido (sin defensor o el defensor no resiste), se muestra una escena: el atacante embiste el castillo, cada carta perdida cae con destello, chispas y «−1», y aparece el resultado («−N cartas del castillo» o «¡Castillo destruido!»). Evento `castle_hit` en `g.moves`; código `scripts/castle_hit_scene.gd` (hereda de `DuelScene`). Se desactiva con «Duelo 2D: no»; un clic la salta.
- **Fuente:** `UiFont` busca `.ttf/.otf` en `assets/fuentes/` (o `fuentes/` junto al ejecutable) y la aplica a todo el juego; prefiere un archivo con «harukaze» en el nombre. Los caracteres que falten se completan con la fuente por defecto.

## 28. Dados en la escena del duelo

En la escena 2D del duelo los dados son co-protagonistas: aparecen en primer plano bajo cada carta, caen rodando y girando (la cara cambia hasta quedar en el valor real), y bajo ellos se muestra «Total N» (con los puntos fijos entre paréntesis). Si hay muchos dados se achican y pasan a varias filas. Al decidirse el duelo, los dados del ganador se tiñen de oro y crecen; los del perdedor se apagan. Código: `scripts/big_die.gd` (clase `BigDie`) y `scripts/duel_scene.gd`.

## 29. Corrección: varios guerreros por turno y Kotaro

- Se eliminó el tope de «1 guerrero por turno»: ahora se pueden bajar hasta 4 en el mismo turno, limitados solo por el campo (1 activo + 3 pasivos) y por el Honor disponible. La IA también lo aprovecha.
- Kotaro (9) copia el efecto de batalla de hasta 2 Ninja **en juego** cuando él es el guerrero activo y ataca. Antes no se podía bajar otro Ninja el mismo turno, lo que impedía usarlo. Si no hay Ninja aplicable, el registro lo avisa. En un ataque directo al castillo solo cuenta Sasuke (hace robar 2).

## 30. Galería de cartas, zoom en el editor y Campaña Histórica

- **Menú principal (orden):** Modo Campaña Histórica · Jugar contra la IA · Constructor de mazos · Galería de cartas · Salir.
- **Galería de cartas:** las 99 cartas en miniaturas grandes (con su número y ✔/✘ de si funcionan), con buscador (nombre, clan o número) y filtro por tipo o «solo las que NO funcionan». Al hacer clic se abre el **visor** a pantalla completa: imagen grande, encabezado (número, tipo, clan, ataque, honor, frecuencia), estado «FUNCIONA / NO FUNCIONA», el **texto de la carta** y **cómo lo interpreta el juego** (`data/detalles.csv`, una línea por carta, editable). Navegación con ◀ ▶ o las flechas del teclado; Esc cierra. Es la herramienta para la revisión final imagen ↔ efecto antes del ejecutable. Código: `CardViewer`, `CardInfo`.
- **Constructor de mazos:** botón «Zoom» (con lupa) en cada carta del catálogo y del mazo, que abre el mismo visor y permite recorrer la lista; selector **Orden: Clan y categoría / N° de colección**; las filas muestran el número de la carta.
- **Campaña Histórica** (`CampaignStore`, `CampaignMap`, progreso en `user://campana.json`): 7 puntos que se desbloquean al ganar. Orden: 1 Sombras Ninja · 2 Espadas Ronin · 3 Kai contra Echigo · 4 Templo de Enryaku-Ji · 5 Casa y Trono · 6 Alianza del Oeste · 7 Unificadores. Al hacer clic en un punto se elige tu mazo (o al azar) y se comienza el duelo contra el mazo temático correspondiente. Al ganar se desbloquea el siguiente punto; al perder (o rendirse) se puede reintentar. Los duelos ganados se pueden repetir. Botón «Reiniciar campaña». Textos de lugar/trama de cada duelo: propuestos por Claude, editables en `CampaignStore.LEVELS`.
- Pruebas: `tests/test_menu.gd` (23).

## 31. Revisión imagen vs. juego (lote 1)
La imagen manda sobre el juego. Aplicado: Honor 5 en los 14 Daimyo (55-60, 62-69); ids 53/54 intercambiados (53 Kunichika, 54 Motoyama Boku, Honor 4); 61 = Watanabe Tenzo; stats de 4, 24, 50, 51, 52, 63; Saizo (descarta solo si mata), Hanzo (roba hasta 7), Terror 7 Mares (sin clan, máx. 4), Sanada (al recibir ataque), Yogidomi (solo Toyotomi), Katsuyori (+7), Kage Katsu (descarta quien usa el Bushi), Reiki (3 cartas); efectos de 78/81 intercambiados.
Pendiente (depende de Ejércitos, que fueron eliminados, o requiere decisión): 9 Kotaro (ninjas de la mano), 32, 52, 58, 63, 67, 93 (Ejércitos), 56 (turno rival), 61 (efecto nuevo), 72, 94 (un solo dado), 69 («guardia»), giratorias 72/73/81/96/98.

## 32. Lote 2 (decisiones del autor)
Kotaro copia de la MANO (2 Ninja distintos). Watanabe Tenzo (61): habilidad A «roba 1 carta extra» y +1 dado a todos tus Ninja en duelo. Akechi (69): el Daimyo robado entra a la zona de pasivos («en guardia»; si está llena, al pozo). Dominio de sí mismo (72, x3) y Honestidad (94, x2) se juegan DESPUÉS de lanzar y afectan UN dado tuyo elegido. Hideyoshi (56): solo en tu turno. Dificultad (GameConfig.difficulty, Game.ai_level): 0 Fácil (la IA no usa Bushi ni habilidades), 1 Normal, 2 Difícil (mazo temático fuerte), 3 Pesadilla (además, cada turno la IA roba 1 carta y gana 1 Honor extra, y lo anuncia en el registro). Menú: «Aprender a Jugar» (guide_pages.gd) enlaza cartas de la Galería.
Pendiente: cartas giratorias 72/73/81 (¿cuándo se revelan?) y 96/98.

## 33. Arte del autor integrado
assets/fondos (4 estaciones x campo/castillo; selector «Fondo» en Jugar y en el duelo de campaña; el tablero usa el campo), assets/castillo (7 etapas: el castillo cambia al perder cartas en el ataque directo), assets/personajes (poses alternativas de Daimyo 55, 56, 57, 58, 59, 62 que aparecen al ganar un duelo; shogun.png al completar la campaña; creador.png). Todo mediante ExtraArt (extra_art.gd).

## 34. Tutorial, créditos y fuente
Menú: «Tutorial rápido (1 minuto)» abre una partida guiada (tutorial_overlay.gd): 7 pasos de ~8,5 s con flechas sobre el tablero real; el jugador empieza (Game.first_player) y la IA va en nivel Fácil. «Créditos» muestra la imagen del Creador. Fuente de la interfaz: Shippori Mincho Bold (OFL) en assets/fuentes/ (si se agrega un archivo con «harukaze» en el nombre, tiene prioridad).

## 35. Campaña de 8 etapas y narrador
- Orden: 1 Kenshin vs Takeda (eliges aliado; el aliado te aconseja como sabio y el otro es el rival), 2 Masamune (Clan Date), 3 Tenzo (Sombras Ninja), 4 Mitsunari (Espadas Ronin), 5 Nobunaga (Clan Oda), 6 Hideyoshi (Clan Toyotomi), 7 Ieyasu (Clan Tokugawa), 8 El Creador (mejores cartas, IA en Pesadilla, hace trampa y se burla).
- Cada personaje comenta la partida con globos de cómic (`scripts/narrator.gd`); imágenes `assets/personajes/<nombre>_a|b|c|d.png` (a con fondo, b neutra, c/d gesto y cuarta pared).

## 36. Tope de Honor
El Honor de un jugador **nunca pasa de 7** (`Game.HONOR_MAX`). Todo el Honor ganado (turno, cartas Bushi, habilidades, Kenyo, etc.) pasa por `Game.gain_honor`, que recorta al máximo; el Honor que sobra se pierde.

## 37. Vigente desde el 6-nov (reemplaza lo anterior si se contradice)
- **Cartas**: 99 cartas + ficha 900 (el «90 cartas» de §0/§4 está obsoleto).
- **Prioridad en ventanas de batalla**: primero el ATACANTE y luego el defensor, alternando hasta que ambos pasen (la guía ya lo dice así).
- **Rectitud Zen (78)**: el primer dado de TU próximo lanzamiento vale 6 (no se repite en empates). **El camino (81)**: anula todas las modificaciones de dados de esa batalla y sus efectos de inicio; cada guerrero tira los dados de su carta; una vez por batalla. (§19-§20 los tenían al revés.)
- **Kage Katsu (31)**: descarta 1 carta quien usa el Bushi (no el rival que lo juega primero). §12 queda corregido.
- **Cartas giratorias** (96 Cortesía, 98 Muerte Honorable, 72 Dominio de sí mismo, 73 Deshonor, 81 El camino): solo funcionan boca abajo. Se colocan en la fase principal (máx. 2, cuenta como Bushi jugado; Nabe 33 lo impide). 96 y 98 se revelan solas al cumplirse su condición; 72, 73 y 81 las juega el dueño con un clic desde boca abajo en la ventana que corresponda (72 y 73 tras lanzar; 81 antes de lanzar) y van al pozo.
- **Sessai Choro (44)**: tira tantos dados como el luchador rival (ya descontado su dado menos) y al rival se le resta 1 dado.
- **Hideyoshi (56)**: el efecto vale solo en tu turno (decisión documentada; la imagen dice lo contrario y debe corregirse). Los mensajes dicen «Hideyoshi».
- **Honor máximo 7** (ver §36). **Mano máxima 7**: el Complejo Enryaku-Ji ya no puede devolver un guerrero a una mano llena; va al pozo.
- **Terror de los 7 mares (13)**: 1 dado y 1 de ataque (el CSV decía 2/2).
- **Equilibrio de mazos**: El Creador pasa a Oda+Toyotomi (19-24 ×3, 55/56 ×2 + Bushi); Oda, Toyotomi y Date recortados; Ronin, Alianza del Oeste y Casa y Trono reforzados con Coraje y menos cartas caras.
- **Pendiente de imagen** (la imagen manda, salvo estas): 98 → «más de 2 puntos de diferencia» + rótulo Giratorio; 56 → «solo en tu turno»; 84/99 sin «Ejército»; letras de 22/40/63.
- **Correcciones menores (6-nov)**: Kosaka (6) descarta 2 de forma OPCIONAL (0 o 2); Kotaro (9) copiando a Saizo (1) sí hace descartar al azar; Tachibana (14) suma +3 dados vs Ninja solo al ATACAR; Musha Shugyo (87) llega como máximo a 7 dados EN TOTAL; Complejo Enryaku-Ji (90): un guerrero solo gana +1 de ataque una vez; Ninjutsu (91) vence al terminar el turno.

## 38. Colección, sobres y efectos de carta (8-nov)
- **Pantalla de presentación** (`scenes/splash.tscn`, escena principal): logo `assets/logo.png` (temporal, reemplazable) y «Presiona cualquier botón para avanzar». Solo sale al abrir el juego.
- **Colección** (`user://coleccion.json`): se empieza con 17 cartas distintas, las del **Mazo inicial** (50 cartas, `CollectionStore.STARTER`). El editor de mazos, «Completar al azar», «Cargar como base», Jugar contra la IA y la campaña solo ofrecen cartas y mazos que el jugador tiene completos. La IA rival usa siempre mazos completos. En Jugar contra la IA ya no existe «Mazo al azar» para ti (sí para el rival).
- **Sobres**: la PRIMERA vez que ganas cada duelo de campaña recibes 1 sobre (se abre desde el cartel de victoria o desde «Abrir sobre» del menú). Contiene 2 guerreros, 2 acciones Bushi y 1 Daimyo; se prefieren cartas que aún no tienes y, si no quedan, salen repetidas. Las repetidas no dan nada.
- **Galería**: las cartas no obtenidas aparecen en blanco y negro, borrosas, con «?»; la búsqueda no las encuentra y no se pueden abrir. Botones de prueba 🔓 Todas / 🔒 Reiniciar.
- **Holográfico** (`assets/shaders/holo.gdshader`, `CardFx.HOLO` = Daimyos 55-60): arcoíris, destello y chispas en galería, visor y apertura de sobres (en el visor sigue al ratón).

## 39. Teclado y mano en abanico (9-nov)
- **Ventana de decisión**: las opciones van en una rejilla fija (antes un HFlowContainer dentro de un scroll dejaba zonas sin respuesta al clic).
- **Mano en abanico** (`FanHand`): las cartas se abren como en una mano real; la carta bajo el ratón (o elegida con el teclado) se levanta, crece y queda por encima, con el botón Zoom.
- **Teclado**: flechas o WASD mueven el cursor (contorno celeste con fondo tenue); Arriba/Abajo cambian entre barra de acciones y mano; Tab cambia de zona; Enter o Espacio eligen; Z amplía la carta; Esc cierra el zoom. En ventanas de decisión se recorren las opciones (Arriba/Abajo por filas) y luego Confirmar / Ver el tablero. Mover el ratón devuelve el control al ratón.
