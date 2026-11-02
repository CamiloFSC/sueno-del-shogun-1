extends SceneTree
## Carga de imágenes sueltas (.jfif, .jpg, .png) desde assets/cartas.
func _init() -> void:
	CardDB.load_all()
	var ok := true
	for id in [5, 1, 60, 77]:
		var t := CardArt.get_texture(id)
		print(id, " -> ", t, " ", (t.get_size() if t != null else "sin imagen"))
		if t == null: ok = false
	print("sin imagen (esperado null): ", CardArt.get_texture(10))
	print("OK" if ok else "FALLO")
	quit(0 if ok else 1)
