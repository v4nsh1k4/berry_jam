# Credits and third-party notices

## Made by the team during the jam

- All GDScript code (`autoload/`, `scripts/`, `ui/`, `tests/`), scenes
  (`scenes/`) and game data (`data/`, `tools/datagen/` generators).
- All shaders (`shaders/`: ink splash, ink bleed, glitch, halftone paper,
  danger vignette).
- All art: drawn in code at runtime (`_draw()`), no image files except the
  project icon `icon.svg` (hand-written SVG).
- All music and sound effects except the two audio files in `audio/`:
  synthesized in code (`scripts/audio/`).
- `audio/baby_cry.wav` (the cry heard three times in the game): recorded by
  our team during the jam.
- `proposal.pdf`: the team's original game proposal.

Development was assisted by the Claude Code AI assistant (commits marked
`Co-Authored-By: Claude`).

## Third-party

| What | Used for | Source | License |
| --- | --- | --- | --- |
| Godot Engine 4.7.2 | the engine and runtime | https://godotengine.org | MIT |
| Godot 4.7.2 Web export templates | the browser build | https://godotengine.org | MIT (engine) plus the third-party licenses bundled with Godot (https://godotengine.org/license) |
| Godot's built-in default font, Open Sans | all on-screen text (no font file is shipped by us; it is inside the engine) | bundled with Godot | SIL Open Font License 1.1 |
| `audio/ending.wav` | the short music sting at the epilogue | Music from SnipSound (https://snipsound.com/free-music/?track=278), royalty-free | royalty-free, no attribution required (credited anyway) |

No plugins, addons, asset packs, starter kits, templates or copied code
snippets are part of the game.

## Development history

Two third-party editor addons were used in an early prototype (berry_jam,
the `berry-jam/` folder) and removed; they were never part of the game.
