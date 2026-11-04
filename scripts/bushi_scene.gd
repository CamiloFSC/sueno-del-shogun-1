class_name BushiScene
extends DuelScene
## Escenas en primer plano de las cartas Bushi: 1) la carta que se juega, 2) su efecto (dado y texto). Solo presentación.

func _wait(sec: float) -> void:
	if _skipped:
		return
	var t := get_tree().create_timer(sec)
	await t.timeout

## ev: {p, id}. info: {name, card, tex}
func play_card(ev: Dictionary, info: Dictionary, sfx: Sfx) -> void:
	_sfx = sfx
	var S := get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var who := _label(("Tú juegas" if info.name == "Tú" else "%s juega" % info.name), 34, Color(1.0, 0.85, 0.3))
	who.size = Vector2(S.x, 50)
	who.position = Vector2(0, 26)
	who.modulate.a = 0.0
	add_child(who)
	var ch := minf(S.y * 0.72, 520.0)
	var card := _make_card(info.card, info.tex, ch)
	card.pivot_offset = card.size * 0.5
	card.position = Vector2(S.x * 0.5 - card.size.x * 0.5, S.y * 0.5 - card.size.y * 0.5 + 20.0)
	card.scale = Vector2(0.5, 0.5)
	card.modulate.a = 0.0
	add_child(card)
	if sfx != null:
		sfx.play("aviso")
	var tw := create_tween()
	_tweens.append(tw)
	tw.set_parallel(true)
	tw.tween_property(bg, "color:a", 0.6, 0.25)
	tw.tween_property(who, "modulate:a", 1.0, 0.25)
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(1.5)
	var out := create_tween()
	_tweens.append(out)
	out.set_parallel(true)
	for n in [bg, who, card]:
		out.tween_property(n, "modulate:a", 0.0, 0.2)
	await _wait(0.2)
	queue_free()

## ev: {p, id, lines, dice, draw}. info: {name, card, tex}
func play_fx(ev: Dictionary, info: Dictionary, sfx: Sfx) -> void:
	_sfx = sfx
	var S := get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.modulate.a = 0.0
	add_child(bg)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	add_child(root)
	var ch := minf(S.y * 0.5, 380.0)
	var card := _make_card(info.card, info.tex, ch)
	card.position = Vector2(S.x * 0.14, S.y * 0.5 - card.size.y * 0.5)
	root.add_child(card)
	var x0 := card.position.x + card.size.x + 50.0
	var wbox := S.x - x0 - 60.0
	var title := _label(info.card.nombre, 34, Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector2(x0, S.y * 0.5 - ch * 0.5)
	title.size = Vector2(wbox, 48)
	root.add_child(title)
	var y := title.position.y + 64.0
	var dice_nodes: Array = []
	var dice: Array = ev.dice
	if not dice.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.position = Vector2(x0, y)
		root.add_child(row)
		for v in dice:
			var d := DieFace.new(v, 96)
			row.add_child(d)
			dice_nodes.append([d, v])
		y += 116.0
	var text := ""
	for l in ev.lines:
		text += "• " + str(l) + "\n"
	if ev.draw > 0:
		text += "• Roba %d carta(s)." % ev.draw
	var lbl := _label(text.strip_edges(), 24, Color(1, 0.97, 0.88))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.position = Vector2(x0, y)
	lbl.size = Vector2(wbox, 220)
	lbl.modulate.a = 0.0 if not dice.is_empty() else 1.0
	root.add_child(lbl)
	var tw := create_tween()
	_tweens.append(tw)
	tw.set_parallel(true)
	tw.tween_property(bg, "modulate:a", 1.0, 0.2)
	tw.tween_property(root, "modulate:a", 1.0, 0.2)
	await _wait(0.25)
	if not dice_nodes.is_empty():
		if sfx != null:
			sfx.play("dados")
		for dn in dice_nodes:
			dn[0].start_roll(dn[1], 0.9)
		await _wait(1.1)
		create_tween().tween_property(lbl, "modulate:a", 1.0, 0.2)
	await _wait(1.6)
	var out := create_tween()
	_tweens.append(out)
	out.set_parallel(true)
	out.tween_property(bg, "modulate:a", 0.0, 0.2)
	out.tween_property(root, "modulate:a", 0.0, 0.2)
	await _wait(0.2)
	queue_free()
