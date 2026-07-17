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
## validation; every failure leaves the caller's GameState byte-for-byte equal
## at the runtime-object level.

const OK := &""
const ERR_STATE_INVALID := &"SIM_STATE_INVALID"
const ERR_NEGATIVE_ELAPSED := &"SIM_NEGATIVE_ELAPSED"
const ERR_UNSUPPORTED_CONCURRENCY := &"SIM_UNSUPPORTED_CONCURRENCY"
const ERR_UNSUPPORTED_RETINUE := &"SIM_UNSUPPORTED_RETINUE"
const ERR_UNSUPPORTED_FLOW := &"SIM_UNSUPPORTED_FLOW"
const ERR_UNSUPPORTED_MODIFIER := &"SIM_UNSUPPORTED_MODIFIER"
const ERR_OVERFLOW := &"SIM_OVERFLOW"
const ERR_ZERO_BOUNDARY := &"SIM_ZERO_BOUNDARY"

const FLOW_CORE_RETURNS_PROGRESS_SUBUNITS := &"FLOW_CORE_RETURNS_PROGRESS_SUBUNITS"
const FLOW_CORE_RETURNS_RATE_CARRY_UNITS := &"FLOW_CORE_RETURNS_RATE_CARRY_UNITS"
const FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS := &"FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS"
const FLOW_CORE_ESSENCE_RATE_CARRY_UNITS := &"FLOW_CORE_ESSENCE_RATE_CARRY_UNITS"
const FLOW_CORE_MASTERY_RATE_CARRY_UNITS := &"FLOW_CORE_MASTERY_RATE_CARRY_UNITS"
const CORE_FLOW_KEYS := [FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, FLOW_CORE_RETURNS_RATE_CARRY_UNITS, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, FLOW_CORE_MASTERY_RATE_CARRY_UNITS]

const EVENT_THRESHOLD_SETTLED := &"THRESHOLD_SETTLED"
const EVENT_PRIORITY_LIFECYCLE := 200

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

func resolve_elapsed_msec(state: GameState, elapsed_msec: int) -> SimulationResult:
	var base := _validate_base(state)
	if not base.success: return base
	if elapsed_msec < 0: return SimulationResult.failure(ERR_NEGATIVE_ELAPSED, {})
	if elapsed_msec == 0: return SimulationResult.successful(0, 0, SimulationChangeSummary.new(), [], [])

	var active_ids := _active_reaping_ids(state)
	if active_ids.size() > 1: return SimulationResult.failure(ERR_UNSUPPORTED_CONCURRENCY, {"active_count": active_ids.size()})
	var before := state.deep_clone()
	var candidate := state.deep_clone()
	var advance := candidate.advance_simulation_time(elapsed_msec)
	if not advance.ok: return SimulationResult.failure(ERR_OVERFLOW, advance)
	var result: SimulationResult
	if active_ids.is_empty():
		result = SimulationResult.successful(elapsed_msec, elapsed_msec, SimulationChangeSummary.new(), [], [])
	else:
		result = _resolve_active(candidate, StringName(active_ids[0]), elapsed_msec, before.simulation_time_msec)
	if not result.success: return result
	var validation := GameStateValidator.validate(candidate, registry)
	if not validation.ok: return SimulationResult.failure(ERR_STATE_INVALID, validation)
	state.replace_from(candidate)
	return result

func _resolve_active(candidate: GameState, reaping_id: StringName, elapsed_msec: int, start_msec: int) -> SimulationResult:
	var reaping: GameState.ReapingState = candidate.reapings[reaping_id]
	if not reaping.retinue_ids.is_empty(): return SimulationResult.failure(ERR_UNSUPPORTED_RETINUE, {"reaping_id": reaping_id})
	var flow_check := _validate_flow_keys(reaping)
	if not flow_check.success: return flow_check
	var rate: RatePlan = _build_rate_plan(candidate, reaping)
	if not rate.success: return SimulationResult.failure(rate.error_code, rate.developer_details)
	var remaining := elapsed_msec
	var cursor := start_msec
	var summary := SimulationChangeSummary.new()
	var segments: Array[SimulationSegment] = []
	var events: Array[SimulationEvent] = []
	while remaining > 0:
		var threshold: GameState.ThresholdState = candidate.thresholds[reaping.threshold_id]
		var segment_msec := remaining
		var will_settle := false
		if str(threshold.lifecycle_state) == "OVERDUE" and threshold.remaining_backlog > 0:
			var boundary := _settlement_boundary_msec(threshold.remaining_backlog, _get_flow(reaping, FLOW_CORE_RETURNS_PROGRESS_SUBUNITS), _get_flow(reaping, FLOW_CORE_RETURNS_RATE_CARRY_UNITS), rate.returns_rate_subunits_per_period, rate.returns_period_msec)
			if not boundary.ok: return SimulationResult.failure(StringName(boundary.code), boundary)
			if boundary.elapsed_msec <= remaining:
				if boundary.elapsed_msec <= 0: return SimulationResult.failure(ERR_ZERO_BOUNDARY, boundary)
				segment_msec = boundary.elapsed_msec
				will_settle = true
		var segment := _apply_segment(candidate, reaping, rate, segment_msec, cursor, summary)
		if not segment.success: return segment
		segments.append(segment.segments[0])
		cursor += segment_msec
		remaining -= segment_msec
		if will_settle:
			threshold.lifecycle_state = &"SETTLED"
			threshold.remaining_backlog = 0
			events.append(SimulationEvent.settled(cursor, reaping.threshold_id, reaping_id, threshold.persistent_returns_total))
			# The rate plan is rebuilt after lifecycle changes so settled multipliers
			# are applied prospectively only; already-earned boundary output keeps the
			# Overdue rate and residual math that produced the final backlog soul.
			rate = _build_rate_plan(candidate, reaping)
			if not rate.success: return SimulationResult.failure(rate.error_code, rate.developer_details)
	return SimulationResult.successful(elapsed_msec, elapsed_msec, summary, segments, events)

