class_name ReportLedgerValidator
extends RefCounted

## The one runtime semantic validator for the caller-owned ledger. It checks
## live facts, retained records, and compact continuation without retaining any
## state or reconstructing detail that retention deliberately discarded.

const FAILURE := &"REPORT_LEDGER_VALIDATION_FAILED"
const MODES := [&"FOREGROUND_SUPPLIED", &"OFFLINE_FIXTURE", &"DEBUG"]
const INT64_MAX := FixedPoint.INT64_MAX

static func validate(ledger: ReportLedger) -> Dictionary:
	var details := _details(ledger)
	return {"ok": details.is_empty(), "code": &"" if details.is_empty() else FAILURE, "details": details}

static func _details(ledger: ReportLedger) -> String:
	if ledger == null: return "Ledger is required."
	var identity_details := _validate_owned_node_identities(ledger)
	if not identity_details.is_empty(): return identity_details
	if ledger.window_start_simulation_msec < 0 or ledger.ingested_through_simulation_msec < ledger.window_start_simulation_msec:
		return "Ledger cursors are invalid."
	if ledger.next_record_sequence < 1: return "Next record sequence is invalid."
	var live_details := _validate_window(ledger.window_start_simulation_msec, ledger.ingested_through_simulation_msec, ledger.foreground_elapsed_msec, ledger.offline_elapsed_msec, ledger.debug_elapsed_msec, ledger.next_event_sequence, ledger.slices, ledger.settlement_events)
	if not live_details.is_empty(): return live_details
	var history_details := _validate_history(ledger)
	if not history_details.is_empty(): return history_details
	var continuation_details := _validate_continuations(ledger)
	if not continuation_details.is_empty(): return continuation_details
	return _validate_detailed_continuity(ledger)

static func _validate_history(ledger: ReportLedger) -> String:
	if ledger.retained_records.size() > ReportLedger.MAX_RETAINED_RECORDS: return "Retained history exceeds capacity."
	if ledger.retained_records.is_empty():
		if ledger.next_record_sequence != 1: return "Empty history has an invalid record sequence."
		return ""
	var expected_sequence := ledger.next_record_sequence - ledger.retained_records.size()
	var previous_end := -1
	for record in ledger.retained_records:
		if record == null or record.record_sequence != expected_sequence or record.record_sequence <= 0: return "Retained record sequence is invalid."
		if previous_end >= 0 and record.window_start_simulation_msec != previous_end: return "Retained record windows are not contiguous."
		var details := _validate_window(record.window_start_simulation_msec, record.window_end_simulation_msec, record.foreground_elapsed_msec, record.offline_elapsed_msec, record.debug_elapsed_msec, record.settlement_events.size() + 1, record.slices, record.settlement_events)
		if not details.is_empty(): return "Retained record %d is invalid: %s" % [record.record_sequence, details]
		previous_end = record.window_end_simulation_msec
		expected_sequence += 1
	if previous_end != ledger.window_start_simulation_msec: return "Final retained record does not meet the live window."
	return ""

static func _validate_window(start: int, finish: int, foreground: int, offline: int, debug: int, next_event: int, slices: Array[ReportLedgerSlice], events: Array[ReportSettlementEvent]) -> String:
	if start < 0 or finish < start or foreground < 0 or offline < 0 or debug < 0 or next_event < 1: return "Window root values are invalid."
	var duration_sum := _add(foreground, offline)
	if not duration_sum.ok: return "Mode duration overflow."
	duration_sum = _add(duration_sum.value, debug)
	if not duration_sum.ok or duration_sum.value != finish - start: return "Mode duration coverage is invalid."
	var mode_elapsed := {&"FOREGROUND_SUPPLIED": 0, &"OFFLINE_FIXTURE": 0, &"DEBUG": 0}
	var last_end := start
	for slice in slices:
		var slice_details := _validate_slice(slice, start, finish, last_end)
		if not slice_details.is_empty(): return slice_details
		var elapsed := slice.end_simulation_msec - slice.start_simulation_msec
		var added := _add(int(mode_elapsed[slice.run_mode]), elapsed)
		if not added.ok: return "Slice duration overflow."
		mode_elapsed[slice.run_mode] = added.value
		last_end = slice.end_simulation_msec
	if int(mode_elapsed[&"FOREGROUND_SUPPLIED"]) > foreground or int(mode_elapsed[&"OFFLINE_FIXTURE"]) > offline or int(mode_elapsed[&"DEBUG"]) > debug:
		return "Slice mode coverage exceeds root coverage."
	for index in range(1, slices.size()):
		if _merge_compatible(slices[index - 1], slices[index]): return "Adjacent slices are not maximal."
	return _validate_events(start, finish, next_event, slices, events)

