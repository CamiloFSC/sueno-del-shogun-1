#!/usr/bin/env python3
"""Informe de balance de «Sueño del Shogun» a partir de simulaciones IA vs IA.

Uso rápido:
  python3 tools/balance_report.py --godot /ruta/godot --partidas 100000 --procesos 4 \
      --salida tools/balance_linea_base
  python3 tools/balance_report.py --godot /ruta/godot --partidas 100000 \
      --salida tools/balance_nuevo --comparar tools/balance_linea_base.json
  python3 tools/balance_report.py --csv-dir carpeta_con_csv --salida x   (sin simular)
Ver tools/BALANCE_LEEME.md.
"""
import argparse, csv, glob, json, math, os, subprocess, sys, tempfile, time
import numpy as np

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NC = 99


def simular(godot, partidas, procesos, semilla0, carpeta):
    os.makedirs(carpeta, exist_ok=True)
    base, resto = divmod(partidas, procesos)
    lotes = []
    for i in range(procesos):
        n = base + (1 if i < resto else 0)
        if n == 0:
            continue
        seed = semilla0 + i
        out = os.path.join(carpeta, "s%d.csv" % seed)
        env = dict(os.environ, SEED=str(seed), N=str(n), OUT=out)
        log = open(os.path.join(carpeta, "s%d.log" % seed), "w")
        p = subprocess.Popen([godot, "--headless", "--path", RAIZ, "-s", "tests/sim_balance.gd"],
                             env=env, stdout=log, stderr=subprocess.STDOUT)
        lotes.append((p, out, n))
    t0 = time.time()
    while any(p.poll() is None for p, _, _ in lotes):
        hechas = 0
        for _, out, _ in lotes:
            if os.path.exists(out):
                with open(out, "rb") as f:
                    hechas += sum(chunk.count(b"\n") for chunk in iter(lambda: f.read(1 << 20), b""))
        print("  [%4ds] %d/%d partidas" % (time.time() - t0, hechas, partidas), file=sys.stderr, flush=True)
        time.sleep(15)
    for p, out, _ in lotes:
        if p.returncode != 0:
            sys.exit("Godot falló (código %s) en %s; revisa el .log" % (p.returncode, out))
    return time.time() - t0


def leer_csvs(carpeta):
    filas = []
    for fn in sorted(glob.glob(os.path.join(carpeta, "*.csv"))):
        txt = open(fn).read().replace(";", " ").replace(",", " ")
        if not txt.strip():
            continue
        a = np.fromstring(txt, sep=" ", dtype=np.float64)
        filas.append(a.reshape(-1, 2 * NC + 3))
    if not filas:
        sys.exit("No hay datos CSV en " + carpeta)
    return np.vstack(filas)


def logit_irls(X, y, pen, it=50):
    n, k = X.shape
    b = np.zeros(k)
    for _ in range(it):
        eta = np.clip(X @ b, -30, 30)
        p = 1 / (1 + np.exp(-eta))
        w = p * (1 - p)
        H = X.T @ (X * w[:, None]) + np.diag(pen)
        g = X.T @ (y - p) - pen * b
        db = np.linalg.solve(H, g)
        b += db
        if np.max(np.abs(db)) < 1e-9:
            break
    eta = np.clip(X @ b, -30, 30)
    p = 1 / (1 + np.exp(-eta))
    w = p * (1 - p)
    H = X.T @ (X * w[:, None]) + np.diag(pen)
    return b, np.linalg.inv(H), w


def nombres():
    d = {}
    with open(os.path.join(RAIZ, "data", "cartas.csv"), encoding="utf-8-sig") as f:
        for r in csv.DictReader(f):
            d[int(r["id"])] = (r["nombre"], r["categoria"])
    return d


