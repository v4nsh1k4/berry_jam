"""Generates Chapter 2 .tres data for INK-BLEED (dev tool, not shipped)."""
from gen_lib import *

CLOCK = ["spiral", "hand", "house"]
GO = (1080, 396, 104, 112)
BACK = (0, 396, 96, 112)

for bid, text, ability in [("vane_hide", "HIDE", "hide"), ("vane_hush", "HUSH", "hush"), ("vane_wait", "WAIT", "wait")]:
    write(f"data/bubbles/{bid}.tres", "bubble_data",
          dict(id=SN(bid), text=text, ability_id=SN(ability), stolen_from=SN("mrs_vane")))

frame("ch2_long_hallway", "The Long Hallway", "long_hallway", 0.045, (150, 466),
      ["The house is darker here. Your torch is all you have.",
       "F or click: flashlight, aimed with the mouse. Light shows what the dark hides."],
      "Shine the light along the walls. Something at the far end opens with a word.",
      exits=[exit_(GO, "ch2_gallery", (150, 466), SLIDE, "hall_panel_open")],
      lights=[light("glow", (150, 300), 220, 0.35)],
      items=[item(id="hall_writing", kind="writing", position=(300, 110), size=(560, 80), revealed_by_light=True,
                  text="SHE KEEPS THE KEYS.\nHE KEEPS THE TIME."),
             item(id="hall_latch", kind="latch", position=(950, 300), size=(60, 60), revealed_by_light=True,
                  accepted_ability_ids=["open"], sets_flag="hall_panel_open", prompt="A hidden latch. It needs a word."),
             item(id="hall_panel", kind="secret_door", position=(1060, 120), size=(100, 262),
                  requires_flag="hall_panel_open", sets_flag="hall_panel_door")])

frame("ch2_gallery", "The Portrait Gallery", "gallery", 0.05, (150, 466),
      ["Something sleeps in the far corner.", "Light wakes it. In the dark, walking is safe. Running (Shift) is not."],
      "Turn the light off and walk past it slowly. If it rises, stand still in the dark.",
      exits=[exit_(BACK, "ch2_long_hallway", (980, 466), SLIDE), exit_(GO, "ch2_servants_passage", (170, 466), SLIDE)],
      lights=[light("glow", (120, 300), 220, 0.35), light("glow", (1130, 300), 180, 0.35)],
      items=[item(id="gallery_plaque", kind="writing", position=(470, 228), size=(300, 40), revealed_by_light=True,
                  text="DON'T LOOK AT IT.")],
      crawler=(980, 492))

frame("ch2_servants_passage", "The Servants' Passage", "passage", 0.06, (190, 466),
      ["The servants' passage. Narrow. Places to hide."],
      "When it comes, press E at the wardrobe, curtain or table to hide. Come out when it has gone.",
      exits=[exit_(BACK, "ch2_gallery", (980, 466), SLIDE), exit_(GO, "ch2_pantry", (170, 466), SLIDE)],
      lights=[light("glow", (620, 260), 240, 0.4)],
      items=[item(id="passage_wardrobe", kind="hiding_spot", position=(330, 120), size=(120, 262), text="wardrobe"),
             item(id="passage_curtain", kind="hiding_spot", position=(640, 110), size=(110, 272), text="curtain"),
             item(id="passage_table", kind="hiding_spot", position=(880, 300), size=(130, 82), text="table")],
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
       "It patrols here. Light lets you read the clock, and lets it find you."],
      "Say HUSH or WAIT first, then light the clock face for a moment. Or hide behind the curtain afterwards.",
      exits=[exit_(BACK, "ch2_pantry", (980, 466), SLIDE), exit_(GO, "ch2_cellar", (200, 466), SLIDE)],
      lights=[light("glow", (120, 300), 180, 0.3), light("glow", (1130, 300), 180, 0.3)],
      items=[item(id="grandfather_clock", kind="clock", position=(540, 70), size=(120, 310), revealed_by_light=True,
                  symbols=CLOCK, sets_flag="clock_read"),
             item(id="clock_curtain", kind="hiding_spot", position=(230, 110), size=(130, 272), text="curtain")],
      crawler=(980, 492), patrol=True)

frame("ch2_cellar", "The Locked Cellar Stair", "cellar_stair", 0.06, (200, 466),
      ["The cellar stair. Three dials, then a padlock."],
      "Set the dials to the clock's three marks (REMEMBER shows them again), then say OPEN to the padlock. Then go.",
      exits=[exit_(BACK, "ch2_clock_room", (980, 466), SLIDE), exit_(GO, "ch2_end", (170, 466), SPLASH, "cellar_open")],
      lights=[light("glow", (860, 220), 220, 0.45), light("glow", (140, 300), 180, 0.3)],
      items=[item(id="cellar_memory", kind="memory", position=(400, 150), size=(150, 80), requires_flag="clock_read", symbols=CLOCK),
             item(id="cellar_dials", kind="symbol_lock", position=(800, 262), size=(120, 70), symbols=CLOCK,
                  sets_flag="cellar_dials_set", text="panel"),
             item(id="cellar_door", kind="door", position=(1010, 120), size=(130, 262), accepted_ability_ids=["open"],
                  requires_flag="cellar_dials_set", sets_flag="cellar_open",
                  prompt="Padlocked. The dials beside it are not set yet.")],
      crawler=(60, 492), events=["cellar_chase"])

frame("ch2_end", "The Cellar", "cellar_stair", 0.08, (170, 466), ["At the bottom of the stair, the page is wet."], "",
      lights=[light("glow", (300, 300), 300, 0.45)], next_chapter="res://data/chapters/ch3.tres")

write("data/chapters/ch2.tres", "chapter_data", dict(
    id=SN("ch2"), title="Chapter 2: The Hallway of Shadows", first_frame_id=SN("ch2_long_hallway"),
    damage_visual_scale=1.3, line_jitter=1.35,
    intro_lines=PSA(["Issue #2.", "The house has noticed the one without words.", "Somewhere below, ink is moving."])))
