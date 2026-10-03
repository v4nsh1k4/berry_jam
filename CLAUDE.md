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
glitch). **Twist (Stage 4B, not built yet):** the Crawler and the Ink Shadow are
secretly the **Comic Artist's hand** (long jointed fingers with pen-nib tips),
the player is an anomaly rather than a victim, and the way out is **giving every
word back**.

Jam theme: COMIC / LIGHT / TWIST. Target: desktop browser on itch.io (HTML5 zip).

## 2. The user and how to work with them

- The user is new to Godot and on a **Mac**. Explain how to run and test in
  plain steps. In the Godot editor: ▶ (top right), **⌘B**, or fn+F5. The editor
  canvas looks empty because everything is drawn by code at runtime.
- Godot binary on this machine: `/Users/vanshikar/Downloads/Godot.app/Contents/MacOS/Godot`
  (4.7.2). Export templates for 4.7.2 are installed.
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
  default font only.
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
| **4B (next)** | Chapter 3 climax: Artist's-hand reveal, the final word, intro animation, ending, epilogue |

Git history on `ink-bleed`: commit 1 = Chapters 1-2, commit 2 = Stage 4A.
A Claude Docs page "Ink-Bleed: Game Flow & Architecture" was written after
Stage 2. It does **not** cover Stages 3-4A; this file is the up-to-date source.

## 5. How to run, test and export

```
cd game_jam
GODOT=/Users/vanshikar/Downloads/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --import            # re-import after adding files (catches parse errors)
$GODOT --path .                                 # play
$GODOT --headless --path . res://tests/inventory_test.tscn                       # prints INVENTORY TEST PASSED
SHOT_DIR=/some/dir $GODOT --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_play.gd
$GODOT --headless --path . --export-release "Web" build/web/index.html           # web export
$GODOT --main-pack build/web/index.pck --resolution 1280x720 --script res://tests/playthroughs/ch2_play.gd
```

- `tests/playthroughs/*.gd` are SceneTree scripts that drive the real game:
  `ch1_play`, `ch1_flows` (drawer, continue, restart), `ch2_play`, `ch2_caught`
  (telegraph, catch, restart), `save_check`, `ch3_play`, `ch3_margin` (Shadow
  chase), `ch3_minimal` (nothing optional stolen), `menu_clicks`, `exit_grace`.
  They print a log and save screenshots to `$SHOT_DIR`. Read the screenshots,
  because visual bugs (cyan glitch blocks, a pink vignette flood) only showed
  up there.
- **Always run the playthroughs against the exported pack too** (`--main-pack`).
  It runs the same compiled scripts as the web build, and two export-only bugs
  were caught only this way (§9).
- Debug builds only: **jump to any room**. On the web add `?frame=ch3_margin`;
  on desktop run with `-- --frame=ch3_margin`. `scripts/systems/debug_jump.gd`
  adds the words a player would carry into that chapter.
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
| `EventBus` | ~45 signals, no logic. Each signal has `@warning_ignore("unused_signal")` (per line, for 4.3 compatibility) |
| `AudioManager` | Builds every sound on the first click (`SfxSynth`), SFX voices, drone, Crawler dread (heartbeat speeding with notice, rumble, skitter, growl), volume and mute in `user://settings.cfg` |
| `ShakeManager` | Trauma shake (trauma squared, decays) on the viewport canvas transform; also holds the frame's **base tilt** (`FrameData.panel_tilt`, rotated about the panel centre) |
| `GameState` | `inventory` (uncapped, single source of truth), `selected_index`, `flags`, `stolen_bubble_ids`, `returned_bubble_ids`, `stolen_bubble_count`, `comic_damage`, `current_chapter`, `chapter_start` snapshot, `is_playing`, `modal_open`; save/restore (`to_dict` / `from_dict`) |
| `LightingSystem` | Flashlight on/off (F / left click), only with flag `has_flashlight` |
| `FrameManager` | Loads `data/frames/<id>.tres`, builds the `Frame`, places the player, exits, reload on `player_caught` |
| `TransitionManager` | SLIDE (page sheet) and INK_SPLASH (shader) wipes around a swap |
| `AbilityRegistry` | ability id → `AbilityData` + handler instance, `speak()`, cooldowns (`ABILITY_PATHS` list) |

