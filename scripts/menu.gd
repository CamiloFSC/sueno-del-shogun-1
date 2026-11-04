extends Control
## Menú principal: jugar (elegir mazos), constructor de mazos y salir.

const KINDS := {
	"go": Color(0.20, 0.50, 0.75), "good": Color(0.18, 0.55, 0.28), "gold": Color(0.80, 0.62, 0.10),
	"neutral": Color(0.40, 0.40, 0.44), "end": Color(0.25, 0.35, 0.55), "bad": Color(0.70, 0.20, 0.20),
}
const CATEGORIES := ["Todas", "Guerreros", "Daimyos", "Acciones"]

var home: Control
var gallery: Control
var campaign: Control
var viewer: CardViewer
var sort_pick: OptionButton
var cat_ids: Array = []
var deck_ids: Array = []
var gal_grid: HFlowContainer
var gal_search: LineEdit
var gal_cat: OptionButton
var gal_info: Label
var gal_ids: Array = []
var play_screen: Control
var guide: Control
var credits: Control
var guide_page := 0
var guide_title: Label
var guide_body: Label
var guide_links: HFlowContainer
var guide_idx: Label
var pick_diff: OptionButton
var duel_diff: OptionButton
var pick_season: OptionButton
var duel_season: OptionButton
var editor: Control
var options: Array = []
var pick_me: OptionButton
var pick_opp: OptionButton
var desc_me: Label
var desc_opp: Label
var play_msg: Label

# editor
var cnt: Dictionary = {}
var name_edit: LineEdit
var search: LineEdit
var cat_pick: OptionButton
var load_pick: OptionButton
var load_opts: Array = []
var catalog_box: VBoxContainer
var deck_box: VBoxContainer
var count_lbl: Label
var msg_lbl: Label
var detail_lbl: RichTextLabel
var detail_tex: TextureRect
var save_btn: Button

func _ready() -> void:
	UiFont.apply(self)
	CardDB.load_all()
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bgtex: Texture2D = CardArt._load_path("res://assets/fondo.jpg")
	if bgtex != null:
		var pic := TextureRect.new()
		pic.texture = bgtex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.modulate = Color(0.5, 0.5, 0.55)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)
	_build_home()
	_build_play()
	_build_editor()
	_build_gallery()
	_build_campaign()
	_build_guide()
	_build_credits()
	viewer = CardViewer.new()
	add_child(viewer)
	if GameConfig.start_screen == "campana":
		GameConfig.start_screen = ""
		_show(campaign)
	else:
		_show(home)

func _show(c: Control) -> void:
	for s in [home, play_screen, editor, gallery, campaign, guide, credits]:
		s.visible = (s == c)
	if c == play_screen:
		_refresh_play()
	elif c == editor:
		_refresh_editor()
	elif c == gallery:
		_fill_gallery()
	elif c == campaign:
		_refresh_campaign()

# ------------------------------------------------------------------ utilidades de interfaz

func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _btn(text: String, kind: String, cb: Callable, size: int = 18) -> Button:
	var base: Color = KINDS.get(kind, KINDS["neutral"])
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	b.add_theme_stylebox_override("normal", _box(base, base.lightened(0.45)))
	b.add_theme_stylebox_override("hover", _box(base.lightened(0.18), Color.WHITE))
	b.add_theme_stylebox_override("pressed", _box(base.darkened(0.2), Color.WHITE))
	b.add_theme_stylebox_override("disabled", _box(Color(0.22, 0.22, 0.24), Color(0.32, 0.32, 0.34)))
	b.pressed.connect(cb)
	return b

