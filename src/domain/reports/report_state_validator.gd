class_name ReportStateValidator
extends RefCounted

## Pure content-aware validator for the saved report aggregate family.
##
## It owns no report state and never mutates candidates, reads clocks, or
## reconstructs facts. It validates runtime classes, checked integer domains,
## content references, map identity, sequence ordering, and cross-field
## relationships before persistence or runtime exposure.

const OK := "OK"
const ERR_TYPE := "REPORT_STATE_TYPE"
const ERR_RANGE := "REPORT_STATE_RANGE"
const ERR_CONTENT := "REPORT_STATE_CONTENT"
const ERR_CROSS_FIELD := "REPORT_STATE_CROSS_FIELD"
const ERR_ALIAS := "REPORT_STATE_ALIAS"
const INT64_MAX := FixedPoint.INT64_MAX
const APPROVED_MODES := ["FOREGROUND_SUPPLIED", "OFFLINE_FIXTURE", "DEBUG"]
const APPROVED_REASONS := ["MANUAL_REVIEW", "OFFLINE_RETURN", "SYSTEM_BOUNDARY"]
const APPROVED_LIFECYCLES := ["OVERDUE", "SETTLED"]
const APPROVED_EVENT_TYPES := ["OUTPUT_CHANNEL_BANKED", "THRESHOLD_SETTLED"]

static func validate(report_state: ReportState, gameplay_cursor_msec: int, registry: ContentRegistry) -> Dictionary:
	if report_state == null or not report_state is ReportState: return _err(ERR_TYPE, "report_state")
	if registry == null or not registry.ready: return _err(ERR_CONTENT, "content_registry")
	var result := _nonnegative(report_state.ingested_through_simulation_msec, "report_state.ingested_through_simulation_msec")
	if not result.ok: return result
	if report_state.ingested_through_simulation_msec > gameplay_cursor_msec: return _err(ERR_CROSS_FIELD, "report_state.ingested_through_simulation_msec")
	result = _positive(report_state.next_report_sequence, "report_state.next_report_sequence"); if not result.ok: return result
	result = _positive(report_state.next_event_sequence, "report_state.next_event_sequence"); if not result.ok: return result
	result = _nonnegative(report_state.dropped_history_count, "report_state.dropped_history_count"); if not result.ok: return result
	if report_state.history.size() > ReportState.REPORT_HISTORY_LIMIT: return _err(ERR_RANGE, "report_state.history")
	var previous_report_sequence := 0
	var previous_snapshot_time := 0
	var previous_event_sequence := 0
	var previous_event_order: Array = []
	var seen_event_sequences := {}
	for index in range(report_state.history.size()):
		var record = report_state.history[index]
		if record == null or not record is ReportRecord: return _err(ERR_TYPE, "report_state.history.%d" % index)
		result = _validate_record(record, report_state.ingested_through_simulation_msec, previous_report_sequence, previous_snapshot_time, previous_event_sequence, previous_event_order, seen_event_sequences, registry, "report_state.history.%d" % index)
		if not result.ok: return result
		previous_report_sequence = result.report_sequence
		previous_snapshot_time = result.snapshot_time
		previous_event_sequence = result.event_sequence
		previous_event_order = result.event_order
	if report_state.next_report_sequence <= previous_report_sequence: return _err(ERR_CROSS_FIELD, "report_state.next_report_sequence")
	if report_state.live == null or not report_state.live is ReportAccumulatorState: return _err(ERR_TYPE, "report_state.live")
	result = _validate_accumulator(report_state.live, report_state.ingested_through_simulation_msec, true, previous_snapshot_time, previous_event_sequence, previous_event_order, seen_event_sequences, registry, "report_state.live")
	if not result.ok: return result
	if report_state.next_event_sequence <= result.event_sequence: return _err(ERR_CROSS_FIELD, "report_state.next_event_sequence")
	return {"ok": true, "code": OK}

