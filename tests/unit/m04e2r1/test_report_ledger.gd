extends GutTest

## This file is deliberately table-driven, but each row carries its literal ID,
## valid fixture, one mutation, and direct proof of the named bad condition.

const EQUALITY_IDS := [
	"EQ-R01", "EQ-R02", "EQ-R03", "EQ-R04", "EQ-R05", "EQ-R06", "EQ-R07", "EQ-R08",
	"EQ-S01", "EQ-S02", "EQ-S03", "EQ-S04", "EQ-S05", "EQ-S06", "EQ-S07", "EQ-S08", "EQ-S09", "EQ-S10", "EQ-S11", "EQ-S12", "EQ-S13", "EQ-S14", "EQ-S15", "EQ-S16", "EQ-S17",
	"EQ-C01", "EQ-C02", "EQ-C03", "EQ-C04", "EQ-C05", "EQ-C06", "EQ-C07", "EQ-C08", "EQ-C09", "EQ-C10", "EQ-C11",
	"EQ-E01", "EQ-E02", "EQ-E03", "EQ-E04", "EQ-E05", "EQ-E06"
]

func test_factory_and_validator_result_grammar() -> void:
	var expected_keys := ["ok", "code", "details"]
	for start in [0, 17]:
		var ledger := ReportLedger.create_empty(start)
		assert_not_null(ledger, "factory accepts %d" % start)
		var result := ReportLedgerValidator.validate(ledger)
		assert_true(_same_string_set(result.keys(), expected_keys), "success keys %d" % start)
		assert_true(result.ok, "empty ledger validates %d" % start)
		assert_eq(result.code, &"", "success code %d" % start)
		assert_eq(result.details, "", "success details %d" % start)
	assert_null(ReportLedger.create_empty(-1), "negative factory cursor is null")
	var invalid := _canonical()
	invalid.next_event_sequence = 0
	var failure := ReportLedgerValidator.validate(invalid)
	assert_true(_same_string_set(failure.keys(), expected_keys), "failure keys")
	assert_false(failure.ok, "failure ok")
	assert_eq(failure.code, ReportLedgerValidator.FAILURE, "failure code")
	assert_ne(failure.details, "", "failure details")