func _lbl(text: String, size: int = 16, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	return c

func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

# ------------------------------------------------------------------ inicio

func _build_home() -> void:
	home = _screen()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	home.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.custom_minimum_size = Vector2(380, 0)
	cc.add_child(vb)
	var t := _lbl("Sueño del Shogun 1", 54, Color(1.0, 0.85, 0.3))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sub := _lbl("Juego de cartas", 20, Color(0.8, 0.75, 0.65))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	vb.add_child(Control.new())
	vb.add_child(_btn("Modo Campaña Histórica", "gold", func(): _show(campaign), 24))
	vb.add_child(_btn("▶  Jugar contra la IA", "good", func(): _show(play_screen), 24))
	vb.add_child(_btn("Constructor de mazos", "go", func(): _show(editor), 24))
	vb.add_child(_btn("Galería de cartas", "end", func(): _show(gallery), 24))
	vb.add_child(_btn("Aprender a Jugar", "go", func(): guide_page = 0; _refresh_guide(); _show(guide), 24))
	vb.add_child(_btn("Tutorial rápido (1 minuto)", "good", _start_tutorial_game, 20))
	vb.add_child(_btn("Créditos", "neutral", func(): _show(credits), 18))
	vb.add_child(_btn("Salir", "neutral", func(): get_tree().quit(), 20))

# ------------------------------------------------------------------ elegir mazos para jugar

func _build_play() -> void:
	play_screen = _screen()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_screen.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(760, 0)
	cc.add_child(vb)
	vb.add_child(_lbl("Elige los mazos", 36, Color(1.0, 0.85, 0.3)))
	vb.add_child(_lbl("TU MAZO", 18, Color(0.7, 0.85, 1.0)))
	pick_me = OptionButton.new()
	pick_me.add_theme_font_size_override("font_size", 20)
	pick_me.item_selected.connect(func(_i): _update_desc())
	vb.add_child(pick_me)
	desc_me = _lbl("", 15, Color(0.85, 0.85, 0.85))
	desc_me.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc_me)
	vb.add_child(_lbl("MAZO DEL RIVAL (IA)", 18, Color(1.0, 0.7, 0.7)))
	pick_opp = OptionButton.new()
	pick_opp.add_theme_font_size_override("font_size", 20)
	pick_opp.item_selected.connect(func(_i): _update_desc())
	vb.add_child(pick_opp)
	desc_opp = _lbl("", 15, Color(0.85, 0.85, 0.85))
	desc_opp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc_opp)
	vb.add_child(_lbl("DIFICULTAD DE LA IA", 18, Color(1.0, 0.85, 0.3)))
	pick_diff = _diff_picker()
	vb.add_child(pick_diff)
	vb.add_child(_lbl("FONDO (ESTACIÓN)", 18, Color(1.0, 0.85, 0.3)))
	pick_season = _season_picker()
	vb.add_child(pick_season)
	play_msg = _lbl("", 16, Color(1.0, 0.6, 0.4))
	vb.add_child(play_msg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	row.add_child(_btn("◀  Volver", "neutral", func(): _show(home)))
	row.add_child(_btn("Editar mazos", "go", func(): _show(editor)))
	row.add_child(_btn("▶  ¡Comenzar partida!", "good", _start_game, 22))

func _refresh_play() -> void:
	var keep_me := pick_me.selected
	var keep_opp := pick_opp.selected
	options = DeckStore.all_options()
	for pk in [pick_me, pick_opp]:
		pk.clear()
		pk.add_item("Mazo al azar")
		for o in options:
			pk.add_item(o.label)
	pick_me.select(clampi(keep_me, 0, pick_me.item_count - 1) if keep_me >= 0 else 0)
	pick_opp.select(clampi(keep_opp, 0, pick_opp.item_count - 1) if keep_opp >= 0 else 0)
	play_msg.text = ""
	_update_desc()

func _desc_of(i: int) -> String:
	if i <= 0:
		return "Se arma un mazo de 50 cartas al azar."
	return options[i - 1].desc

func _update_desc() -> void:
	desc_me.text = _desc_of(pick_me.selected)
	desc_opp.text = _desc_of(pick_opp.selected)

func _start_game() -> void:
	var i := pick_me.selected
	var j := pick_opp.selected
	GameConfig.deck_me = [] if i <= 0 else options[i - 1].deck
	GameConfig.deck_opp = [] if j <= 0 else options[j - 1].deck
	GameConfig.name_me = "Mazo al azar" if i <= 0 else options[i - 1].label
	GameConfig.name_opp = "Mazo al azar" if j <= 0 else options[j - 1].label
	GameConfig.difficulty = pick_diff.selected
	GameConfig.season = pick_season.selected
	GameConfig.campaign_level = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# ------------------------------------------------------------------ constructor de mazos

func _build_editor() -> void:
	editor = _screen()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_right = -12
	root.offset_top = 8
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 6)
	editor.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	top.add_child(_btn("◀ Menú", "neutral", func(): _show(home), 16))
	top.add_child(_lbl("Nombre:", 16))
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(240, 0)
	name_edit.placeholder_text = "Nombre del mazo"
	name_edit.add_theme_font_size_override("font_size", 18)
	top.add_child(name_edit)
	count_lbl = _lbl("0 / 50", 24, Color(1.0, 0.85, 0.3))
	top.add_child(count_lbl)
	save_btn = _btn("Guardar", "good", _on_save, 16)
	top.add_child(save_btn)
	top.add_child(_btn("Nuevo", "neutral", func(): cnt = {}; name_edit.text = ""; _msg(""); _refresh_editor(), 16))
	top.add_child(_btn("Completar al azar", "go", _on_fill, 16))
	top.add_child(_btn("Vaciar", "bad", func(): cnt = {}; _refresh_editor(), 16))
	var top2 := HBoxContainer.new()
	top2.add_theme_constant_override("separation", 8)
	root.add_child(top2)
	top2.add_child(_lbl("Cargar un mazo como base:", 16))
	load_pick = OptionButton.new()
	load_pick.add_theme_font_size_override("font_size", 16)
	load_pick.custom_minimum_size = Vector2(220, 0)
	top2.add_child(load_pick)
	top2.add_child(_btn("Cargar", "go", _on_load, 16))
	top2.add_child(_btn("Borrar mazo guardado", "bad", _on_delete, 16))

	msg_lbl = _lbl("", 16, Color(1.0, 0.7, 0.4))
	root.add_child(msg_lbl)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 12)
	root.add_child(mid)

	# catálogo
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(left)
	var filt := HBoxContainer.new()
	left.add_child(filt)
	filt.add_child(_lbl("CARTAS DISPONIBLES  ", 16, Color(0.7, 0.85, 1.0)))
	search = LineEdit.new()
	search.placeholder_text = "Buscar por nombre o clan…"
	search.custom_minimum_size = Vector2(230, 0)
	search.text_changed.connect(func(_t): _fill_catalog())
	filt.add_child(search)
	cat_pick = OptionButton.new()
	for c in CATEGORIES:
		cat_pick.add_item(c)
	cat_pick.item_selected.connect(func(_i): _fill_catalog())
	filt.add_child(cat_pick)
	filt.add_child(_lbl("  Orden:", 16))
	sort_pick = OptionButton.new()
	sort_pick.add_item("Clan y categoría")
	sort_pick.add_item("N° de colección")
	sort_pick.item_selected.connect(func(_i): _fill_catalog(); _fill_deck())
	filt.add_child(sort_pick)
	var sc1 := ScrollContainer.new()
	sc1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc1.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc1)
	catalog_box = VBoxContainer.new()
	catalog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_box.add_theme_constant_override("separation", 2)
	sc1.add_child(catalog_box)

	# mazo
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(500, 0)
	mid.add_child(right)
	right.add_child(_lbl("TU MAZO  (clic en «−» para quitar)", 16, Color(1.0, 0.85, 0.3)))
	var sc2 := ScrollContainer.new()
	sc2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc2)
	deck_box = VBoxContainer.new()
	deck_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_box.add_theme_constant_override("separation", 2)
	sc2.add_child(deck_box)

	# detalle
	var det := HBoxContainer.new()
	det.custom_minimum_size = Vector2(0, 110)
	det.add_theme_constant_override("separation", 10)
	root.add_child(det)
	detail_tex = TextureRect.new()
	detail_tex.custom_minimum_size = Vector2(80, 108)
	detail_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	det.add_child(detail_tex)
	detail_lbl = RichTextLabel.new()
	detail_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_lbl.text = "Pasa el mouse sobre una carta para leer su efecto. Haz clic en una carta del catálogo para agregarla."
	det.add_child(detail_lbl)

