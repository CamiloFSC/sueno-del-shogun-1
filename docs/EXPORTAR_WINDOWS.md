# Exportar «Sueño del Shogun 1» a Windows

El proyecto ya incluye `export_presets.cfg` con el preset **Windows Desktop** (x86_64, PCK embebido
=> un único `.exe`, sin firma, producto «Sueño del Shogun 1»).

## Pasos en tu PC (Godot 4.3.stable, versión estándar, no .NET)
1. Abre Godot 4.3 y, en el gestor de proyectos, importa la carpeta `cartas_godot` (archivo `project.godot`).
2. Instala las plantillas: **Editor > Administrar plantillas de exportación > Descargar e instalar**
   (o «Instalar desde archivo» con `Godot_v4.3-stable_export_templates.tpz`). Deben ser exactamente la 4.3.stable.
3. Antes de exportar, copia tus imágenes y la fuente (ver más abajo).
4. **Proyecto > Exportar…**, elige «Windows Desktop», comprueba que «Embed PCK» está activo y pulsa
   **Exportar proyecto** (desmarca «Exportar con depuración»). Guarda como `SuenoDelShogun1.exe`.
5. Por línea de comandos: `godot --headless --path . --export-release "Windows Desktop" SuenoDelShogun1.exe`.

El preset excluye `tests/`, `tools/`, `docs/` y `*.md`; incluye `data/*.csv`, `assets/cartas/*`,
`assets/fuentes/*`, `assets/sonidos/*` y `assets/fondo.jpg` (modo «todos los recursos», así los
`.jfif`, `.ttf`, etc. se empaquetan tal cual, sin convertir).

## Dónde poner las 99 imágenes y la fuente
Opción A (empaquetadas en el .exe): antes de exportar, pon las imágenes en `assets/cartas/` y la fuente
(.ttf/.otf) en `assets/fuentes/`. Nombres: empezar por el número de carta (`1.jfif`, `055.png`,
`12 Pirata Wokou.jfif`) o el nombre normalizado (`saizo.png`). Formatos: jfif, jpg, jpeg, png, webp.
Ver `assets/cartas/LEEME.txt`.

Opción B (sin reexportar): junto al `.exe` crea las carpetas `cartas/` y `fuentes/` y copia ahí los
archivos. El juego las busca también ahí y en `user://cartas/` y `user://fuentes/`
(en Windows: `%APPDATA%\Godot\app_userdata\Sueño del Shogun 1\`). El `.jfif` no lo importa Godot; se lee como bytes.

## Notas
- Sin icono propio el .exe usa el icono por defecto de Godot; para cambiarlo pon un `.ico` en
  «Application > Icon» del preset (en Windows Godot necesita `rcedit` configurado en Ajustes del editor).
- Windows SmartScreen puede avisar porque el ejecutable no está firmado.
- Ventana: 1280x720, redimensionable, estiramiento `canvas_items`.
