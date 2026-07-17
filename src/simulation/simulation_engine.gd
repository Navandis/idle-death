class_name SimulationEngine
extends RefCounted

## Transactional M04C elapsed-time resolver for zero or one active Reaping.
##
## The engine owns only supplied-duration core production: returned souls,
## Essence, active-Form Mastery, cycle phase/count, operation-owned residuals,
## and the Overdue-to-Settled lifecycle boundary. It does not own clocks,
## scene-tree timing, assignment commands, Retinues, milestones, reports,
## forecasts, tutorial state, persistence bytes, or platform time. Every success
## resolves a deep-cloned candidate and replaces live state once after complete
## validation; every failure leaves the caller's GameState unchanged.

const OK := &""
const ERR_STATE_INVALID := &"SIM_STATE_INVALID"
const ERR_NEGATIVE_ELAPSED := &"SIM_NEGATIVE_ELAPSED"
const ERR_UNSUPPORTED_CONCURRENCY := &"SIM_UNSUPPORTED_CONCURRENCY"
const ERR_UNSUPPORTED_RETINUE := &"SIM_UNSUPPORTED_RETINUE"
const ERR_UNSUPPORTED_FLOW := &"SIM_UNSUPPORTED_FLOW"
const ERR_UNSUPPORTED_MODIFIER := &"SIM_UNSUPPORTED_MODIFIER"
const ERR_OVERFLOW := &"SIM_OVERFLOW"
const ERR_INVALID_RESIDUAL := &"SIM_INVALID_RESIDUAL"
const ERR_INVALID_RATE := &"SIM_INVALID_RATE"
const ERR_INVALID_CONTENT := &"SIM_INVALID_CONTENT"
const ERR_ZERO_BOUNDARY := &"SIM_ZERO_BOUNDARY"

const FLOW_CORE_RETURNS_PROGRESS_SUBUNITS := &"FLOW_CORE_RETURNS_PROGRESS_SUBUNITS"
const FLOW_CORE_RETURNS_RATE_CARRY_UNITS := &"FLOW_CORE_RETURNS_RATE_CARRY_UNITS"
const FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS := &"FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS"
const FLOW_CORE_ESSENCE_RATE_CARRY_UNITS := &"FLOW_CORE_ESSENCE_RATE_CARRY_UNITS"
const FLOW_CORE_MASTERY_RATE_CARRY_UNITS := &"FLOW_CORE_MASTERY_RATE_CARRY_UNITS"
const CORE_FLOW_KEYS := [FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, FLOW_CORE_RETURNS_RATE_CARRY_UNITS, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, FLOW_CORE_MASTERY_RATE_CARRY_UNITS]

const EVENT_THRESHOLD_SETTLED := &"THRESHOLD_SETTLED"
const EVENT_PRIORITY_LIFECYCLE := 200
const CORE_METRICS := ["SOULS_RETURNED_RATE", "ESSENCE_YIELD", "MASTERY_RATE"]
const IRRELEVANT_METRICS := ["DISCOVERY_RATE", "FORECAST_UNCERTAINTY", "RETINUE_CONTRIBUTION", "OUTPUT_CHANNEL_RATE", "SUPPORT_CONSUMPTION", "SETTLED_OUTPUT"]

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

func resolve_elapsed_msec(state: GameState, elapsed_msec: int) -> SimulationResult:
	if elapsed_msec < 0:
		return SimulationResult.failure(ERR_NEGATIVE_ELAPSED, {"elapsed_msec": elapsed_msec}, elapsed_msec)
	var base := _validate_base(state, elapsed_msec)
	if not base.success:
		return base
	if elapsed_msec == 0:
		return SimulationResult.successful(elapsed_msec, 0, SimulationChangeSummary.timeline_only(0), [], [])

	var active_ids := _active_reaping_ids(state)
	if active_ids.size() > 1:
		return SimulationResult.failure(ERR_UNSUPPORTED_CONCURRENCY, {"active_count": active_ids.size()}, elapsed_msec)
	var candidate := state.deep_clone()
	var advance := candidate.advance_simulation_time(elapsed_msec)
	if not advance.ok:
		return SimulationResult.failure(_map_failure_code(advance.code), advance, elapsed_msec)
	var result: SimulationResult
	if active_ids.is_empty():
		result = SimulationResult.successful(elapsed_msec, elapsed_msec, SimulationChangeSummary.timeline_only(elapsed_msec), [], [])
	else:
		result = _resolve_active(candidate, StringName(active_ids[0]), elapsed_msec, state.simulation_time_msec)
	if not result.success:
		return result
	var validation := GameStateValidator.validate(candidate, registry)
	if not validation.ok:
		return SimulationResult.failure(_map_validation_error(validation), validation, elapsed_msec)
	state.replace_from(candidate)
	return result

