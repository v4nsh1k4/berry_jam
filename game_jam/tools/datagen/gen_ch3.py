"""Generates Chapter 3 .tres data for INK-BLEED (dev tool, not shipped).

Story order (Stage 4B): discover the damage (Torn Page) -> an ability puzzle
(Gallery of Words) -> the Ink Shadow chase (Margin) -> the final steal (Ink
Heart) -> REVEAL -> return phase (Returning Room, Torn Page, Gallery, Ink
Heart) -> repair -> escape (Last Page) -> epilogue. Nothing can be given back
before the reveal (GameState.twist_revealed)."""
from gen_lib import *

GO = (1080, 396, 104, 112)
BACK = (0, 396, 96, 112)
HAND = "artist_hand"

# The last word: the Shadow holds it. Stealing it plays the reveal.
write("data/bubbles/hand_erase.tres", "bubble_data",
      dict(id=SN("hand_erase"), text="ERASE", ability_id=SN("erase"), stolen_from=SN("hand"),
           owner_name="the Hand", story_final=True))

def owner(npc_id, name, style, pos, words, lines, broken, relief, pleas=(), **extra):
    return Sub("npc_data", id=SN(npc_id), display_name=name, position=V2(pos), visual_style=SN(style),
               bubbles=TypedArr("bubble_data", [bubble_ext(w) for w in words]),
               lines=PSA(lines), broken_lines=PSA(broken), relief_lines=PSA(relief), plea_lines=PSA(pleas),
               words_stealable=False, **extra)

VANE = dict(npc_id="mrs_vane", name="Mrs. Vane", style="housekeeper", pos=(470, 404),
            words=["vane_hide", "vane_hush", "vane_wait"],
            lines=["Don't {word} from me, child.", "{word}, the page is tearing.", "{word}. Don't leave us like this."],
            broken=["Don't... from me. P-please.", "..., the page is t-tearing...", "... Don't leave us. Please."],
            relief=["Bless you, child.", "It sounds right again.", "There. That's my voice."],
            pleas=["You took it... I can't finish my sentences.", "Every word you took left a hole in me.",
                   "I keep reaching for it and it isn't there."])
LADY = dict(npc_id="portrait_lady", name="The Portrait", style="portrait", pos=(1000, 170), words=["portrait_remember"],
            lines=["Help me {word} who I was."], broken=["Help me... who I... was?"], relief=["I remember now. Thank you."],
            pleas=["I can't... who was I? You took it.", "There is a hole where my words were."],
            reach_y=270.0, bubble_offsets=PV2A([(-230, -60)]))
ARTHUR = dict(npc_id="arthur", name="Arthur", style="butler", pos=(560, 404),
              words=["arthur_open", "arthur_push", "arthur_wait", "arthur_help"],
              lines=["I used to {word} every door in this house.", "{word} the chairs in, I always said.",
                     "{word} for me, sir. Please.", "Can you {word} me find my words?"],
              broken=["I used to... every d-door. Please.", "...the chairs in. Something's m-missing.",
                      "...for me. P-please, give it back.", "Can you... me? Please."],
              relief=["Oh... thank you, sir.", "That's mine. I remember it.", "I can nearly speak again.", "I'm whole. Thank you."])
ARTHUR_FAR = Sub("npc_data", id=SN("arthur_far"), display_name="Arthur", position=V2((1114, 382)),
                 visual_style=SN("butler"), scale=0.6)

def the_hand(display):
    # Invisible holder for the last word: the bubble hangs in the Shadow's
    # grip (and, after the reveal, under the hand's open palm).
    return Sub("npc_data", id=SN("the_hand"), display_name=display, position=V2((860, 404)), visual_style=SN("none"),
               bubbles=TypedArr("bubble_data", [bubble_ext("hand_erase")]), lines=PSA(["{word} the mistake."]),
               broken_lines=PSA(["... the mistake."]), bubble_offsets=PV2A([(0, -236)]), words_stealable=True)