### Scene tree (`scenes/main.tscn`) and canvas layers
World (layer 0: the `Frame` under `World/FrameRoot`, plus `World/Player`; the
Frame's `CanvasModulate` darkens only this layer) → PageLayer 10 (follows
the viewport so it shakes and tilts with the world: `GlitchOverlay`,
`InkBleed`, `PageOverlay` = white gutter, border, cracks, captions) → HUDLayer
20 (`InventoryStrip`, `NoticeMeter`, `InteractPrompt`) → FXLayer 25
(`DangerVignette`, `FeedbackFx`) → LockLayer 40 → TransitionManager 50 →
MenuLayer 60 (Intro, EndCard, MainMenu, PauseMenu) → StartLayer 100. The panel
is the fixed `Frame.PANEL_RECT` = (48, 32, 1184×528) on a 1280×720 page. All
room data is in **panel coordinates**. The floor is y ≈ 380 and feet walk in
y 400-504.

### Flow (`scripts/main.gd`)
Title (click or key; browsers need that gesture before audio) → menu → chapter
intro (`ChapterData.intro_lines`) → `_start_chapter` (sets `current_chapter`,
takes the `chapter_start` snapshot, applies `line_jitter`) → frames → a frame
with **`next_chapter`** hands off after 1.5 s to the next chapter's intro → ... →
a frame with **`ending_card`** shows the end card → menu. **Restart Chapter**
restores `chapter_start`: words carried in stay, this chapter's thefts and
returns are undone. **Autosave** (`user://ink_bleed_save.json`, IndexedDB on
the web) happens on every frame change, theft, solved object and quit to menu.

### Data model (`scripts/data/`, files in `data/`)
- `FrameData`: id, display_name, ambient_light, background_style,
  player_spawn, walk_area, captions, exits (`ExitData`), interactables
  (`InteractableData`), npcs (`NpcData`), crawler_spawn, crawler_patrol,
  crawler_kind (`&"crawler"` or `&"shadow"`), lights (`LightSpotData`), events
  (ids in `Frame.EVENT_SCRIPTS`), hint (for HELP), ending_card, next_chapter,
  glitch, panel_tilt, sketch.
- `BubbleData`: id, text, ability_id, stolen_from (an owner id: `arthur`,
  `mrs_vane`, `portrait_lady`, `drawer`), consumable (always false so words are
  never used up and nothing soft-locks). **Each word is its own file named
  `<id>.tres`**, because saves store the paths and fall back to
  `data/bubbles/<id>.tres`.
- `NpcData`: bubbles plus `lines` (with `{word}`), `broken_lines`,
  `reactions` (when robbed), `relief_lines` (when given back),
  `words_stealable` (false in Chapter 3), `visual_style` (`butler`, `portrait`,
  `housekeeper`), bubble_offsets, scale, reach_y.
- `InteractableData.kind`: word targets `door`, `drawer` (`reward_bubble`),
  `latch`, `pushable`. Plain E: `inspect`, `pickup`, `symbol_lock` (text
  `"panel"` = wall box), `hiding_spot` (text: wardrobe, curtain or table).
  Passive: `memory` (REMEMBER), `writing`, `clock`, `secret_door` (opens when
  `requires_flag` is set). Chapter 3: `return_spot` (`owner_id`; text painting
  or drawer). Plus `revealed_by_light` (only visible and usable inside the
  flashlight cone).
- `ChapterData`: title, intro_lines, first_frame_id, damage_visual_scale,
  line_jitter, allows_return.
- `AbilityData`: id, display_name, description, icon_word, target_type
  (INTERACTABLE / ROOM), cooldown, duration, handler script.

**Data generators:** `tools/datagen/gen_lib.py` plus `gen_ch1.py`, `gen_ch2.py`,
`gen_ch3.py` write whole chapters. Run them from `game_jam/`
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
- **Return mechanic (Stage 4A)**: `GameState.return_bubble(bubble, pos)` removes
  the word, updates stolen/returned ids, count and damage, and emits
  **`EventBus.bubble_returned`** plus `comic_damage_changed`. Give a word back by
  holding E 0.7 s under the owner's **broken** bubble (group `returnable`), or
  press E at a `ReturnSpot` (painting or drawer). Only allowed when
  `current_chapter.allows_return` (Chapter 3). **Why:** a returned word is gone
  for good, so returning OPEN in Chapter 1 would soft-lock the doors. Returned
  bubbles show their full line and are never stealable again. Owners who were
  never robbed are whole from the start, so they never block progress.
