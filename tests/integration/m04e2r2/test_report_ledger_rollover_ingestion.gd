extends GutTest

## Packet §8's counted literal continuity matrix. Each case constructs its own
## retained or continuation-only source so a prior row cannot supply authority.
const BASELINE_IDS := [&"retained", &"continuation_only"]
const CANONICAL_ROW_IDS := [
	&"01_identity",
	&"02_lower_revision",
	&"03_greater_revision",
	&"04_backlog",
	&"05_settled_to_overdue",
	&"06_missing_channel",
	&"07_output",
	&"08_period",
	&"09_progress",
	&"10_carry",
	&"11_total",
	&"12_duplicate_settlement",
	&"13_new_channel",
	&"14_new_channel_missing"
]

func test_retained_continuation_supports_post_rollover_ingestion() -> void:
	var source := ReportLedger.create_empty(0)
	var first := SimulationResult.active_reaping(10, 0, 10, "r", [_segment(0, 10, 2, 1)], [])
	source = ReportLedgerIngestor.ingest_committed_run(source, _run(first)).candidate_ledger
	var rolled := ReportLedgerSnapshotter.rollover(source, 10).candidate_ledger
	var second := SimulationResult.active_reaping(10, 10, 20, "r", [_segment(10, 20, 1, 1)], [])
	var result := ReportLedgerIngestor.ingest_committed_run(rolled, _run(second))
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "continuation validates next endpoint: %s" % result.developer_details)
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "full ledger remains valid")

func test_complete_dual_baseline_literal_continuity_matrix() -> void:
	var executed := {}
	for baseline_id in BASELINE_IDS:
		_execute_identity_row(baseline_id)
		executed["%s|01_identity" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"02_lower_revision", _normal_graph_for(baseline_id, {"revision": 1}), ReportLedgerIngestor.ERR_IDENTITY)
		executed["%s|02_lower_revision" % baseline_id] = true
		_execute_greater_revision_row(baseline_id)
		executed["%s|03_greater_revision" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"04_backlog", _normal_graph_for(baseline_id, {"backlog_before": 2, "backlog_after": 1}), ReportLedgerIngestor.ERR_SLICE)
		executed["%s|04_backlog" % baseline_id] = true
		_execute_settled_to_overdue_row(baseline_id)
		executed["%s|05_settled_to_overdue" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"06_missing_channel", _normal_graph_for(baseline_id, {"channels": []}), ReportLedgerIngestor.ERR_CHANNEL)
		executed["%s|06_missing_channel" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"07_output", _normal_graph_for(baseline_id, {"channels": [_channel(&"C", &"ASH", 1000, 1, 2, 1, 2, 0, 0)]}), ReportLedgerIngestor.ERR_CHANNEL)
		executed["%s|07_output" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"08_period", _normal_graph_for(baseline_id, {"channels": [_channel(&"C", &"SOUL", 999, 1, 2, 1, 2, 0, 0)]}), ReportLedgerIngestor.ERR_CHANNEL)
		executed["%s|08_period" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"09_progress", _normal_graph_for(baseline_id, {"channels": [_channel(&"C", &"SOUL", 1000, 0, 2, 1, 2, 0, 0)]}), ReportLedgerIngestor.ERR_CHANNEL)
		executed["%s|09_progress" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"10_carry", _normal_graph_for(baseline_id, {"channels": [_channel(&"C", &"SOUL", 1000, 1, 2, 0, 2, 0, 0)]}), ReportLedgerIngestor.ERR_CHANNEL)
		executed["%s|10_carry" % baseline_id] = true
		_execute_rejection_row(baseline_id, &"11_total", _normal_graph_for(baseline_id, {"channels": [_channel(&"C", &"SOUL", 1000, 1, 2, 1, 2, 1, 1)]}), ReportLedgerIngestor.ERR_CHANNEL)
		executed["%s|11_total" % baseline_id] = true
		_execute_duplicate_settlement_row(baseline_id)
		executed["%s|12_duplicate_settlement" % baseline_id] = true
		_execute_new_channel_row(baseline_id)
		executed["%s|13_new_channel" % baseline_id] = true
		_execute_new_channel_missing_row(baseline_id)
		executed["%s|14_new_channel_missing" % baseline_id] = true
	for baseline_id in BASELINE_IDS:
		for row_id in CANONICAL_ROW_IDS:
			assert_true(executed.has("%s|%s" % [baseline_id, row_id]), "matrix row %s executed from %s baseline" % [row_id, baseline_id])
	assert_eq(executed.size(), BASELINE_IDS.size() * CANONICAL_ROW_IDS.size(), "every canonical row executed from both independently constructed baselines")