func _msg(t: String, ok: bool = false) -> void:
	msg_lbl.text = t
	msg_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5) if ok else Color(1.0, 0.7, 0.4))

func _total() -> int:
	var n := 0
	for id in cnt:
		n += cnt[id]
	return n

func _deck_array() -> Array:
	var out := []
	var ids: Array = cnt.keys()
	ids.sort()
	for id in ids:
		for i in cnt[id]:
			out.append(id)
	return out

func _has_effect(id: int) -> bool:
	var c: Dictionary = CardDB.cards[id]
	if c.categoria == "Accion":
		return Effects.is_implemented_action(id)
	return id in Effects.WARRIORS_WITH_EFFECT

func _short(id: int) -> String:
	var c: Dictionary = CardDB.cards[id]
	if c.categoria == "Accion":
		return "Acción (Bushi)"
	return "%s · ⚔%d ♦%d" % [c.clan, c.ataque, c.costo_honor]

func _add(id: int) -> void:
	if _total() >= DeckStore.SIZE:
		_msg("El mazo ya tiene 50 cartas. Quita una para agregar otra.")
		return
	if cnt.get(id, 0) >= DeckStore.MAX_COPIES:
		_msg("Máximo %d copias de %s." % [DeckStore.MAX_COPIES, CardDB.cards[id].nombre])
		return
	cnt[id] = cnt.get(id, 0) + 1
	_msg("")
	_refresh_editor()

func _remove(id: int) -> void:
	cnt[id] = cnt.get(id, 0) - 1
	if cnt[id] <= 0:
		cnt.erase(id)
	_msg("")
	_refresh_editor()

