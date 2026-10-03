extends Node
## Debug test for the "inventory full" bug: steals COUNT words and checks each
## one lands in GameState.inventory, can be selected (cycling and number keys),
## is shown by the strip when selected, can be spoken, and survives a save /
## load round trip. Your real save file is backed up and restored.
## Run:  godot --path . res://tests/inventory_test.tscn   (exit code 0 = pass)
## Not exported: tests/* is excluded in export_presets.cfg.

const COUNT: int = 12
const WORD_DIR: String = "user://test_words"

var _failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
		push_error("FAIL: " + what)


func _run() -> void:
	var backup: String = ""
	if FileAccess.file_exists(SaveSystem.SAVE_PATH):
		backup = FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	EventBus.game_started.emit()
	EventBus.menu_new_game.emit()
	# New Game opens with the intro cinematic: skip it like a click would.
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	EventBus.intro_finished.emit()
	await get_tree().process_frame
	var strip: Control = main.get_node("HUDLayer/InventoryStrip")

	# 1. Steal COUNT words, each saved as a real resource so saves can find it.
	DirAccess.make_dir_recursive_absolute(WORD_DIR)
	var ids: Array[StringName] = []
	for i in COUNT:
		var word: BubbleData = BubbleData.new()
		word.id = StringName("test_word_%d" % i)
		word.text = "W%d" % i
		word.ability_id = &"help"
		word.stolen_from = &"test"
		var path: String = "%s/w%d.tres" % [WORD_DIR, i]
		ResourceSaver.save(word, path)
		GameState.add_bubble(load(path) as BubbleData, Vector2(640, 300))
		ids.append(word.id)
		_check(GameState.inventory.size() == i + 1, "word %d added (inventory %d)" % [i, GameState.inventory.size()])
	_check(strip.call("is_index_visible", COUNT - 1), "newest word scrolled into view")

	# 2. Cycle through every word: selectable, visible when selected, usable.
	GameState.select(0, false)
	for i in COUNT:
		_check(GameState.selected_index == i, "cycle reaches word %d" % i)
		_check(strip.call("is_index_visible", i), "word %d visible when selected" % i)
		AbilityRegistry.reset_cooldowns()
		_check(AbilityRegistry.speak(GameState.selected_bubble(), null), "word %d can be spoken" % i)
		GameState.cycle(1)
	_check(GameState.selected_index == 0, "cycling wraps back to the first word")
	GameState.cycle(-1)
	_check(GameState.selected_index == COUNT - 1, "cycling backwards wraps to the last word")

	# 3. Number keys pick a slot inside the visible window.
	var slot_event: InputEventAction = InputEventAction.new()
	slot_event.action = "bubble_slot_3"
	slot_event.pressed = true
	Input.parse_input_event(slot_event)
	await get_tree().process_frame
	_check(GameState.selected_index == strip.call("first_visible") + 2, "key 3 selects the third visible slot")

	# 4. Save / load round trip keeps every word in order.
	var snapshot: Dictionary = GameState.to_dict()
	GameState.reset()
	_check(GameState.inventory.is_empty(), "reset empties the inventory")
	_check(GameState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), "snapshot loads")
	var loaded: Array[StringName] = []
	for word in GameState.inventory:
		loaded.append(word.id)
	_check(loaded == ids, "all %d words survive save/load in order" % COUNT)

	# Clean up and restore the player's own save.
	for i in COUNT:
		DirAccess.remove_absolute("%s/w%d.tres" % [WORD_DIR, i])
	if backup != "":
		var file: FileAccess = FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
		file.store_string(backup)
		file.close()
	else:
		SaveSystem.clear()
	if _failures.is_empty():
		print("INVENTORY TEST PASSED: %d words" % COUNT)
	else:
		print("INVENTORY TEST FAILED (%d): %s" % [_failures.size(), ", ".join(_failures)])
	get_tree().quit(0 if _failures.is_empty() else 1)
