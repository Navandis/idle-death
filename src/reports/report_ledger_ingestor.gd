class_name ReportLedgerIngestor
extends RefCounted

## Stateless boundary from finalized committed T2 facts to one caller-owned
## normalized ledger candidate.  It never stores the input or returned ledger.

const ERR_LEDGER_REQUIRED := &"REPORT_INGEST_LEDGER_REQUIRED"
const ERR_LEDGER_INVALID := &"REPORT_INGEST_LEDGER_INVALID"
const ERR_RUN_REQUIRED := &"REPORT_INGEST_RUN_REQUIRED"
const ERR_MODE_REJECTED := &"REPORT_INGEST_MODE_REJECTED"
const ERR_RUN_FAILED := &"REPORT_INGEST_RUN_FAILED"
const ERR_PROJECTED := &"REPORT_INGEST_PROJECTED_STATE_REJECTED"
const ERR_WRAPPER := &"REPORT_INGEST_WRAPPER_MISMATCH"
const ERR_RESULT_INVALID := &"REPORT_INGEST_RESULT_INVALID"
const ERR_GAP := &"REPORT_INGEST_FORWARD_GAP"
const ERR_OVERLAP := &"REPORT_INGEST_PARTIAL_OVERLAP"
const ERR_IDENTITY := &"REPORT_INGEST_IDENTITY_MISMATCH"
const ERR_SLICE := &"REPORT_INGEST_SLICE_DISCONTINUITY"
const ERR_CHANNEL := &"REPORT_INGEST_CHANNEL_DISCONTINUITY"
const ERR_OVERFLOW := &"REPORT_INGEST_OVERFLOW"
const ERR_CANDIDATE := &"REPORT_INGEST_CANDIDATE_INVALID"
const INT64_MAX := FixedPoint.INT64_MAX

static func ingest_committed_run(source_ledger: ReportLedger, run: SimulationRunService.SimulationRunResult) -> ReportLedgerIngestResult:
	if source_ledger == null: return _reject(ERR_LEDGER_REQUIRED, "Source ledger is required.")
	var source_validation := ReportLedgerValidator.validate(source_ledger)
	if not source_validation.ok: return _reject(ERR_LEDGER_INVALID, source_validation.details)
	if run == null: return _reject(ERR_RUN_REQUIRED, "Committed run wrapper is required.")
	if not SimulationRunService.COMMITTED_MODES.has(run.mode): return _reject(ERR_MODE_REJECTED, "Run mode is not a committed report mode.")
	if not run.success: return _reject(ERR_RUN_FAILED, "Committed run wrapper did not succeed.")
	if run.projected_state != null: return _reject(ERR_PROJECTED, "Committed report ingestion rejects projected state.")
	var inner: SimulationResult = run.simulation_result
	if inner == null or not _wrapper_matches(run, inner): return _reject(ERR_WRAPPER, "Run wrapper and inner result do not have exact parity.")
	var inner_validation := SimulationResultProjector.validate(inner)
	if not inner_validation.ok: return _reject(ERR_RESULT_INVALID, str(inner_validation.details))
	var interval := _classify(source_ledger.ingested_through_simulation_msec, run.baseline_simulation_time_msec, run.result_simulation_time_msec)
	if interval == ReportLedgerIngestResult.ZERO_DURATION_NO_OP or interval == ReportLedgerIngestResult.DUPLICATE_NO_OP: return ReportLedgerIngestResult.no_op(interval)
	if interval == ERR_GAP: return _reject(ERR_GAP, "Committed interval begins ahead of the ledger cursor.")
	if interval == ERR_OVERLAP: return _reject(ERR_OVERLAP, "Committed interval partially overlaps the ledger cursor.")
	var candidate := source_ledger.deep_clone()
	var duration_result := _add_mode_duration(candidate, run.mode, inner.committed_elapsed_msec)
	if not duration_result.ok: return _reject(ERR_OVERFLOW, duration_result.details)
	if inner.result_kind == SimulationResult.KIND_ACTIVE_REAPING:
		for segment in inner.segments:
			var append_result := _append_segment(candidate, segment, run.mode, inner.content_revision)
			if not append_result.ok: return _reject(StringName(append_result.code), append_result.details)
		var event_result := _append_settlements(candidate, inner)
		if not event_result.ok: return _reject(StringName(event_result.code), event_result.details)
	candidate.ingested_through_simulation_msec = run.result_simulation_time_msec
	var candidate_validation := ReportLedgerValidator.validate(candidate)
	if not candidate_validation.ok: return _reject(ERR_CANDIDATE, candidate_validation.details)
	return ReportLedgerIngestResult.applied(candidate)

