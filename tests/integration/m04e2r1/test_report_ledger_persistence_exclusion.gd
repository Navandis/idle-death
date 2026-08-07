extends GutTest

func test_ledger_candidate_is_detached_and_excluded_from_schema_v3_ownership() -> void:
	var state := GameState.new(0)
	var before_snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var source := ReportLedger.create_empty(0)
	var inner := SimulationResult.timeline_only(10, 0, 10, "r")
	var run := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", 10, 0, 10, inner, null)
	var result := ReportLedgerIngestor.ingest_committed_run(source, run)
	assert_true(result.success, "ingest success")
	assert_true(result.changed, "ingest changed")
	assert_eq(result.outcome, ReportLedgerIngestResult.APPLIED, "ingest applied")
	assert_eq(result.error_code, &"", "applied error is empty")
	assert_eq(result.developer_details, "", "applied details are empty")
	assert_not_null(result.candidate_ledger, "candidate exists")
	assert_true(ReportLedgerValidator.validate(result.candidate_ledger).ok, "candidate validates")
	assert_ne(result.candidate_ledger, source, "candidate is detached")
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_eq(snapshot.schema_version, SaveInt64.format(3), "schema remains v3")
	assert_eq(JSON.stringify(snapshot), JSON.stringify(before_snapshot), "runtime ledger is not serialized")
	var candidate := result.candidate_ledger
	candidate.debug_elapsed_msec = 10
	assert_eq(source.debug_elapsed_msec, 0, "candidate mutation leaves source")
	assert_eq(JSON.stringify(snapshot), JSON.stringify(before_snapshot), "candidate mutation leaves snapshot")
	source.offline_elapsed_msec = 10
	assert_eq(candidate.offline_elapsed_msec, 0, "source mutation leaves candidate")
	assert_eq(JSON.stringify(snapshot), JSON.stringify(before_snapshot), "source mutation leaves snapshot")
	state.simulation_time_msec = 7
	assert_eq(source.ingested_through_simulation_msec, 0, "GameState mutation leaves source")
	assert_eq(candidate.ingested_through_simulation_msec, 10, "GameState mutation leaves candidate")
	assert_eq(JSON.stringify(snapshot), JSON.stringify(before_snapshot), "GameState mutation leaves snapshot")
	snapshot.schema_version = SaveInt64.format(99)
	assert_eq(SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).schema_version, SaveInt64.format(3), "snapshot mutation leaves GameState")
	assert_eq(source.ingested_through_simulation_msec, 0, "snapshot mutation leaves source")
	assert_eq(candidate.ingested_through_simulation_msec, 10, "snapshot mutation leaves candidate")
	var text := JSON.stringify(snapshot)
	for forbidden in ["ReportLedger", "report_ledger", "settlement_events", "ReportLedgerIngestor", "ingest_committed_run", "REPORT_INGEST_"]:
		assert_false(text.contains(forbidden), "snapshot excludes %s" % forbidden)
	var properties := Array(GameState.new().get_property_list()).map(func(value): return String(value.name))
	assert_false(properties.has("report_ledger"), "GameState has no ReportLedger owner")
	assert_false(result.candidate_ledger == null, "null candidate cannot prove ownership")
