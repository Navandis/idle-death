extends SceneTree

## Isolated behavioral trace for M04E2T1. It owns only temporary probe-file
## cleanup and assertion output; gameplay remains owned by GameState and the
## shared SimulationEngine transaction. `--work-root` must be an existing
## isolated directory supplied by the caller. No result or journal fact is
## persisted there.

const HOUR := 3600000
const EXPECTED_MARKERS := [
	"TRACE M04E2T1 private_candidate_single_commit=PASS",
	"TRACE M04E2T1 run_context_captured_once=PASS",
	"TRACE M04E2T1 core_mutation_fact_shared_provenance=PASS",
	"TRACE M04E2T1 channel_mutation_fact_shared_provenance=PASS",
	"TRACE M04E2T1 settlement_boundary_fact_shared_provenance=PASS",
	"TRACE M04E2T1 timeline_only_transaction=PASS",
	"TRACE M04E2T1 partial_candidate_failure_preserves_live=PASS",
	"TRACE M04E2T1 compatibility_summary_derived_from_journal=PASS",
	"TRACE M04E2T1 events_derived_from_journal=PASS",
	"TRACE M04E2T1 one_hour_eight_hour_settlement_unchanged=PASS",
	"TRACE M04E2T1 forecast_commit_chunk_mode_equivalence=PASS",
	"TRACE M04E2T1 schema_v3_no_later_slice_artifacts=PASS",
]

var _work_root := ""
var _probe_path := ""
var _markers: Array[String] = []
var _registry: ContentRegistry

func _init() -> void:
	_work_root = _argument_value("--work-root")
	if _work_root.is_empty() or not DirAccess.dir_exists_absolute(_work_root):
		_fail("M04E2T1 requires an existing isolated --work-root.")
		return
	_probe_path = _work_root.path_join("m04e2t1_trace_probe.tmp")
	var probe := FileAccess.open(_probe_path, FileAccess.WRITE)
	if probe == null:
		_fail("M04E2T1 could not use the supplied isolated --work-root.")
		return
	probe.store_string("M04E2T1 trace probe")
	probe.close()
	if not FileAccess.file_exists(_probe_path):
		_fail("M04E2T1 work-root probe was not created.")
		return
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	_run()
	_cleanup_work_root()
	if _markers != EXPECTED_MARKERS:
		_fail("M04E2T1 marker sequence is incomplete or reordered.")
		return
	quit(0)

