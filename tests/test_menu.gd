extends SceneTree
## Galería, visor, ordenar en el editor y Campaña Histórica.
var fails := 0
var total := 0
func check(name: String, ok: bool) -> void:
	total += 1
	if not ok:
		fails += 1
		print("FAIL  ", name)

func _init() -> void:
	CardDB.load_all()
	# información de cartas
	check("99 cartas en la colección", CardInfo.collection_ids().size() == 99)
	var all_detail := true
	for id in CardInfo.collection_ids():
		if CardInfo.detail(id).begins_with("(Sin descripción"):
			all_detail = false
			print("sin detalle: ", id)
	check("Las 99 cartas tienen descripción del motor", all_detail)
	check("Las 99 cartas funcionan", CardInfo.working_count() == 99)
	check("Encabezado de una acción", "Acción Bushi" in CardInfo.header(94))
	# campaña
	CampaignStore.reset()
	check("Campaña nueva: progreso 0", CampaignStore.progress() == 0)
	check("No se puede saltar el duelo 2", not CampaignStore.complete(2) and CampaignStore.progress() == 0)
	check("Ganar el duelo 1 desbloquea el 2", CampaignStore.complete(1) and CampaignStore.progress() == 1)
	check("Repetir un duelo ganado no avanza", not CampaignStore.complete(1) and CampaignStore.progress() == 1)
	var order := ["Clan Takeda", "Clan Date", "Sombras Ninja", "Espadas Ronin", "Clan Oda", "Clan Toyotomi", "Clan Tokugawa", "El Creador"]
	var ok := CampaignStore.count() == 8 and DeckStore.problem(CampaignStore.rival_deck(1, true)) == "" and CampaignStore.rival_name(1, true) == "Uesugi e Ikko Ikki"
	for i in 8:
		ok = ok and CampaignStore.LEVELS[i].mazo == order[i] and DeckStore.problem(CampaignStore.rival_deck(i + 1)) == ""
	check("8 duelos en el orden pedido, con mazos válidos", ok)
	CampaignStore.reset()
	# menú
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	menu._show(menu.gallery)
	check("Galería muestra 99 cartas", menu.gal_ids.size() == 99 and menu.gal_grid.get_child_count() == 99)
	menu.gal_cat.select(4)
	menu._fill_gallery()
	check("Filtro «no funcionan» vacío (todas funcionan)", menu.gal_ids.is_empty())
	menu.gal_cat.select(0)
	menu.gal_search.text = "94"
	menu._fill_gallery()
	check("Buscar por número", menu.gal_ids == [94])
	menu.gal_search.text = ""
	menu._fill_gallery()
	menu.viewer.open(menu.gal_ids, 0)
	check("Visor abre en la carta 1", menu.viewer.visible and menu.viewer.ids[menu.viewer.index] == 1)
	menu.viewer.step(-1)
	check("Visor da la vuelta al retroceder (carta 99)", menu.viewer.ids[menu.viewer.index] == 99)
	menu.viewer.step(1)
	check("Visor avanza a la carta 1", menu.viewer.ids[menu.viewer.index] == 1)
	menu.viewer.close()
	check("Visor se cierra", not menu.viewer.visible)
	# editor: orden por número de colección y zoom
	menu._show(menu.editor)
	menu.sort_pick.select(1)
	menu._fill_catalog()
	var sorted_ok := true
	for i in range(1, menu.cat_ids.size()):
		if menu.cat_ids[i] < menu.cat_ids[i - 1]:
			sorted_ok = false
	check("Editor: catálogo ordenado por número de colección", sorted_ok and menu.cat_ids[0] == 1)
	menu.sort_pick.select(0)
	menu._fill_catalog()
	check("Editor: orden por clan cambia el orden", menu.cat_ids[0] != 1 or menu.cat_ids[1] != 2)
	menu.cnt = {94: 2, 5: 1}
	menu.sort_pick.select(1)
	menu._refresh_editor()
	check("Editor: lista del mazo ordenada por número", menu.deck_ids == [5, 94])
	menu._show(menu.campaign)
	check("Campaña: 8 puntos y solo el 1 disponible", menu.map.get_child_count() == 8 and not menu.map.get_child(0).disabled and menu.map.get_child(1).disabled)
	menu._open_duel_panel(5)
	menu._start_campaign_duel.call_deferred()
	await process_frame
	check("Iniciar duelo 5 configura mazo rival y nivel", GameConfig.campaign_level == 5 and GameConfig.name_opp == "Clan Oda" and GameConfig.deck_opp.size() == 50)
	# partida de campaña: ganar desbloquea
	var main = load("res://scenes/main.tscn").instantiate()
	GameConfig.campaign_level = 1
	root.add_child(main)
	await process_frame
	main.g.surrender(1)      # el rival se rinde: gana el humano
	await process_frame
	check("Ganar el duelo 1 en la partida desbloquea el punto 2", CampaignStore.progress() == 1)
	check("Mensaje de victoria de campaña", "superado" in main.end_sub.text and "desbloquea el punto 2" in main.end_sub.text)
	CampaignStore.reset()
	GameConfig.campaign_level = 0
	print("PRUEBAS: %d | FALLAS: %d" % [total, fails])
	quit()
