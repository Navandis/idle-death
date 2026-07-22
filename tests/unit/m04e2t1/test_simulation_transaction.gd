extends GutTest

## Focused M04E2T1 tests for transaction ownership, fact provenance, finalization,
## and atomic failure. The fixture uses the existing one-active-Reaping M04C
## content so exact production formulas remain covered by the upstream suites.

const HOUR := 3600000

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_registry())

func _state(backlog: int = 1000000, active: bool = true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"
	threshold.remaining_backlog = backlog
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = active
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 7
	reaping.retinue_ids = [&"RET_TEST_ORDER"]
	# The normal engine rejects Retinues, so most tests use this helper's clean
	# assignment identity and set the deferred list back to empty at the boundary.
	reaping.retinue_ids.clear()
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func test_active_context_is_captured_once_and_facts_share_core_provenance() -> void:
	var state := _state()
	var trace := _engine().resolve_elapsed_with_trace(state, HOUR)
	var result: SimulationEngine.SimulationResult = trace.result
	assert_true(result.success, result.developer_details)
	var transaction: Dictionary = trace.transaction
	var context: Dictionary = transaction.context
	assert_eq(context.baseline_simulation_time_msec, 0)
	assert_eq(context.requested_elapsed_msec, HOUR)
	assert_true(context.has_active_reaping)
	assert_eq(context.threshold_id, &"THR_GLOAMWOOD")
	assert_eq(context.assignment_revision, 7)
	assert_eq(context.form_id, &"FORM_MAN_AT_ARMS")
	assert_eq(context.writ_id, &"WRIT_STANDARD")
	assert_eq(context.initial_lifecycle_state, &"OVERDUE")
	assert_eq(context.ordered_retinue_ids, [])
	assert_eq(context.content_revision, ContentRegistry.CURRENT_REVISION)
	var facts: Array = transaction.facts
	assert_eq(facts[0].kind, SimulationFactJournal.KIND_CORE_SEGMENT)
	var core: Dictionary = facts[0]
	assert_eq(core.returned_souls_delta, result.segments[0].returned_souls_delta)
	assert_eq(core.backlog_delta, result.segments[0].backlog_delta)
	assert_eq(core.Essence_delta, result.segments[0].Essence_delta)
	assert_eq(core.Mastery_delta_subunits, result.segments[0].Mastery_delta_subunits)
	assert_eq(core.completed_cycles_delta, result.segments[0].completed_cycles_delta)
	assert_true(transaction.journal_frozen)
	assert_eq(transaction.state, SimulationTransaction.STATE_COMMITTED)

func test_context_arrays_are_detached_and_no_active_context_is_explicit() -> void:
	var retinues: Array[StringName] = [&"RET_ONE"]
	var context := SimulationRunContext.new(12, 34, true, &"THR_GLOAMWOOD", 2, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", retinues, &"OVERDUE", "r2")
	retinues.append(&"RET_TWO")
	assert_eq(context.ordered_retinue_ids, [&"RET_ONE"])
	var copy := context.detached_copy()
	copy.ordered_retinue_ids.append(&"RET_THREE")
	assert_eq(context.ordered_retinue_ids, [&"RET_ONE"])
	var idle := _state(100, false)
	var trace := _engine().resolve_elapsed_with_trace(idle, 1000)
	assert_true(trace.result.success, trace.result.developer_details)
	assert_false(trace.transaction.context.has_active_reaping)
	assert_eq(trace.transaction.context.threshold_id, &"")
	assert_eq(trace.transaction.context.assignment_revision, 0)
	assert_eq(trace.transaction.facts.size(), 1)
	assert_eq(trace.transaction.facts[0].kind, SimulationFactJournal.KIND_TIMELINE)

func test_channel_fact_and_event_share_channel_endpoints() -> void:
	var state := _state()
	var unlock := OutputAccessService.new(_registry()).unlock_output_item(state, &"SOUL_CALLING_SOLDIER")
	assert_true(unlock.success, str(unlock))
	assert_true(OutputAccessService.new(_registry()).reconcile_available_sources(state).success)
	var trace := _engine().resolve_elapsed_with_trace(state, HOUR)
	assert_true(trace.result.success, trace.result.developer_details)
	var channel_fact: Dictionary = {}
	for fact in trace.transaction.facts:
		if fact.kind == SimulationFactJournal.KIND_CHANNEL_SEGMENT and fact.banked_units_delta > 0:
			channel_fact = fact
			break
	assert_false(channel_fact.is_empty())
	var delta: Dictionary = trace.result.segments[0].channel_deltas[0]
	assert_eq(channel_fact.progress_subunits_before, delta.progress_subunits_before)
	assert_eq(channel_fact.progress_subunits_after, delta.progress_subunits_after)
	assert_eq(channel_fact.total_banked_units_after, delta.total_banked_units_after)
	var bank_event: SimulationEngine.SimulationEvent = trace.result.events[0]
	assert_eq(bank_event.event_type, SimulationEngine.EVENT_OUTPUT_CHANNEL_BANKED)
	assert_eq(bank_event.payload.quantity, channel_fact.banked_units_delta)
	assert_eq(bank_event.payload.total_banked_units, channel_fact.total_banked_units_after)

func test_settlement_event_keeps_boundary_total_not_final_run_total() -> void:
	var state := _state(1)
	var trace := _engine().resolve_elapsed_with_trace(state, 10000)
	assert_true(trace.result.success, trace.result.developer_details)
	assert_eq(trace.result.events.size(), 1)
	var settlement: SimulationEngine.SimulationEvent = trace.result.events[0]
	assert_eq(settlement.event_type, SimulationEngine.EVENT_THRESHOLD_SETTLED)
	assert_eq(settlement.occurred_simulation_msec, 870)
	var settlement_fact: Dictionary = {}
	for fact in trace.transaction.facts:
		if fact.kind == SimulationFactJournal.KIND_SETTLEMENT:
			settlement_fact = fact
	assert_eq(settlement.payload.persistent_returns_total, settlement_fact.persistent_returns_total)
	assert_eq(settlement_fact.persistent_returns_total, 1)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 3)

func test_partial_channel_failure_preserves_complete_live_state() -> void:
	var state := _state()
	var unlock := OutputAccessService.new(_registry()).unlock_output_item(state, &"SOUL_CALLING_SOLDIER")
	assert_true(unlock.success, str(unlock))
	assert_true(OutputAccessService.new(_registry()).reconcile_available_sources(state).success)
	var acq: GameState.ThresholdAcquisitionState = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]
	acq.progress_subunits = FixedPoint.SCALE - 1
	state.inventory.entries[&"SOUL_CALLING_SOLDIER"] = GameState.InventoryEntryState.new(FixedPoint.INT64_MAX)
	var before := _canonical(state)
	var result := _engine().resolve_elapsed(state, 1)
	assert_false(result.success)
	assert_eq(result.error_code, SimulationEngine.ERR_OVERFLOW)
	assert_eq(result.committed_elapsed_msec, 0)
	assert_true(result.segments.is_empty())
	assert_true(result.events.is_empty())
	assert_true(result.change_summary.is_empty())
	assert_eq(_canonical(state), before)

