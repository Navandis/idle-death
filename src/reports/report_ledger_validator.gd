class_name ReportLedgerValidator
extends RefCounted

const FAILURE := &"REPORT_LEDGER_VALIDATION_FAILED"
const MODES := [&"FOREGROUND_SUPPLIED", &"OFFLINE_FIXTURE", &"DEBUG"]
const INT64_MAX := FixedPoint.INT64_MAX

static func validate(ledger: ReportLedger) -> Dictionary:
	var details := _details(ledger)
	return {"ok": details.is_empty(), "code": &"" if details.is_empty() else FAILURE, "details": details}

static func _details(ledger: ReportLedger) -> String:
	if ledger == null: return "Ledger is required."
	if ledger.window_start_simulation_msec < 0 or ledger.ingested_through_simulation_msec < ledger.window_start_simulation_msec: return "Ledger cursors are invalid."
	if ledger.foreground_elapsed_msec < 0 or ledger.offline_elapsed_msec < 0 or ledger.debug_elapsed_msec < 0 or ledger.next_event_sequence < 1: return "Ledger root values are invalid."
	var duration_sum := _add(ledger.foreground_elapsed_msec, ledger.offline_elapsed_msec)
	if not duration_sum.ok: return "Mode duration overflow."
	duration_sum = _add(duration_sum.value, ledger.debug_elapsed_msec)
	if not duration_sum.ok or duration_sum.value != ledger.ingested_through_simulation_msec - ledger.window_start_simulation_msec: return "Mode duration coverage is invalid."
	var mode_elapsed := {&"FOREGROUND_SUPPLIED": 0, &"OFFLINE_FIXTURE": 0, &"DEBUG": 0}
	var last_end := ledger.window_start_simulation_msec
	var identities := {}
	var threshold_latest := {}
	var threshold_channels := {}
	for slice in ledger.slices:
		var slice_details := _validate_slice(slice, ledger, last_end)
		if not slice_details.is_empty(): return slice_details
		var elapsed := slice.end_simulation_msec - slice.start_simulation_msec
		var added := _add(int(mode_elapsed[slice.run_mode]), elapsed)
		if not added.ok: return "Slice duration overflow."
		mode_elapsed[slice.run_mode] = added.value
		var identity_key := "%s|%d" % [slice.threshold_id, slice.assignment_revision]
		var identity_value := "%s|%s|%s" % [slice.form_id, slice.writ_id, slice.ordered_retinue_ids]
		if identities.has(identity_key) and identities[identity_key] != identity_value: return "Component identity changed."
		identities[identity_key] = identity_value
		if threshold_latest.has(slice.threshold_id):
			var previous: ReportLedgerSlice = threshold_latest[slice.threshold_id]
			if previous.remaining_backlog_after != slice.remaining_backlog_before or (previous.lifecycle_state == &"SETTLED" and slice.lifecycle_state == &"OVERDUE"): return "Threshold continuity is invalid."
			var expected_channels: Dictionary = threshold_channels[slice.threshold_id]
			for prior_id in expected_channels:
				if not _channel_by_id(slice, StringName(prior_id)): return "Previously seen channel is absent."
			for channel in slice.channels:
				if expected_channels.has(channel.channel_id):
					var prior: ReportLedgerChannel = expected_channels[channel.channel_id]
					if prior.output_item_id != channel.output_item_id or prior.rate_period_msec != channel.rate_period_msec \
						or prior.progress_subunits_after != channel.progress_subunits_before or prior.rate_carry_units_after != channel.rate_carry_units_before \
						or prior.total_banked_units_after != channel.total_banked_units_before: return "Channel continuity is invalid."
		else:
			threshold_channels[slice.threshold_id] = {}
		for channel in slice.channels: threshold_channels[slice.threshold_id][channel.channel_id] = channel
		threshold_latest[slice.threshold_id] = slice
		last_end = slice.end_simulation_msec
	if int(mode_elapsed[&"FOREGROUND_SUPPLIED"]) > ledger.foreground_elapsed_msec or int(mode_elapsed[&"OFFLINE_FIXTURE"]) > ledger.offline_elapsed_msec or int(mode_elapsed[&"DEBUG"]) > ledger.debug_elapsed_msec: return "Slice mode coverage exceeds root coverage."
	for index in range(1, ledger.slices.size()):
		if _merge_compatible(ledger.slices[index - 1], ledger.slices[index]): return "Adjacent slices are not maximal."
	return _validate_events(ledger)

