class_name SaveStorage
extends RefCounted

## Minimal byte-storage interface used by SaveService.
##
## Implementations own path mechanics only.  They do not parse JSON, select save
## revisions, mutate runtime state, or derive gameplay values from file metadata.

func exists(path: String) -> bool:
	return false

func read_bytes(path: String) -> Dictionary:
	return {"ok": false, "code": "SAVE_STORAGE_NOT_IMPLEMENTED", "bytes": PackedByteArray()}

func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
	return {"ok": false, "code": "SAVE_STORAGE_NOT_IMPLEMENTED"}

func copy(path_from: String, path_to: String) -> Dictionary:
	return {"ok": false, "code": "SAVE_STORAGE_NOT_IMPLEMENTED"}

func rename(path_from: String, path_to: String) -> Dictionary:
	return {"ok": false, "code": "SAVE_STORAGE_NOT_IMPLEMENTED"}

func remove(path: String) -> Dictionary:
	return {"ok": false, "code": "SAVE_STORAGE_NOT_IMPLEMENTED"}
