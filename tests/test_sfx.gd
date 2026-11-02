extends SceneTree
## Comprueba que todos los sonidos cargan.
func _init() -> void:
	var ok := true
	for n in Sfx.NAMES:
		var st := Sfx._load(n)
		print(n, " -> ", "OK %.2f s" % st.get_length() if st != null else "FALTA")
		if st == null: ok = false
	print("SONIDOS OK" if ok else "SONIDOS FALLO")
	quit()
