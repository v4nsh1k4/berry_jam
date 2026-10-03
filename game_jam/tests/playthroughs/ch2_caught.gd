extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch2_caught.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.
var gs
var fm
const STATES := ["DORMANT", "PATROL", "STALKING", "HUNTING", "TELEGRAPH", "LUNGE", "SEARCHING", "RETREATING"]
func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()
func _wait(sec: float) -> void:
	await create_timer(sec).timeout
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_shot_dir() + "/" + name)
func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	var bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	bus.menu_new_game.emit()
	# New Game opens with the intro cinematic: skip it like a click would.
	current_scene.get_node("MenuLayer/IntroCinematic").call("_finish")
	var main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	gs.add_bubble(load("res://data/bubbles/arthur_open.tres"))
	gs.set_flag(&"has_flashlight")
	main._start_chapter(load("res://data/chapters/ch2.tres"))
	main.get_node("MenuLayer/IntroSequence").hide()
	main._pending = null
	await _wait(0.4)
	print("chapter_start words=", gs.chapter_start.get("inventory", []).size())
	gs.add_bubble(load("res://data/bubbles/vane_hide.tres"))
	fm.go_to(&"ch2_clock_room")
	await _wait(0.4)
	var player = main.get_node("World/Player")
	var crawler = get_first_node_in_group(&"crawler")
	crawler._pos = Vector2(760, 470)
	player.global_position = Vector2(48 + 520, 32 + 466)
	root.warp_mouse(Vector2(48 + 800, 32 + 400))
	root.get_node("/root/LightingSystem").set_light(true)
	var saw_telegraph := false
	var caught := false
	bus.player_caught.connect(func(): caught = true)
	for i in 60:
		await _wait(0.1)
		var st: String = STATES[crawler.state] if is_instance_valid(crawler) else "gone"
		if st == "TELEGRAPH" and not saw_telegraph:
			saw_telegraph = true
			print("telegraph at t=", i * 0.1)
			await _shot("20_telegraph.png")
		if caught:
			print("caught at t=", i * 0.1)
			await _wait(0.05)
			await _shot("21_caught.png")
			break
	await _wait(1.5)
	print("after catch frame=", fm.current_frame.data.id, " words=", gs.inventory.size(), " light=", root.get_node("/root/LightingSystem").is_light_on)
	bus.restart_chapter_requested.emit()
	await _wait(1.4)
	print("after restart frame=", fm.current_frame.data.id, " words=", gs.inventory.map(func(b): return b.text), " chapter=", gs.current_chapter.id)
	quit()