func _apply_segment(candidate: GameState, reaping: GameState.ReapingState, rate: RatePlan, elapsed_msec: int, start_msec: int, summary: SimulationChangeSummary) -> SimulationResult:
	var threshold: GameState.ThresholdState = candidate.thresholds[reaping.threshold_id]
	var returns := _accumulate_extract(reaping, FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, FLOW_CORE_RETURNS_RATE_CARRY_UNITS, rate.returns_rate_subunits_per_period, rate.returns_period_msec, elapsed_msec)
	if not returns.ok: return SimulationResult.failure(ERR_OVERFLOW, returns)
	if returns.whole > 0 and threshold.persistent_returns_total > FixedPoint.INT64_MAX - returns.whole: return SimulationResult.failure(ERR_OVERFLOW, {})
	threshold.persistent_returns_total += returns.whole
	if str(threshold.lifecycle_state) == "OVERDUE": threshold.remaining_backlog = max(0, threshold.remaining_backlog - returns.whole)
	summary.returned_souls += returns.whole

	var essence := _accumulate_extract(reaping, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, rate.essence_rate_subunits_per_period, rate.essence_period_msec, elapsed_msec)
	if not essence.ok: return SimulationResult.failure(ERR_OVERFLOW, essence)
	if essence.whole > 0:
		var entry: GameState.InventoryEntryState = candidate.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new())
		if entry.total > FixedPoint.INT64_MAX - essence.whole: return SimulationResult.failure(ERR_OVERFLOW, {})
		entry.total += essence.whole
		candidate.inventory.entries[&"RES_ESSENCE"] = entry
	summary.essence += essence.whole

	var mastery_accum := FixedPoint.accumulate_for_elapsed_msec(rate.mastery_rate_subunits_per_period, rate.mastery_period_msec, elapsed_msec, _get_flow(reaping, FLOW_CORE_MASTERY_RATE_CARRY_UNITS))
	if not mastery_accum.ok: return SimulationResult.failure(ERR_OVERFLOW, mastery_accum)
	var form: GameState.FormState = candidate.forms[reaping.form_id]
	if form.mastery_subunits > FixedPoint.INT64_MAX - mastery_accum.produced_subunits: return SimulationResult.failure(ERR_OVERFLOW, {})
	form.mastery_subunits += mastery_accum.produced_subunits
	reaping.flow_carry_units[FLOW_CORE_MASTERY_RATE_CARRY_UNITS] = mastery_accum.carry_units
	summary.mastery_subunits += mastery_accum.produced_subunits

	if reaping.cycle_phase_msec + elapsed_msec < reaping.cycle_phase_msec: return SimulationResult.failure(ERR_OVERFLOW, {})
	var total_phase := reaping.cycle_phase_msec + elapsed_msec
	var cycles: int = total_phase / rate.cycle_duration_msec
	if reaping.completed_cycle_count > FixedPoint.INT64_MAX - cycles: return SimulationResult.failure(ERR_OVERFLOW, {})
	reaping.completed_cycle_count += cycles
	reaping.cycle_phase_msec = total_phase % rate.cycle_duration_msec
	summary.completed_cycles += cycles
	return SimulationResult.successful(0, 0, summary, [SimulationSegment.new(start_msec, elapsed_msec, str(threshold.lifecycle_state), returns.whole, essence.whole, mastery_accum.produced_subunits, cycles)], [])

