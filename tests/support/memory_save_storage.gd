class_name MemorySaveStorage
extends SaveStorage

## In-memory storage with deterministic failure injection for persistence tests.

var files := {}
var fail_next := ""

func fail_once(operation: String) -> void:
	fail_next = operation

func exists(path: String) -> bool:
	return files.has(path)

func read_bytes(path: String) -> Dictionary:
	if _consume("read"):
		return {"ok": false, "code": "MEMORY_READ_FAIL", "bytes": PackedByteArray()}
	if not files.has(path):
		return {"ok": false, "code": "MEMORY_MISSING", "bytes": PackedByteArray()}
	return {"ok": true, "code": "OK", "bytes": files[path]}

func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
	if _consume("write"):
		return {"ok": false, "code": "MEMORY_WRITE_FAIL"}
	files[path] = bytes.duplicate()
	return {"ok": true, "code": "OK"}

func copy(path_from: String, path_to: String) -> Dictionary:
	if _consume("copy"):
		return {"ok": false, "code": "MEMORY_COPY_FAIL"}
	if not files.has(path_from):
		return {"ok": false, "code": "MEMORY_MISSING"}
	files[path_to] = files[path_from].duplicate()
	return {"ok": true, "code": "OK"}

func rename(path_from: String, path_to: String) -> Dictionary:
	if _consume("rename"):
		return {"ok": false, "code": "MEMORY_RENAME_FAIL"}
	if not files.has(path_from):
		return {"ok": false, "code": "MEMORY_MISSING"}
	files[path_to] = files[path_from]
	files.erase(path_from)
	return {"ok": true, "code": "OK"}

func remove(path: String) -> Dictionary:
	files.erase(path)
	return {"ok": true, "code": "OK"}

func _consume(operation: String) -> bool:
	if fail_next == operation:
		fail_next = ""
		return true
	return false
