extends Control
## Interfaz mínima (placeholder). Tú = jugador 0, la IA = jugador 1.

const HUMAN := 0
const ZONE_H := 185     # alto de las cartas en el tablero
const HAND_H := 180     # alto de las cartas de la mano
const HELP := "CÓMO JUGAR\n\n1. Cada turno ganas +1 Honor y robas 1 carta.\n2. Baja 1 guerrero pagando su Honor (♦). Las cartas con borde dorado son las que puedes jugar.\n3. Juega acciones (rojas) si quieres.\n4. Ataca al guerrero rival o a su castillo (⚔ = dados que tiras).\n5. Gana quien vacíe el castillo rival (7 cartas).\n\nPasa el mouse sobre una carta para verla grande y leer su efecto.\nAzul = guerrero · Verde = daimyo · Rojo = acción"

var g: Game
var rng := RandomNumberGenerator.new()
var ai_timer: Timer
var info_opp: Label
var info_me: Label
var badge_opp: HonorBadge
var badge_me: HonorBadge
var dice_panel: VBoxContainer
var castle_opp: CastleView
var castle_me: CastleView
var dice_shown_id := 0
var preview_panel: PanelContainer
var choice_overlay: ColorRect
var choice_title: Label
var choice_box: HFlowContainer
var choice_info: Label
var choice_btn: Button
var choice_sel: Array = []
var choice_for := 0
var preview_tex: TextureRect
var duel_busy := false
var zoom_btn: Button
var zoom_id := 0
var zoom_token := 0
var zoom_hovering := false
var zoom_overlay: ColorRect
var zoom_view: TextureRect
var zoom_text: Label
var preview_lbl: Label
var dice_anim_end := 0
var status: Label
var zone_opp: HBoxContainer
var zone_me: HBoxContainer
var hand_box: HBoxContainer
var bar: HBoxContainer
var log_box: RichTextLabel
var sfx_bank: Sfx
var toast_panel: PanelContainer
var toast_lbl: Label
var toast_timer: Timer
var end_overlay: ColorRect
var end_btns := {}
var camp_result := ""
var end_title: Label
var end_sub: Label
var alert_panel: PanelContainer
var alert_lbl: Label
var alert_tween: Tween
var harakiri_dialog: ConfirmationDialog
var help_dialog: AcceptDialog
var peek_btn: Button
var return_btn: Button
var choice_peek := false
var end_hidden := false
var end_played := false
var prev_phase := ""
var pile_deck: Array = [null, null]      # mazo de cada jugador
var pile_disc: Array = [null, null]      # pozo de descarte de cada jugador
var active_btn: Array = [null, null]     # carta activa dibujada (para animar su salida)
var last_active_rect: Array = [Rect2(), Rect2()]
var fx_layer: Control
var pile_overlay: ColorRect
var pile_title: Label
var pile_box: HFlowContainer

func _ready() -> void:
	UiFont.apply(self)
	CardDB.load_all()
	rng.randomize()
	_build_ui()
	_new_game()

func _new_game() -> void:
	end_hidden = false
	end_played = false
	camp_result = ""
	choice_peek = false
	prev_phase = ""
	if end_overlay != null:
		end_overlay.visible = false
	g = Game.new()
	g.sfx_enabled = true
	var deck_me: Array = GameConfig.deck_me if not GameConfig.deck_me.is_empty() else DeckBuilder.random_deck(rng)
	var deck_opp: Array = GameConfig.deck_opp if not GameConfig.deck_opp.is_empty() else DeckBuilder.random_deck(rng)
	if GameConfig.deck_opp.is_empty() and GameConfig.difficulty >= 2:   # Difícil y Pesadilla: la IA usa un mazo temático fuerte
		var fuertes := [4, 0]   # Unificadores, Sombras Ninja (los de más victorias en el análisis de balance)
		var pk: int = fuertes[rng.randi() % fuertes.size()]
		deck_opp = DeckStore.preset_deck(pk)
	g.setup(deck_me, deck_opp, rng.randi(), ["Tú", "Rival IA"])
	g.ai_level = GameConfig.difficulty
	g.changed.connect(_refresh)
	_refresh()