func _accumulate_extract(reaping: GameState.ReapingState, progress_key: StringName, carry_key: StringName, rate_subunits: int, period_msec: int, elapsed_msec: int) -> Dictionary:
	var accumulated := FixedPoint.accumulate_for_elapsed_msec(rate_subunits, period_msec, elapsed_msec, _get_flow(reaping, carry_key))
	if not accumulated.ok: return accumulated
	var added := FixedPoint.add_subunits(_get_flow(reaping, progress_key), accumulated.produced_subunits)
	if not added.ok: return added
	var extracted := FixedPoint.extract_whole(added.subunits)
	reaping.flow_carry_units[progress_key] = extracted.remaining_subunits
	reaping.flow_carry_units[carry_key] = accumulated.carry_units
	return {"ok": true, "whole": extracted.whole_units}

func _settlement_boundary_msec(backlog: int, progress: int, carry: int, rate_subunits: int, period_msec: int) -> Dictionary:
	for elapsed in range(1, period_msec + 1):
		var acc := FixedPoint.accumulate_for_elapsed_msec(rate_subunits, period_msec, elapsed, carry)
		if not acc.ok: return acc
		var total := FixedPoint.add_subunits(progress, acc.produced_subunits)
		if not total.ok: return total
		if total.subunits / FixedPoint.SCALE >= backlog:
			return {"ok": true, "elapsed_msec": elapsed}
	return {"ok": true, "elapsed_msec": FixedPoint.INT64_MAX}

func _build_rate_plan(state: GameState, reaping: GameState.ReapingState) -> RatePlan:
	var form_record: Dictionary = registry.get_record(str(reaping.form_id)).record
	var threshold_record: Dictionary = registry.get_record(str(reaping.threshold_id)).record
	var essence_record: Dictionary = {}
	for channel_id in threshold_record.channel_ids:
		var channel: Dictionary = registry.get_record(channel_id).record
		if channel.output_item_id == "RES_ESSENCE": essence_record = channel
	if essence_record.is_empty(): return RatePlan.failure(ERR_STATE_INVALID, {"missing": "RES_ESSENCE channel"})
	var returns_rate: int = form_record.base_returned_souls_rate.rate_subunits_per_period
	for trait_record in form_record.traits:
		for modifier in trait_record.modifiers:
			if modifier.metric == "SOULS_RETURNED_RATE":
				var applied := _apply_supported_multiplier(returns_rate, modifier, threshold_record)
				if not applied.ok: return RatePlan.failure(StringName(applied.code), applied)
				returns_rate = applied.value
			elif modifier.metric in ["RETINUE_CONTRIBUTION"]:
				continue
			else:
				return RatePlan.failure(ERR_UNSUPPORTED_MODIFIER, modifier)
	if str(state.thresholds[reaping.threshold_id].lifecycle_state) == "SETTLED":
		var settled_returns := FixedPoint.multiply_scaled_floor(returns_rate, threshold_record.settled_multiplier_subunits)
		if not settled_returns.ok: return RatePlan.failure(ERR_OVERFLOW, settled_returns)
		returns_rate = settled_returns.value
		var settled_essence := FixedPoint.multiply_scaled_floor(essence_record.rate.rate_subunits_per_period, essence_record.settled_multiplier_subunits)
		if not settled_essence.ok: return RatePlan.failure(ERR_OVERFLOW, settled_essence)
		return RatePlan.successful(returns_rate, form_record.base_returned_souls_rate.period_msec, settled_essence.value, essence_record.rate.period_msec, form_record.active_mastery_rate.rate_subunits_per_period, form_record.active_mastery_rate.period_msec, form_record.cycle_duration_msec)
	return RatePlan.successful(returns_rate, form_record.base_returned_souls_rate.period_msec, essence_record.rate.rate_subunits_per_period, essence_record.rate.period_msec, form_record.active_mastery_rate.rate_subunits_per_period, form_record.active_mastery_rate.period_msec, form_record.cycle_duration_msec)

func _apply_supported_multiplier(rate: int, modifier: Dictionary, threshold_record: Dictionary) -> Dictionary:
	if modifier.operation != "MULTIPLY" or modifier.scope != "REAPING_TOTAL" or modifier.condition != "THRESHOLD_HAS_ANY_TAG": return {"ok": false, "code": ERR_UNSUPPORTED_MODIFIER}
	var matches := false
	for tag in modifier.condition_values:
		if threshold_record.tags.has(tag): matches = true
	if not matches: return {"ok": true, "value": rate}
	return FixedPoint.multiply_scaled_floor(rate, modifier.value_subunits)

