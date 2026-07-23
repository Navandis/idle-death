class_name SimulationResultProjector
extends RefCounted

## Pure M04E2T2 projection and structural-validation boundary.  It consumes only
## the detached run context and frozen T1 journal evidence, maps facts without
## calculating gameplay, and returns a detached typed SimulationResult.  It never
## receives GameState, clocks, scenes, files, reports, or a caller-authored
## candidate/result, and it cannot authorize the transaction commit.

const INT64_MAX := FixedPoint.INT64_MAX

static func project(context: SimulationRunContext, journal: SimulationFactJournal) -> Dictionary:
	if context == null or journal == null:
		return _failure("Projection requires context and journal.")
	if not journal.is_frozen():
		return _failure("Projection requires a frozen journal.")
	var facts := journal.facts_snapshot()
	var timeline: Dictionary = {}
	var core_facts: Array[Dictionary] = []
	var channel_facts: Array[Dictionary] = []
	var settlement_facts: Array[Dictionary] = []
	for fact in facts:
		match fact.get("kind", &""):
			SimulationFactJournal.KIND_TIMELINE: timeline = fact
			SimulationFactJournal.KIND_CORE_SEGMENT: core_facts.append(fact)
			SimulationFactJournal.KIND_CHANNEL_SEGMENT: channel_facts.append(fact)
			SimulationFactJournal.KIND_SETTLEMENT: settlement_facts.append(fact)
			_:
				return _failure("Projection received an unknown journal fact.")
	if timeline.is_empty(): return _failure("Projection requires one timeline fact.")
	var result_time := int(timeline.get("after_time", context.baseline_simulation_time_msec))
	if core_facts.is_empty():
		var timeline_result := SimulationResult.timeline_only(context.requested_elapsed_msec, context.baseline_simulation_time_msec, result_time, context.content_revision)
		var timeline_validation := validate(timeline_result)
		if not timeline_validation.ok: return timeline_validation
		return {"ok": true, "result": timeline_result}

	var channel_by_segment: Dictionary = {}
	for channel_fact in channel_facts:
		var index := int(channel_fact.segment_index)
		if not channel_by_segment.has(index): channel_by_segment[index] = []
		channel_by_segment[index].append(channel_fact)
	var segments: Array[SimulationSegmentResult] = []
	for core in core_facts:
		var segment_channels: Array[SimulationChannelDeltaResult] = []
		for channel_fact in channel_by_segment.get(int(core.segment_index), []):
			segment_channels.append(SimulationChannelDeltaResult.new(
				StringName(channel_fact.channel_id),
				StringName(channel_fact.output_item_id),
				int(channel_fact.banked_units_delta),
				int(channel_fact.progress_subunits_before),
				int(channel_fact.progress_subunits_after),
				int(channel_fact.period_msec),
				int(channel_fact.rate_carry_units_before),
				int(channel_fact.rate_carry_units_after),
				int(channel_fact.total_banked_units_before),
				int(channel_fact.total_banked_units_after)
			))
		segment_channels.sort_custom(func(a: SimulationChannelDeltaResult, b: SimulationChannelDeltaResult) -> bool: return str(a.channel_id) < str(b.channel_id))
		segments.append(SimulationSegmentResult.new(
			int(core.segment_index),
			StringName(core.threshold_id),
			int(core.assignment_revision),
			StringName(core.form_id),
			StringName(core.writ_id),
			_copy_string_names(core.ordered_retinue_ids),
			StringName(core.lifecycle_state),
			int(core.start_simulation_msec),
			int(core.end_simulation_msec),
			int(core.elapsed_msec),
			int(core.returned_souls_delta),
			-int(core.backlog_delta),
			int(core.Essence_delta),
			int(core.Mastery_delta_subunits),
			int(core.completed_cycles_delta),
			segment_channels
		))

	var events: Array[SimulationEvent] = []
	for settlement in settlement_facts:
		events.append(SimulationThresholdSettledEvent.new(
			int(settlement.occurred_simulation_msec),
			int(settlement.segment_index),
			StringName(settlement.threshold_id),
			int(settlement.persistent_returns_total),
			int(settlement.remaining_backlog_before),
			int(settlement.remaining_backlog_after),
			StringName(settlement.lifecycle_before),
			StringName(settlement.lifecycle_after)
		))
	for channel in channel_facts:
		if int(channel.banked_units_delta) <= 0: continue
		var owning_segment := int(channel.segment_index)
		events.append(SimulationChannelBankedEvent.new(
			int(channel.segment_end_simulation_msec),
			owning_segment,
			StringName(context.threshold_id),
			StringName(channel.channel_id),
			StringName(channel.output_item_id),
			int(channel.banked_units_delta),
			StringName(channel.lifecycle_state),
			int(channel.total_banked_units_after),
			int(channel.progress_subunits_after)
		))
	events.sort_custom(_event_less)
	var result := SimulationResult.active_reaping(context.requested_elapsed_msec, context.baseline_simulation_time_msec, result_time, context.content_revision, segments, events)
	var validation := validate(result)
	if not validation.ok: return validation
	return {"ok": true, "result": result}

