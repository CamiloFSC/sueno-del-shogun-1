extends SceneTree
func _init() -> void:
	var ok := true
	for n in ["ataque", "dano", "derrota", "victoria"]:
		var a := AnimStore.make(67, n)
		if a == null or a.frame_count != 6:
			ok = false
			print("FALLA ", n)
	if AnimStore.make(1, "ataque") != null:
		ok = false
	print("anim_store: ", "OK" if ok else "FALLA")
	quit(0 if ok else 1)