func test_exact_42_field_equality_inventory_and_clone_isolation() -> void:
	assert_eq(EQUALITY_IDS.size(), 42, "the equality inventory has exactly 42 fields")
	assert_true(_has_unique(EQUALITY_IDS), "no duplicate equality ID")
	var rows := [
		_eq("EQ-R01", "window_start_simulation_msec", func(l): l.window_start_simulation_msec = 1),
		_eq("EQ-R02", "ingested_through_simulation_msec", func(l): l.ingested_through_simulation_msec = 11),
		_eq("EQ-R03", "foreground_elapsed_msec", func(l): l.foreground_elapsed_msec = 9),
		_eq("EQ-R04", "offline_elapsed_msec", func(l): l.offline_elapsed_msec = 1),
		_eq("EQ-R05", "debug_elapsed_msec", func(l): l.debug_elapsed_msec = 1),
		_eq("EQ-R06", "next_event_sequence", func(l): l.next_event_sequence = 9),
		_eq("EQ-R07", "slices array membership", func(l): l.slices.clear()),
		_eq("EQ-R08", "settlement_events array membership", func(l): l.settlement_events.clear()),
		_eq("EQ-S01", "run_mode", func(l): l.slices[0].run_mode = SimulationRunService.MODE_DEBUG),
		_eq("EQ-S02", "content_revision", func(l): l.slices[0].content_revision = "other"),
		_eq("EQ-S03", "threshold_id", func(l): l.slices[0].threshold_id = &"OTHER"),
		_eq("EQ-S04", "assignment_revision", func(l): l.slices[0].assignment_revision = 2),
		_eq("EQ-S05", "form_id", func(l): l.slices[0].form_id = &"FORM_OTHER"),
		_eq("EQ-S06", "writ_id", func(l): l.slices[0].writ_id = &"WRIT_OTHER"),
		_eq("EQ-S07", "ordered_retinue_ids content/order", func(l): l.slices[0].ordered_retinue_ids[0] = &"RET_B"),
		_eq("EQ-S08", "lifecycle_state", func(l): l.slices[0].lifecycle_state = &"SETTLED"),
		_eq("EQ-S09", "start_simulation_msec", func(l): l.slices[0].start_simulation_msec = 1),
		_eq("EQ-S10", "end_simulation_msec", func(l): l.slices[0].end_simulation_msec = 11),
		_eq("EQ-S11", "returned_souls_delta", func(l): l.slices[0].returned_souls_delta = 7),
		_eq("EQ-S12", "remaining_backlog_before", func(l): l.slices[0].remaining_backlog_before = 11),
		_eq("EQ-S13", "remaining_backlog_after", func(l): l.slices[0].remaining_backlog_after = 1),
		_eq("EQ-S14", "essence_delta", func(l): l.slices[0].essence_delta = 7),
		_eq("EQ-S15", "mastery_delta_subunits", func(l): l.slices[0].mastery_delta_subunits = 7),
		_eq("EQ-S16", "completed_cycles_delta", func(l): l.slices[0].completed_cycles_delta = 7),
		_eq("EQ-S17", "channels array membership", func(l): l.slices[0].channels.clear()),
		_eq("EQ-C01", "channel_id", func(l): l.slices[0].channels[0].channel_id = &"Z"),
		_eq("EQ-C02", "output_item_id", func(l): l.slices[0].channels[0].output_item_id = &"OTHER"),
		_eq("EQ-C03", "start_simulation_msec", func(l): l.slices[0].channels[0].start_simulation_msec = 1),
		_eq("EQ-C04", "end_simulation_msec", func(l): l.slices[0].channels[0].end_simulation_msec = 9),
		_eq("EQ-C05", "progress_subunits_before", func(l): l.slices[0].channels[0].progress_subunits_before = 2),
		_eq("EQ-C06", "progress_subunits_after", func(l): l.slices[0].channels[0].progress_subunits_after = 2),
		_eq("EQ-C07", "rate_period_msec", func(l): l.slices[0].channels[0].rate_period_msec = 99),
		_eq("EQ-C08", "rate_carry_units_before", func(l): l.slices[0].channels[0].rate_carry_units_before = 2),
		_eq("EQ-C09", "rate_carry_units_after", func(l): l.slices[0].channels[0].rate_carry_units_after = 2),
		_eq("EQ-C10", "total_banked_units_before", func(l): l.slices[0].channels[0].total_banked_units_before = 2),
		_eq("EQ-C11", "total_banked_units_after", func(l): l.slices[0].channels[0].total_banked_units_after = 2),
		_eq("EQ-E01", "event_sequence", func(l): l.settlement_events[0].event_sequence = 2),
		_eq("EQ-E02", "content_revision", func(l): l.settlement_events[0].content_revision = "other"),
		_eq("EQ-E03", "threshold_id", func(l): l.settlement_events[0].threshold_id = &"OTHER"),
		_eq("EQ-E04", "assignment_revision", func(l): l.settlement_events[0].assignment_revision = 2),
		_eq("EQ-E05", "occurred_simulation_msec", func(l): l.settlement_events[0].occurred_simulation_msec = 9),
		_eq("EQ-E06", "persistent_returns_total", func(l): l.settlement_events[0].persistent_returns_total = 8)
	]
	var actual_ids: Array[String] = []
	for row in rows:
		actual_ids.append(row.id)
		var source := _canonical()
		assert_true(ReportLedgerValidator.validate(source).ok, "%s source validates" % row.id)
		var snapshot := source.deep_clone()
		var clone := source.deep_clone()
		assert_true(clone.value_equals(source), "%s initial equality" % row.id)
		row.mutate.call(clone)
		assert_false(clone.value_equals(source), "%s one named field differs: %s" % [row.id, row.path])
		assert_true(source.value_equals(snapshot), "%s source remains isolated" % row.id)
	assert_eq(actual_ids, EQUALITY_IDS, "exact expected equality ID order")

func test_complete_validator_matrix_with_fresh_valid_baselines() -> void:
	var rows := _validator_rows()
	var expected := _validator_expected_ids()
	var actual: Array[String] = []
	assert_eq(expected.size(), 80, "literal validator expected-ID inventory has 80 IDs")
	for row in rows:
		actual.append(row.id)
		var ledger: ReportLedger = row.build.call()
		assert_true(ReportLedgerValidator.validate(ledger).ok, "%s fresh baseline validates" % row.id)
		var subject := [ledger]
		row.mutate.call(subject)
		var tested_subject = subject[0]
		assert_true(row.probe.call(tested_subject), "%s target condition exists" % row.id)
		var failure := ReportLedgerValidator.validate(tested_subject)
		row.verify.call(failure)
	assert_eq(actual, expected, "validator matrix has 80 actual IDs with zero missing or unknown IDs")
	assert_true(_has_unique(actual), "validator IDs are unique")

func test_channel_interval_may_be_strictly_contained_in_owning_slice() -> void:
	# Containment does not require channel endpoints to equal its slice endpoints.
	var ledger := _canonical()
	ledger.slices[0].channels[0].start_simulation_msec = 2
	ledger.slices[0].channels[0].end_simulation_msec = 8
	assert_true(ReportLedgerValidator.validate(ledger).ok, "channel [2,8) is contained in slice [0,10)")

