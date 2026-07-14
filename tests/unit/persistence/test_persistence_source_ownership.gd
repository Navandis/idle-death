extends GutTest

func test_persistence_does_not_use_local_time_or_steam() -> void:
	var forbidden := ["Time.get", "OS.get_datetime", "FileAccess.get_modified_time", "Steam.", "Steamworks", "steam_appid"]
	for path in _gd_files("res://src/persistence"):
		var text := FileAccess.get_file_as_string(path)
		for token in forbidden:
			assert_false(text.contains(token), "%s must not contain %s" % [path, token])

func _gd_files(root: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var path := root.path_join(name)
		if dir.current_is_dir() and not name.begins_with("."):
			out.append_array(_gd_files(path))
		elif name.ends_with(".gd"):
			out.append(path)
		name = dir.get_next()
	return out
