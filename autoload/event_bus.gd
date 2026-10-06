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

# Returning words (Chapter 3)
## A stolen word went back to its owner. `screen_pos` is where it landed.
@warning_ignore("unused_signal")
signal bubble_returned(bubble: BubbleData, screen_pos: Vector2)
## The Ink Shadow scribbled out a hiding spot.
@warning_ignore("unused_signal")
signal hiding_spot_erased(spot_id: StringName)

# The twist and the ending (Chapter 3 climax)
## The last word (ERASE) was stolen: the reveal starts and the world freezes.
@warning_ignore("unused_signal")
signal reveal_started
## The reveal has played: GameState.twist_revealed is now true and words can
## be given back.
@warning_ignore("unused_signal")
signal twist_revealed
## The Artist's hand rubs its eraser across the floor at `screen_pos`.
@warning_ignore("unused_signal")
signal hand_erase(screen_pos: Vector2)
## ERASE went back to the hand: cracks seal, the glitch fades, the way out opens.
@warning_ignore("unused_signal")
signal comic_repaired
@warning_ignore("unused_signal")
signal intro_cinematic_finished
@warning_ignore("unused_signal")
signal epilogue_finished
## The player walked out of the page: the save is cleared.
@warning_ignore("unused_signal")
signal game_completed

# Cutscenes, music, goals (Stage 4C)
@warning_ignore("unused_signal")
signal cutscene_started(cutscene_id: StringName)
@warning_ignore("unused_signal")
signal cutscene_finished(cutscene_id: StringName)
## Ask the music to play a track or stinger (MusicManager ids).
@warning_ignore("unused_signal")
signal music_cue(cue: StringName)
## The persistent goal line in the HUD ("" hides it).
@warning_ignore("unused_signal")
signal goal_changed(text: String)
## A scare fired; intensity 0..1 scales its shake and flash (accessibility).
@warning_ignore("unused_signal")
signal scare(kind: StringName, intensity: float)
## A scare with a build-up is starting: music and ambience drop out for `seconds`.
@warning_ignore("unused_signal")
signal scare_building(kind: StringName, seconds: float)

# Stage 4D
## The inventory order changed (reordering words).
@warning_ignore("unused_signal")
signal inventory_reordered
## Something opened: the unified "unlocked" feedback (UnlockFeedback).
@warning_ignore("unused_signal")
signal unlocked(data: InteractableData, screen_pos: Vector2)
## An exit's lock opened (ExitZone draws it open; feedback points at it).
@warning_ignore("unused_signal")
signal exit_unlocked(exit: ExitData, screen_pos: Vector2)
## A GameState flag became true for the first time.
@warning_ignore("unused_signal")
signal flag_set(flag: StringName)
## What is feeding the noticed meter right now (its two HUD icons).
@warning_ignore("unused_signal")
signal notice_sources(light: bool, noise: bool)

## Stage 6: AudioManager played a sound effect (MusicFiles dips bg_track
## under loud ones).
@warning_ignore("unused_signal")
signal sfx_played(sound: StringName, volume_db: float)

## Stage 6: E on a plain "inspect" object (the awakening mirror's ghoul).
@warning_ignore("unused_signal")
signal inspected(id: StringName)

## Stage 6b: a one-time tutorial hint (Hints.once). PageOverlay queues them
## at the bottom right, one at a time, each held for its reading time.
@warning_ignore("unused_signal")
signal hint_requested(text: String, duration: float, urgent: bool)
