# Ink-Bleed

A 2D psychological horror puzzle game set inside a comic book, *The Silent
House of Hollow Hill*. You are an unperson with no speech bubble, drawn in the
only colour in the comic: red. You steal other characters' words and speak
them to open, move, remember, freeze and hide. Light shows you the house, and
it shows you to the Ink Crawler. Every stolen word damages the comic a little
more, and in Chapter 3 the way out is to give them all back.

Made in Godot 4.7.2 with GDScript and the Compatibility renderer. All art and
sound are generated in code: there are no asset files and no addons.

## Run

1. Open Godot, choose **Import**, and select `game_jam/project.godot`.
2. Press **▶** (or ⌘B on a Mac, F5 elsewhere). Click the title page or press
   any key, then choose **Start**.

| Action | Keys |
| --- | --- |
| Walk / run | A/D or ←/→, hold **Shift** to run (loud: the Crawler hears running) |
| Step nearer / further | W/S or ↑/↓ |
| Steal a word | Stand under it and hold **E** (step left/right to choose between words) |
| Pick a stolen word | **1-6** for a visible slot, **Q / R** or the mouse wheel to cycle, or click a slot |
| Say the word | **E** at the thing in front of you, or with nothing near to say it into the room |
| Look / take / hide / dials | **E** on mirrors, pickups, hiding spots and dial locks |
| Give a word back (Chapter 3) | Pick it, stand under its owner's broken bubble and hold **E** (or press **E** at their portrait) |
| Flashlight | **F** or left click, aimed with the mouse (from the end of Chapter 1) |
| Jump | **Space**, only on the page-spread page in Chapter 3 |
| Skip a cutscene | **Space** or click (each cutscene plays once per run) |
| Pause | **Esc** or **P** |

Menus work with the mouse or the keyboard (arrows + Enter; Esc goes back).

## Walkthroughs

### Chapter 1: The Rotted Bedchamber

1. **Awakening.** Optionally press E at the mirror, then walk right.
2. **The Rotted Bedchamber.** The drawer is locked, and the Crawler rises in
   the window. Walk right.
3. **The Landing.** Stand under **OPEN** and **PUSH** (and optionally HELP or
   WAIT) and hold E. Pick OPEN, then press E at the study door.
4. **The Study Corridor.** The ink hand passes. Steal **REMEMBER** from the
   portrait.
5. **The Study.** PUSH the cabinet, then say REMEMBER: the marks **eye,
   moon, key** glow, and the carved door opens for whoever remembers.
6. **The Back Stair.** Take the flashlight, then go through the right-hand
   door. Chapter 2's intro follows.

Optional: OPEN the bedchamber drawer to get **HUSH**.

### Chapter 2: The Hallway of Shadows

Light puzzles: every one fills the noticed meter where the Crawler is, so use
the light in short bursts.

1. **The Long Hallway** (safe). Turn the light on. Writing appears on the
   wall. Hold the light on the **ink over the far door** until it shrinks
   away.
2. **The Portrait Gallery.** The Crawler sleeps by the far door, and the door
   has no handle. **Sweep the light along the walls** to find a lever, and
   pull it with E while it is lit. Then turn the light off and walk (don't
   run) past the sleeper. If it wakes, stand still in the dark until it sinks.
3. **The Servants' Passage.** After a growl and a warning, the Crawler rises
   behind you. Press E at the wardrobe, curtain or table to hide. When it has
   gone, **burn back the ink growth** over the far door with a long look of
   light (it creeps back in the dark).
4. **The Housekeeper's Pantry.** Mrs. Vane's flashback cutscene plays. Steal
   **HIDE, HUSH and WAIT** from her (optional).