func _validate_base(state: GameState) -> SimulationResult:
	var validation := GameStateValidator.validate(state, registry)
	if not validation.ok: return SimulationResult.failure(ERR_STATE_INVALID, validation)
	return SimulationResult.successful(0, 0, SimulationChangeSummary.new(), [], [])

func _validate_flow_keys(reaping: GameState.ReapingState) -> SimulationResult:
	for key in reaping.flow_carry_units.keys():
		if not CORE_FLOW_KEYS.has(key) and int(reaping.flow_carry_units[key]) != 0:
			return SimulationResult.failure(ERR_UNSUPPORTED_FLOW, {"flow_key": str(key)})
	if _get_flow(reaping, FLOW_CORE_RETURNS_PROGRESS_SUBUNITS) >= FixedPoint.SCALE or _get_flow(reaping, FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS) >= FixedPoint.SCALE:
		return SimulationResult.failure(ERR_UNSUPPORTED_FLOW, {"range": "progress"})
	return SimulationResult.successful(0, 0, SimulationChangeSummary.new(), [], [])

func _active_reaping_ids(state: GameState) -> Array:
	var ids := []
	for key in state.reapings.keys():
		if state.reapings[key].is_active: ids.append(key)
	ids.sort()
	return ids

func _get_flow(reaping: GameState.ReapingState, key: StringName) -> int:
	return int(reaping.flow_carry_units.get(key, 0))

class RatePlan:
	extends RefCounted
	var success := false; var error_code: StringName = &""; var developer_details := {}
	var returns_rate_subunits_per_period := 0; var returns_period_msec := 0; var essence_rate_subunits_per_period := 0; var essence_period_msec := 0; var mastery_rate_subunits_per_period := 0; var mastery_period_msec := 0; var cycle_duration_msec := 0
	static func successful(rr:int, rp:int, er:int, ep:int, mr:int, mp:int, cd:int) -> RatePlan:
		var p := RatePlan.new(); p.success = true; p.returns_rate_subunits_per_period = rr; p.returns_period_msec = rp; p.essence_rate_subunits_per_period = er; p.essence_period_msec = ep; p.mastery_rate_subunits_per_period = mr; p.mastery_period_msec = mp; p.cycle_duration_msec = cd; return p
	static func failure(code: StringName, details: Dictionary) -> RatePlan:
		var p := RatePlan.new(); p.error_code = code; p.developer_details = details; return p

class SimulationChangeSummary:
	extends RefCounted
	var returned_souls := 0; var essence := 0; var mastery_subunits := 0; var completed_cycles := 0

class SimulationSegment:
	extends RefCounted
	var start_msec := 0; var elapsed_msec := 0; var lifecycle := ""; var returned_souls := 0; var essence := 0; var mastery_subunits := 0; var completed_cycles := 0
	func _init(start_value:=0, elapsed_value:=0, lifecycle_value:="", returns_value:=0, essence_value:=0, mastery_value:=0, cycles_value:=0) -> void:
		start_msec = start_value; elapsed_msec = elapsed_value; lifecycle = lifecycle_value; returned_souls = returns_value; essence = essence_value; mastery_subunits = mastery_value; completed_cycles = cycles_value

class SimulationEvent:
	extends RefCounted
	var event_type: StringName; var occurred_simulation_msec := 0; var priority := EVENT_PRIORITY_LIFECYCLE; var subject_id: StringName; var source_id: StringName; var payload := {}; var reportable := true; var tutorial_relevant := true
	static func settled(time:int, threshold_id:StringName, reaping_id:StringName, returns_total:int) -> SimulationEvent:
		var e := SimulationEvent.new(); e.event_type = EVENT_THRESHOLD_SETTLED; e.occurred_simulation_msec = time; e.subject_id = threshold_id; e.source_id = reaping_id; e.payload = {"threshold_id": str(threshold_id), "lifecycle_state": "SETTLED", "remaining_backlog": 0, "persistent_returns_total": returns_total}; return e

class SimulationResult:
	extends RefCounted
	var success := false; var error_code: StringName = &""; var developer_details := {}; var requested_elapsed_msec := 0; var committed_elapsed_msec := 0; var change_summary: SimulationChangeSummary; var segments: Array = []; var events: Array = []
	static func successful(requested:int, committed:int, summary:SimulationChangeSummary, segment_values:Array, event_values:Array) -> SimulationResult:
		var r := SimulationResult.new(); r.success = true; r.requested_elapsed_msec = requested; r.committed_elapsed_msec = committed; r.change_summary = summary; r.segments = segment_values; r.events = event_values; return r
	static func failure(code:StringName, details:Dictionary) -> SimulationResult:
		var r := SimulationResult.new(); r.error_code = code; r.developer_details = details; r.change_summary = SimulationChangeSummary.new(); return r
