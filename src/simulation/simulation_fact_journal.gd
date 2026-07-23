class_name SimulationFactJournal
extends RefCounted

## Bounded, non-persisted facts produced by one SimulationTransaction.
##
## The journal owns ordered explanatory facts only; it does not own gameplay
## state, formulas, event history, reports, analytics, or save data. A fact is
## appended only after its transaction mutation has passed all checks. Facts
## are bounded to the current call and become detached read-only evidence when
## frozen. All times are integer simulation milliseconds.

const KIND_TIMELINE := &"TIMELINE"
const KIND_CORE_SEGMENT := &"CORE_SEGMENT"
const KIND_CHANNEL_SEGMENT := &"CHANNEL_SEGMENT"
const KIND_SETTLEMENT := &"SETTLEMENT"

var requested_elapsed_msec: int:
	get: return _requested_elapsed_msec
var baseline_simulation_time_msec: int:
	get: return _baseline_simulation_time_msec
var max_fact_count: int:
	get: return _max_fact_count
var _requested_elapsed_msec: int
var _baseline_simulation_time_msec: int
var _max_fact_count: int
var _facts: Array[Dictionary] = []
var _frozen := false

func _init(baseline_time: int, requested_elapsed: int, fact_limit: int = 512) -> void:
	_baseline_simulation_time_msec = baseline_time
	_requested_elapsed_msec = requested_elapsed
	_max_fact_count = fact_limit

func record_timeline(before_time: int, after_time: int) -> Dictionary:
	if not _can_append(): return _failure("Journal is frozen or full.")
	if before_time < 0 or after_time < before_time or after_time - before_time != requested_elapsed_msec:
		return _failure("Timeline fact does not match the requested elapsed interval.")
	return _append_fact({
		"kind": KIND_TIMELINE,
		"before_time": before_time,
		"after_time": after_time,
		"elapsed_msec": after_time - before_time,
	})

func record_core_segment(values: Dictionary) -> Dictionary:
	if not _can_append(): return _failure("Journal is frozen or full.")
	var required := [
		"segment_index", "threshold_id", "assignment_revision", "form_id", "writ_id",
		"ordered_retinue_ids", "lifecycle_state", "start_simulation_msec",
		"end_simulation_msec", "elapsed_msec", "returned_souls_delta",
		"backlog_delta", "Essence_delta", "Mastery_delta_subunits",
		"completed_cycles_delta", "flow_endpoints",
	]
	if not _has_keys(values, required): return _failure("Core fact is missing required fields.")
	var fact := values.duplicate(true)
	fact["kind"] = KIND_CORE_SEGMENT
	return _append_fact(fact)

func record_channel_segment(values: Dictionary) -> Dictionary:
	if not _can_append(): return _failure("Journal is frozen or full.")
	var required := [
		"segment_index", "channel_id", "output_item_id", "lifecycle_state",
		"segment_end_simulation_msec", "progress_subunits_before",
		"progress_subunits_after", "rate_carry_units_before",
		"rate_carry_units_after", "total_banked_units_before",
		"total_banked_units_after", "banked_units_delta", "inventory_total_before",
		"inventory_total_after",
	]
	if not _has_keys(values, required): return _failure("Channel fact is missing required fields.")
	var fact := values.duplicate(true)
	fact["kind"] = KIND_CHANNEL_SEGMENT
	return _append_fact(fact)

func record_settlement(values: Dictionary) -> Dictionary:
	if not _can_append(): return _failure("Journal is frozen or full.")
	var required := [
		"segment_index", "threshold_id", "occurred_simulation_msec",
		"persistent_returns_total", "remaining_backlog_before",
		"remaining_backlog_after", "lifecycle_before", "lifecycle_after",
	]
	if not _has_keys(values, required): return _failure("Settlement fact is missing required fields.")
	var fact := values.duplicate(true)
	fact["kind"] = KIND_SETTLEMENT
	return _append_fact(fact)

