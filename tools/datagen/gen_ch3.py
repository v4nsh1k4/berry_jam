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

# 2. The Gallery of Words: a whole comic page of four small panels the
# player hops between (PageSpreadData). Solution: A (Vane and the Portrait
# plead) -> B (dark: light the lens; it throws light down into C and shows a
# lever there) -> drop to C (A's floor tear) -> cross C's gutter tear (jump,
# the torchlit pencil plank, or PUSH A's crate down into it) -> pull the lever
# -> D: say OPEN at the door. Or clear B's ink pool with light and drop into D.
# Minimum words: OPEN. Light puzzles: the lens, the pool, the plank.
SPREAD = page_spread(
    [spread_panel("A", (16, 12, 568, 248), 200, (60, 200), "gallery", 0.75, -1.2, gap=(300, 372)),
     spread_panel("B", (604, 8, 564, 256), 206, (650, 206), "dark_room", 0.0, 1.0),
     spread_panel("C", (16, 282, 548, 234), 456, (60, 456), "torn", 0.5, 0.8, gap=(290, 390), bridge="spread_crate",
                  lit_bridge=True),
     spread_panel("D", (584, 286, 584, 230), 458, (640, 458), "door_room", 0.6, -0.8)],
    [hop("A", "right", "B", (650, 206)), hop("B", "left", "A", (535, 200)),
     hop("A", "fall", "C", (230, 456), zone=(300, 372)),
     hop("C", "jump", "A", (110, 200), zone=(30, 120)),
     hop("C", "right", "D", (640, 458)), hop("D", "left", "C", (520, 456)),
     hop("B", "fall", "D", (1040, 458), zone=(990, 1100), flag="spread_pool"),
     hop("D", "jump", "B", (1040, 206), zone=(990, 1110))])
frame("ch3_gallery_words", "The Gallery of Words", "spread", 0.03, (60, 200),
      ["The page has come apart into panels. Walk off an edge to cross the gutter.",
       "Space: jump. The white between the panels is nothing at all."],
      "Light the glass in the dark panel. Drop through the tear, cross the gutter (jump, or light the pencil plank), "
      "pull the lever, then say OPEN at the last door.",
      exits=[exit_((1050, 390, 110, 90), "ch3_margin", (320, 466), SLIDE, "spread_door")],
      items=[item(id="spread_crate", kind="pushable", position=(420, 120), size=(80, 80), accepted_ability_ids=["push"],
                  sets_flag="spread_crate", push_offset=(-125, 320), prompt="A crate, right by the tear."),
             item(id="spread_lens", kind="lens", position=(690, 24), size=(70, 90), light_hold=1.2, sets_flag="spread_lens",
                  push_offset=(-230, 310), caption="The glass throws the light down through the gutter."),
             item(id="spread_hint", kind="writing", position=(800, 40), size=(320, 70), revealed_by_light=True,
                  text="LIGHT THE GLASS"),
             item(id="spread_pool", kind="light_ink", text="pool", position=(985, 174), size=(120, 46), light_hold=1.6,
                  sets_flag="spread_pool", caption="The ink shrinks from a hole in the floor."),
             item(id="spread_arrow", kind="lit_writing", position=(330, 296), size=(140, 50), requires_flag="spread_lens",
                  text="PULL"),
             item(id="spread_lever", kind="lever", position=(470, 340), size=(50, 90), requires_flag="spread_lens",
                  sets_flag="spread_lever", caption="Far off, in the last panel, a bolt slides back."),
             item(id="spread_door", kind="door", position=(1046, 270), size=(90, 188), accepted_ability_ids=["open"],
                  requires_flag="spread_lever", sets_flag="spread_door",
                  prompt="Bolted from somewhere else. Then it will need a word.")],
      npcs=[owner(**dict(VANE, pos=(130, 200), show_bubbles=False, scale=0.8)),
            owner(**dict(LADY, pos=(250, 130), show_bubbles=False, scale=0.6))],
      glitch=0.2, sketch=0.15, spread=SPREAD, walk=(0, 0, 1184, 528), doodles=True)

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
      ["The Ink Heart. It is holding one last word.", "When its eyes go white, it is listening. Be still.",
       "The ink drinks the light here. Your torch is useless."],
      "Move only while it isn't listening; hide or stand still when its eyes go white. Stand under the word and hold E. "
      "HUSH, WAIT and HIDE make it easier.",
      lights=[light("glow", (860, 170), 170, 0.55), light("glow", (200, 300), 220, 0.3)],
      items=[item(id="heart_curtain", kind="hiding_spot", position=(360, 110), size=(110, 272), text="curtain"),
             item(id="heart_table", kind="hiding_spot", position=(650, 300), size=(130, 82), text="table")],
      npcs=[the_hand("The Shadow")],
      crawler=(1010, 492), patrol=True, crawler_kind="heart", glitch=0.9, tilt=-3.0, sketch=0.55, light_disabled=True)

# ---- After the reveal: the return phase ---------------------------------------

# 5. The Returning Room: everyone you robbed waits here together (the returns
# are batched into one room). Any of an owner's broken bubbles takes their
# word back. The way to the Heart opens when every ordinary word is home.
frame("ch3_returning_room", "The Returning Room", "returning_room", 0.2, (170, 466),
      ["Now you know what you are. Give back what you took.",
       "Select a word (1-6, Q / R), stand under one of its owner's broken bubbles, hold E."],
      "Give each word to its owner: Arthur, Mrs. Vane, the Portrait, the old drawer. When the eraser's shadow falls, step out of it or hide.",
      exits=[exit_(GO, "ch3_heart_return", (160, 466), SPLASH, "all_returned")],
      lights=[light("candle", (600, 288), 320, 0.85), light("glow", (210, 175), 240, 0.4), light("glow", (900, 230), 240, 0.4)],
      items=[item(id="ch3_drawer", kind="return_spot", position=(995, 300), size=(110, 82), owner_id="drawer",
                  text="drawer", sets_flag="whole_drawer", caption="the old drawer"),
             item(id="returning_curtain", kind="hiding_spot", position=(20, 110), size=(100, 272), text="curtain")],
      npcs=[owner(**dict(ARTHUR, pos=(420, 404), bubble_offsets=PV2A([(-150, -205), (-80, -305), (110, -225), (190, -318)]))),
            owner(**dict(VANE, pos=(820, 404), bubble_offsets=PV2A([(-110, -210), (-60, -300), (100, -240)]))),
            owner(**dict(LADY, pos=(210, 160), bubble_offsets=PV2A([(0, -110)])))],
      events=[HAND, "return_gate"], glitch=0.5, tilt=0.6, sketch=0.15)

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
    id=SN("ch3"), title="Chapter 3: The Ink Heart", first_frame_id=SN("ch3_gallery_words"),
    damage_visual_scale=1.6, line_jitter=1.6, allows_return=True, return_frame_id=SN("ch3_returning_room"),
    intro_lines=PSA([])))
