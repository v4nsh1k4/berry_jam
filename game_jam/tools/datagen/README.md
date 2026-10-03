# Data generators (dev tool, not part of the game)

These Python scripts write the chapter `.tres` files in `data/`. They are the
quickest way to lay out a whole chapter (rooms, exits, lights, objects, NPCs,
words) in one place.

```
cd game_jam
python3 tools/datagen/gen_ch1.py .
python3 tools/datagen/gen_ch2.py .
```

Running a generator **overwrites** that chapter's `.tres` files. If you have
tweaked a room in the Godot editor since, either make the same change here
first, or stop using the generator for that chapter.