func test_r2_root_fields_clone_and_equality_are_detached() -> void:
	var ledger := _canonical()
	ledger.next_record_sequence = 2
	var record := ReportWindowRecord.new()
	record.record_sequence = 1
	record.window_end_simulation_msec = 10
	record.foreground_elapsed_msec = 10
	ledger.retained_records.append(record)
	var continuation := ReportThresholdContinuation.new()
	continuation.threshold_id = &"THRESHOLD_A"
	continuation.latest_assignment_revision = 1
	continuation.form_id = &"FORM_A"
	continuation.writ_id = &"WRIT_A"
	continuation.lifecycle_state = &"OVERDUE"
	continuation.remaining_backlog = 0
	continuation.has_settled = true
	ledger.threshold_continuations.append(continuation)
	var copy := ledger.deep_clone()
	assert_true(copy.value_equals(ledger), "R2 root fields participate in equality")
	copy.retained_records[0].record_sequence = 2
	assert_false(copy.value_equals(ledger), "record sequence differs")
	assert_eq(ledger.retained_records[0].record_sequence, 1, "record is detached")

func _eq(id: String, path: String, mutate: Callable) -> Dictionary:
	return {"id": id, "path": path, "mutate": mutate}

func _validator_expected_ids() -> Array[String]:
	return [
		"V-ROOT-01",
		"V-ROOT-02",
		"V-ROOT-03",
		"V-ROOT-04",
		"V-ROOT-05",
		"V-ROOT-06",
		"V-ROOT-07",
		"V-SLICE-01",
		"V-SLICE-02",
		"V-SLICE-03",
		"V-SLICE-04",
		"V-SLICE-05",
		"V-SLICE-06",
		"V-SLICE-07",
		"V-SLICE-08",
		"V-SLICE-09",
		"V-SLICE-10",
		"V-SLICE-11",
		"V-SLICE-12",
		"V-SLICE-13",
		"V-SLICE-14",
		"V-SLICE-15",
		"V-SLICE-16",
		"V-SLICE-17",
		"V-SLICE-18",
		"V-SLICE-19",
		"V-SLICE-20",
		"V-SLICE-21",
		"V-SLICE-22",
		"V-SLICE-23",
		"V-SLICE-24",
		"V-SLICE-25",
		"V-SLICE-26",
		"V-CHAN-01",
		"V-CHAN-02",
		"V-CHAN-03",
		"V-CHAN-04",
		"V-CHAN-05",
		"V-CHAN-06",
		"V-CHAN-07",
		"V-CHAN-08",
		"V-CHAN-09",
		"V-CHAN-10",
		"V-CHAN-11",
		"V-CHAN-12",
		"V-CHAN-13",
		"V-CHAN-14",
		"V-CHAN-15",
		"V-CHAN-16",
		"V-CHAN-17",
		"V-CHAN-18",
		"V-CHAN-19",
		"V-EVT-01",
		"V-EVT-02",
		"V-EVT-03",
		"V-EVT-04",
		"V-EVT-05",
		"V-EVT-06",
		"V-EVT-07",
		"V-EVT-08",
		"V-EVT-09",
		"V-EVT-10",
		"V-EVT-11",
		"V-EVT-12",
		"V-EVT-13",
		"V-EVT-14",
		"V-EVT-15",
		"V-EVT-16",
		"V-EVT-17",
		"V-CONT-01",
		"V-CONT-02",
		"V-CONT-03",
		"V-CONT-04",
		"V-CONT-05",
		"V-CONT-06",
		"V-CONT-07",
		"V-CONT-08",
		"V-CONT-09",
		"V-CONT-10",
		"V-CONT-11"
	]

func _row(id: String, build: Callable, mutate: Callable, probe: Callable, mutates_subject: bool = false) -> Dictionary:
	var apply_mutation := func(subject):
		mutate.call(subject if mutates_subject else subject[0])
	return {"id": id, "build": build, "mutate": apply_mutation, "probe": probe, "verify": func(failure): _assert_validator_failure(failure, id)}

func _assert_validator_failure(failure: Dictionary, id: String) -> void:
	assert_true(_same_string_set(failure.keys(), ["code", "details", "ok"]), "%s exact result keys" % id)
	assert_false(failure.ok, "%s rejects" % id)
	assert_eq(failure.code, ReportLedgerValidator.FAILURE, "%s failure code" % id)
	assert_ne(failure.details, "", "%s failure details" % id)