func _resolve_active(candidate: GameState, reaping_id: StringName, elapsed_msec: int, start_msec: int) -> SimulationResult:
	var reaping: GameState.ReapingState = candidate.reapings[reaping_id]
	if not reaping.retinue_ids.is_empty():
		return SimulationResult.failure(ERR_UNSUPPORTED_RETINUE, {"reaping_id": str(reaping_id)}, elapsed_msec)
	var flow_check := _validate_flow_keys(reaping, elapsed_msec)
	if not flow_check.success:
		return flow_check
	var rate: RatePlan = _build_rate_plan(candidate, reaping)
	if not rate.success:
		return SimulationResult.failure(rate.error_code, rate.developer_details, elapsed_msec)
	var threshold_start: GameState.ThresholdState = candidate.thresholds[reaping.threshold_id]
	var summary := SimulationChangeSummary.production_start(elapsed_msec, reaping.threshold_id, reaping_id, str(threshold_start.lifecycle_state))
	var remaining := elapsed_msec
	var cursor := start_msec
	var segments: Array[SimulationSegment] = []
	var events: Array[SimulationEvent] = []
	var transition_count := 0
	while remaining > 0:
		var threshold: GameState.ThresholdState = candidate.thresholds[reaping.threshold_id]
		var segment_msec := remaining
		var will_settle := false
		if str(threshold.lifecycle_state) == "OVERDUE" and threshold.remaining_backlog > 0:
			var boundary := _settlement_boundary_msec(threshold.remaining_backlog, _get_flow(reaping, FLOW_CORE_RETURNS_PROGRESS_SUBUNITS), _get_flow(reaping, FLOW_CORE_RETURNS_RATE_CARRY_UNITS), rate.returns_rate_subunits_per_period, rate.returns_period_msec, remaining)
			if not boundary.ok:
				return SimulationResult.failure(_map_failure_code(boundary.code), boundary, elapsed_msec)
			if boundary.elapsed_msec <= remaining:
				if boundary.elapsed_msec <= 0:
					return SimulationResult.failure(ERR_ZERO_BOUNDARY, boundary, elapsed_msec)
				segment_msec = boundary.elapsed_msec
				will_settle = true
		var segment := _apply_segment(candidate, reaping, rate, segment_msec, cursor, summary)
		if not segment.success:
			segment.requested_elapsed_msec = elapsed_msec
			return segment
		segments.append(segment.segments[0])
		cursor += segment_msec
		remaining -= segment_msec
		if will_settle:
			transition_count += 1
			if transition_count > 1:
				return SimulationResult.failure(ERR_ZERO_BOUNDARY, {"reason": "repeating settlement boundary"}, elapsed_msec)
			threshold.lifecycle_state = &"SETTLED"
			threshold.remaining_backlog = 0
			events.append(SimulationEvent.settled(cursor, reaping.threshold_id, reaping_id, threshold.persistent_returns_total))
			rate = _build_rate_plan(candidate, reaping)
			if not rate.success:
				return SimulationResult.failure(rate.error_code, rate.developer_details, elapsed_msec)
	summary.lifecycle_after = str(candidate.thresholds[reaping.threshold_id].lifecycle_state)
	return SimulationResult.successful(elapsed_msec, elapsed_msec, summary, segments, events)

