class_name JsonSaveCodec
extends RefCounted

## Project-owned deterministic JSON_V1 byte codec for primitive save snapshots.
##
## The codec does not know runtime classes and does not decide whether a schema
## is valid gameplay data.  It only converts validated primitive Dictionaries to
## UTF-8 JSON bytes and back, rejecting unsupported Variant types before bytes can
## become a committed save candidate.

const OK := "OK"
const ERR_UNSUPPORTED_VARIANT := "SAVE_CODEC_UNSUPPORTED_VARIANT"
const ERR_JSON_PARSE := "SAVE_CODEC_JSON_PARSE"

func encode(snapshot: Dictionary) -> Dictionary:
	var primitive := _normalize(snapshot)
	if not primitive.ok:
		return primitive
	var text := JSON.stringify(primitive.value, "", false, true)
	return {"ok": true, "code": OK, "bytes": text.to_utf8_buffer()}


func decode(bytes: PackedByteArray) -> Dictionary:
	var text := bytes.get_string_from_utf8()
	var json := JSON.new()
	var err := json.parse(text)
	if err != Error.OK:
		return {"ok": false, "code": ERR_JSON_PARSE, "message": json.get_error_message()}
	var value: Variant = json.data
	if typeof(value) != TYPE_DICTIONARY:
		return {"ok": false, "code": ERR_JSON_PARSE}
	return {"ok": true, "code": OK, "snapshot": value}


func _normalize(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return {"ok": true, "value": value}
		TYPE_DICTIONARY:
			var out := {}
			var keys := (value as Dictionary).keys()
			keys.sort()
			for key in keys:
				if typeof(key) != TYPE_STRING:
					return {"ok": false, "code": ERR_UNSUPPORTED_VARIANT}
				var child := _normalize(value[key])
				if not child.ok:
					return child
				out[key] = child.value
			return {"ok": true, "value": out}
		TYPE_ARRAY:
			var arr := []
			for item in value:
				var child := _normalize(item)
				if not child.ok:
					return child
				arr.append(child.value)
			return {"ok": true, "value": arr}
		_:
			return {"ok": false, "code": ERR_UNSUPPORTED_VARIANT}