- **Light**: Chapter 1 rooms use fixed `LightSpot`s (candle, moon, glow). The
  flashlight cone texture is generated in code; `Flashlight.illuminates(_rect)`
  does cone tests for `revealed_by_light` objects. The player's red aura is
  always on (dims when concealed).
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
- **Comic damage** = stolen words / **9** (all stealable words: 6 in Chapter 1,
  3 in Chapter 2; Chapter 3 has none). `GameState.damage_visual()` scales it by
  the chapter. It drives the border wobble, red inner edge, cracks, ink bleed
  shader, characters drawn "unfinished" (`InkDraw.gap_ratio`), and in Chapter 3
  the glitch shader (`ui/glitch_overlay.gd`, strength = frame.glitch × (0.3 +
  0.7 × damage)). Returning words heals all of it.
- **Drawing**: everything uses `scripts/ink/ink_draw.gd` (jittered lines that
  re-roll every 140 ms, the "line boil"; `jitter_scale` per chapter;
  `gap_ratio` for unfinished lines; `fill()` survives self-intersecting
  polygons). Room art is in `scripts/frame/backgrounds/` (one file per chapter
  or room group).

### Split precedents (for the 250-line rule)
`InventoryArt` (strip drawing), `InteractableArt` / `InteractableArt2`, the
`HidingSpot` / `ReturnSpot` subclasses chosen by `Frame.KIND_CLASSES`, the
Crawler brain/view split, `NpcArt`, `BubbleArt`, `SymbolArt`.

## 7. Content, chapter by chapter

**Chapter 1, The Rotted Bedchamber** (`ch1_*`): awakening (mirror) →
bedchamber (locked drawer holding HUSH, the Crawler's silhouette at the window,
Arthur far away) → landing (Arthur: **OPEN, PUSH**, WAIT, HELP; study door
needs OPEN) → study corridor (portrait gives **REMEMBER**; the ink-hand moment)
→ study (PUSH the cabinet, REMEMBER shows **eye, moon, key**, dial lock) →
back stair (flashlight pickup sets `has_flashlight`) → `ch1_end` hands off to
Chapter 2.

**Chapter 2, The Hallway of Shadows** (`ch2_*`): long hallway (safe;
light-revealed writing and a hidden latch, OPEN) → gallery (Crawler dormant;
learn that light is risk) → servants' passage (scripted stalker; hide in a
wardrobe, curtain or table) → pantry (Mrs. Vane: **HIDE, HUSH, WAIT**; the
pantry-fingers scare on the first theft) → clock room (patrolling Crawler;
light the clock face to read **spiral, hand, house**) → cellar stair (dials,
then OPEN, then a short chase) → `ch2_end` hands off to Chapter 3. Only OPEN,
REMEMBER and the flashlight are required.

**Chapter 3, The Ink Heart** (`ch3_*`, frames 1-4 only): torn page (Mrs. Vane
and the Portrait plead for exactly the stolen words) → returning room (safe;
Arthur, plus the drawer for HUSH) → gallery of words (three `ReturnSpot`
portraits; the `gallery_gate` event opens the wall when all are whole) → margin
(Ink Shadow chase) → `ch3_heart_card` placeholder "THE INK HEART: COMING NEXT".
Glitch per frame: 0.35 / 0.12 / 0.5 / 0.75.

## 8. Open issues and next steps

1. **UX note (resolved, but worth improving):** the user first thought words
   could only be given back at the Gallery portraits, not to the characters
   themselves (both work). Make it clearer: e.g. name the owner in the prompt
   and tooltip ("give back to Arthur"), and have the Torn Page / Returning Room
   captions say you can give words straight to the person.
2. **Stage 4B** (not started): Chapter 3 climax, Artist's-hand reveal, final
   word, intro animation, ending, epilogue. Hooks: `TODO(later)` in
   `GameState.return_bubble`, `InkShadow`, `ink_hand_event.gd`, `crawler_art.gd`,
   `AbilityRegistry._ready`. If 4B adds stealable words, raise
   `GameState.DAMAGE_FOR_FULL_EFFECT`.
3. **Not built:** "erasing platforms" (the game has no jumping, so the Shadow
   erases hiding spots instead), the full intro cinematic, and screen distortion
   near the Crawler (that is border warp plus shake, not a screen shader).
4. Credits say "the Berry Jam team"; real names go in `ui/main_menu.gd`.
5. The user should delete `ink-bleed-(4.3)/` (deleting it from here was blocked).

## 9. Hard-won gotchas (read before touching these areas)

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
- Red is reserved: the player, the steal ring, the selected slot, the prompt
  key, SNATCH!/SPLAT!, the steal splash, cracks, the damage edge, the notice
  blot, hunting eyes, the danger vignette (edges only, capped). Anything else
  stays black and white.
