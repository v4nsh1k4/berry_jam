"""Writes data/cutscenes/*.tres (CutsceneData). Run: python3 gen_cutscenes.py <project root>"""
from gen_lib import *

FULL = [(0, 0, 1, 1)]
TWO = [(0, 0, 0.5, 1), (0.5, 0, 0.5, 1)]
WIDE_L = [(0, 0, 0.62, 1), (0.62, 0, 0.38, 1)]
THREE = [(0, 0, 0.34, 1), (0.34, 0, 0.33, 1), (0.67, 0, 0.33, 1)]
TOP_BOTTOM = [(0, 0, 1, 0.5), (0, 0.5, 1, 0.5)]


def beat(duration, panels, draws, caption="", camera="still", sfx="", page_turn=False):
    return Sub("cutscene_beat", duration=float(duration), panels=R2Arr(panels), draws=PSA(draws),
               caption=caption, camera=SN(camera), sfx=SN(sfx), page_turn=page_turn)


def cutscene(name, cid, trigger, music, beats, skippable=True):
    write(f"data/cutscenes/{name}.tres", "cutscene_data", dict(
        id=SN(cid), trigger=trigger, skippable=skippable, music_cue=SN(music),
        beats=TypedArr("cutscene_beat", beats)))


# C1: the first theft, and what it costs.
cutscene("c1_first_steal", "c1_first_steal", "first_steal", "sting_soft", [
    beat(2.6, WIDE_L, ["steal_tear", "red_smudge"], "The word came away like a scab.", "zoom_in", "steal"),
    beat(3.0, FULL, ["pencil_lines"], "Somewhere in the house, a line went thin.", "pan_right", "nib"),
])

# C2: the torch, and the thing that watches light.
cutscene("c2_torch", "c2_torch", "resolved:flashlight", "sting_soft", [
    beat(2.8, FULL, ["torch"], "Light. The house shows what it hides...", "zoom_in", "click"),
    beat(3.0, FULL, ["pen_shadow"], "...and it shows you to whatever is watching.", "pan_right", "whisper", True),
])

# C3: Mrs. Vane's flashback: what the book was before the red mark.
cutscene("c3_flashback", "c3_flashback", "frame:ch2_pantry", "flashback", [
    beat(3.2, TWO, ["story_tea", "story_family"], "Once, this was a quiet book. No one in it was red.", "still", "swoosh", True),
    beat(3.0, TWO, ["story_door", "story_gap"], "Then a gap was left on the page. Something red seeped in.", "zoom_in", "nib"),
])

# C4: down the cellar stair, into Chapter 3.
cutscene("c4_descent", "c4_descent", "frame:ch2_end", "sting_descent", [
    beat(3.0, FULL, ["descent"], "The stair goes down further than the drawing does.", "zoom_in", "creak"),
    beat(3.2, WIDE_L, ["ink_rising", "red_smudge"], "And the ink is rising to meet you.", "shake", "growl"),
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
