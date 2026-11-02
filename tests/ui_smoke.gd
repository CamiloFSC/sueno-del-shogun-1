extends SceneTree
## Carga la escena principal y juega como humano usando la IA para ver que la UI no falle.
func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# ventana de decisión: ver el tablero y volver
	var g = main.g
	var ok := true
	g.turn_player = 0; g.phase = "MAIN"; g.battle = {}; g.pending = {}
	g.request_choice(0, "Prueba", [{"label": "A"}, {"label": "B"}], [1], func(_s): pass)
	g.changed.emit()
	ok = ok and main.choice_overlay.visible and not main.return_btn.visible
	main.peek_btn.pressed.emit()
	ok = ok and not main.choice_overlay.visible and main.return_btn.visible
	main.return_btn.pressed.emit()
	ok = ok and main.choice_overlay.visible and not main.return_btn.visible
	g.choose([0])
	# aviso de descarte
	g.players[0].hand = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	g.turn_player = 0; g.phase = "DISCARD"
	g.changed.emit()
	ok = ok and main.alert_panel.visible
	g.phase = "MAIN"
	g.changed.emit()
	ok = ok and not main.alert_panel.visible
	# mensaje emergente y victoria
	g.toast("prueba")
	g.changed.emit()
	ok = ok and main.toast_panel.visible
	print("UI interacciones: ", "OK" if ok else "FALLO")
	main._new_game()
	g = main.g
	var steps := 0
	while main.g.phase != "OVER" and steps < 3000:
		AI.act(main.g)   # la IA juega ambos lados; la UI se redibuja en cada cambio
		steps += 1
		if steps % 5 == 0:
			await process_frame
	print("UI OK. Fase final: ", main.g.phase, " | pasos: ", steps, " | ganador: ", main.g.winner)
	quit()
