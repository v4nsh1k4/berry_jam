extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_minimal.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.
var gs
var fm
var player
func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()
func _wait(sec: float) -> void:
	await create_timer(sec).timeout
func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(0.06)
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _wait(0.12)
func _give_at(id: String, x: float) -> void:
	for i in gs.inventory.size():
		if String(gs.inventory[i].id) == id:
			gs.select(i, false)
	player.global_position = Vector2(48 + x, 32 + 466)
	await _wait(0.2)
	await _tap("interact")
	await _wait(0.4)
func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	var bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	var main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")
	gs.reset()
	for w in ["arthur_open", "arthur_push", "portrait_remember"]:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	gs.set_flag(&"has_flashlight")
	main._start_chapter(load("res://data/chapters/ch3.tres"))
	main.get_node("MenuLayer/IntroSequence").hide()
	main._pending = null
	await _wait(0.3)
	fm.go_to(&"ch3_gallery_words")
	await _wait(0.5)
	print("start: vane whole=", gs.has_flag(&"whole_vane"), " arthur whole=", gs.has_flag(&"whole_arthur"), " gate=", gs.has_flag(&"gallery_open"))
	# Wrong owner: Arthur's word at the Lady's painting.
	await _give_at("arthur_open", 954)
	print("wrong painting: words=", gs.inventory.size())
	await _give_at("arthur_open", 230)
	await _give_at("arthur_push", 230)
	print("arthur done: whole=", gs.has_flag(&"whole_arthur"), " gate=", gs.has_flag(&"gallery_open"))
	await _give_at("portrait_remember", 954)
	print("all done: gate=", gs.has_flag(&"gallery_open"), " damage=", gs.comic_damage, " words=", gs.inventory.size())
	# Restart Chapter undoes this chapter's returns.
	bus.restart_chapter_requested.emit()
	await _wait(1.4)
	print("restart: frame=", gs.current_frame_id, " words=", gs.inventory.size(), " returned=", gs.returned_bubble_ids.size(), " gate=", gs.has_flag(&"gallery_open"))
	quit()
