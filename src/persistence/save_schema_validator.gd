class_name SaveSchemaValidator
extends RefCounted

## Validates primitive schema dictionaries before runtime construction or commit.
##
## Validation deliberately happens outside the byte codec.  The codec proves that
## bytes are JSON and primitive values; this class proves those primitives match
## Death Idle's schema, integer-string rules, and cross-field invariants.

const OK := "OK"
const ERR_NOT_DICTIONARY := "SAVE_SCHEMA_NOT_DICTIONARY"
const ERR_KEY_SET := "SAVE_SCHEMA_KEY_SET"
const ERR_CODEC := "SAVE_SCHEMA_UNSUPPORTED_CODEC"
const ERR_SCHEMA_VERSION := "SAVE_SCHEMA_UNSUPPORTED_VERSION"
const ERR_CONTENT_REVISION := "SAVE_SCHEMA_CONTENT_REVISION"
const ERR_TYPE := "SAVE_SCHEMA_TYPE"
const ERR_CROSS_FIELD := "SAVE_SCHEMA_CROSS_FIELD"
const ERR_ABSOLUTE_PATH := "SAVE_SCHEMA_ABSOLUTE_PATH"

static func validate_v1(snapshot: Variant) -> Dictionary:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return _err(ERR_NOT_DICTIONARY, "")
	var data: Dictionary = snapshot
	var keys_result := _require_keys(data, SaveEnvelope.TOP_LEVEL_KEYS, "")
	if not keys_result.ok:
		return keys_result
	if data.codec_id != SaveEnvelope.CODEC_JSON_V1:
		return _err(ERR_CODEC, "codec_id")
	var schema := SaveInt64.parse(data.schema_version, false, "schema_version")
	if not schema.ok:
		return schema
	if schema.value != SaveEnvelope.CURRENT_SCHEMA_VERSION:
		return _err(ERR_SCHEMA_VERSION, "schema_version")
	var revision := SaveInt64.parse(data.save_revision, false, "save_revision")
	if not revision.ok:
		return revision
	if typeof(data.content_revision) != TYPE_STRING or (data.content_revision as String).is_empty():
		return _err(ERR_CONTENT_REVISION, "content_revision")
	if _looks_like_absolute_path(data.content_revision):
		return _err(ERR_ABSOLUTE_PATH, "content_revision")
	if typeof(data.last_offline_resolution_id) != TYPE_STRING or _looks_like_absolute_path(data.last_offline_resolution_id):
		return _err(ERR_TYPE, "last_offline_resolution_id")
	if typeof(data.metadata) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "metadata")
	if typeof(data.game_state) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "game_state")
	var game_keys := _require_keys(data.game_state, SaveEnvelope.GAME_KEYS, "game_state")
	if not game_keys.ok:
		return game_keys
	var sim := SaveInt64.parse(data.game_state.simulation_time_msec, false, "game_state.simulation_time_msec")
	if not sim.ok:
		return sim
	if typeof(data.time_authority) != TYPE_DICTIONARY:
		return _err(ERR_TYPE, "time_authority")
	var time_keys := _require_keys(data.time_authority, SaveEnvelope.TIME_AUTHORITY_KEYS, "time_authority")
	if not time_keys.ok:
		return time_keys
	var t: Dictionary = data.time_authority
	if typeof(t.has_trusted_anchor) != TYPE_BOOL or typeof(t.trusted_source_id) != TYPE_STRING or typeof(t.pending_trusted_reconciliation) != TYPE_BOOL or typeof(t.last_sample_diagnostic_code) != TYPE_STRING:
		return _err(ERR_TYPE, "time_authority")
	if t.last_sample_diagnostic_code.is_empty() or _looks_like_absolute_path(t.last_sample_diagnostic_code):
		return _err(ERR_TYPE, "time_authority.last_sample_diagnostic_code")
	var anchor := SaveInt64.parse(t.trusted_anchor_utc_msec, false, "time_authority.trusted_anchor_utc_msec")
	if not anchor.ok:
		return anchor
	var foreground := SaveInt64.parse(t.foreground_credited_since_anchor_msec, false, "time_authority.foreground_credited_since_anchor_msec")
	if not foreground.ok:
		return foreground
	if t.has_trusted_anchor:
		if t.trusted_source_id.is_empty():
			return _err(ERR_CROSS_FIELD, "time_authority.trusted_source_id")
	else:
		if anchor.value != 0 or foreground.value != 0 or not t.trusted_source_id.is_empty():
			return _err(ERR_CROSS_FIELD, "time_authority")
	return {"ok": true, "code": OK, "save_revision": revision.value, "simulation_time_msec": sim.value, "trusted_anchor_utc_msec": anchor.value, "foreground_credited_since_anchor_msec": foreground.value}


static func _require_keys(data: Dictionary, expected: Array, field_path: String) -> Dictionary:
	var actual := data.keys()
	actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	if actual != sorted_expected:
		return _err(ERR_KEY_SET, field_path)
	return {"ok": true, "code": OK}


static func _looks_like_absolute_path(value: String) -> bool:
	return value.begins_with("/") or value.begins_with("\\") or (value.length() >= 3 and value[1] == ":" and (value[2] == "\\" or value[2] == "/"))


static func _err(code: String, field_path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": field_path}
