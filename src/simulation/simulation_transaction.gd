class_name SimulationTransaction
extends RefCounted

## Single-provenance internal transaction for one SimulationEngine call.
##
## The transaction owns exactly one deep-cloned candidate, one immutable
## SimulationRunContext, one bounded SimulationFactJournal, finalization, and
## the sole live-state commit. It does not own production formulas, boundary
## selection, clocks, persistence, reports, UI, or public result semantics.
## Engine calculations are supplied as checked endpoint plans; this class alone
## applies those plans. Every successful mutation records its fact from the
## candidate's actual before/after values. All time values are milliseconds.

const STATE_OPEN := &"OPEN"
const STATE_FAILED := &"FAILED"
const STATE_FINALIZED := &"FINALIZED"
const STATE_COMMITTED := &"COMMITTED"

const ERR_TRANSACTION_STATE := &"SIM_TRANSACTION_STATE"
const ERR_TRANSACTION_INPUT := &"SIM_TRANSACTION_INPUT"
const ERR_OVERFLOW := &"SIM_OVERFLOW"

var _registry: ContentRegistry
var _source: GameState
var _candidate: GameState
var _context: SimulationRunContext
var _journal: SimulationFactJournal
var state := STATE_OPEN
var _finalized_result: SimulationResult = null
var _current_segment_index := -1

static func open(source_state: GameState, run_context: SimulationRunContext, content_registry: ContentRegistry) -> SimulationTransaction:
	var transaction := SimulationTransaction.new()
	transaction._source = source_state
	transaction._registry = content_registry
	transaction._context = run_context.detached_copy()
	transaction._candidate = source_state.deep_clone()
	transaction._journal = SimulationFactJournal.new(run_context.baseline_simulation_time_msec, run_context.requested_elapsed_msec)
	return transaction

func calculation_snapshot() -> GameState:
	if state != STATE_OPEN: return null
	return _candidate.deep_clone()

func requested_elapsed_msec() -> int:
	return _context.requested_elapsed_msec

func journal_is_frozen() -> bool:
	return _journal.is_frozen()

func next_segment_index() -> int:
	return _current_segment_index + 1

func current_segment_index() -> int:
	return _current_segment_index

func advance_timeline() -> Dictionary:
	if not _is_open(): return _failure(ERR_TRANSACTION_STATE, "Timeline cannot advance after transaction finalization.")
	if not _journal.can_accept(): return _failure(ERR_TRANSACTION_INPUT, "Timeline journal capacity is exhausted.")
	var before := _candidate.simulation_time_msec
	if before != _context.baseline_simulation_time_msec:
		return _failure(ERR_TRANSACTION_INPUT, "Candidate timeline no longer matches the captured run context.")
	if before > FixedPoint.INT64_MAX - _context.requested_elapsed_msec:
		return _failure(ERR_OVERFLOW, "simulation_time_msec")
	var after := before + _context.requested_elapsed_msec
	var timeline := _candidate.advance_simulation_time(_context.requested_elapsed_msec)
	if not timeline.ok: return _failure(ERR_OVERFLOW, "simulation_time_msec")
	var recorded := _journal.record_timeline(before, after)
	if not recorded.ok:
		_candidate.simulation_time_msec = before
		return _failure(ERR_TRANSACTION_INPUT, recorded.details)
	return {"ok": true}