static func _wrapper_matches(run: SimulationRunService.SimulationRunResult, inner: SimulationResult) -> bool:
	if run.requested_elapsed_msec != inner.requested_elapsed_msec or inner.committed_elapsed_msec != run.requested_elapsed_msec or run.baseline_simulation_time_msec != inner.baseline_simulation_time_msec or run.result_simulation_time_msec != inner.result_simulation_time_msec or run.success != inner.success: return false
	return run.result_simulation_time_msec - run.baseline_simulation_time_msec == inner.committed_elapsed_msec

static func _classify(cursor: int, start: int, finish: int) -> StringName:
	if start == finish:
		if start == cursor: return ReportLedgerIngestResult.ZERO_DURATION_NO_OP
		return ReportLedgerIngestResult.DUPLICATE_NO_OP if start < cursor else ERR_GAP
	if finish <= cursor: return ReportLedgerIngestResult.DUPLICATE_NO_OP
	if start < cursor: return ERR_OVERLAP
	if start > cursor: return ERR_GAP
	return &"EXACT_NEW"

static func _add_mode_duration(candidate: ReportLedger, mode: StringName, elapsed: int) -> Dictionary:
	var field := ""
	match mode:
		SimulationRunService.MODE_FOREGROUND_SUPPLIED: field = "foreground_elapsed_msec"
		SimulationRunService.MODE_OFFLINE_FIXTURE: field = "offline_elapsed_msec"
		SimulationRunService.MODE_DEBUG: field = "debug_elapsed_msec"
	var added := _add(int(candidate.get(field)), elapsed)
	if not added.ok: return {"ok": false, "details": "Mode duration overflow."}
	candidate.set(field, added.value)
	return {"ok": true}

static func _append_segment(candidate: ReportLedger, segment: SimulationSegmentResult, mode: StringName, content: String) -> Dictionary:
	var next := _slice_from(segment, mode, content)
	var continuity := _check_continuity(candidate, next)
	if not continuity.ok: return continuity
	if not candidate.slices.is_empty() and _can_merge(candidate.slices.back(), next):
		var merge_result := _merge(candidate.slices.back(), next)
		if not merge_result.ok: return merge_result
	else:
		candidate.slices.append(next)
	_update_continuation(candidate, next)
	return {"ok": true}

static func _slice_from(segment: SimulationSegmentResult, mode: StringName, content: String) -> ReportLedgerSlice:
	var slice := ReportLedgerSlice.new()
	slice.run_mode = mode
	slice.content_revision = content
	slice.threshold_id = segment.threshold_id
	slice.assignment_revision = segment.assignment_revision
	slice.form_id = segment.form_id
	slice.writ_id = segment.writ_id
	slice.ordered_retinue_ids.assign(segment.ordered_retinue_ids)
	slice.lifecycle_state = segment.lifecycle_state
	slice.start_simulation_msec = segment.start_simulation_msec
	slice.end_simulation_msec = segment.end_simulation_msec
	slice.returned_souls_delta = segment.returned_souls_delta
	slice.remaining_backlog_before = segment.remaining_backlog_before
	slice.remaining_backlog_after = segment.remaining_backlog_after
	slice.essence_delta = segment.essence_delta
	slice.mastery_delta_subunits = segment.mastery_delta_subunits
	slice.completed_cycles_delta = segment.completed_cycles_delta
	for fact in segment.channel_deltas:
		var channel := ReportLedgerChannel.new()
		channel.channel_id = fact.channel_id
		channel.output_item_id = fact.output_item_id
		channel.start_simulation_msec = segment.start_simulation_msec
		channel.end_simulation_msec = segment.end_simulation_msec
		channel.progress_subunits_before = fact.progress_subunits_before
		channel.progress_subunits_after = fact.progress_subunits_after
		channel.rate_period_msec = fact.rate_period_msec
		channel.rate_carry_units_before = fact.rate_carry_units_before
		channel.rate_carry_units_after = fact.rate_carry_units_after
		channel.total_banked_units_before = fact.total_banked_units_before
		channel.total_banked_units_after = fact.total_banked_units_after
		slice.channels.append(channel)
	return slice

