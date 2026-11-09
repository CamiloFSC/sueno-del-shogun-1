extends SceneTree
var fails := 0
func check(n: String, c: bool) -> void:
	print(("PASS  " if c else "FAIL  ") + n)
	if not c: fails += 1
func _init() -> void:
	var a := SpriteAnim.from_file("res://assets/animaciones/ejemplo/ataque_3x2.png", 10.0, false)
	root.add_child(a)
	check("Lee 3x2 del nombre = 6 fotogramas", a.frame_count == 6)
	check("Tamaño de fotograma 480x345", a.custom_minimum_size == Vector2(480, 345))
	a.play()
	await create_timer(0.35).timeout
	check("Avanza de fotograma", (a.texture as AtlasTexture).region.position != Vector2.ZERO)
	await create_timer(0.8).timeout
	check("Sin loop termina en el último fotograma", (a.texture as AtlasTexture).region.position == Vector2(960, 345))
	print("FALLAS: %d" % fails)
	quit(1 if fails > 0 else 0)