func apply_core_segment(values: Dictionary) -> Dictionary:
	if not _is_open(): return _failure(ERR_TRANSACTION_STATE, "Core mutation is not allowed after finalization.")
	if not _journal.can_accept(): return _failure(ERR_TRANSACTION_INPUT, "Core journal capacity is exhausted.")
	var check := _validate_core_plan(values)
	if not check.ok: return check
	var threshold_id: StringName = _context.threshold_id
	var reaping: GameState.ReapingState = _candidate.reapings[threshold_id]
	var threshold: GameState.ThresholdState = _candidate.thresholds[threshold_id]
	var form: GameState.FormState = _candidate.forms[_context.form_id]
	var inventory_entry: GameState.InventoryEntryState = _candidate.inventory.entries.get(&"RES_ESSENCE", GameState.InventoryEntryState.new())
	# All endpoint checks happen before the first write. This keeps a malformed plan
	# from leaving a half-applied core operation in the private candidate.
	if threshold.persistent_returns_total != int(values.persistent_returns_before) or threshold.remaining_backlog != int(values.remaining_backlog_before):
		return _failure(ERR_TRANSACTION_INPUT, "Core Threshold before endpoints do not match the candidate.")
	if inventory_entry.total != int(values.essence_before) or form.mastery_subunits != int(values.mastery_before):
		return _failure(ERR_TRANSACTION_INPUT, "Core inventory/Form before endpoints do not match the candidate.")
	if reaping.cycle_phase_msec != int(values.cycle_phase_before) or reaping.completed_cycle_count != int(values.completed_cycles_before):
		return _failure(ERR_TRANSACTION_INPUT, "Core Reaping before endpoints do not match the candidate.")
	for flow_key in values.flow_endpoints.keys():
		var endpoint: Dictionary = values.flow_endpoints[flow_key]
		if int(reaping.flow_carry_units.get(flow_key, 0)) != int(endpoint.before):
			return _failure(ERR_TRANSACTION_INPUT, "Core flow before endpoint does not match the candidate.")
	# Apply the complete core mutation only after every before/range check passed.
	threshold.persistent_returns_total = int(values.persistent_returns_after)
	threshold.remaining_backlog = int(values.remaining_backlog_after)
	inventory_entry.total = int(values.essence_after)
	_candidate.inventory.entries[&"RES_ESSENCE"] = inventory_entry
	form.mastery_subunits = int(values.mastery_after)
	reaping.cycle_phase_msec = int(values.cycle_phase_after)
	reaping.completed_cycle_count = int(values.completed_cycles_after)
	for flow_key in values.flow_endpoints.keys():
		var endpoint: Dictionary = values.flow_endpoints[flow_key]
		reaping.flow_carry_units[flow_key] = int(endpoint.after)
	_current_segment_index = int(values.segment_index)
	var fact := values.duplicate(true)
	fact.erase("persistent_returns_before")
	fact.erase("persistent_returns_after")
	fact.erase("remaining_backlog_before")
	fact.erase("remaining_backlog_after")
	fact.erase("essence_before")
	fact.erase("essence_after")
	fact.erase("mastery_before")
	fact.erase("mastery_after")
	fact.erase("cycle_phase_before")
	fact.erase("cycle_phase_after")
	fact.erase("completed_cycles_before")
	fact.erase("completed_cycles_after")
	fact["returned_souls_delta"] = int(values.persistent_returns_after) - int(values.persistent_returns_before)
	fact["backlog_delta"] = int(values.remaining_backlog_after) - int(values.remaining_backlog_before)
	fact["Essence_delta"] = int(values.essence_after) - int(values.essence_before)
	fact["Mastery_delta_subunits"] = int(values.mastery_after) - int(values.mastery_before)
	fact["completed_cycles_delta"] = int(values.completed_cycles_after) - int(values.completed_cycles_before)
	var recorded := _journal.record_core_segment(fact)
	if not recorded.ok:
		return _failure(ERR_TRANSACTION_INPUT, recorded.details)
	return {"ok": true, "segment_index": _current_segment_index}

func apply_channel_segment(values: Dictionary) -> Dictionary:
	if not _is_open(): return _failure(ERR_TRANSACTION_STATE, "Channel mutation is not allowed after finalization.")
	if not _journal.can_accept(): return _failure(ERR_TRANSACTION_INPUT, "Channel journal capacity is exhausted.")
	var check := _validate_channel_plan(values)
	if not check.ok: return check
	var threshold: GameState.ThresholdState = _candidate.thresholds[_context.threshold_id]
	var acq: GameState.ThresholdAcquisitionState = threshold.channel_acquisition[values.channel_id]
	var item_id: StringName = values.output_item_id
	var entry: GameState.InventoryEntryState = _candidate.inventory.entries.get(item_id, GameState.InventoryEntryState.new())
	if acq.progress_subunits != int(values.progress_subunits_before) or acq.rate_carry_units != int(values.rate_carry_units_before) or acq.total_banked_units != int(values.total_banked_units_before):
		return _failure(ERR_TRANSACTION_INPUT, "Channel before endpoints do not match the candidate.")
	if entry.total != int(values.inventory_total_before):
		return _failure(ERR_TRANSACTION_INPUT, "Channel inventory before endpoint does not match the candidate.")
	# The checks above include every related total before mutation. Reservations are
	# carried through the existing entry, so channel banking cannot consume them.
	acq.progress_subunits = int(values.progress_subunits_after)
	acq.rate_carry_units = int(values.rate_carry_units_after)
	acq.total_banked_units = int(values.total_banked_units_after)
	if int(values.banked_units_delta) > 0:
		entry.total = int(values.inventory_total_after)
		_candidate.inventory.entries[item_id] = entry
	var fact := values.duplicate(true)
	var recorded := _journal.record_channel_segment(fact)
	if not recorded.ok:
		return _failure(ERR_TRANSACTION_INPUT, recorded.details)
	return {"ok": true}

