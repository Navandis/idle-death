class_name ReportSchemaValidator
extends RefCounted

## Exact primitive validator for the schema-v4 report tree.
##
## This class owns no runtime objects or files. It validates exact object keys,
## canonical decimal-string integers, primitive types, ordering, and local
## cross-field relationships before `SaveSchemaMapper` constructs ReportState.
## Content-aware identity checks remain in `ReportStateValidator`.

const OK := "OK"
const ERR_TYPE := "REPORT_SCHEMA_TYPE"
const ERR_KEY_SET := "REPORT_SCHEMA_KEY_SET"
const ERR_CROSS_FIELD := "REPORT_SCHEMA_CROSS_FIELD"
const ERR_RANGE := "REPORT_SCHEMA_RANGE"
const INT64_MAX := FixedPoint.INT64_MAX
const MODES := ["FOREGROUND_SUPPLIED", "OFFLINE_FIXTURE", "DEBUG"]
const EVENT_TYPES := ["OUTPUT_CHANNEL_BANKED", "THRESHOLD_SETTLED"]
const REASONS := ["MANUAL_REVIEW", "OFFLINE_RETURN", "SYSTEM_BOUNDARY"]

static func validate(data: Variant, gameplay_cursor_msec: int) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, "report_state")
	var result := _require(data, ["dropped_history_count", "history", "ingested_through_simulation_msec", "live", "next_event_sequence", "next_report_sequence"], "report_state"); if not result.ok: return result
	var cursor := _integer(data, "ingested_through_simulation_msec", "report_state.ingested_through_simulation_msec"); if not cursor.ok: return cursor
	if cursor.value > gameplay_cursor_msec: return _err(ERR_CROSS_FIELD, "report_state.ingested_through_simulation_msec")
	result = _positive_integer(data, "next_report_sequence", "report_state.next_report_sequence"); if not result.ok: return result
	result = _positive_integer(data, "next_event_sequence", "report_state.next_event_sequence"); if not result.ok: return result
	result = _integer(data, "dropped_history_count", "report_state.dropped_history_count"); if not result.ok: return result
	if typeof(data.history) != TYPE_ARRAY: return _err(ERR_TYPE, "report_state.history")
	if data.history.size() > ReportState.REPORT_HISTORY_LIMIT: return _err(ERR_RANGE, "report_state.history")
	var previous_report_sequence := 0
	var previous_snapshot_time := 0
	var previous_event_sequence := 0
	var previous_event_order: Array = []
	var seen_event_sequences := {}
	for index in range(data.history.size()):
		result = _validate_record(data.history[index], cursor.value, previous_report_sequence, previous_snapshot_time, previous_event_sequence, previous_event_order, seen_event_sequences, "report_state.history.%d" % index); if not result.ok: return result
		previous_report_sequence = result.sequence
		previous_snapshot_time = result.snapshot_time
		previous_event_sequence = result.event_sequence
		previous_event_order = result.event_order
	if cursor.value < 0 or data.next_report_sequence == null: return _err(ERR_RANGE, "report_state.next_report_sequence")
	var next_report := _positive_integer(data, "next_report_sequence", "report_state.next_report_sequence"); if not next_report.ok: return next_report
	if next_report.value <= previous_report_sequence: return _err(ERR_CROSS_FIELD, "report_state.next_report_sequence")
	result = _validate_accumulator(data.live, cursor.value, true, previous_snapshot_time, previous_event_sequence, previous_event_order, seen_event_sequences, "report_state.live"); if not result.ok: return result
	var next_event := _positive_integer(data, "next_event_sequence", "report_state.next_event_sequence"); if not next_event.ok: return next_event
	if next_event.value <= result.event_sequence: return _err(ERR_CROSS_FIELD, "report_state.next_event_sequence")
	return {"ok": true, "code": OK, "cursor": cursor.value}