static func _check_continuity(candidate: ReportLedger, next: ReportLedgerSlice) -> Dictionary:
	var prior := _continuation(candidate, next.threshold_id)
	if prior == null: return _legacy_detail_continuity(candidate, next)
	if next.assignment_revision < prior.latest_assignment_revision:
		return {"ok": false, "code": ERR_IDENTITY, "details": "Assignment revision regressed."}
	if next.assignment_revision == prior.latest_assignment_revision and (next.form_id != prior.form_id or next.writ_id != prior.writ_id or next.ordered_retinue_ids != prior.ordered_retinue_ids):
		return {"ok": false, "code": ERR_IDENTITY, "details": "Historical component identity changed."}
	if prior.remaining_backlog != next.remaining_backlog_before or (prior.lifecycle_state == &"SETTLED" and next.lifecycle_state == &"OVERDUE"):
		return {"ok": false, "code": ERR_SLICE, "details": "Threshold backlog or lifecycle is discontinuous."}
	for prior_channel in prior.channels:
		var current := _channel(next, prior_channel.channel_id)
		if current == null: return {"ok": false, "code": ERR_CHANNEL, "details": "A previously seen channel is missing."}
		if prior_channel.output_item_id != current.output_item_id or prior_channel.rate_period_msec != current.rate_period_msec or prior_channel.progress_subunits != current.progress_subunits_before or prior_channel.rate_carry_units != current.rate_carry_units_before or prior_channel.total_banked_units != current.total_banked_units_before:
			return {"ok": false, "code": ERR_CHANNEL, "details": "Channel endpoints are discontinuous."}
	return {"ok": true}

static func _legacy_detail_continuity(candidate: ReportLedger, next: ReportLedgerSlice) -> Dictionary:
	# Direct R1 fixtures may predate R2 continuation entries. Preserve the R1
	# public rejection precedence for those validated caller-created ledgers;
	# candidates produced by this ingestor always gain compact continuation.
	var latest: ReportLedgerSlice = null
	var known_channels := {}
	for prior in candidate.slices:
		if prior.threshold_id != next.threshold_id: continue
		latest = prior
		for channel in prior.channels: known_channels[channel.channel_id] = channel
		if prior.assignment_revision == next.assignment_revision and (prior.form_id != next.form_id or prior.writ_id != next.writ_id or prior.ordered_retinue_ids != next.ordered_retinue_ids):
			return {"ok": false, "code": ERR_IDENTITY, "details": "Historical component identity changed."}
	if latest == null: return {"ok": true}
	if latest.remaining_backlog_after != next.remaining_backlog_before or (latest.lifecycle_state == &"SETTLED" and next.lifecycle_state == &"OVERDUE"):
		return {"ok": false, "code": ERR_SLICE, "details": "Threshold backlog or lifecycle is discontinuous."}
	for prior_id in known_channels:
		var current := _channel(next, StringName(prior_id))
		if current == null: return {"ok": false, "code": ERR_CHANNEL, "details": "A previously seen channel is missing."}
		var previous: ReportLedgerChannel = known_channels[prior_id]
		if previous.output_item_id != current.output_item_id or previous.rate_period_msec != current.rate_period_msec or previous.progress_subunits_after != current.progress_subunits_before or previous.rate_carry_units_after != current.rate_carry_units_before or previous.total_banked_units_after != current.total_banked_units_before:
			return {"ok": false, "code": ERR_CHANNEL, "details": "Channel endpoints are discontinuous."}
	return {"ok": true}

