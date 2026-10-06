extends SceneTree
## Dev check: loads every script under res:// (except tests/tools) so parse
## and type errors show up. Prints COMPILE CHECK DONE.
##   godot --headless --path . --script res://tests/compile_check.gd

func _initialize() -> void:
	_scan("res://")
	print("COMPILE CHECK DONE")
	quit()


func _scan(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	for sub in dir.get_directories():
		# Folders with a .gdignore (local tools) are not part of the project.
		if not sub.begins_with(".") and sub not in ["tests", "tools", "build", "addons"] \
				and not FileAccess.file_exists(dir_path.path_join(sub).path_join(".gdignore")):
			_scan(dir_path.path_join(sub))
	for file in dir.get_files():
		if file.ends_with(".gd"):
			var script: GDScript = load(dir_path.path_join(file)) as GDScript
			if script == null or not script.can_instantiate():
				print("FAILED: ", dir_path.path_join(file))
