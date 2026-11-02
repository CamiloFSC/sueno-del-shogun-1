#!/usr/bin/env python3
"""Reescribe el texto del efecto en la imagen de una carta (prueba piloto).
Uso: python3 retexto.py <imagen_entrada> <salida.png> "<linea1>|<linea2>|..." x0 y0 x1 y1 [serif|sans] [escala_texto]
Las coordenadas son de una vista previa de 600 px de ancho (se escalan solas)."""
import sys, numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont
FONTS = {"serif": "/usr/share/texmf/fonts/opentype/public/tex-gyre/texgyrepagella-regular.otf",
         "sans": "/usr/share/fonts/opentype/inter/Inter-Medium.otf"}
def main(a):
    src, out, text = a[0], a[1], a[2].split("|")
    x0, y0, x1, y1 = [int(v) for v in a[3:7]]
    kind = a[7] if len(a) > 7 else "serif"; k = float(a[8]) if len(a) > 8 else 1.0
    light = len(a) > 9 and a[9] == "claro"   # texto claro sobre fondo oscuro
    im = Image.open(src).convert("RGB"); W, H = im.size; f = W / 600.0
    x0, y0, x1, y1 = [int(v * f) for v in (x0, y0, x1, y1)]
    arr = np.array(im); roi = arr[y0:y1, x0:x1].copy()
    gray = cv2.cvtColor(roi, cv2.COLOR_RGB2GRAY)
    if light:
        thr = np.percentile(gray, 99) * 0.72
        mask = (gray > thr).astype(np.uint8) * 255
    else:
        thr = np.percentile(gray, 50) * 0.62
        mask = (gray < thr).astype(np.uint8) * 255
    ink = tuple(int(v) for v in (np.percentile(roi[mask > 0], 90, axis=0) if light else np.median(roi[mask > 0], axis=0))) if mask.any() else (40, 30, 25)
    mask = cv2.dilate(mask, np.ones((5, 5), np.uint8), iterations=2)
    clean = cv2.inpaint(roi, mask, 6, cv2.INPAINT_TELEA)
    arr[y0:y1, x0:x1] = clean
    img = Image.fromarray(arr); d = ImageDraw.Draw(img)
    bw, bh = x1 - x0, y1 - y0
    size = int(bh / (len(text) * 1.25) * k)
    while True:
        font = ImageFont.truetype(FONTS[kind], size)
        w = max(d.textlength(t, font=font) for t in text)
        if w <= bw * 0.96 or size < 8: break
        size -= 1
    lh = size * 1.25; y = y0 + (bh - lh * len(text)) / 2
    for t in text:
        d.text((x0 + (bw - d.textlength(t, font=font)) / 2, y), t, font=font, fill=ink); y += lh
    img.save(out)
main(sys.argv[1:])