def paint(pid, oid, x, name, flag=""):
    p = dict(id=pid, kind="return_spot", position=(x, 140), size=(160, 200), owner_id=oid, text="painting", caption=name)
    if flag: p["sets_flag"] = flag
    return item(**p)

# ---- Before the reveal -------------------------------------------------------

# 1. The Torn Page: everyone missing exactly what was taken. Nothing can be mended yet.
frame("ch3_torn_page", "The Torn Page", "torn_page", 0.14, (150, 466),
      ["The page is tearing. Everyone here is missing something.", "They are missing what you took."],
      "Nothing here can be mended yet. The way on is to the right.",
      exits=[exit_(GO, "ch3_gallery_words", (170, 466), SLIDE)],
      lights=[light("glow", (470, 260), 300, 0.5), light("glow", (1000, 200), 220, 0.4)],
      npcs=[owner(**VANE), owner(**LADY), ARTHUR_FAR],
      glitch=0.35, tilt=-1.2, sketch=0.1)

# 2. The Gallery of Words: the damage on show (ghost bubbles over the
# portraits), and a puzzle for the words every player has: PUSH, REMEMBER,
# the dial box, OPEN. The flashlight finds the hint.
GALLERY_SYMBOLS = ["nib", "eye", "hand"]
frame("ch3_gallery_words", "The Gallery of Words", "gallery_words", 0.12, (170, 466),
      ["Three portraits, and ghost bubbles where their words should be. Yours now.", "The way on is sealed."],
      "PUSH the fallen frame, say REMEMBER at the wall behind it, set the dial box to those marks, then say OPEN at the door.",
      exits=[exit_(BACK, "ch3_torn_page", (980, 466), SLIDE), exit_(GO, "ch3_margin", (320, 466), SLIDE, "gallery_open")],
      lights=[light("glow", (195, 360), 200, 0.35), light("glow", (595, 360), 200, 0.35), light("glow", (935, 360), 200, 0.35)],
      items=[paint("paint_arthur", "arthur", 115, "Arthur"), paint("paint_vane", "mrs_vane", 515, "Mrs. Vane"),
             paint("paint_lady", "portrait_lady", 855, "The Lady"),
             item(id="gallery_memory", kind="memory", position=(300, 220), size=(190, 110), symbols=GALLERY_SYMBOLS,
                  requires_flag="gallery_frame_moved"),
             item(id="gallery_fallen", kind="pushable", position=(310, 252), size=(170, 130), accepted_ability_ids=["push"],
                  sets_flag="gallery_frame_moved", push_offset=(-190, 0), prompt="A fallen frame, far too heavy to lift."),
             item(id="gallery_writing", kind="writing", position=(560, 20), size=(440, 90), revealed_by_light=True,
                  text="what fell hides what it saw\nmove it. REMEMBER."),
             item(id="gallery_dials", kind="symbol_lock", position=(705, 262), size=(120, 70), text="panel",
                  symbols=GALLERY_SYMBOLS, sets_flag="gallery_dials"),
             item(id="gallery_door", kind="door", position=(1066, 150), size=(96, 232), accepted_ability_ids=["open"],
                  requires_flag="gallery_dials", sets_flag="gallery_open",
                  prompt="Sealed. The dial box beside the portraits isn't set.")],
      glitch=0.5, tilt=1.5, sketch=0.25)