# ------------------------------------------------------------------ construcción

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bgtex: Texture2D = ExtraArt.season_bg("campo", ExtraArt.resolve_season(GameConfig.season, rng))
	if bgtex == null:
		bgtex = CardArt._load_path("res://assets/fondo.jpg")
	if bgtex != null:                                  # campo de batalla de fondo
		var pic := TextureRect.new()
		pic.texture = bgtex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.modulate = Color(0.62, 0.62, 0.66)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)

	var cols := HBoxContainer.new()                  # tablero a la izquierda, registro y dados a la derecha
	cols.set_anchors_preset(Control.PRESET_FULL_RECT)
	cols.offset_left = 10
	cols.offset_right = -10
	cols.offset_top = 8
	cols.offset_bottom = -8
	cols.add_theme_constant_override("separation", 10)
	add_child(cols)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	cols.add_child(root)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(270, 0)
	side.add_theme_constant_override("separation", 6)
	cols.add_child(side)

	# --- tablero
	var zr1 := _zone_row(root)
	zone_opp = zr1[0]
	castle_opp = zr1[1]
	pile_deck[1] = zr1[2]
	pile_disc[1] = zr1[3]
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(gap)
	var zr2 := _zone_row(root)
	zone_me = zr2[0]
	castle_me = zr2[1]
	pile_deck[0] = zr2[2]
	pile_disc[0] = zr2[3]
	bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, HAND_H + 22)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 6)
	sc.add_child(hand_box)

	# --- columna derecha: marcadores, mensaje, registro de la partida y dados
	var tools := HFlowContainer.new()
	tools.add_theme_constant_override("separation", 6)
	side.add_child(tools)
	sfx_bank = Sfx.new()
	add_child(sfx_bank)
	var snd := Button.new()
	snd.text = "Sonido: sí"
	snd.focus_mode = Control.FOCUS_NONE
	snd.pressed.connect(func():
		sfx_bank.enabled = not sfx_bank.enabled
		snd.text = "Sonido: sí" if sfx_bank.enabled else "Sonido: no")
	tools.add_child(snd)
	var dz := Button.new()
	dz.text = "Duelo 2D: sí"
	dz.focus_mode = Control.FOCUS_NONE
	dz.tooltip_text = "Escena animada del duelo de dados (un clic la salta)"
	dz.pressed.connect(func():
		GameConfig.duel_anim = not GameConfig.duel_anim
		dz.text = "Duelo 2D: sí" if GameConfig.duel_anim else "Duelo 2D: no")
	tools.add_child(dz)
	var hb := Button.new()
	hb.text = "? Ayuda"
	hb.focus_mode = Control.FOCUS_NONE
	hb.pressed.connect(func(): help_dialog.popup_centered())
	tools.add_child(hb)
	var r1 := _info_row(side)
	info_opp = r1[0]
	badge_opp = r1[1]
	var r2 := _info_row(side)
	info_me = r2[0]
	badge_me = r2[1]
	status = _label(side)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(260, 84)
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	var logp := PanelContainer.new()
	logp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	logp.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.55), Color(0.5, 0.42, 0.25), 1))
	side.add_child(logp)
	log_box = RichTextLabel.new()
	log_box.scroll_following = true
	logp.add_child(log_box)
	var dp := PanelContainer.new()
	dp.custom_minimum_size = Vector2(0, 190)
	dp.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.55), Color(0.5, 0.42, 0.25), 1))
	side.add_child(dp)
	var dice_scroll := ScrollContainer.new()
	dice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dice_scroll)
	dice_panel = VBoxContainer.new()
	dice_panel.custom_minimum_size = Vector2(250, 0)
	dice_panel.add_theme_constant_override("separation", 3)
	dice_scroll.add_child(dice_panel)

	# --- vista ampliada de la carta bajo el mouse
	preview_panel = PanelContainer.new()
	preview_panel.visible = false
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.z_index = 150
	preview_panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.07, 0.06, 0.96), Color(1.0, 0.85, 0.3), 3))
	var pv := VBoxContainer.new()
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(pv)
	preview_tex = TextureRect.new()
	preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(preview_tex)
	preview_lbl = Label.new()
	preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_lbl.add_theme_font_size_override("font_size", 15)
	preview_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(preview_lbl)
	add_child(preview_panel)
	_build_zoom()

	# --- ventana de decisión (la abre cualquier efecto que pida elegir algo)
	choice_overlay = ColorRect.new()
	choice_overlay.color = Color(0, 0, 0, 0.62)
	choice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_overlay.z_index = 100
	choice_overlay.visible = false
	add_child(choice_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice_overlay.add_child(cc)
	var cpanel := PanelContainer.new()
	cpanel.add_theme_stylebox_override("panel", _style(Color(0.10, 0.09, 0.08), Color(1.0, 0.85, 0.3), 3))
	cc.add_child(cpanel)
	var cvb := VBoxContainer.new()
	cvb.add_theme_constant_override("separation", 10)
	cvb.custom_minimum_size = Vector2(740, 0)
	cpanel.add_child(cvb)
	choice_title = Label.new()
	choice_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_title.custom_minimum_size = Vector2(720, 0)
	choice_title.add_theme_font_size_override("font_size", 20)
	choice_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	cvb.add_child(choice_title)
	var csc := ScrollContainer.new()
	csc.custom_minimum_size = Vector2(720, 300)
	csc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cvb.add_child(csc)
	choice_box = HFlowContainer.new()
	choice_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_box.add_theme_constant_override("h_separation", 8)
	choice_box.add_theme_constant_override("v_separation", 8)
	csc.add_child(choice_box)
	choice_info = Label.new()
	cvb.add_child(choice_info)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	cvb.add_child(crow)
	choice_btn = Button.new()
	choice_btn.focus_mode = Control.FOCUS_NONE
	choice_btn.custom_minimum_size = Vector2(0, 44)
	choice_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_btn(choice_btn, "good")
	choice_btn.pressed.connect(func(): g.choose(choice_sel.duplicate()))
	crow.add_child(choice_btn)
	peek_btn = Button.new()
	peek_btn.text = "Ver el tablero"
	peek_btn.focus_mode = Control.FOCUS_NONE
	peek_btn.custom_minimum_size = Vector2(190, 44)
	_style_btn(peek_btn, "neutral")
	peek_btn.pressed.connect(func():
		choice_peek = true
		_update_choice())
	crow.add_child(peek_btn)
	return_btn = Button.new()                       # aparece mientras miras el tablero
	return_btn.text = "↩  Volver a la decisión"
	return_btn.focus_mode = Control.FOCUS_NONE
	return_btn.custom_minimum_size = Vector2(300, 48)
	_style_btn(return_btn, "gold")
	return_btn.z_index = 120
	return_btn.visible = false
	return_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	return_btn.offset_left = -150
	return_btn.offset_right = 150
	return_btn.offset_top = 10
	return_btn.pressed.connect(func():
		choice_peek = false
		_update_choice())
	add_child(return_btn)

	# --- visor del pozo de descarte
	pile_overlay = ColorRect.new()
	pile_overlay.color = Color(0, 0, 0, 0.62)
	pile_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pile_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pile_overlay.z_index = 105
	pile_overlay.visible = false
	add_child(pile_overlay)
	var pcc := CenterContainer.new()
	pcc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pile_overlay.add_child(pcc)
	var ppanel := PanelContainer.new()
	ppanel.add_theme_stylebox_override("panel", _style(Color(0.10, 0.09, 0.08), Color(1.0, 0.85, 0.3), 3))
	pcc.add_child(ppanel)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 10)
	pvb.custom_minimum_size = Vector2(900, 0)
	ppanel.add_child(pvb)
	pile_title = Label.new()
	pile_title.add_theme_font_size_override("font_size", 22)
	pile_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	pvb.add_child(pile_title)
	var psc := ScrollContainer.new()
	psc.custom_minimum_size = Vector2(880, 380)
	psc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pvb.add_child(psc)
	pile_box = HFlowContainer.new()
	pile_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_box.add_theme_constant_override("h_separation", 8)
	pile_box.add_theme_constant_override("v_separation", 8)
	psc.add_child(pile_box)
	var pclose := Button.new()
	pclose.text = "Cerrar"
	pclose.focus_mode = Control.FOCUS_NONE
	pclose.custom_minimum_size = Vector2(0, 44)
	_style_btn(pclose, "neutral")
	pclose.pressed.connect(func(): pile_overlay.visible = false)
	pvb.add_child(pclose)
	for q in 2:
		var qq: int = q
		pile_disc[q].clicked.connect(func(): _open_pile(qq))
	fx_layer = Control.new()                         # cartas que vuelan entre zonas
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.z_index = 160
	add_child(fx_layer)

	# --- aviso de descarte (más de 7 cartas)
	alert_panel = PanelContainer.new()
	alert_panel.z_index = 90
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.visible = false
	alert_panel.add_theme_stylebox_override("panel", _style(Color(0.35, 0.05, 0.05, 0.93), Color(1.0, 0.8, 0.2), 4))
	alert_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	alert_panel.offset_left = -300
	alert_panel.offset_right = 300
	alert_panel.offset_top = 150
	add_child(alert_panel)
	var ah := HBoxContainer.new()
	ah.add_theme_constant_override("separation", 14)
	ah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.add_child(ah)
	ah.add_child(AlertIcon.new())
	alert_lbl = Label.new()
	alert_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_lbl.custom_minimum_size = Vector2(380, 0)
	alert_lbl.add_theme_font_size_override("font_size", 22)
	alert_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	alert_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ah.add_child(alert_lbl)

	# --- mensaje emergente (efectos giratorios, etc.)
	toast_panel = PanelContainer.new()
	toast_panel.z_index = 130
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.visible = false
	toast_panel.add_theme_stylebox_override("panel", _style(Color(0.12, 0.08, 0.2, 0.95), Color(0.75, 0.6, 1.0), 3))
	toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_panel.offset_left = -330
	toast_panel.offset_right = 330
	toast_panel.offset_top = 70
	add_child(toast_panel)
	toast_lbl = Label.new()
	toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_lbl.custom_minimum_size = Vector2(620, 0)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_font_size_override("font_size", 24)
	toast_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	toast_panel.add_child(toast_lbl)
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.timeout.connect(func(): toast_panel.visible = false)
	add_child(toast_timer)

	# --- victoria / derrota
	end_overlay = ColorRect.new()
	end_overlay.color = Color(0, 0, 0, 0.7)
	end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	end_overlay.z_index = 140
	end_overlay.visible = false
	add_child(end_overlay)
	var ec := CenterContainer.new()
	ec.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_overlay.add_child(ec)
	var evb := VBoxContainer.new()
	evb.add_theme_constant_override("separation", 14)
	evb.custom_minimum_size = Vector2(760, 0)
	ec.add_child(evb)
	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 96)
	end_title.add_theme_constant_override("outline_size", 12)
	end_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	evb.add_child(end_title)
	end_sub = Label.new()
	end_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_sub.add_theme_font_size_override("font_size", 22)
	evb.add_child(end_sub)
	var erow := HBoxContainer.new()
	erow.alignment = BoxContainer.ALIGNMENT_CENTER
	erow.add_theme_constant_override("separation", 12)
	evb.add_child(erow)
	for spec in [["▶  Nueva partida", "gold", "new"], ["Volver a la campaña", "good", "camp"], ["☰  Menú", "neutral", "menu"], ["Ver el tablero", "go", "peek"]]:
		var eb := Button.new()
		eb.text = spec[0]
		eb.focus_mode = Control.FOCUS_NONE
		eb.custom_minimum_size = Vector2(200, 52)
		_style_btn(eb, spec[1])
		var act: String = spec[2]
		end_btns[act] = eb
		eb.pressed.connect(func():
			if act == "new":
				_new_game()
			elif act == "camp":
				GameConfig.start_screen = "campana"
				_to_menu()
			elif act == "menu":
				_to_menu()
			else:
				end_hidden = true
				end_overlay.visible = false)
		erow.add_child(eb)

	# --- diálogos
	harakiri_dialog = ConfirmationDialog.new()
	harakiri_dialog.title = "Harakiri"
	harakiri_dialog.dialog_text = "¿Rendirte con Honor?\nPerderás esta partida."
	harakiri_dialog.ok_button_text = "Sí, Harakiri"
	harakiri_dialog.cancel_button_text = "Seguir luchando"
	harakiri_dialog.confirmed.connect(func(): g.surrender(HUMAN))
	add_child(harakiri_dialog)
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Cómo jugar"
	help_dialog.dialog_text = HELP
	help_dialog.ok_button_text = "Entendido"
	add_child(help_dialog)

	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.timeout.connect(_ai_step)
	add_child(ai_timer)