static func _validate_slice(slice: ReportLedgerSlice, window_start: int, window_end: int, previous_end: int) -> String:
	if slice == null or not MODES.has(slice.run_mode) or slice.content_revision.is_empty() or str(slice.threshold_id).is_empty() or slice.assignment_revision <= 0 or str(slice.form_id).is_empty() or str(slice.writ_id).is_empty(): return "Slice identity is invalid."
	var seen_retinue := {}
	for retinue in slice.ordered_retinue_ids:
		if str(retinue).is_empty() or seen_retinue.has(retinue): return "Retinue identity is invalid."
		seen_retinue[retinue] = true
	if not [&"OVERDUE", &"SETTLED"].has(slice.lifecycle_state) or slice.start_simulation_msec < window_start or slice.start_simulation_msec < previous_end or slice.end_simulation_msec <= slice.start_simulation_msec or slice.end_simulation_msec > window_end: return "Slice timing is invalid."
	if slice.returned_souls_delta < 0 or slice.remaining_backlog_before < 0 or slice.remaining_backlog_after < 0 or slice.remaining_backlog_after > slice.remaining_backlog_before or slice.essence_delta < 0 or slice.mastery_delta_subunits < 0 or slice.completed_cycles_delta < 0: return "Slice values are invalid."
	if slice.lifecycle_state == &"OVERDUE" and slice.remaining_backlog_before <= 0: return "Overdue slice must start with backlog."
	if slice.lifecycle_state == &"SETTLED" and (slice.remaining_backlog_before != 0 or slice.remaining_backlog_after != 0): return "Settled slice endpoints are invalid."
	var previous_id := ""
	for channel in slice.channels:
		if channel == null or str(channel.channel_id).is_empty() or str(channel.output_item_id).is_empty() or (not previous_id.is_empty() and str(channel.channel_id) <= previous_id): return "Channel ordering is invalid."
		previous_id = str(channel.channel_id)
		if channel.start_simulation_msec < slice.start_simulation_msec or channel.end_simulation_msec <= channel.start_simulation_msec or channel.end_simulation_msec > slice.end_simulation_msec or channel.progress_subunits_before < 0 or channel.progress_subunits_before >= FixedPoint.SCALE or channel.progress_subunits_after < 0 or channel.progress_subunits_after >= FixedPoint.SCALE or channel.rate_period_msec <= 0 or channel.rate_carry_units_before < 0 or channel.rate_carry_units_before >= channel.rate_period_msec or channel.rate_carry_units_after < 0 or channel.rate_carry_units_after >= channel.rate_period_msec or channel.total_banked_units_before < 0 or channel.total_banked_units_after < channel.total_banked_units_before: return "Channel endpoints are invalid."
	return ""

