class_name AnimStore
extends RefCounted
## Animaciones de Daimyo por hoja de sprites: id de carta -> carpeta en assets/animaciones/.
## Cada carpeta puede tener ataque_CxF.png, dano_CxF.png, derrota_CxF.png, victoria_CxF.png.

const FOLDERS := {67: "imagawa"}

static func has(id: int) -> bool:
	return FOLDERS.has(id)

## Devuelve un SpriteAnim para (id, nombre de animación) o null si no existe.
static func make(id: int, anim: String, fps: float = 7.0, loop: bool = true) -> SpriteAnim:
	if not FOLDERS.has(id):
		return null
	var dir := "res://assets/animaciones/%s/" % FOLDERS[id]
	var da := DirAccess.open(dir)
	if da == null:
		return null
	for f in da.get_files():
		if f.begins_with(anim + "_") and f.ends_with(".png"):
			var a := SpriteAnim.from_file(dir + f, fps, loop)
			a.set_anchors_preset(Control.PRESET_FULL_RECT)
			a.play()
			return a
	return null
