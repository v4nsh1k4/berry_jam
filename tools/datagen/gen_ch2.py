"""Generates Chapter 2 .tres data for INK-BLEED (dev tool, not shipped)."""
from gen_lib import *

# The clock face's marks, clockwise from twelve (the answer). Read left to
# right they would be house, hand, spiral: the hallway clue gives the order.
CLOCK = ["hand", "spiral", "house"]
GO = (1080, 396, 104, 112)
BACK = (0, 396, 96, 112)

for bid, text, ability in [("vane_hide", "HIDE", "hide"), ("vane_hush", "HUSH", "hush"), ("vane_wait", "WAIT", "wait")]:
    write(f"data/bubbles/{bid}.tres", "bubble_data",
          dict(id=SN(bid), text=text, ability_id=SN(ability), stolen_from=SN("mrs_vane"), owner_name="Mrs. Vane"))

frame("ch2_long_hallway", "The Long Hallway", "long_hallway", 0.045, (150, 466),
      ["The house is darker here. Your torch is all you have.",
       "F or click: flashlight, aimed with the mouse. Ink shrinks from the light."],
      "Shine the light on the ink over the far door and hold it there until it shrinks away.",
      exits=[exit_(GO, "ch2_gallery", (150, 466), SLIDE, "hall_panel_open")],
      lights=[light("glow", (150, 300), 220, 0.35)],
      items=[item(id="hall_writing", kind="writing", position=(170, 100), size=(820, 80), revealed_by_light=True,
                  text="MRS. VANE KEEPS THE CELLAR KEY AS A SHADOW.\nREAD ARTHUR'S CLOCK FROM XII, CLOCKWISE."),
             item(id="hall_ink", kind="light_ink", text="door", position=(1050, 120), size=(120, 270), light_hold=1.6,
                  sets_flag="hall_panel_open", caption="The ink shrinks from the light. The way is open.")], doodles=True)

frame("ch2_gallery", "The Portrait Gallery", "gallery", 0.05, (150, 466),
      ["Something sleeps by the far door. The door has no handle.",
       "Sweep the light along the walls to find a way, but light wakes it. Walk, don't run."],
      "Sweep the light along the walls (in short bursts) to find the lever, pull it with E, then walk past it in the dark.",
      exits=[exit_(BACK, "ch2_long_hallway", (980, 466), SLIDE), exit_(GO, "ch2_servants_passage", (170, 466), SLIDE, "gallery_lever")],
      lights=[light("glow", (120, 300), 220, 0.35), light("glow", (1130, 300), 180, 0.35)],
      items=[item(id="gallery_plaque", kind="writing", position=(440, 196), size=(520, 76), revealed_by_light=True,
                  text="THE BOLT IS UNDER THE SECOND FRAME.\nDON'T LIGHT THE SLEEPER."),
             item(id="gallery_lever", kind="lever", position=(330, 270), size=(60, 100), revealed_by_light=True,
                  sets_flag="gallery_lever", caption="Somewhere by the far door, a bolt slides back.")],
      crawler=(980, 492))

frame("ch2_servants_passage", "The Servants' Passage", "passage", 0.06, (190, 466),
      ["The servants' passage. Narrow. Places to hide.",
       "Ink has grown over the far door. It shrinks from light, and creeps back in the dark."],
      "When it comes, hide (E at the wardrobe, curtain or table). Once it has gone, hold the light on the growth until it burns away.",
      exits=[exit_(BACK, "ch2_gallery", (980, 466), SLIDE), exit_(GO, "ch2_pantry", (170, 466), SLIDE, "passage_burned")],
      lights=[light("glow", (620, 260), 240, 0.4)],
      items=[item(id="passage_wardrobe", kind="hiding_spot", position=(330, 120), size=(120, 262), text="wardrobe"),
             item(id="passage_curtain", kind="hiding_spot", position=(640, 110), size=(110, 272), text="curtain"),
             item(id="passage_table", kind="hiding_spot", position=(880, 300), size=(130, 82), text="table"),
             item(id="passage_growth", kind="light_ink", text="growth", position=(1060, 250), size=(124, 260), light_hold=2.0,
                  sets_flag="passage_burned", caption="The growth curls up and flakes away.")],
      crawler=(70, 492), events=["passage_stalker"])