func _info_row(parent: Node) -> Array:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	var t := Label.new()
	t.text = "HONOR"
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	h.add_child(t)
	var b := HonorBadge.new()
	h.add_child(b)
	var l := Label.new()
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_font_size_override("font_size", 14)
	h.add_child(l)
	return [l, b]

func _style_btn(b: Button, kind: String) -> void:
	var base: Color = BTN_COLORS.get(kind, BTN_COLORS["neutral"])
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	b.add_theme_stylebox_override("normal", _btn_box(base, base.lightened(0.45), true))
	b.add_theme_stylebox_override("hover", _btn_box(base.lightened(0.18), Color.WHITE, true))
	b.add_theme_stylebox_override("pressed", _btn_box(base.darkened(0.2), Color.WHITE, false))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(0.22, 0.22, 0.24), Color(0.32, 0.32, 0.34), false))

func _update_choice() -> void:
	if g.phase == "CHOICE" and g.pending.player == HUMAN:
		if choice_for != g.pending_id:
			choice_for = g.pending_id
			choice_sel = []
			choice_peek = false
		_fill_choice()
		choice_overlay.visible = not choice_peek
		return_btn.visible = choice_peek
	else:
		choice_overlay.visible = false
		return_btn.visible = false
		choice_peek = false
		choice_for = 0

func _fill_choice() -> void:
	var pd: Dictionary = g.pending
	var valid: Array = pd.valid
	choice_title.text = pd.prompt
	_clear(choice_box)
	for i in pd.options.size():
		var o: Dictionary = pd.options[i]
		var picked: bool = i in choice_sel
		var b: Button
		if o.has("card"):
			b = _card_btn(o.card, true, func(): _toggle_choice(i), 170)
		elif o.has("die"):      # un dado dibujado (Hidetoshi)
			b = Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(92, 96)
			_style_btn(b, "go")
			b.pressed.connect(func(): _toggle_choice(i))
			var face := DieFace.new(o.die, 46)
			face.position = Vector2(23, 8)
			b.add_child(face)
			var lb := Label.new()
			lb.text = str(o.label)
			lb.position = Vector2(8, 62)
			lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(lb)
		else:
			b = Button.new()
			b.text = str(o.label)
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(120, 64)
			_style_btn(b, "go")
			b.add_theme_font_size_override("font_size", 24 if str(o.label).length() <= 8 else 16)
			b.pressed.connect(func(): _toggle_choice(i))
		if picked:
			b.modulate = Color(1.0, 1.0, 0.45)
			var ck := Label.new()
			ck.text = str(choice_sel.find(i) + 1) if pd.mode == "order" else "✔"
			ck.add_theme_font_size_override("font_size", 30)
			ck.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			ck.position = Vector2(6, 0)
			ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ck)
		choice_box.add_child(b)
	var parts := []
	for v in valid:
		parts.append(str(v))
	if pd.mode == "info":
		choice_info.text = "Solo para mirar. Cierra la ventana cuando termines."
	elif pd.mode == "order":
		choice_info.text = "Haz clic en las cartas en el orden deseado: la 1 quedará arriba del mazo (llevas %d de %d)." % [choice_sel.size(), valid[0]]
	elif valid.size() == 1:
		choice_info.text = "Elige %d (llevas %d)." % [valid[0], choice_sel.size()]
	elif valid.size() > 2 and valid[valid.size() - 1] - valid[0] == valid.size() - 1:
		var zero := " Confirma sin elegir nada para no hacerlo." if valid[0] == 0 else ""
		choice_info.text = "Elige entre %d y %d (llevas %d).%s" % [valid[0], valid[valid.size() - 1], choice_sel.size(), zero]
	else:
		choice_info.text = "Elige %s (llevas %d). Si no eliges ninguna, no se usa el efecto." % [" o ".join(parts), choice_sel.size()]
	choice_btn.disabled = not (choice_sel.size() in valid)
	choice_btn.text = "Cerrar" if pd.mode == "info" else "Confirmar"

