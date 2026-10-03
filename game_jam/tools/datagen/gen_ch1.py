"""Generates Chapter 1 .tres data for INK-BLEED (dev tool, not shipped)."""
from gen_lib import *

LOCK_SYMBOLS = ["eye", "moon", "key"]

# ---- Bubbles -------------------------------------------------------------
OWNER_NAMES = {"arthur": "Arthur", "portrait_lady": "the Portrait", "drawer": "the old drawer"}
for bid, text, ability, owner in [
    ("arthur_open", "OPEN", "open", "arthur"), ("arthur_push", "PUSH", "push", "arthur"),
    ("arthur_wait", "WAIT", "wait", "arthur"), ("arthur_help", "HELP", "help", "arthur"),
    ("portrait_remember", "REMEMBER", "remember", "portrait_lady"), ("drawer_hush", "HUSH", "hush", "drawer"),
]:
    write(f"data/bubbles/{bid}.tres", "bubble_data",
          dict(id=SN(bid), text=text, ability_id=SN(ability), stolen_from=SN(owner), owner_name=OWNER_NAMES[owner]))

# ---- Frames ----------------------------------------------------------------
frame("ch1_awakening", "Awakening", "awakening", 0.1, (230, 470),
      ["You wake. Your speech bubble is empty.", "A/D: walk.   E: look at things."],
      "Look in the mirror if you like. Then walk right, through the door.",
      exits=[exit_((1080, 396, 104, 112), "ch1_bedchamber", (150, 466), SLIDE)],
      lights=[light("candle", (382, 278), 260, 0.85), light("moon", (880, 150), 330, 0.5)],
      items=[item(id="mirror", kind="inspect", position=(580, 120), size=(120, 262),
                  caption="The mirror shows an empty panel where your face should be.")])

frame("ch1_bedchamber", "The Rotted Bedchamber", "bedchamber", 0.09, (150, 466),
      ["Something drips. The window is bleeding ink.", "Across the room, someone waits in the doorway."],
      "The drawer is locked. A word would open it. Arthur has plenty of words.",
      exits=[exit_((0, 396, 80, 112), "ch1_awakening", (980, 466), SLIDE),
             exit_((1080, 396, 104, 112), "ch1_landing", (170, 466), SLIDE)],
      lights=[light("moon", (205, 160), 330, 0.6), light("candle", (370, 258), 240, 0.8)],
      items=[item(id="bedchamber_drawer", kind="drawer", position=(325, 290), size=(90, 90),
                  accepted_ability_ids=["open"], sets_flag="drawer_open",
                  prompt="A locked drawer. It needs a word.", reward_bubble=bubble_ext("drawer_hush"))],
      npcs=[Sub("npc_data", id=SN("arthur_far"), display_name="Arthur", position=V2((1114, 382)),
                visual_style=SN("butler"), scale=0.72)],
      events=["crawler_window"])

frame("ch1_landing", "The Landing", "landing", 0.1, (170, 466),
      ["Arthur the Butler. He is full of words.", "Stand under a word and hold E to take it."],
      "Take OPEN from Arthur. Pick it with 1-6 or Q / R, stand at the study door and press E.",
      exits=[exit_((0, 396, 96, 112), "ch1_bedchamber", (1000, 466), SLIDE),
             exit_((1060, 396, 124, 112), "ch1_study_corridor", (170, 466), SLIDE, "study_door_open")],
      lights=[light("candle", (360, 120), 230, 0.75), light("candle", (580, 120), 230, 0.75), light("candle", (800, 120), 230, 0.75)],
      items=[item(id="study_door", kind="door", position=(1010, 120), size=(130, 262),
                  accepted_ability_ids=["open"], sets_flag="study_door_open",
                  prompt="The study door is locked. Say a word (pick one with 1-6 or Q / R).")],
      npcs=[Sub("npc_data", id=SN("arthur"), display_name="Arthur", position=V2((560, 404)), visual_style=SN("butler"),
                bubbles=TypedArr("bubble_data", [bubble_ext("arthur_open"), bubble_ext("arthur_push"), bubble_ext("arthur_wait"), bubble_ext("arthur_help")]),
                lines=PSA(["Do not {word} the study, sir.", "{word} nothing. Touch nothing.", "{word} here until morning.", "If you need {word}, ring."]),
                broken_lines=PSA(["Do not... the s-study, sir.", "...nothing. T-touch nothing?", "...here. Until. Um.", "If you need... if you..."]),
                reactions=PSA(["Odd. I had a word for that.", "My mouth feels... emptier.", "Sir? Is someone taking my words?", "...", "I... I..."]))])