# 3. The Margin: the Ink Shadow's chase.
frame("ch3_margin", "The Margin", "margin", 0.12, (320, 466),
      ["The margin. Nothing here is drawn properly.", "Something enormous is coming. Run for the door, or hide."],
      "Run (Shift) for the far door. Hide only to dodge a lunge: it scribbles hiding places out.",
      exits=[exit_(GO, "ch3_ink_heart", (160, 466), SPLASH)],
      lights=[light("glow", (1110, 300), 220, 0.45), light("glow", (600, 260), 300, 0.3)],
      items=[item(id="margin_curtain", kind="hiding_spot", position=(330, 110), size=(110, 272), text="curtain"),
             item(id="margin_wardrobe", kind="hiding_spot", position=(620, 120), size=(120, 262), text="wardrobe"),
             item(id="margin_table", kind="hiding_spot", position=(880, 300), size=(130, 82), text="table")],
      crawler=(40, 492), crawler_kind="shadow", events=["margin_chase"], glitch=0.75, tilt=-2.0, sketch=0.45)

# 4. The Ink Heart: the Shadow's lair. It guards the last word and listens.
frame("ch3_ink_heart", "The Ink Heart", "ink_heart", 0.1, (160, 466),
      ["The Ink Heart. It is holding one last word.", "When its eyes go white, it is listening. Be still."],
      "Move only while it isn't listening; hide or stand still when its eyes go white. Stand under the word and hold E. "
      "HUSH, WAIT and HIDE make it easier.",
      lights=[light("glow", (860, 170), 170, 0.55), light("glow", (200, 300), 220, 0.3)],
      items=[item(id="heart_curtain", kind="hiding_spot", position=(360, 110), size=(110, 272), text="curtain"),
             item(id="heart_table", kind="hiding_spot", position=(650, 300), size=(130, 82), text="table")],
      npcs=[the_hand("The Shadow")],
      crawler=(1010, 492), patrol=True, crawler_kind="heart", glitch=0.9, tilt=-3.0, sketch=0.55)

# ---- After the reveal: the return phase ---------------------------------------

# 5. The Returning Room: first room after the reveal. Arthur and the drawer.
frame("ch3_returning_room", "The Returning Room", "returning_room", 0.2, (170, 466),
      ["Now you know what you are. Give back what you took.",
       "Select a word (1-6, Q / R), stand under its owner's broken bubble, hold E."],
      "Give Arthur his words, and the drawer its HUSH. When the eraser's shadow falls on the floor, step out of it or hide.",
      exits=[exit_(GO, "ch3_torn_return", (170, 466), SLIDE)],
      lights=[light("candle", (380, 288), 320, 0.85), light("glow", (255, 175), 240, 0.4)],
      items=[item(id="ch3_drawer", kind="return_spot", position=(930, 300), size=(110, 82), owner_id="drawer",
                  text="drawer", sets_flag="whole_drawer", caption="the old drawer"),
             item(id="returning_curtain", kind="hiding_spot", position=(30, 110), size=(100, 272), text="curtain")],
      npcs=[owner(**ARTHUR)], events=[HAND], glitch=0.6, tilt=0.6, sketch=0.15)

# 6. The Torn Page again: Mrs. Vane and the Portrait.
frame("ch3_torn_return", "The Torn Page", "torn_page", 0.16, (170, 466),
      ["The torn page. They are still waiting.", "Give each word back to the one you took it from."],
      "Give Mrs. Vane her words, and the Portrait hers. The hand grows weaker with every word you give back.",
      exits=[exit_(BACK, "ch3_returning_room", (980, 466), SLIDE), exit_(GO, "ch3_gallery_return", (170, 466), SLIDE)],
      lights=[light("glow", (470, 260), 300, 0.5), light("glow", (1000, 200), 220, 0.4)],
      items=[item(id="torn_curtain", kind="hiding_spot", position=(920, 110), size=(100, 272), text="curtain")],
      npcs=[owner(**VANE), owner(**LADY), ARTHUR_FAR], events=[HAND], glitch=0.45, tilt=-1.0, sketch=0.1)