func _execute_identity_row(baseline_id: StringName) -> void:
	_execute_rejection_row(baseline_id, &"01_identity_form", _normal_graph_for(baseline_id, {"form": &"F2"}), ReportLedgerIngestor.ERR_IDENTITY)
	_execute_rejection_row(baseline_id, &"01_identity_writ", _normal_graph_for(baseline_id, {"writ": &"W2"}), ReportLedgerIngestor.ERR_IDENTITY)
	_execute_rejection_row(baseline_id, &"01_identity_retinue", _normal_graph_for(baseline_id, {"retinue": [&"B"]}), ReportLedgerIngestor.ERR_IDENTITY)

func _execute_greater_revision_row(baseline_id: StringName) -> void:
	var source := _normal_baseline(baseline_id)
	var graph := _graph(source.ingested_through_simulation_msec, source.ingested_through_simulation_msec + 10, {"revision": 7, "form": &"F2", "writ": &"W2", "retinue": [&"B"]})
	var before := _capture(source, graph)
	var result := ReportLedgerIngestor.ingest_committed_run(source, graph.run)
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "03_greater_revision applies from %s: %s" % [baseline_id, result.developer_details])
	assert_not_null(result.candidate_ledger, "03_greater_revision returns one candidate")
	assert_true(not is_same(result.candidate_ledger, source), "03_greater_revision candidate is detached")
	_assert_preserved(source, graph, before, "03_greater_revision %s source/input" % baseline_id)
	_assert_literal_continuation(result.candidate_ledger, 7, &"F2", &"W2", [&"B"], 1, [[&"C", &"SOUL", 1000, 2, 2, 0]], "03_greater_revision %s candidate" % baseline_id)