static func _validate_events(window_start: int, window_end: int, next_event: int, slices: Array[ReportLedgerSlice], events: Array[ReportSettlementEvent]) -> String:
	var expected := {}
	for slice in slices:
		if slice.lifecycle_state == &"OVERDUE" and slice.remaining_backlog_after == 0: expected[slice.threshold_id] = slice
	var settled := {}
	var previous_time := window_start
	for index in range(events.size()):
		var event: ReportSettlementEvent = events[index]
		if event == null or event.event_sequence != index + 1 or event.event_sequence >= next_event or event.content_revision.is_empty() or str(event.threshold_id).is_empty() or event.assignment_revision <= 0 or event.occurred_simulation_msec <= window_start or event.occurred_simulation_msec > window_end or event.occurred_simulation_msec < previous_time or event.persistent_returns_total < 0 or settled.has(event.threshold_id): return "Settlement event shape is invalid."
		if not expected.has(event.threshold_id): return "Settlement event has no owning slice."
		var owner: ReportLedgerSlice = expected[event.threshold_id]
		if event.content_revision != owner.content_revision or event.assignment_revision != owner.assignment_revision or event.occurred_simulation_msec != owner.end_simulation_msec: return "Settlement event does not match its slice."
		settled[event.threshold_id] = true
		previous_time = event.occurred_simulation_msec
	if next_event != events.size() + 1: return "Next event sequence is invalid."
	for threshold_id in expected:
		if not settled.has(threshold_id): return "Settlement event is required."
	return ""

static func _validate_continuations(ledger: ReportLedger) -> String:
	var previous_threshold := ""
	for continuation in ledger.threshold_continuations:
		if continuation == null or str(continuation.threshold_id).is_empty() or continuation.latest_assignment_revision <= 0 or str(continuation.form_id).is_empty() or str(continuation.writ_id).is_empty() or not [&"OVERDUE", &"SETTLED"].has(continuation.lifecycle_state) or continuation.remaining_backlog < 0: return "Threshold continuation shape is invalid."
		if not _continuation_tuple_is_reachable(continuation): return "Threshold continuation lifecycle tuple is invalid."
		if not previous_threshold.is_empty() and str(continuation.threshold_id) <= previous_threshold: return "Threshold continuation ordering is invalid."
		previous_threshold = str(continuation.threshold_id)
		var retinue_seen := {}
		for retinue in continuation.ordered_retinue_ids:
			if str(retinue).is_empty() or retinue_seen.has(retinue): return "Threshold continuation retinue is invalid."
			retinue_seen[retinue] = true
		var previous_channel := ""
		for channel in continuation.channels:
			if channel == null or str(channel.channel_id).is_empty() or str(channel.output_item_id).is_empty() or channel.rate_period_msec <= 0 or channel.progress_subunits < 0 or channel.progress_subunits >= FixedPoint.SCALE or channel.rate_carry_units < 0 or channel.rate_carry_units >= channel.rate_period_msec or channel.total_banked_units < 0: return "Channel continuation shape is invalid."
			if not previous_channel.is_empty() and str(channel.channel_id) <= previous_channel: return "Channel continuation ordering is invalid."
			previous_channel = str(channel.channel_id)
	return ""

static func _validate_detailed_continuity(ledger: ReportLedger) -> String:
	var latest := {}
	var known_channels := {}
	var settled_thresholds := {}
	var seen_events := {}
	for record in ledger.retained_records:
		var record_details := _accumulate_detail(record.slices, record.settlement_events, latest, known_channels, settled_thresholds, seen_events)
		if not record_details.is_empty(): return record_details
	var live_details := _accumulate_detail(ledger.slices, ledger.settlement_events, latest, known_channels, settled_thresholds, seen_events)
	if not live_details.is_empty(): return live_details
	for threshold_id in latest:
		var continuation := _continuation_by_id(ledger, StringName(threshold_id))
		if continuation == null: return "Detailed Threshold has no compact continuation."
		var detail: ReportLedgerSlice = latest[threshold_id]
		if continuation.latest_assignment_revision != detail.assignment_revision or continuation.form_id != detail.form_id or continuation.writ_id != detail.writ_id or continuation.ordered_retinue_ids != detail.ordered_retinue_ids or continuation.lifecycle_state != detail.lifecycle_state or continuation.remaining_backlog != detail.remaining_backlog_after: return "Latest detailed Threshold disagrees with continuation."
		if bool(settled_thresholds.get(threshold_id, false)) != continuation.has_settled: return "Settlement continuation disagrees with detail."
		var detail_channels: Dictionary = known_channels[threshold_id]
		if detail_channels.size() != continuation.channels.size(): return "Continuation channel count disagrees with detail."
		for channel in continuation.channels:
			if not detail_channels.has(channel.channel_id): return "Continuation channel is absent from detail."
			var detail_channel: ReportLedgerChannel = detail_channels[channel.channel_id]
			if channel.output_item_id != detail_channel.output_item_id or channel.rate_period_msec != detail_channel.rate_period_msec or channel.progress_subunits != detail_channel.progress_subunits_after or channel.rate_carry_units != detail_channel.rate_carry_units_after or channel.total_banked_units != detail_channel.total_banked_units_after: return "Continuation channel disagrees with detail."
	return ""