static func _validate_record(record: ReportRecord, report_cursor: int, previous_sequence: int, previous_snapshot_time: int, previous_event_sequence: int, previous_event_order: Array, seen_event_sequences: Dictionary, registry: ContentRegistry, path: String) -> Dictionary:
	var result := _positive(record.report_sequence, path + ".report_sequence"); if not result.ok: return result
	if record.report_sequence <= previous_sequence: return _err(ERR_CROSS_FIELD, path + ".report_sequence")
	if not APPROVED_REASONS.has(str(record.snapshot_reason)): return _err(ERR_RANGE, path + ".snapshot_reason")
	result = _nonnegative(record.snapshot_simulation_msec, path + ".snapshot_simulation_msec"); if not result.ok: return result
	if record.snapshot_simulation_msec < previous_snapshot_time or record.snapshot_simulation_msec > report_cursor: return _err(ERR_CROSS_FIELD, path + ".snapshot_simulation_msec")
	var window: Variant = record._window_for_validation()
	if window == null or not window is ReportAccumulatorState: return _err(ERR_TYPE, path + ".window")
	if window.window_ended_simulation_msec != record.snapshot_simulation_msec: return _err(ERR_CROSS_FIELD, path + ".window.window_ended_simulation_msec")
	result = _validate_accumulator(window, record.snapshot_simulation_msec, false, previous_snapshot_time, previous_event_sequence, previous_event_order, seen_event_sequences, registry, path + ".window")
	if not result.ok: return result
	return {"ok": true, "code": OK, "report_sequence": record.report_sequence, "snapshot_time": record.snapshot_simulation_msec, "event_sequence": result.event_sequence, "event_order": result.event_order}

static func _validate_accumulator(accumulator: ReportAccumulatorState, owning_cursor: int, live_window: bool, previous_window_end: int, previous_event_sequence: int, previous_event_order: Array, seen_event_sequences: Dictionary, registry: ContentRegistry, path: String) -> Dictionary:
	var result := _nonnegative(accumulator.window_started_simulation_msec, path + ".window_started_simulation_msec"); if not result.ok: return result
	result = _nonnegative(accumulator.window_ended_simulation_msec, path + ".window_ended_simulation_msec"); if not result.ok: return result
	if accumulator.window_started_simulation_msec < previous_window_end or accumulator.window_started_simulation_msec > accumulator.window_ended_simulation_msec: return _err(ERR_CROSS_FIELD, path + ".window_started_simulation_msec")
	if live_window and accumulator.window_ended_simulation_msec != owning_cursor: return _err(ERR_CROSS_FIELD, path + ".window_ended_simulation_msec")
	result = _nonnegative(accumulator.ingested_run_count, path + ".ingested_run_count"); if not result.ok: return result
	result = _nonnegative(accumulator.omitted_event_count, path + ".omitted_event_count"); if not result.ok: return result
	if accumulator.ingested_run_count == 0 and accumulator.omitted_event_count == 0 and accumulator.committed_mode_counts.is_empty() and accumulator.attribution_slices.is_empty() and accumulator.event_type_counts.is_empty() and accumulator.recent_events.is_empty() and accumulator.window_started_simulation_msec != accumulator.window_ended_simulation_msec:
		return _err(ERR_CROSS_FIELD, path + ".window")
	if live_window and accumulator.ingested_run_count == 0 and accumulator.omitted_event_count == 0 and accumulator.committed_mode_counts.is_empty() and accumulator.attribution_slices.is_empty() and accumulator.event_type_counts.is_empty() and accumulator.recent_events.is_empty() and accumulator.window_started_simulation_msec != owning_cursor:
		return _err(ERR_CROSS_FIELD, path + ".window_started_simulation_msec")
	var mode_total := 0
	var mode_keys := {}
	for mode_key in accumulator.committed_mode_counts.keys():
		var mode := str(mode_key)
		if mode_keys.has(mode) or not APPROVED_MODES.has(mode): return _err(ERR_RANGE, path + ".committed_mode_counts")
		mode_keys[mode] = true
		var count = accumulator.committed_mode_counts[mode_key]
		result = _nonnegative(count, path + ".committed_mode_counts.%s" % mode); if not result.ok: return result
		if mode_total > INT64_MAX - count: return _err(ERR_RANGE, path + ".committed_mode_counts")
		mode_total += count
	if mode_total != accumulator.ingested_run_count: return _err(ERR_CROSS_FIELD, path + ".committed_mode_counts")
	if accumulator.ingested_run_count == 0 and (accumulator.omitted_event_count > 0 or not accumulator.attribution_slices.is_empty() or not accumulator.event_type_counts.is_empty() or not accumulator.recent_events.is_empty()):
		return _err(ERR_CROSS_FIELD, path + ".ingested_run_count")
	var slice_keys := {}
	for raw_key in accumulator.attribution_slices.keys():
		var key := str(raw_key)
		if slice_keys.has(key): return _err(ERR_ALIAS, path + ".attribution_slices")
		slice_keys[key] = true
		var slice = accumulator.attribution_slices[raw_key]
		if slice == null or not slice is ReportAttributionSlice: return _err(ERR_TYPE, path + ".attribution_slices.%s" % key)
		result = _validate_slice(slice, key, accumulator.window_started_simulation_msec, accumulator.window_ended_simulation_msec, registry, path + ".attribution_slices.%s" % key); if not result.ok: return result
	var event_count_keys := {}
	var event_count_total := 0
	for raw_type in accumulator.event_type_counts.keys():
		var event_type := str(raw_type)
		if event_count_keys.has(event_type) or not APPROVED_EVENT_TYPES.has(event_type): return _err(ERR_RANGE, path + ".event_type_counts")
		event_count_keys[event_type] = true
		var count = accumulator.event_type_counts[raw_type]
		result = _nonnegative(count, path + ".event_type_counts.%s" % event_type); if not result.ok: return result
		if event_count_total > INT64_MAX - count: return _err(ERR_RANGE, path + ".event_type_counts")
		event_count_total += count
	if accumulator.recent_events.size() > ReportState.REPORT_RECENT_EVENT_LIMIT: return _err(ERR_RANGE, path + ".recent_events")
	var last_event_sequence := previous_event_sequence
	var last_event_order := previous_event_order
	var retained_counts := {}
	for index in range(accumulator.recent_events.size()):
		var event = accumulator.recent_events[index]
		if event == null or not event is ReportEventRecord: return _err(ERR_TYPE, path + ".recent_events.%d" % index)
		result = _validate_event(event, accumulator.window_started_simulation_msec, accumulator.window_ended_simulation_msec, last_event_sequence, last_event_order, seen_event_sequences, registry, path + ".recent_events.%d" % index); if not result.ok: return result
		last_event_sequence = event.event_sequence
		last_event_order = result.event_order
		var event_type := str(event.event_type)
		retained_counts[event_type] = int(retained_counts.get(event_type, 0)) + 1
	for event_type in retained_counts.keys():
		if not accumulator.event_type_counts.has(StringName(event_type)) and not accumulator.event_type_counts.has(event_type): return _err(ERR_CROSS_FIELD, path + ".event_type_counts.%s" % event_type)
		var stored_count = accumulator.event_type_counts.get(StringName(event_type), accumulator.event_type_counts.get(event_type, 0))
		if stored_count < retained_counts[event_type]: return _err(ERR_CROSS_FIELD, path + ".event_type_counts.%s" % event_type)
	if accumulator.omitted_event_count > INT64_MAX - accumulator.recent_events.size(): return _err(ERR_RANGE, path + ".omitted_event_count")
	var consumed_event_count: int = accumulator.omitted_event_count + accumulator.recent_events.size()
	if event_count_total != consumed_event_count: return _err(ERR_CROSS_FIELD, path + ".event_type_counts")
	if previous_event_sequence > INT64_MAX - accumulator.omitted_event_count: return _err(ERR_RANGE, path + ".omitted_event_count")
	if last_event_sequence < previous_event_sequence + accumulator.omitted_event_count: last_event_sequence = previous_event_sequence + accumulator.omitted_event_count
	return {"ok": true, "code": OK, "event_sequence": last_event_sequence, "event_order": last_event_order}

