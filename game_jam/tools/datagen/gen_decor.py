"""Stage 6 room decor (RoomDecor), merged into frame() by gen_lib, per frame id.
webs: (x, y, size, angle deg): a cobweb fanned over 90 deg from `angle` at an
anchor (no light of their own: room light and the torch show them;
0 = opens right/down from a top-left corner, 90 = down/left from a
top-right corner, -90 = up/right from a furniture edge).
eyes: (x, y, pairs): pale watching eyes in a dark corner.
Panel coordinates (1184 x 528). Kept clear of objects, clues, exits and the
page spread's lit puzzle areas (the spread has none). Heavier in Chapter 2,
a few in Chapter 1, very few in Chapter 3."""

DECOR = {
    # Chapter 1
    "ch1_bedchamber": dict(webs=[(0, 0, 120, 0)], eyes=[(1120, 70, 2)]),
    "ch1_study": dict(webs=[(0, 0, 105, 0)]),
    "ch1_exit": dict(webs=[(1184, 0, 140, 90)], eyes=[(84, 80, 1)]),
    # Chapter 2
    "ch2_long_hallway": dict(webs=[(0, 0, 120, 0), (1184, 0, 110, 90)], eyes=[(96, 70, 2)]),
    "ch2_gallery": dict(webs=[(0, 0, 100, 0)], eyes=[(1110, 70, 3)]),
    "ch2_servants_passage": dict(webs=[(0, 0, 130, 0), (1184, 0, 120, 90), (452, 122, 70, -90)], eyes=[(1000, 62, 3)]),
    "ch2_pantry": dict(webs=[(1184, 0, 110, 90)]),
    "ch2_clock_room": dict(webs=[(0, 0, 120, 0)], eyes=[(1110, 70, 2)]),
    "ch2_cellar": dict(webs=[(0, 0, 140, 0), (1184, 0, 100, 90)], eyes=[(90, 96, 3)]),
    "ch2_end": dict(webs=[(0, 0, 120, 0)], eyes=[(1100, 110, 2)]),
    # Chapter 3
    "ch3_margin": dict(eyes=[(1110, 70, 1)]),
}