frame("ch2_pantry", "The Housekeeper's Pantry", "pantry", 0.1, (170, 466),
      ["Mrs. Vane, the housekeeper. She keeps looking at the dark.", "Stand under a word and hold E to take it."],
      "Take HIDE, HUSH and WAIT from Mrs. Vane. The clock room will test you.",
      exits=[exit_(BACK, "ch2_servants_passage", (980, 466), SLIDE), exit_(GO, "ch2_clock_room", (170, 466), SLIDE)],
      lights=[light("candle", (715, 280), 300, 0.85), light("glow", (1000, 240), 200, 0.3)],
      npcs=[Sub("npc_data", id=SN("mrs_vane"), display_name="Mrs. Vane", position=V2((560, 404)), visual_style=SN("housekeeper"),
                bubbles=TypedArr("bubble_data", [bubble_ext("vane_hide"), bubble_ext("vane_hush"), bubble_ext("vane_wait")]),
                lines=PSA(["{word} in here, quickly!", "{word} now, child. It listens.", "{word} for the clock to strike."]),
                broken_lines=PSA(["...in here, q-quickly!", "...now. It l-l-listens.", "...for the c-clock to..."]),
                reactions=PSA(["My words... where did they go?", "Child, you are making it worse.", "It comes for the ones who talk."]))],
      events=["crawler_fingers"])

frame("ch2_clock_room", "The Clock Room", "clock_room", 0.05, (170, 466),
      ["The clock has no hands. Its face only shows in the light.",
       "It patrols here. The far door is bolted to the clock's dial box."],
      "Light the clock face (WAIT on the pendulum holds the marks still), then set the dial box: read the marks from XII, clockwise.",
      exits=[exit_(BACK, "ch2_pantry", (980, 466), SLIDE), exit_(GO, "ch2_cellar", (200, 466), SLIDE, "clock_solved")],
      lights=[light("glow", (120, 300), 180, 0.3), light("glow", (1130, 300), 180, 0.3)],
      items=[item(id="grandfather_clock", kind="clock", position=(540, 70), size=(120, 310), revealed_by_light=True,
                  symbols=CLOCK, sets_flag="clock_read",
                  caption="Three marks on the face. The dial box beside the clock wants them, in the right order."),
             item(id="clock_dials", kind="symbol_lock", text="panel", position=(690, 262), size=(110, 64), symbols=CLOCK,
                  sets_flag="clock_solved", caption="THE CLOCK'S MARKS"),
             item(id="clock_curtain", kind="hiding_spot", position=(230, 110), size=(130, 272), text="curtain")],
      crawler=(980, 492), patrol=True)

frame("ch2_cellar", "The Locked Cellar Stair", "cellar_stair", 0.06, (200, 466),
      ["The cellar stair. A padlock, and a keyhole drawn on the wall.",
       "Light makes shadows here. Stand on the chalk mark."],
      "Stand on the chalk X and light the iron key until its shadow fits the outline. Then say OPEN to the padlock, and run.",
      exits=[exit_(BACK, "ch2_clock_room", (980, 466), SLIDE), exit_(GO, "ch2_end", (170, 466), SPLASH, "cellar_open")],
      lights=[light("glow", (860, 220), 220, 0.45), light("glow", (140, 300), 180, 0.3)],
      items=[item(id="cellar_shadow", kind="shadow_puzzle", position=(620, 250), size=(80, 140), symbols=["key"],
                  stand_spot=(380, 410, 120, 100), light_hold=1.2, sets_flag="cellar_dials_set",
                  caption="The shadow fits the keyhole. The padlock clicks loose."),
             item(id="cellar_door", kind="door", position=(1010, 120), size=(130, 262), accepted_ability_ids=["open"],
                  requires_flag="cellar_dials_set", sets_flag="cellar_open",
                  prompt="Padlocked. The keyhole on the wall is still empty.")],
      crawler=(60, 492), events=["cellar_chase"])

frame("ch2_end", "The Cellar", "cellar_stair", 0.08, (170, 466), ["At the bottom of the stair, the page is wet."], "",
      lights=[light("glow", (300, 300), 300, 0.45)], next_chapter="res://data/chapters/ch3.tres")

write("data/chapters/ch2.tres", "chapter_data", dict(
    id=SN("ch2"), title="Chapter 2: The Hallway of Shadows", first_frame_id=SN("ch2_long_hallway"),
    damage_visual_scale=1.3, line_jitter=1.35,
    intro_lines=PSA([])))