frame("ch1_study_corridor", "The Study Corridor", "study_corridor", 0.16, (170, 466),
      ["A portrait is muttering to itself."],
      "The portrait still remembers something. Take its word.",
      exits=[exit_((0, 396, 96, 112), "ch1_landing", (960, 466), SLIDE),
             exit_((1080, 396, 104, 112), "ch1_study", (170, 466), SLIDE)],
      lights=[light("candle", (440, 120), 260, 0.8), light("candle", (915, 286), 300, 0.85), light("glow", (190, 220), 260, 0.35)],
      npcs=[Sub("npc_data", id=SN("portrait_lady"), display_name="The Portrait", position=V2((640, 190)), visual_style=SN("portrait"),
                bubbles=TypedArr("bubble_data", [bubble_ext("portrait_remember")]),
                lines=PSA(["{word} me? Anyone?"]), broken_lines=PSA(["...me? A-anyone?"]),
                reactions=PSA(["Now I can't remember who I was."]), reach_y=270.0)],
      events=["ink_hand"])

frame("ch1_study", "The Study", "study", 0.1, (170, 466),
      ["The study. Something is hidden here.", "Three symbols lock the far door."],
      "That cabinet is hiding something. PUSH it, then try to REMEMBER.",
      exits=[exit_((0, 396, 96, 112), "ch1_study_corridor", (980, 466), SLIDE),
             exit_((1080, 396, 104, 112), "ch1_exit", (170, 466), SLIDE, "study_lock_open")],
      lights=[light("candle", (300, 252), 300, 0.85), light("candle", (960, 120), 240, 0.7)],
      items=[item(id="alcove_memory", kind="memory", position=(715, 190), size=(130, 80),
                  requires_flag="cabinet_pushed", symbols=LOCK_SYMBOLS),
             item(id="study_cabinet", kind="pushable", position=(695, 110), size=(170, 272),
                  accepted_ability_ids=["push"], sets_flag="cabinet_pushed", push_offset=(-190, 0),
                  prompt="A heavy cabinet. Far too heavy to move by hand."),
             item(id="study_lock", kind="symbol_lock", position=(1010, 120), size=(130, 262),
                  sets_flag="study_lock_open", symbols=LOCK_SYMBOLS)])

frame("ch1_exit", "The Back Stair", "exit_room", 0.08, (170, 466),
      ["Something lies on the table."],
      "Take the torch from the table. Then leave by the far door.",
      exits=[exit_((0, 396, 96, 112), "ch1_study", (980, 466), SLIDE),
             exit_((1080, 396, 104, 112), "ch1_end", (170, 466), SPLASH, "has_flashlight")],
      lights=[light("moon", (600, 30), 380, 0.55)],
      items=[item(id="flashlight", kind="pickup", position=(530, 290), size=(130, 90), sets_flag="has_flashlight",
                  caption="Light. Use it carefully.   (F or click)")])

frame("ch1_end", "The Hallway", "hallway", 0.12, (170, 466), ["The hallway goes on into the dark."], "",
      lights=[light("glow", (200, 300), 300, 0.5)], next_chapter="res://data/chapters/ch2.tres")

write("data/chapters/ch1.tres", "chapter_data", dict(
    id=SN("ch1"), title="Chapter 1: The Rotted Bedchamber", first_frame_id=SN("ch1_awakening"),
    damage_visual_scale=1.0, line_jitter=1.0,
    intro_lines=PSA(["The Silent House of Hollow Hill.  Issue #1.",
                     "Everyone in this house was drawn with something to say.",
                     "Everyone... except you."])))
