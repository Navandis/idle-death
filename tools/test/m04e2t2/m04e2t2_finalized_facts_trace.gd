extends SceneTree

## Isolated M04E2T2 trace for the detached typed simulation-fact boundary.  It
## owns only a temporary probe file and assertion output; gameplay remains owned
## by the normal engine and transaction.  `--work-root` must be an existing
## isolated directory supplied by the caller, and all probe data is removed
## before successful completion.

const HOUR := 3600000
const EXPECTED_MARKERS := [
	"TRACE M04E2T2 typed_result_envelope=PASS",
	"TRACE M04E2T2 segment_historical_identity=PASS",
	"TRACE M04E2T2 channel_endpoint_contract=PASS",
	"TRACE M04E2T2 channel_event_closed_union=PASS",
	"TRACE M04E2T2 settlement_event_closed_union=PASS",
	"TRACE M04E2T2 timeline_only_positive=PASS",
	"TRACE M04E2T2 zero_and_failure_no_authority=PASS",
	"TRACE M04E2T2 one_hour_values_unchanged=PASS",
	"TRACE M04E2T2 eight_hour_values_unchanged=PASS",
	"TRACE M04E2T2 settlement_segments_and_order=PASS",
	"TRACE M04E2T2 same_timestamp_attribution=PASS",
	"TRACE M04E2T2 equal_output_identity_distinct=PASS",
	"TRACE M04E2T2 forecast_commit_mode_equivalence=PASS",
	"TRACE M04E2T2 raw_public_grammar_removed=PASS",
	"TRACE M04E2T2 schema_v3_no_result_artifacts=PASS",
]

var _work_root := ""
var _probe_path := ""
var _markers: Array[String] = []
var _registry: ContentRegistry

func _init() -> void:
	_work_root = _argument_value("--work-root")
	if _work_root.is_empty() or not DirAccess.dir_exists_absolute(_work_root):
		_fail("M04E2T2 requires an existing isolated --work-root.")
		return
	_probe_path = _work_root.path_join("m04e2t2_trace_probe.tmp")
	var probe := FileAccess.open(_probe_path, FileAccess.WRITE)
	if probe == null:
		_fail("M04E2T2 could not use the supplied isolated --work-root.")
		return
	probe.store_string("M04E2T2 trace probe")
	probe.close()
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var success := _run()
	_cleanup_work_root()
	if not success or _markers != EXPECTED_MARKERS:
		_fail("M04E2T2 marker sequence is incomplete or reordered.")
		return
	quit(0)