func _hover(id: int) -> void:
	var c: Dictionary = CardDB.cards[id]
	var note := "" if _has_effect(id) else "\n[color=#ffb060](Efecto aún no implementado: juega solo con su ataque y coste)[/color]"
	var head := "[b]%s[/b] — %s" % [c.nombre, c.categoria]
	if c.categoria != "Accion":
		head += "  |  Clan %s  |  Ataque %d  |  Honor %d" % [c.clan, c.ataque, c.costo_honor]
	detail_lbl.text = ""
	detail_lbl.append_text(head + "\n" + c.efecto + note)
	detail_tex.texture = CardArt.get_texture(id)

func _refresh_editor() -> void:
	var n := _total()
	count_lbl.text = "%d / %d" % [n, DeckStore.SIZE]
	count_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if n == DeckStore.SIZE else Color(1.0, 0.85, 0.3))
	save_btn.disabled = n != DeckStore.SIZE
	_fill_catalog()
	_fill_deck()
	_fill_load_pick()

func _catalog_ids() -> Array:
	var q := search.text.strip_edges().to_lower()
	var cat: int = cat_pick.selected
	var ids := []
	for id in CardDB.cards:
		if id >= CardDB.TOKEN_ID:
			continue
		var c: Dictionary = CardDB.cards[id]
		if cat == 1 and c.categoria != "Guerrero": continue
		if cat == 2 and c.categoria != "Daimyo": continue
		if cat == 3 and c.categoria != "Accion": continue
		if q != "" and not (q in c.nombre.to_lower() or q in c.clan.to_lower()):
			continue
		ids.append(id)
	_sort_ids(ids)
	return ids

func _sort_ids(ids: Array) -> void:
	if sort_pick != null and sort_pick.selected == 1:     # por número de colección
		ids.sort()
		return
	ids.sort_custom(func(a, b):
		var ca: Dictionary = CardDB.cards[a]
		var cb: Dictionary = CardDB.cards[b]
		var ka := [ca.categoria == "Accion", ca.clan, ca.categoria == "Daimyo", ca.costo_honor, a]
		var kb := [cb.categoria == "Accion", cb.clan, cb.categoria == "Daimyo", cb.costo_honor, b]
		return ka < kb)

## Botón «Zoom» con lupa: abre el visor en la carta indicada de la lista.
func _zoom_btn(list: Array, i: int) -> Button:
	var b := Button.new()
	b.text = "Zoom"
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.custom_minimum_size = Vector2(86, 0)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _box(Color(0.12, 0.10, 0.06), Color(1.0, 0.85, 0.3)))
	b.add_theme_stylebox_override("hover", _box(Color(0.35, 0.25, 0.08), Color.WHITE))
	b.add_theme_stylebox_override("pressed", _box(Color(0.5, 0.35, 0.1), Color.WHITE))
	b.add_theme_constant_override("h_separation", 4)
	var ic := MagnifierIcon.new()
	ic.position = Vector2(8, 5)
	b.add_child(ic)
	b.tooltip_text = "Ver la carta en grande"
	b.pressed.connect(func(): viewer.open(list, i))
	return b

func _fill_catalog() -> void:
	if catalog_box == null:
		return
	_clear(catalog_box)
	cat_ids = _catalog_ids()
	for ci in cat_ids.size():
		var id: int = cat_ids[ci]
		var c: Dictionary = CardDB.cards[id]
		var inn: int = cnt.get(id, 0)
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.text = "N° %d  %s   —   %s%s%s" % [id, c.nombre, _short(id), "" if _has_effect(id) else "   (sin efecto)", ("      ✔ ×%d en el mazo" % inn) if inn > 0 else ""]
		b.disabled = inn >= DeckStore.MAX_COPIES or _total() >= DeckStore.SIZE
		var fill := Color(0.16, 0.24, 0.36)
		if c.categoria == "Daimyo":
			fill = Color(0.15, 0.32, 0.20)
		elif c.categoria == "Accion":
			fill = Color(0.38, 0.16, 0.16)
		b.add_theme_stylebox_override("normal", _box(fill, fill.lightened(0.3)))
		b.add_theme_stylebox_override("hover", _box(fill.lightened(0.2), Color.WHITE))
		b.add_theme_stylebox_override("pressed", _box(fill.darkened(0.2), Color.WHITE))
		b.add_theme_stylebox_override("disabled", _box(fill.darkened(0.55), fill.darkened(0.2)))
		b.add_theme_color_override("font_disabled_color", Color(0.65, 0.65, 0.65))
		b.pressed.connect(_add.bind(id))
		b.mouse_entered.connect(_hover.bind(id))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 4)
		crow.add_child(_zoom_btn(cat_ids, ci))
		crow.add_child(b)
		catalog_box.add_child(crow)

