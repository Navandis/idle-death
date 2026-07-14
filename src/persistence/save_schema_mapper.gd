class_name SaveSchemaMapper
extends RefCounted

## Maps minimal M01 runtime state to and from primitive schema-version-1 data.
##
## The mapper owns no file bytes and performs no JSON parsing.  It converts the
## runtime sentinel for "no trusted anchor" (`-1`) into explicit wire fields so
## the save file never relies on a negative epoch to mean absence.

const OK := "OK"
const ERR_SCHEMA := "SAVE_SCHEMA_INVALID"

static func runtime_to_snapshot(game_state: GameState, time_state: TimeAuthorityState, save_revision: int, content_revision: String = SaveEnvelope.DEFAULT_CONTENT_REVISION) -> Dictionary:
	var has_anchor := time_state.has_anchor()
	return {
		"codec_id": SaveEnvelope.CODEC_JSON_V1,
		"schema_version": SaveInt64.format(SaveEnvelope.CURRENT_SCHEMA_VERSION),
		"save_revision": SaveInt64.format(save_revision),
		"content_revision": content_revision,
		"last_offline_resolution_id": "",
		"metadata": {},
		"game_state": {"simulation_time_msec": SaveInt64.format(game_state.simulation_time_msec)},
		"time_authority": {
			"has_trusted_anchor": has_anchor,
			"trusted_anchor_utc_msec": SaveInt64.format(time_state.trusted_anchor_utc_msec if has_anchor else 0),
			"trusted_source_id": time_state.trusted_source_id if has_anchor else "",
			"foreground_credited_since_anchor_msec": SaveInt64.format(time_state.foreground_credited_since_anchor_msec if has_anchor else 0),
			"pending_trusted_reconciliation": time_state.pending_trusted_reconciliation,
			"last_sample_diagnostic_code": time_state.last_sample_diagnostic_code,
		},
	}


static func snapshot_to_runtime(snapshot: Dictionary) -> Dictionary:
	var validation := SaveSchemaValidator.validate_v1(snapshot)
	if not validation.ok:
		return validation
	var game := GameState.new(validation.simulation_time_msec)
	var time := TimeAuthorityState.new()
	var t: Dictionary = snapshot.time_authority
	if t.has_trusted_anchor:
		time.trusted_anchor_utc_msec = validation.trusted_anchor_utc_msec
		time.trusted_source_id = t.trusted_source_id
		time.foreground_credited_since_anchor_msec = validation.foreground_credited_since_anchor_msec
	else:
		time.trusted_anchor_utc_msec = -1
		time.trusted_source_id = ""
		time.foreground_credited_since_anchor_msec = 0
	time.pending_trusted_reconciliation = t.pending_trusted_reconciliation
	time.last_sample_diagnostic_code = t.last_sample_diagnostic_code
	return {"ok": true, "code": OK, "game_state": game, "time_authority_state": time, "save_revision": validation.save_revision, "content_revision": snapshot.content_revision}
