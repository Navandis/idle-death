extends SceneTree

const HOUR := 3600000
const TRACE_PREFIX := "TRACE M04E2A1 "

var _registry: ContentRegistry
var _service: SimulationRunService
var _work_root := ""
var _markers: Array[String] = []

func _initialize() -> void:
	var setup := _setup()
	if not setup.ok:
		printerr(setup.details); quit(setup.code); return
	var result := _run_trace()
	if not result.ok:
		printerr(result.details); quit(result.code); return
	quit(0)

func _setup() -> Dictionary:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--work-root" and i + 1 < args.size(): _work_root = args[i + 1]
	if _work_root.strip_edges() == "" or _work_root.begins_with("user://"):
		return {"ok": false, "code": 2, "details": "M04E2A1 trace requires explicit non-user --work-root"}
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not _registry.ready: return {"ok": false, "code": 3, "details": str(_registry.diagnostics)}
	_service = SimulationRunService.new(_registry)
	DirAccess.make_dir_recursive_absolute(_work_root)
	return {"ok": true}

func _run_trace() -> Dictionary:
	var one := _prepared_state(1000000, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var one_run := _service.run_committed(one, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not one_run.success: return _fail(10, one_run.developer_details)
	var segment: SimulationEngine.SimulationSegmentResult = one_run.simulation_result.segments[0]
	if not (segment.threshold_id == &"THR_GLOAMWOOD" and segment.assignment_revision == 1 and segment.form_id == &"FORM_MAN_AT_ARMS" and segment.writ_id == &"WRIT_STANDARD" and segment.ordered_retinue_ids.is_empty() and segment.start_simulation_msec == 0 and segment.end_simulation_msec == HOUR and segment.elapsed_msec == HOUR): return _fail(11, "typed segment identity/timing")
	_trace("typed_segment_identity_and_timing=PASS")
	var found_soldier := false
	for delta in segment.channel_deltas:
		if delta.channel_id == &"CHANNEL_GLOAMWOOD_SOLDIER_SOULS" and delta.output_item_id == &"SOUL_CALLING_SOLDIER" and delta.banked_units_delta == 12 and delta.total_banked_units_after - delta.total_banked_units_before == 12:
			found_soldier = true
	if not found_soldier: return _fail(12, "typed channel endpoints")
	_trace("typed_channel_endpoint_contract=PASS")
	if not _one_hour_values_match(one): return _fail(13, "one-hour values")
	_trace("one_hour_values_unchanged=PASS")
	var eight := _prepared_state(1000000, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var eight_run := _service.run_committed(eight, 8 * HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not eight_run.success or not _eight_hour_values_match(eight): return _fail(14, "eight-hour values")
	_trace("eight_hour_values_unchanged=PASS")
	var settlement := _prepared_state(1, [&"SOUL_CALLING_SOLDIER"])
	var settlement_run := _service.run_committed(settlement, 2000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not (settlement_run.success and settlement_run.simulation_result.segments.size() == 2 and settlement_run.simulation_result.segments[0].lifecycle_state == &"OVERDUE" and settlement_run.simulation_result.segments[1].lifecycle_state == &"SETTLED" and settlement_run.simulation_result.events.size() >= 1): return _fail(15, "settlement segments")
	_trace("settlement_segments_and_events=PASS")
	var idle := _prepared_state(1000000, [])
	idle.reapings.clear()
	var timeline := _service.run_committed(idle, 1234, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not (timeline.success and timeline.simulation_result.segments.is_empty() and timeline.simulation_result.events.is_empty() and timeline.simulation_result.change_summary.size() == 1 and timeline.simulation_result.change_summary.simulation_time_delta_msec == 1234): return _fail(16, "timeline")
	_trace("timeline_only_positive_run=PASS")
	var zero := _service.forecast(_prepared_state(1000000, []), 0)
	var negative := _service.forecast(_prepared_state(1000000, []), -1)
	if not (zero.success and zero.simulation_result.segments.is_empty() and zero.simulation_result.events.is_empty() and not negative.success and negative.simulation_result == null): return _fail(17, "zero/failure")
	_trace("zero_and_failure_shapes=PASS")
	if not _same_timestamp_recall(): return _fail(18, "recall attribution")
	_trace("same_timestamp_recall_attribution=PASS")
	if not _same_timestamp_redispatch(): return _fail(19, "redispatch attribution")
	_trace("same_timestamp_redispatch_attribution=PASS")
	if not _equal_output_identity(): return _fail(20, "equal output identity")
	_trace("equal_output_component_identity_distinct=PASS")
	if not _malformed_rejects_before_commit(): return _fail(21, "malformed no commit")
	_trace("malformed_result_rejects_before_commit=PASS")
	if not _forecast_mode_equivalence(): return _fail(22, "forecast/mode equivalence")
	_trace("forecast_commit_and_mode_equivalence=PASS")
	if not _schema_exclusion(): return _fail(23, "schema exclusion")
	_trace("schema_v3_no_result_artifacts=PASS")
	if not _source_audit(): return _fail(24, "source audit")
	_trace("no_report_or_later_slice_sources=PASS")
	if _markers.size() != 14: return _fail(25, "expected 14 markers")
	return {"ok": true}

func _same_timestamp_recall() -> bool:
	var state := _prepared_state(1000000, [])
	var result := _service.run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not result.success: return false
	var retained: SimulationEngine.SimulationSegmentResult = result.simulation_result.segments[0]
	var recalled := ReapingAssignmentService.new(_registry).recall(state, &"THR_GLOAMWOOD", 1)
	return recalled.success and retained.assignment_revision == 1 and retained.form_id == &"FORM_MAN_AT_ARMS" and retained.writ_id == &"WRIT_STANDARD"

func _same_timestamp_redispatch() -> bool:
	var state := _prepared_state(1000000, [])
	var result := _service.run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	if not result.success: return false
	var retained: SimulationEngine.SimulationSegmentResult = result.simulation_result.segments[0]
	var assignment := ReapingAssignmentService.new(_registry)
	if not assignment.recall(state, &"THR_GLOAMWOOD", 1).success: return false
	if not assignment.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 2).success: return false
	return retained.assignment_revision == 1 and retained.writ_id == &"WRIT_STANDARD" and state.reapings[&"THR_GLOAMWOOD"].assignment_revision == 3

func _equal_output_identity() -> bool:
	var a := SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 1000, 1000, 1, 1, 0, 0, 0, [])
	var b := SimulationEngine.SimulationSegmentResult.new(&"THR_GLOAMWOOD", 2, &"FORM_MAN_AT_ARMS", &"WRIT_EMERGENCY", [], &"OVERDUE", 0, 1000, 1000, 1, 1, 0, 0, 0, [])
	return a.assignment_revision != b.assignment_revision and a.writ_id != b.writ_id and a.returned_souls_delta == b.returned_souls_delta

func _malformed_rejects_before_commit() -> bool:
	var engine := SimulationEngine.new(_registry)
	var live := _prepared_state(1000000, [])
	var before := _canonical(live)
	var candidate := live.deep_clone()
	candidate.advance_simulation_time(1)
	var malformed := SimulationEngine.SimulationResult.new(true, SimulationEngine.OK, "", 1)
	malformed.committed_elapsed_msec = 1
	var result := engine._commit_if_valid(live, candidate, malformed)
	return not result.success and result.error_code == SimulationEngine.ERR_RESULT_INVALID and _canonical(live) == before

func _forecast_mode_equivalence() -> bool:
	var forecast_base := _prepared_state(1000000, [&"SOUL_CALLING_SOLDIER"])
	var forecast := _service.forecast(forecast_base, HOUR)
	var foreground := forecast_base.deep_clone()
	var offline := forecast_base.deep_clone()
	var debug := forecast_base.deep_clone()
	var f := _service.run_committed(foreground, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	var o := _service.run_committed(offline, HOUR, SimulationRunService.MODE_OFFLINE_FIXTURE)
	var d := _service.run_committed(debug, HOUR, SimulationRunService.MODE_DEBUG)
	return forecast.success and f.success and o.success and d.success and _canonical(forecast.projected_state) == _canonical(foreground) and _canonical(foreground) == _canonical(offline) and _canonical(offline) == _canonical(debug) and forecast.simulation_result.segments[0] is SimulationEngine.SimulationSegmentResult

func _schema_exclusion() -> bool:
	var state := _prepared_state(1000000, [&"SOUL_CALLING_SOLDIER"])
	if not _service.run_committed(state, HOUR, SimulationRunService.MODE_FOREGROUND_SUPPLIED).success: return false
	var root := _work_root.path_join("save-proof")
	DirAccess.make_dir_recursive_absolute(root)
	var file_set := SaveFileSet.new(root, "m04e2a1")
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(FileSaveStorage.new(), file_set), _registry)
	var saved := coordinator.save_runtime(state, TimeAuthorityState.new(), 1)
	if not saved.ok: return false
	var text := FileAccess.get_file_as_string(file_set.primary_path)
	for needle in ["SimulationRunResult", "SimulationResult", "SimulationSegmentResult", "SimulationChannelDeltaResult", "SimulationEvent", "report_state", "schema_version\\\":\\\"4"]:
		if text.find(needle) != -1: return false
	return SaveEnvelope.CURRENT_SCHEMA_VERSION == SaveEnvelope.SCHEMA_VERSION_V3 and ContentRegistry.CURRENT_REVISION == "prototype-content-r2"

func _one_hour_values_match(state: GameState) -> bool:
	return state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 4140 and state.inventory.entries[&"RES_ESSENCE"].total == 360 and state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 60000000 and state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 60 and state.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 12 and state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits == 125000

func _eight_hour_values_match(state: GameState) -> bool:
	return state.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 33120 and state.inventory.entries[&"RES_ESSENCE"].total == 2880 and state.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 480000000 and state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 480 and state.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 96 and state.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1

func _prepared_state(backlog: int, item_ids: Array[StringName]) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"; threshold.remaining_backlog = backlog
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"; reaping.is_active = true; reaping.form_id = &"FORM_MAN_AT_ARMS"; reaping.writ_id = &"WRIT_STANDARD"; reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	var access := OutputAccessService.new(_registry)
	for item_id in item_ids: access.unlock_output_item(state, item_id)
	access.reconcile_available_sources(state)
	return state

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _source_audit() -> bool:
	for path in ["res://src/simulation/simulation_engine.gd", "res://src/simulation/simulation_run_service.gd", "res://src/debug/m04c_debug_advance.gd"]:
		var source := FileAccess.get_file_as_string(path)
		for needle in ["ReportState", "ReportService", "schema version 4", "SCHEMA_VERSION_V4", "trusted_time", "extends Node"]:
			if source.find(needle) != -1: return false
	return true

func _trace(marker: String) -> void:
	_markers.append(marker)
	print(TRACE_PREFIX + marker)

func _fail(code: int, details: String) -> Dictionary:
	return {"ok": false, "code": code, "details": details}