static func _continuation_tuple_is_reachable(continuation: ReportThresholdContinuation) -> bool:
	if continuation.lifecycle_state == &"OVERDUE":
		return (continuation.remaining_backlog > 0 and not continuation.has_settled) or (continuation.remaining_backlog == 0 and continuation.has_settled)
	return continuation.lifecycle_state == &"SETTLED" and continuation.remaining_backlog == 0 and continuation.has_settled

static func _validate_owned_node_identities(ledger: ReportLedger) -> String:
	var seen := {}
	var seen_arrays := []
	if not _track_owned_array(ledger.slices, seen_arrays): return "Ledger-owned mutable report node is reused."
	if not _track_owned_array(ledger.settlement_events, seen_arrays): return "Ledger-owned mutable report node is reused."
	if not _track_owned_array(ledger.retained_records, seen_arrays): return "Ledger-owned mutable report node is reused."
	if not _track_owned_array(ledger.threshold_continuations, seen_arrays): return "Ledger-owned mutable report node is reused."
	for continuation in ledger.threshold_continuations:
		if not _track_owned_node(continuation, seen): return "Ledger-owned mutable report node is reused."
		if continuation != null:
			if not _track_owned_array(continuation.ordered_retinue_ids, seen_arrays): return "Ledger-owned mutable report node is reused."
			if not _track_owned_array(continuation.channels, seen_arrays): return "Ledger-owned mutable report node is reused."
			for channel in continuation.channels:
				if not _track_owned_node(channel, seen): return "Ledger-owned mutable report node is reused."
	for record in ledger.retained_records:
		if not _track_owned_node(record, seen): return "Ledger-owned mutable report node is reused."
		if record != null:
			if not _track_owned_array(record.slices, seen_arrays): return "Ledger-owned mutable report node is reused."
			if not _track_owned_array(record.settlement_events, seen_arrays): return "Ledger-owned mutable report node is reused."
			for slice in record.slices:
				if not _track_owned_node(slice, seen): return "Ledger-owned mutable report node is reused."
				if slice != null:
					if not _track_owned_array(slice.ordered_retinue_ids, seen_arrays): return "Ledger-owned mutable report node is reused."
					if not _track_owned_array(slice.channels, seen_arrays): return "Ledger-owned mutable report node is reused."
					for channel in slice.channels:
						if not _track_owned_node(channel, seen): return "Ledger-owned mutable report node is reused."
			for event in record.settlement_events:
				if not _track_owned_node(event, seen): return "Ledger-owned mutable report node is reused."
	for slice in ledger.slices:
		if not _track_owned_node(slice, seen): return "Ledger-owned mutable report node is reused."
		if slice != null:
			if not _track_owned_array(slice.ordered_retinue_ids, seen_arrays): return "Ledger-owned mutable report node is reused."
			if not _track_owned_array(slice.channels, seen_arrays): return "Ledger-owned mutable report node is reused."
			for channel in slice.channels:
				if not _track_owned_node(channel, seen): return "Ledger-owned mutable report node is reused."
	for event in ledger.settlement_events:
		if not _track_owned_node(event, seen): return "Ledger-owned mutable report node is reused."
	return ""