func _run() -> bool:
	var envelope := _engine().resolve_elapsed(_state(), 1000)
	if not _assert(envelope.result_kind == SimulationResult.KIND_ACTIVE_REAPING and envelope.success and envelope.segments.size() > 0, "typed result envelope"): return false
	for segment in envelope.segments:
		if not _assert(segment is SimulationSegmentResult, "typed segment"): return false
		for channel in segment.channel_deltas:
			if not _assert(channel is SimulationChannelDeltaResult, "typed channel"): return false
	for event in envelope.events:
		if not _assert(event is SimulationChannelBankedEvent or event is SimulationThresholdSettledEvent, "closed event subtype"): return false
	_pass("typed_result_envelope")

	var identity_state := _state()
	var identity_result := _engine().resolve_elapsed(identity_state, HOUR)
	var identity_segment := identity_result.segments[0]
	if not _assert(identity_segment.threshold_id == &"THR_GLOAMWOOD" and identity_segment.assignment_revision == 11 and identity_segment.form_id == &"FORM_MAN_AT_ARMS" and identity_segment.writ_id == &"WRIT_STANDARD" and identity_segment.ordered_retinue_ids.is_empty(), "historical identity"): return false
	identity_state.reapings[&"THR_GLOAMWOOD"].assignment_revision = 99
	identity_state.reapings[&"THR_GLOAMWOOD"].form_id = &"FORM_SCRIBE"
	if not _assert(identity_segment.assignment_revision == 11 and identity_segment.form_id == &"FORM_MAN_AT_ARMS", "retained identity detached"): return false
	_pass("segment_historical_identity")

	var channel_state := _state()
	_unlock(channel_state, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var channel_result := _engine().resolve_elapsed(channel_state, 8 * HOUR)
	var channel_seen := false
	for segment in channel_result.segments:
		for channel in segment.channel_deltas:
			channel_seen = true
			if not _assert(channel.rate_period_msec > 0 and channel.progress_subunits_after >= 0 and channel.progress_subunits_after < FixedPoint.SCALE and channel.rate_carry_units_after >= 0 and channel.rate_carry_units_after < channel.rate_period_msec and channel.total_banked_units_after - channel.total_banked_units_before == channel.banked_units_delta, "channel endpoint"): return false
	if not _assert(channel_seen, "channel endpoint exists"): return false
	_pass("channel_endpoint_contract")

	for event in channel_result.events:
		if not _assert(event is SimulationChannelBankedEvent or event is SimulationThresholdSettledEvent, "closed channel union"): return false
		if event is SimulationChannelBankedEvent and not _assert(event.quantity > 0 and event.source_id != &"" and event.output_item_id != &"", "typed channel event"): return false
	_pass("channel_event_closed_union")

	var settlement_result := _engine().resolve_elapsed(_state(1), 10000)
	if not _assert(settlement_result.events.size() == 1 and settlement_result.events[0] is SimulationThresholdSettledEvent and settlement_result.events[0].occurred_simulation_msec == 870 and settlement_result.events[0].remaining_backlog_after == 0 and settlement_result.events[0].lifecycle_before == &"OVERDUE" and settlement_result.events[0].lifecycle_after == &"SETTLED", "Settlement event"): return false
	_pass("settlement_event_closed_union")

	var timeline := _engine().resolve_elapsed(_state(100, false), 1234)
	if not _assert(timeline.result_kind == SimulationResult.KIND_TIMELINE_ONLY and timeline.committed_elapsed_msec == 1234 and timeline.segments.is_empty() and timeline.events.is_empty(), "timeline-only result"): return false
	_pass("timeline_only_positive")

	var no_authority_state := _state()
	var before := _canonical(no_authority_state)
	var zero := _engine().resolve_elapsed(no_authority_state, 0)
	var failure := _engine().resolve_elapsed(no_authority_state, -1)
	if not _assert(zero.result_kind == SimulationResult.KIND_ZERO_DURATION and zero.segments.is_empty() and failure.result_kind == SimulationResult.KIND_FAILURE and not failure.success and _canonical(no_authority_state) == before, "zero/failure authority"): return false
	_pass("zero_and_failure_no_authority")

	var one_hour := _state()
	_unlock(one_hour, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	if not _assert(_engine().resolve_elapsed(one_hour, HOUR).success and one_hour.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 4140 and one_hour.inventory.entries[&"RES_ESSENCE"].total == 360 and one_hour.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 60000000 and one_hour.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 60 and one_hour.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 12 and one_hour.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits == 125000, "one-hour values"): return false
	_pass("one_hour_values_unchanged")

	var eight_hour := _state()
	_unlock(eight_hour, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	if not _assert(_engine().resolve_elapsed(eight_hour, 8 * HOUR).success and eight_hour.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total == 33120 and eight_hour.inventory.entries[&"RES_ESSENCE"].total == 2880 and eight_hour.forms[&"FORM_MAN_AT_ARMS"].mastery_subunits == 480000000 and eight_hour.reapings[&"THR_GLOAMWOOD"].completed_cycle_count == 480 and eight_hour.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 96 and eight_hour.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1, "eight-hour values"): return false
	_pass("eight_hour_values_unchanged")

	if not _assert(settlement_result.segments.size() == 2 and settlement_result.segments[0].lifecycle_state == &"OVERDUE" and settlement_result.segments[1].lifecycle_state == &"SETTLED" and settlement_result.segments[0].end_simulation_msec == settlement_result.segments[1].start_simulation_msec and settlement_result.events[0].segment_index == 0, "Settlement segmentation"): return false
	_pass("settlement_segments_and_order")

	var retained_state := _state()
	var retained_result := _engine().resolve_elapsed(retained_state, HOUR)
	var retained := retained_result.segments[0]
	retained_state.reapings[&"THR_GLOAMWOOD"].is_active = false
	retained_state.reapings[&"THR_GLOAMWOOD"].assignment_revision = 100
	if not _assert(retained.assignment_revision == 11 and retained.form_id == &"FORM_MAN_AT_ARMS", "same timestamp attribution"): return false
	_pass("same_timestamp_attribution")

	var first := SimulationSegmentResult.new(0, &"THR_GLOAMWOOD", 1, &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [], &"OVERDUE", 0, 1000, 1000, 1, 0, 1, 1, 0, 0, 0, [])
	var second := SimulationSegmentResult.new(0, &"THR_GLOAMWOOD", 1, &"FORM_SCRIBE", &"WRIT_STANDARD", [], &"OVERDUE", 0, 1000, 1000, 1, 0, 1, 1, 0, 0, 0, [])
	if not _assert(not first.value_equals(second), "equal output identity distinct"): return false
	_pass("equal_output_identity_distinct")

	var forecast_base := _state(1)
	var forecast_service := SimulationRunService.new(_content_registry())
	var forecast := forecast_service.forecast(forecast_base, 10000)
	var committed_state := forecast_base.deep_clone()
	var committed := forecast_service.run_committed(committed_state, 10000, SimulationRunService.MODE_OFFLINE_FIXTURE)
	var debug_state := forecast_base.deep_clone()
	var debug := forecast_service.run_committed(debug_state, 10000, SimulationRunService.MODE_DEBUG)
	if not _assert(forecast.success and committed.success and debug.success and forecast.simulation_result.value_equals(committed.simulation_result) and committed.simulation_result.value_equals(debug.simulation_result), "mode equality"): return false
	_pass("forecast_commit_mode_equivalence")

	var engine_source := FileAccess.get_file_as_string("res://src/simulation/simulation_engine.gd")
	var transaction_source := FileAccess.get_file_as_string("res://src/simulation/simulation_transaction.gd")
	var result_source := FileAccess.get_file_as_string("res://src/simulation/results/simulation_result.gd")
	if not _assert(not engine_source.contains("class SimulationResult") and not engine_source.contains("class SimulationEvent") and not transaction_source.contains("change_summary") and not result_source.contains("payload"), "raw public grammar removed"): return false
	_pass("raw_public_grammar_removed")

	var snapshot := SaveSchemaMapper.runtime_to_snapshot(eight_hour, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var text := JSON.stringify(snapshot)
	if not _assert(snapshot.schema_version == SaveInt64.format(3) and snapshot.content_revision == ContentRegistry.CURRENT_REVISION and not text.contains("SimulationResult") and not text.contains("channel_deltas") and not text.contains("OUTPUT_CHANNEL_BANKED"), "schema exclusion"): return false
	_pass("schema_v3_no_result_artifacts")
	return true

func _engine() -> SimulationEngine:
	return SimulationEngine.new(_content_registry())

func _content_registry() -> ContentRegistry:
	return _registry

func _state(backlog: int = 1000000, active: bool = true) -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"T2_TRACE")
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
	reaping.assignment_revision = 11
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func _unlock(state: GameState, item_ids: Array[StringName]) -> void:
	var access := OutputAccessService.new(_content_registry())
	for item_id in item_ids: access.unlock_output_item(state, item_id)
	access.reconcile_available_sources(state)

func _canonical(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _argument_value(name: String) -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == name: return str(args[index + 1])
	return ""

func _cleanup_work_root() -> void:
	if FileAccess.file_exists(_probe_path):
		var error := DirAccess.remove_absolute(_probe_path)
		if error != OK: _fail("M04E2T2 probe cleanup failed.")
	if FileAccess.file_exists(_probe_path): _fail("M04E2T2 probe cleanup proof failed.")

func _assert(condition: bool, detail: String) -> bool:
	if condition: return true
	push_error("M04E2T2 trace failure: " + detail)
	return false

func _pass(name: String) -> void:
	var marker := "TRACE M04E2T2 %s=PASS" % name
	_markers.append(marker)
	print(marker)

func _fail(detail: String) -> void:
	push_error(detail)
	quit(1)
