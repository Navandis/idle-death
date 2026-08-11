extends GutTest

func test_schema_and_serialized_snapshot_exclude_r2_symbols() -> void:
	var state := GameState.new(0)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	assert_eq(snapshot.schema_version, SaveInt64.format(3), "R2 retains schema version three")
	var serialized := JSON.stringify(snapshot)
	for symbol in ["ReportWindowRecord", "ReportLedgerSnapshotter", "ReportLedgerReader", "threshold_continuations", "retained_records", "next_record_sequence"]:
		assert_false(serialized.contains(symbol), "snapshot excludes %s" % symbol)