func _apply_segment(candidate: GameState, reaping: GameState.ReapingState, rate: RatePlan, elapsed_msec: int, start_msec: int, summary: SimulationChangeSummary) -> SimulationResult:
	if elapsed_msec <= 0:
		return SimulationResult.failure(ERR_ZERO_BOUNDARY, {"elapsed_msec": elapsed_msec}, 0)
	var threshold: GameState.ThresholdState = candidate.thresholds[reaping.threshold_id]
	var lifecycle_context := str(threshold.lifecycle_state)
	var backlog_before := threshold.remaining_backlog
	var returns := _accumulate_extract(reaping, FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, FLOW_CORE_RETURNS_RATE_CARRY_UNITS, rate.returns_rate_subunits_per_period, rate.returns_period_msec, elapsed_msec)
	if not returns.ok:
		return SimulationResult.failure(_map_failure_code(returns.code), returns, 0)
	if returns.whole > 0 and threshold.persistent_returns_total > FixedPoint.INT64_MAX - returns.whole:
		return SimulationResult.failure(ERR_OVERFLOW, {"field": "persistent_returns_total"}, 0)
	threshold.persistent_returns_total += returns.whole
	if lifecycle_context == "OVERDUE":
		threshold.remaining_backlog = max(0, threshold.remaining_backlog - returns.whole)
	var backlog_delta := backlog_before - threshold.remaining_backlog
	summary.returned_souls_delta += returns.whole
	summary.backlog_reduced += backlog_delta

	var essence := _accumulate_extract(reaping, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, rate.essence_rate_subunits_per_period, rate.essence_period_msec, elapsed_msec)
	if not essence.ok:
		return SimulationResult.failure(_map_failure_code(essence.code), essence, 0)
	if essence.whole > 0:
		var entry: GameState.InventoryEntryState = candidate.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new())
		if entry.total > FixedPoint.INT64_MAX - essence.whole:
			return SimulationResult.failure(ERR_OVERFLOW, {"field": "RES_ESSENCE"}, 0)
		entry.total += essence.whole
		candidate.inventory.entries[&"RES_ESSENCE"] = entry
	summary.essence_delta += essence.whole

	var mastery_accum := FixedPoint.accumulate_for_elapsed_msec(rate.mastery_rate_subunits_per_period, rate.mastery_period_msec, elapsed_msec, _get_flow(reaping, FLOW_CORE_MASTERY_RATE_CARRY_UNITS))
	if not mastery_accum.ok:
		return SimulationResult.failure(_map_failure_code(mastery_accum.code), mastery_accum, 0)
	var form: GameState.FormState = candidate.forms[reaping.form_id]
	if form.mastery_subunits > FixedPoint.INT64_MAX - mastery_accum.produced_subunits:
		return SimulationResult.failure(ERR_OVERFLOW, {"field": "mastery_subunits"}, 0)
	form.mastery_subunits += mastery_accum.produced_subunits
	reaping.flow_carry_units[FLOW_CORE_MASTERY_RATE_CARRY_UNITS] = mastery_accum.carry_units
	summary.mastery_delta_subunits += mastery_accum.produced_subunits

	if reaping.cycle_phase_msec > FixedPoint.INT64_MAX - elapsed_msec:
		return SimulationResult.failure(ERR_OVERFLOW, {"field": "cycle_phase_msec"}, 0)
	var total_phase := reaping.cycle_phase_msec + elapsed_msec
	var cycles: int = total_phase / rate.cycle_duration_msec
	if reaping.completed_cycle_count > FixedPoint.INT64_MAX - cycles:
		return SimulationResult.failure(ERR_OVERFLOW, {"field": "completed_cycle_count"}, 0)
	reaping.completed_cycle_count += cycles
	reaping.cycle_phase_msec = total_phase % rate.cycle_duration_msec
	summary.completed_cycles_delta += cycles
	return SimulationResult.successful(0, 0, summary, [SimulationSegment.new(start_msec, start_msec + elapsed_msec, lifecycle_context, returns.whole, backlog_delta, essence.whole, mastery_accum.produced_subunits, cycles)], [])

func _accumulate_extract(reaping: GameState.ReapingState, progress_key: StringName, carry_key: StringName, rate_subunits: int, period_msec: int, elapsed_msec: int) -> Dictionary:
	var accumulated := FixedPoint.accumulate_for_elapsed_msec(rate_subunits, period_msec, elapsed_msec, _get_flow(reaping, carry_key))
	if not accumulated.ok:
		return accumulated
	var added := FixedPoint.add_subunits(_get_flow(reaping, progress_key), accumulated.produced_subunits)
	if not added.ok:
		return added
	var extracted := FixedPoint.extract_whole(added.subunits)
	reaping.flow_carry_units[progress_key] = extracted.remaining_subunits
	reaping.flow_carry_units[carry_key] = accumulated.carry_units
	return {"ok": true, "whole": extracted.whole_units}