func _validator_rows() -> Array:
	var r := []
	r.append_array([
		_row("V-ROOT-01", func(): return _canonical(), func(subject): subject[0] = null, func(subject): return subject == null, true),
		_row("V-ROOT-02", func(): return _canonical(), func(l): l.window_start_simulation_msec = -1, func(l): return l.window_start_simulation_msec < 0),
		_row("V-ROOT-03", func(): return _canonical(), func(l): l.ingested_through_simulation_msec = -1, func(l): return l.ingested_through_simulation_msec < l.window_start_simulation_msec),
		_row("V-ROOT-04", func(): return _canonical(), func(l): l.foreground_elapsed_msec = -1, func(l): return l.foreground_elapsed_msec < 0),
		_row("V-ROOT-05", func(): return _canonical(), func(l): l.foreground_elapsed_msec = 9, func(l): return l.foreground_elapsed_msec + l.offline_elapsed_msec + l.debug_elapsed_msec != l.ingested_through_simulation_msec - l.window_start_simulation_msec),
		_row("V-ROOT-06", func(): return _root_overflow(), func(l): l.offline_elapsed_msec = 1, func(l): return l.foreground_elapsed_msec > FixedPoint.INT64_MAX - l.offline_elapsed_msec),
		_row("V-ROOT-07", func(): return _canonical(), func(l): l.next_event_sequence = 0, func(l): return l.next_event_sequence < 1)
	])
	r.append_array([
		_row("V-SLICE-01", func(): return _canonical(), func(l): l.slices[0] = null, func(l): return l.slices[0] == null),
		_row("V-SLICE-02", func(): return _canonical(), func(l): l.slices[0].run_mode = &"UNKNOWN", func(l): return not ReportLedgerValidator.MODES.has(l.slices[0].run_mode)),
		_row("V-SLICE-03", func(): return _canonical(), func(l): l.slices[0].content_revision = "", func(l): return l.slices[0].content_revision.is_empty()),
		_row("V-SLICE-04", func(): return _canonical(), func(l): l.slices[0].threshold_id = &"", func(l): return str(l.slices[0].threshold_id).is_empty()),
		_row("V-SLICE-05", func(): return _canonical(), func(l): l.slices[0].assignment_revision = 0, func(l): return l.slices[0].assignment_revision <= 0),
		_row("V-SLICE-06", func(): return _canonical(), func(l): l.slices[0].form_id = &"", func(l): return str(l.slices[0].form_id).is_empty()),
		_row("V-SLICE-07", func(): return _canonical(), func(l): l.slices[0].writ_id = &"", func(l): return str(l.slices[0].writ_id).is_empty()),
		_row("V-SLICE-08", func(): return _canonical(), func(l): l.slices[0].ordered_retinue_ids[0] = &"", func(l): return str(l.slices[0].ordered_retinue_ids[0]).is_empty()),
		_row("V-SLICE-09", func(): return _canonical(), func(l): l.slices[0].ordered_retinue_ids[1] = &"RET_A", func(l): return l.slices[0].ordered_retinue_ids[0] == l.slices[0].ordered_retinue_ids[1]),
		_row("V-SLICE-10", func(): return _canonical(), func(l): l.slices[0].lifecycle_state = &"INVALID", func(l): return not [&"OVERDUE", &"SETTLED"].has(l.slices[0].lifecycle_state)),
		_row("V-SLICE-11", func(): return _canonical(), func(l): l.slices[0].start_simulation_msec = -1, func(l): return l.slices[0].start_simulation_msec < l.window_start_simulation_msec),
		_row("V-SLICE-12", func(): return _two_slices(), func(l): l.slices[1].start_simulation_msec = 5, func(l): return l.slices[1].start_simulation_msec < l.slices[0].end_simulation_msec),
		_row("V-SLICE-13", func(): return _canonical(), func(l): l.slices[0].end_simulation_msec = 0, func(l): return l.slices[0].end_simulation_msec <= l.slices[0].start_simulation_msec),
		_row("V-SLICE-14", func(): return _canonical(), func(l): l.slices[0].end_simulation_msec = 11, func(l): return l.slices[0].end_simulation_msec > l.ingested_through_simulation_msec),
		_row("V-SLICE-15", func(): return _canonical(), func(l): l.slices[0].returned_souls_delta = -1, func(l): return l.slices[0].returned_souls_delta < 0),
		_row("V-SLICE-16", func(): return _canonical(), func(l): l.slices[0].remaining_backlog_before = -1, func(l): return l.slices[0].remaining_backlog_before < 0),
		_row("V-SLICE-17", func(): return _canonical(), func(l): l.slices[0].remaining_backlog_after = -1, func(l): return l.slices[0].remaining_backlog_after < 0),
		_row("V-SLICE-18", func(): return _canonical(), func(l): l.slices[0].remaining_backlog_after = 11, func(l): return l.slices[0].remaining_backlog_after > l.slices[0].remaining_backlog_before),
		_row("V-SLICE-19", func(): return _canonical(), func(l): l.slices[0].essence_delta = -1, func(l): return l.slices[0].essence_delta < 0),
		_row("V-SLICE-20", func(): return _canonical(), func(l): l.slices[0].mastery_delta_subunits = -1, func(l): return l.slices[0].mastery_delta_subunits < 0),
		_row("V-SLICE-21", func(): return _canonical(), func(l): l.slices[0].completed_cycles_delta = -1, func(l): return l.slices[0].completed_cycles_delta < 0),
		_row("V-SLICE-22", func(): return _canonical(), func(l): l.slices[0].remaining_backlog_before = 0, func(l): return l.slices[0].lifecycle_state == &"OVERDUE" and l.slices[0].remaining_backlog_before <= 0),
		_row("V-SLICE-23", func(): return _settled(), func(l): l.slices[0].remaining_backlog_before = 1, func(l): return l.slices[0].lifecycle_state == &"SETTLED" and l.slices[0].remaining_backlog_before != 0),
		_row("V-SLICE-24", func(): return _settled(), func(l): l.slices[0].remaining_backlog_after = 1, func(l): return l.slices[0].lifecycle_state == &"SETTLED" and l.slices[0].remaining_backlog_after != 0),
		_row("V-SLICE-25", func(): return _mode_coverage_baseline(), func(l): l.slices.append(_coverage_extra()), func(l): return 15 > l.foreground_elapsed_msec),
		_row("V-SLICE-26", func(): return _merge_pair(), func(l): l.slices[1].content_revision = l.slices[0].content_revision, func(l): return ReportLedgerValidator._merge_compatible(l.slices[0], l.slices[1]))
	])
	r.append_array([
		_row("V-CHAN-01", func(): return _canonical(), func(l): l.slices[0].channels[0] = null, func(l): return l.slices[0].channels[0] == null),
		_row("V-CHAN-02", func(): return _canonical(), func(l): l.slices[0].channels[0].channel_id = &"", func(l): return str(l.slices[0].channels[0].channel_id).is_empty()),
		_row("V-CHAN-03", func(): return _canonical(), func(l): l.slices[0].channels[0].output_item_id = &"", func(l): return str(l.slices[0].channels[0].output_item_id).is_empty()),
		_row("V-CHAN-04", func(): return _canonical(), func(l): l.slices[0].channels[1].channel_id = &"CHANNEL_A", func(l): return l.slices[0].channels[0].channel_id == l.slices[0].channels[1].channel_id),
		_row("V-CHAN-05", func(): return _canonical(), func(l): l.slices[0].channels[1].channel_id = &"A", func(l): return str(l.slices[0].channels[1].channel_id) <= str(l.slices[0].channels[0].channel_id)),
		_row("V-CHAN-06", func(): return _canonical(), func(l): l.slices[0].channels[0].start_simulation_msec = -1, func(l): return l.slices[0].channels[0].start_simulation_msec < l.slices[0].start_simulation_msec),
		_row("V-CHAN-07", func(): return _canonical(), func(l): l.slices[0].channels[0].end_simulation_msec = 0, func(l): return l.slices[0].channels[0].end_simulation_msec <= l.slices[0].channels[0].start_simulation_msec),
		_row("V-CHAN-08", func(): return _canonical(), func(l): l.slices[0].channels[0].end_simulation_msec = 11, func(l): return l.slices[0].channels[0].end_simulation_msec > l.slices[0].end_simulation_msec),
		_row("V-CHAN-09", func(): return _canonical(), func(l): l.slices[0].channels[0].progress_subunits_before = -1, func(l): return l.slices[0].channels[0].progress_subunits_before < 0),
		_row("V-CHAN-10", func(): return _canonical(), func(l): l.slices[0].channels[0].progress_subunits_before = FixedPoint.SCALE, func(l): return l.slices[0].channels[0].progress_subunits_before >= FixedPoint.SCALE),
		_row("V-CHAN-11", func(): return _canonical(), func(l): l.slices[0].channels[0].progress_subunits_after = -1, func(l): return l.slices[0].channels[0].progress_subunits_after < 0),
		_row("V-CHAN-12", func(): return _canonical(), func(l): l.slices[0].channels[0].progress_subunits_after = FixedPoint.SCALE, func(l): return l.slices[0].channels[0].progress_subunits_after >= FixedPoint.SCALE),
		_row("V-CHAN-13", func(): return _canonical(), func(l): l.slices[0].channels[0].rate_period_msec = 0, func(l): return l.slices[0].channels[0].rate_period_msec <= 0),
		_row("V-CHAN-14", func(): return _canonical(), func(l): l.slices[0].channels[0].rate_carry_units_before = -1, func(l): return l.slices[0].channels[0].rate_carry_units_before < 0),
		_row("V-CHAN-15", func(): return _canonical(), func(l): l.slices[0].channels[0].rate_carry_units_before = 1000, func(l): return l.slices[0].channels[0].rate_carry_units_before >= l.slices[0].channels[0].rate_period_msec),
		_row("V-CHAN-16", func(): return _canonical(), func(l): l.slices[0].channels[0].rate_carry_units_after = -1, func(l): return l.slices[0].channels[0].rate_carry_units_after < 0),
		_row("V-CHAN-17", func(): return _canonical(), func(l): l.slices[0].channels[0].rate_carry_units_after = 1000, func(l): return l.slices[0].channels[0].rate_carry_units_after >= l.slices[0].channels[0].rate_period_msec),
		_row("V-CHAN-18", func(): return _canonical(), func(l): l.slices[0].channels[0].total_banked_units_before = -1, func(l): return l.slices[0].channels[0].total_banked_units_before < 0),
		_row("V-CHAN-19", func(): return _canonical(), func(l): l.slices[0].channels[0].total_banked_units_after = -1, func(l): return l.slices[0].channels[0].total_banked_units_after < l.slices[0].channels[0].total_banked_units_before)
	])
	r.append_array(_event_rows())
	r.append_array(_continuity_rows())
	return r

