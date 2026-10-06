extends SceneTree
## Dev tool: screenshots of the title page, menu pages, controls card and
## End Card credits (Stage 7 before/after checks). $SHOT_DIR; FRAMES=1 also
## prints the slowest frames of the title build.

var frame_ms: Array = []

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _shot(name: String) -> void:
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func() -> void: drawn[0] = true, CONNECT_ONE_SHOT)
	for i in 20:
		if drawn[0]:
			break
		await process_frame
	if not drawn[0]:
		RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(_shot_dir() + "/" + name)

func _frames(sec: float) -> void:
	var t0: int = Time.get_ticks_usec()
	var last: int = t0
	while Time.get_ticks_usec() - t0 < int(sec * 1000000.0):
		await process_frame
		var now: int = Time.get_ticks_usec()
		frame_ms.append((now - last) / 1000.0)
		last = now

func _run() -> void:
	await _frames(0.4)
	await _shot("t0_title_early.png")
	await _frames(4.0)
	await _shot("t1_title.png")
	var sorted: Array = frame_ms.duplicate()
	sorted.sort()
	print("TITLE frames=", sorted.size(), " median=", snapped(sorted[sorted.size() / 2], 0.1), " p95=", snapped(sorted[int(sorted.size() * 0.95)], 0.1), " max=", snapped(sorted[-1], 0.1))
	print("TITLE built=", load("res://ui/title_art.gd").done)
	root.get_node("/root/EventBus").game_started.emit()
	await _frames(1.0)
	var menu = current_scene.get_node("MenuLayer/MainMenu")
	await _shot("t2_menu.png")
	for page in ["controls", "credits", "about"]:
		if menu._pages.has(page):
			menu._show_page(page)
			await _frames(0.3)
			await _shot("t3_menu_%s.png" % page)
	menu._show_page("main")
	var card = current_scene.get_node("MenuLayer/ControlsCard")
	card.open()
	await _frames(0.3)
	await _shot("t4_card_newgame.png")
	card.hide()
	var end = current_scene.get_node("MenuLayer/EndCard")
	end._text = "THE END"
	end._credits = true
	end.show()
	await _frames(0.3)
	await _shot("t5_endcard.png")
	end.hide()
	# In game: the F1 card and the pause menu's Controls page.
	var gs = root.get_node("/root/GameState")
	menu.hide()
	current_scene._start_chapter(load("res://data/chapters/ch1.tres"), &"ch1_landing")
	current_scene.get_node("MenuLayer/IntroSequence").hide()
	await _frames(1.5)
	card.open_in_game()
	await _frames(0.3)
	await _shot("t6_card_ingame.png")
	card._accept()
	var pause = current_scene.get_node("MenuLayer/PauseMenu")
	pause.open()
	pause._show_controls(true)
	await _frames(0.3)
	await _shot("t7_pause_controls.png")
	quit()
