class_name FileSaveStorage
extends SaveStorage

## Godot FileAccess/DirAccess implementation of SaveStorage.
##
## This class owns only byte-level filesystem operations.  It never consults file
## modification timestamps and never interprets save contents; SaveService handles
## validation before asking this class to replace files.

const OK := "OK"
const ERR_OPEN := "SAVE_FILE_OPEN_FAILED"
const ERR_WRITE := "SAVE_FILE_WRITE_FAILED"
const ERR_READ := "SAVE_FILE_READ_FAILED"
const ERR_COPY := "SAVE_FILE_COPY_FAILED"
const ERR_RENAME := "SAVE_FILE_RENAME_FAILED"
const ERR_REMOVE := "SAVE_FILE_REMOVE_FAILED"

func exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func read_bytes(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "code": ERR_OPEN, "path": path, "bytes": PackedByteArray()}
	var bytes := file.get_buffer(file.get_length())
	return {"ok": true, "code": OK, "path": path, "bytes": bytes}

func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
	_ensure_parent(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "code": ERR_OPEN, "path": path}
	file.store_buffer(bytes)
	file.flush()
	if file.get_error() != Error.OK:
		return {"ok": false, "code": ERR_WRITE, "path": path}
	return {"ok": true, "code": OK, "path": path}

func copy(path_from: String, path_to: String) -> Dictionary:
	_ensure_parent(path_to)
	var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(path_from), ProjectSettings.globalize_path(path_to))
	return {"ok": err == Error.OK, "code": OK if err == Error.OK else ERR_COPY, "from": path_from, "to": path_to}

func rename(path_from: String, path_to: String) -> Dictionary:
	_ensure_parent(path_to)
	if exists(path_to):
		var remove_result := remove(path_to)
		if not remove_result.ok:
			return remove_result
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(path_from), ProjectSettings.globalize_path(path_to))
	return {"ok": err == Error.OK, "code": OK if err == Error.OK else ERR_RENAME, "from": path_from, "to": path_to}

func remove(path: String) -> Dictionary:
	if not exists(path):
		return {"ok": true, "code": OK, "path": path}
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return {"ok": err == Error.OK, "code": OK if err == Error.OK else ERR_REMOVE, "path": path}

func _ensure_parent(path: String) -> void:
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