func _event_rows() -> Array:
	return [
		_row("V-EVT-01", func(): return _canonical(), func(l): l.settlement_events[0] = null, func(l): return l.settlement_events[0] == null),
		_row("V-EVT-02", func(): return _two_settled(), func(l): l.settlement_events[1].event_sequence = 3, func(l): return l.settlement_events[1].event_sequence != 2),
		_row("V-EVT-03", func(): return _canonical(), func(l): l.settlement_events[0].event_sequence = l.next_event_sequence, func(l): return l.settlement_events[0].event_sequence >= l.next_event_sequence),
		_row("V-EVT-04", func(): return _canonical(), func(l): l.settlement_events[0].content_revision = "", func(l): return l.settlement_events[0].content_revision.is_empty()),
		_row("V-EVT-05", func(): return _canonical(), func(l): l.settlement_events[0].threshold_id = &"", func(l): return str(l.settlement_events[0].threshold_id).is_empty()),
		_row("V-EVT-06", func(): return _canonical(), func(l): l.settlement_events[0].assignment_revision = 0, func(l): return l.settlement_events[0].assignment_revision <= 0),
		_row("V-EVT-07", func(): return _canonical(), func(l): l.settlement_events[0].occurred_simulation_msec = 0, func(l): return l.settlement_events[0].occurred_simulation_msec <= l.window_start_simulation_msec),
		_row("V-EVT-08", func(): return _canonical(), func(l): l.settlement_events[0].occurred_simulation_msec = 11, func(l): return l.settlement_events[0].occurred_simulation_msec > l.ingested_through_simulation_msec),
		_row("V-EVT-09", func(): return _two_settled(), func(l): l.settlement_events[1].occurred_simulation_msec = 9, func(l): return l.settlement_events[1].occurred_simulation_msec < l.settlement_events[0].occurred_simulation_msec),
		_row("V-EVT-10", func(): return _canonical(), func(l): l.settlement_events[0].persistent_returns_total = -1, func(l): return l.settlement_events[0].persistent_returns_total < 0),
		_row("V-EVT-11", func(): return _two_settled(), func(l): l.settlement_events[1].threshold_id = l.settlement_events[0].threshold_id, func(l): return l.settlement_events[0].threshold_id == l.settlement_events[1].threshold_id),
		_row("V-EVT-12", func(): return _canonical(), func(l): l.settlement_events[0].threshold_id = &"NO_OWNER", func(l): return l.settlement_events[0].threshold_id == &"NO_OWNER"),
		_row("V-EVT-13", func(): return _canonical(), func(l): l.settlement_events[0].content_revision = "wrong", func(l): return l.settlement_events[0].content_revision != l.slices[0].content_revision),
		_row("V-EVT-14", func(): return _canonical(), func(l): l.settlement_events[0].assignment_revision = 2, func(l): return l.settlement_events[0].assignment_revision != l.slices[0].assignment_revision),
		_row("V-EVT-15", func(): return _canonical(), func(l): l.settlement_events[0].occurred_simulation_msec = 9, func(l): return l.settlement_events[0].occurred_simulation_msec != l.slices[0].end_simulation_msec),
		_row("V-EVT-16", func(): return _canonical(), func(l): l.settlement_events.clear(), func(l): return l.settlement_events.is_empty()),
		_row("V-EVT-17", func(): return _canonical(), func(l): l.next_event_sequence = 3, func(l): return l.next_event_sequence != l.settlement_events.size() + 1)
	]

