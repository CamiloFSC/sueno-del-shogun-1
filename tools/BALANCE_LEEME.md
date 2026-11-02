# Herramienta de balance

`tools/balance_report.py` lanza simulaciones IA vs IA (`tests/sim_balance.gd`) con mazos aleatorios,
ajusta una regresión logística (numpy, IRLS + ridge leve) de la victoria de A contra
(copiasA − copiasB) más un término de quién empieza, y genera un informe.

## Uso
```
godot --headless --path . --import          # una vez, antes de simular
python3 tools/balance_report.py --godot /ruta/godot --partidas 100000 --procesos 4 --salida tools/balance_nuevo
python3 tools/balance_report.py --godot /ruta/godot --salida tools/balance_nuevo --comparar tools/balance_linea_base.json
python3 tools/balance_report.py --csv-dir carpeta --solo-analizar --salida x   # reutiliza CSV ya simulados
```
Parámetros: `--partidas`, `--procesos`, `--godot` (o variable GODOT), `--semilla`, `--csv-dir`, `--ridge`.
Genera `<salida>.md` (informe) y `<salida>.json` (efectos por carta). Con `--csv-dir` los CSV se conservan.

## Interpretación
- Efecto = puntos porcentuales de victoria por copia extra, centrado en su grupo (acciones / guerreros+daimyos);
  0 = carta media del grupo. EE = error estándar; |z|>2 es significativo.
- Con 100.000 partidas el EE típico es ~0,2 pp por carta. Para ver cambios de ~0,5 pp conviene >=100k partidas.
- `--comparar` lista las cartas cuyo efecto cambió con |z|>2 respecto al JSON anterior (usar semillas distintas
  o iguales da igual; el ruido ya está en el EE). Tras cambiar una carta, el resto del grupo se desplaza un poco
  por el centrado: fijarse en la carta tocada.
- Línea base del estado actual: `tools/balance_linea_base.md/.json`. Regenerarla tras cada cambio aceptado.
