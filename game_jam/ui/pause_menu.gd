extends Control
## Esc / P while playing: Resume, Restart Chapter, Sound on/off, volume,
## Quit to menu. Pauses the tree; this node keeps running.

var _mute_button: Button
var _resume_button: Button
var _volume: HSlider
var _music_button: Button
var _music: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiTheme.make_screen(self)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	box.add_child(UiTheme.make_label("PAUSED", 44))
	_resume_button = UiTheme.make_button("Resume", close)
	box.add_child(_resume_button)
	box.add_child(UiTheme.make_button("Restart Chapter", _on_restart))
	_mute_button = UiTheme.make_button("", _on_mute)
	box.add_child(_mute_button)
	box.add_child(UiTheme.make_label("Volume", 18))
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.custom_minimum_size = Vector2(320, 28)
	_volume.value_changed.connect(_on_volume_changed)
	box.add_child(_volume)
	_music_button = UiTheme.make_button("", _on_music_mute)
	box.add_child(_music_button)
	_music = HSlider.new()
	_music.min_value = 0.0
	_music.max_value = 1.0
	_music.step = 0.05
	_music.custom_minimum_size = Vector2(320, 28)
	_music.value_changed.connect(MusicManager.set_music_volume)
	box.add_child(_music)
	box.add_child(UiTheme.make_button("Quit to Menu", _on_quit))
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		close()
	elif GameState.is_playing and not GameState.modal_open and not TransitionManager.is_playing:
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	_volume.set_value_no_signal(AudioManager.master_volume)
	_music.set_value_no_signal(MusicManager.music_volume)
	_refresh_mute()
	show()
	get_tree().paused = true
	_resume_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false


func _refresh_mute() -> void:
	_mute_button.text = "Sound: Off" if AudioManager.muted else "Sound: On"
	_music_button.text = "Music: Off" if MusicManager.music_muted else "Music: On"


func _on_music_mute() -> void:
	MusicManager.set_music_muted(not MusicManager.music_muted)
	_refresh_mute()


func _on_mute() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_refresh_mute()


func _on_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value)


func _on_restart() -> void:
	close()
	EventBus.restart_chapter_requested.emit()


func _on_quit() -> void:
	close()
	EventBus.quit_to_menu_requested.emit()