func _fill_deck() -> void:
	_clear(deck_box)
	var ids := cnt.keys()
	_sort_ids(ids)
	deck_ids = ids
	for di in ids.size():
		var id: int = ids[di]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(_zoom_btn(deck_ids, di))
		var minus := _btn("−", "bad", _remove.bind(id), 16)
		minus.custom_minimum_size = Vector2(36, 0)
		row.add_child(minus)
		var plus := _btn("+", "good", _add.bind(id), 16)
		plus.custom_minimum_size = Vector2(36, 0)
		plus.disabled = cnt[id] >= DeckStore.MAX_COPIES or _total() >= DeckStore.SIZE
		row.add_child(plus)
		row.add_child(_lbl("×%d" % cnt[id], 18, Color(1.0, 0.85, 0.3)))
		var cd: Dictionary = CardDB.cards[id]
		var nm := _lbl("N° %d  %s" % [id, cd.nombre] if cd.categoria == "Accion" else "N° %d  %s  (%s ⚔%d)" % [id, cd.nombre, cd.clan, cd.ataque], 15)
		nm.mouse_filter = Control.MOUSE_FILTER_PASS
		nm.mouse_entered.connect(_hover.bind(id))
		row.add_child(nm)
		deck_box.add_child(row)

func _fill_load_pick() -> void:
	load_pick.clear()
	load_opts = DeckStore.all_options()
	for o in load_opts:
		load_pick.add_item(o.label)

func _on_save() -> void:
	var err := DeckStore.save_deck(name_edit.text, _deck_array())
	if err != "":
		_msg(err)
	else:
		_msg("Mazo «%s» guardado." % name_edit.text.strip_edges(), true)
		_fill_load_pick()

func _on_load() -> void:
	if load_pick.selected < 0 or load_opts.is_empty():
		return
	var o: Dictionary = load_opts[load_pick.selected]
	cnt = DeckStore.counts_of(o.deck)
	name_edit.text = o.label.trim_prefix("★ ") if o.label.begins_with("★ ") else o.label + " (copia)"
	_msg("Cargado: %s. Puedes modificarlo y guardarlo con otro nombre." % o.label, true)
	_refresh_editor()

func _on_delete() -> void:
	if load_pick.selected < 0 or load_opts.is_empty():
		return
	var lab: String = load_opts[load_pick.selected].label
	if not lab.begins_with("★ "):
		_msg("Solo se pueden borrar tus mazos guardados (los marcados con ★).")
		return
	DeckStore.delete_deck(lab.trim_prefix("★ "))
	_msg("Mazo «%s» borrado." % lab.trim_prefix("★ "), true)
	_fill_load_pick()

func _on_fill() -> void:
	var pool := []
	for id in CardDB.cards:
		if id < CardDB.TOKEN_ID and _has_effect(id):
			pool.append(id)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var guard := 0
	while _total() < DeckStore.SIZE and guard < 2000:
		guard += 1
		var id: int = pool[rng.randi() % pool.size()]
		if cnt.get(id, 0) < DeckStore.MAX_COPIES:
			cnt[id] = cnt.get(id, 0) + 1
	_msg("Mazo completado al azar con cartas que ya funcionan.", true)
	_refresh_editor()

# ------------------------------------------------------------------ galería de cartas

func _build_gallery() -> void:
	gallery = _screen()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gallery.add_child(shade)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = 10
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	gallery.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	top.add_child(_btn("◀ Menú", "neutral", func(): _show(home), 16))
	top.add_child(_lbl("Galería de cartas", 28, Color(1.0, 0.85, 0.3)))
	gal_search = LineEdit.new()
	gal_search.placeholder_text = "Buscar por nombre, clan o número…"
	gal_search.custom_minimum_size = Vector2(280, 0)
	gal_search.text_changed.connect(func(_t): _fill_gallery())
	top.add_child(gal_search)
	gal_cat = OptionButton.new()
	for c in ["Todas", "Guerreros", "Daimyos", "Acciones", "Solo las que NO funcionan"]:
		gal_cat.add_item(c)
	gal_cat.item_selected.connect(func(_i): _fill_gallery())
	top.add_child(gal_cat)
	gal_info = _lbl("", 17, Color(0.8, 0.9, 1.0))
	root.add_child(gal_info)
	root.add_child(_lbl("Haz clic en una carta para verla en grande, con su efecto, cómo lo interpreta el juego y si funciona (✔ funciona · ✘ no funciona). En el visor pasas de una carta a otra con las flechas.", 14, Color(0.8, 0.8, 0.8)))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	gal_grid = HFlowContainer.new()
	gal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gal_grid.add_theme_constant_override("h_separation", 10)
	gal_grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(gal_grid)

