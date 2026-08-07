extends GutTest

func test_ledger_is_independent_runtime_only_and_schema_v3_snapshot_excludes_symbols() -> void:
	var state := GameState.new(0)
	var before_snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	var ledger := ReportLedger.create_empty(0)
	var inner := SimulationResult.timeline_only(10, 0, 10, "r")
	var run := SimulationRunService.SimulationRunResult.new(true, SimulationRunService.MODE_FOREGROUND_SUPPLIED, &"", "", 10, 0, 10, inner, null)
	var applied := ReportLedgerIngestor.ingest_committed_run(ledger, run).candidate_ledger
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_eq(snapshot.schema_version, SaveInt64.format(3), "schema remains v3")
	assert_eq(JSON.stringify(snapshot), JSON.stringify(before_snapshot), "applied runtime ledger does not alter GameState")
	assert_ne(applied, ledger, "ledger candidate is caller-owned")
	var text := JSON.stringify(snapshot)
	for forbidden in ["ReportLedger", "report_ledger", "settlement_events", "ReportLedgerIngestor", "ingest_committed_run"]:
		assert_false(text.contains(forbidden), "snapshot excludes %s" % forbidden)
	var properties := Array(GameState.new().get_property_list()).map(func(value): return String(value.name))
	assert_false(properties.has("report_ledger"), "GameState has no ReportLedger owner")