static func validate(result: SimulationResult) -> Dictionary:
	if result == null: return _failure("Result is null.")
	match result.result_kind:
		SimulationResult.KIND_FAILURE:
			if result.success or str(result.error_code).is_empty() or result.committed_elapsed_msec != 0 or not result.segments.is_empty() or not result.events.is_empty() or result.baseline_simulation_time_msec != result.result_simulation_time_msec:
				return _failure("Failure result shape is invalid.")
			return {"ok": true}
		SimulationResult.KIND_ZERO_DURATION:
			if not result.success or result.requested_elapsed_msec != 0 or result.committed_elapsed_msec != 0 or not result.segments.is_empty() or not result.events.is_empty() or result.baseline_simulation_time_msec != result.result_simulation_time_msec:
				return _failure("Zero-duration result shape is invalid.")
			return {"ok": true}
		SimulationResult.KIND_TIMELINE_ONLY:
			if not _valid_positive_envelope(result) or not result.segments.is_empty() or not result.events.is_empty(): return _failure("Timeline-only result shape is invalid.")
			return {"ok": true}
		SimulationResult.KIND_ACTIVE_REAPING:
			if not _valid_positive_envelope(result) or result.segments.is_empty(): return _failure("Active result envelope is invalid.")
			return _validate_active(result)
		_:
			return _failure("Unknown result kind.")

static func _validate_active(result: SimulationResult) -> Dictionary:
	var segments := result.segments
	var expected_identity := {}
	var total_elapsed := 0
	var previous_end := result.baseline_simulation_time_msec
	var previous_lifecycle := &""
	for index in range(segments.size()):
		var segment: SimulationSegmentResult = segments[index]
		if segment == null or segment.segment_index != index: return _failure("Segment index is not contiguous.")
		if str(segment.threshold_id).is_empty() or segment.assignment_revision <= 0 or str(segment.form_id).is_empty() or str(segment.writ_id).is_empty(): return _failure("Segment identity is invalid.")
		if not [&"OVERDUE", &"SETTLED"].has(segment.lifecycle_state): return _failure("Segment lifecycle is invalid.")
		if not _has_unique_retinues(segment.ordered_retinue_ids): return _failure("Segment Retinue identity contains duplicates.")
		if segment.start_simulation_msec != previous_end or segment.start_simulation_msec < 0 or segment.end_simulation_msec <= segment.start_simulation_msec or segment.elapsed_msec != segment.end_simulation_msec - segment.start_simulation_msec: return _failure("Segment timing is invalid.")
		if segment.end_simulation_msec > result.result_simulation_time_msec: return _failure("Segment exceeds result cursor.")
		if not _checked_add(total_elapsed, segment.elapsed_msec).ok: return _failure("Segment elapsed aggregation overflow.")
		total_elapsed += segment.elapsed_msec
		if segment.returned_souls_delta < 0 or segment.backlog_reduced < 0 or segment.essence_delta < 0 or segment.mastery_delta_subunits < 0 or segment.completed_cycles_delta < 0: return _failure("Segment delta is negative.")
		var identity := "%s|%s|%s|%s|%s" % [segment.threshold_id, segment.assignment_revision, segment.form_id, segment.writ_id, segment.ordered_retinue_ids]
		if index == 0: expected_identity["value"] = identity
		elif expected_identity.value != identity: return _failure("Historical segment identity changed within a run.")
		if index > 0 and previous_lifecycle == &"SETTLED" and segment.lifecycle_state != &"SETTLED": return _failure("Settled lifecycle regressed.")
		previous_lifecycle = segment.lifecycle_state
		var channels := segment.channel_deltas
		var previous_channel := ""
		for channel in channels:
			if channel == null or str(channel.channel_id).is_empty() or str(channel.output_item_id).is_empty(): return _failure("Channel identity is invalid.")
			if previous_channel != "" and str(channel.channel_id) <= previous_channel: return _failure("Channel IDs are not unique and canonical.")
			previous_channel = str(channel.channel_id)
			var channel_validation := _validate_channel(channel)
			if not channel_validation.ok: return channel_validation
		previous_end = segment.end_simulation_msec
	if segments.size() > 2 or (segments.size() == 2 and (segments[0].lifecycle_state != &"OVERDUE" or segments[1].lifecycle_state != &"SETTLED")):
		return _failure("Current resolver produced an unsupported lifecycle sequence.")
	if total_elapsed != result.committed_elapsed_msec or previous_end != result.result_simulation_time_msec: return _failure("Segments do not cover the committed interval.")
	return _validate_events(result)