func _execute_settled_to_overdue_row(baseline_id: StringName) -> void:
	var source := _settled_baseline(baseline_id)
	var event := SimulationThresholdSettledEvent.new(source.ingested_through_simulation_msec + 10, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	var graph := _graph(source.ingested_through_simulation_msec, source.ingested_through_simulation_msec + 10, {"backlog_before": 1, "backlog_after": 0, "events": [event]})
	_execute_rejection(source, graph, &"05_settled_to_overdue", baseline_id, ReportLedgerIngestor.ERR_SLICE)

func _execute_duplicate_settlement_row(baseline_id: StringName) -> void:
	var source := _settled_baseline(baseline_id)
	var start := source.ingested_through_simulation_msec
	var event := SimulationThresholdSettledEvent.new(start + 10, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	var graph := _graph(start, start + 10, {"backlog_before": 1, "backlog_after": 0, "events": [event]})
	_execute_rejection(source, graph, &"12_duplicate_settlement", baseline_id, ReportLedgerIngestor.ERR_SLICE)

func _execute_new_channel_row(baseline_id: StringName) -> void:
	var source := _normal_baseline(baseline_id)
	var graph := _graph(source.ingested_through_simulation_msec, source.ingested_through_simulation_msec + 10, {"channels": [_channel(&"C", &"SOUL", 1000, 1, 2, 1, 2, 0, 0), _channel(&"D", &"DUST", 1000, 5, 6, 1, 2, 2, 2)]})
	var before := _capture(source, graph)
	var result := ReportLedgerIngestor.ingest_committed_run(source, graph.run)
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "13_new_channel applies from %s: %s" % [baseline_id, result.developer_details])
	assert_not_null(result.candidate_ledger, "13_new_channel returns one candidate")
	assert_true(not is_same(result.candidate_ledger, source), "13_new_channel candidate is detached")
	_assert_preserved(source, graph, before, "13_new_channel %s source/input" % baseline_id)
	_assert_literal_continuation(result.candidate_ledger, 2, &"F", &"W", [&"A"], 1, [[&"C", &"SOUL", 1000, 2, 2, 0], [&"D", &"DUST", 1000, 6, 2, 2]], "13_new_channel %s candidate" % baseline_id)

func _execute_new_channel_missing_row(baseline_id: StringName) -> void:
	var source := _normal_baseline(baseline_id)
	var first_graph := _graph(source.ingested_through_simulation_msec, source.ingested_through_simulation_msec + 10, {"channels": [_channel(&"C", &"SOUL", 1000, 1, 2, 1, 2, 0, 0), _channel(&"D", &"DUST", 1000, 5, 6, 1, 2, 2, 2)]})
	var first_before := _capture(source, first_graph)
	var first := ReportLedgerIngestor.ingest_committed_run(source, first_graph.run)
	assert_eq(first.outcome, ReportLedgerIngestResult.APPLIED, "14_new_channel_missing first appearance applies from %s" % baseline_id)
	assert_not_null(first.candidate_ledger, "14_new_channel_missing has a post-appearance source")
	_assert_preserved(source, first_graph, first_before, "14_new_channel_missing first appearance %s source/input" % baseline_id)
	var next_source: ReportLedger = first.candidate_ledger
	var next_graph := _graph(next_source.ingested_through_simulation_msec, next_source.ingested_through_simulation_msec + 10, {"channels": [_channel(&"C", &"SOUL", 1000, 2, 3, 2, 3, 0, 0)]})
	_execute_rejection(next_source, next_graph, &"14_new_channel_missing", baseline_id, ReportLedgerIngestor.ERR_CHANNEL)

func _execute_rejection_row(baseline_id: StringName, row_id: StringName, graph: Dictionary, expected_code: StringName) -> void:
	var source := _normal_baseline(baseline_id)
	_execute_rejection(source, graph, row_id, baseline_id, expected_code)

func _execute_rejection(source: ReportLedger, graph: Dictionary, row_id: StringName, baseline_id: StringName, expected_code: StringName) -> void:
	var before := _capture(source, graph)
	var result := ReportLedgerIngestor.ingest_committed_run(source, graph.run)
	assert_eq(result.outcome, ReportLedgerIngestResult.REJECTED, "%s rejects from %s" % [row_id, baseline_id])
	assert_eq(result.error_code, expected_code, "%s returns the exact error from %s" % [row_id, baseline_id])
	assert_false(result.developer_details.is_empty(), "%s reports non-empty rejection details" % row_id)
	assert_null(result.candidate_ledger, "%s returns no candidate" % row_id)
	_assert_preserved(source, graph, before, "%s %s source/input" % [row_id, baseline_id])

func _normal_baseline(baseline_id: StringName) -> ReportLedger:
	var source := ReportLedger.create_empty(0)
	var first := _graph(0, 10, {"backlog_before": 2, "backlog_after": 1, "channels": [_channel(&"C", &"SOUL", 1000, 0, 1, 0, 1, 0, 0)]})
	var ingested := ReportLedgerIngestor.ingest_committed_run(source, first.run)
	assert_eq(ingested.outcome, ReportLedgerIngestResult.APPLIED, "normal %s baseline introducing run applies" % baseline_id)
	var rolled := ReportLedgerSnapshotter.rollover(ingested.candidate_ledger, 10)
	assert_eq(rolled.outcome, ReportLedgerSnapshotResult.APPLIED, "normal %s baseline introducing record rolls" % baseline_id)
	return _prune(rolled.candidate_ledger, baseline_id)

func _settled_baseline(baseline_id: StringName) -> ReportLedger:
	var source := ReportLedger.create_empty(0)
	var event := SimulationThresholdSettledEvent.new(10, 0, &"T", 2, 0, 0, &"OVERDUE", &"SETTLED")
	var first := _graph(0, 10, {"backlog_before": 1, "backlog_after": 0, "channels": [_channel(&"C", &"SOUL", 1000, 0, 1, 0, 1, 0, 0)], "events": [event]})
	var ingested := ReportLedgerIngestor.ingest_committed_run(source, first.run)
	assert_eq(ingested.outcome, ReportLedgerIngestResult.APPLIED, "settled %s baseline real Settlement applies" % baseline_id)
	var rolled := ReportLedgerSnapshotter.rollover(ingested.candidate_ledger, 10)
	assert_eq(rolled.outcome, ReportLedgerSnapshotResult.APPLIED, "settled %s baseline rolls its Settlement record" % baseline_id)
	return _prune(rolled.candidate_ledger, baseline_id)

func _prune(source: ReportLedger, baseline_id: StringName) -> ReportLedger:
	if baseline_id == &"retained": return source
	var current := source
	for finish in range(20, 100, 10):
		var timeline := SimulationResult.timeline_only(10, finish - 10, finish, "matrix")
		var ingested := ReportLedgerIngestor.ingest_committed_run(current, _run(timeline))
		assert_eq(ingested.outcome, ReportLedgerIngestResult.APPLIED, "continuation-only baseline ingests timeline %d" % finish)
		var rolled := ReportLedgerSnapshotter.rollover(ingested.candidate_ledger, finish)
		assert_eq(rolled.outcome, ReportLedgerSnapshotResult.APPLIED, "continuation-only baseline rolls timeline %d" % finish)
		current = rolled.candidate_ledger
	assert_eq(current.retained_records.size(), ReportLedger.MAX_RETAINED_RECORDS, "continuation-only baseline keeps capacity eight")
	assert_eq(current.retained_records[0].record_sequence, 2, "continuation-only baseline prunes the introducing record")
	assert_true(current.slices.is_empty() and current.settlement_events.is_empty(), "continuation-only baseline leaves a canonical empty live window")
	assert_true(ReportLedgerValidator.validate(current).ok, "continuation-only baseline remains valid after pruning")
	return current

func _normal_graph_for(baseline_id: StringName, changes: Dictionary) -> Dictionary:
	var cursor := 10 if baseline_id == &"retained" else 90
	return _graph(cursor, cursor + 10, changes)

func _graph(start: int, finish: int, changes: Dictionary = {}) -> Dictionary:
	var channel_specs: Array = changes.get("channels", [_channel(&"C", &"SOUL", 1000, 1, 2, 1, 2, 0, 0)])
	var channels: Array[SimulationChannelDeltaResult] = []
	for spec in channel_specs:
		channels.append(SimulationChannelDeltaResult.new(spec.channel_id, spec.output_item_id, spec.total_after - spec.total_before, spec.progress_before, spec.progress_after, spec.period, spec.carry_before, spec.carry_after, spec.total_before, spec.total_after))
	var retinue: Array[StringName] = []
	for retinue_id in changes.get("retinue", [&"A"]): retinue.append(StringName(retinue_id))
	var segment := SimulationSegmentResult.new(0, &"T", int(changes.get("revision", 2)), StringName(changes.get("form", &"F")), StringName(changes.get("writ", &"W")), retinue, &"OVERDUE", start, finish, finish - start, int(changes.get("backlog_before", 1)) - int(changes.get("backlog_after", 1)), int(changes.get("backlog_before", 1)) - int(changes.get("backlog_after", 1)), int(changes.get("backlog_before", 1)), int(changes.get("backlog_after", 1)), 0, 0, 0, channels)
	var events: Array[SimulationEvent] = []
	for event in changes.get("events", []): events.append(event)
	var inner := SimulationResult.active_reaping(finish - start, start, finish, "matrix", [segment], events)
	var run := _run(inner)
	var input_refs: Array = [run, inner, segment]
	input_refs.append_array(channels)
	input_refs.append_array(events)
	return {"run": run, "inner": inner, "segment": segment, "channels": channels, "events": events, "input_refs": input_refs}

func _channel(channel_id: StringName, output_item_id: StringName, period: int, progress_before: int, progress_after: int, carry_before: int, carry_after: int, total_before: int, total_after: int) -> Dictionary:
	return {"channel_id": channel_id, "output_item_id": output_item_id, "period": period, "progress_before": progress_before, "progress_after": progress_after, "carry_before": carry_before, "carry_after": carry_after, "total_before": total_before, "total_after": total_after}

func _capture(source: ReportLedger, graph: Dictionary) -> Dictionary:
	var channel_values: Array = []
	for channel in graph.channels: channel_values.append(channel.detached_copy())
	var event_values: Array = []
	for event in graph.events: event_values.append(event.detached_copy())
	return {"source_value": source.deep_clone(), "source_refs": _report_refs(source), "run": graph.run, "inner": graph.inner, "inner_value": graph.inner.detached_copy(), "segment": graph.segment, "segment_value": graph.segment.detached_copy(), "channel_values": channel_values, "event_values": event_values, "input_refs": graph.input_refs.duplicate()}

func _assert_preserved(source: ReportLedger, graph: Dictionary, before: Dictionary, label: String) -> void:
	assert_true(source.value_equals(before.source_value), "%s preserves source values" % label)
	assert_true(_same_refs(_report_refs(source), before.source_refs), "%s preserves source root and nested report-node references" % label)
	assert_true(is_same(graph.run, before.run) and is_same(graph.inner, before.inner), "%s preserves wrapper and inner-result references" % label)
	assert_true(graph.inner.value_equals(before.inner_value), "%s preserves inner-result values" % label)
	assert_true(is_same(graph.segment, before.segment) and graph.segment.value_equals(before.segment_value), "%s preserves segment reference and value" % label)
	assert_true(_same_refs(graph.input_refs, before.input_refs), "%s preserves channel/event input references" % label)
	for index in range(graph.channels.size()):
		assert_true(graph.channels[index].value_equals(before.channel_values[index]), "%s preserves channel %d value" % [label, index])
	for index in range(graph.events.size()):
		assert_true(graph.events[index].value_equals(before.event_values[index]), "%s preserves event %d value" % [label, index])

func _assert_literal_continuation(candidate: ReportLedger, revision: int, form_id: StringName, writ_id: StringName, retinue: Array[StringName], backlog: int, endpoints: Array, label: String) -> void:
	assert_eq(candidate.ingested_through_simulation_msec, candidate.window_start_simulation_msec + 10, "%s stores the exact interval cursor" % label)
	assert_eq(candidate.slices.size(), 1, "%s retains the exact new live slice" % label)
	assert_eq(candidate.threshold_continuations.size(), 1, "%s stores one Threshold continuation" % label)
	var continuation: ReportThresholdContinuation = candidate.threshold_continuations[0]
	assert_eq(continuation.latest_assignment_revision, revision, "%s stores literal revision" % label)
	assert_eq(continuation.form_id, form_id, "%s stores literal Form" % label)
	assert_eq(continuation.writ_id, writ_id, "%s stores literal Writ" % label)
	assert_eq(continuation.ordered_retinue_ids, retinue, "%s stores literal Retinue order" % label)
	assert_eq(continuation.lifecycle_state, &"OVERDUE", "%s stores literal lifecycle" % label)
	assert_eq(continuation.remaining_backlog, backlog, "%s stores literal backlog endpoint" % label)
	assert_eq(continuation.channels.size(), endpoints.size(), "%s stores every literal channel endpoint" % label)
	for index in range(endpoints.size()):
		var expected: Array = endpoints[index]
		var actual: ReportChannelContinuation = continuation.channels[index]
		assert_eq(actual.channel_id, expected[0], "%s channel %d ID" % [label, index])
		assert_eq(actual.output_item_id, expected[1], "%s channel %d output" % [label, index])
		assert_eq(actual.rate_period_msec, expected[2], "%s channel %d period" % [label, index])
		assert_eq(actual.progress_subunits, expected[3], "%s channel %d progress" % [label, index])
		assert_eq(actual.rate_carry_units, expected[4], "%s channel %d carry" % [label, index])
		assert_eq(actual.total_banked_units, expected[5], "%s channel %d total" % [label, index])

func _report_refs(ledger: ReportLedger) -> Array:
	var refs: Array = [ledger]
	for continuation in ledger.threshold_continuations:
		refs.append(continuation)
		refs.append_array(continuation.channels)
	for record in ledger.retained_records:
		refs.append(record)
		refs.append_array(record.slices)
		refs.append_array(record.settlement_events)
		for slice in record.slices: refs.append_array(slice.channels)
	refs.append_array(ledger.slices)
	refs.append_array(ledger.settlement_events)
	for slice in ledger.slices: refs.append_array(slice.channels)
	return refs

func _same_refs(left: Array, right: Array) -> bool:
	if left.size() != right.size(): return false
	for index in range(left.size()):
		if not is_same(left[index], right[index]): return false
	return true

func _segment(start: int, finish: int, before: int, after: int, revision: int = 1, progress_before: int = 0) -> SimulationSegmentResult:
	var channel := SimulationChannelDeltaResult.new(&"C", &"SOUL", 0, progress_before, 0, 1000, 0, 0, 0, 0)
	return SimulationSegmentResult.new(0, &"T", revision, &"F", &"W", [&"A"], &"OVERDUE", start, finish, finish - start, before - after, before - after, before, after, 0, 0, 0, [channel])

func _run(inner: SimulationResult) -> SimulationRunService.SimulationRunResult:
	return SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", inner.requested_elapsed_msec, inner.baseline_simulation_time_msec, inner.result_simulation_time_msec, inner, null)
