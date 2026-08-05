extends GutTest

func test_ledger_is_runtime_only_and_schema_v3_snapshot_has_no_report_symbols() -> void:
	var ledger := ReportLedger.create_empty(0)
	assert_true(ReportLedgerValidator.validate(ledger).ok)
	var state := GameState.new(0)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_eq(snapshot.schema_version, SaveInt64.format(3))
	var text := JSON.stringify(snapshot)
	for forbidden in ["ReportLedger", "report_ledger", "settlement_events", "ReportLedgerIngestor"]:
		assert_false(text.contains(forbidden), forbidden)
