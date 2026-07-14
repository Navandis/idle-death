extends GutTest

## Focused source-ownership check for M01 authoritative time boundaries.
## It rejects local wall-clock and file-timestamp APIs in authoritative source
## while allowing the single process-monotonic adapter to call Time.get_ticks_msec.

const ALLOWED_TICKS_FILE := "res://src/platform/time/process_monotonic_clock.gd"
const SCAN_ROOTS := ["res://src/domain", "res://src/simulation", "res://src/platform/time"]
const FORBIDDEN_PATTERNS := ["Time.get_unix_time", "Time.get_datetime", "FileAccess.get_modified_time", "DirAccess.get_modified_time"]

func test_authoritative_sources_do_not_read_wall_clock_or_file_time() -> void:
	for root in SCAN_ROOTS:
		_scan_directory(root)

func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	assert_not_null(dir, "scan root exists: %s" % path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var child := path.path_join(name)
		if dir.current_is_dir():
			_scan_directory(child)
		elif name.ends_with(".gd"):
			_check_file(child)
		name = dir.get_next()
	dir.list_dir_end()

func _check_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	for pattern in FORBIDDEN_PATTERNS:
		assert_eq(text.find(pattern), -1, "%s must not contain %s" % [path, pattern])
	if path != ALLOWED_TICKS_FILE:
		assert_eq(text.find("Time.get_ticks_msec"), -1, "%s must not read the monotonic adapter directly" % path)