func _toggle_choice(i: int) -> void:
	var maxn: int = g.pending.valid.max()
	if i in choice_sel:
		choice_sel.erase(i)
	elif choice_sel.size() < maxn:
		choice_sel.append(i)
	elif maxn == 1:
		choice_sel = [i]
	_fill_choice()

const ROLL_TIME := 0.9

func _draw_dice() -> void:
	var rolling := false
	if g.duel_id != 0 and g.duel_id != dice_shown_id:
		dice_shown_id = g.duel_id          # duelo nuevo: animar
		dice_anim_end = Time.get_ticks_msec() + int(ROLL_TIME * 1000.0)
		get_tree().create_timer(ROLL_TIME + 0.05).timeout.connect(_end_roll.bind(g.duel_id))
		rolling = true
	elif Time.get_ticks_msec() < dice_anim_end:
		return                              # animación en curso: no redibujar
	_clear(dice_panel)
	if g.last_duel.is_empty():
		var e := Label.new()
		e.text = "Aquí verás los dados de cada duelo."
		dice_panel.add_child(e)
		return
	var d: Dictionary = g.last_duel
	for p in [1, 0]:
		var head := Label.new()
		var mark := "  ✔ GANA" if d.winner == p else ""
		if rolling:
			head.text = "%s (%s): …" % [g.players[p].name, d.names[p]]
		else:
			head.text = "%s (%s): %d%s" % [g.players[p].name, d.names[p], d.totals[p], mark]
		head.add_theme_color_override("font_color", Color(1, 0.9, 0.4) if d.winner == p else Color.WHITE)
		dice_panel.add_child(head)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		for v in d.rolls[p]:
			var die := DieFace.new(v, 34)
			flow.add_child(die)
			if rolling:
				die.start_roll(v, ROLL_TIME)
		if d.points[p] > 0 and not rolling:
			var plus := Label.new()
			plus.text = "+%d" % d.points[p]
			plus.add_theme_font_size_override("font_size", 20)
			flow.add_child(plus)
		dice_panel.add_child(flow)
	if d.ties > 0 and not rolling:
		var t := Label.new()
		t.text = "(hubo %d empate(s) y se volvió a tirar)" % d.ties
		dice_panel.add_child(t)

func _zone_row(parent: Node) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.42), Color(0.45, 0.38, 0.22, 0.8), 1))
	parent.add_child(panel)
	var outer := HBoxContainer.new()
	outer.custom_minimum_size = Vector2(0, ZONE_H + 14)
	panel.add_child(outer)
	var piles := VBoxContainer.new()                 # mazo (arriba) y pozo de descarte (abajo)
	piles.add_theme_constant_override("separation", 4)
	piles.custom_minimum_size = Vector2(86, 0)
	outer.add_child(piles)
	var deck_pile := PileView.new("mazo", "MAZO")
	piles.add_child(deck_pile)
	var disc_pile := PileView.new("pozo", "POZO")
	piles.add_child(disc_pile)
	var zsc := ScrollContainer.new()
	zsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zsc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(zsc)
	var zone := HBoxContainer.new()
	zone.add_theme_constant_override("separation", 6)
	zsc.add_child(zone)
	var castle := CastleView.new()
	outer.add_child(castle)
	return [zone, castle, deck_pile, disc_pile]

func _end_roll(id: int) -> void:
	if id == g.duel_id:
		dice_anim_end = 0
		_draw_dice()

func _label(parent: Node) -> Label:
	var l := Label.new()
	parent.add_child(l)
	return l

func _row(parent: Node) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 120)
	h.add_theme_constant_override("separation", 6)
	parent.add_child(h)
	return h

func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

# ------------------------------------------------------------------ dibujo

func _card_text(id: int) -> String:
	var c := g.card(id)
	if c.categoria == "Accion":
		var mark := "" if Effects.is_implemented_action(id) else "\n(sin implementar)"
		return "%s\nBushi%s" % [c.nombre, mark]
	return "%s\n%s\n⚔ %d   ♦ %d  [%s]" % [c.nombre, c.clan, c.ataque, c.costo_honor, c.duracion]

func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6)
	return sb

## Carta con su imagen real (si existe en assets/cartas/).
func _art_btn(id: int, tex: Texture2D, enabled: bool, cb: Callable, h: int) -> Button:
	var b := Button.new()
	var aspect := float(tex.get_width()) / float(tex.get_height())
	b.custom_minimum_size = Vector2(int(h * aspect), h)
	b.disabled = false   # el "apagado" se dibuja con el color de la imagen
	b.focus_mode = Control.FOCUS_NONE
	var border := Color(1.0, 0.85, 0.3) if enabled else Color(0.25, 0.25, 0.25)
	var width := 3 if enabled else 1
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(0, 0, 0, 0)
	empty.border_color = border
	empty.set_border_width_all(width)
	empty.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", empty)
	var hov := empty.duplicate()
	hov.border_color = Color(1, 1, 0.7)
	hov.set_border_width_all(3)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_stylebox_override("disabled", empty)
	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.modulate = Color.WHITE if enabled else Color(0.45, 0.45, 0.45)
	b.add_child(img)
	b.mouse_entered.connect(func(): _show_detail(id); _zoom_show(id, b))
	b.mouse_exited.connect(func(): _hide_preview(); _zoom_leave())
	if cb.is_valid() and enabled:
		b.pressed.connect(cb)
	return b

func _card_btn(id: int, enabled: bool, cb: Callable = Callable(), h: int = ZONE_H) -> Button:
	var tex := CardArt.get_texture(id)
	if tex != null:
		return _art_btn(id, tex, enabled, cb, h)
	var b := Button.new()
	b.custom_minimum_size = Vector2(maxi(120, int(h * 0.8)), h)
	b.text = _card_text(id)
	b.disabled = not enabled
	var cat: String = g.card(id).categoria
	var base := Color(0.16, 0.24, 0.36)          # guerrero: azul
	if cat == "Daimyo":
		base = Color(0.15, 0.32, 0.20)           # daimyo: verde
	elif cat == "Accion":
		base = Color(0.38, 0.16, 0.16)           # bushi: rojo
	b.add_theme_stylebox_override("normal", _style(base, Color(1.0, 0.85, 0.3), 3))
	b.add_theme_stylebox_override("hover", _style(base.lightened(0.2), Color(1, 1, 0.7), 3))
	b.add_theme_stylebox_override("pressed", _style(base.lightened(0.3), Color.WHITE, 3))
	b.add_theme_stylebox_override("disabled", _style(base.darkened(0.45), base.lightened(0.1), 1))
	b.add_theme_color_override("font_disabled_color", Color(0.62, 0.62, 0.62))
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_entered.connect(func(): _show_detail(id); _zoom_show(id, b))
	b.mouse_exited.connect(func(): _hide_preview(); _zoom_leave())
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

