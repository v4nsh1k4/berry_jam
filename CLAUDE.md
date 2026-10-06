# INK-BLEED: handoff for Claude Code

This repo (`v4nsh1k4/berry_jam`; the work is on **`main`**, mirrored on branch
`ink-bleed`) holds a game-jam entry. **The game lives in `game_jam/`.** Ignore `berry-jam/` (an old, unrelated
first attempt) and `ink-bleed-(4.3)/` (a stale editor backup the user should
delete; never commit it). `proposal.pdf` is the original proposal.

Read this whole file before changing anything. It records what was built, how
it fits together, and *why* each decision was made.

---

## 1. The project in one paragraph

*Ink-Bleed* is a 2D psychological-horror puzzle game set inside a comic book,
*The Silent House of Hollow Hill*. The player is an "unperson": a faceless
figure with an **empty speech bubble**, drawn in **red**, the only colour in a
black-and-white comic. They **steal words** (speech bubbles) from characters
and **speak** them as abilities (OPEN a door, PUSH a cabinet...). Light (a
flashlight from the end of Chapter 1) reveals the house but draws the **Ink
Crawler**. Every stolen word **damages the comic** (cracks, ink bleed, wobble,
glitch). **Twist (built in Stage 4B):** stealing the last word (ERASE) from the
Ink Shadow plays the reveal: the Crawler and the Shadow are the **Comic
Artist's hand** (long jointed fingers with pen-nib tips), the player is the
mistake on the page, and the way out is **giving every word back**. Only after
the reveal can words be returned. Then the comic repairs, the player walks out
through the border, and an epilogue plays in the real world.

Jam theme: COMIC / LIGHT / TWIST. Target: desktop browser on itch.io (HTML5 zip).

## 2. The user and how to work with them

- The user is new to Godot and on a **Mac**. Explain how to run and test in
  plain steps. In the Godot editor: ▶ (top right), **⌘B**, or fn+F5. The editor
  canvas looks empty because everything is drawn by code at runtime.
- Godot binaries differ per machine. On the original machine:
  `/Users/vanshikar/Downloads/Godot.app/Contents/MacOS/Godot` (4.7.2). On the
  machine used for Stage 4B: `~/Downloads/Godot_mono.app/Contents/MacOS/Godot`
  (4.7.2 **.NET**). The .NET editor runs and tests the game fine but **refuses
  Web export** ("not supported when using C#/.NET"), even for a GDScript-only
  project. Export with a standard (non-.NET) 4.7.2 editor; its web templates
  go in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`
  (`web_nothreads_release.zip`, `web_nothreads_debug.zip`).
- **Working style they chose:** carry on through all items of a stage without
  stopping after each one, **test everything yourself** (scripted runs plus
  screenshots), and give **one report at the end** with per-system test
  instructions. Stop only for real decisions or permissions.
- **Ask before architecture-changing decisions.** Small structural moves that
  keep behaviour (splitting a long script, a subclass) are fine to do and
  mention.
- **Commit or push only when asked.** The team works from `main` (the user asked
  for the game to be on `main` so others can start from it). Attribution: end commit messages with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- They paste long staged briefs ("Stage N"). Each brief repeats the standing
  rules below; follow them strictly.

## 3. Standing rules (from every brief)

- Godot 4.7.2 (written to stay 4.3-compatible where cheap), **GDScript only**,
  **Compatibility renderer**, must export to Web without threads.
- **Original hand-written code.** No addons, starter kits or templates. All art
  and sound are **procedural** (`_draw()`, shaders, generated audio). The
  default font only. **No audio files except three team-made ones**:
  `res://audio/baby_cry.wav` (Stage 5, CryBank), `res://audio/bg_track.wav`
  and `res://audio/ending.wav` (Stage 6, MusicFiles). Everything else is
  synthesized.
- **Static typing everywhere** (`var x: float = 1.0`, typed returns).
- **Systems talk only through `EventBus` signals.** Small public methods on
  autoloads (`GameState.add_bubble`, `AbilityRegistry.speak`) are the
  exception, not scene-to-scene references.