static func _validate_channel(channel: SimulationChannelDeltaResult) -> Dictionary:
	if channel.rate_period_msec <= 0 or channel.banked_units_delta < 0 or channel.progress_subunits_before < 0 or channel.progress_subunits_before >= FixedPoint.SCALE or channel.progress_subunits_after < 0 or channel.progress_subunits_after >= FixedPoint.SCALE or channel.rate_carry_units_before < 0 or channel.rate_carry_units_before >= channel.rate_period_msec or channel.rate_carry_units_after < 0 or channel.rate_carry_units_after >= channel.rate_period_msec or channel.total_banked_units_before < 0 or channel.total_banked_units_after < 0 or channel.total_banked_units_after < channel.total_banked_units_before:
		return _failure("Channel endpoint domain is invalid.")
	if channel.total_banked_units_after - channel.total_banked_units_before != channel.banked_units_delta: return _failure("Channel banked delta does not match totals.")
	return {"ok": true}

static func _validate_events(result: SimulationResult) -> Dictionary:
	var segments := result.segments
	var events := result.events
	var expected_banks := {}
	for segment in segments:
		for channel in segment.channel_deltas:
			if channel.banked_units_delta > 0: expected_banks["%d|%s" % [segment.segment_index, channel.channel_id]] = channel
	var actual_banks := {}
	var settlement_count := 0
	var last_key := ""
	for event in events:
		if not (event is SimulationChannelBankedEvent or event is SimulationThresholdSettledEvent): return _failure("Event is not a closed typed subtype.")
		if event.segment_index < 0 or event.segment_index >= segments.size(): return _failure("Event segment ownership is invalid.")
		var owner: SimulationSegmentResult = segments[event.segment_index]
		if event.occurred_simulation_msec <= owner.start_simulation_msec or event.occurred_simulation_msec > owner.end_simulation_msec: return _failure("Event time is outside its owning segment.")
		var order_key := "%020d|%03d|%s|%s" % [event.occurred_simulation_msec, event.priority, event.subject_id, event.source_id]
		if last_key != "" and order_key < last_key: return _failure("Events are not in stable order.")
		last_key = order_key
		if event is SimulationChannelBankedEvent:
			var bank_event: SimulationChannelBankedEvent = event
			if bank_event.event_type != SimulationEvent.EVENT_OUTPUT_CHANNEL_BANKED or bank_event.priority != SimulationEvent.EVENT_PRIORITY_CHANNEL_GAIN or not bank_event.reportable or not bank_event.tutorial_relevant or bank_event.subject_id != owner.threshold_id or bank_event.quantity <= 0: return _failure("Channel bank event envelope is invalid.")
			var bank_key := "%d|%s" % [bank_event.segment_index, bank_event.source_id]
			if not expected_banks.has(bank_key) or actual_banks.has(bank_key): return _failure("Channel bank event cardinality is invalid.")
			var channel: SimulationChannelDeltaResult = expected_banks[bank_key]
			if bank_event.output_item_id != channel.output_item_id or bank_event.quantity != channel.banked_units_delta or bank_event.lifecycle_state != owner.lifecycle_state or bank_event.total_banked_units_after != channel.total_banked_units_after or bank_event.progress_subunits_after != channel.progress_subunits_after or bank_event.occurred_simulation_msec != owner.end_simulation_msec: return _failure("Channel bank event does not match its channel fact.")
			actual_banks[bank_key] = true
		else:
			var settle_event: SimulationThresholdSettledEvent = event
			settlement_count += 1
			if settle_event.event_type != SimulationEvent.EVENT_THRESHOLD_SETTLED or settle_event.priority != SimulationEvent.EVENT_PRIORITY_LIFECYCLE or not settle_event.reportable or not settle_event.tutorial_relevant or settle_event.subject_id != owner.threshold_id or settle_event.source_id != SimulationEvent.SIMULATION_ENGINE_SOURCE or settle_event.lifecycle_before != &"OVERDUE" or settle_event.lifecycle_after != &"SETTLED" or settle_event.persistent_returns_total < 0 or settle_event.remaining_backlog_before < 0 or settle_event.remaining_backlog_after != 0 or settle_event.remaining_backlog_before < settle_event.remaining_backlog_after or settle_event.occurred_simulation_msec != owner.end_simulation_msec or owner.lifecycle_state != &"OVERDUE": return _failure("Settlement event is invalid.")
	# A two-segment OVERDUE -> SETTLED sequence proves that Settlement evidence
	# is required even when a detached caller has no journal metadata. An exact
	# boundary has one OVERDUE segment, so its typed Settlement event is the
	# self-contained evidence that the event is expected. No caller flag is
	# needed to validate either form.
	var lifecycle_requires_settlement := segments.size() == 2 and segments[0].lifecycle_state == &"OVERDUE" and segments[1].lifecycle_state == &"SETTLED"
	if actual_banks.size() != expected_banks.size() or settlement_count > 1 or (lifecycle_requires_settlement and settlement_count != 1): return _failure("Event cardinality does not match segment facts.")
	return {"ok": true}