func apply_settlement_transition() -> Dictionary:
	if not _is_open(): return _failure(ERR_TRANSACTION_STATE, "Settlement mutation is not allowed after finalization.")
	if not _journal.can_accept(): return _failure(ERR_TRANSACTION_INPUT, "Settlement journal capacity is exhausted.")
	if _current_segment_index < 0: return _failure(ERR_TRANSACTION_INPUT, "Settlement requires a completed core segment.")
	var threshold: GameState.ThresholdState = _candidate.thresholds[_context.threshold_id]
	if threshold.lifecycle_state != &"OVERDUE" or threshold.remaining_backlog != 0:
		return _failure(ERR_TRANSACTION_INPUT, "Settlement requires an Overdue Threshold with zero backlog.")
	var occurred := _context.baseline_simulation_time_msec
	for fact in _journal.facts_snapshot():
		if fact.get("kind", &"") == SimulationFactJournal.KIND_CORE_SEGMENT and int(fact.segment_index) == _current_segment_index:
			occurred = int(fact.end_simulation_msec)
	var before := threshold.remaining_backlog
	threshold.lifecycle_state = &"SETTLED"
	var recorded := _journal.record_settlement({
		"segment_index": _current_segment_index,
		"threshold_id": _context.threshold_id,
		"occurred_simulation_msec": occurred,
		"persistent_returns_total": threshold.persistent_returns_total,
		"remaining_backlog_before": before,
		"remaining_backlog_after": threshold.remaining_backlog,
		"lifecycle_before": &"OVERDUE",
		"lifecycle_after": &"SETTLED",
	})
	if not recorded.ok:
		threshold.lifecycle_state = &"OVERDUE"
		return _failure(ERR_TRANSACTION_INPUT, recorded.details)
	return {"ok": true}

func finalize() -> Dictionary:
	if state != STATE_OPEN: return _failure(ERR_TRANSACTION_STATE, "Transaction can finalize only once from OPEN.")
	var validation := GameStateValidator.validate(_candidate, _registry, true)
	if not validation.ok:
		state = STATE_FAILED
		return _failure(SimulationEngine.ERR_STATE_INVALID, str(validation))
	var journal_validation := _journal.validate()
	if not journal_validation.ok:
		state = STATE_FAILED
		return _failure(SimulationEngine.ERR_RESULT_INVALID, journal_validation.details)
	var frozen := _journal.freeze()
	if not frozen.ok:
		state = STATE_FAILED
		return _failure(SimulationEngine.ERR_RESULT_INVALID, frozen.details)
	var projection := SimulationResultProjector.project(_context, _journal)
	if not projection.ok:
		state = STATE_FAILED
		return _failure(SimulationEngine.ERR_RESULT_INVALID, projection.details)
	_finalized_result = projection.result
	state = STATE_FINALIZED
	return {"ok": true, "result": _finalized_result}

func commit_to(live_state: GameState):
	if state != STATE_FINALIZED or live_state != _source:
		return _failure(ERR_TRANSACTION_STATE, "Only the finalized transaction may commit to its captured source.")
	# This is the only live-state mutation in the transaction path.
	live_state.copy_from(_candidate)
	state = STATE_COMMITTED
	return {"ok": true, "result": _finalized_result}

func read_only_snapshot() -> Dictionary:
	return {
		"state": state,
		"context": _context.read_only_snapshot(),
		"journal_frozen": _journal.is_frozen(),
		"facts": _journal.facts_snapshot(),
	}