func _gallery_ids() -> Array:
	var q := gal_search.text.strip_edges().to_lower()
	var cat: int = gal_cat.selected
	var ids := []
	for id in CardInfo.collection_ids():
		var c: Dictionary = CardDB.cards[id]
		if cat == 1 and c.categoria != "Guerrero": continue
		if cat == 2 and c.categoria != "Daimyo": continue
		if cat == 3 and c.categoria != "Accion": continue
		if cat == 4 and CardInfo.works(id): continue
		if q != "" and not (q in c.nombre.to_lower() or q in c.clan.to_lower() or q == str(id)):
			continue
		ids.append(id)
	return ids

func _fill_gallery() -> void:
	if gal_grid == null:
		return
	_clear(gal_grid)
	gal_ids = _gallery_ids()
	gal_info.text = "%d cartas mostradas · %d / %d funcionan en el juego" % [gal_ids.size(), CardInfo.working_count(), CardInfo.collection_ids().size()]
	for i in gal_ids.size():
		var id: int = gal_ids[i]
		var c: Dictionary = CardDB.cards[id]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(176, 246)
		var fill := Color(0.16, 0.24, 0.36)
		if c.categoria == "Daimyo":
			fill = Color(0.15, 0.32, 0.20)
		elif c.categoria == "Accion":
			fill = Color(0.38, 0.16, 0.16)
		var ok := CardInfo.works(id)
		var border := Color(1.0, 0.85, 0.3) if ok else Color(1.0, 0.35, 0.3)
		for st in ["normal", "hover", "pressed"]:
			var sb := _box(fill.lightened(0.15) if st == "hover" else fill, Color.WHITE if st == "hover" else border)
			sb.set_border_width_all(3)
			sb.content_margin_left = 4
			sb.content_margin_right = 4
			sb.content_margin_top = 4
			sb.content_margin_bottom = 4
			b.add_theme_stylebox_override(st, sb)
		var tex := CardArt.get_texture(id)
		if tex != null:
			var img := TextureRect.new()
			img.texture = tex
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.set_anchors_preset(Control.PRESET_FULL_RECT)
			img.offset_left = 4
			img.offset_right = -4
			img.offset_top = 4
			img.offset_bottom = -4
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(img)
		else:
			b.text = "%s\n\n%s" % [c.nombre, "" if c.categoria == "Accion" else "%s\n⚔%d ♦%d" % [c.clan, c.ataque, c.costo_honor]]
			b.add_theme_font_size_override("font_size", 17)
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			b.add_theme_color_override("font_pressed_color", Color.WHITE)
		var num := _lbl(str(id), 16, Color.WHITE)
		num.add_theme_color_override("font_outline_color", Color.BLACK)
		num.add_theme_constant_override("outline_size", 6)
		num.position = Vector2(8, 4)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(num)
		var mark := _lbl("✔" if ok else "✘", 22, Color(0.45, 1.0, 0.55) if ok else Color(1.0, 0.4, 0.35))
		mark.add_theme_color_override("font_outline_color", Color.BLACK)
		mark.add_theme_constant_override("outline_size", 6)
		mark.position = Vector2(148, 2)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mark)
		b.pressed.connect(func(): viewer.open(gal_ids, i))
		gal_grid.add_child(b)

# ------------------------------------------------------------------ campaña histórica

var map: CampaignMap
var camp_msg: Label
var duel_panel: PanelContainer
var duel_dim: ColorRect
var duel_title: Label
var duel_text: Label
var duel_pick: OptionButton
var duel_level := 0
var duel_side: OptionButton
var duel_side_lbl: Label
var duel_options: Array = []

