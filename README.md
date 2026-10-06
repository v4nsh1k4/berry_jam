# Ink-Bleed

**A 2D psychological-horror puzzle game set inside a comic book, _The Silent
House of Hollow Hill_.** Made for the Infinium 26 game jam (theme: COMIC /
LIGHT / TWIST).

A reader leans too close to an old comic and is pulled in. Inside, you are an
unperson: faceless, drawn in red, the only colour in a black-and-white world,
with an empty speech bubble and no words of your own. To get through the house
you **steal words** from its characters and **speak them as power**: OPEN a
door, PUSH a cabinet, REMEMBER a code, HIDE from what hunts in the dark. But
every stolen word tears the page a little more, and **light** (your flashlight)
shows you the house while drawing the Ink Crawler to you. Find the way out of
the comic before the story falls apart.

- **Play in the browser:** https://ananyas2025.itch.io/ink-bleed
- **Playtime:** about 15-16 minutes, three chapters.

## Team

| Name | Discord |
| --- | --- |
| Ananya Sinha | ananya.s2025 |
| Sai Akshara Bysani | ak.0370 |
| Vanshika Rallapalli | midnightblooom |
| Shevani Vinod | serpentwantsthelimelight_01849 |
| Hasini Toleti | marshmallow._.0 |

## Engine

Godot **4.7.2**, GDScript only, Compatibility renderer, Web export without
threads. All art, animation, music and sound are generated in code; the only
asset files are a cry recorded by the team and a royalty-free music sting from
SnipSound, in `audio/` (see [CREDITS.md](CREDITS.md)).

## Run locally (from the repo root)

1. Install Godot 4.7.2 (the standard build; the .NET build also runs it).
2. In Godot's Project Manager choose **Import** and pick `project.godot` at the
   root of this repository.
3. Press **▶ Run Project** (F5, or ⌘B on a Mac). The main scene is
   `scenes/main.tscn`. The editor canvas looks empty: everything is drawn at
   runtime.

Command line: `godot --path .` from the repo root.

## Build for the web (itch.io)

1. Use the **standard** (non-.NET) Godot 4.7.2 editor: the .NET editor refuses
   Web export even for GDScript projects. Install the 4.7.2 export templates
   (Editor → Manage Export Templates).
2. **Project → Export → Web → Export Project** (the preset already writes
   `build/web/index.html`), or from the repo root:
   `godot --headless --path . --export-release "Web" build/web/index.html`
3. Zip the **contents** of `build/web/` (`index.html` at the top level of the
   zip) and upload it to itch.io as an HTML project, viewport 1280 x 720. No
   SharedArrayBuffer is needed (threads are off).

Keep `editor/export/convert_text_resources_to_binary=false` in
`project.godot`: with it on, Godot 4.7.2 web exports lose the game's text.

## Controls

| Action | Keys |
| --- | --- |
| Walk | A / D or the arrow keys |
| Step nearer / further | W / S |
| Run (loud: it can hear you) | Shift |
| Jump (only on the page-spread page in Chapter 3) | Space, W / Up |
| Say the selected word / use doors, locks, hiding spots | E |
| Steal a word / give a word back | Hold E under it |
| Pick the word E says | 1-6, Q / R, mouse wheel (or click a slot) |
| Reorder words | Shift + Q / R, or drag |
| Flashlight, aimed with the mouse | F or left click |
| Controls card, any time | F1 or H |
| Pause | Esc or P |
| Skip a cutscene | Space or click |

## Built during the jam

All of the game's code, mechanics, architecture, art and sound were built by
the team during the jam's 100-hour window (except the royalty-free SnipSound
music sting credited below). No game starter kits, templates,
asset packs, plugins or addons are used: the project contains only original
GDScript, original shaders, data files written for this game, an audio
recording made by the team, and one royalty-free music sting (SnipSound). Development was assisted by the Claude Code AI
assistant (visible as `Co-Authored-By` lines in the commit history).
The original plan is in [`proposal.pdf`](proposal.pdf); see
[SCOPE.md](SCOPE.md) for what the game delivers against it.

## Third-party assets and code

- **Godot Engine 4.7.2** and its Web export templates: MIT License.
- **Open Sans**, Godot's built-in default font (used for all text; no font
  files are included): SIL Open Font License 1.1.
- **`audio/ending.wav`**: Music from SnipSound
  (https://snipsound.com/free-music/?track=278), royalty-free.
- Nothing else: no third-party art, shaders, plugins or code snippets.
  Full list: [CREDITS.md](CREDITS.md).

## License

[MIT](LICENSE).

## For developers

`CLAUDE.md` documents the architecture, systems and test scripts in detail
(`tests/` and `tools/` are excluded from the export).
