extends GutTest

func test_reader_returns_detached_live_history_and_not_found_grammars() -> void:
	var source := ReportLedger.create_empty(0)
	source.ingested_through_simulation_msec = 5
	source.foreground_elapsed_msec = 5
	var rolled := ReportLedgerSnapshotter.rollover(source, 5).candidate_ledger
	var history := ReportLedgerReader.read_history(rolled)
	assert_true(history.ok and history.records.size() == 1, "history is returned")
	history.records[0].foreground_elapsed_msec = 99
	assert_eq(rolled.retained_records[0].foreground_elapsed_msec, 5, "history copy is detached")
	var missing := ReportLedgerReader.read_record(rolled, 9)
	assert_true(missing.ok and not missing.found and missing.record == null, "missing positive sequence is not an error")
	assert_eq(ReportLedgerReader.read_record(rolled, 0).code, ReportLedgerReader.ERR_SEQUENCE_INVALID, "zero sequence rejects")
