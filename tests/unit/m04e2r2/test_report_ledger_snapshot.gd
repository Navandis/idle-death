extends GutTest

func test_rollover_projects_timeline_window_and_empty_redelivery_no_ops() -> void:
	var source := ReportLedger.create_empty(0)
	source.ingested_through_simulation_msec = 10
	source.foreground_elapsed_msec = 10
	var result := ReportLedgerSnapshotter.rollover(source, 10)
	assert_true(result.success and result.changed, "positive timeline window rolls")
	assert_eq(result.created_record_sequence, 1, "first sequence")
	assert_eq(result.candidate_ledger.retained_records[0].window_end_simulation_msec, 10, "record ends at live cursor")
	assert_eq(result.candidate_ledger.window_start_simulation_msec, 10, "next live window starts at cursor")
	assert_eq(ReportLedgerSnapshotter.rollover(result.candidate_ledger, 10).outcome, ReportLedgerSnapshotResult.EMPTY_NO_OP, "canonical empty redelivery is idempotent")

func test_rollover_rejects_invalid_cursor_without_source_mutation() -> void:
	var source := ReportLedger.create_empty(0)
	var before := source.deep_clone()
	var result := ReportLedgerSnapshotter.rollover(source, -1)
	assert_eq(result.error_code, ReportLedgerSnapshotter.ERR_CURSOR_INVALID, "negative cursor rejects")
	assert_true(source.value_equals(before), "rejection preserves source")