static func _validate_slice(slice: ReportAttributionSlice, expected_key: String, owning_window_start: int, owning_window_end: int, registry: ContentRegistry, path: String) -> Dictionary:
	if slice.canonical_identity_key() != expected_key: return _err(ERR_CROSS_FIELD, path)
	var result := _positive(slice.assignment_revision, path + ".assignment_revision"); if not result.ok: return result
	if not APPROVED_LIFECYCLES.has(str(slice.lifecycle_state)): return _err(ERR_RANGE, path + ".lifecycle_state")
	var threshold := _content(registry, str(slice.threshold_id), "threshold", path + ".threshold_id"); if not threshold.ok: return threshold
	result = _validate_loadout(slice.loadout_identity, registry, path + ".loadout_identity"); if not result.ok: return result
	result = _nonnegative(slice.window_started_simulation_msec, path + ".window_started_simulation_msec"); if not result.ok: return result
	result = _nonnegative(slice.window_ended_simulation_msec, path + ".window_ended_simulation_msec"); if not result.ok: return result
	if slice.window_started_simulation_msec < owning_window_start or slice.window_ended_simulation_msec > owning_window_end or slice.window_started_simulation_msec > slice.window_ended_simulation_msec: return _err(ERR_CROSS_FIELD, path + ".window")
	result = _nonnegative(slice.elapsed_msec, path + ".elapsed_msec"); if not result.ok: return result
	if not _difference_matches(slice.window_started_simulation_msec, slice.window_ended_simulation_msec, slice.elapsed_msec): return _err(ERR_CROSS_FIELD, path + ".elapsed_msec")
	for field in ["returned_souls_delta", "backlog_reduced", "completed_cycles_delta"]:
		result = _nonnegative(slice[field], path + "." + field); if not result.ok: return result
	result = _validate_quantity_map(slice.inventory_gains_by_item_id, registry, "item", path + ".inventory_gains_by_item_id"); if not result.ok: return result
	result = _validate_quantity_map(slice.mastery_gains_subunits_by_form_id, registry, "form", path + ".mastery_gains_subunits_by_form_id"); if not result.ok: return result
	var channel_keys := {}
	for raw_channel_id in slice.channel_summaries_by_channel_id.keys():
		var channel_id := str(raw_channel_id)
		if channel_keys.has(channel_id): return _err(ERR_ALIAS, path + ".channel_summaries_by_channel_id")
		channel_keys[channel_id] = true
		var summary = slice.channel_summaries_by_channel_id[raw_channel_id]
		if summary == null or not summary is ReportChannelSummary: return _err(ERR_TYPE, path + ".channel_summaries_by_channel_id.%s" % channel_id)
		result = _validate_channel(summary, str(slice.threshold_id), channel_id, slice.elapsed_msec, registry, path + ".channel_summaries_by_channel_id.%s" % channel_id); if not result.ok: return result
	return {"ok": true, "code": OK}