func _settlement_boundary_msec(backlog: int, progress: int, carry: int, rate_subunits: int, period_msec: int, max_elapsed_msec: int) -> Dictionary:
	var max_result := _whole_returns_after_elapsed(progress, carry, rate_subunits, period_msec, max_elapsed_msec)
	if not max_result.ok:
		return max_result
	if max_result.whole < backlog:
		return {"ok": true, "elapsed_msec": FixedPoint.INT64_MAX}
	var low := 1
	var high := max_elapsed_msec
	while low < high:
		var mid: int = (low + high) / 2
		var mid_result := _whole_returns_after_elapsed(progress, carry, rate_subunits, period_msec, mid)
		if not mid_result.ok:
			return mid_result
		if mid_result.whole >= backlog:
			high = mid
		else:
			low = mid + 1
	return {"ok": true, "elapsed_msec": low}

func _whole_returns_after_elapsed(progress: int, carry: int, rate_subunits: int, period_msec: int, elapsed_msec: int) -> Dictionary:
	var acc := FixedPoint.accumulate_for_elapsed_msec(rate_subunits, period_msec, elapsed_msec, carry)
	if not acc.ok:
		return acc
	var total := FixedPoint.add_subunits(progress, acc.produced_subunits)
	if not total.ok:
		return total
	return {"ok": true, "whole": total.subunits / FixedPoint.SCALE}

func _build_rate_plan(state: GameState, reaping: GameState.ReapingState) -> RatePlan:
	var form_result := registry.get_record(str(reaping.form_id))
	var threshold_result := registry.get_record(str(reaping.threshold_id))
	if not form_result.ok or not threshold_result.ok:
		return RatePlan.failure(ERR_INVALID_CONTENT, {"form_id": str(reaping.form_id), "threshold_id": str(reaping.threshold_id)})
	var form_record: Dictionary = form_result.record
	var threshold_record: Dictionary = threshold_result.record
	var essence_result := _find_single_essence_channel(threshold_record, reaping.threshold_id)
	if not essence_result.ok:
		return RatePlan.failure(ERR_INVALID_CONTENT, essence_result)
	var essence_record: Dictionary = essence_result.record
	var returns_rate: int = form_record.base_returned_souls_rate.rate_subunits_per_period
	var essence_rate: int = essence_record.rate.rate_subunits_per_period
	var mastery_rate: int = form_record.active_mastery_rate.rate_subunits_per_period
	for trait_record in form_record.traits:
		for modifier in trait_record.modifiers:
			var metric := str(modifier.metric)
			if CORE_METRICS.has(metric):
				var target_rate := returns_rate
				if metric == "ESSENCE_YIELD": target_rate = essence_rate
				elif metric == "MASTERY_RATE": target_rate = mastery_rate
				var applied := _apply_core_modifier(target_rate, modifier, threshold_record)
				if not applied.ok:
					return RatePlan.failure(ERR_UNSUPPORTED_MODIFIER, {"modifier": modifier, "reason": applied.code})
				if metric == "SOULS_RETURNED_RATE": returns_rate = applied.value
				elif metric == "ESSENCE_YIELD": essence_rate = applied.value
				elif metric == "MASTERY_RATE": mastery_rate = applied.value
			elif IRRELEVANT_METRICS.has(metric):
				continue
			else:
				return RatePlan.failure(ERR_UNSUPPORTED_MODIFIER, {"modifier": modifier, "reason": "unknown metric"})
	if str(state.thresholds[reaping.threshold_id].lifecycle_state) == "SETTLED":
		var settled_returns := FixedPoint.multiply_scaled_floor(returns_rate, threshold_record.settled_multiplier_subunits)
		if not settled_returns.ok: return RatePlan.failure(_map_failure_code(settled_returns.code), settled_returns)
		returns_rate = settled_returns.value
		var settled_essence := FixedPoint.multiply_scaled_floor(essence_rate, essence_record.settled_multiplier_subunits)
		if not settled_essence.ok: return RatePlan.failure(_map_failure_code(settled_essence.code), settled_essence)
		essence_rate = settled_essence.value
	if _invalid_rate(returns_rate, form_record.base_returned_souls_rate.period_msec) or _invalid_rate(essence_rate, essence_record.rate.period_msec) or _invalid_rate(mastery_rate, form_record.active_mastery_rate.period_msec) or int(form_record.cycle_duration_msec) <= 0:
		return RatePlan.failure(ERR_INVALID_RATE, {"form_id": str(reaping.form_id), "threshold_id": str(reaping.threshold_id)})
	return RatePlan.successful(returns_rate, form_record.base_returned_souls_rate.period_msec, essence_rate, essence_record.rate.period_msec, mastery_rate, form_record.active_mastery_rate.period_msec, form_record.cycle_duration_msec)

