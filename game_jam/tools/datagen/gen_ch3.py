"""Generates Chapter 3 (first 4 frames) .tres data for INK-BLEED (dev tool, not shipped)."""
from gen_lib import *

GO = (1080, 396, 104, 112)
BACK = (0, 396, 96, 112)

def owner(npc_id, name, style, pos, words, lines, broken, relief, **extra):
    return Sub("npc_data", id=SN(npc_id), display_name=name, position=V2(pos), visual_style=SN(style),
               bubbles=TypedArr("bubble_data", [bubble_ext(w) for w in words]),
               lines=PSA(lines), broken_lines=PSA(broken), relief_lines=PSA(relief), words_stealable=False, **extra)

# 1. The Torn Page: everyone missing exactly what was taken. Returning starts here.
frame("ch3_torn_page", "The Torn Page", "torn_page", 0.14, (150, 466),
      ["The page is tearing. Everyone here is missing something.",
       "Pick a stolen word, stand under its owner's broken bubble, hold E to give it back."],
      "Give each word back to the one you took it from. Arthur is further on.",
      exits=[exit_(GO, "ch3_returning_room", (170, 466), SLIDE)],
      lights=[light("glow", (470, 260), 300, 0.5), light("glow", (1000, 200), 220, 0.4)],
      npcs=[owner("mrs_vane", "Mrs. Vane", "housekeeper", (470, 404), ["vane_hide", "vane_hush", "vane_wait"],
                  ["Don't {word} from me, child.", "{word}, the page is tearing.", "{word}. Don't leave us like this."],
                  ["Don't... from me. P-please.", "..., the page is t-tearing...", "... Don't leave us. Please."],
                  ["Bless you, child.", "It sounds right again.", "There. That's my voice."]),
            owner("portrait_lady", "The Portrait", "portrait", (1000, 170), ["portrait_remember"],
                  ["Help me {word} who I was."], ["Help me... who I... was?"], ["I remember now. Thank you."],
                  reach_y=270.0, bubble_offsets=PV2A([(-230, -60)])),
            Sub("npc_data", id=SN("arthur_far"), display_name="Arthur", position=V2((1114, 382)),
                visual_style=SN("butler"), scale=0.6)],
      glitch=0.35, tilt=-1.2, sketch=0.1)

# 2. The Returning Room: calm and safe; Arthur and the old drawer.
frame("ch3_returning_room", "The Returning Room", "returning_room", 0.2, (170, 466),
      ["A quiet room. Nothing hunts here.", "Arthur is waiting for his words."],
      "Select one of Arthur's words and hold E under its broken bubble. The drawer takes back what you found in it.",
      exits=[exit_(BACK, "ch3_torn_page", (980, 466), SLIDE), exit_(GO, "ch3_gallery_words", (170, 466), SLIDE)],
      lights=[light("candle", (380, 288), 320, 0.85), light("glow", (255, 175), 240, 0.4)],
      items=[item(id="ch3_drawer", kind="return_spot", position=(930, 300), size=(110, 82), owner_id="drawer",
                  text="drawer", sets_flag="whole_drawer", caption="The old drawer")],
      npcs=[owner("arthur", "Arthur", "butler", (560, 404), ["arthur_open", "arthur_push", "arthur_wait", "arthur_help"],
                  ["I used to {word} every door in this house.", "{word} the chairs in, I always said.",
                   "{word} for me, sir. Please.", "Can you {word} me find my words?"],
                  ["I used to... every d-door. Please.", "...the chairs in. Something's m-missing.",
                   "...for me. P-please, give it back.", "Can you... me? Please."],
                  ["Oh... thank you, sir.", "That's mine. I remember it.", "I can nearly speak again.", "I'm whole. Thank you."])],
      glitch=0.12, tilt=0.4)

# 3. The Gallery of Words: every portrait lit opens the way.
paint = lambda pid, oid, x, name, flag: item(id=pid, kind="return_spot", position=(x, 140), size=(160, 200), owner_id=oid,
                                             text="painting", sets_flag=flag, caption=name)
frame("ch3_gallery_words", "The Gallery of Words", "gallery_words", 0.12, (170, 466),
      ["Three portraits. The way on opens when everyone is whole.", "Give their words back here, or where you met them."],
      "A lit portrait is whole. Give back every word you took from the dark ones.",
      exits=[exit_(BACK, "ch3_returning_room", (980, 466), SLIDE), exit_(GO, "ch3_margin", (320, 466), SLIDE, "gallery_open")],
      lights=[light("glow", (230, 360), 200, 0.35), light("glow", (592, 360), 200, 0.35), light("glow", (954, 360), 200, 0.35)],
      items=[paint("paint_arthur", "arthur", 150, "Arthur", "whole_arthur"),
             paint("paint_vane", "mrs_vane", 512, "Mrs. Vane", "whole_vane"),
             paint("paint_lady", "portrait_lady", 874, "The Lady", "whole_lady"),
             item(id="gallery_wall", kind="secret_door", position=(1060, 120), size=(100, 262),
                  requires_flag="gallery_open", sets_flag="gallery_door")],
      events=["gallery_gate"], glitch=0.5, tilt=1.5, sketch=0.25)

# 4. The Margin: the Ink Shadow's first chase.
frame("ch3_margin", "The Margin", "margin", 0.12, (320, 466),
      ["The margin. Nothing here is drawn properly.", "Something enormous is coming. Run for the door, or hide."],
      "Run (Shift) for the far door. Hide only to dodge a lunge: it scribbles hiding places out.",
      exits=[exit_(GO, "ch3_heart_card", (170, 466), SPLASH)],
      lights=[light("glow", (1110, 300), 220, 0.45), light("glow", (600, 260), 300, 0.3)],
      items=[item(id="margin_curtain", kind="hiding_spot", position=(330, 110), size=(110, 272), text="curtain"),
             item(id="margin_wardrobe", kind="hiding_spot", position=(620, 120), size=(120, 262), text="wardrobe"),
             item(id="margin_table", kind="hiding_spot", position=(880, 300), size=(130, 82), text="table")],
      crawler=(40, 492), crawler_kind="shadow", events=["margin_chase"], glitch=0.75, tilt=-2.0, sketch=0.45)

frame("ch3_heart_card", "The Ink Heart", "margin", 0.15, (170, 466), [], "",
      lights=[light("glow", (300, 300), 300, 0.5)], ending="THE INK HEART: COMING NEXT", glitch=0.9, sketch=0.6)

write("data/chapters/ch3.tres", "chapter_data", dict(
    id=SN("ch3"), title="Chapter 3: The Ink Heart", first_frame_id=SN("ch3_torn_page"),
    damage_visual_scale=1.6, line_jitter=1.6, allows_return=True,
    intro_lines=PSA(["Issue #3.", "The ink is running. The panels won't hold.", "Everyone you took from is still here. Waiting."])))
