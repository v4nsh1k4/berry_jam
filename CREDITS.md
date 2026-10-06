# Credits and third-party notices

## Made by the team during the jam

- All GDScript code (`autoload/`, `scripts/`, `ui/`, `tests/`), scenes
  (`scenes/`) and game data (`data/`, `tools/datagen/` generators).
- All shaders (`shaders/`: ink splash, ink bleed, glitch, halftone paper,
  danger vignette).
- All art: drawn in code at runtime (`_draw()`), no image files except the
  project icon `icon.svg` (hand-written SVG).
- All music and sound effects except the three recordings below: synthesized
  in code (`scripts/audio/`).
- Audio recordings (team-made, see "Needs verification"):
  - `audio/baby_cry.wav`: the cry heard three times in the game.
  - `audio/ending.wav`: the short sting at the epilogue.
  - `audio/bg_track.wav`: a background track; **no longer used** (the game
    plays synthesized piano instead) but still in the repository.
- `proposal.pdf`: the team's original game proposal.

Development was assisted by the Claude Code AI assistant (commits marked
`Co-Authored-By: Claude`).

## Third-party

| What | Used for | Source | License |
| --- | --- | --- | --- |
| Godot Engine 4.7.2 | the engine and runtime | https://godotengine.org | MIT |
| Godot 4.7.2 Web export templates | the browser build | https://godotengine.org | MIT (engine) plus the third-party licenses bundled with Godot (https://godotengine.org/license) |
| Godot's built-in default font | all on-screen text (no font file is shipped by us; it is inside the engine) | bundled with Godot | SIL Open Font License 1.1 (see verification below) |

No plugins, addons, asset packs, starter kits, templates or copied code
snippets are part of the game.

## Needs verification

Please check these before submitting; they are listed rather than guessed:

1. **The three audio files** (`audio/baby_cry.wav`, `audio/ending.wav`,
   `audio/bg_track.wav`): the project notes say they were made by the team.
   Confirm who made each and that they were made during the jam, and that
   nothing in them comes from a sample library or another track (if it does,
   add its source and license here). `bg_track.wav` is unused: you could
   delete it to shrink the download.
2. **The default font**: Godot 4's built-in theme font is, to our knowledge,
   *Open Sans* (SIL OFL 1.1), compiled into the engine. Confirm against the
   license list for Godot 4.7.2 (https://godotengine.org/license) and name it
   here.
3. **Removed prototype** (`berry-jam/`, deleted before submission; still in
   the git history): it held two third-party editor addons (`godot_mcp`,
   `godot_mcp_toolkit`) used as development tools, not game code. Confirm
   whether they need a mention for the history audit.
4. **Local tool, not in the repository**: `godot-mcp-toolkit/` (an editor
   automation tool, git-ignored). It is not part of the game or the build.
