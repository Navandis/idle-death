extends GutTest

func test_four_way_runtime_ownership_isolation_uses_fresh_bundles() -> void:
	var candidate_bundle := _ownership_bundle()
	candidate_bundle.candidate.foreground_elapsed_msec = 99
	assert_true(candidate_bundle.source.value_equals(candidate_bundle.source_fingerprint), "candidate mutation leaves source")
	assert_eq(_state_fingerprint(candidate_bundle.state), candidate_bundle.state_fingerprint, "candidate mutation leaves GameState")
	assert_eq(JSON.stringify(candidate_bundle.snapshot), candidate_bundle.snapshot_fingerprint, "candidate mutation leaves snapshot")
	var source_bundle := _ownership_bundle()
	source_bundle.source.next_event_sequence = 9
	assert_true(source_bundle.candidate.value_equals(source_bundle.candidate_fingerprint), "source mutation leaves candidate")
	assert_eq(_state_fingerprint(source_bundle.state), source_bundle.state_fingerprint, "source mutation leaves GameState")
	assert_eq(JSON.stringify(source_bundle.snapshot), source_bundle.snapshot_fingerprint, "source mutation leaves snapshot")
	var state_bundle := _ownership_bundle()
	state_bundle.state.simulation_time_msec = 99
	assert_true(state_bundle.source.value_equals(state_bundle.source_fingerprint), "GameState mutation leaves source")
	assert_true(state_bundle.candidate.value_equals(state_bundle.candidate_fingerprint), "GameState mutation leaves candidate")
	assert_eq(JSON.stringify(state_bundle.snapshot), state_bundle.snapshot_fingerprint, "GameState mutation leaves snapshot")
	assert_ne(_state_fingerprint(state_bundle.state), state_bundle.state_fingerprint, "new GameState mapping fingerprint changes")
	var snapshot_bundle := _ownership_bundle()
	snapshot_bundle.snapshot.schema_version = "9"
	assert_true(snapshot_bundle.source.value_equals(snapshot_bundle.source_fingerprint), "snapshot mutation leaves source")
	assert_true(snapshot_bundle.candidate.value_equals(snapshot_bundle.candidate_fingerprint), "snapshot mutation leaves candidate")
	assert_eq(_state_fingerprint(snapshot_bundle.state), snapshot_bundle.state_fingerprint, "snapshot mutation leaves GameState")

func test_schema_v3_and_serialized_output_exclude_all_ledger_symbols() -> void:
	var bundle := _ownership_bundle()
	assert_true(_owns_isolated_candidate(bundle.candidate), "real candidate satisfies ownership predicate")
	assert_eq(bundle.snapshot.schema_version, SaveInt64.format(3), "schema remains v3")
	var properties := Array(GameState.new().get_property_list()).map(func(value): return String(value.name))
	assert_false(properties.has("report_ledger"), "GameState has no report ledger property")
	var serialized := JSON.stringify(bundle.snapshot)
	for forbidden in ["ReportLedger", "report_ledger", "settlement_events", "ReportLedgerIngestor", "ingest_committed_run", "REPORT_INGEST_"]:
		assert_false(serialized.contains(forbidden), "serialized snapshot excludes %s" % forbidden)
	var null_candidate: ReportLedger = null
	assert_false(_owns_isolated_candidate(null_candidate), "null candidate fails ownership predicate")

func _ownership_bundle() -> Dictionary:
	var state := GameState.new(0)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var snapshot_fingerprint := JSON.stringify(snapshot)
	var source := ReportLedger.create_empty(0)
	var source_before := source.deep_clone()
	var inner := SimulationResult.timeline_only(10, 0, 10, "r")
	var run := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", 10, 0, 10, inner, null)
	var result := ReportLedgerIngestor.ingest_committed_run(source, run)
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "bundle ingestion applies")
	assert_true(result.success and result.changed, "bundle result success/changed")
	assert_eq(result.error_code, &"", "bundle result empty error")
	assert_eq(result.developer_details, "", "bundle result empty details")
	assert_not_null(result.candidate_ledger, "bundle has non-null candidate")
	assert_ne(result.candidate_ledger, source, "bundle candidate detached")
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "bundle candidate validates")
	assert_eq(JSON.stringify(SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)), snapshot_fingerprint, "post-ingestion GameState snapshot equals pre-ingestion snapshot")
	assert_true(source.value_equals(source_before), "bundle source remains value-equal to source-before")
	# Applying a caller-owned ledger changes no state that the mapper observes.
	assert_eq(_state_fingerprint(state), snapshot_fingerprint, "runtime ledger does not change GameState snapshot")
	return {"source": source, "candidate": result.candidate_ledger, "state": state, "snapshot": snapshot, "source_fingerprint": source_before, "candidate_fingerprint": result.candidate_ledger.deep_clone(), "state_fingerprint": snapshot_fingerprint, "snapshot_fingerprint": snapshot_fingerprint}

func _owns_isolated_candidate(candidate: ReportLedger) -> bool:
	return candidate != null and ReportLedgerValidator.validate(candidate).ok

func _state_fingerprint(state: GameState) -> String:
	return JSON.stringify(SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION))
