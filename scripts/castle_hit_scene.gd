class_name CastleHitScene
extends DuelScene
## Escena 2D del ataque directo al castillo: el atacante embiste, el castillo pierde cartas.
## Solo presentación (el motor ya resolvió). Un clic la salta.

## ev: {p: atacante, id, d: dueño del castillo, before: cartas antes, n: cartas perdidas}
## info: {names:[n0,n1], card: Dictionary, tex: Texture2D}
func play_hit(ev: Dictionary, info: Dictionary, sfx: Sfx) -> void:
	_sfx = sfx
	var S := get_viewport_rect().size
	var a: int = ev.p
	var d: int = ev.d
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var title := _label("¡ATAQUE AL CASTILLO!", 44, Color(1.0, 0.6, 0.2))
	title.position = Vector2(0, 18)
	title.size = Vector2(S.x, 60)
	title.modulate.a = 0.0
	_stage.add_child(title)
	# atacante
	var ch := minf(380.0, S.y * 0.5)
	var att := _make_card(info.card, info.tex, ch)
	var ay := S.y * 0.5 - att.size.y * 0.5
	var ax := S.x * 0.22 - att.size.x * 0.5
	att.position = Vector2(-att.size.x - 20, ay)
	_stage.add_child(att)
	var an := _label(info.names[a], 22, Color(1, 0.95, 0.8))
	an.size = Vector2(att.size.x + 80, 30)
	an.position = Vector2(-40, -34)
	att.add_child(an)
	# castillo
	var cv := TextureRect.new()   # imagen del castillo según cuántas cartas le quedan
	var left: int = ev.before
	cv.texture = ExtraArt.castle_stage(left)
	cv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cv.size = Vector2(minf(620.0, S.x * 0.5), minf(500.0, S.y * 0.66))
	cv.pivot_offset = cv.size * 0.5
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.position = Vector2(S.x * 0.70 - cv.size.x * 0.5, S.y * 0.5 - cv.size.y * 0.5)
	cv.modulate.a = 0.0
	_stage.add_child(cv)
	var cn := _label("Castillo de %s" % info.names[d], 24, Color(1, 0.95, 0.8))
	cn.size = Vector2(420, 30)
	cn.position = Vector2(S.x * 0.70 - 210.0, maxf(cv.position.y - 40.0, 70.0))
	cn.modulate.a = 0.0
	_stage.add_child(cn)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_stage.move_child(att, -1)   # el atacante queda delante del castillo
	# 1) entrada
	var t := _tw()
	t.set_parallel(true)
	t.tween_property(bg, "color:a", 0.88, 0.2)
	t.tween_property(title, "modulate:a", 1.0, 0.25)
	t.tween_property(cv, "modulate:a", 1.0, 0.3)
	t.tween_property(cn, "modulate:a", 1.0, 0.3)
	t.tween_property(att, "position", Vector2(ax, ay), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	await _wait(0.5)
	# 2) retroceso y embestida
	var target_x: float = cv.position.x - att.size.x * 0.5 + 60.0
	t = _tw()
	t.tween_property(att, "position:x", ax - 60.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(att, "position:x", target_x, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	# 3) impactos: cada carta perdida cae del castillo
	var c_center: Vector2 = cv.position + cv.size * 0.5
	for i in ev.n:
		_play("espadas")
		_impact(0.75)
		_burst(c_center + Vector2(randf_range(-60, 60), randf_range(-50, 50)))
		left = maxi(0, ev.before - i - 1)
		cv.texture = ExtraArt.castle_stage(left)
		var s := _label("−1", 40, Color(1.0, 0.35, 0.3))
		s.size = Vector2(120, 50)
		s.position = c_center + Vector2(-60 + i * 30, -100)
		_stage.add_child(s)
		var ts := _tw()
		ts.set_parallel(true)
		ts.tween_property(s, "position:y", s.position.y - 70.0, 0.8)
		ts.tween_property(s, "modulate:a", 0.0, 0.8).set_delay(0.3)
		await _shake(0.3, 14.0)
		await _wait(0.12)
	# 4) resultado
	var msg := "¡Castillo destruido!" if left == 0 else "−%d carta%s del castillo" % [ev.n, "" if ev.n == 1 else "s"]
	var res := _label(msg, 34, Color(1.0, 0.88, 0.3))
	res.size = Vector2(S.x, 50)
	res.position = Vector2(0, S.y - 90.0)
	_stage.add_child(res)
	t = _tw()
	t.tween_property(att, "position:x", ax, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	await _wait(0.8)
	t = _tw()
	t.set_parallel(true)
	t.tween_property(bg, "color:a", 0.0, 0.25)
	t.tween_property(_stage, "modulate:a", 0.0, 0.25)
	await t.finished
	finished.emit()
	queue_free()
