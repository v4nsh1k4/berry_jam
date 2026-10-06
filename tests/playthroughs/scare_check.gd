extends SceneTree
## Jumpscare test (dev, not exported): fires all eight scares from their room
## flags (screenshots), checks the clock scare's Crawler hunts close by, the
## cellar scare's build-up (music and ambience near silent, the recorded cry
## growing, the light out, then the face), that a menu calls the build off and
## it tries again, spacing, chases, and that nothing repeats (also not after
## Restart Chapter). Run from the repo root:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/scare_check.gd

var gs
var fm
var bus
var main
var player
var ok := true
var scares: Array = []

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

## A hidden window (another Space, a full-screen app) is never drawn, so
## frame_post_draw never comes: then force a draw for the shot.
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

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _check(label: String, cond: bool) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	ok = ok and cond

func _go(frame: String) -> void:
	var ch = load("res://scripts/systems/debug_jump.gd").prepare(frame)
	gs.current_chapter = ch
	gs.is_playing = true
	gs.chapter_start = gs.to_dict()
	fm.go_to(StringName(frame))
	await _wait(1.2)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	bus.scare.connect(func(kind, _i): scares.append(kind))
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	bus.menu_new_game.emit()
	main.get_node("MenuLayer/ControlsCard").call("_accept")
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	main.get_node("MenuLayer/MainMenu").hide()
	bus.intro_finished.emit()
	main.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.4)
	player = main.get_node("World/Player")
	var ov = main.get_node("FXLayer/JumpscareOverlay")
	var rooms := {&"scare_hallway": ["ch2_long_hallway", &"hall_panel_open"], &"scare_gallery": ["ch2_gallery", &"gallery_lever"],
		&"scare_passage": ["ch2_servants_passage", &"survived_passage"], &"scare_clock": ["ch2_clock_room", &"clock_read"],
		&"scare_hand": ["ch3_gallery_words", &"spread_lens"], &"scare_cellar": ["ch2_cellar", &"cellar_dials_set"],
		&"scare_closet": ["ch1_bedchamber", &"closet_near"], &"scare_escape": ["ch3_gallery_words", &"spread_pool"]}
	var mm = root.get_node("/root/MusicManager")
	var am = root.get_node("/root/AudioManager")
	for id in rooms:
		await _go(rooms[id][0])
		ov._since_last = 999.0
		player.global_position = Vector2(48 + 420, 32 + (200 if id in [&"scare_hand", &"scare_escape"] else 466))
		var before: int = scares.size()
		gs.set_flag(rooms[id][1])
		var waited := 0.0
		var build_seen := false
		while scares.size() == before and waited < 8.0:
			await _wait(0.05)
			waited += 0.05
			if id == &"scare_cellar" and not build_seen and ov._build_t > 2.75:
				build_seen = true
				await _shot("sc_scare_cellar_build.png")
				print("cellar build at %.2fs: bg_track %.1f dB, drone %.1f dB, cry %s (seen %s), light %s" % [ov._build_t, mm._files.level,
					am._drone.volume_db, am.last_played, gs.seen.has(&"cry_scare"), root.get_node("/root/LightingSystem").is_light_on])
				_check("cellar build: music + ambience near silent, the cry playing, the light out", mm._files.level < -40.0
					and mm._players[mm._active].volume_db < -40.0
					and am._drone.volume_db <= -59.0 and gs.seen.has(&"cry_scare") and not root.get_node("/root/LightingSystem").is_light_on)
		await _wait(0.12)
		await _shot("sc_%s.png" % id)
		_check("%s fired after its trigger (%.1fs)" % [id, waited], scares.size() == before + 1 and scares[-1] == id)
		await _wait(0.6)
		if id == &"scare_cellar":
			_check("the cellar scare had its silent build-up first", build_seen)
	print("fired: ", scares)
	_check("all eight scares fired once each", scares.size() == 8 and gs.seen.has(&"scare_escape"))
	# A menu during the build calls it off; it tries again once fair.
	gs.seen.erase(&"scare_cellar")
	await _go("ch2_cellar")
	var lights = root.get_node("/root/LightingSystem")
	ov._since_last = 999.0
	ov._on_flag_set(&"cellar_dials_set")
	await _wait(2.4)
	var n0: int = scares.size()
	gs.modal_open = true
	await _wait(0.3)
	_check("a menu mid-build calls it off (no hit, the cry stopped)", ov._building.is_empty() and scares.size() == n0 and not gs.seen.has(&"cry_scare"))
	await _wait(1.0)
	gs.modal_open = false
	var w2 := 0.0
	while scares.size() == n0 and w2 < 8.0:
		await _wait(0.1)
		w2 += 0.1
	_check("...then it builds again and hits once (%.1fs)" % w2, scares.size() == n0 + 1 and scares[-1] == &"scare_cellar")
	# The torch flickers out with the room's light (a room with no monster:
	# a lit torch wakes the cellar's Crawler, which rightly holds a scare back).
	await _go("ch2_long_hallway")
	gs.set_flag(&"has_flashlight")
	lights.set_light(true)
	var lit_before: bool = lights.is_light_on
	ov._since_last = 999.0
	ov.play(&"scare_cellar")
	await _wait(3.4)
	_check("the torch flickered out with the room's light", lit_before and not lights.is_light_on)
	await _wait(3.6)
	_check("the bed is back ~2 s after the scare's silence (%.1f dB)" % mm._files.level, mm._files.level > mm._files.bed_db() - 4.0)
	_check("eight scares in the table", ov.scares().size() == 8)
	# Stage 6b: the panel escape mid-zoom.
	ov.play(&"scare_escape")
	await _wait(0.8)
	await _shot("sc_scare_escape_late.png")
	await _wait(1.0)
	# Stage 6b: the closet's own telegraph (a crack and a creak) and the walk-up.
	gs.seen.erase(&"scare_closet")
	gs.flags.erase(&"closet_near")
	await _go("ch1_bedchamber")
	ov._since_last = 999.0
	player.global_position = Vector2(48 + 200, 32 + 466)
	var closet: Node = null
	for n2 in fm.current_frame.get_node("Props").get_children():
		if n2.get_script() != null and String(n2.get_script().resource_path).ends_with("closet_scare_event.gd"):
			closet = n2
	await _wait(4.4)
	var cracked: bool = closet._cracked_at >= 0.0
	await _shot("sc_closet_crack.png")
	var c0: int = scares.size()
	await _wait(1.0)
	var early: bool = scares.size() == c0
	# A Controls card (F1 / H) open: no scare may start under it.
	var card = main.get_node("MenuLayer/ControlsCard")
	card.open_in_game()
	player.global_position = Vector2(48 + 930, 32 + 466)
	await _wait(3.0)
	var held: bool = scares.size() == c0 and paused
	card._accept()
	await _wait(1.5)
	print("closet: cracked=%s (creak %s), quiet before the walk-up=%s, held under the controls card=%s, fired=%s" % [cracked,
		am.last_played, early, held, scares.size() > c0 and scares[-1] == &"scare_closet"])
	_check("closet: crack + creak first, then the scare as you walk up (not under a modal)", cracked and early and held
		and scares.size() == c0 + 1 and scares[-1] == &"scare_closet")
	await _wait(2.8)
	await _shot("sc_closet_after.png")
	# The clock's gameplay half: the Crawler appears and hunts.
	await _go("ch2_clock_room")
	ov.play(&"scare_clock")
	await _wait(0.5)
	var crawler = get_first_node_in_group(&"crawler")
	_check("clock scare: the Crawler is close and hunting", crawler.is_hunting() and absf(crawler.global_position.x - player.global_position.x) < 420.0)
	# Spacing, chases and replays.
	gs.seen.clear()
	await _go("ch2_gallery")
	var n: int = scares.size()
	ov._since_last = 10.0
	gs.set_flag(&"gallery_lever")
	await _wait(3.0)
	_check("a scare inside 60 s of the last one waits", scares.size() == n)
	ov._since_last = 999.0
	var shadow = get_first_node_in_group(&"crawler")
	shadow.wake_to(true, 3.0)
	await _wait(1.5)
	_check("...and still waits while the Crawler hunts", scares.size() == n)
	shadow._set_state(0)
	await _wait(1.0)
	_check("...then fires once it is fair", scares.size() == n + 1)
	bus.restart_chapter_requested.emit()
	await _wait(2.0)
	gs.set_flag(&"gallery_lever")
	await _wait(3.0)
	_check("never replayed after a restart", scares.size() == n + 1 and gs.seen.has(&"scare_gallery"))
	print("SCARE TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