func _continuity_rows() -> Array:
	return [
		_row("V-CONT-01", func(): return _two_slices(), func(l): l.slices[1].form_id = &"OTHER", func(l): return l.slices[1].form_id != l.slices[0].form_id),
		_row("V-CONT-02", func(): return _two_slices(), func(l): l.slices[1].ordered_retinue_ids.reverse(), func(l): return l.slices[1].ordered_retinue_ids != l.slices[0].ordered_retinue_ids),
		_row("V-CONT-03", func(): return _two_slices(), func(l): l.slices[1].remaining_backlog_before = 8, func(l): return l.slices[1].remaining_backlog_before != l.slices[0].remaining_backlog_after),
		_row("V-CONT-04", func(): return _settled_then_slice(), func(l): l.slices[1].lifecycle_state = &"OVERDUE", func(l): return l.slices[0].lifecycle_state == &"SETTLED" and l.slices[1].lifecycle_state == &"OVERDUE"),
		_row("V-CONT-05", func(): return _two_slices(), func(l): l.slices[1].channels.clear(), func(l): return l.slices[1].channels.is_empty()),
		_row("V-CONT-06", func(): return _two_slices(), func(l): l.slices[1].channels[0].output_item_id = &"OTHER", func(l): return l.slices[1].channels[0].output_item_id != l.slices[0].channels[0].output_item_id),
		_row("V-CONT-07", func(): return _two_slices(), func(l): l.slices[1].channels[0].rate_period_msec = 999, func(l): return l.slices[1].channels[0].rate_period_msec != l.slices[0].channels[0].rate_period_msec),
		_row("V-CONT-08", func(): return _two_slices(), func(l): l.slices[1].channels[0].progress_subunits_before = 2, func(l): return l.slices[1].channels[0].progress_subunits_before != l.slices[0].channels[0].progress_subunits_after),
		_row("V-CONT-09", func(): return _two_slices(), func(l): l.slices[1].channels[0].rate_carry_units_before = 1, func(l): return l.slices[1].channels[0].rate_carry_units_before != l.slices[0].channels[0].rate_carry_units_after),
		_row("V-CONT-10", func(): return _two_slices(), func(l): l.slices[1].channels[0].total_banked_units_before = 1, func(l): return l.slices[1].channels[0].total_banked_units_before != l.slices[0].channels[0].total_banked_units_after),
		_row("V-CONT-11", func(): return _cross_revision_settled(), func(l): l.settlement_events[1].threshold_id = l.settlement_events[0].threshold_id, func(l): return l.settlement_events[0].threshold_id == l.settlement_events[1].threshold_id and (l.settlement_events[0].assignment_revision != l.settlement_events[1].assignment_revision or l.settlement_events[0].content_revision != l.settlement_events[1].content_revision) and l.slices[1].assignment_revision == l.settlement_events[1].assignment_revision and l.slices[1].content_revision == l.settlement_events[1].content_revision)
	]