func _build_campaign() -> void:
	campaign = _screen()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	campaign.add_child(shade)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14
	top.offset_right = -14
	top.offset_top = 10
	top.add_theme_constant_override("separation", 12)
	campaign.add_child(top)
	top.add_child(_btn("◀ Menú", "neutral", func(): _show(home), 16))
	var t := _lbl("Modo Campaña Histórica", 36, Color(1.0, 0.85, 0.3))
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 8)
	top.add_child(t)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(_btn("Reiniciar campaña", "bad", func(): CampaignStore.reset(); _refresh_campaign(), 14))
	camp_msg = _lbl("", 20, Color(1, 0.95, 0.8))
	camp_msg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	camp_msg.offset_top = 70
	camp_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camp_msg.add_theme_color_override("font_outline_color", Color.BLACK)
	camp_msg.add_theme_constant_override("outline_size", 6)
	campaign.add_child(camp_msg)
	map = CampaignMap.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.offset_top = 110
	map.offset_bottom = -70
	map.picked.connect(_open_duel_panel)
	campaign.add_child(map)
	# ventana del duelo
	duel_dim = ColorRect.new()
	duel_dim.color = Color(0, 0, 0, 0.6)
	duel_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	duel_dim.visible = false
	campaign.add_child(duel_dim)
	var dcc := CenterContainer.new()
	dcc.set_anchors_preset(Control.PRESET_FULL_RECT)
	duel_dim.add_child(dcc)
	duel_panel = PanelContainer.new()
	duel_panel.add_theme_stylebox_override("panel", _box(Color(0.08, 0.07, 0.06, 0.97), Color(1.0, 0.85, 0.3)))
	duel_panel.custom_minimum_size = Vector2(620, 0)
	dcc.add_child(duel_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	duel_panel.add_child(vb)
	duel_title = _lbl("", 30, Color(1.0, 0.85, 0.3))
	vb.add_child(duel_title)
	duel_text = _lbl("", 16, Color(0.9, 0.9, 0.9))
	duel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(duel_text)
	duel_side_lbl = _lbl("¿A QUIÉN QUIERES DE ALIADO?", 16, Color(1.0, 0.6, 0.5))
	vb.add_child(duel_side_lbl)
	duel_side = OptionButton.new()
	duel_side.add_theme_font_size_override("font_size", 18)
	duel_side.add_item("Uesugi Kenshin (rival: Takeda Shingen)")
	duel_side.add_item("Takeda Shingen (rival: Uesugi Kenshin)")
	duel_side.item_selected.connect(func(_i): _refresh_duel_text())
	vb.add_child(duel_side)
	vb.add_child(_lbl("TU MAZO", 16, Color(0.7, 0.85, 1.0)))
	duel_pick = OptionButton.new()
	duel_pick.add_theme_font_size_override("font_size", 18)
	vb.add_child(duel_pick)
	vb.add_child(_lbl("DIFICULTAD DE LA IA", 16, Color(1.0, 0.85, 0.3)))
	duel_diff = _diff_picker()
	vb.add_child(duel_diff)
	vb.add_child(_lbl("FONDO (ESTACIÓN)", 16, Color(1.0, 0.85, 0.3)))
	duel_season = _season_picker()
	vb.add_child(duel_season)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	row.add_child(_btn("Cancelar", "neutral", func(): duel_dim.visible = false, 16))
	row.add_child(_btn("Editar mazos", "go", func(): duel_dim.visible = false; _show(editor), 16))
	row.add_child(_btn("▶  ¡Comenzar duelo!", "good", _start_campaign_duel, 20))

func _refresh_campaign() -> void:
	duel_dim.visible = false
	var pr := CampaignStore.progress()
	map.progress = pr
	if pr >= CampaignStore.count():
		camp_msg.text = "¡Campaña completada! Eres el nuevo Shogun. Puedes repetir cualquier duelo."
	else:
		camp_msg.text = "Duelo %d de %d desbloqueado: %s. Gana para abrir el siguiente punto." % [pr + 1, CampaignStore.count(), CampaignStore.LEVELS[pr].titulo]

func _open_duel_panel(level: int) -> void:
	duel_level = level
	var info: Dictionary = CampaignStore.LEVELS[level - 1]
	duel_side_lbl.visible = info.has("bando")
	duel_side.visible = info.has("bando")
	_refresh_duel_text()
	duel_options = DeckStore.all_options()
	duel_pick.clear()
	duel_pick.add_item("Mazo al azar")
	var last := CampaignStore.last_deck()
	var sel := 0
	for i in duel_options.size():
		duel_pick.add_item(duel_options[i].label)
		if duel_options[i].label == last:
			sel = i + 1
	duel_pick.select(sel)
	duel_dim.visible = true

func _refresh_duel_text() -> void:
	var info: Dictionary = CampaignStore.LEVELS[duel_level - 1]
	var alt: bool = info.has("bando") and duel_side.selected == 1
	duel_title.text = "Duelo %d: %s" % [duel_level, info.titulo]
	duel_text.text = "%s\n%s\n\nRival: mazo «%s». %s" % [info.lugar, info.texto, CampaignStore.rival_name(duel_level, alt), CampaignStore.rival_desc(duel_level, alt)]

func _start_campaign_duel() -> void:
	var i := duel_pick.selected
	GameConfig.deck_me = [] if i <= 0 else duel_options[i - 1].deck
	GameConfig.name_me = "Mazo al azar" if i <= 0 else duel_options[i - 1].label
	CampaignStore.remember_deck("" if i <= 0 else duel_options[i - 1].label)
	var alt: bool = CampaignStore.LEVELS[duel_level - 1].has("bando") and duel_side.selected == 1
	GameConfig.camp_alt = alt
	GameConfig.deck_opp = CampaignStore.rival_deck(duel_level, alt)
	GameConfig.name_opp = CampaignStore.rival_name(duel_level, alt)
	GameConfig.difficulty = 3 if CampaignStore.LEVELS[duel_level - 1].has("boss") else duel_diff.selected
	GameConfig.season = duel_season.selected
	GameConfig.campaign_level = duel_level
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ------------------------------------------------------------------ dificultad y guía

func _diff_picker() -> OptionButton:
	var ob := OptionButton.new()
	ob.add_theme_font_size_override("font_size", 18)
	for n in ["Fácil", "Normal", "Difícil", "Pesadilla (la IA hace trampa)"]:
		ob.add_item(n)
	ob.select(GameConfig.difficulty)
	return ob

func _build_guide() -> void:
	guide = _screen()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.08, 0.07, 0.06, 0.95), Color(1.0, 0.85, 0.3)))
	panel.custom_minimum_size = Vector2(900, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	top.add_child(_btn("◀ Menú", "neutral", func(): _show(home), 16))
	top.add_child(_lbl("   Aprender a Jugar", 30, Color(1.0, 0.85, 0.3)))
	guide_title = _lbl("", 26, Color(0.85, 0.95, 1.0))
	vb.add_child(guide_title)
	guide_body = _lbl("", 19, Color(0.95, 0.95, 0.95))
	guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_body.custom_minimum_size = Vector2(860, 260)
	vb.add_child(guide_body)
	vb.add_child(_lbl("Cartas relacionadas (clic para verlas en detalle):", 15, Color(0.8, 0.75, 0.65)))
	guide_links = HFlowContainer.new()
	guide_links.custom_minimum_size = Vector2(860, 0)
	guide_links.add_theme_constant_override("h_separation", 8)
	guide_links.add_theme_constant_override("v_separation", 6)
	vb.add_child(guide_links)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 14)
	vb.add_child(nav)
	nav.add_child(_btn("◀ Anterior", "go", func(): guide_page = maxi(guide_page - 1, 0); _refresh_guide(), 18))
	guide_idx = _lbl("", 18, Color(0.8, 0.8, 0.8))
	guide_idx.custom_minimum_size = Vector2(120, 0)
	guide_idx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(guide_idx)
	nav.add_child(_btn("Siguiente ▶", "good", func(): guide_page = mini(guide_page + 1, GuidePages.PAGES.size() - 1); _refresh_guide(), 18))

