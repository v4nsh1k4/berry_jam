extends SceneTree
## Stage 4D UI screenshots (dev, not exported): controls card, chapter title
## card, doodles, word tooltip / selected line / x2 badge, the noticed meter's
## icons, and the final room's hand with its pencil.
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ui_check.gd

var gs
var fm
var bus
var main
var player

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_shot_dir() + "/" + name)

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _go(frame: String) -> void:
	var ch = load("res://scripts/systems/debug_jump.gd").prepare(frame)
	main._start_chapter(ch, StringName(frame))
	await _wait(1.5)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	main.get_node("MenuLayer/MainMenu").hide()
	bus.menu_new_game.emit()
	await _wait(0.4)
	await _shot("ui_controls.png")
	print("controls card visible=", main.get_node("MenuLayer/ControlsCard").visible)
	main.get_node("MenuLayer/ControlsCard").call("_accept")
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	await _wait(0.8)
	await _shot("ui_title.png")
	await _wait(2.5)
	await _shot("ui_awakening.png")
	player = main.get_node("World/Player")
	for w in ["arthur_open", "arthur_wait", "vane_wait", "portrait_remember"]:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	await _wait(0.8)
	var strip = main.get_node("HUDLayer/InventoryStrip")
	var motion := InputEventMouseMotion.new()
	motion.position = strip.get_global_transform() * strip._slot_rect(1).get_center()
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await _wait(0.4)
	print("hover slot=", strip._hover_slot)
	await _shot("ui_tooltip.png")
	print("words=", gs.inventory.size())
	root.warp_mouse(Vector2(640, 200))
	await _go("ch2_clock_room")
	root.warp_mouse(Vector2(48 + 600, 32 + 140))
	root.get_node("/root/LightingSystem").set_light(true)
	await _wait(1.2)
	await _shot("ui_meter.png")
	root.get_node("/root/LightingSystem").set_light(false)
	await _go("ch3_heart_return")
	await _wait(1.0)
	await _shot("ui_hand0.png")
	await _wait(3.0)
	await _shot("ui_hand.png")
	print("frame=", fm.current_frame.data.id, " paused=", paused, " modal=", gs.modal_open)
	print("UI CHECK DONE")
	quit()