static func _validate_record(data: Variant, report_cursor: int, previous_sequence: int, previous_snapshot_time: int, previous_event_sequence: int, previous_event_order: Array, seen_event_sequences: Dictionary, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var result := _require(data, ["report_sequence", "snapshot_reason", "snapshot_simulation_msec", "window"], path); if not result.ok: return result
	var sequence := _positive_integer(data, "report_sequence", path + ".report_sequence"); if not sequence.ok: return sequence
	if sequence.value <= previous_sequence: return _err(ERR_CROSS_FIELD, path + ".report_sequence")
	var reason := _string(data, "snapshot_reason", path + ".snapshot_reason"); if not reason.ok: return reason
	if not REASONS.has(reason.value): return _err(ERR_RANGE, path + ".snapshot_reason")
	var snapshot_time := _integer(data, "snapshot_simulation_msec", path + ".snapshot_simulation_msec"); if not snapshot_time.ok: return snapshot_time
	if snapshot_time.value < previous_snapshot_time or snapshot_time.value > report_cursor: return _err(ERR_CROSS_FIELD, path + ".snapshot_simulation_msec")
	result = _validate_accumulator(data.window, snapshot_time.value, false, previous_snapshot_time, previous_event_sequence, previous_event_order, seen_event_sequences, path + ".window"); if not result.ok: return result
	if result.end_time != snapshot_time.value: return _err(ERR_CROSS_FIELD, path + ".window.window_ended_simulation_msec")
	return {"ok": true, "code": OK, "sequence": sequence.value, "snapshot_time": snapshot_time.value, "event_sequence": result.event_sequence, "event_order": result.event_order}

static func _validate_accumulator(data: Variant, expected_end: int, live_window: bool, previous_window_end: int, previous_event_sequence: int, previous_event_order: Array, seen_event_sequences: Dictionary, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var result := _require(data, ["attribution_slices", "committed_mode_counts", "event_type_counts", "ingested_run_count", "omitted_event_count", "recent_events", "window_ended_simulation_msec", "window_started_simulation_msec"], path); if not result.ok: return result
	var start := _integer(data, "window_started_simulation_msec", path + ".window_started_simulation_msec"); if not start.ok: return start
	var end := _integer(data, "window_ended_simulation_msec", path + ".window_ended_simulation_msec"); if not end.ok: return end
	if start.value < previous_window_end or start.value > end.value or (live_window and end.value != expected_end): return _err(ERR_CROSS_FIELD, path + ".window_started_simulation_msec")
	var run_count := _integer(data, "ingested_run_count", path + ".ingested_run_count"); if not run_count.ok: return run_count
	var omitted := _integer(data, "omitted_event_count", path + ".omitted_event_count"); if not omitted.ok: return omitted
	if typeof(data.committed_mode_counts) != TYPE_DICTIONARY: return _err(ERR_TYPE, path + ".committed_mode_counts")
	if typeof(data.attribution_slices) != TYPE_DICTIONARY: return _err(ERR_TYPE, path + ".attribution_slices")
	if typeof(data.event_type_counts) != TYPE_DICTIONARY: return _err(ERR_TYPE, path + ".event_type_counts")
	if typeof(data.recent_events) != TYPE_ARRAY: return _err(ERR_TYPE, path + ".recent_events")
	if run_count.value == 0 and omitted.value == 0 and data.committed_mode_counts.is_empty() and data.attribution_slices.is_empty() and data.event_type_counts.is_empty() and data.recent_events.is_empty() and start.value != end.value:
		return _err(ERR_CROSS_FIELD, path + ".window")
	if live_window and run_count.value == 0 and omitted.value == 0 and data.committed_mode_counts.is_empty() and data.attribution_slices.is_empty() and data.event_type_counts.is_empty() and data.recent_events.is_empty() and start.value != expected_end:
		return _err(ERR_CROSS_FIELD, path + ".window_started_simulation_msec")
	var mode_total := 0
	for key in data.committed_mode_counts.keys():
		if typeof(key) != TYPE_STRING or not MODES.has(key): return _err(ERR_RANGE, path + ".committed_mode_counts")
		var count := _integer_value(data.committed_mode_counts[key], path + ".committed_mode_counts." + key); if not count.ok: return count
		if mode_total > INT64_MAX - count.value: return _err(ERR_RANGE, path + ".committed_mode_counts")
		mode_total += count.value
	if mode_total != run_count.value: return _err(ERR_CROSS_FIELD, path + ".committed_mode_counts")
	if run_count.value == 0 and (omitted.value > 0 or not data.attribution_slices.is_empty() or not data.event_type_counts.is_empty() or not data.recent_events.is_empty()):
		return _err(ERR_CROSS_FIELD, path + ".ingested_run_count")
	for key in data.attribution_slices.keys():
		if typeof(key) != TYPE_STRING or key.is_empty(): return _err(ERR_TYPE, path + ".attribution_slices")
		result = _validate_slice(data.attribution_slices[key], key, start.value, end.value, path + ".attribution_slices." + key); if not result.ok: return result
	var event_count_total := 0
	for key in data.event_type_counts.keys():
		if typeof(key) != TYPE_STRING or not EVENT_TYPES.has(key): return _err(ERR_RANGE, path + ".event_type_counts")
		result = _integer_value(data.event_type_counts[key], path + ".event_type_counts." + key); if not result.ok: return result
		if event_count_total > INT64_MAX - result.value: return _err(ERR_RANGE, path + ".event_type_counts")
		event_count_total += result.value
	if data.recent_events.size() > ReportState.REPORT_RECENT_EVENT_LIMIT: return _err(ERR_RANGE, path + ".recent_events")
	var last_event_sequence := previous_event_sequence
	var last_event_order := previous_event_order
	var retained_counts := {}
	for index in range(data.recent_events.size()):
		result = _validate_event(data.recent_events[index], start.value, end.value, last_event_sequence, last_event_order, seen_event_sequences, path + ".recent_events.%d" % index); if not result.ok: return result
		last_event_sequence = result.sequence
		last_event_order = result.event_order
		retained_counts[result.event_type] = int(retained_counts.get(result.event_type, 0)) + 1
	for key in retained_counts.keys():
		if not data.event_type_counts.has(key) or int(data.event_type_counts[key]) < retained_counts[key]: return _err(ERR_CROSS_FIELD, path + ".event_type_counts." + key)
	if omitted.value > INT64_MAX - data.recent_events.size(): return _err(ERR_RANGE, path + ".omitted_event_count")
	var consumed_event_count: int = omitted.value + data.recent_events.size()
	if event_count_total != consumed_event_count: return _err(ERR_CROSS_FIELD, path + ".event_type_counts")
	if previous_event_sequence > INT64_MAX - omitted.value: return _err(ERR_RANGE, path + ".omitted_event_count")
	if last_event_sequence < previous_event_sequence + omitted.value: last_event_sequence = previous_event_sequence + omitted.value
	return {"ok": true, "code": OK, "end_time": end.value, "event_sequence": last_event_sequence, "event_order": last_event_order}

static func _validate_slice(data: Variant, expected_key: String, owning_window_start: int, owning_window_end: int, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var keys := ["assignment_revision", "backlog_reduced", "channel_summaries_by_channel_id", "completed_cycles_delta", "elapsed_msec", "inventory_gains_by_item_id", "lifecycle_state", "loadout_identity", "mastery_gains_subunits_by_form_id", "returned_souls_delta", "threshold_id", "window_ended_simulation_msec", "window_started_simulation_msec"]
	var result := _require(data, keys, path); if not result.ok: return result
	var threshold := _string(data, "threshold_id", path + ".threshold_id"); if not threshold.ok: return threshold
	var revision := _positive_integer(data, "assignment_revision", path + ".assignment_revision"); if not revision.ok: return revision
	var lifecycle := _string(data, "lifecycle_state", path + ".lifecycle_state"); if not lifecycle.ok: return lifecycle
	if lifecycle.value != "OVERDUE" and lifecycle.value != "SETTLED": return _err(ERR_RANGE, path + ".lifecycle_state")
	if expected_key != "%s|%s|%s" % [threshold.value, revision.value, lifecycle.value]: return _err(ERR_CROSS_FIELD, path)
	result = _validate_loadout(data.loadout_identity, path + ".loadout_identity"); if not result.ok: return result
	var start := _integer(data, "window_started_simulation_msec", path + ".window_started_simulation_msec"); if not start.ok: return start
	var end := _integer(data, "window_ended_simulation_msec", path + ".window_ended_simulation_msec"); if not end.ok: return end
	var elapsed := _integer(data, "elapsed_msec", path + ".elapsed_msec"); if not elapsed.ok: return elapsed
	if start.value < owning_window_start or end.value > owning_window_end or start.value > end.value or not _difference_matches(start.value, end.value, elapsed.value): return _err(ERR_CROSS_FIELD, path + ".elapsed_msec")
	for field in ["returned_souls_delta", "backlog_reduced", "completed_cycles_delta"]:
		result = _integer(data, field, path + "." + field); if not result.ok: return result
	result = _validate_quantity_map(data.inventory_gains_by_item_id, path + ".inventory_gains_by_item_id"); if not result.ok: return result
	result = _validate_quantity_map(data.mastery_gains_subunits_by_form_id, path + ".mastery_gains_subunits_by_form_id"); if not result.ok: return result
	if typeof(data.channel_summaries_by_channel_id) != TYPE_DICTIONARY: return _err(ERR_TYPE, path + ".channel_summaries_by_channel_id")
	for key in data.channel_summaries_by_channel_id.keys():
		if typeof(key) != TYPE_STRING or key.is_empty(): return _err(ERR_TYPE, path + ".channel_summaries_by_channel_id")
		result = _validate_channel(data.channel_summaries_by_channel_id[key], key, threshold.value, elapsed.value, path + ".channel_summaries_by_channel_id." + key); if not result.ok: return result
	return {"ok": true, "code": OK}

static func _validate_loadout(data: Variant, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var result := _require(data, ["form_id", "ordered_retinue_ids", "writ_id"], path); if not result.ok: return result
	for field in ["form_id", "writ_id"]:
		result = _string(data, field, path + "." + field); if not result.ok or result.value.is_empty(): return _err(ERR_TYPE, path + "." + field)
	if typeof(data.ordered_retinue_ids) != TYPE_ARRAY: return _err(ERR_TYPE, path + ".ordered_retinue_ids")
	var seen := {}
	for index in range(data.ordered_retinue_ids.size()):
		var value = data.ordered_retinue_ids[index]
		if typeof(value) != TYPE_STRING or value.is_empty() or seen.has(value): return _err(ERR_CROSS_FIELD, path + ".ordered_retinue_ids.%d" % index)
		seen[value] = true
	return {"ok": true, "code": OK}

static func _validate_quantity_map(data: Variant, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	for key in data.keys():
		if typeof(key) != TYPE_STRING or key.is_empty(): return _err(ERR_TYPE, path)
		var result := _integer_value(data[key], path + "." + key); if not result.ok: return result
	return {"ok": true, "code": OK}

static func _validate_channel(data: Variant, expected_channel: String, expected_threshold: String, owning_slice_elapsed: int, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var result := _require(data, ["banked_units_delta", "channel_id", "elapsed_msec", "output_item_id", "progress_subunits_end", "progress_subunits_start", "rate_carry_units_end", "rate_carry_units_start", "threshold_id", "total_banked_units_end", "total_banked_units_start"], path); if not result.ok: return result
	for field in ["threshold_id", "channel_id", "output_item_id"]:
		result = _string(data, field, path + "." + field); if not result.ok or result.value.is_empty(): return _err(ERR_TYPE, path + "." + field)
	if data.threshold_id != expected_threshold or data.channel_id != expected_channel: return _err(ERR_CROSS_FIELD, path)
	for field in ["elapsed_msec", "banked_units_delta", "progress_subunits_start", "progress_subunits_end", "rate_carry_units_start", "rate_carry_units_end", "total_banked_units_start", "total_banked_units_end"]:
		result = _integer(data, field, path + "." + field); if not result.ok: return result
		if field.begins_with("progress_") and result.value >= FixedPoint.SCALE: return _err(ERR_RANGE, path + "." + field)
	if int(data.elapsed_msec) > owning_slice_elapsed: return _err(ERR_CROSS_FIELD, path + ".elapsed_msec")
	if int(data.total_banked_units_end) < int(data.total_banked_units_start) or not _difference_matches(int(data.total_banked_units_start), int(data.total_banked_units_end), int(data.banked_units_delta)): return _err(ERR_CROSS_FIELD, path + ".banked_units_delta")
	return {"ok": true, "code": OK}

static func _validate_event(data: Variant, window_start: int, window_end: int, previous_sequence: int, previous_event_order: Array, seen_event_sequences: Dictionary, path: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY: return _err(ERR_TYPE, path)
	var result := _require(data, ["event_sequence", "event_type", "occurred_simulation_msec", "priority", "source_id", "subject_id"], path); if not result.ok: return result
	var sequence := _positive_integer(data, "event_sequence", path + ".event_sequence"); if not sequence.ok: return sequence
	if sequence.value <= previous_sequence or seen_event_sequences.has(sequence.value): return _err(ERR_CROSS_FIELD, path + ".event_sequence")
	seen_event_sequences[sequence.value] = true
	var type_value := _string(data, "event_type", path + ".event_type"); if not type_value.ok or not EVENT_TYPES.has(type_value.value): return _err(ERR_RANGE, path + ".event_type")
	var occurred := _integer(data, "occurred_simulation_msec", path + ".occurred_simulation_msec"); if not occurred.ok: return occurred
	if occurred.value <= window_start or occurred.value > window_end: return _err(ERR_CROSS_FIELD, path + ".occurred_simulation_msec")
	var priority := _integer(data, "priority", path + ".priority"); if not priority.ok: return priority
	for field in ["subject_id", "source_id"]:
		result = _string(data, field, path + "." + field); if not result.ok or result.value.is_empty(): return _err(ERR_TYPE, path + "." + field)
	if (type_value.value == "OUTPUT_CHANNEL_BANKED" and priority.value != 100) or (type_value.value == "THRESHOLD_SETTLED" and priority.value != 200): return _err(ERR_CROSS_FIELD, path + ".priority")
	if not _event_order_is_valid(previous_event_order, occurred.value, priority.value, data.subject_id, data.source_id): return _err(ERR_CROSS_FIELD, path + ".event_order")
	return {"ok": true, "code": OK, "sequence": sequence.value, "event_type": type_value.value, "event_order": [occurred.value, priority.value, data.subject_id, data.source_id]}

static func _integer(data: Dictionary, key: String, path: String) -> Dictionary:
	return _integer_value(data.get(key, null), path)

static func _integer_value(value: Variant, path: String) -> Dictionary:
	var parsed := SaveInt64.parse(value, false, path)
	return parsed if parsed.ok else parsed

static func _positive_integer(data: Dictionary, key: String, path: String) -> Dictionary:
	var result := _integer(data, key, path); if not result.ok: return result
	if result.value <= 0: return _err(ERR_RANGE, path)
	return result

static func _difference_matches(start: int, end: int, expected: int) -> bool:
	if start < 0 or end < start or expected < 0 or expected > INT64_MAX: return false
	if start > INT64_MAX - expected: return false
	return start + expected == end

static func _event_order_is_valid(previous: Array, occurred: int, priority: int, subject: String, source: String) -> bool:
	if previous.is_empty(): return true
	if occurred != int(previous[0]): return occurred > int(previous[0])
	if priority != int(previous[1]): return priority > int(previous[1])
	if subject != str(previous[2]): return subject > str(previous[2])
	return source >= str(previous[3])

static func _string(data: Dictionary, key: String, path: String) -> Dictionary:
	var value = data.get(key, null)
	if typeof(value) != TYPE_STRING: return _err(ERR_TYPE, path)
	return {"ok": true, "code": OK, "value": value}

static func _require(data: Dictionary, expected: Array, path: String) -> Dictionary:
	var actual := data.keys(); actual.sort(); var wanted := expected.duplicate(); wanted.sort()
	if actual != wanted: return _err(ERR_KEY_SET, path)
	return {"ok": true, "code": OK}

static func _err(code: String, path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": path}