func _refresh_guide() -> void:
	var pg: Dictionary = GuidePages.PAGES[guide_page]
	guide_title.text = pg.t
	guide_body.text = pg.b
	guide_idx.text = "%d / %d" % [guide_page + 1, GuidePages.PAGES.size()]
	for c in guide_links.get_children():
		c.queue_free()
	var ids: Array = pg.c
	for k in ids.size():
		var cid: int = ids[k]
		guide_links.add_child(_btn("%d · %s" % [cid, CardDB.cards[cid].nombre], "end", func(): viewer.open(ids, k), 14))

func _season_picker() -> OptionButton:
	var ob := OptionButton.new()
	ob.add_theme_font_size_override("font_size", 18)
	for n in ExtraArt.SEASONS:
		ob.add_item(n)
	ob.select(GameConfig.season)
	return ob

func _start_tutorial_game() -> void:
	GameConfig.deck_me = DeckStore.preset_deck(4)     # mazo Unificadores
	GameConfig.deck_opp = DeckStore.preset_deck(1)
	GameConfig.name_me = "Unificadores"
	GameConfig.name_opp = "Espadas Ronin"
	GameConfig.campaign_level = 0
	GameConfig.tutorial = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _build_credits() -> void:
	credits = _screen()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	credits.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.08, 0.07, 0.06, 0.95), Color(1.0, 0.85, 0.3)))
	cc.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var pic := TextureRect.new()
	pic.texture = ExtraArt.creator()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(300, 500)
	row.add_child(pic)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(520, 0)
	row.add_child(vb)
	vb.add_child(_lbl("Créditos", 34, Color(1.0, 0.85, 0.3)))
	vb.add_child(_lbl("El Creador del juego", 24, Color(0.85, 0.95, 1.0)))
	var t := _lbl("Sueño del Shogun 1: diseño del juego, ilustraciones y reglas de Camilo Estay (© 2016-2017). Todos los derechos reservados.\n\nMotor: Godot Engine 4.3 (licencia MIT).\nFuente de la interfaz: Shippori Mincho (SIL Open Font License 1.1).\n\nProgramación del videojuego asistida por Claude (Anthropic).", 17, Color(0.9, 0.9, 0.9))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(t)
	vb.add_child(_btn("◀ Menú", "neutral", func(): _show(home), 18))