func _root_overflow() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = FixedPoint.INT64_MAX
	ledger.foreground_elapsed_msec = FixedPoint.INT64_MAX
	return ledger

func _canonical() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 10
	ledger.foreground_elapsed_msec = 10
	var slice := _slice(0, 10, 10, 0, &"THRESHOLD_A")
	slice.channels.append(_channel(&"CHANNEL_A", 0, 10, 0, 0, 0, 0))
	slice.channels.append(_channel(&"CHANNEL_B", 0, 10, 3, 4, 1, 2))
	ledger.slices.append(slice)
	ledger.settlement_events.append(_settlement(1, &"THRESHOLD_A", 10, 1, "content-r", 9))
	ledger.next_event_sequence = 2
	assert_true(ReportLedgerValidator.validate(ledger).ok, "canonical fixture validates")
	return ledger

func _slice(start: int, finish: int, before: int, after: int, threshold: StringName = &"THRESHOLD_A") -> ReportLedgerSlice:
	var slice := ReportLedgerSlice.new()
	slice.run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
	slice.content_revision = "content-r"
	slice.threshold_id = threshold
	slice.assignment_revision = 1
	slice.form_id = &"FORM_A"
	slice.writ_id = &"WRIT_A"
	slice.ordered_retinue_ids = [&"RET_A", &"RET_B"]
	slice.lifecycle_state = &"OVERDUE"
	slice.start_simulation_msec = start
	slice.end_simulation_msec = finish
	slice.returned_souls_delta = before - after
	slice.remaining_backlog_before = before
	slice.remaining_backlog_after = after
	slice.essence_delta = 2
	slice.mastery_delta_subunits = 3
	slice.completed_cycles_delta = 4
	return slice

func _channel(id: StringName, start: int, finish: int, progress_before: int, progress_after: int, carry_before: int, carry_after: int) -> ReportLedgerChannel:
	var channel := ReportLedgerChannel.new()
	channel.channel_id = id
	channel.output_item_id = &"SOUL"
	channel.start_simulation_msec = start
	channel.end_simulation_msec = finish
	channel.progress_subunits_before = progress_before
	channel.progress_subunits_after = progress_after
	channel.rate_period_msec = 1000
	channel.rate_carry_units_before = carry_before
	channel.rate_carry_units_after = carry_after
	channel.total_banked_units_before = 0
	channel.total_banked_units_after = 0
	return channel