static func _validate_slice(slice: ReportLedgerSlice, ledger: ReportLedger, previous_end: int) -> String:
	if slice == null or not MODES.has(slice.run_mode) or slice.content_revision.is_empty() or str(slice.threshold_id).is_empty() or slice.assignment_revision <= 0 or str(slice.form_id).is_empty() or str(slice.writ_id).is_empty(): return "Slice identity is invalid."
	var seen := {}
	for retinue in slice.ordered_retinue_ids:
		if str(retinue).is_empty() or seen.has(retinue): return "Retinue identity is invalid."
		seen[retinue] = true
	if not [&"OVERDUE", &"SETTLED"].has(slice.lifecycle_state) or slice.start_simulation_msec < ledger.window_start_simulation_msec or slice.start_simulation_msec < previous_end or slice.end_simulation_msec <= slice.start_simulation_msec or slice.end_simulation_msec > ledger.ingested_through_simulation_msec: return "Slice timing is invalid."
	if slice.returned_souls_delta < 0 or slice.remaining_backlog_before < 0 or slice.remaining_backlog_after < 0 or slice.remaining_backlog_after > slice.remaining_backlog_before or slice.essence_delta < 0 or slice.mastery_delta_subunits < 0 or slice.completed_cycles_delta < 0: return "Slice values are invalid."
	if slice.lifecycle_state == &"OVERDUE" and slice.remaining_backlog_before <= 0: return "Overdue slice must start with backlog."
	if slice.lifecycle_state == &"SETTLED" and (slice.remaining_backlog_before != 0 or slice.remaining_backlog_after != 0): return "Settled slice endpoints are invalid."
	var previous_id := ""
	for channel in slice.channels:
		if channel == null or str(channel.channel_id).is_empty() or str(channel.output_item_id).is_empty() or (not previous_id.is_empty() and str(channel.channel_id) <= previous_id): return "Channel ordering is invalid."
		previous_id = str(channel.channel_id)
		if channel.start_simulation_msec < slice.start_simulation_msec or channel.end_simulation_msec <= channel.start_simulation_msec or channel.end_simulation_msec > slice.end_simulation_msec or channel.progress_subunits_before < 0 or channel.progress_subunits_before >= FixedPoint.SCALE or channel.progress_subunits_after < 0 or channel.progress_subunits_after >= FixedPoint.SCALE or channel.rate_period_msec <= 0 or channel.rate_carry_units_before < 0 or channel.rate_carry_units_before >= channel.rate_period_msec or channel.rate_carry_units_after < 0 or channel.rate_carry_units_after >= channel.rate_period_msec or channel.total_banked_units_before < 0 or channel.total_banked_units_after < channel.total_banked_units_before: return "Channel endpoints are invalid."
	return ""

static func _validate_events(ledger: ReportLedger) -> String:
	var thresholds := {}
	var expected := {}
	for slice in ledger.slices:
		if slice.lifecycle_state == &"OVERDUE" and slice.remaining_backlog_after == 0: expected[slice.threshold_id] = slice
	var previous_time := ledger.window_start_simulation_msec
	for index in range(ledger.settlement_events.size()):
		var event: ReportSettlementEvent = ledger.settlement_events[index]
		if event == null or event.event_sequence != index + 1 or event.event_sequence >= ledger.next_event_sequence or event.content_revision.is_empty() or str(event.threshold_id).is_empty() or event.assignment_revision <= 0 or event.occurred_simulation_msec <= ledger.window_start_simulation_msec or event.occurred_simulation_msec > ledger.ingested_through_simulation_msec or event.occurred_simulation_msec < previous_time or event.persistent_returns_total < 0 or thresholds.has(event.threshold_id): return "Settlement event shape is invalid."
		if not expected.has(event.threshold_id): return "Settlement event has no owning slice."
		var owner: ReportLedgerSlice = expected[event.threshold_id]
		if event.content_revision != owner.content_revision or event.assignment_revision != owner.assignment_revision or event.occurred_simulation_msec != owner.end_simulation_msec: return "Settlement event does not match its slice."
		thresholds[event.threshold_id] = true
		previous_time = event.occurred_simulation_msec
	if ledger.next_event_sequence != ledger.settlement_events.size() + 1: return "Next event sequence is invalid."
	for threshold_id in expected:
		if not thresholds.has(threshold_id): return "Settlement event is required."
	return ""

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