static func _valid_positive_envelope(result: SimulationResult) -> bool:
	if not result.success or result.requested_elapsed_msec <= 0 or result.committed_elapsed_msec != result.requested_elapsed_msec or str(result.content_revision).is_empty(): return false
	if result.baseline_simulation_time_msec < 0 or result.result_simulation_time_msec < result.baseline_simulation_time_msec: return false
	return result.result_simulation_time_msec - result.baseline_simulation_time_msec == result.committed_elapsed_msec

static func _checked_add(left: int, right: int) -> Dictionary:
	if left < 0 or right < 0 or left > INT64_MAX - right: return {"ok": false}
	return {"ok": true, "value": left + right}

static func _copy_string_names(values: Array) -> Array[StringName]:
	var copied: Array[StringName] = []
	for value in values: copied.append(StringName(value))
	return copied

static func _has_unique_retinues(values: Array[StringName]) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value): return false
		seen[value] = true
	return true

static func _event_less(left: SimulationEvent, right: SimulationEvent) -> bool:
	if left.occurred_simulation_msec != right.occurred_simulation_msec: return left.occurred_simulation_msec < right.occurred_simulation_msec
	if left.priority != right.priority: return left.priority < right.priority
	if str(left.subject_id) != str(right.subject_id): return str(left.subject_id) < str(right.subject_id)
	return str(left.source_id) < str(right.source_id)

static func _failure(details: String) -> Dictionary:
	return {"ok": false, "code": SimulationEngine.ERR_RESULT_INVALID, "details": details}