def analizar(M, ridge=1e-3):
    n = len(M)
    A, B = M[:, :NC], M[:, NC:2 * NC]
    gan, emp, turnos = M[:, 2 * NC], M[:, 2 * NC + 1], M[:, 2 * NC + 2]
    y = (gan == 0).astype(float)
    s = np.where(emp == 0, 1.0, -1.0)
    D = A - B
    var = D.std(axis=0) > 0
    idx = np.where(var)[0]
    X = np.column_stack([D[:, idx], s])
    pen = np.full(X.shape[1], ridge)
    pen[-1] = 0.0
    b, V, w = logit_irls(X, y, pen)
    k = len(idx)
    # derivada media de la probabilidad respecto al logit (para pasar a puntos porcentuales)
    fac = 100 * w.mean()
    nom = nombres()
    ids = [int(i) + 1 for i in idx]
    grupo = ["Acciones" if nom[i][1] == "Accion" else "Guerreros y Daimyos" for i in ids]
    grupo_arr = np.array(grupo)
    res = {}
    for g in ("Acciones", "Guerreros y Daimyos"):
        m = grupo_arr == g
        mi = np.where(m)[0]
        for j in mi:
            c = np.zeros(X.shape[1])
            c[mi] = -1.0 / len(mi)
            c[j] += 1.0
            e = fac * (c @ b)
            se = fac * math.sqrt(max(c @ V @ c, 0))
            res[ids[j]] = dict(id=ids[j], nombre=nom[ids[j]][0], categoria=nom[ids[j]][1], grupo=g,
                               efecto_pp=e, se_pp=se, z=e / se if se > 0 else 0.0)
        orden = sorted(mi, key=lambda j: -res[ids[j]]["efecto_pp"])
        for r, j in enumerate(orden, 1):
            res[ids[j]]["puesto"] = r
            res[ids[j]]["de"] = len(mi)
    # cambiar un guerrero/daimyo por una acción
    ma = grupo_arr == "Acciones"
    c = np.zeros(X.shape[1])
    c[:k][~ma] = 1.0 / (~ma).sum()
    c[:k][ma] = -1.0 / ma.sum()
    c[-1] = 0
    sw = fac * (c @ b)
    sw_se = fac * math.sqrt(c @ V @ c)
    # ventaja de empezar
    bs, bs_se = b[-1], math.sqrt(V[-1, -1])
    st_gana = np.where(emp == gan, 1.0, 0.0)
    f_emp = st_gana.mean()
    f_se = math.sqrt(f_emp * (1 - f_emp) / n)
    pm = 1 / (1 + math.exp(-bs))
    glob_ = dict(partidas=int(n), empieza_gana_obs=100 * f_emp, empieza_gana_obs_se=100 * f_se,
                 empieza_gana_modelo=100 * pm, empieza_gana_modelo_se=100 * pm * (1 - pm) * bs_se,
                 cambio_accion_por_guerrero_pp=-sw, cambio_se_pp=sw_se, turnos_medios=float(turnos.mean()),
                 factor_pp=fac, ridge=ridge)
    return glob_, res


def tabla(lista, titulo):
    L = ["### " + titulo, "", "| Puesto | Id | Carta | Efecto (pp/copia) | EE | z |", "|---:|---:|---|---:|---:|---:|"]
    for r in lista:
        L.append("| %d/%d | %d | %s | %+.2f | %.2f | %+.1f |" % (r["puesto"], r["de"], r["id"], r["nombre"],
                                                           r["efecto_pp"], r["se_pp"], r["z"]))
    return L + [""]


def informe(glob_, res, extra, comp=None, comp_nombre=""):
    g = glob_
    L = ["# Informe de balance", "",
         "- Partidas: **%d** (IA vs IA, mazos aleatorios de 50 cartas, máx. 3 copias)" % g["partidas"],
         "- Quien empieza gana: **%.2f %%** observado (EE %.2f); modelo %.2f %% (EE %.2f)" % (
             g["empieza_gana_obs"], g["empieza_gana_obs_se"], g["empieza_gana_modelo"], g["empieza_gana_modelo_se"]),
         "- Cambiar 1 acción por 1 guerrero/daimyo: **%+.2f pp** de victoria (EE %.2f)" % (
             g["cambio_accion_por_guerrero_pp"], g["cambio_se_pp"]),
         "- Turnos medios por partida: %.1f" % g["turnos_medios"]]
    for k, v in extra.items():
        L.append("- %s: %s" % (k, v))
    L += ["",
          "Efecto = puntos porcentuales de victoria por copia adicional en el mazo, regresión logística "
          "(ridge %.0e) sobre copiasA-copiasB + quién empieza, **centrado dentro de su grupo** (0 = carta media del grupo). "
          "EE = error estándar." % g["ridge"], ""]
    for grp in ("Acciones", "Guerreros y Daimyos"):
        l = sorted([r for r in res.values() if r["grupo"] == grp], key=lambda r: r["puesto"])
        L.append("## " + grp)
        L.append("")
        L += tabla(l[:12], "12 mejores")
        L += tabla(l[::-1][:12], "12 peores")
    if comp:
        L += ["## Comparación con " + comp_nombre, "",
              "Cartas con cambio significativo (|z|>2) entre ambas corridas.", ""]
        if not comp:
            pass
        filas = comp["filas"]
        L.append("Diferencia de quien empieza: %+.2f pp; cambio acción/guerrero: %+.2f pp" % (
            comp["d_empieza"], comp["d_cambio"]))
        L.append("")
        if filas:
            L += ["| Id | Carta | Antes | Ahora | Δ pp | z | Puesto antes→ahora |", "|---:|---|---:|---:|---:|---:|---|"]
            for f in filas:
                L.append("| %d | %s | %+.2f | %+.2f | %+.2f | %+.1f | %d→%d |" % (
                    f["id"], f["nombre"], f["antes"], f["ahora"], f["delta"], f["z"], f["puesto_antes"], f["puesto_ahora"]))
        else:
            L.append("_Ninguna carta cambió significativamente._")
        L.append("")
    return "\n".join(L)