- **Content is `.tres` data** (frames, words, abilities, chapters), not code.
- **Scripts under about 250 lines.** Split when larger (see the precedents in §6).
- Mark future hooks with `# TODO(later): ...` (Stage 4B climax, the final word).
- **Keep `editor/export/convert_text_resources_to_binary=false`** (see §9).
- Red (`InkDraw.RED`, #C8102E) means **the player, danger or damage** only.
  Never flood the screen with it. Speech bubbles stay black and white.

## 4. Status by stage

| Stage | What it delivered |
| --- | --- |
| 1 | Frame (panel) system, transitions, player, flashlight, bubble stealing, inventory, basic Crawler, test chapter |
| 2 | Ability system, Chapter 1 (6 rooms), light rework, foreshadowing, polish (shake, FX, procedural audio), menus, pause, saves |
| 3 | Inventory bug fix (no cap, paging), stand-under targeting, red art direction, Crawler redesign (state machine, stop-motion), WAIT and HIDE, hiding spots, light-revealed objects, Chapter 2 (7 frames), chapter chaining |
| 4A | Return-the-words mechanic, Chapter 3 frames 1-4, glitch/breakdown visuals, Ink Shadow v1, damage recalibrated to 9 words, debug room jump |
| 4B | Story reorder (no returning before the reveal), Gallery ability puzzle, the Ink Heart and the final steal (ERASE), the reveal, the return phase with the Artist's hand, the final word and repair, the Last Page, epilogue, intro cinematic, save v2 migration, F9 debug jump |
| 4C | Pacing pass to ~15 min (Torn Page cut, one batched Returning Room, gallery return removed, Ch1 intro captions cut), CutsceneSystem + C1-C6, reveal rewrite (9 captions, ~35 s, goal line), light puzzles (4 in Ch2, 3 in the spread, light disabled in the Ink Heart), the page spread (Gallery of Words), scarier monster, one major + one minor jumpscare, MusicManager, intro/ending as comic pages, save v3, F6-F10 debug keys |

| 5 | Atmosphere pass: a shorter intro (25 s → 18.5 s) where the reader is sucked into the comic; C1, C2 and C4 first person (red hands, empty bubble, vignette); more detail in every cutscene (same beats, same 32.64 s); a wooden door creak (3 variants, pitch jittered) for every door, exit and secret door; an ominous music bed under all of Chapters 1-3; a sixth scare (the cellar: silence, the cry, lights out, a huge face); the team's recorded cry at three one-time moments |
| 6 | C1 back to third person (a comic page: the theft from outside); reveal second half rewritten ("author", "You were the monster." held in near-silence) + recap; the return-phase hand holds the ERASER end in every state; tonal `groan` / `growl` replace the old flatulent `creak` / `growl`; the team's `bg_track.wav` as the Chapter 1-3 bed (dips under SFX, drops for big moments) and `ending.wav` once at the epilogue; a melancholy layer on the menu; comic black-and-white credits; the awakening mirror's ghoul; cobwebs and watching eyes in 11 rooms; psychedelic fill in cutscene panels; crows + scrawled lettering on the title page and menu; an abstract falling figure in the intro |
| 6b | Credits without the font / licence lines; the crow ring round the End Card credits; a new mirror line (+ `repeat_caption`); C2 without hands; the intro finger normal-length (arm with fixed bone lengths) and the pull a red whoosh (no figure); the home page on the scenes' beige with black lettering; clearer instructions (hints queued at the bottom right, NOTICED / HUNTED! meter, E-says-the-selected-word, Controls card lines); clickable inventory arrows; the controls card any time (F1 / H, pause menu Controls page); cutscenes re-timed for reading (32.64 s → 48.40 s); two new scares (closet, panel escape: eight in all); the music +9 dB everywhere with softer ducks |
| 4D | 22 playtest fixes: real Study and Clock dial locks (TRY + "?"), every clue used (hallway, plaque, clock), decoy doors removed, forgiving spread jump (buffer + coyote, W/Up), no duplicate words (x2 slots), WAIT made useful (pendulum, gutter fingers) with a frost effect, unified unlock feedback (captions, pop-ups, sound, pulse, padlocks that drop, gated exit doors, off-screen arrow), word tooltips + selected-word line, reorder (drag, Shift+Q/R), controls card on New Game, noticed-meter cause icons + noise from running, margin doodles, clean chapter title cards, reveal rebuilt (morph, label card, recap), five one-time scares, return/erase music + build-up layers, the Artist's pencil, save v4 |

Git history on `main`: Chapters 1-2, Stage 4A, a handoff note, Stage 4B,
Stage 4C, the study-lock cut (since reverted by 4D), Stage 4D (d1e2764).
Stage 5 (d462ec3). Stage 6 (804ed89). Stage 6b (the commit after it).
A Claude Docs page "Ink-Bleed: Game Flow & Architecture" was written after
Stage 2. It does **not** cover Stages 3-4B; this file is the up-to-date source.

## 5. How to run, test and export

```
cd game_jam
GODOT=/Users/vanshikar/Downloads/Godot.app/Contents/MacOS/Godot   # see §2 for other machines
$GODOT --headless --path . --import            # re-import after adding files
$GODOT --headless --path . --script res://tests/compile_check.gd               # loads every script: parse/type errors
$GODOT --path .                                 # play
$GODOT --headless --path . res://tests/inventory_test.tscn                       # prints INVENTORY TEST PASSED
SHOT_DIR=/some/dir $GODOT --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_story.gd
$GODOT --headless --path . --export-release "Web" build/web/index.html           # web export (non-.NET editor)
$GODOT --main-pack build/web/index.pck --resolution 1280x720 --script res://tests/playthroughs/ch2_play.gd
```

- `tests/playthroughs/*.gd` are SceneTree scripts that drive the real game:
  `intro_play` (cinematic), `ch1_play`, `ch1_flows` (drawer, continue,
  restart), `ch2_play`, `ch2_caught` (telegraph, catch, restart), `save_check`,
  `ch3_margin` (Shadow chase), `ch3_story` (all of Chapter 3 in story order:
  no returns before the reveal, Gallery puzzle, the Heart, the reveal, the
  return phase, repair, Last Page, epilogue, end card; `MINIMAL=1` carries only
  OPEN, PUSH, REMEMBER), `ch3_systems` (save v1 migration, resuming mid-reveal,
  Restart after the reveal, the hand's telegraph/catch/hiding/WAIT/weakening,
  lost-word fallback, the Heart's listening), `menu_clicks`, `exit_grace`.
  Stage 4C added: `cutscenes` (every beat screenshotted, triggers, skip
  grace, `seen` saved and kept on restart), `reveal_check` (each caption beat,
  goal line), `spread_play` (the whole page spread with real inputs: hops,
  jump, lens, pool drop, gutter fall, crate bridge, lever, fingers, door),
  `scare_check` (both scares, once only), `music_check` (render time, slowest
  frame, clipping, loop seams), `cinematics_check` (intro and ending pages).
  Older playthroughs skip cutscenes by connecting `cutscene_started` to
  `CutsceneSystem._finish`. Stage 4D added `gates_check` (Study and Clock
  locks incl. wrong codes and save/load, unlock captions, the gallery lever,
  the cellar marker after reload / save-load / light on-off, the spread
  door's padlock) and `ui_check` (controls card, title card, doodles, hover
  tooltip + x2, meter icons, the final room's hand). New Game now waits on
  the controls card: tests press it (`MenuLayer/ControlsCard._accept`).
  Stage 5 extended `cutscenes` (lengths vs. Stage 4D, three shots per POV
  beat, slowest frame; `ONLY=c1_first_steal,c2_torch` runs some),
  `cinematics_check` (the 18.5 s intro, the cry at its end once; `FAST=1`
  jumps the clock for quick shots), `scare_check` (six scares, the cellar
  build-up: music/ambience near silent, cry, light out; a menu calls it off
  and it retries), `music_check` (the bed under Ch1-3 rooms, back within
  ~2 s after cutscene/lunge/scare drops, off for reveal/return; new sounds
  and cry variants, clipping), `gates_check` (creak for door / exit / secret
  door, click for padlock / dials / lever), `reveal_check` (the thin cry on
  the erase beat, once).
  Stage 6 extended `cutscenes` (C1's six shots; median / 95th percentile /
  slowest frame), `reveal_check` (the five new captions in order, "author"
  everywhere, "never a monster" once, the held near-silent last beat longest,
  label and recap text), `ui_check` (title page, menu, Controls, the comic
  Credits page incl. Esc and a click on Back, the End Card credits incl. Esc,
  the mirror ghoul (full then short, input never blocked), webs/eyes in three
  rooms dark and torch-lit, the return-phase hand in hover/aim/rub/lift/
  watch/offer), `music_check` (bg_track / ending.wav facts, bg_track under
  Ch1-3 rooms without restarts, the 3 dB dip under a door creak, out in
  ~0.25 s for cutscene / lunge / scare / reveal and back within ~2 s, the
  crossfaded loop, off in the return phase, ending.wav once then the
  synthesized ending, Back to Menu stops all, the menu layer: on, no clipping,
  gaps of silence, mute + focus), `scare_check` (bg_track in the cellar build).
  They print a log and save screenshots to `$SHOT_DIR`. Read the screenshots,
  because visual bugs (cyan glitch blocks, a pink vignette flood) only showed
  up there. `tests/visual/art_preview.gd` renders any drawing call to a PNG.
- **A hidden test window is never drawn** (another Space, a full-screen app,
  even with `--always-on-top`), so `frame_post_draw` never fires and a
  screenshot waits for ever. Every `_shot` now waits 20 frames and then
  `RenderingServer.force_draw()`s. Mouse-aimed torch steps (`warp_mouse`)
  still fail in a hidden/unfocused window: in Stage 5, `ch2_play` on the
  pack failed at a different torch step each run while desktop passed.
- **Run with `--disable-vsync`** on macOS: an occluded/unfocused test window
  can block on vsync and freeze the run at a screenshot (looks like a hang
  with no error). Unfocused windows can also drop `warp_mouse`, so a torch-
  aiming step can fail once; rerun before suspecting the game.
- **Run tests one at a time:** they share `user://ink_bleed_save.json`. A test
  that errors never quits (the window stays open): kill it. Long runs can have
  their window shrunk by the desktop, so `_shot` resets it to 1280x720 first.
- **Always run the playthroughs against the exported pack too** (`--main-pack`).
  It runs the same compiled scripts as the web build, and two export-only bugs
  were caught only this way (§9).
- Debug builds only: **jump to any room**. On the web add `?frame=ch3_margin`
  (optionally `&words=arthur_open,vane_hide` and `&twist=1`); on desktop run
  with `-- --frame=ch3_margin [--words=...] [--twist=1]`. **In game (debug
  builds, e.g. the editor's ▶): F6** next cutscene, **F7** next jumpscare
  (cycles all eight, right where you are), **F1 / H** the controls card (all builds), **F8** the reveal, **F9** next Chapter 3 room, **F10** the page
  spread (all in `main._unhandled_key_input`). `DebugJump` adds the
  words a player would carry; return-phase rooms also get ERASE and
  `twist_revealed`.
- Web check in a browser: serve `build/web` with `python3 -m http.server`. The
  Claude Code sandbox blocks local servers, so that needs
  `dangerouslyDisableSandbox` (it worked with the user's approval). The in-app
  browser pane must be visible: a hidden pane gives a zero-size canvas and
  misleading WebGL errors.
- itch.io: zip the *contents* of `build/web` (index.html at the root), HTML
  project, 1280x720, no SharedArrayBuffer needed (threads are off).

Test-writing gotchas: scripts run with `--script` can't reference game
`class_name`s at parse time before the autoloads exist (it breaks compilation),
so find nodes by **group** (`get_first_node_in_group(&"crawler")`) and use
duck typing. GDScript lambdas capture locals **by value** (use an Array as a
box). Don't name test methods after `SceneTree` methods.

## 6. Architecture

### Autoloads (`game_jam/autoload/`, in load order)
| Autoload | Owns |
| --- | --- |
| `EventBus` | ~52 signals, no logic. Each signal has `@warning_ignore("unused_signal")` (per line, for 4.3 compatibility) |
| `AudioManager` | Builds every sound on the first click (`SfxSynth`; newer ones one per frame via `_pending`; a `_pending` entry may be a job object whose `next()` returns null until done, e.g. `SfxSynth3.Groan`), emits `EventBus.sfx_played` for every sound, SFX voices, drone, Crawler dread (heartbeat speeding with notice, rumble, skitter, growl), volume and mute in `user://settings.cfg`. Stage 5: `play_door_creak()` (3 creaks), `play_cry(variant, db, fade_in, once_id)` / `stop_cry()` (CryBank), `hush(s)` (drone/heartbeat out), `last_played` (tests) |
| `ShakeManager` | Trauma shake (trauma squared, decays) on the viewport canvas transform; also holds the frame's **base tilt** (`FrameData.panel_tilt`, rotated about the panel centre) |
| `GameState` | `inventory` (uncapped, single source of truth), `selected_index`, `flags`, `stolen_bubble_ids`, `returned_bubble_ids`, `stolen_bubble_count`, `comic_damage` (+ eased `shown_damage`), **`twist_revealed`**, `current_chapter`, `chapter_start` snapshot, `is_playing`, `modal_open`; `return_bubble`, `reveal_twist`, `normal_words_held`, `held_share`, `glitch_of`; save/restore (`to_dict` / `from_dict`, built by `StateSnapshot`) |
| `LightingSystem` | Flashlight on/off (F / left click), only with flag `has_flashlight` |
| `FrameManager` | Loads `data/frames/<id>.tres`, builds the `Frame`, places the player, exits, reload on `player_caught` |
| `TransitionManager` | SLIDE (page sheet) and INK_SPLASH (shader) wipes around a swap |
| `AbilityRegistry` | ability id → `AbilityData` + handler instance, `speak()`, cooldowns (`ABILITY_PATHS` list) |
| `CutsceneSystem` | CanvasLayer 55. Loads `data/cutscenes/*.tres` (`CUTSCENE_PATHS`), plays one when its trigger fires (`first_steal`, `resolved:<id>`, `frame:<id>`, `repaired`), pauses the tree, skippable after 0.6 s, marks it in `GameState.seen` |
| `MusicManager` | Music bus (→ Master), tracks rendered a chunk per frame (`MusicRenderer` + `MusicSynth`/`MusicSynth2`/`MusicSynth3`), crossfades, build-up layers (`MusicLayers` child: pulse → strings swell → hunt), the team's files (`MusicFiles` child: bg_track under ch1/ch2/ch3 rooms, ending.wav at the epilogue; the Stage 5 synthesized **bed** only if bg_track is missing), the menu's melancholy layer (`menu_sad`, `SAD_DB` -19), stingers, ducking, focus-loss mute; music volume/mute in `settings.cfg` |

### Scene tree (`scenes/main.tscn`) and canvas layers
World (layer 0: the `Frame` under `World/FrameRoot`, plus `World/Player`; the
Frame's `CanvasModulate` darkens only this layer) → PageLayer 10 (follows
the viewport so it shakes and tilts with the world: `GlitchOverlay`,
`InkBleed`, `PageOverlay` = white gutter, border, cracks, captions) → HUDLayer
20 (`InventoryStrip`, `NoticeMeter`, `InteractPrompt`, `GoalLine`) → FXLayer 25
(`DangerVignette`, `FeedbackFx`, `UnlockFeedback`, `JumpscareOverlay`) → LockLayer 40 →
TransitionManager 50 → CutsceneSystem 55 →
MenuLayer 60 (IntroCinematic, IntroSequence, RevealSequence,
EpilogueSequence, EndCard, MainMenu, ControlsCard, PauseMenu) → StartLayer 100. The panel
is the fixed `Frame.PANEL_RECT` = (48, 32, 1184×528) on a 1280×720 page. All
room data is in **panel coordinates**. The floor is y ≈ 380 and feet walk in
y 400-504.

### Flow (`scripts/main.gd`)
Title (click or key; browsers need that gesture before audio) → menu → **New
Game: `IntroCinematic`** (18.5 s, Space/click skips) → chapter intro
(`ChapterData.intro_lines`) → `_start_chapter` (sets `current_chapter`, takes
the `chapter_start` snapshot, applies `line_jitter`) → frames → a frame with
**`next_chapter`** hands off after 1.5 s to the next chapter's intro → ... →
Chapter 3: stealing the `story_final` word plays **`RevealSequence`**, which
sets `twist_revealed`, **retakes `chapter_start` at
`ChapterData.return_frame_id`** and lands the player there → return phase →
repair → the Last Page → walking out of the border reaches `ch3_outside`
(`FrameData.epilogue`): **`EpilogueSequence`** (emits `game_completed`: save
cleared, progress flag `completed`) → `EndCard` ("THE END", credits, Back to
Menu). **Restart Chapter** restores `chapter_start` and goes to its frame:
words carried in stay, this chapter's (or this phase's) thefts and returns are
undone. **Autosave** (`user://ink_bleed_save.json`, IndexedDB on the web)
happens on every frame change, theft, solved object and quit to menu.

**Save format v4** (`SaveSystem.VERSION`): v2 added `twist_revealed`; v3
added `seen` (watched cutscenes and fired scares); v4 (Stage 4D) only
migrates flags: a save with `clock_read` also gets `clock_solved` (reading the
clock used to open its door; now the dial box does). Inventory order is the
saved order (reordering persists). One-time hints live in progress.cfg. `SaveSystem.migrate()` upgrades v1 (Stage 4A) saves: Chapters 1-2 as they are;
a save inside Chapter 3 restarts at Chapter 3's `chapter_start` (so the reveal
is never skipped); unusable or future-version saves count as "no save". A save
naming a frame that no longer exists (Stage 4C removed `ch3_torn_page`,
`ch3_torn_return`, `ch3_gallery_return`) falls back to its chapter's first
frame, or `return_frame_id` after the twist.
`user://progress.cfg` (`SaveSystem.get_progress/set_progress`) survives new
games: `seen_reveal` (the reveal is skippable only after one full viewing) and
`completed`.

### Data model (`scripts/data/`, files in `data/`)
- `FrameData`: id, display_name, ambient_light, background_style,
  player_spawn, walk_area, captions, exits (`ExitData`), interactables
  (`InteractableData`), npcs (`NpcData`), crawler_spawn, crawler_patrol,
  crawler_kind (`&"crawler"`, `&"shadow"` or `&"heart"`), lights
  (`LightSpotData`), events (ids in `Frame.EVENT_SCRIPTS`, incl.
  `artist_hand`), hint (for HELP), ending_card, next_chapter, glitch,
  panel_tilt, sketch, **border_gap** (the lit way out in the right border once
  repaired), **epilogue** (arriving plays the epilogue), **light_disabled**
  (the torch won't work: "The ink drinks the light."), **spread**
  (`PageSpreadData`: the frame is a page of small panels).
- `PageSpreadData` → `panels: Array[SpreadPanelData]` (id, rect, tilt,
  ambient, style, floor_y, entry, gap + gap_bridge_flag + gap_lit_bridge),
  `hops: Array[SpreadHop]` (from_panel, trigger right/left/jump/fall/down,
  zone_x, to_panel, to_point, requires_flag, locked_caption), page_number,
  finger_hazard. Interactables and NPCs stay in the frame's normal lists, in
  frame coordinates; each belongs to the panel that contains it.
- `CutsceneData` (id, trigger, skippable, music_cue, beats) →
  `CutsceneBeat` (duration, `panels: Array[Rect2]` as page fractions, draws
  = `CutsceneArt` ids, caption, camera still/zoom_in/zoom_out/pan_left/
  pan_right/shake, sfx, page_turn). Generated by `tools/datagen/gen_cutscenes.py`.
- `BubbleData`: id, text, ability_id, stolen_from (an owner id: `arthur`,
  `mrs_vane`, `portrait_lady`, `drawer`, `hand`), **owner_name** (for "give
  back to Arthur"), **story_final** (ERASE: stealing it plays the reveal,
  returning it repairs the comic), consumable (always false so words are
  never used up and nothing soft-locks). **Each word is its own file named
  `<id>.tres`**, because saves store the paths and fall back to
  `data/bubbles/<id>.tres`.
- `NpcData`: bubbles plus `lines` (with `{word}`), `broken_lines`,
  `reactions` (when robbed), `relief_lines` (when given back), **plea_lines**
  (Chapter 3 before the reveal, one per approach), `words_stealable` (false in
  Chapter 3 except the Shadow's ERASE), `visual_style` (`butler`, `portrait`,
  `housekeeper`, `none` = only the bubble), bubble_offsets, scale, reach_y.
- `InteractableData.kind`: word targets `door`, `drawer` (`reward_bubble`),
  `latch`, `pushable`. Plain E: `inspect`, `pickup`, `symbol_lock` (text
  `"panel"` = wall box), `hiding_spot` (text: wardrobe, curtain or table).
  Passive: `memory` (REMEMBER), `writing`, `clock`, `secret_door` (opens when
  `requires_flag` is set). Chapter 3: `return_spot` (`owner_id`; text painting
  or drawer). Plus `revealed_by_light` (only visible and usable inside the
  flashlight cone). Light kinds (Stage 4C, `LightPuzzle` subclass): `light_ink`
  (text door/pool/growth; recedes under the cone for `light_hold` s, creeps
  back in the dark), `lens` (lit for `light_hold` s → sets its flag, beam
  along `push_offset`), `lit_writing` (shows once `requires_flag` is set),
  `shadow_puzzle` (stand inside `stand_spot` and light it: its shadow
  (symbols[0]) slides into the wall outline), `lever` (plain E; hidden in the
  dark if `revealed_by_light`, hidden until `requires_flag` if set).
- `ChapterData`: title, intro_lines, first_frame_id, damage_visual_scale,
  line_jitter, allows_return, **return_frame_id** (where the reveal lands).
- `HandPressureData` (`data/hand/hand_pressure.tres`): the Artist's hand
  tuning as strong/weak pairs (interval, telegraph, width, speed) plus
  rub_time and first_delay. Edit the `.tres` to tune it.
- `AbilityData`: id, display_name, description, icon_word, target_type
  (INTERACTABLE / ROOM), cooldown, duration, handler script.

**Data generators:** `tools/datagen/gen_lib.py` plus `gen_ch1.py`, `gen_ch2.py`,
`gen_ch3.py` write whole chapters, `gen_cutscenes.py` the cutscenes. Run them from `game_jam/`
(`python3 tools/datagen/gen_ch3.py .`). They **overwrite** that chapter's
`.tres` files, so edit the generator rather than the `.tres` (or stop using the
generator for that chapter). `tests/` and `tools/` are excluded from the export.

### Key systems
- **Words loop** (`scripts/player/interactor.gd`): bubbles in reach win, and the
  one chosen is the bubble the player **stands under** (nearest along the floor,
  within 120 px; ties go to the facing side; within 380 px of the speaker). The
  mouse is never used for picking, so it stays free to aim the flashlight. Hold E
  0.5 s to steal (`GameState.add_bubble`). E at an object speaks the selected
  word via `AbilityRegistry.speak`; E with nothing near speaks into the room.
  Interactables need the player within **130 px of their interact point**
  (bottom centre + 20). Keep data inside that, because two bugs were exactly this.
- **Abilities** (`scripts/abilities/`): OPEN, PUSH, REMEMBER (memory sketches
  5 s), HUSH (Crawler blind 8 s, 20 s cooldown), HELP (frame hint), WAIT (freezes
  the nearest freezable thing for 5 s, a risen Crawler first), HIDE (aura near
  zero, concealed 6 s, 25 s cooldown). A wrong word gives "?" and a shudder,
  never a failure.
- **Inventory** (`ui/inventory_strip.gd` + `inventory_art.gd`): 6 visible
  slots window over an uncapped list. **1-6** pick a visible slot, **Q / R** or
  the wheel cycle (`GameState.cycle`). E was not used for cycling because E is
  interact. "+N" arrows show hidden words.
- **Return mechanic**: `GameState.return_bubble(bubble, pos)` removes the
  word, updates stolen/returned ids, count and damage, and emits
  **`EventBus.bubble_returned`**. Give a word back by holding E 0.7 s under the
  owner's **broken** bubble (group `returnable`), or press E at a `ReturnSpot`
  (painting or drawer). **Only after the reveal** (`GameState.can_return()` =
  `twist_revealed` and `allows_return`); before it, broken bubbles are not
  targetable, return spots are scenery, and owners plead (`plea_lines`).
  **Why:** the story order is damage → chase → final steal → reveal → return.
  Prompts name the owner ("Hold E: give "OPEN" back to Arthur"; "Arthur is
  missing "PUSH". Select it..."), and so does the inventory tooltip. Returned
  bubbles show their full line and are never stealable again. Owners never
  robbed are whole from the start. ERASE goes back last (1.4 s hold; refused
  while any ordinary word is held). Fallback: a word marked stolen that is no
  longer in the inventory goes home by itself when the player nears its owner
  (`GameState.restore_lost_word`). Return FX: warm two-note chime, THANK YOU,
  red-to-white drops, relief caption, the comic heals smoothly
  (`shown_damage` eases at 0.8 words/s).
- **The reveal** (Stage 6 rewrote the second half: see "Stage 6 systems"
  below; this paragraph describes 4B/4C) (`ui/reveal_sequence.gd` + `reveal_art.gd` +
  `reveal_art_tear.gd`, ~35 s, unskippable the first time): on stealing a
  `story_final` word (or resuming a save holding it with the twist unseen) it
  emits `reveal_started`, pauses the tree, and plays nine one-idea captions,
  each on its beat: the Shadow resolves into a hand with a pen ("The hand holds
  a pen.") → pull back to the page ("This comic has an Artist.") → the desk
  ("Everyone here says only what the Artist wrote.") → back in on the red
  figure ("I was never written...") → the hand swaps to the eraser and rubs the
  figure's legs out, dust falling ("The Artist is erasing me..." / "It was the
  Artist's hand.") → the cost: robbed characters with broken lines ("And every
  word I stole..."), rips tear down the page ("Every theft tore the page.") and
  stitch with light ("To mend it, I must give it all back."). Then
  `reveal_twist()`, `chapter_start` retaken, land in `return_frame_id`, and
  `goal_changed("Give back what you took.")` shows the HUD goal line
  (`ui/goal_line.gd`; it fades on the first return, flag `goal_first_return`).
- **The Artist's hand** (`scripts/enemy/artist_hand.gd`, drawn by `HandArt`
  and `HandFloorArt`; a frame lists it as the `artist_hand` event). States:
  HOVER → AIM (the eraser's hatched shadow darkens a strip of floor + growl;
  ≥ 0.6 s, 1.1-1.6 s by default) → RUB (0.55 s; the only time it catches:
  in the strip and not hidden) → LIFT → HOVER; WATCH once no ordinary word is
  held (no attacks); OFFER (Ink Heart, ERASE selected nearby: eraser set down,
  grip open); WITHDRAW after ERASE is back. Weaker with every return via
  `GameState.held_share()` and `HandPressureData`. HUSH pauses attempts, WAIT
  freezes it (group `freezable`), hiding is safe. Caught → room reloads,
  returns kept.
- **Heart Shadow** (`heart_shadow.gd`, `crawler_kind = &"heart"`): an Ink
  Shadow without the ink wall that paces `LAIR` (panel x 960-1110) beside the
  word and every 4.5 s LISTENS: 0.9 s warning (stops, eyes go wide and white,
  growl, first time a caption) then 1.8 s where any movement within 700 px
  (not concealed) wakes it hunting (scent 4 s, faster). It leaves the lair to
  hunt and sinks back after losing you (not relentless); it scribbles out
  hiding spots only while after you. Freezes for good on `reveal_started`.
- **Repair** (`GameState.return_bubble` of the `story_final` word sets flag
  `comic_repaired` and emits **`comic_repaired`**): glitch fades to 0, the
  halftone rebuilds and the panel lightens (`Frame`), line wobble calms to 1.0
  (`main.gd`), the hand withdraws, and frames with `border_gap` open a lit gap
  in the right border (`PageOverlay`). The exit to the Last Page needs the flag.
- **Light**: Chapter 1 rooms use fixed `LightSpot`s (candle, moon, glow). The
  flashlight cone texture is generated in code; `Flashlight.illuminates(_rect)`
  does cone tests for `revealed_by_light` objects and the light puzzles
  (`scripts/interactables/light_puzzle.gd` + `light_puzzle_art.gd`). Light
  still fills the notice meter, so every puzzle is light-vs-risk. Frames with
  `light_disabled` refuse the torch (`LightingSystem.light_blocked`). The
  player's red aura is always on (dims when concealed).
- **Cutscenes** (`autoload/cutscene_system.gd`, `ui/cutscene_view.gd`,
  `ui/cutscene_art.gd` (C3) + `cutscene_art2.gd` (C5, C6) + Stage 5's
  `cutscene_art3.gd` / `cutscene_art4.gd` (first person, `pov_*` ids) and
  `cutscene_detail.gd` (halftone/splatter on every panel, per-id props and
  secondary motion)). C1, C2 and C4 are POV: the scene is drawn under a
  `pov_look_up` / `pov_look` / `pov_sweep` / `pov_look_down` / `pov_shake`
  camera (breathing sway, slight roll), then `CutsceneArt3.overlay` draws
  the player's red hands, the empty bubble at the edge of view and a dark
  vignette fixed to the viewer. C2's dark room is lit only inside the cone
  (darkness is a fan polygon round it, no clipping). Totals: C1 4.76 s, C2
  4.93, C3 5.27, C4 5.27, C5 5.27, C6 7.14 = 32.64 s (unchanged). a page with 1-4 clipped panel
  Controls that ink in one by one, a typed narration box, a slow camera
  transform, an optional page turn. C1 first steal, C2 the torch
  (`resolved:flashlight`), C3 Mrs. Vane's flashback (`frame:ch2_pantry`),
  C4 descent (`frame:ch2_end`), C5 the Heart (`frame:ch3_ink_heart`), C6 the
  repair (`repaired`). `GameState.seen` (saved, v3) holds watched cutscenes
  **and** scares; Restart Chapter and deaths keep it, so nothing replays.
  `main._hand_off` waits for a cutscene before the next chapter's intro.
- **Page spread** (`scripts/frame/spread/`): `Frame.setup` adds a
  `SpreadController` first when `data.spread` is set. It clamps the player to
  their panel's floor (walk_area per panel), hops them across gutters
  (`SpreadHop`, a tweened arc + "WHOOSH"), drops them into the gutter through
  tears (respawn at the panel's entry, never a death), handles jumping (Space,
  `Player.lift` is drawing-only) and lighting. **Per-panel light, no
  SubViewports:** the frame's CanvasModulate keeps everything dark; each
  `SpreadPanelView`, prop and (while inside) the player carries its panel's
  light-mask bit; a soft square fill light per lit panel culls to that bit;
  the torch lights every bit. `SpreadFingers`: torch on 4 s → fingers peek
  through the gutter under the player (0.8 s telegraph) and stab (knock back).
- **Scares** (superseded by the Stage 4D/5 notes below) (`ui/jumpscare_overlay.gd`, FXLayer): `scare_clock` 0.6 s after
  the clock is read (0.35 s face + `scare_hit` + shake + one short red flash,
  then `InkCrawler.appear_at` 330 px behind the player + `wake_to`: run for the
  unbolted door or hide), `scare_margin` (the hand slams across the page with
  a nib stab). Once per run (`GameState.seen`), never with a menu, cutscene or
  page turn up. `intensity` = settings.cfg `[accessibility] scare_intensity`
  scales shake and flash (Stage 5 option). Emits `EventBus.scare`.
- **Monster look** (`crawler_view.gd`): after each move its strokes pen back in
  (`InkDraw.gap_ratio`) over faint pencil guides; the eyes follow the player
  even when dormant (`CrawlerArt.look`); the mouth tears wider within 380 px;
  twitches get more erratic when near; `CrawlerGlimpse` very rarely flashes a
  silhouette at the cone's edge (40 s cooldown). Audio: whispers when near,
  nib scratches with the skitter, and a 0.4 s held silence after the growl
  before a lunge (`AudioManager._on_telegraph`).
- **Music** (`autoload/music_manager.gd`, `scripts/audio/music_synth.gd`):
  menu (music box motif), ch1, ch2 (Shepard tone), ch3 (stutter), reveal
  (swell then silence), warm (motif in major: return phase + repair), ending;
  layers `layer_intensity` (notice/nearness) and `layer_hunt`. Loops are
  folded seamless. Renders in ~4 s on desktop at 4 ms/frame, menu first.
  Stingers: discover (new room), danger (`player_noticed`), relief (return),
  cutscene cues. Ducks for cutscenes and scares; drops out before lunges.
- **Intro / ending** (`ui/intro_cinematic.gd`, `ui/epilogue_sequence.gd`,
  shared `ui/comic_pages.gd`): comic pages of tilted, clipped panels looking
  into 1280x720 scenes, halftone tint, page turns. Intro (Stage 5, 18.5 s,
  `IntroArt` / `IntroArt2`, scene ids 0 room / 1 page close-up / 2 tunnel):
  0-4.4 a reader bent over the comic on a desk at night; 4.4-9.8 the page's
  ink lifts and reaches out, the room warps toward the page (panel frames
  and speed lines rush in, page lines curl), a finger touches the page and
  turns red; 9.8-13.6 inside the pull, the red reader dragged into the
  light; 13.6 SLAM (the book shut on the desk); 15.0 the white first panel
  inks in; 15.3 the recorded cry, raw and faint (`cry_intro`). Ending ~30 s
  (out through the border gap → the teen closes the book → the last panel,
  everyone whole, a faint red mark, "Some stories keep a little of whoever
  visits them.").
- **Notice meter** (`scripts/systems/notice_system.gd`): active only in frames
  with a Crawler *and* once the player has the flashlight. Light fills it in
  3 s; it drains in 5 s (3x faster when concealed, where light counts only
  25%). Full → `player_noticed`; empty → `player_lost`.
- **Ink Crawler** = brain `scripts/enemy/ink_crawler.gd` (states DORMANT,
  PATROL, STALKING, HUNTING, TELEGRAPH, LUNGE, SEARCHING, RETREATING) plus
  `CrawlerView` (stop-motion at 8 fps, eye glow, nearness signal) plus
  `CrawlerArt`. Contract: **light is the trigger, standing still in the dark is
  always safe, running (Shift) is loud, it only catches while HUNTING or in a
  LUNGE, and every lunge is telegraphed for 0.6 s** (freeze, growl, eyes flare
  red). `wake_to(hunting, scent)` is for scripted chases. Caught → the room
  reloads, words kept.
- **Ink Shadow** (`ink_shadow.gd` + `shadow_view.gd`) subclasses the Crawler
  (speed_scale 0.75, catch_radius 80, lunge_range 260, relentless). It draws a
  wall of ink behind it and every 7 s **scribbles out a hiding spot** (0.9 s
  visible scribble plus sound). **It freezes while scribbling and can't lunge for
  2.5 s after**, so a player pushed out of a hiding spot has a fair head start.
  That was added after a test showed being pushed out meant instant death.
- **Comic damage** = stolen words / **10** (all stealable words: 6 in Chapter 1,
  3 in Chapter 2, ERASE in Chapter 3), eased (`shown_damage`). `GameState.damage_visual()` scales it by
  the chapter. It drives the border wobble, red inner edge, cracks, ink bleed
  shader, characters drawn "unfinished" (`InkDraw.gap_ratio`), and in Chapter 3
  the glitch shader (`ui/glitch_overlay.gd`, strength = frame.glitch × (0.3 +
  0.7 × damage), zero once repaired). Returning words heals all of it.
- **Drawing**: everything uses `scripts/ink/ink_draw.gd` (jittered lines that
  re-roll every 140 ms, the "line boil"; `jitter_scale` per chapter;
  `gap_ratio` for unfinished lines; `fill()` survives self-intersecting
  polygons). Room art is in `scripts/frame/backgrounds/` (one file per chapter
  or room group).

- **Stage 4D systems.**
  - *Unlock feedback* (`scripts/systems/unlock_feedback.gd`, FXLayer):
    `Interactable.resolve` emits `EventBus.unlocked(data, pos)` for door,
    symbol_lock, lever, latch, secret_door, drawer, light kinds, pushable;
    doors/locks whose `requires_flag` comes true emit it too (their padlock
    drops: `Interactable.unbolt`, `InteractableArt.padlock`); gated exits
    emit `exit_unlocked`. One caption (InteractableData.unlock_caption or a
    default per kind; an opened way beats an unbolted door beats the object),
    a pop-up, a sound, a pulse ring, and "somewhere nearby" + an arrow when
    the thing is off the panel or in another spread panel.
    `GameState.set_flag` emits **`EventBus.flag_set`** the first time.
  - *Gated exits* (`ExitZone` + `ExitDoorArt`): an exit with required_flag
    whose opener is not an object at the exit draws its own door + padlock,
    swings open on the flag and stays open. Solved shadow puzzles / lenses
    carry a glow light so their marker shows in the dark.
  - *Dial locks*: `SymbolLockUI` pauses the world, needs TRY (Enter/Space/
    button), "?" on a wrong code, title = the lock's caption.
    `GrandfatherClock` (kind clock) owns the pendulum; marks are steady only
    while it is frozen or passing the middle; reading sets `clock_read`; the
    `clock_dials` symbol_lock sets `clock_solved` (the exit's flag).
  - *Inventory*: `InventorySlots` groups same-word bubbles into one slot
    (x2), picks the right owner's bubble on give-back, reorders
    (`move_slot`); `add_bubble` refuses an id already held. The strip shows
    a hover tooltip and the selected word's effect line; drag or Shift+Q/R
    reorders. `Hints.once(id, text)` = one-time hints (progress.cfg).
  - *Spread jump*: `SpreadJump` (buffer 0.12 s, coyote 0.12 s, 0.7 s / 90 px
    hop, Space or W/Up); tears drop only after the coyote grace.
  - *Noticed meter*: running steps within 430 px add 0.07 each
    (`NoticeSystem._on_footstep`); `EventBus.notice_sources` lights the
    torch / footprint icons (`NoticeIcons`); a quiet tick per 12%.
  - *Scares* (`ui/jumpscare_overlay.gd` + `ui/scare_art.gd`): a table of five (six since Stage 5, eight since 6b)
    (hallway lights-out face, gallery portrait, passage wardrobe, clock face
    + Crawler strike, spread hand slam), each triggered by a room flag, then
    waiting for a fair moment (no menu/cutscene/turn/dials, no Crawler
    stalking or hunting, not mid-hop, 60 s since the last); saved in
    `GameState.seen`; never in the return phase; F7 cycles them.
  - *Reveal* (`ui/reveal_sequence.gd` + `ui/reveal_beats.gd`): beats with
    reading-time durations (min 2.5 s): morph (the Shadow's silhouette, a
    `Ghost` child, dissolves into the hand), the 7 captions, the label card
    "THE MONSTER WAS THE ARTIST'S HAND.", the recap card.
  - *The Artist's tool*: `HandArt` draws ONE pencil (nib one end, eraser the
    other) inside the grip; `tool` &"pen" or &"eraser" picks which end is on
    the page; `pencil_lying` when set down.
  - *Music*: `return` (return phase), `erase` (heart_return; `hand_erase`
    boosts the tension layer), `warm` after the repair; `layer_pulse` added.
  - *UI*: `ControlsCard` (New Game waits for OK; the menu's Controls page uses
    its grid), `IntroSequence` = the chapter title card, `PageDoodles` on
    frames with `doodles`.

- **Stage 5 systems.**
  - *Door creak* (`SfxSynth2.door_creak(seed)`): stick-slip pulses at a
    gliding, wobbling rate through two wood resonances plus friction noise,
    ~0.75-0.95 s; three seeds built one per frame (`door_creak_0..2`),
    played by `UnlockFeedback` for door / exit / secret_door with pitch
    jitter. Padlocks (unbolt), dial boxes, latches and levers click.
    `UnlockFeedback.heard` logs [kind, sound] for tests. C4's stair played
    the old `creak` (Stage 6: replaced by `groan`).
  - *Music bed* (Stage 6: only when bg_track.wav is missing) (`MusicSynth2._bed`, 24 s loop): detuned partial pairs
    (55/55.17, 110/110.25 Hz...) beating every 4-6 s, a breathing tritone,
    three far glass tones with echoes. Plays at `BED_DB` -14 whenever the
    wanted track is ch1/ch2/ch3; follows every duck; drops at 140 dB/s and
    comes back at 40 dB/s (≤ ~2 s). Off for menu, reveal, return, erase,
    warm, ending.
  - *The recorded cry* (`scripts/audio/cry_bank.gd`): loads
    `res://audio/baby_cry.wav` (guarded by `ResourceLoader.exists`; falls
    back to `SfxSynth2.wail()` with a warning). Variants: raw; low (low-pass
    baked into the samples a chunk per frame, played at pitch 0.6, because
    web sample playback ignores bus effects); thin (cut at 62%). Used three
    times, each once per run via `GameState.seen`: `cry_intro` (end of the
    intro, raw, -17 dB), `cry_scare` (the cellar scare's build, low, fading
    in), `cry_reveal` (the reveal's erase beat, thin).
  - *Scares*: six. `scare_cellar` (ch2_cellar, flag `cellar_dials_set`,
    `build` 3.0 s, `patience` 90 s): `EventBus.scare_building(kind, s)`
    ducks music to near silence and hushes the drone; the cry grows; the
    panel darkens and the light (and the torch) flickers out
    (`ScareArt.lit/blackout`); then `cry_face` (a huge doubled, stretched,
    glitch-torn face), shake 1.0 x intensity, one red flash, `scare_low` +
    `scare_hit`, cry cut. A menu / cutscene / page turn mid-build calls it
    off and it retries; leaving the room drops it. No Crawler strike (the
    cellar chase starts on OPEN as before).
  - *Save*: no version bump; new ids (`scare_cellar`, `cry_*`) are just
    entries in `seen`.

- **Stage 6b systems.**
  - *Hints* (`Hints.once(id, text, s, urgent)` → `EventBus.hint_requested`):
    PageOverlay shows ONE at a time at the bottom right of the panel, above
    the room's captions, as "TIP: ...", held for max(its time, 1.5 s + 0.06 s
    a character, 3 s). Urgent ones (the light, the half-full meter, Shift)
    jump the queue and pre-empt a running tip. Toasts (`caption_requested`:
    inspect lines, unlock captions, pleas) stay top centre. The interact
    prompt floats over its object.
  - *Notice meter*: "NOTICED" label; pulses past 70%; while the Crawler
    hunts (HUNTING / TELEGRAPH / LUNGE) the blot turns jagged and bigger, reads
    "HUNTED!" and plays a nib snap (plus the existing danger sting).
  - *Controls*: `ControlsCard.open_in_game()` (F1 or H while playing, not in a
    cutscene / transition / modal) pauses and sets `modal_open`, closes with
    F1 / H, Esc or OK and restores what it found; it never emits `accepted`
    (New Game waits on that). The pause menu has a Controls page (Esc goes
    back to the pause menu). "F1 or H" hint once.
  - *Inventory arrows*: `InventoryArt.arrow_rect` hit areas; hover box and
    pointing cursor; a click scrolls the window one slot (selection kept).
    The selected-word line reads "E says ...", the strip "E says it".
  - *Cutscene timing* (`gen_cutscenes.py reading_time`): each beat lasts at
    least 0.3 s + max(2.5 s, 0.06 s a character) + 0.6 s hold (+0.5 s for
    a page turn). C1 6.80, C2 7.44, C3 8.72, C4 7.30, C5 7.44, C6 10.70 =
    48.40 s (was 32.64).
  - *Scares* (eight): `scare_closet` (ch1_bedchamber; `closet_scare` event:
    4 s after entering the wardrobe creaks open a crack; 2.5 s later walking
    within 190 px sets `closet_near`; the doors burst on a stretched pale face
    (`ScareArt2.closet`), sting `shriek` (1250 Hz, tonal), shake 0.85, one red
    flash; then they swing shut). `scare_escape` (ch3_gallery_words, flag
    `spread_pool`: the ink pool cleared): `ScareArt2.panel_escape`, 1.3 s, a
    comic page where one figure stepped out of its panel, "Not the page.
    You.", `shriek_low`, shake 0.8, no flash. Any scare entry with art
    &"escape" and `figure` / `caption` / `panel` reuses it (data only).
    Entries may set `sound`, `shake`, `flash`.
  - *Music levels* (+9 dB): MusicManager BASE_DB -10 → -4, SAFE_DB -20 →
    -14, BED_DB -14 → -8, SAD_DB -19 → -13; MusicFiles BG_DB -17 → -11,
    ENDING_DB -6 → 0; stingers fixed at STING_DB -8 (unchanged); slider
    default 0.6 → 0.85, and a settings.cfg without `music_level` 2 is moved
    to the new default once. Ducks: cutscene / scare / lunge warning -6 dB
    (0.5), the scare's for 0.8 s; only the cellar build and the reveal's
    silent beat (duck >= 0.9) still drop bg_track out. The SFX dip never
    stacks on a duck.

- **Stage 6 systems.**
  - *C1, third person* (`ui/cutscene_art5.gd`, ids `c1_steal`, `c1_tear`,
    `c1_thin`, `c1_alone`; WIDE_L pages, cameras zoom_in / shake): the red
    unperson reaches out, a red thread pulls Arthur's OPEN off ("RRIP!"),
    the close-up of the bubble peeling off its tail like a scab; then the
    page shudders, the ink thins and the pencil underdrawing shows, the red
    figure alone with the torn word and a hairline crack. Same 4.76 s, same
    trigger. C2 and C4 keep the first-person hands (CutsceneArt3/4).
  - *Reveal text*: beats morph, artist ("This comic has an author."),
    monster ("The monster was never a monster."), hand ("It was, in fact, the
    author's hand." + label card "THE AUTHOR'S HAND."), erase ("To the author,
    you were the anomaly. A glitch. A mistake.", the thin cry), stole ("You
    starved the characters of their words, and broke the story.": the robbed
    owners, then the page tears at 45%), you ("You were the monster.", 6.5 s:
    `MusicManager.duck(0.97)` + `AudioManager.hush`, the hand stills over the
    page eraser-down, the page darkens round the red figure), recap ("The
    monster was the author's hand." / "I was the glitch it was erasing." /
    "My theft broke the story."). ~37.5 s + fade. Player-facing text says
    **author** everywhere (epilogue caption, "Author's note" in Ch3 rooms);
    ids and class names keep "artist".
  - *The hand's eraser*: `HandArt._pencil` eraser-down draws a short pencil
    in the fist and a big eraser block past the fingertips (no nib showing);
    `tool_tip(&"eraser")` = DIR x 0.94. `ArtistHand` draws `&"eraser"` in
    every state (OFFER only half-opens the grip; the lying pencil is gone).
    `HandFloorArt` adds the eraser block's own shadow inside the strip.
  - *Sounds* (`scripts/audio/sfx_synth3.gd`): `groan` (C4's stair): 180 →
    245 Hz rising detuned partials (1.0071 detune), widening vibrato, a ghost
    harmonic at x7.02 fading in, a reversed swell into a 0.21 s echo, a breathy
    high-passed whisper; 1.9 s, peak -2.5 dBFS (RMS -19), played at -5 dB with
    5% pitch jitter; built in 4 chunks. `growl` (every danger telegraph): 160
    → 196 Hz detuned partials + a fifth-ish partial (x1.414), 7.5 Hz vibrato,
    high-passed rasp; 0.75 s, peak -6 dBFS. `moan` (the mirror): 262 → 233 Hz
    breathy "oo", 1.7 s at 11025 Hz, peak 0.45. The old `creak` and `growl`
    (SfxSynth) are deleted: 57% / 66% of their energy was under 150 Hz.
  - *bg_track / ending* (`scripts/audio/music_files.gd`, MusicManager's
    child): loaded on start-up frames 8 and 16 (never the click). bg_track:
    `BG_DB` -17, two players crossfading 2 s at the loop (the file starts with
    0.21 s of silence and ends with a step), dips 3 dB for 0.5 s under any
    sound played at -8 dB or louder (`EventBus.sfx_played`), drops at
    160 dB/s for ducks >= 0.6 (cutscene, scare, scare build, lunge telegraph)
    and returns at 40 dB/s; off (and stopped after 3 s) outside Ch1-3 rooms.
    MusicManager skips rendering ch1/ch2/ch3/bed when the file exists.
    ending.wav: `play_ending()` on the epilogue frame, 1 s after the previous
    track starts fading, `ENDING_DB` -6, a 0.15 s fade at its end, once per
    run; then the synthesized ending at BASE_DB - 6. `stop_all()` on Back to
    Menu. Import is the default (QOA): 3.6 MB + 0.23 MB in the pack.
  - *Menu melancholy* (`MusicSynth3`, `menu_sad`, 40 s loop): A minor music
    box (11 notes in 3 phrases, a detuned ghost voice, two 0.42 s echoes, a
    3.5 s decay), sine pads under phrase ends, ~3-4 s of silence between
    phrases; notes rendered twice (also one loop earlier) so tails wrap.
  - *Credits* (`ui/credits_art.gd`): one comic page, B&W, used by the menu's
    Credits page and the End Card (THE END heads it). Esc / Back work on both.
  - *Mirror ghoul* (`scripts/events/mirror_ghoul_event.gd`, event
    `mirror_ghoul` in ch1_awakening): `Interactable.interact_plain` emits
    `EventBus.inspected(id)` for inspect objects; on "mirror" a pale
    faceless figure leans out of the glass, slumps and sinks (2.8 s first, then
    1.4 s, `GameState.seen` `mirror_ghoul`), a soft `moan`, a small light.
    Never blocks input.
  - *Room decor* (`scripts/frame/room_decor.gd`; FrameData `webs`
    (Array[Vector4] x, y, size, angle°) and `corner_eyes` (Array[Vector3] x,
    y, pairs); placed in `tools/datagen/gen_decor.py`, merged by gen_lib):
    webs sway at the boil rate, the odd spider; eyes blink rarely and track
    the player slowly, one small light per cluster, one cluster per room.
  - *Cutscene fill* (`ui/cutscene_fill.gd`): spirals in free corners, rings,
    drops, eyes, nibs, hatch swirls, Ben-Day fields and doodles, stepped at
    the boil rate, kept off each id's subject (`focus_of`), faint corner
    spirals only on dark panels. `CutsceneDetail.texture`'s ~900 halftone
    dots are now one cached triangle array per panel.
  - *Title / menu* (`ui/title_art.gd` SubViewport + `crow_shapes.gd` +
    `title_live.gd` + `title_lettering.gd`): nine crows in clipped
    cross-hatching (`Geometry2D.intersect_polyline_with_polygon`) inked into a
    texture a few shapes per frame from start-up (`frame_post_draw` gates each
    batch; the target clears once, then never), then a live layer (looping
    spiral, eye blinks, feather shiver, the red figure). The lettering is a
    polyline stroke font (lowercase + T, S, H) built into one triangle array
    per boil tick.
  - *Intro*: `IntroArt2._falling` is an abstract red streak (blot head,
    torso ribbon, limbs dissolving into dashes, fragments peeling off).

### Split precedents (for the 250-line rule)
`InventoryArt` (strip drawing), `InteractableArt` / `InteractableArt2`, the
`HidingSpot` / `ReturnSpot` subclasses chosen by `Frame.KIND_CLASSES`, the
Crawler brain/view split, `NpcArt`, `BubbleArt`, `SymbolArt`, `StateSnapshot`
(GameState serialisation), `HandArt` / `HandFloorArt`, `RevealArt`,
`RealWorldArt` (intro + epilogue), `BgCh3End`, `CutsceneArt`/`CutsceneArt2`,
`SfxSynth2`, `LightPuzzle`/`LightPuzzleArt`, `SpreadController`/`SpreadArt`/
`SpreadPanelView`/`SpreadFingers`, `RevealArtTear`, `ComicPages`, `RevealBeats`,
`ScareArt`, `MusicRenderer`/`MusicSynth2`, `GrandfatherClock`, `InventorySlots`,
`ExitDoorArt`, `NoticeIcons`, `PageDoodles`, `SpreadJump`, `IntroArt`/`IntroArt2`,
`CutsceneArt3`/`CutsceneArt4`, `CutsceneDetail`, `CryBank`, (Stage 6)
`CutsceneArt5`, `CutsceneFill`, `MusicFiles`, `MusicLayers` (split out of
MusicManager), `MusicSynth3`, `SfxSynth3`, `CreditsArt`, `RoomDecor`,
`TitleArt`/`CrowShapes`/`TitleLive`/`TitleLettering`, (6b) `ScareArt2`,
the closet event.

## 7. Content, chapter by chapter

**Chapter 1, The Rotted Bedchamber** (`ch1_*`): awakening (mirror) →
bedchamber (locked drawer holding HUSH, the Crawler's silhouette at the window,
Arthur far away) → landing (Arthur: **OPEN, PUSH**, WAIT, HELP; study door
needs OPEN) → study corridor (portrait gives **REMEMBER**; the ink-hand moment)
→ study (PUSH the cabinet; REMEMBER shows the sketch **eye, moon, key** with
an arrow to the dial door; only the dials (TRY) set `study_lock_open`) →
back stair (flashlight pickup sets `has_flashlight`) → `ch1_end` hands off to
Chapter 2.

**Chapter 2, The Hallway of Shadows** (`ch2_*`), four light puzzles: long
hallway (safe tutorial: light-revealed writing; hold the light on the
`light_ink` door over the exit) → gallery (Crawler dormant by the handle-less
door; sweep for the light-revealed `lever`, then sneak past) → servants'
passage (scripted stalker; hide; then burn back the `light_ink` growth over
the exit, which regrows in the dark) → pantry (C3 flashback; Mrs. Vane:
**HIDE, HUSH, WAIT**; the pantry-fingers scare on the first theft) → clock
room (patrolling Crawler; light the clock face (WAIT on the pendulum holds
the marks still) → the **major jumpscare**: the Crawler appears behind you and
hunts → the dial box beside the clock: **hand, spiral, house**, read from XII
clockwise as the hallway wall says; it unbolts the exit) → cellar stair
(`shadow_puzzle`: stand on the chalk X, light the iron key until its shadow
fits the keyhole; a moment later the Stage 5 cellar scare; then OPEN, then a
short chase) → `ch2_end` (C4) hands off
to Chapter 3. Only OPEN and the flashlight are required here.

**Chapter 3, The Ink Heart** (`ch3_*`). *Before the reveal:* gallery of words
= **the page spread** (4 panels; Vane and the Portrait plead without bubbles;
light puzzles: lens → shows C's lever, ink pool → drop to D, torchlit pencil
plank over C's gutter tear; PUSH the crate into the tear as a bridge; lever +
**OPEN** at D's door) → margin (minor scare: the hand slams across the page;
Ink Shadow chase) → **ink heart** (C5; light disabled; move between the
Shadow's listens, steal **ERASE** → reveal). *After the reveal:* returning
room (everyone at once: Arthur, Mrs. Vane, the Portrait, the drawer;
`return_gate` sets `all_returned` and opens the way when every owner is
whole; the hand at full strength; curtain on the far left) → heart return
(the hand WATCHes; give ERASE back → C6 repair, lit gap in the border) → **the
Last Page** → `ch3_outside` (ending pages, THE END, credits). Minimum words
for the whole game: OPEN, PUSH, REMEMBER (+ ERASE); every other word is
optional.

**Stage 4C timing** (estimates for a first-time player, not measured): before
the cuts ≈16:40; with the new content (≈50 s cutscenes, +13 s reveal, the
spread, light puzzles, longer intro/ending) and the cuts ≈15:45 (after the
Ch1 study dial lock was also cut, with the user's OK). The
cuts: Ch1 intro captions dropped, Ch2/Ch3 chapter lines shortened, Torn Page
removed (its pleading is in the spread), the Gallery's third dial lock
replaced by the spread, the return phase batched into one room (no Torn
Page / Gallery revisits), the cellar's second dial lock + REMEMBER replaced
by the shadow puzzle.

## 8. Open issues and next steps

0. **Stage 6**: `bg_track.wav` is 18.9 MB (stereo 48 kHz, 98.6 s): convert it
   to OGG (the user's call). Not heard by the agent: the new groan / growl /
   moan, the menu layer, bg_track's levels and dips. Not checked in a real
   browser: the title SubViewport build, frame pacing. C2 and C4 still use
   first-person hands (the user is deciding).

1. Stage 5 is complete; nothing is stubbed. Runtime ≈ 15½-16 min (4D's
   estimate minus 6.5 s of intro; cutscenes unchanged at 32.64 s).
2. Not verified in a real browser: frame pacing (the in-app browser pane was
   hidden, which throttles it to 1 fps) and how the cry / creak / bed sound
   (audio can't be heard by the agent). Desktop numbers: intro worst frame
   24 ms (page 1's first frame; page 2 ~20 ms, the rest < 10 ms), cutscenes
   31 ms on C1's first frame, otherwise ≤ 13 ms.
3. `ch3_systems` prints `E2 WAIT froze hand=false` (also at d1e2764, before
   Stage 5): WAIT near the Returning Room's hand freezes something else
   first. Check WaitAbility's target order vs. the test.
4. `ink_crawler.gd` is 261 lines (unchanged since 4C); `music_manager.gd`
   is at 250. Split the Crawler's senses / MusicManager's settings next time.
5. Credits say "the Berry Jam team" (placeholder); real names go in
   `ui/credits_art.gd` (`TEAM`). "Voice: the team" and the "Code, art..." line
   were removed in Stage 6.
6. The user should delete `ink-bleed-(4.3)/` (deleting it from here was blocked).

## 9. Hard-won gotchas (read before touching these areas)

- **A Callable to a RefCounted's method does not keep it alive**: store the
  object itself (AudioManager `_pending` holds `SfxSynth3.Groan`, not
  `.next`), or it is freed and the call hits null.
- **SubViewports and hidden test windows:** TitleArt builds only on frames
  that are actually drawn; tests force draws (`ui_check` does) or the
  backdrop stays half-inked.
- **WAV import (4.7.2):** the importer refuses WAVE_FORMAT_EXTENSIBLE
  headers ("not PCM"). The team's `baby_cry.wav` arrived that way; its
  header was rewritten as plain PCM (samples byte-identical). Keep its
  `.import` at `compress/mode=0`: the 4.x default (QOA) would hand CryBank
  compressed bytes it can't filter.
- **Web audio is sample playback:** bus effects (AudioEffectLowPassFilter
  etc.) are skipped on the web, so filters are baked into samples (CryBank).

- **Godot 4.7.2 web export bug #1:** with
  `convert_text_resources_to_binary=true`, every **PackedStringArray in `.tres`**
  exports empty (captions, lines, lock answers; the lock becomes unsolvable).
  Keep it false.
- **Export bug #2:** a typed constant of packed arrays
  (`const X: Array[PackedStringArray] = [[...]]`) reads back empty in the
  exported game and crashed the web build ("memory access out of bounds"). Use
  plain text split at runtime (see `CONTROLS_TEXT` in `ui/main_menu.gd`).
  Single-level consts (`PackedStringArray`, `Array[StringName]`) were verified
  fine.
- In 4.7, a **freed object compares equal to `null`**, so guard with
  `is_instance_valid(x)`, never `x != null`.
- **Menus:** each page's full-screen wrapper must be hidden as a whole, and
  wrappers use `MOUSE_FILTER_IGNORE`. An invisible page on top once swallowed
  every click while the keyboard still worked.
- `CanvasModulate` dims everything in the world layer, so "glowing" things
  (Crawler eyes, memory sketches, return spots) carry a tiny `PointLight2D`.
  Compatibility mode lights each object with about 8 lights at most.
- The glitch shader uses `hint_screen_texture`. It is verified on WebGL2 in a
  real browser. Keep its colours greyscale (inverting red makes cyan).
- **Exits:** an exit that unlocks while the player stands in it waits 1.5 s
  (`ExitZone` watches the flag change) so the door is seen opening. A spawn
  must never sit inside an exit or inside an enemy's lunge range (the Margin
  spawn moved to x 320 for that reason).
- **Bubbles beat objects for E.** A hiding spot or return spot whose interact
  point is within 120 px (along the floor) of a bubble that is stealable or
  returnable can't be used while that bubble is: keep hiding spots clear of
  characters' bubbles (two return-phase curtains were moved for this).
- **Holding ERASE without `twist_revealed` plays the reveal** (it pauses the
  tree). Anything that builds state by hand (debug jumps, tests) must set
  `twist_revealed` *before* adding the word.
- The reveal pauses the tree; it and the screens around it use
  `PROCESS_MODE_ALWAYS`. Timers that must run while paused need
  `create_timer(t, true)`.
- **`settings.cfg` is shared** by AudioManager, MusicManager and (read-only)
  JumpscareOverlay: every save must `load()` the file first, then set its own
  keys, or it wipes the others' (AudioManager used to overwrite it).
- **Nothing heavy on the first click:** browsers need that click before
  audio, and everything built then stalls the frame. Music renders a chunk
  per frame (`MusicRenderer`), and newer sounds and stingers are built one
  per frame after it (`AudioManager._pending`, `MusicManager._stinger_jobs`).
  A 130 ms stall here made `menu_clicks` miss the Controls button.
- **Cutscenes pause the tree** like the reveal; `CutsceneSystem` and its view
  are `PROCESS_MODE_ALWAYS`. Anything that hands off between chapters must
  wait for `CutsceneSystem.is_playing` to clear.
- Red is reserved: the player, the steal ring, the selected slot, the prompt
  key, SNATCH!/SPLAT!, the steal splash, cracks, the damage edge, the notice
  blot, hunting eyes, the danger vignette (edges only, capped). Anything else
  stays black and white.
