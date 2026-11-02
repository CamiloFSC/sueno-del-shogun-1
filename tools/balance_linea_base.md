# Informe de balance

- Partidas: **100000** (IA vs IA, mazos aleatorios de 50 cartas, máx. 3 copias)
- Quien empieza gana: **55.32 %** observado (EE 0.16); modelo 55.65 % (EE 0.16)
- Cambiar 1 acción por 1 guerrero/daimyo: **+1.28 pp** de victoria (EE 0.03)
- Simulación: 4 procesos (semillas 1-4, 25.000 c/u), máquina de 2 núcleos, ~9 min
- Turnos medios por partida: 10.7

Efecto = puntos porcentuales de victoria por copia adicional en el mazo, regresión logística (ridge 1e-03) sobre copiasA-copiasB + quién empieza, **centrado dentro de su grupo** (0 = carta media del grupo). EE = error estándar.

## Acciones

### 12 mejores

| Puesto | Id | Carta | Efecto (pp/copia) | EE | z |
|---:|---:|---|---:|---:|---:|
| 1/30 | 83 | El Tokaido | +4.29 | 0.14 | +30.2 |
| 2/30 | 98 | Muerte Honorable | +3.68 | 0.14 | +26.1 |
| 3/30 | 79 | Reiki | +2.75 | 0.14 | +19.6 |
| 4/30 | 86 | Kansei | +2.64 | 0.14 | +18.8 |
| 5/30 | 96 | Cortesia | +1.83 | 0.14 | +13.0 |
| 6/30 | 71 | Ceremonia del té | +1.66 | 0.14 | +11.8 |
| 7/30 | 94 | Honestidad | +1.20 | 0.14 | +8.5 |
| 8/30 | 70 | Conspiración | +0.60 | 0.14 | +4.3 |
| 9/30 | 76 | Intriga | +0.56 | 0.14 | +4.0 |
| 10/30 | 72 | Dominio de si mismo | +0.38 | 0.14 | +2.7 |
| 11/30 | 85 | Hansei | -0.01 | 0.14 | -0.1 |
| 12/30 | 78 | Rectitud Zen | -0.15 | 0.14 | -1.1 |

### 12 peores

| Puesto | Id | Carta | Efecto (pp/copia) | EE | z |
|---:|---:|---|---:|---:|---:|
| 30/30 | 80 | Dilema del cucu | -1.64 | 0.14 | -11.7 |
| 29/30 | 89 | Castillo de montaña | -1.60 | 0.14 | -11.4 |
| 28/30 | 74 | El destino del clan | -1.51 | 0.14 | -10.8 |
| 27/30 | 92 | Matrimonio arreglado | -1.47 | 0.14 | -10.5 |
| 26/30 | 91 | Ninjutsu | -1.44 | 0.14 | -10.2 |
| 25/30 | 99 | Reflexion y justicia | -1.42 | 0.14 | -10.1 |
| 24/30 | 87 | Musha Shugyo | -1.40 | 0.14 | -10.0 |
| 23/30 | 77 | Liderazgo | -1.31 | 0.14 | -9.4 |
| 22/30 | 95 | Nobleza de espiritu | -1.24 | 0.14 | -8.8 |
| 21/30 | 75 | El Nakasendo | -1.23 | 0.14 | -8.8 |
| 20/30 | 97 | Lealtad | -1.21 | 0.14 | -8.7 |
| 19/30 | 82 | El maestro estratega | -0.90 | 0.14 | -6.4 |

## Guerreros y Daimyos

### 12 mejores

| Puesto | Id | Carta | Efecto (pp/copia) | EE | z |
|---:|---:|---|---:|---:|---:|
| 1/69 | 53 | Motoyama Boku | +2.91 | 0.18 | +15.9 |
| 2/69 | 60 | Date | +1.37 | 0.18 | +7.4 |
| 3/69 | 21 | Nobutada | +1.30 | 0.18 | +7.1 |
| 4/69 | 65 | Yoshihiro | +0.90 | 0.18 | +4.9 |
| 5/69 | 13 | Terror 7 mares | +0.69 | 0.18 | +3.8 |
| 6/69 | 16 | Sasaki Kojiro | +0.59 | 0.18 | +3.2 |
| 7/69 | 44 | Sessai Choro | +0.56 | 0.18 | +3.1 |
| 8/69 | 56 | Hidetoshi | +0.51 | 0.18 | +2.8 |
| 9/69 | 30 | Anayama Baitetsu | +0.49 | 0.18 | +2.7 |
| 10/69 | 59 | Kenshin | +0.44 | 0.18 | +2.4 |
| 11/69 | 8 | Tenzo | +0.43 | 0.18 | +2.3 |
| 12/69 | 27 | Honda Heihachiro | +0.42 | 0.18 | +2.3 |

### 12 peores

| Puesto | Id | Carta | Efecto (pp/copia) | EE | z |
|---:|---:|---|---:|---:|---:|
| 69/69 | 12 | Pirata Wokou | -1.67 | 0.18 | -9.1 |
| 68/69 | 31 | Kage Katsu | -0.96 | 0.18 | -5.2 |
| 67/69 | 3 | Revancha | -0.83 | 0.18 | -4.5 |
| 66/69 | 40 | Yoshihisa | -0.82 | 0.18 | -4.4 |
| 65/69 | 11 | Toshie | -0.76 | 0.18 | -4.1 |
| 64/69 | 52 | Morichika | -0.76 | 0.18 | -4.2 |
| 63/69 | 19 | Nobutaka | -0.76 | 0.18 | -4.1 |
| 62/69 | 6 | Kosaka | -0.66 | 0.18 | -3.6 |
| 61/69 | 1 | Saizo | -0.66 | 0.18 | -3.6 |
| 60/69 | 49 | Rukkaku YOshikata | -0.64 | 0.18 | -3.5 |
| 59/69 | 34 | Junyo | -0.58 | 0.18 | -3.1 |
| 58/69 | 10 | Matsu | -0.57 | 0.18 | -3.1 |