func _validate_core_plan(values: Dictionary) -> Dictionary:
	var required := [
		"segment_index", "threshold_id", "assignment_revision", "form_id", "writ_id",
		"ordered_retinue_ids", "lifecycle_state", "start_simulation_msec",
		"end_simulation_msec", "elapsed_msec", "persistent_returns_before",
		"persistent_returns_after", "remaining_backlog_before", "remaining_backlog_after",
		"essence_before", "essence_after", "mastery_before", "mastery_after",
		"cycle_phase_before", "cycle_phase_after", "completed_cycles_before",
		"completed_cycles_after", "flow_endpoints",
	]
	for key in required:
		if not values.has(key): return _failure(ERR_TRANSACTION_INPUT, "Core plan missing %s." % key)
	if StringName(values.threshold_id) != _context.threshold_id or int(values.assignment_revision) != _context.assignment_revision or StringName(values.form_id) != _context.form_id or StringName(values.writ_id) != _context.writ_id:
		return _failure(ERR_TRANSACTION_INPUT, "Core plan identity differs from captured context.")
	if values.ordered_retinue_ids != _context.ordered_retinue_ids:
		return _failure(ERR_TRANSACTION_INPUT, "Core plan Retinue identity differs from captured context.")
	if int(values.segment_index) != _current_segment_index + 1:
		return _failure(ERR_TRANSACTION_INPUT, "Core segment indexes must be sequential.")
	if int(values.start_simulation_msec) < _context.baseline_simulation_time_msec or int(values.end_simulation_msec) <= int(values.start_simulation_msec) or int(values.elapsed_msec) != int(values.end_simulation_msec) - int(values.start_simulation_msec):
		return _failure(ERR_TRANSACTION_INPUT, "Core plan timing is invalid.")
	if StringName(values.lifecycle_state) != &"OVERDUE" and StringName(values.lifecycle_state) != &"SETTLED":
		return _failure(ERR_TRANSACTION_INPUT, "Core plan lifecycle is invalid.")
	for key in ["persistent_returns_before", "persistent_returns_after", "remaining_backlog_before", "remaining_backlog_after", "essence_before", "essence_after", "mastery_before", "mastery_after", "cycle_phase_before", "cycle_phase_after", "completed_cycles_before", "completed_cycles_after"]:
		if int(values[key]) < 0: return _failure(ERR_TRANSACTION_INPUT, "Core plan values cannot be negative.")
	if int(values.persistent_returns_after) < int(values.persistent_returns_before) or int(values.remaining_backlog_after) > int(values.remaining_backlog_before) or int(values.essence_after) < int(values.essence_before) or int(values.mastery_after) < int(values.mastery_before) or int(values.completed_cycles_after) < int(values.completed_cycles_before):
		return _failure(ERR_TRANSACTION_INPUT, "Core plan endpoints move in an invalid direction.")
	return {"ok": true}

func _validate_channel_plan(values: Dictionary) -> Dictionary:
	var required := ["segment_index", "channel_id", "output_item_id", "lifecycle_state", "segment_end_simulation_msec", "progress_subunits_before", "progress_subunits_after", "rate_carry_units_before", "rate_carry_units_after", "total_banked_units_before", "total_banked_units_after", "banked_units_delta", "inventory_total_before", "inventory_total_after", "period_msec"]
	for key in required:
		if not values.has(key): return _failure(ERR_TRANSACTION_INPUT, "Channel plan missing %s." % key)
	if int(values.segment_index) != _current_segment_index or StringName(values.lifecycle_state) != _current_lifecycle_state():
		return _failure(ERR_TRANSACTION_INPUT, "Channel plan does not belong to the current core segment.")
	if int(values.segment_end_simulation_msec) <= _context.baseline_simulation_time_msec or int(values.period_msec) <= 0:
		return _failure(ERR_TRANSACTION_INPUT, "Channel plan timing is invalid.")
	for key in ["progress_subunits_before", "progress_subunits_after", "rate_carry_units_before", "rate_carry_units_after", "total_banked_units_before", "total_banked_units_after", "banked_units_delta", "inventory_total_before", "inventory_total_after"]:
		if int(values[key]) < 0: return _failure(ERR_TRANSACTION_INPUT, "Channel plan values cannot be negative.")
	if int(values.progress_subunits_before) >= FixedPoint.SCALE or int(values.progress_subunits_after) >= FixedPoint.SCALE or int(values.rate_carry_units_before) >= int(values.period_msec) or int(values.rate_carry_units_after) >= int(values.period_msec):
		return _failure(ERR_TRANSACTION_INPUT, "Channel progress/carry is outside its normalized range.")
	if int(values.total_banked_units_after) - int(values.total_banked_units_before) != int(values.banked_units_delta):
		return _failure(ERR_TRANSACTION_INPUT, "Channel banked delta does not match its endpoints.")
	if int(values.inventory_total_after) - int(values.inventory_total_before) != int(values.banked_units_delta):
		return _failure(ERR_TRANSACTION_INPUT, "Channel inventory delta does not match its banked endpoint.")
	return {"ok": true}

func _current_lifecycle_state() -> StringName:
	for fact in _journal.facts_snapshot():
		if fact.get("kind", &"") == SimulationFactJournal.KIND_CORE_SEGMENT and int(fact.segment_index) == _current_segment_index:
			return StringName(fact.lifecycle_state)
	return &""

func _is_open() -> bool:
	return state == STATE_OPEN

func _failure(code: StringName, details: String) -> Dictionary:
	# Invalid calls after finalization or commit are rejected without reopening the
	# transaction's terminal state. Only an open transaction can become FAILED.
	if state == STATE_OPEN:
		state = STATE_FAILED
	return {"ok": false, "code": code, "details": details}