func _find_single_essence_channel(threshold_record: Dictionary, threshold_id: StringName) -> Dictionary:
	var matches: Array[Dictionary] = []
	for channel_id in threshold_record.channel_ids:
		var channel_result := registry.get_record(channel_id)
		if channel_result.ok and channel_result.record.type == "channel" and channel_result.record.enabled and channel_result.record.source_threshold_id == str(threshold_id) and channel_result.record.output_item_id == "RES_ESSENCE":
			matches.append(channel_result.record)
	if matches.size() != 1:
		return {"ok": false, "code": ERR_INVALID_CONTENT, "match_count": matches.size(), "threshold_id": str(threshold_id)}
	return {"ok": true, "record": matches[0]}

func _apply_core_modifier(rate: int, modifier: Dictionary, threshold_record: Dictionary) -> Dictionary:
	if modifier.operation != "MULTIPLY" or modifier.scope != "REAPING_TOTAL":
		return {"ok": false, "code": ERR_UNSUPPORTED_MODIFIER}
	match str(modifier.condition):
		"ALWAYS":
			if not modifier.condition_values.is_empty(): return {"ok": false, "code": ERR_UNSUPPORTED_MODIFIER}
		"THRESHOLD_HAS_ANY_TAG":
			var matches := false
			for tag in modifier.condition_values:
				if threshold_record.tags.has(tag): matches = true
			if not matches: return {"ok": true, "value": rate}
		_:
			return {"ok": false, "code": ERR_UNSUPPORTED_MODIFIER}
	var multiplied := FixedPoint.multiply_scaled_floor(rate, modifier.value_subunits)
	if not multiplied.ok:
		return {"ok": false, "code": _map_failure_code(multiplied.code)}
	return {"ok": true, "value": multiplied.value}

func _invalid_rate(rate_subunits: int, period_msec: int) -> bool:
	return rate_subunits < 0 or period_msec <= 0

func _validate_base(state: GameState, elapsed_msec: int) -> SimulationResult:
	var validation := GameStateValidator.validate(state, registry)
	if not validation.ok:
		return SimulationResult.failure(_map_validation_error(validation), validation, elapsed_msec)
	return SimulationResult.successful(elapsed_msec, 0, SimulationChangeSummary.timeline_only(0), [], [])

func _validate_flow_keys(reaping: GameState.ReapingState, elapsed_msec: int) -> SimulationResult:
	for key in reaping.flow_carry_units.keys():
		if not CORE_FLOW_KEYS.has(key) and int(reaping.flow_carry_units[key]) != 0:
			return SimulationResult.failure(ERR_UNSUPPORTED_FLOW, {"flow_key": str(key)}, elapsed_msec)
	return SimulationResult.successful(elapsed_msec, 0, SimulationChangeSummary.timeline_only(0), [], [])

func _active_reaping_ids(state: GameState) -> Array:
	var ids := []
	for key in state.reapings.keys():
		if state.reapings[key].is_active: ids.append(key)
	ids.sort()
	return ids

func _get_flow(reaping: GameState.ReapingState, key: StringName) -> int:
	return int(reaping.flow_carry_units.get(key, 0))

func _map_validation_error(validation: Dictionary) -> StringName:
	if validation.code == GameStateValidator.ERR_CORE_RESIDUAL:
		return ERR_INVALID_RESIDUAL
	if validation.code == GameStateValidator.ERR_CONTENT:
		return ERR_INVALID_CONTENT
	return ERR_STATE_INVALID

func _map_failure_code(code: Variant) -> StringName:
	match str(code):
		FixedPoint.ERR_INVALID_CARRY, FixedPoint.ERR_NEGATIVE_INPUT:
			return ERR_INVALID_RESIDUAL
		FixedPoint.ERR_INVALID_PERIOD:
			return ERR_INVALID_RATE
		FixedPoint.ERR_OVERFLOW, GameState.ERR_TIME_OVERFLOW:
			return ERR_OVERFLOW
	return StringName(str(code))