func test_timeline_only_transaction_and_summary_are_journal_derived() -> void:
	var state := _state(100, false)
	var trace := _engine().resolve_elapsed_with_trace(state, 1234)
	assert_true(trace.result.success, trace.result.developer_details)
	assert_eq(trace.result.segments, [])
	assert_eq(trace.result.events, [])
	assert_eq(trace.result.change_summary, {"simulation_time_delta_msec": 1234})
	assert_eq(trace.transaction.facts[0].before_time, 0)
	assert_eq(trace.transaction.facts[0].after_time, 1234)

func test_transaction_finalization_and_journal_freeze_are_one_way() -> void:
	var journal := SimulationFactJournal.new(0, 1000)
	assert_true(journal.record_timeline(0, 1000).ok)
	assert_true(journal.freeze().ok)
	assert_false(journal.record_timeline(1000, 2000).ok)
	var source := _state(100, false)
	var context := SimulationRunContext.new(0, 1000, false, &"", 0, &"", &"", [], &"", ContentRegistry.CURRENT_REVISION)
	var transaction := SimulationTransaction.open(source, context, _registry())
	var before := _canonical(source)
	assert_true(transaction.calculation_snapshot() != source)
	assert_true(transaction.advance_timeline().ok)
	var finalization := transaction.finalize(Callable(self, "_positive_stub_result"))
	assert_true(finalization.ok, str(finalization))
	assert_true(transaction.journal_is_frozen())
	assert_false(transaction.advance_timeline().ok)
	assert_false(transaction.finalize(Callable(self, "_positive_stub_result")).ok)
	assert_eq(_canonical(source), before)
	var committed: Dictionary = transaction.commit_to(source)
	assert_true(committed.ok, str(committed))
	assert_eq(source.simulation_time_msec, 1000)
	assert_false(transaction.commit_to(source).ok)

func test_failed_operation_after_successful_operation_preserves_candidate_and_journal() -> void:
	var source := _state(100, false)
	var context := SimulationRunContext.new(0, 1000, false, &"", 0, &"", &"", [], &"", ContentRegistry.CURRENT_REVISION)
	var transaction := SimulationTransaction.open(source, context, _registry())
	assert_true(transaction.advance_timeline().ok)
	var facts_before: Array = transaction.read_only_snapshot().facts
	var failed := transaction.apply_core_segment({})
	assert_false(failed.ok)
	assert_eq(transaction.state, SimulationTransaction.STATE_FAILED)
	# A failed transaction deliberately hides its private candidate; its source and
	# journal remain observable only through the no-commit and unchanged-facts proofs.
	assert_eq(transaction.calculation_snapshot(), null)
	assert_eq(transaction.read_only_snapshot().facts, facts_before)
	assert_eq(_canonical(source), _canonical(_state(100, false)))

func test_candidate_validation_failure_preserves_live_state() -> void:
	var source := _state(100, false)
	source.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits = -1
	var before := _canonical(source)
	var context := SimulationRunContext.new(0, 1000, false, &"", 0, &"", &"", [], &"", ContentRegistry.CURRENT_REVISION)
	var transaction := SimulationTransaction.open(source, context, _registry())
	var failed := transaction.finalize(Callable(self, "_positive_stub_result"))
	assert_false(failed.ok)
	assert_eq(failed.code, SimulationEngine.ERR_STATE_INVALID)
	assert_eq(transaction.state, SimulationTransaction.STATE_FAILED)
	assert_eq(_canonical(source), before)

func test_source_audit_has_no_arbitrary_candidate_result_commit_seam() -> void:
	var transaction_source := FileAccess.get_file_as_string("res://src/simulation/simulation_transaction.gd")
	assert_eq(transaction_source.find("commit_if_valid(live"), -1)
	assert_eq(transaction_source.find("arbitrary_candidate"), -1)
	assert_eq(transaction_source.find("arbitrary_result"), -1)

func _positive_stub_result(_journal: SimulationFactJournal, context: SimulationRunContext) -> SimulationEngine.SimulationResult:
	var result := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", context.requested_elapsed_msec)
	result.committed_elapsed_msec = context.requested_elapsed_msec
	return result