func _run() -> void:
	var state := _state()
	var before := _canonical(state)
	var trace := SimulationEngine.new(_registry).resolve_elapsed_with_trace(state, HOUR)
	_assert(trace.result.success, trace.result.developer_details)
	_assert(trace.transaction.state == SimulationTransaction.STATE_COMMITTED, "transaction committed")
	_assert(_canonical(state) != before, "live state changed only after success")
	_pass("private_candidate_single_commit")

	var context: Dictionary = trace.transaction.context
	_assert(context.baseline_simulation_time_msec == 0 and context.requested_elapsed_msec == HOUR, "context cursor/request")
	_assert(context.threshold_id == &"THR_GLOAMWOOD" and context.assignment_revision == 1, "context identity")
	_assert(trace.transaction.facts.size() >= 2, "context run has bounded facts")
	_pass("run_context_captured_once")

	var core: Dictionary = _first_fact(trace.transaction.facts, SimulationFactJournal.KIND_CORE_SEGMENT)
	_assert(not core.is_empty(), "core fact exists")
	_assert(core.returned_souls_delta == trace.result.segments[0].returned_souls_delta, "core returned endpoint")
	_assert(core.Essence_delta == trace.result.segments[0].essence_delta, "core Essence endpoint")
	_pass("core_mutation_fact_shared_provenance")

	var soldier_state := _state()
	_assert(OutputAccessService.new(_registry).unlock_output_item(soldier_state, &"SOUL_CALLING_SOLDIER").success, "Soldier unlock")
	_assert(OutputAccessService.new(_registry).reconcile_available_sources(soldier_state).success, "Soldier source")
	var channel_trace := SimulationEngine.new(_registry).resolve_elapsed_with_trace(soldier_state, HOUR)
	var channel_fact: Dictionary = _first_banked_fact(channel_trace.transaction.facts)
	_assert(not channel_fact.is_empty(), "channel fact exists")
	var channel_delta: SimulationChannelDeltaResult = channel_trace.result.segments[0].channel_deltas[0]
	_assert(channel_fact.progress_subunits_after == channel_delta.progress_subunits_after and channel_fact.total_banked_units_after == channel_delta.total_banked_units_after, "channel endpoints")
	_pass("channel_mutation_fact_shared_provenance")

	var settlement_state := _state(1)
	var settlement_trace := SimulationEngine.new(_registry).resolve_elapsed_with_trace(settlement_state, 10000)
	var settlement_fact: Dictionary = _first_fact(settlement_trace.transaction.facts, SimulationFactJournal.KIND_SETTLEMENT)
	_assert(settlement_trace.result.events.size() == 1 and settlement_fact.persistent_returns_total == 1, "Settlement boundary total")
	_assert(settlement_trace.result.events[0].persistent_returns_total == settlement_fact.persistent_returns_total, "Settlement event provenance")
	_pass("settlement_boundary_fact_shared_provenance")

	var idle := _state(100, false)
	var idle_trace := SimulationEngine.new(_registry).resolve_elapsed_with_trace(idle, 1234)
	_assert(idle_trace.result.result_kind == SimulationResult.KIND_TIMELINE_ONLY and idle_trace.result.committed_elapsed_msec == 1234, "timeline result")
	_assert(idle_trace.transaction.facts.size() == 1 and idle_trace.transaction.facts[0].kind == SimulationFactJournal.KIND_TIMELINE, "timeline fact")
	_pass("timeline_only_transaction")

	var overflow := _state()
	_assert(OutputAccessService.new(_registry).unlock_output_item(overflow, &"SOUL_CALLING_SOLDIER").success, "overflow unlock")
	_assert(OutputAccessService.new(_registry).reconcile_available_sources(overflow).success, "overflow source")
	var overflow_acq: GameState.ThresholdAcquisitionState = overflow.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]
	overflow_acq.progress_subunits = FixedPoint.SCALE - 1
	overflow.inventory.entries[&"SOUL_CALLING_SOLDIER"] = GameState.InventoryEntryState.new(FixedPoint.INT64_MAX)
	var overflow_before := _canonical(overflow)
	var overflow_result := SimulationEngine.new(_registry).resolve_elapsed(overflow, 1)
	_assert(not overflow_result.success and overflow_result.error_code == SimulationEngine.ERR_OVERFLOW, "partial overflow failure")
	_assert(_canonical(overflow) == overflow_before, "partial failure preserves live")
	_pass("partial_candidate_failure_preserves_live")

	_assert(trace.result.segments[0].returned_souls_delta == core.returned_souls_delta, "typed core total")
	_assert(trace.result.committed_elapsed_msec == HOUR, "typed timeline")
	_pass("compatibility_summary_derived_from_journal")
	var bank_event: SimulationChannelBankedEvent = channel_trace.result.events[0]
	_assert(bank_event.quantity == channel_fact.banked_units_delta and bank_event.total_banked_units_after == channel_fact.total_banked_units_after, "event channel fact")
	_pass("events_derived_from_journal")

	var one_hour := _state()
	var eight_hour := _state()
	var one_result := SimulationEngine.new(_registry).resolve_elapsed(one_hour, HOUR)
	var eight_result := SimulationEngine.new(_registry).resolve_elapsed(eight_hour, 8 * HOUR)
	_assert(one_result.success and eight_result.success, "one/eight hour success")
	_assert(one_hour.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 4140 and eight_hour.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 33120, "one/eight hour returns")
	_assert(one_hour.inventory.entries[&"RES_ESSENCE"].total == 360 and eight_hour.inventory.entries[&"RES_ESSENCE"].total == 2880, "one/eight hour Essence")
	_pass("one_hour_eight_hour_settlement_unchanged")

	var forecast_base := _state()
	var forecast := SimulationRunService.new(_registry).forecast(forecast_base, HOUR)
	var committed := forecast_base.deep_clone()
	var committed_result := SimulationRunService.new(_registry).run_committed(committed, HOUR, SimulationRunService.MODE_OFFLINE_FIXTURE)
	var chunked := forecast_base.deep_clone()
	for _i in range(4):
		_assert(SimulationRunService.new(_registry).run_committed(chunked, HOUR / 4, SimulationRunService.MODE_DEBUG).success, "chunk success")
	_assert(forecast.success and committed_result.success and _canonical(forecast.projected_state) == _canonical(committed) and _canonical(committed) == _canonical(chunked), "forecast commit chunk equivalence")
	_pass("forecast_commit_chunk_mode_equivalence")

	var mapped := SaveSchemaMapper.runtime_to_snapshot(committed, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var snapshot_text := JSON.stringify(mapped)
	_assert(mapped.has("schema_version") and mapped.schema_version == SaveInt64.format(4), "schema v4")
	for forbidden in ["SimulationTransaction", "SimulationFactJournal", "SimulationRunContext", "ReportService", "ingest_committed_run", "snapshot_live", "peek_report"]:
		_assert(not snapshot_text.contains(forbidden), "schema exclusion %s" % forbidden)
	_pass("schema_v3_no_later_slice_artifacts")

func _state(backlog: int = 1000000, active: bool = true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TRACE")
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
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _first_fact(facts: Array, kind: StringName) -> Dictionary:
	for fact in facts:
		if fact.kind == kind: return fact
	return {}

func _first_banked_fact(facts: Array) -> Dictionary:
	for fact in facts:
		if fact.kind == SimulationFactJournal.KIND_CHANNEL_SEGMENT and int(fact.banked_units_delta) > 0: return fact
	return {}

func _argument_value(name: String) -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == name: return str(args[index + 1])
	return ""

func _cleanup_work_root() -> void:
	if FileAccess.file_exists(_probe_path):
		var error := DirAccess.remove_absolute(_probe_path)
		_assert(error == OK, "M04E2T1 work-root probe cleanup")
	_assert(not FileAccess.file_exists(_probe_path), "M04E2T1 work-root cleanup proof")

func _assert(condition: bool, detail: String) -> void:
	if not condition: _fail(detail)

func _pass(name: String) -> void:
	var marker := "TRACE M04E2T1 %s=PASS" % name
	_markers.append(marker)
	print(marker)

func _fail(detail: String) -> void:
	push_error("M04E2T1 trace failure: " + detail)
	quit(1)
