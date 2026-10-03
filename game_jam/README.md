# Ink-Bleed

A 2D psychological horror puzzle game set inside a comic book, *The Silent
House of Hollow Hill*. You are an unperson with no speech bubble, drawn in the
only colour in the comic: red. You steal other characters' words and speak
them to open, move, remember, freeze and hide. Light shows you the house, and
it shows you to the Ink Crawler. Every stolen word damages the comic a little
more.

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
| Flashlight | **F** or left click, aimed with the mouse (from the end of Chapter 1) |
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
5. **The Study.** PUSH the cabinet, then say REMEMBER: the marks are **eye,
   moon, key**. Set the door's dials to match.
6. **The Back Stair.** Take the flashlight, then go through the right-hand
   door. Chapter 2's intro follows.

Optional: OPEN the bedchamber drawer to get **HUSH**.

### Chapter 2: The Hallway of Shadows

1. **The Long Hallway** (safe). Turn the light on. Writing appears on the wall,
   and a **hidden latch** appears at the far end. Say OPEN to the latch, and the
   panelling opens.
2. **The Portrait Gallery.** The Crawler sleeps by the exit. Keep the light
   off and walk (don't run) past it. If it wakes, stand still in the dark
   until it sinks.
3. **The Servants' Passage.** After a growl and a warning, the Crawler rises
   behind you. Press E at the wardrobe, curtain or table to hide, and come out
   when it has gone. You can also simply run for the far door.
4. **The Housekeeper's Pantry.** Steal **HIDE, HUSH and WAIT** from Mrs. Vane.
   The first theft triggers the chapter's one scare.
5. **The Clock Room.** The Crawler patrols. Say **HUSH** (or WAIT once it is
   up), then shine the light on the clock face for a second. Its marks are
   **spiral, hand, house**. Turn the light off, or hide behind the curtain.
6. **The Locked Cellar Stair.** If you've forgotten the marks, say REMEMBER.
   Press E at the dial box, set it to spiral, hand, house, then say **OPEN**
   at the padlock. The Crawler surges, so go through the door.
7. "CHAPTER 3: COMING SOON".

**If you take nothing optional:** Chapter 1 still gives OPEN, PUSH and
REMEMBER, and Chapter 2 needs only OPEN, REMEMBER and the flashlight. The clock
can be read with no words at all: wait until the Crawler is at the far end of
its patrol, light the clock for a second, then turn the light off and stand
still, or hide behind the curtain. Words are never used up, so
no order of play can lock you out.

## How it fits together

```
autoload/         EventBus (all signals), GameState (inventory, flags, comic damage,
                  chapter, checkpoints), FrameManager, TransitionManager, LightingSystem,
                  AbilityRegistry, AudioManager, ShakeManager
data/abilities/   AbilityData .tres, one per word ability (8)
data/bubbles/     BubbleData .tres, one per stealable word
data/chapters/    ChapterData: title, intro captions, first frame, damage scale, line wobble
data/frames/      FrameData .tres, one per comic panel
scripts/abilities/  one handler per ability (open, push, remember, hush, help, wait, hide)
scripts/audio/    SfxSynth: every sound rendered in code
scripts/enemy/    InkCrawler (brain: states and senses), CrawlerView (stop-motion look), CrawlerArt
scripts/events/   scripted moments: ink hand, crawler window, pantry fingers, passage stalker, cellar chase
scripts/frame/    Frame, exits, fixed lights, backgrounds/ (art per room)
scripts/interactables/  doors, drawers, latches, cabinets, pickups, locks, memories,
                  hiding spots, light-revealed writing, the clock and its pendulum
scripts/npc/      characters (Arthur, the portrait, Mrs. Vane) and their art
scripts/player/   Player, Interactor (steal / speak), Flashlight
scripts/systems/  notice meter, feedback FX, save system
shaders/          halftone paper, ink-splash wipe, ink bleed, danger vignette
ui/               menus, pause, intro, end card, inventory, lock dials, page overlay
tests/            debug tests (not exported)
tools/datagen/    Python generators for the chapter .tres files (not exported)
```

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
