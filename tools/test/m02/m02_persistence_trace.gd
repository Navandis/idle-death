extends SceneTree

## Headless M02 real-file trace used by Codex and owner verification.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var root := ""
	for i in range(args.size()):
		if args[i] == "--save-root" and i + 1 < args.size():
			root = args[i + 1]
	if root.is_empty():
		printerr("M02_TRACE_FAIL missing --save-root")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
	var files := SaveFileSet.new(root, "trace")
	var service := SaveService.new(FileSaveStorage.new(), files)
	_check(service.save_runtime(GameState.new(100), TimeAuthorityState.new(), 1).ok, "revision 1 written")
	_check(service.save_runtime(GameState.new(200), TimeAuthorityState.new(), 2).ok, "revision 2 written")
	_check(FileAccess.file_exists(files.backup_path), "backup revision 1 exists")
	var storage := FileSaveStorage.new()
	var corrupt := "{corrupt-primary".to_utf8_buffer()
	_check(storage.write_bytes(files.primary_path, corrupt).ok, "primary corrupted")
	var loaded := service.load_runtime()
	_check(loaded.ok, "fallback load ok")
	_check(loaded.save_revision == 1, "backup revision selected")
	_check(loaded.selected_role == "backup", "backup role selected")
	_check(storage.read_bytes(files.primary_path).bytes == corrupt, "corrupt primary retained")
	print("M02_TRACE_PASS selected_revision=%s rejected_primary=%s retained_corrupt_primary=true" % [loaded.save_revision, loaded.diagnostics[0].code])
	quit(0)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("M02_TRACE_OK " + label)
	else:
		printerr("M02_TRACE_FAIL " + label)
		quit(1)
