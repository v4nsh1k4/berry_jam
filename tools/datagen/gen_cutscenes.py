"""Writes data/cutscenes/*.tres (CutsceneData). Run: python3 gen_cutscenes.py <project root>"""
from gen_lib import *

FULL = [(0, 0, 1, 1)]
TWO = [(0, 0, 0.5, 1), (0.5, 0, 0.5, 1)]
WIDE_L = [(0, 0, 0.62, 1), (0.62, 0, 0.38, 1)]
THREE = [(0, 0, 0.34, 1), (0.34, 0, 0.33, 1), (0.67, 0, 0.33, 1)]
TOP_BOTTOM = [(0, 0, 1, 0.5), (0, 0.5, 1, 0.5)]


# Stage 6b reading-time pass (playtesters could not finish the captions):
# a beat lasts at least the caption's start delay, its reading time (0.06 s a
# character, 2.5 s at least) and a short hold; page turns add their turn.
TYPE_START = 0.3
READ_PER_CHAR = 0.06
MIN_READ = 2.5
HOLD = 0.6
TURN = 0.5


def reading_time(caption, page_turn=False):
    return TYPE_START + max(MIN_READ, len(caption) * READ_PER_CHAR) + HOLD + (TURN if page_turn else 0.0)


def beat(duration, panels, draws, caption="", camera="still", sfx="", page_turn=False):
    # Stage 4D runtime pass: every beat 15% shorter; Stage 6b: never shorter
    # than its reading time.
    seconds = max(float(duration) * 0.85, reading_time(caption, page_turn))
    return Sub("cutscene_beat", duration=round(seconds, 2), panels=R2Arr(panels), draws=PSA(draws),
               caption=caption, camera=SN(camera), sfx=SN(sfx), page_turn=page_turn)


def cutscene(name, cid, trigger, music, beats, skippable=True):
    write(f"data/cutscenes/{name}.tres", "cutscene_data", dict(
        id=SN(cid), trigger=trigger, skippable=skippable, music_cue=SN(music),
        beats=TypedArr("cutscene_beat", beats)))


# Stage 5: C2 and C4 are first person (CutsceneArt3/4 pov_* ids and pov_*
# camera modes). Stage 6: C1 is third person again (CutsceneArt5 c1_* ids).
# Same beats and durations as Stage 4D.

# C1: the first theft, and what it costs.
cutscene("c1_first_steal", "c1_first_steal", "first_steal", "sting_soft", [
    beat(2.6, WIDE_L, ["c1_steal", "c1_tear"], "The word came away like a scab.", "zoom_in", "steal"),
    beat(3.0, WIDE_L, ["c1_thin", "c1_alone"], "Somewhere in the house, a line went thin.", "shake", "nib"),
])

# C2: the torch, and the thing that watches light.
cutscene("c2_torch", "c2_torch", "resolved:flashlight", "sting_soft", [
    beat(2.8, FULL, ["pov_torch"], "Light. The house shows what it hides...", "pov_sweep", "click"),
    beat(3.0, FULL, ["pov_watch"], "...and it shows you to whatever is watching.", "pov_look", "whisper", True),
])

# C3: Mrs. Vane's flashback: what the book was before the red mark.
cutscene("c3_flashback", "c3_flashback", "frame:ch2_pantry", "flashback", [
    beat(3.2, TWO, ["story_tea", "story_family"], "Once, this was a quiet book. No one in it was red.", "still", "swoosh", True),
    beat(3.0, TWO, ["story_door", "story_gap"], "Then a gap was left on the page. Something red seeped in.", "zoom_in", "nib"),
])

# C4: down the cellar stair, into Chapter 3.
cutscene("c4_descent", "c4_descent", "frame:ch2_end", "sting_descent", [
    beat(3.0, FULL, ["pov_stairs"], "The stair goes down further than the drawing does.", "pov_look_down", "groan"),
    beat(3.2, FULL, ["pov_ink_rise"], "And the ink is rising to meet you.", "pov_shake", "growl"),
])

# C5: the Ink Heart, before the last theft.
cutscene("c5_before_final", "c5_before_final", "frame:ch3_ink_heart", "sting_heart", [
    beat(2.8, TWO, ["sketch_through", "torn_panels"], "The Heart. Every line in the book runs here.", "zoom_in", "heartbeat"),
    beat(3.4, WIDE_L, ["shadow_hang", "eraser_dust"], "Something huge holds the last word.", "pan_left", "nib", True),
])

# C6: the repair, after the last word goes home.
cutscene("c6_repair", "c6_repair", "repaired", "repair", [
    beat(2.6, TWO, ["eraser_dust", "repair_panel"], "The eraser lifts. The lines come back.", "still", "nib", True),
    beat(2.8, FULL, ["whole_cast"], "Everyone is whole again.", "zoom_out", "chime"),
    beat(3.0, FULL, ["border_gap"], "And in the border, a gap just your size.", "pan_right", "swoosh"),
])