static func _track_owned_array(container: Array, seen: Array) -> bool:
	for tracked in seen:
		if is_same(tracked, container): return false
	seen.append(container)
	return true
static func _track_owned_node(node: RefCounted, seen: Dictionary) -> bool:
	if node == null: return true
	var identity := node.get_instance_id()
	if seen.has(identity): return false
	seen[identity] = true
	return true

static func _accumulate_detail(slices: Array[ReportLedgerSlice], events: Array[ReportSettlementEvent], latest: Dictionary, known_channels: Dictionary, settled_thresholds: Dictionary, seen_events: Dictionary) -> String:
	for slice in slices:
		var key := slice.threshold_id
		if latest.has(key):
			var prior: ReportLedgerSlice = latest[key]
			if slice.assignment_revision < prior.assignment_revision: return "Assignment revision regressed."
			if slice.assignment_revision == prior.assignment_revision and (slice.form_id != prior.form_id or slice.writ_id != prior.writ_id or slice.ordered_retinue_ids != prior.ordered_retinue_ids): return "Component identity changed."
			if prior.remaining_backlog_after != slice.remaining_backlog_before or (prior.lifecycle_state == &"SETTLED" and slice.lifecycle_state == &"OVERDUE"): return "Threshold continuity is invalid."
			var expected_channels: Dictionary = known_channels[key]
			for prior_id in expected_channels:
				var current := _channel_by_id(slice, StringName(prior_id))
				if current == null: return "Previously seen channel is absent."
				var prior_channel: ReportLedgerChannel = expected_channels[prior_id]
				if prior_channel.output_item_id != current.output_item_id or prior_channel.rate_period_msec != current.rate_period_msec or prior_channel.progress_subunits_after != current.progress_subunits_before or prior_channel.rate_carry_units_after != current.rate_carry_units_before or prior_channel.total_banked_units_after != current.total_banked_units_before: return "Channel continuity is invalid."
		else:
			known_channels[key] = {}
		for channel in slice.channels: known_channels[key][channel.channel_id] = channel
		latest[key] = slice
		if slice.lifecycle_state == &"SETTLED": settled_thresholds[key] = true
	for event in events:
		if seen_events.has(event.threshold_id): return "Settlement event duplicates retained detail."
		seen_events[event.threshold_id] = true
		settled_thresholds[event.threshold_id] = true
	return ""

static func _continuation_by_id(ledger: ReportLedger, threshold_id: StringName) -> ReportThresholdContinuation:
	for continuation in ledger.threshold_continuations:
		if continuation.threshold_id == threshold_id: return continuation
	return null

static func _channel_by_id(slice: ReportLedgerSlice, channel_id: StringName) -> ReportLedgerChannel:
	for channel in slice.channels:
		if channel.channel_id == channel_id: return channel
	return null

static func _merge_compatible(left: ReportLedgerSlice, right: ReportLedgerSlice) -> bool:
	if left.end_simulation_msec != right.start_simulation_msec or left.run_mode != right.run_mode or left.content_revision != right.content_revision or left.threshold_id != right.threshold_id or left.assignment_revision != right.assignment_revision or left.form_id != right.form_id or left.writ_id != right.writ_id or left.ordered_retinue_ids != right.ordered_retinue_ids or left.lifecycle_state != right.lifecycle_state or left.channels.size() != right.channels.size(): return false
	for index in range(left.channels.size()):
		if left.channels[index].channel_id != right.channels[index].channel_id or left.channels[index].output_item_id != right.channels[index].output_item_id or left.channels[index].rate_period_msec != right.channels[index].rate_period_msec or left.channels[index].end_simulation_msec != right.channels[index].start_simulation_msec: return false
	return true

static func _add(left: int, right: int) -> Dictionary:
	if left < 0 or right < 0 or left > INT64_MAX - right: return {"ok": false}
	return {"ok": true, "value": left + right}