static func _validate_loadout(loadout: ReportLoadoutIdentity, registry: ContentRegistry, path: String) -> Dictionary:
	if loadout == null or not loadout is ReportLoadoutIdentity: return _err(ERR_TYPE, path)
	var result := _content(registry, str(loadout.form_id), "form", path + ".form_id"); if not result.ok: return result
	result = _content(registry, str(loadout.writ_id), "writ", path + ".writ_id"); if not result.ok: return result
	var seen := {}
	for index in range(loadout.ordered_retinue_ids.size()):
		var retinue_id := str(loadout.ordered_retinue_ids[index])
		if seen.has(retinue_id): return _err(ERR_CROSS_FIELD, path + ".ordered_retinue_ids.%d" % index)
		seen[retinue_id] = true
		result = _content(registry, retinue_id, "retinue", path + ".ordered_retinue_ids.%d" % index); if not result.ok: return result
	return {"ok": true, "code": OK}

static func _validate_quantity_map(values: Dictionary, registry: ContentRegistry, content_type: String, path: String) -> Dictionary:
	var seen := {}
	for raw_id in values.keys():
		var id := str(raw_id)
		if seen.has(id): return _err(ERR_ALIAS, path)
		seen[id] = true
		var result := _content(registry, id, content_type, path + ".%s" % id); if not result.ok: return result
		result = _nonnegative(values[raw_id], path + ".%s" % id); if not result.ok: return result
	return {"ok": true, "code": OK}

static func _validate_channel(summary: ReportChannelSummary, expected_threshold: String, expected_channel: String, owning_slice_elapsed: int, registry: ContentRegistry, path: String) -> Dictionary:
	if str(summary.threshold_id) != expected_threshold or str(summary.channel_id) != expected_channel: return _err(ERR_CROSS_FIELD, path)
	var relation := _channel_relationship(registry, expected_channel, expected_threshold, path); if not relation.ok: return relation
	if str(summary.output_item_id) != str(relation.channel.output_item_id): return _err(ERR_CROSS_FIELD, path + ".output_item_id")
	var result := _nonnegative(summary.elapsed_msec, path + ".elapsed_msec"); if not result.ok: return result
	if summary.elapsed_msec > owning_slice_elapsed: return _err(ERR_CROSS_FIELD, path + ".elapsed_msec")
	result = _nonnegative(summary.banked_units_delta, path + ".banked_units_delta"); if not result.ok: return result
	for field in ["total_banked_units_start", "total_banked_units_end"]:
		result = _nonnegative(summary[field], path + "." + field); if not result.ok: return result
	if summary.total_banked_units_end < summary.total_banked_units_start or not _difference_matches(summary.total_banked_units_start, summary.total_banked_units_end, summary.banked_units_delta): return _err(ERR_CROSS_FIELD, path + ".banked_units_delta")
	for field in ["progress_subunits_start", "progress_subunits_end"]:
		if summary[field] < 0 or summary[field] >= FixedPoint.SCALE: return _err(ERR_RANGE, path + "." + field)
	var period := int(relation.channel.rate.period_msec)
	for field in ["rate_carry_units_start", "rate_carry_units_end"]:
		if summary[field] < 0 or summary[field] >= period: return _err(ERR_RANGE, path + "." + field)
	return {"ok": true, "code": OK}