func _settlement(sequence: int, threshold: StringName, when: int, revision: int = 1, content: String = "content-r", total: int = 0) -> ReportSettlementEvent:
	var event := ReportSettlementEvent.new()
	event.event_sequence = sequence
	event.content_revision = content
	event.threshold_id = threshold
	event.assignment_revision = revision
	event.occurred_simulation_msec = when
	event.persistent_returns_total = total
	return event

func _settled() -> ReportLedger:
	var ledger := _canonical()
	ledger.slices[0].lifecycle_state = &"SETTLED"
	ledger.slices[0].remaining_backlog_before = 0
	ledger.slices[0].remaining_backlog_after = 0
	ledger.slices[0].returned_souls_delta = 0
	ledger.settlement_events.clear()
	ledger.next_event_sequence = 1
	assert_true(ReportLedgerValidator.validate(ledger).ok, "settled fixture validates")
	return ledger

func _two_slices() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 10
	ledger.offline_elapsed_msec = 10
	var first := _slice(0, 10, 10, 9)
	first.channels.append(_channel(&"CHANNEL_A", 0, 10, 0, 1, 0, 0))
	var second := _slice(10, 20, 9, 8)
	second.run_mode = SimulationRunService.MODE_OFFLINE_FIXTURE
	second.channels.append(_channel(&"CHANNEL_A", 10, 20, 1, 2, 0, 0))
	ledger.slices = [first, second]
	assert_true(ReportLedgerValidator.validate(ledger).ok, "two-slice fixture validates")
	return ledger

func _merge_pair() -> ReportLedger:
	var ledger := _two_slices()
	ledger.slices[1].run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
	ledger.slices[1].content_revision = "content-other"
	ledger.foreground_elapsed_msec = 20
	ledger.offline_elapsed_msec = 0
	assert_true(ReportLedgerValidator.validate(ledger).ok, "near-merge pair validates")
	return ledger

func _mode_coverage_baseline() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 10
	ledger.offline_elapsed_msec = 10
	var first := _slice(0, 10, 10, 9)
	first.channels.append(_channel(&"CHANNEL_A", 0, 10, 0, 0, 0, 0))
	ledger.slices.append(first)
	assert_true(ReportLedgerValidator.validate(ledger).ok, "mode-coverage baseline validates")
	return ledger

func _coverage_extra() -> ReportLedgerSlice:
	var slice := _slice(10, 15, 9, 8)
	slice.content_revision = "content-next"
	slice.channels.append(_channel(&"CHANNEL_A", 10, 15, 0, 0, 0, 0))
	return slice

func _settled_then_slice() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 10
	ledger.offline_elapsed_msec = 10
	var first := _slice(0, 10, 0, 0)
	first.lifecycle_state = &"SETTLED"
	first.returned_souls_delta = 0
	first.channels.append(_channel(&"CHANNEL_A", 0, 10, 0, 0, 0, 0))
	var second := _slice(10, 20, 0, 0)
	second.lifecycle_state = &"SETTLED"
	second.returned_souls_delta = 0
	second.run_mode = SimulationRunService.MODE_OFFLINE_FIXTURE
	second.channels.append(_channel(&"CHANNEL_A", 10, 20, 0, 0, 0, 0))
	ledger.slices = [first, second]
	assert_true(ReportLedgerValidator.validate(ledger).ok, "settled continuity fixture validates")
	return ledger

func _two_settled() -> ReportLedger:
	var ledger := ReportLedger.create_empty(0)
	ledger.ingested_through_simulation_msec = 20
	ledger.foreground_elapsed_msec = 10
	ledger.offline_elapsed_msec = 10
	var a := _slice(0, 10, 10, 0, &"THRESHOLD_A")
	a.channels.append(_channel(&"CHANNEL_A", 0, 10, 0, 0, 0, 0))
	var b := _slice(10, 20, 10, 0, &"THRESHOLD_B")
	b.run_mode = SimulationRunService.MODE_OFFLINE_FIXTURE
	b.channels.append(_channel(&"CHANNEL_A", 10, 20, 0, 0, 0, 0))
	ledger.slices = [a, b]
	ledger.settlement_events = [_settlement(1, &"THRESHOLD_A", 10), _settlement(2, &"THRESHOLD_B", 20)]
	ledger.next_event_sequence = 3
	assert_true(ReportLedgerValidator.validate(ledger).ok, "two ordered Settlements validate")
	return ledger

func _cross_revision_settled() -> ReportLedger:
	var ledger := _two_settled()
	ledger.slices[1].assignment_revision = 2
	ledger.slices[1].content_revision = "content-revision-2"
	ledger.settlement_events[1].assignment_revision = 2
	ledger.settlement_events[1].content_revision = "content-revision-2"
	assert_true(ReportLedgerValidator.validate(ledger).ok, "cross-revision settled baseline validates")
	return ledger

func _same_string_set(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size(): return false
	for value in expected:
		if not actual.has(value): return false
	return true

func _has_unique(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value): return false
		seen[value] = true
	return true