# ---------------------------------------------------------------- zoom de cartas (lupa)

func _build_zoom() -> void:
	zoom_btn = Button.new()
	zoom_btn.text = "Zoom"
	zoom_btn.focus_mode = Control.FOCUS_NONE
	zoom_btn.z_index = 190
	zoom_btn.visible = false
	zoom_btn.custom_minimum_size = Vector2(86, 30)
	zoom_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	zoom_btn.add_theme_font_size_override("font_size", 15)
	zoom_btn.add_theme_stylebox_override("normal", _style(Color(0.1, 0.08, 0.05, 0.92), Color(1.0, 0.85, 0.3), 2))
	zoom_btn.add_theme_stylebox_override("hover", _style(Color(0.35, 0.25, 0.08, 0.98), Color(1, 1, 0.7), 2))
	zoom_btn.add_theme_stylebox_override("pressed", _style(Color(0.5, 0.35, 0.1, 1.0), Color.WHITE, 2))
	var ic := MagnifierIcon.new()
	ic.position = Vector2(8, 4)
	zoom_btn.add_child(ic)
	zoom_btn.mouse_entered.connect(func(): zoom_hovering = true; zoom_token += 1)
	zoom_btn.mouse_exited.connect(func(): zoom_hovering = false; _zoom_leave())
	zoom_btn.pressed.connect(func(): _open_zoom(zoom_id))
	add_child(zoom_btn)
	zoom_overlay = ColorRect.new()
	zoom_overlay.color = Color(0, 0, 0, 0.94)
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	zoom_overlay.z_index = 200
	zoom_overlay.visible = false
	zoom_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_close_zoom())
	add_child(zoom_overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 20
	box.offset_right = -20
	box.offset_top = 12
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(box)
	zoom_view = TextureRect.new()
	zoom_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	zoom_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zoom_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zoom_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(zoom_view)
	zoom_text = Label.new()
	zoom_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zoom_text.add_theme_font_size_override("font_size", 20)
	zoom_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(zoom_text)

func _zoom_show(id: int, b: Control) -> void:
	zoom_token += 1
	zoom_id = id
	var r := b.get_global_rect()
	var bw := 86.0
	var pos := Vector2(r.position.x + r.size.x * 0.5 - bw * 0.5, r.position.y + 6.0)
	pos.x = clampf(pos.x, 4.0, size.x - bw - 4.0)
	pos.y = clampf(pos.y, 4.0, size.y - 36.0)
	zoom_btn.position = pos
	zoom_btn.size = Vector2(bw, 30)
	zoom_btn.visible = true

func _zoom_leave() -> void:
	zoom_token += 1
	var tk := zoom_token
	await get_tree().create_timer(0.25).timeout
	if tk == zoom_token and not zoom_hovering and zoom_btn != null:
		zoom_btn.visible = false

func _zoom_hide_now() -> void:
	zoom_token += 1
	zoom_hovering = false
	if zoom_btn != null:
		zoom_btn.visible = false

func _open_zoom(id: int) -> void:
	if id == 0:
		return
	var tex := CardArt.get_texture(id)
	var c := g.card(id)
	zoom_view.texture = tex
	zoom_view.visible = tex != null
	var head: String = c.nombre
	if c.categoria != "Accion":
		head += "  ·  Clan %s  ·  Ataque %d  ·  Honor %d" % [c.clan, c.ataque, c.costo_honor]
	zoom_text.text = ((head + "\n\n" + c.efecto + "\n\n") if tex == null else "") + "Clic o Esc para cerrar"
	zoom_text.add_theme_font_size_override("font_size", 28 if tex == null else 20)
	zoom_text.size_flags_vertical = Control.SIZE_EXPAND_FILL if tex == null else Control.SIZE_SHRINK_BEGIN
	zoom_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zoom_overlay.visible = true
	_hide_preview()
	_zoom_hide_now()

func _close_zoom() -> void:
	zoom_overlay.visible = false

func _unhandled_input(ev: InputEvent) -> void:
	if zoom_overlay != null and zoom_overlay.visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_close_zoom()
		get_viewport().set_input_as_handled()

func _show_detail(id: int) -> void:
	var c := g.card(id)
	var head: String = c.nombre + "\n"
	if c.categoria != "Accion":
		head += "Clan %s · Ataque %d · Honor %d\n" % [c.clan, c.ataque, c.costo_honor]
	var note := ""
	if g.is_giratorio(id):
		note += "\n\nCarta giratoria: haz clic en ella en tu turno para colocarla boca abajo (máx. 2). Se revela sola cuando ocurre su condición."
	if Effects.ABILITY_TEXT.has(id):
		note += "\n\n★ Habilidad activa: úsala con el botón «Habilidades» (una vez por turno)."
	_show_preview(id, head + c.efecto + note)

func _show_preview(id: int, text: String) -> void:
	var tex := CardArt.get_texture(id)
	var tw := 300.0
	var th := 0.0
	if tex != null:
		var aspect := float(tex.get_width()) / float(tex.get_height())
		th = 360.0
		tw = th * aspect
		if tw > 420.0:
			tw = 420.0
			th = tw / aspect
	preview_tex.texture = tex
	preview_tex.custom_minimum_size = Vector2(tw, th)
	preview_lbl.custom_minimum_size = Vector2(tw, 0)
	preview_lbl.text = text
	preview_panel.size = Vector2(tw + 20.0, 0.0)
	preview_panel.position = Vector2(size.x - tw - 30.0, 40.0)
	preview_panel.visible = true
	_fit_preview.call_deferred()

func _fit_preview() -> void:
	var ms := preview_panel.get_combined_minimum_size()
	preview_panel.size = Vector2(ms.x, ms.y)

func _hide_preview() -> void:
	if preview_panel != null:
		preview_panel.visible = false

func _zone(box: HBoxContainer, p: int) -> void:
	_clear(box)
	active_btn[p] = null
	var pl = g.players[p]
	var lbl := Label.new()
	lbl.text = "ACTIVO"
	box.add_child(lbl)
	if pl.active != 0:
		var ab := _card_btn(pl.active, true)
		_add_attack_badge(ab, p)
		box.add_child(ab)
		active_btn[p] = ab
	else:
		var e := Label.new()
		e.text = "(vacío)  "
		box.add_child(e)
	var sep := VSeparator.new()
	box.add_child(sep)
	var l2 := Label.new()
	l2.text = "PASIVOS"
	box.add_child(l2)
	for id in pl.passive:
		box.add_child(_card_btn(id, true))
	if not pl.facedown.is_empty():
		box.add_child(VSeparator.new())
		var lf := Label.new()
		lf.text = "BOCA ABAJO"
		box.add_child(lf)
		for id in pl.facedown:
			if p == HUMAN:
				box.add_child(_card_btn(id, true))
			else:
				var hb := Button.new()
				hb.custom_minimum_size = Vector2(int(ZONE_H * 0.7), ZONE_H)
				hb.text = "?\nBoca\nabajo"
				hb.focus_mode = Control.FOCUS_NONE
				_style_btn(hb, "neutral")
				hb.add_theme_font_size_override("font_size", 13)
				box.add_child(hb)
	if not pl.temple.is_empty():
		box.add_child(VSeparator.new())
		var lt := Label.new()
		var parts := []
		for t in pl.temple.heroes:
			parts.append("%s (%d)" % [g.card(t.id).nombre, t.left])
		lt.text = "⛩ COMPLEJO ENRYAKU-JI (cap. %d)\n%s" % [Effects.temple_cap(g, p), ", ".join(parts) if not parts.is_empty() else "vacío"]
		lt.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		lt.add_theme_font_size_override("font_size", 13)
		lt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lt.custom_minimum_size = Vector2(150, 0)
		box.add_child(lt)
	# permite leer el efecto de cartas "deshabilitadas"
	for b in box.get_children():
		if b is Button:
			b.mouse_filter = Control.MOUSE_FILTER_PASS
			b.focus_mode = Control.FOCUS_NONE

## Marca sobre el guerrero activo con los dados que lanza ahora (con los aumentos o rebajas de efectos).
func _add_attack_badge(btn: Button, p: int) -> void:
	var pl = g.players[p]
	var d: Dictionary = g.dice_for(p, g.turn_player == p)
	var base: int = g.card(pl.active).ataque
	var txt := "⚔ %d" % d.n
	if d.n != base:
		txt += " (%s%d)" % ["+" if d.n > base else "", d.n - base]
	if d.points > 0:
		txt += "  +%d pts" % d.points
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55) if d.n > base else (Color(1.0, 0.55, 0.5) if d.n < base else Color.WHITE))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := PanelContainer.new()
	back.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.75), Color(1, 0.85, 0.3), 1))
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.position = Vector2(4, 4)
	back.add_child(lbl)
	btn.add_child(back)