class RatePlan:
	extends RefCounted
	var success := false
	var error_code: StringName = &""
	var developer_details := {}
	var returns_rate_subunits_per_period := 0
	var returns_period_msec := 0
	var essence_rate_subunits_per_period := 0
	var essence_period_msec := 0
	var mastery_rate_subunits_per_period := 0
	var mastery_period_msec := 0
	var cycle_duration_msec := 0
	static func successful(rr:int, rp:int, er:int, ep:int, mr:int, mp:int, cd:int) -> RatePlan:
		var p := RatePlan.new()
		p.success = true; p.returns_rate_subunits_per_period = rr; p.returns_period_msec = rp; p.essence_rate_subunits_per_period = er; p.essence_period_msec = ep; p.mastery_rate_subunits_per_period = mr; p.mastery_period_msec = mp; p.cycle_duration_msec = cd
		return p
	static func failure(code: StringName, details: Dictionary) -> RatePlan:
		var p := RatePlan.new(); p.error_code = code; p.developer_details = details; return p

class SimulationChangeSummary:
	extends RefCounted
	var simulation_time_delta_msec := 0
	var returned_souls_delta := 0
	var backlog_reduced := 0
	var essence_delta := 0
	var mastery_delta_subunits := 0
	var completed_cycles_delta := 0
	var lifecycle_before := ""
	var lifecycle_after := ""
	var threshold_id: StringName = &""
	var operation_id: StringName = &""
	static func timeline_only(delta_msec: int) -> SimulationChangeSummary:
		var s := SimulationChangeSummary.new(); s.simulation_time_delta_msec = delta_msec; return s
	static func production_start(delta_msec: int, threshold: StringName, operation: StringName, lifecycle: String) -> SimulationChangeSummary:
		var s := timeline_only(delta_msec); s.threshold_id = threshold; s.operation_id = operation; s.lifecycle_before = lifecycle; s.lifecycle_after = lifecycle; return s

class SimulationSegment:
	extends RefCounted
	var start_simulation_msec := 0
	var end_simulation_msec := 0
	var elapsed_msec := 0
	var lifecycle := ""
	var returned_souls := 0
	var backlog_reduced := 0
	var essence := 0
	var mastery_subunits := 0
	var completed_cycles := 0
	func _init(start_value:=0, end_value:=0, lifecycle_value:="", returns_value:=0, backlog_value:=0, essence_value:=0, mastery_value:=0, cycles_value:=0) -> void:
		start_simulation_msec = start_value; end_simulation_msec = end_value; elapsed_msec = end_value - start_value; lifecycle = lifecycle_value; returned_souls = returns_value; backlog_reduced = backlog_value; essence = essence_value; mastery_subunits = mastery_value; completed_cycles = cycles_value

class SimulationEvent:
	extends RefCounted
	var event_type: StringName
	var occurred_simulation_msec := 0
	var priority := EVENT_PRIORITY_LIFECYCLE
	var subject_id: StringName
	var source_id: StringName
	var payload := {}
	var reportable := true
	var tutorial_relevant := true
	static func settled(time:int, threshold_id:StringName, reaping_id:StringName, returns_total:int) -> SimulationEvent:
		var e := SimulationEvent.new(); e.event_type = EVENT_THRESHOLD_SETTLED; e.occurred_simulation_msec = time; e.subject_id = threshold_id; e.source_id = reaping_id; e.payload = {"threshold_id": str(threshold_id), "lifecycle_state": "SETTLED", "remaining_backlog": 0, "persistent_returns_total": returns_total}; return e

class SimulationResult:
	extends RefCounted
	var success := false
	var error_code: StringName = &""
	var developer_details := {}
	var requested_elapsed_msec := 0
	var committed_elapsed_msec := 0
	var change_summary: SimulationChangeSummary = SimulationChangeSummary.new()
	var segments: Array = []
	var events: Array = []
	static func successful(requested:int, committed:int, summary:SimulationChangeSummary, segment_values:Array, event_values:Array) -> SimulationResult:
		var r := SimulationResult.new(); r.success = true; r.requested_elapsed_msec = requested; r.committed_elapsed_msec = committed; r.change_summary = summary; r.segments = segment_values; r.events = event_values; return r
	static func failure(code:StringName, details:Dictionary, requested:int = 0) -> SimulationResult:
		var r := SimulationResult.new(); r.error_code = code; r.developer_details = details; r.requested_elapsed_msec = requested; r.committed_elapsed_msec = 0; return r
