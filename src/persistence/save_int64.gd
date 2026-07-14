class_name SaveInt64
extends RefCounted

## Canonical signed 64-bit decimal-string conversion for save data.
##
## The persistence layer uses this helper at the JSON boundary so authoritative
## integer values never pass through JSON's floating-point number handling.  The
## class owns no gameplay state and performs no time reads; callers provide the
## field path so validation errors can identify the exact schema field.

const OK := "OK"
const ERR_NOT_STRING := "SAVE_INT_NOT_STRING"
const ERR_EMPTY := "SAVE_INT_EMPTY"
const ERR_PLUS := "SAVE_INT_PLUS_SIGN"
const ERR_WHITESPACE := "SAVE_INT_WHITESPACE"
const ERR_MALFORMED := "SAVE_INT_MALFORMED"
const ERR_LEADING_ZERO := "SAVE_INT_LEADING_ZERO"
const ERR_NEGATIVE_DISALLOWED := "SAVE_INT_NEGATIVE_DISALLOWED"
const ERR_OUT_OF_RANGE := "SAVE_INT_OUT_OF_RANGE"
const INT64_MAX_TEXT := "9223372036854775807"
const INT64_MIN_ABS_TEXT := "9223372036854775808"
const INT64_MAX := 9223372036854775807
const INT64_MIN := -9223372036854775807 - 1

static func format(value: int) -> String:
	return str(value)


static func parse(value: Variant, allow_negative: bool, field_path: String = "") -> Dictionary:
	if typeof(value) != TYPE_STRING:
		return _err(ERR_NOT_STRING, field_path)
	var text := value as String
	if text.is_empty():
		return _err(ERR_EMPTY, field_path)
	if text.strip_edges() != text:
		return _err(ERR_WHITESPACE, field_path)
	if text.begins_with("+"):
		return _err(ERR_PLUS, field_path)
	var negative := text.begins_with("-")
	var digits := text.substr(1) if negative else text
	if negative and not allow_negative:
		return _err(ERR_NEGATIVE_DISALLOWED, field_path)
	if digits.is_empty():
		return _err(ERR_MALFORMED, field_path)
	if digits.length() > 1 and digits.begins_with("0"):
		return _err(ERR_LEADING_ZERO, field_path)
	if negative and digits == "0":
		return _err(ERR_LEADING_ZERO, field_path)
	for index in digits.length():
		var code := digits.unicode_at(index)
		if code < 48 or code > 57:
			return _err(ERR_MALFORMED, field_path)
	var limit := INT64_MIN_ABS_TEXT if negative else INT64_MAX_TEXT
	if digits.length() > limit.length() or (digits.length() == limit.length() and digits > limit):
		return _err(ERR_OUT_OF_RANGE, field_path)
	var parsed: int = 0
	for index in digits.length():
		parsed = parsed * 10 + int(digits[index])
	if negative:
		parsed = -parsed
	return {"ok": true, "code": OK, "value": parsed, "field_path": field_path}


static func _err(code: String, field_path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": field_path, "value": 0}
