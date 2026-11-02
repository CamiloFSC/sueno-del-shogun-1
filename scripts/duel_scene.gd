class_name DuelScene
extends Control
## Escena 2D de duelo (nivel 1): las dos cartas se enfrentan, chocan, el ganador golpea y el perdedor muere.
## Es solo presentación: el motor ya resolvió el duelo. Un clic la salta.

signal finished

var _tweens: Array = []
var _skipped := false
var _sfx: Sfx = null
var _stage: Control
var _flash: ColorRect

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 180

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_skipped = true
		for t in _tweens:
			if is_instance_valid(t):
				t.set_speed_scale(100.0)

func _tw() -> Tween:
	var t := create_tween()
	if _skipped:
		t.set_speed_scale(100.0)
	_tweens.append(t)
	return t

func _wait(sec: float) -> void:
	var t := _tw()
	t.tween_interval(sec)
	await t.finished

func _play(sound: String) -> void:
	if _sfx != null and not _skipped:
		_sfx.play(sound)

## ev: evento "duel" del motor. info: {names:[n0,n1], cards:[card0, card1], tex:[t0, t1]}
func play(ev: Dictionary, info: Dictionary, sfx: Sfx) -> void:
	_sfx = sfx
	var S := get_viewport_rect().size
	var winner: int = ev.p
	var loser := 1 - winner
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var ch := minf(340.0, S.y * 0.46)
	var title := _label("¡DUELO!", 44, Color(1.0, 0.85, 0.3))
	title.position = Vector2(0, 18)
	title.size = Vector2(S.x, 60)
	title.modulate.a = 0.0
	_stage.add_child(title)
	var cards: Array = []
	var rest: Array = []
	var dice_lbl: Array = []
	var dice: Array = []
	for p in 2:
		var c := _make_card(info.cards[p], info.tex[p], ch)
		var cy := S.y * 0.40 - c.size.y * 0.5
		var cx := S.x * (0.27 if p == 0 else 0.73) - c.size.x * 0.5
		rest.append(Vector2(cx, cy))
		c.position = Vector2(-c.size.x - 20 if p == 0 else S.x + 20, cy)
		_stage.add_child(c)
		cards.append(c)
		var own := _label(info.names[p], 22, Color(1, 0.95, 0.8))
		own.size = Vector2(c.size.x + 80, 30)
		own.position = Vector2(-40, -34)
		c.add_child(own)
		# dados en primer plano, debajo de la carta
		var rolls: Array = ev.rolls[p]
		var pts: int = ev.points[p]
		var side_x: float = S.x * (0.27 if p == 0 else 0.73)
		var dice_y: float = S.y * 0.40 + ch * 0.5 + 22.0
		var zone_h: float = S.y - dice_y - 70.0
		var avail_w: float = S.x * 0.42
		var sz := 88.0
		var cols := 1
		var nrows := 1
		while true:
			cols = maxi(1, int(avail_w / (sz + 12.0)))
			nrows = int(ceil(float(rolls.size()) / cols))
			if nrows * (sz + 12.0) <= zone_h or sz <= 34.0:
				break
			sz -= 6.0
		var group: Array = []
		for i in rolls.size():
			var row := i / cols
			var in_row := mini(cols, rolls.size() - row * cols)
			var col := i % cols
			var d := BigDie.new(sz)
			d.value = 1
			d.position = Vector2(side_x - in_row * (sz + 12.0) * 0.5 + 6.0 + col * (sz + 12.0), dice_y + row * (sz + 12.0))
			d.modulate.a = 0.0
			_stage.add_child(d)
			group.append(d)
		dice.append(group)
		var dl := _label("", 34, Color.WHITE)
		dl.size = Vector2(avail_w, 46)
		dl.position = Vector2(side_x - avail_w * 0.5, dice_y + nrows * (sz + 12.0) + 2.0)
		dl.modulate.a = 0.0
		_stage.add_child(dl)
		dice_lbl.append(dl)
		dl.text = "Total %d%s" % [ev.totals[p], ("   (%s%d)" % ["+" if pts >= 0 else "−", absi(pts)]) if pts != 0 else ""]
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# 1) entrada
	var t := _tw()
	t.set_parallel(true)
	t.tween_property(bg, "color:a", 0.88, 0.2)
	t.tween_property(title, "modulate:a", 1.0, 0.25)
	for p in 2:
		t.tween_property(cards[p], "position", rest[p], 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	# 2) los dados ruedan y caen
	_play("dados")
	t = _tw()
	t.set_parallel(true)
	var longest := 0.0
	for p in 2:
		var rolls: Array = ev.rolls[p]
		for i in dice[p].size():
			var d: BigDie = dice[p][i]
			var final_v: int = rolls[i]
			var delay: float = 0.05 * i
			var dur: float = 0.8
			longest = maxf(longest, delay + dur)
			var y0 := d.position.y
			d.position.y = y0 - 140.0
			d.scale = Vector2(1.5, 1.5)
			t.tween_property(d, "modulate:a", 1.0, 0.1).set_delay(delay)
			t.tween_property(d, "position:y", y0, dur).set_delay(delay).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			t.tween_property(d, "scale", Vector2.ONE, dur).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_property(d, "rotation", TAU * (2.0 if i % 2 == 0 else -2.0), dur).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_method(func(x: float):
				d.value = final_v if x >= 0.97 else 1 + int(x * 40.0) % 6, 0.0, 1.0, dur).set_delay(delay)
	await t.finished
	d_end_fix(dice)
	t = _tw()
	t.set_parallel(true)
	for p in 2:
		t.tween_property(dice_lbl[p], "modulate:a", 1.0, 0.3)
	await t.finished
	await _wait(0.7)
	# 3) choque
	var mid := S.x * 0.5
	t = _tw()
	t.set_parallel(true)
	for p in 2:
		var tx: float = mid - cards[p].size.x * (0.92 if p == 0 else 0.08)
		t.tween_property(cards[p], "position:x", tx, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	_play("espadas")
	_impact(0.7)
	await _shake(0.3, 12.0)
	# 4) el ganador golpea, el perdedor recibe
	var w: Control = cards[winner]
	var l: Control = cards[loser]
	var dir := 1.0 if winner == 0 else -1.0
	t = _tw()
	t.tween_property(w, "position:x", w.position.x - dir * 50.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(w, "position:x", w.position.x + dir * 90.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	_play("espadas")
	_impact(0.9)
	_burst(l.position + l.size * 0.5)
	var alt: Texture2D = ExtraArt.alt_pose(ev.ids[winner])   # pose alternativa del Daimyo ganador
	if alt != null:
		var ar := TextureRect.new()
		ar.texture = alt
		ar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ar.set_anchors_preset(Control.PRESET_FULL_RECT)
		ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ar.modulate.a = 0.0
		w.add_child(ar)
		create_tween().tween_property(ar, "modulate:a", 1.0, 0.3)
	l.modulate = Color(1.0, 0.45, 0.4)
	t = _tw()
	t.set_parallel(true)
	t.tween_property(l, "position:x", l.position.x + dir * 70.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "rotation", dir * 0.25, 0.2)
	await _shake(0.3, 18.0)
	# 5) muerte del perdedor y gloria del ganador
	var dead := _label("¡DERROTADO!", 30, Color(1.0, 0.3, 0.25))
	dead.size = Vector2(l.size.x + 120, 40)
	dead.position = Vector2(-60, l.size.y * 0.42)
	l.add_child(dead)
	var win_lbl := _label("¡GANA!", 30, Color(1.0, 0.88, 0.3))
	win_lbl.size = Vector2(w.size.x + 120, 40)
	win_lbl.position = Vector2(-60, -72)
	w.add_child(win_lbl)
	w.pivot_offset = w.size * 0.5
	l.pivot_offset = l.size * 0.5
	t = _tw()
	t.set_parallel(true)
	for dd in dice[winner]:
		dd.tint = Color(1.0, 0.88, 0.35)
		t.tween_property(dd, "scale", Vector2(1.18, 1.18), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for dd in dice[loser]:
		dd.tint = Color(0.55, 0.4, 0.38)
		t.tween_property(dd, "modulate:a", 0.55, 0.4)
	dice_lbl[winner].add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	dice_lbl[loser].add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	t.tween_property(l, "modulate:a", 0.0, 0.75).set_delay(0.15)
	t.tween_property(l, "scale", Vector2(0.65, 0.65), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(l, "rotation", dir * 0.7, 0.9)
	t.tween_property(title, "modulate:a", 0.0, 0.2)
	t.tween_property(w, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	await _wait(0.6)
	# 6) salida
	t = _tw()
	t.set_parallel(true)
	t.tween_property(bg, "color:a", 0.0, 0.25)
	t.tween_property(_stage, "modulate:a", 0.0, 0.25)
	await t.finished
	finished.emit()
	queue_free()

func _label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _make_card(c: Dictionary, tex: Texture2D, h: float) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex != null:
		var w := h * float(tex.get_width()) / float(tex.get_height())
		root.size = Vector2(w, h)
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(r)
		return root
	root.size = Vector2(h * 0.72, h)
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.24, 0.36) if c.categoria != "Daimyo" else Color(0.15, 0.32, 0.20)
	sb.border_color = Color(1.0, 0.85, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", sb)
	root.add_child(p)
	var l := _label("%s\n\n%s\n⚔ %d" % [c.nombre, c.clan, c.ataque], 24, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(l)
	return root

func _impact(strength: float) -> void:
	_flash.color = Color(1, 1, 0.9, strength * 0.7)
	var t := _tw()
	t.tween_property(_flash, "color:a", 0.0, 0.25)

func _shake(sec: float, amp: float) -> void:
	var t := _tw()
	var n := 8
	for i in n:
		var k := 1.0 - float(i) / n
		t.tween_property(_stage, "position", Vector2(randf_range(-amp, amp) * k, randf_range(-amp, amp) * k), sec / n)
	t.tween_property(_stage, "position", Vector2.ZERO, 0.02)
	await t.finished

func _burst(pos: Vector2) -> void:
	var pr := CPUParticles2D.new()
	pr.position = pos
	pr.emitting = true
	pr.one_shot = true
	pr.explosiveness = 1.0
	pr.amount = 50
	pr.lifetime = 0.8
	pr.direction = Vector2(0, -1)
	pr.spread = 180.0
	pr.initial_velocity_min = 160.0
	pr.initial_velocity_max = 420.0
	pr.gravity = Vector2(0, 500)
	pr.scale_amount_min = 3.0
	pr.scale_amount_max = 7.0
	pr.color = Color(1.0, 0.55, 0.25)
	_stage.add_child(pr)

func d_end_fix(dice: Array) -> void:
	for g in dice:
		for d in g:
			d.rotation = 0.0