# 7. The Gallery of Words, repairing: the right word to the right owner opens the way.
frame("ch3_gallery_return", "The Gallery of Words", "gallery_words", 0.14, (170, 466),
      ["Every portrait wants its voice back. So does the drawer.", "The way on opens when everyone is whole."],
      "Give each word to its owner's portrait (or the drawer). A lit portrait is whole. Owners you never robbed are lit already.",
      exits=[exit_(BACK, "ch3_torn_return", (980, 466), SLIDE),
             exit_(GO, "ch3_heart_return", (160, 466), SPLASH, "gallery_open")],
      lights=[light("glow", (230, 360), 200, 0.35), light("glow", (592, 360), 200, 0.35), light("glow", (954, 360), 200, 0.35)],
      items=[paint("paint_arthur", "arthur", 150, "Arthur", "whole_arthur"),
             paint("paint_vane", "mrs_vane", 512, "Mrs. Vane", "whole_vane"),
             paint("paint_lady", "portrait_lady", 874, "The Portrait", "whole_lady"),
             item(id="gallery_drawer", kind="return_spot", position=(360, 300), size=(100, 82), owner_id="drawer",
                  text="drawer", sets_flag="whole_drawer", caption="the old drawer"),
             item(id="gallery_wall", kind="secret_door", position=(1060, 120), size=(100, 262),
                  requires_flag="gallery_open", sets_flag="gallery_door")],
      events=["gallery_gate", HAND], glitch=0.3, tilt=0.8, sketch=0.1)

# 8. The Ink Heart again: the last word goes back to the hand.
frame("ch3_heart_return", "The Ink Heart", "ink_heart", 0.2, (160, 466),
      ["The hand is waiting. It has stopped hunting.", "One word left. It was never yours."],
      "Select ERASE, stand under the hand's empty bubble and hold E.",
      exits=[exit_(GO, "ch3_escape", (170, 466), SLIDE, "comic_repaired")],
      lights=[light("glow", (860, 170), 220, 0.6), light("glow", (300, 300), 260, 0.35)],
      npcs=[the_hand("The Hand")], events=[HAND], glitch=0.45, tilt=-1.5, sketch=0.3, border_gap=True)

# 9. The Last Page: whole again, everyone speaking full lines. Out through the border.
def farewell(npc_id, name, style, pos, word, line, offset, **extra):
    return Sub("npc_data", id=SN(npc_id), display_name=name, position=V2(pos), visual_style=SN(style),
               bubbles=TypedArr("bubble_data", [bubble_ext(word)]), lines=PSA([line]), broken_lines=PSA(["..."]),
               bubble_offsets=PV2A([offset]), words_stealable=False, **extra)
frame("ch3_escape", "The Last Page", "escape", 0.9, (170, 466),
      ["The page is whole again.", "The way out is through the border."],
      "Walk out through the gap in the border, on the right.",
      exits=[exit_((1100, 396, 84, 112), "ch3_outside", (170, 466), SLIDE)],
      npcs=[farewell("portrait_lady", "The Portrait", "portrait", (190, 170), "portrait_remember",
                     "I {word} who I was. Thank you.", (230, -90), reach_y=270.0),
            farewell("arthur", "Arthur", "butler", (560, 404), "arthur_open", "Thank you, sir. I can {word} every door again.", (-80, -250)),
            farewell("mrs_vane", "Mrs. Vane", "housekeeper", (930, 404), "vane_hide", "Go on, child. Nothing to {word} from now.", (20, -232))],
      border_gap=True)

# 10. Outside the page: the epilogue plays here, then the end card.
frame("ch3_outside", "", "plain", 1.0, (170, 466), [], "", ending="THE END", epilogue=True)

write("data/chapters/ch3.tres", "chapter_data", dict(
    id=SN("ch3"), title="Chapter 3: The Ink Heart", first_frame_id=SN("ch3_torn_page"),
    damage_visual_scale=1.6, line_jitter=1.6, allows_return=True, return_frame_id=SN("ch3_returning_room"),
    intro_lines=PSA(["Issue #3.", "The ink is running. The panels won't hold.", "Everyone you took from is still here. Waiting."])))