def comparar(res, glob_, ruta):
    ant = json.load(open(ruta))
    ra = {int(k): v for k, v in ant["cartas"].items()}
    filas = []
    for i, r in res.items():
        if i not in ra:
            continue
        a = ra[i]
        d = r["efecto_pp"] - a["efecto_pp"]
        se = math.hypot(r["se_pp"], a["se_pp"])
        z = d / se if se > 0 else 0
        if abs(z) > 2:
            filas.append(dict(id=i, nombre=r["nombre"], antes=a["efecto_pp"], ahora=r["efecto_pp"], delta=d, z=z,
                              puesto_antes=a["puesto"], puesto_ahora=r["puesto"]))
    filas.sort(key=lambda f: -abs(f["z"]))
    ga = ant["global"]
    return dict(filas=filas, d_empieza=glob_["empieza_gana_obs"] - ga["empieza_gana_obs"],
                d_cambio=glob_["cambio_accion_por_guerrero_pp"] - ga["cambio_accion_por_guerrero_pp"])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"), help="ruta al binario de Godot")
    ap.add_argument("--partidas", type=int, default=100000)
    ap.add_argument("--procesos", type=int, default=4)
    ap.add_argument("--semilla", type=int, default=1, help="semilla inicial (cada proceso usa semilla+i)")
    ap.add_argument("--salida", default=os.path.join(RAIZ, "tools", "balance_informe"),
                    help="prefijo de salida (.md y .json)")
    ap.add_argument("--csv-dir", help="carpeta de CSV (si existe se usa tal cual; si no, se crea y se simula)")
    ap.add_argument("--solo-analizar", action="store_true", help="no simular, usar --csv-dir existente")
    ap.add_argument("--comparar", help="JSON de un informe anterior")
    ap.add_argument("--ridge", type=float, default=1e-3)
    a = ap.parse_args()
    t0 = time.time()
    carpeta = a.csv_dir or tempfile.mkdtemp(prefix="balance_")
    extra = {}
    if not a.solo_analizar:
        ts = simular(a.godot, a.partidas, a.procesos, a.semilla, carpeta)
        extra["Tiempo de simulación"] = "%.0f s con %d procesos" % (ts, a.procesos)
        extra["Semillas"] = "%d..%d" % (a.semilla, a.semilla + a.procesos - 1)
    M = leer_csvs(carpeta)
    glob_, res = analizar(M, a.ridge)
    comp = comparar(res, glob_, a.comparar) if a.comparar else None
    md = informe(glob_, res, extra, comp, a.comparar or "")
    print(md)
    with open(a.salida + ".md", "w") as f:
        f.write(md + "\n")
    with open(a.salida + ".json", "w") as f:
        json.dump({"global": glob_, "extra": extra, "cartas": {str(k): v for k, v in sorted(res.items())}}, f,
                  ensure_ascii=False, indent=1)
    print("\nGuardado: %s.md / %s.json  (total %.0f s)" % (a.salida, a.salida, time.time() - t0), file=sys.stderr)


if __name__ == "__main__":
    main()