func _info(p: int) -> String:
	var pl = g.players[p]
	return "%s\nMano %d · Mazo %d · Castillo %d/7 · Pozo %d" % [
		pl.name, pl.hand.size(), pl.deck.size(), pl.castle.size(), pl.discard.size()]

func _refresh() -> void:
	_hide_preview()
	_zoom_hide_now()
	for q in 2:                           # posición de la carta activa antes de redibujar (para animar su salida)
		if is_instance_valid(active_btn[q]):
			last_active_rect[q] = active_btn[q].get_global_rect()
	var seen := {}
	for n in g.sfx:                       # sonidos pedidos por el motor (sin repetir el mismo en un instante)
		if not seen.has(n):
			seen[n] = true
			sfx_bank.play(n)
	g.sfx.clear()
	if not g.toasts.is_empty():           # mensajes emergentes (efectos giratorios)
		toast_lbl.text = "¡Efecto giratorio!\n" + "\n".join(g.toasts)
		toast_panel.visible = true
		toast_timer.start(3.4)
		sfx_bank.play("giratoria")
		g.toasts.clear()
	info_opp.text = _info(1)
	info_me.text = _info(0)
	badge_opp.value = g.players[1].honor
	badge_me.value = g.players[0].honor
	castle_opp.count = g.players[1].castle.size()
	castle_me.count = g.players[0].castle.size()
	_draw_dice()
	_zone(zone_opp, 1)
	_zone(zone_me, 0)
	for q in 2:
		var pl_q = g.players[q]
		pile_deck[q].count = pl_q.deck.size()
		pile_disc[q].count = pl_q.discard.size()
		if pl_q.discard.is_empty():
			pile_disc[q].top_id = 0
			pile_disc[q].top_tex = null
			pile_disc[q].top_name = ""
		else:
			var top: int = pl_q.discard[pl_q.discard.size() - 1]
			pile_disc[q].top_id = top
			pile_disc[q].top_tex = CardArt.get_texture(top)
			pile_disc[q].top_name = g.card(top).nombre
		pile_deck[q].tooltip_text = "Mazo de %s: %d cartas" % [pl_q.name, pl_q.deck.size()]
		pile_disc[q].tooltip_text = "Pozo de %s: %d cartas (clic para ver)" % [pl_q.name, pl_q.discard.size()]
	log_box.text = "\n".join(g.log_lines.slice(maxi(0, g.log_lines.size() - 40)))
	_clear(bar)
	_clear(hand_box)
	var mine: bool = g.phase != "OVER" and g.actor() == HUMAN
	var me = g.players[HUMAN]

	for i in me.hand.size():
		var id: int = me.hand[i]
		var ok := false
		var cb := Callable()
		match g.phase:
			"MAIN":
				if g.is_hero(id):
					ok = mine and g.can_play_warrior(HUMAN, id)
					cb = func(): g.play_warrior(i)
				else:
					ok = mine and Effects.can_play(g, HUMAN, id)
					cb = func(): g.play_action(i)
			"WINDOW":
				ok = mine and not g.is_hero(id) and Effects.can_play(g, HUMAN, id)
				cb = func(): g.play_action(i)
			"DISCARD":
				ok = mine
				cb = func(): g.discard_card(i)
		var b := _card_btn(id, ok, cb, HAND_H)
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		hand_box.add_child(b)

	match g.phase:
		"OVER":
			status.text = "¡Fin de la partida! Gana %s." % g.players[g.winner].name
			_add_btn("▶  Nueva partida", _new_game, true, "gold")
			_add_btn("☰  Menú", _to_menu, true, "neutral")
			if end_hidden:
				_add_btn("Ver resultado", func():
					end_hidden = false
					_refresh(), true, "go")
		"MAIN":
			if mine:
				var playable := 0
				for hid in me.hand:
					if (g.is_hero(hid) and g.can_play_warrior(HUMAN, hid)) or (not g.is_hero(hid) and Effects.can_play(g, HUMAN, hid)):
						playable += 1
				if me.active == 0 and playable == 0:
					status.text = "Tu turno %d (Honor %d): no puedes bajar ni jugar nada todavía. Pulsa «Terminar turno»; mañana tendrás 1 Honor más." % [g.turn_number, me.honor]
				elif me.active == 0:
					status.text = "Tu turno %d: baja un guerrero (cartas con borde dorado) para poder atacar." % g.turn_number
				elif playable > 0:
					status.text = "Tu turno %d: puedes jugar cartas de tu mano o atacar con %s." % [g.turn_number, g.card(me.active).nombre]
				else:
					status.text = "Tu turno %d: ataca con %s o termina el turno." % [g.turn_number, g.card(me.active).nombre]
			else:
				status.text = "Turno del rival…"
			if mine:
				var has_active: bool = me.active != 0
				_add_btn("⚔  Atacar al guerrero", func(): g.declare_attack("guerrero"), has_active and g.players[1].active != 0, "attack")
				_add_btn("♜  Atacar el castillo", func(): g.declare_attack("castillo"), has_active, "castle")
				if g.can_swap_active(HUMAN):
					_add_btn("⇄  Cambiar activo", func(): g.open_swap(), true, "gold")
				var abil: Array = g.available_abilities()
				if not abil.is_empty():
					_add_btn("★  Habilidades (%d)" % abil.size(), func(): g.open_abilities(), true, "gold")
				_add_btn("Terminar turno  ▶", func(): g.end_turn(), true, "end")
				_add_btn("☰", _to_menu, true, "neutral")
		"DEFENDER_CHOICE":
			status.text = "El rival ataca tu castillo. ¿Resistes con tu guerrero?" if mine else "El rival decide si resiste…"
			if mine:
				_add_btn("✔  Resistir (duelo de dados)", func(): g.respond(true), true, "good")
				_add_btn("Dejar pasar (pierdes 1 carta del castillo)", func(): g.respond(false), true, "neutral")
		"WINDOW":
			if g.battle.get("rolled", false):
				var r0: Dictionary = g.battle.res[0]
				var r1: Dictionary = g.battle.res[1]
				status.text = "Dados lanzados — tú: %s = %d  vs  rival: %s = %d. %s" % [str(r0.rolls), r0.total, str(r1.rolls), r1.total,
					"Puedes jugar una carta de dados o continuar." if mine else "El rival decide…"]
				if mine:
					_add_btn("▶  Continuar", func(): g.pass_priority(), true, "go")
			else:
				var d1 := g.dice_for(0, g.battle.att == 0)
				var d2 := g.dice_for(1, g.battle.att == 1)
				status.text = "Duelo — tú: %d dado(s)%s  vs  rival: %d dado(s)%s. Puedes jugar acciones de batalla." % [
					d1.n, (" +%d" % d1.points) if d1.points > 0 else "", d2.n, (" +%d" % d2.points) if d2.points > 0 else ""]
				if mine:
					_add_btn("▶  ¡Tirar los dados!", func(): g.pass_priority(), true, "go")
		"CHOICE":
			status.text = ("Decisión: " + g.pending.prompt) if mine else "%s está decidiendo…" % g.players[g.pending.player].name
		"DISCARD":
			status.text = "Tienes más de 7 cartas: haz clic en una carta de tu mano para descartarla." if mine else "El rival descarta…"

	# Harakiri: rendirse con Honor (siempre disponible mientras se juega)
	if g.phase != "OVER":
		var hk := _add_btn("Harakiri", func(): harakiri_dialog.popup_centered(), true, "bad")
		hk.tooltip_text = "¡Rendirse con Honor!"

	# aviso de descarte (más de 7 cartas en la mano)
	var need_alert: bool = g.phase == "DISCARD" and mine
	if need_alert:
		var extra: int = me.hand.size() - Game.HAND_LIMIT
		alert_lbl.text = "¡Tienes %d cartas en la mano!\nDescarta %d carta%s (máximo %d)." % [me.hand.size(), extra, "" if extra == 1 else "s", Game.HAND_LIMIT]
		if not alert_panel.visible:
			sfx_bank.play("aviso")
			if alert_tween != null:
				alert_tween.kill()
			alert_tween = create_tween().set_loops()
			alert_tween.tween_property(alert_panel, "modulate:a", 0.6, 0.55)
			alert_tween.tween_property(alert_panel, "modulate:a", 1.0, 0.55)
		alert_panel.visible = true
	else:
		alert_panel.visible = false
		if alert_tween != null:
			alert_tween.kill()
			alert_tween = null
		alert_panel.modulate.a = 1.0

	# victoria / derrota
	if g.phase == "OVER":
		var won: bool = g.winner == HUMAN
		if not end_played:
			end_played = true
			sfx_bank.play("victoria" if won else "derrota")
		end_title.text = "¡VICTORIA!" if won else "DERROTA"
		end_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25) if won else Color(0.9, 0.2, 0.2))
		end_sub.text = g.log_lines[g.log_lines.size() - 1]
		var camp: bool = GameConfig.campaign_level > 0
		end_btns["camp"].visible = camp
		end_btns["new"].text = ("▶  Reintentar duelo" if camp else "▶  Nueva partida")
		end_btns["new"].visible = not (camp and won)
		if camp and won:
			if camp_result == "":
				var lv: int = GameConfig.campaign_level
				var unlocked := CampaignStore.complete(lv)
				camp_result = "\n\n¡Duelo %d de la campaña superado!" % lv
				if lv >= CampaignStore.count():
					camp_result += " ¡Campaña completada: eres el nuevo Shogun!"
					_show_shogun()
				elif unlocked:
					camp_result += " Se desbloquea el punto %d: %s." % [lv + 1, CampaignStore.LEVELS[lv].mazo]
			end_sub.text += camp_result
		end_sub.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
		end_overlay.visible = not end_hidden
	else:
		end_overlay.visible = false
	prev_phase = g.phase

	_update_choice()
	if not g.moves.is_empty():
		var batch: Array = g.moves.duplicate()
		g.moves.clear()
		var duel := {}
		var rest := []
		for m in batch:
			if m.k == "duel" or m.k == "castle_hit":
				duel = m
			else:
				rest.append(m)
		if duel.is_empty():
			_play_moves(rest)
		else:
			_play_duel(duel, rest)
	if g.phase != "OVER" and g.actor() != HUMAN:
		ai_timer.start(1.9 if Time.get_ticks_msec() < dice_anim_end else 0.8)

