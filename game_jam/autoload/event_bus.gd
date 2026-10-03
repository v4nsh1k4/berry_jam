extends Node
## Global signal hub. Systems emit and listen here instead of holding
## references to each other.

# Flow
@warning_ignore("unused_signal")
signal game_started
@warning_ignore("unused_signal")
signal menu_new_game
@warning_ignore("unused_signal")
signal menu_continue
@warning_ignore("unused_signal")
signal intro_finished
@warning_ignore("unused_signal")
signal restart_chapter_requested
@warning_ignore("unused_signal")
signal quit_to_menu_requested
@warning_ignore("unused_signal")
signal returned_to_menu
@warning_ignore("unused_signal")
signal game_reset

# Frames
@warning_ignore("unused_signal")
signal frame_changed(frame_data: FrameData)
@warning_ignore("unused_signal")
signal exit_entered(exit: ExitData)
@warning_ignore("unused_signal")
signal transition_started
@warning_ignore("unused_signal")
signal transition_finished

# Light and the Crawler
@warning_ignore("unused_signal")
signal light_toggled(is_on: bool)
@warning_ignore("unused_signal")
signal notice_changed(amount: float)
@warning_ignore("unused_signal")
signal player_noticed
@warning_ignore("unused_signal")
signal player_lost
@warning_ignore("unused_signal")
signal player_caught
@warning_ignore("unused_signal")
signal crawler_hushed(duration: float)

# Words
@warning_ignore("unused_signal")
signal bubble_stolen(bubble: BubbleData, from_screen_pos: Vector2)
@warning_ignore("unused_signal")
signal bubble_removed(bubble: BubbleData)
@warning_ignore("unused_signal")
signal bubble_selected(index: int)
@warning_ignore("unused_signal")
signal ability_used(bubble: BubbleData, target_id: StringName)
@warning_ignore("unused_signal")
signal ability_failed(bubble: BubbleData, target_id: StringName)
@warning_ignore("unused_signal")
signal comic_damage_changed(value: float)

# World objects
@warning_ignore("unused_signal")
signal interactable_resolved(interactable_id: StringName, kind: StringName, screen_pos: Vector2)
@warning_ignore("unused_signal")
signal symbol_lock_requested(lock: InteractableData)
@warning_ignore("unused_signal")
signal symbol_lock_solved(lock_id: StringName)

# Presentation
## Text shown in the player's own bubble for a moment ("?" or a spoken word).
@warning_ignore("unused_signal")
signal player_reaction(text: String)
## Empty text hides the prompt. Position is in screen (canvas) space.
@warning_ignore("unused_signal")
signal interact_prompt_changed(text: String, screen_pos: Vector2)
## A short caption box at the top of the panel.
@warning_ignore("unused_signal")
signal caption_requested(text: String, duration: float)
@warning_ignore("unused_signal")
signal shake_requested(amount: float)
## loud = running; the Crawler can hear it.
@warning_ignore("unused_signal")
signal footstep(loud: bool)

# Hiding
## A hiding_spot was used; the player toggles in / out of it.
@warning_ignore("unused_signal")
signal hiding_spot_used(spot_id: StringName, screen_point: Vector2)
## HIDE word: the player's red glow dims for `duration` seconds.
@warning_ignore("unused_signal")
signal player_hide_requested(duration: float)
@warning_ignore("unused_signal")
signal player_concealed_changed(concealed: bool)

# Crawler presentation
## 0..1 how close a risen Crawler is to the player (0 = none / far).
@warning_ignore("unused_signal")
signal crawler_proximity(amount: float, moving: bool)
## The Crawler is about to lunge: a fair warning beat.
@warning_ignore("unused_signal")
signal crawler_telegraph
@warning_ignore("unused_signal")
signal crawler_state_changed(state: StringName)
## A heartbeat was played; strength 0..1 (vignette pulses with it).
@warning_ignore("unused_signal")
signal heartbeat(strength: float)