5. **The Clock Room.** The Crawler patrols, and the far door is bolted. Say
   **HUSH** (or WAIT once it's up), then light the clock face for a second.
   The clock strikes, the bolt slides back, and *something happens*: run for
   the door or hide behind the curtain.
6. **The Locked Cellar Stair.** A **shadow puzzle**: stand on the glowing
   chalk X and light the iron key on its stand until its shadow fits the
   keyhole outline on the wall. Then say **OPEN** at the padlock and run.
7. **The Cellar.** A cutscene leads into Chapter 3.

**Minimum:** OPEN, REMEMBER (Chapter 1's study) and the flashlight. HUSH and
WAIT only make the Clock Room easier: you can wait for the patrol to turn
away, light the clock, then hide.

### Chapter 3: The Ink Heart

Every frame is more broken than the last. Giving words back calms it all.

1. **The Gallery of Words: a page spread.** The whole screen is a comic page
   of four small panels. Walk off a panel's edge to hop across the gutter;
   **Space** jumps. The white gutter is nothing: fall in and you are spat
   back where you entered that panel. Leaving the torch on too long makes ink
   fingers poke up through the gutter under you (a warning first). Mrs. Vane
   and the Portrait plead in the top-left panel; nothing can be given back
   yet.
   - Top-left **A** → walk off its right edge (jump the tear in the floor
     on the way) → top-right **B**, which is dark. Sweep the light: hold it
     on the **glass lens** high on the left. It throws light down into
     bottom-left **C** and shows a lever there. Hold the light on the **ink
     pool** on B's floor to clear a hole, and walk into it to drop to **D**.
   - From D walk left into C, pull the **lever** (E). Back right into D and
     say **OPEN** at the door.
   - Other ways: drop through A's floor tear into C. Cross C's gutter tear by
     jumping, by lighting the pencil-sketched plank (solid only while lit), or
     by saying **PUSH** at A's crate so it falls into the tear. Jump in C's
     left corner to climb back to A, or in D's right corner to climb to B.
2. **The Margin.** The Artist's hand slams across the page. Then the **Ink
   Shadow** rises at the left after a warning. Run (Shift) for the door, or
   hide (lingering gets your hiding place scribbled out).
3. **The Ink Heart.** The torch doesn't work here ("the ink drinks the
   light"). Move only while the Shadow isn't listening (its eyes go white),
   stand under **ERASE** and hold E.
4. **The reveal** (~35 s). Then the goal line reads *Give back what you
   took.*
5. **The Returning Room.** Arthur, Mrs. Vane, the Portrait and the old drawer
   wait together. Pick one of their words and hold E under any of that
   person's broken bubbles (or at the drawer). Dodge the Artist's hand (hide
   behind the curtain on the far left). When everyone is whole, go right.
6. **The Ink Heart again.** Hold E under the hand's open palm with ERASE: the
   page mends (cutscene), and a lit gap opens in the border.
7. **The Last Page.** Walk out through the gap: the ending pages and credits.

**Minimum word set for the whole game:** OPEN, PUSH, REMEMBER (Chapter 1) and
ERASE. Words are never used up, so no order of play can lock you out.
**Estimated first-time runtime:** about 15½-16 minutes (see the Stage 4C notes
in CLAUDE.md).

## How it fits together

```
autoload/         EventBus (all signals), GameState (inventory, flags, comic damage,
                  chapter, checkpoints, seen cutscenes/scares), FrameManager, TransitionManager,
                  LightingSystem, AbilityRegistry, AudioManager, ShakeManager, CutsceneSystem,
                  MusicManager
data/abilities/   AbilityData .tres, one per word ability (8)
data/bubbles/     BubbleData .tres, one per stealable word
data/chapters/    ChapterData: title, intro captions, first frame, damage scale, line wobble
data/cutscenes/   CutsceneData C1-C6 (beats: panels, drawings, caption, camera, sound)
data/frames/      FrameData .tres, one per comic panel
scripts/abilities/  one handler per ability (open, push, remember, hush, help, wait, hide)
scripts/audio/    SfxSynth / SfxSynth2: every sound; MusicSynth + MusicRenderer: the music
scripts/enemy/    InkCrawler (brain: states and senses), CrawlerView (stop-motion look), CrawlerArt,
                  InkShadow + ShadowView (the huge Chapter 3 version)
scripts/events/   scripted moments: ink hand, crawler window, pantry fingers, passage stalker,
                  cellar chase, return gate, margin chase
scripts/frame/    Frame, exits, fixed lights, backgrounds/ (art per room), spread/ (the page
                  spread: SpreadController, panel views, gutter fingers)
scripts/interactables/  doors, drawers, latches, cabinets, pickups, locks, memories,
                  light-revealed writing, the clock and its pendulum; HidingSpot and
                  ReturnSpot and LightPuzzle (light ink, lens, shadow puzzle, lever) are
                  subclasses (Frame.KIND_CLASSES)
scripts/npc/      characters (Arthur, the portrait, Mrs. Vane) and their art
scripts/player/   Player, Interactor (steal / speak), Flashlight
scripts/systems/  notice meter, feedback FX, save system, debug room jump
shaders/          halftone paper, ink-splash wipe, ink bleed, danger vignette, glitch
ui/               menus, pause, intro and ending (ComicPages), cutscene view and art, reveal,
                  jumpscares, goal line, end card, inventory, lock dials, page overlay
tests/            debug tests (not exported)
tools/datagen/    Python generators for the chapter .tres files (not exported)
```

**Returning words (Chapter 3)**
- `GameState.return_bubble(bubble, screen_pos)` takes the word out of the
  inventory and out of `stolen_bubble_ids`, adds it to `returned_bubble_ids`
  (saved; a returned word is gone for good), lowers `stolen_bubble_count` and
  `comic_damage`, and emits **`EventBus.bubble_returned(bubble, screen_pos)`**
  plus `comic_damage_changed`.
- Who listens: the bubble (whole again, never stealable), its character
  (relief caption, outline completes), return spots and the gallery gate,
  FeedbackFx (THANK YOU, red-to-white drops), AudioManager (soft chime). The
  cracks, ink bleed, wobble and glitch all heal through `comic_damage_changed`.
- Only chapters with `ChapterData.allows_return` (Chapter 3) let you give
  words back, so OPEN can't be returned before the doors that need it.
- Stage 4B hooks are marked `TODO(later)` in `return_bubble` and `InkShadow`.

**Comic damage** = stolen words / 9 (every stealable word in the game: 6 in
Chapter 1, 3 in Chapter 2). Each chapter scales how strongly it shows.

**Adding content**
- **A frame:** add a `FrameData` .tres in `data/frames/` named after its `id`,
  plus a background style in `scripts/frame/backgrounds/`.
- **A chapter:** add a `ChapterData`, and set `next_chapter` on the previous
  chapter's last frame.
- **A word:** add a `BubbleData` .tres in `data/bubbles/`. Bubbles must be
  their own files, because saves store their paths.
- **An ability:** add an `AbilityData` .tres pointing at a script that
  extends `AbilityHandler`, and list it in `AbilityRegistry.ABILITY_PATHS`.
- **A scripted moment:** add a script in `scripts/events/` and register it in
  `Frame.EVENT_SCRIPTS`.
- **A Crawler:** set `crawler_spawn` on a frame, plus `crawler_patrol = true`
  if it should walk the room.

## Tests

- **Debug keys (debug builds only, e.g. the editor's ▶):** **F6** plays the
  next cutscene, **F7** jumps to the Clock Room jumpscare, **F8** jumps to the
  reveal, **F9** goes to the next Chapter 3 room, **F10** jumps to the page
  spread.
- **Jump to any room (debug builds only):** on the web add `?frame=ch3_margin`
  (any frame id) to the page URL; on desktop run with `-- --frame=ch3_margin`.
  You get the words a player would normally carry into that chapter.
- **Inventory test** (steals 12 words, then checks it can add, cycle, show,
  speak and save/load them; your real save is restored afterwards):
  ```
  godot --path . res://tests/inventory_test.tscn
  ```
  It prints `INVENTORY TEST PASSED` and exits with code 0.

## Export to Web (itch.io)

You need the export templates, a one-time install: **Editor → Manage Export
Templates → Download and Install**.

1. **Project → Export…**, select the **Web** preset (threads off, output
   `build/web/index.html`, `tests/` and `tools/` excluded), then **Export
   Project**. Untick *Export With Debug*.
2. Test locally:
   ```
   cd build/web && python3 -m http.server 8000
   ```
   then open http://localhost:8000.
3. For itch.io, zip the *contents* of `build/web` (`index.html` at the zip's
   root). Upload as an HTML project at 1280x720 and turn on *Fullscreen
   button*. *SharedArrayBuffer support* is not needed.

## Web notes

- **Keep `editor/export/convert_text_resources_to_binary=false`** in
  project.godot. With it on, Godot 4.7.2's export silently empties every
  `PackedStringArray` in our data (captions, lines, lock answers).
- Compatibility renderer only. 2D lights, `CanvasModulate` and the shaders
  all run on WebGL 2. Each object is lit by at most about 8 lights, and our
  rooms use 1-3 plus the player's two (aura, flashlight) and the Crawler's
  eye glow.
- The Crawler's "glowing" eyes are a tiny light on its head, because darkness
  (`CanvasModulate`) dims everything drawn in the world.
- Sound is pre-rendered `AudioStreamWAV` built in code. Nothing plays until
  the first click or key press.
- Saves and settings go to `user://`, which is IndexedDB in the browser.

## Fonts

The game uses Godot's built-in default font only.