func validate() -> Dictionary:
	if requested_elapsed_msec <= 0:
		return _failure("Positive transaction journal requires positive elapsed time.")
	var timeline_count := 0
	var core_facts: Array[Dictionary] = []
	var channel_facts: Array[Dictionary] = []
	var settlement_count := 0
	for fact in _facts:
		match fact.get("kind", &""):
			KIND_TIMELINE:
				timeline_count += 1
			KIND_CORE_SEGMENT:
				core_facts.append(fact)
			KIND_CHANNEL_SEGMENT:
				channel_facts.append(fact)
			KIND_SETTLEMENT:
				settlement_count += 1
			_:
				return _failure("Journal contains an unknown fact kind.")
	if timeline_count != 1:
		return _failure("Journal must contain exactly one timeline fact.")
	var timeline: Dictionary = _first_fact(KIND_TIMELINE)
	if timeline.before_time != baseline_simulation_time_msec or timeline.elapsed_msec != requested_elapsed_msec:
		return _failure("Timeline fact does not cover the transaction request.")
	if core_facts.is_empty():
		if not channel_facts.is_empty() or settlement_count != 0:
			return _failure("Timeline-only journal cannot contain active facts.")
	else:
		var expected_start := baseline_simulation_time_msec
		for index in range(core_facts.size()):
			var core: Dictionary = core_facts[index]
			if int(core.segment_index) != index:
				return _failure("Core segment indexes must be contiguous.")
			if int(core.start_simulation_msec) != expected_start:
				return _failure("Core segments must be contiguous from the baseline cursor.")
			if int(core.elapsed_msec) <= 0 or int(core.end_simulation_msec) - int(core.start_simulation_msec) != int(core.elapsed_msec):
				return _failure("Core segment timing is invalid.")
			if int(core.end_simulation_msec) > timeline.after_time:
				return _failure("Core segment exceeds the transaction timeline.")
			expected_start = int(core.end_simulation_msec)
		if expected_start != int(timeline.after_time):
			return _failure("Core segments must cover the full transaction timeline.")
		for channel in channel_facts:
			if int(channel.segment_index) < 0 or int(channel.segment_index) >= core_facts.size():
				return _failure("Channel fact references an invalid segment.")
			if int(channel.segment_end_simulation_msec) != int(core_facts[int(channel.segment_index)].end_simulation_msec):
				return _failure("Channel fact must use its segment endpoint.")
		if settlement_count > 1:
			return _failure("A one-active-Reaping transaction can have at most one Settlement boundary.")
		if settlement_count == 1:
			var settlement: Dictionary = _first_fact(KIND_SETTLEMENT)
			if settlement.lifecycle_before != &"OVERDUE" or settlement.lifecycle_after != &"SETTLED" or int(settlement.remaining_backlog_after) != 0:
				return _failure("Settlement fact has an invalid lifecycle transition.")
	return {"ok": true}

func freeze() -> Dictionary:
	if _frozen: return _failure("Journal is already frozen.")
	var validation := validate()
	if not validation.ok: return validation
	_frozen = true
	return {"ok": true}

func is_frozen() -> bool:
	return _frozen

func can_accept(additional_facts: int = 1) -> bool:
	return not _frozen and additional_facts >= 0 and _facts.size() <= max_fact_count - additional_facts

func facts_snapshot() -> Array[Dictionary]:
	var detached: Array[Dictionary] = []
	for fact in _facts:
		detached.append(fact.duplicate(true))
	return detached

func _can_append() -> bool:
	return not _frozen and _facts.size() < max_fact_count

func _append_fact(fact: Dictionary) -> Dictionary:
	_facts.append(fact)
	return {"ok": true}

func _first_fact(kind: StringName) -> Dictionary:
	for fact in _facts:
		if fact.get("kind", &"") == kind:
			return fact
	return {}

func _has_keys(value: Dictionary, keys: Array) -> bool:
	for key in keys:
		if not value.has(key): return false
	return true

func _failure(details: String) -> Dictionary:
	return {"ok": false, "code": &"SIM_JOURNAL_INVALID", "details": details}