static func _update_continuation(candidate: ReportLedger, slice: ReportLedgerSlice) -> void:
	var continuation := _continuation(candidate, slice.threshold_id)
	if continuation == null:
		continuation = ReportThresholdContinuation.new()
		continuation.threshold_id = slice.threshold_id
		candidate.threshold_continuations.append(continuation)
		candidate.threshold_continuations.sort_custom(func(left, right): return str(left.threshold_id) < str(right.threshold_id))
	continuation.latest_assignment_revision = slice.assignment_revision
	continuation.form_id = slice.form_id
	continuation.writ_id = slice.writ_id
	continuation.ordered_retinue_ids.assign(slice.ordered_retinue_ids)
	continuation.lifecycle_state = slice.lifecycle_state
	continuation.remaining_backlog = slice.remaining_backlog_after
	if slice.lifecycle_state == &"SETTLED": continuation.has_settled = true
	for source_channel in slice.channels:
		var target := _continuation_channel(continuation, source_channel.channel_id)
		if target == null:
			target = ReportChannelContinuation.new()
			target.channel_id = source_channel.channel_id
			continuation.channels.append(target)
		target.output_item_id = source_channel.output_item_id
		target.rate_period_msec = source_channel.rate_period_msec
		target.progress_subunits = source_channel.progress_subunits_after
		target.rate_carry_units = source_channel.rate_carry_units_after
		target.total_banked_units = source_channel.total_banked_units_after
	continuation.channels.sort_custom(func(left, right): return str(left.channel_id) < str(right.channel_id))

static func _can_merge(left: ReportLedgerSlice, right: ReportLedgerSlice) -> bool:
	return ReportLedgerValidator._merge_compatible(left, right)

static func _merge(left: ReportLedgerSlice, right: ReportLedgerSlice) -> Dictionary:
	for field in ["returned_souls_delta", "essence_delta", "mastery_delta_subunits", "completed_cycles_delta"]:
		var added := _add(int(left.get(field)), int(right.get(field)))
		if not added.ok: return {"ok": false, "code": ERR_OVERFLOW, "details": "Slice delta overflow."}
		left.set(field, added.value)
	left.end_simulation_msec = right.end_simulation_msec
	left.remaining_backlog_after = right.remaining_backlog_after
	for index in range(left.channels.size()):
		var target: ReportLedgerChannel = left.channels[index]
		var source: ReportLedgerChannel = right.channels[index]
		target.end_simulation_msec = source.end_simulation_msec
		target.progress_subunits_after = source.progress_subunits_after
		target.rate_carry_units_after = source.rate_carry_units_after
		target.total_banked_units_after = source.total_banked_units_after
	return {"ok": true}

static func _append_settlements(candidate: ReportLedger, inner: SimulationResult) -> Dictionary:
	for event in inner.events:
		if not (event is SimulationThresholdSettledEvent): continue
		var continuation := _continuation(candidate, event.subject_id)
		if continuation == null or continuation.has_settled: return {"ok": false, "code": ERR_SLICE, "details": "Threshold has already settled."}
		var next_sequence := _add(candidate.next_event_sequence, 1)
		if not next_sequence.ok: return {"ok": false, "code": ERR_OVERFLOW, "details": "Settlement event sequence overflow."}
		var owner: SimulationSegmentResult = inner.segments[event.segment_index]
		var normalized := ReportSettlementEvent.new()
		normalized.event_sequence = candidate.next_event_sequence
		normalized.content_revision = inner.content_revision
		normalized.threshold_id = event.subject_id
		normalized.assignment_revision = owner.assignment_revision
		normalized.occurred_simulation_msec = event.occurred_simulation_msec
		normalized.persistent_returns_total = event.persistent_returns_total
		candidate.settlement_events.append(normalized)
		candidate.next_event_sequence = next_sequence.value
		continuation.has_settled = true
	return {"ok": true}

static func _channel(slice: ReportLedgerSlice, channel_id: StringName) -> ReportLedgerChannel:
	for value in slice.channels:
		if value.channel_id == channel_id: return value
	return null

static func _continuation(ledger: ReportLedger, threshold_id: StringName) -> ReportThresholdContinuation:
	for continuation in ledger.threshold_continuations:
		if continuation.threshold_id == threshold_id: return continuation
	return null

static func _continuation_channel(continuation: ReportThresholdContinuation, channel_id: StringName) -> ReportChannelContinuation:
	for channel in continuation.channels:
		if channel.channel_id == channel_id: return channel
	return null

static func _add(left: int, right: int) -> Dictionary:
	if left < 0 or right < 0 or left > INT64_MAX - right: return {"ok": false}
	return {"ok": true, "value": left + right}

static func _reject(code: StringName, details: String) -> ReportLedgerIngestResult:
	return ReportLedgerIngestResult.rejected(code, details)
