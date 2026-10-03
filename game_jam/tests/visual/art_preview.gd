extends SceneTree
## Dev tool: renders a piece of procedural art to a PNG, to look at it.
##   godot --path . --resolution 1280x720 --script res://tests/visual/art_preview.gd -- --draw="<gdscript body>" --out=/x.png
## The body runs inside _draw() of a Node2D with `ci` = self and `t` = 0.

func _initialize() -> void:
	var body: String = ""
	var out: String = "/tmp/preview.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--draw="):
			body = arg.trim_prefix("--draw=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var script: GDScript = GDScript.new()
	script.source_code = "extends Node2D\nfunc _draw() -> void:\n\tvar ci: Node2D = self\n\tdraw_rect(Rect2(0, 0, 1280, 720), InkDraw.PAPER)\n\t" + body.replace(";", "\n\t") + "\n"
	script.reload()
	var node: Node2D = Node2D.new()
	node.set_script(script)
	root.add_child(node)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
