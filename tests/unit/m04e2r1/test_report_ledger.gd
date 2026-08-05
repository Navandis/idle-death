extends GutTest

func test_factory_clone_equality_and_validator_grammar() -> void:
	assert_null(ReportLedger.create_empty(-1))
	var ledger := ReportLedger.create_empty(25)
	assert_true(ReportLedgerValidator.validate(ledger).ok)
	assert_eq(ReportLedgerValidator.validate(ledger).keys().size(), 3)
	var copy := ledger.deep_clone()
	assert_ne(copy, ledger)
	assert_true(copy.value_equals(ledger))
	copy.next_event_sequence = 0
	var invalid := ReportLedgerValidator.validate(copy)
	assert_false(invalid.ok)
	assert_eq(invalid.code, ReportLedgerValidator.FAILURE)
	assert_ne(invalid.details, "")

func test_validator_rejects_nonmaximal_slices_and_channel_aliases() -> void:
	var ledger := ReportLedger.create_empty(0)
	ledger.foreground_elapsed_msec = 20
	ledger.ingested_through_simulation_msec = 20
	ledger.slices.append(_slice(0, 10, 10, 9))
	ledger.slices.append(_slice(10, 20, 9, 8))
	assert_false(ReportLedgerValidator.validate(ledger).ok)
	var detached := ledger.slices[0].deep_clone()
	detached.channels[0].total_banked_units_after = 99
	assert_ne(detached.channels[0].total_banked_units_after, ledger.slices[0].channels[0].total_banked_units_after)

func _slice(start: int, finish: int, before: int, after: int) -> ReportLedgerSlice:
	var slice := ReportLedgerSlice.new()
	slice.run_mode = SimulationRunService.MODE_FOREGROUND_SUPPLIED
	slice.content_revision = ContentRegistry.CURRENT_REVISION
	slice.threshold_id = &"THR_TEST"
	slice.assignment_revision = 1
	slice.form_id = &"FORM_TEST"
	slice.writ_id = &"WRIT_TEST"
	slice.lifecycle_state = &"OVERDUE"
	slice.start_simulation_msec = start
	slice.end_simulation_msec = finish
	slice.returned_souls_delta = before - after
	slice.remaining_backlog_before = before
	slice.remaining_backlog_after = after
	var channel := ReportLedgerChannel.new()
	channel.channel_id = &"CHANNEL_TEST"
	channel.output_item_id = &"SOUL_TEST"
	channel.start_simulation_msec = start
	channel.end_simulation_msec = finish
	channel.rate_period_msec = 1000
	slice.channels.append(channel)
	return slice