const BTN_COLORS := {
	"attack": Color(0.78, 0.15, 0.15),   # rojo: atacar guerrero
	"castle": Color(0.85, 0.45, 0.10),   # naranja: atacar castillo
	"end":    Color(0.25, 0.35, 0.55),   # azul acero: terminar turno
	"good":   Color(0.18, 0.55, 0.28),   # verde: resistir
	"neutral": Color(0.40, 0.40, 0.44),  # gris: dejar pasar
	"go":     Color(0.20, 0.50, 0.75),   # azul: listo
	"gold":   Color(0.80, 0.62, 0.10),   # dorado: nueva partida
}

func _btn_box(fill: Color, border: Color, shadow: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 3)
	return sb

func _add_btn(text: String, cb: Callable, enabled: bool = true, kind: String = "neutral") -> Button:
	var base: Color = BTN_COLORS.get(kind, BTN_COLORS["neutral"])
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	b.add_theme_stylebox_override("normal", _btn_box(base, base.lightened(0.45), true))
	b.add_theme_stylebox_override("hover", _btn_box(base.lightened(0.18), Color.WHITE, true))
	b.add_theme_stylebox_override("pressed", _btn_box(base.darkened(0.2), Color.WHITE, false))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(0.22, 0.22, 0.24), Color(0.32, 0.32, 0.34), false))
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): if not b.disabled: b.scale = Vector2(1.04, 1.04))
	b.mouse_exited.connect(func(): b.scale = Vector2.ONE)
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	bar.add_child(b)
	return b

