"""Shared helpers for INK-BLEED .tres generators (dev tool, not shipped)."""
import os, sys
ROOT = sys.argv[1]

class SN(str): pass                     # StringName
class V2(tuple): pass
class R2(tuple): pass
class Sub:                              # sub-resource
    def __init__(self, script, **props): self.script, self.props = script, props
class Ext:                              # external resource path
    def __init__(self, path, type_="Resource"): self.path, self.type = path, type_
class TypedArr:
    def __init__(self, script, items): self.script, self.items = script, items
class SNArr(list): pass
class PSA(list): pass                   # PackedStringArray
class PV2A(list): pass

SCRIPTS = {k: f"res://scripts/data/{k}.gd" for k in
           ["frame_data", "exit_data", "interactable_data", "npc_data", "bubble_data", "light_spot_data", "chapter_data"]}
CLASS = {"frame_data": "FrameData", "bubble_data": "BubbleData", "chapter_data": "ChapterData"}

def q(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

class Writer:
    def __init__(self): self.ext, self.subs, self.n = {}, [], 0
    def ext_id(self, path, type_):
        if path not in self.ext: self.ext[path] = (f"{len(self.ext)+1}_{os.path.basename(path).split('.')[0]}", type_)
        return self.ext[path][0]
    def val(self, v):
        if isinstance(v, bool): return "true" if v else "false"
        if isinstance(v, SN): return "&" + q(v)
        if isinstance(v, str): return q(v)
        if isinstance(v, (int, float)): return repr(float(v)) if isinstance(v, float) else str(v)
        if isinstance(v, V2): return f"Vector2({v[0]}, {v[1]})"
        if isinstance(v, R2): return f"Rect2({v[0]}, {v[1]}, {v[2]}, {v[3]})"
        if isinstance(v, Ext): return f'ExtResource("{self.ext_id(v.path, v.type)}")'
        if isinstance(v, Sub): return f'SubResource("{self.sub(v)}")'
        if isinstance(v, TypedArr):
            sid = self.ext_id(SCRIPTS[v.script], "Script")
            return f'Array[ExtResource("{sid}")]([' + ", ".join(self.val(i) for i in v.items) + "])"
        if isinstance(v, SNArr): return "Array[StringName]([" + ", ".join("&" + q(i) for i in v) + "])"
        if isinstance(v, PSA): return "PackedStringArray(" + ", ".join(q(i) for i in v) + ")"
        if isinstance(v, PV2A): return "PackedVector2Array(" + ", ".join(f"{a}, {b}" for a, b in v) + ")"
        raise TypeError(v)
    def body(self, script, props):
        sid = self.ext_id(SCRIPTS[script], "Script")
        lines = [f'script = ExtResource("{sid}")']
        lines += [f"{k} = {self.val(v)}" for k, v in props.items()]
        return "\n".join(lines)
    def sub(self, s):
        self.n += 1
        sid = f"Resource_{self.n}"
        self.subs.append((sid, self.body(s.script, s.props)))
        return sid
    def render(self, script, props):
        main = self.body(script, props)
        out = [f'[gd_resource type="Resource" script_class="{CLASS[script]}" load_steps={len(self.ext)+len(self.subs)+1} format=3]', ""]
        for path, (eid, type_) in self.ext.items():
            out.append(f'[ext_resource type="{type_}" path="{path}" id="{eid}"]')
        out.append("")
        for sid, b in self.subs:
            out += [f'[sub_resource type="Resource" id="{sid}"]', b, ""]
        out += ["[resource]", main, ""]
        return "\n".join(out)

def write(rel, script, props):
    path = os.path.join(ROOT, rel)
    with open(path, "w") as f: f.write(Writer().render(script, props))
    print("wrote", rel)

def bubble_ext(name): return Ext(f"res://data/bubbles/{name}.tres")
def exit_(area, target, spawn=None, style=0, flag=""):
    p = dict(area=R2(area), target_frame_id=SN(target), transition_style=style)
    if spawn: p["target_spawn"] = V2(spawn)
    if flag: p["required_flag"] = SN(flag)
    return Sub("exit_data", **p)
def light(kind, pos, radius, energy):
    return Sub("light_spot_data", kind=SN(kind), position=V2(pos), radius=float(radius), energy=float(energy))
def item(**p):
    for k in ("id", "kind", "sets_flag", "requires_flag", "owner_id"):
        if k in p: p[k] = SN(p[k])
    for k in ("position", "size", "push_offset"):
        if k in p: p[k] = V2(p[k])
    if "accepted_ability_ids" in p: p["accepted_ability_ids"] = SNArr(p["accepted_ability_ids"])
    if "symbols" in p: p["symbols"] = PSA(p["symbols"])
    if "reward_bubble" in p and isinstance(p["reward_bubble"], str): p["reward_bubble"] = bubble_ext(p["reward_bubble"])
    return Sub("interactable_data", **p)
def frame(fid, name, style, ambient, spawn, captions, hint, exits=(), lights=(), items=(), npcs=(), events=(), ending="",
          next_chapter="", crawler=None, patrol=False, glitch=0.0, tilt=0.0, sketch=0.0, crawler_kind=""):
    p = dict(id=SN(fid), display_name=name, ambient_light=float(ambient), background_style=SN(style),
             player_spawn=V2(spawn), walk_area=R2((40, 400, 1104, 104)), captions=PSA(captions), hint=hint)
    if exits: p["exits"] = TypedArr("exit_data", list(exits))
    if items: p["interactables"] = TypedArr("interactable_data", list(items))
    if npcs: p["npcs"] = TypedArr("npc_data", list(npcs))
    if lights: p["lights"] = TypedArr("light_spot_data", list(lights))
    if events: p["events"] = SNArr(events)
    if ending: p["ending_card"] = ending
    if next_chapter: p["next_chapter"] = Ext(next_chapter)
    if crawler: p["crawler_spawn"] = V2(crawler)
    if patrol: p["crawler_patrol"] = True
    if glitch: p["glitch"] = float(glitch)
    if tilt: p["panel_tilt"] = float(tilt)
    if sketch: p["sketch"] = float(sketch)
    if crawler_kind: p["crawler_kind"] = SN(crawler_kind)
    write(f"data/frames/{fid}.tres", "frame_data", p)

SLIDE, SPLASH = 0, 1