static func _validate_event(event: ReportEventRecord, window_start: int, window_end: int, previous_sequence: int, previous_event_order: Array, seen_event_sequences: Dictionary, registry: ContentRegistry, path: String) -> Dictionary:
	var result := _positive(event.event_sequence, path + ".event_sequence"); if not result.ok: return result
	if event.event_sequence <= previous_sequence or seen_event_sequences.has(event.event_sequence): return _err(ERR_CROSS_FIELD, path + ".event_sequence")
	seen_event_sequences[event.event_sequence] = true
	var event_type := str(event.event_type)
	if not APPROVED_EVENT_TYPES.has(event_type): return _err(ERR_RANGE, path + ".event_type")
	result = _nonnegative(event.occurred_simulation_msec, path + ".occurred_simulation_msec"); if not result.ok: return result
	if event.occurred_simulation_msec <= window_start or event.occurred_simulation_msec > window_end: return _err(ERR_CROSS_FIELD, path + ".occurred_simulation_msec")
	if event_type == "OUTPUT_CHANNEL_BANKED":
		if event.priority != 100 or str(event.source_id).is_empty(): return _err(ERR_CROSS_FIELD, path)
		result = _channel_relationship(registry, str(event.source_id), str(event.subject_id), path + ".source_id"); if not result.ok: return result
	else:
		if event.priority != 200 or str(event.source_id) != "SIMULATION_ENGINE": return _err(ERR_CROSS_FIELD, path)
		result = _content(registry, str(event.subject_id), "threshold", path + ".subject_id"); if not result.ok: return result
	if str(event.subject_id).is_empty() or str(event.source_id).is_empty(): return _err(ERR_CROSS_FIELD, path)
	if not _event_order_is_valid(previous_event_order, event.occurred_simulation_msec, event.priority, str(event.subject_id), str(event.source_id)): return _err(ERR_CROSS_FIELD, path + ".event_order")
	return {"ok": true, "code": OK, "event_order": [event.occurred_simulation_msec, event.priority, str(event.subject_id), str(event.source_id)]}

static func _channel_relationship(registry: ContentRegistry, channel_id: String, threshold_id: String, path: String) -> Dictionary:
	var channel_result := _content(registry, channel_id, "channel", path + ".channel_id"); if not channel_result.ok: return channel_result
	var channel: Dictionary = channel_result.record
	var output_item_result := _content(registry, str(channel.output_item_id), "item", path + ".output_item_id"); if not output_item_result.ok: return output_item_result
	if str(channel.source_threshold_id) != threshold_id: return _err(ERR_CONTENT, path + ".threshold_id")
	if not channel.rate is Dictionary or int(channel.rate.period_msec) <= 0: return _err(ERR_CONTENT, path + ".channel_id")
	var threshold_result := _content(registry, threshold_id, "threshold", path + ".threshold_id"); if not threshold_result.ok: return threshold_result
	if not threshold_result.record.channel_ids.has(channel_id): return _err(ERR_CONTENT, path + ".channel_id")
	return {"ok": true, "code": OK, "channel": channel}

static func _content(registry: ContentRegistry, id: String, expected_type: String, path: String) -> Dictionary:
	if id.is_empty(): return _err(ERR_CONTENT, path)
	var result := registry.get_record(id)
	if not result.ok or result.record.type != expected_type or not result.record.enabled: return _err(ERR_CONTENT, path)
	return result

static func _nonnegative(value: Variant, path: String) -> Dictionary:
	if typeof(value) != TYPE_INT or value < 0 or value > INT64_MAX: return _err(ERR_RANGE if typeof(value) == TYPE_INT else ERR_TYPE, path)
	return {"ok": true, "code": OK}

static func _positive(value: Variant, path: String) -> Dictionary:
	var result := _nonnegative(value, path)
	if not result.ok: return result
	if value <= 0: return _err(ERR_RANGE, path)
	return {"ok": true, "code": OK}

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

static func _err(code: String, field_path: String) -> Dictionary:
	return {"ok": false, "code": code, "field_path": field_path}