## Abre el visor del pozo de descarte de p.
func _open_pile(p: int) -> void:
	var pl = g.players[p]
	pile_title.text = "Pozo de descarte de %s (%d cartas, la última descartada primero)" % [pl.name, pl.discard.size()]
	_clear(pile_box)
	if pl.discard.is_empty():
		var e := Label.new()
		e.text = "El pozo está vacío."
		pile_box.add_child(e)
	for i in range(pl.discard.size() - 1, -1, -1):
		var b := _card_btn(pl.discard[i], true, Callable(), 170)
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		pile_box.add_child(b)
	pile_overlay.visible = true

# ------------------------------------------------------------------ animación de cartas

const FLY_W := 74.0
const FLY_H := 104.0

## Punto de la mano de p hacia/desde donde vuelan las cartas.
func _hand_rect(p: int, index_from_end: int) -> Rect2:
	if p == HUMAN:
		var n := hand_box.get_child_count()
		if n > 0:
			var k := clampi(n - 1 - index_from_end, 0, n - 1)
			var c: Control = hand_box.get_child(k)
			return c.get_global_rect()
		return hand_box.get_global_rect()
	return Rect2(size.x * 0.42, -FLY_H - 20.0, FLY_W, FLY_H)       # la mano rival está "fuera de pantalla", arriba

func _play_duel(ev: Dictionary, rest: Array) -> void:
	if GameConfig.duel_anim and DisplayServer.get_name() != "headless":
		duel_busy = true
		await get_tree().process_frame
		_hide_preview()
		_zoom_hide_now()
		if ev.k == "castle_hit":
			var hs := CastleHitScene.new()
			add_child(hs)
			await hs.play_hit(ev, {
				"names": [g.players[0].name, g.players[1].name],
				"card": g.card(ev.id), "tex": CardArt.get_texture(ev.id)}, sfx_bank)
		else:
			var sc := DuelScene.new()
			add_child(sc)
			var ids: Array = ev.ids
			var info := {
				"names": [g.players[0].name, g.players[1].name],
				"cards": [g.card(ids[0]), g.card(ids[1])],
				"tex": [CardArt.get_texture(ids[0]), CardArt.get_texture(ids[1])]}
			await sc.play(ev, info, sfx_bank)
		duel_busy = false
	if not rest.is_empty():
		_play_moves(rest)

func _play_moves(batch: Array) -> void:
	await get_tree().process_frame            # esperar a que el tablero termine de acomodarse
	var human_new := 0
	for m in batch:
		if (m.k == "deck_hand" or m.k == "castle_hand") and m.p == HUMAN:
			human_new += 1
	var hidden := []
	if human_new > 0:                          # las cartas recién robadas aparecen cuando llega la animación
		var n := hand_box.get_child_count()
		for i in range(maxi(0, n - human_new), n):
			var hc: Control = hand_box.get_child(i)
			hc.modulate.a = 0.0
			hidden.append(hc)
	var delay := 0.0
	var drawn_k := 0
	for m in batch:
		var from_r := Rect2()
		var to_r := Rect2()
		var face := 0
		match m.k:
			"deck_hand":
				from_r = pile_deck[m.p].get_global_rect()
				to_r = _hand_rect(m.p, human_new - 1 - drawn_k) if m.p == HUMAN else _hand_rect(m.p, 0)
				if m.p == HUMAN:
					drawn_k += 1
			"castle_hand":
				from_r = (castle_me if m.p == HUMAN else castle_opp).get_global_rect()
				to_r = _hand_rect(m.p, human_new - 1 - drawn_k) if m.p == HUMAN else _hand_rect(m.p, 0)
				if m.p == HUMAN:
					drawn_k += 1
			"field_discard":
				from_r = last_active_rect[m.p]
				to_r = pile_disc[m.p].get_global_rect()
				face = m.id
			"hand_discard":
				from_r = _hand_rect(m.p, 0) if m.p != HUMAN else hand_box.get_global_rect()
				to_r = pile_disc[m.p].get_global_rect()
				face = m.id
		if from_r.size == Vector2.ZERO:
			from_r = Rect2(size * 0.5, Vector2(FLY_W, FLY_H))
		_fly(from_r, to_r, face, delay)
		delay += 0.13
	if not hidden.is_empty():                  # mostrar las cartas robadas al terminar los vuelos
		get_tree().create_timer(delay + 0.5).timeout.connect(func():
			for hc in hidden:
				if is_instance_valid(hc):
					hc.modulate.a = 1.0)

## Una carta que vuela de un rectángulo a otro. face = 0 → dorso.
func _fly(from_r: Rect2, to_r: Rect2, face: int, delay: float) -> void:
	var card := Control.new()
	card.custom_minimum_size = Vector2(FLY_W, FLY_H)
	card.size = Vector2(FLY_W, FLY_H)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	var tex: Texture2D = CardArt.get_texture(face) if face != 0 else null
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(img)
	else:
		var pn := Panel.new()
		var sb := _style(Color(0.42, 0.08, 0.1) if face == 0 else Color(0.2, 0.22, 0.32), Color(0.95, 0.8, 0.35), 3)
		pn.add_theme_stylebox_override("panel", sb)
		pn.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(pn)
		if face != 0:
			var l := Label.new()
			l.text = g.card(face).nombre
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 12)
			l.set_anchors_preset(Control.PRESET_FULL_RECT)
			card.add_child(l)
	fx_layer.add_child(card)
	var start := from_r.get_center() - card.size * 0.5
	var end := to_r.get_center() - card.size * 0.5
	card.position = start
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): card.visible = true)
	tw.tween_property(card, "position", end, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(card, "scale", Vector2(0.9, 0.9), 0.5)
	tw.tween_callback(card.queue_free)

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _ai_step() -> void:
	if duel_busy:
		ai_timer.start(0.3)
		return
	if g.phase != "OVER" and g.actor() != HUMAN:
		AI.act(g)


## Pantalla final de la campaña: el nuevo Shogun.
func _show_shogun() -> void:
	var tex: Texture2D = ExtraArt.shogun()
	if tex == null:
		return
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var pic := TextureRect.new()
	pic.texture = tex
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.offset_top = 70
	pic.offset_bottom = -80
	layer.add_child(pic)
	var t := Label.new()
	t.text = "¡Eres el nuevo Shogun!"
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	t.offset_top = 14
	layer.add_child(t)
	var b := Button.new()
	b.text = "Continuar"
	b.add_theme_font_size_override("font_size", 22)
	b.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	b.offset_left = -90
	b.offset_right = 90
	b.offset_top = -64
	b.offset_bottom = -16
	b.pressed.connect(func(): layer.queue_free())
	layer.add_child(b)
	layer.modulate.a = 0.0
	add_child(layer)
	create_tween().tween_property(layer, "modulate:a", 1.0, 1.2)
