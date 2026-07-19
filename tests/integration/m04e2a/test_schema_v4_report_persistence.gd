extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
func _state() -> GameState:
	var state := GameState.new(0); state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var t := GameState.ThresholdState.new(); t.knowledge_state = &"CHARTED"; t.availability_state = &"AVAILABLE"; t.lifecycle_state = &"OVERDUE"; t.remaining_backlog = 1000000; state.thresholds[&"THR_GLOAMWOOD"] = t
	var r := GameState.ReapingState.new(); r.threshold_id = &"THR_GLOAMWOOD"; r.is_active = true; r.form_id = &"FORM_MAN_AT_ARMS"; r.writ_id = &"WRIT_STANDARD"; r.assignment_revision = 1; state.reapings[&"THR_GLOAMWOOD"] = r
	var access := OutputAccessService.new(_registry()); assert_true(access.unlock_output_item(state, &"SOUL_CALLING_SOLDIER").success); assert_true(access.reconcile_available_sources(state).success)
	return state
func test_v3_migrates_empty_report_and_v4_round_trips() -> void:
	var v3: Dictionary = SaveMigrationRegistry.new().migrate(_read_json("res://tests/fixtures/saves/schema_v2_m04a_representative.json"), 2, 3).snapshot
	v3.game_state.simulation_time_msec = "12345"
	var migrated := SaveMigrationRegistry.new().migrate(v3, 3, 4)
	assert_true(migrated.ok); assert_eq(migrated.snapshot.schema_version, "4"); assert_eq(migrated.snapshot.game_state.report_state.report_cursor_msec, "12345"); assert_eq(migrated.snapshot.game_state.report_state.history, [])
	var runtime := SaveSchemaMapper.snapshot_to_runtime(migrated.snapshot)
	assert_true(runtime.ok); assert_eq(runtime.game_state.report_state.report_cursor_msec, 12345)
func test_report_live_and_archive_round_trip() -> void:
	var state := _state()
	var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED); assert_true(run.success)
	assert_true(ReportService.new().ingest_committed_run(state, run).success)
	assert_true(ReportService.new().snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).success)
	var original_report := ReportService.new().get_report_record(state, 1)
	assert_lt(original_report.totals.backlog_delta, 0)
	var snap := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 7, ContentRegistry.CURRENT_REVISION)
	assert_eq(snap.schema_version, "4")
	var loaded := SaveSchemaMapper.snapshot_to_runtime(snap)
	var loaded_report := ReportService.new().get_report_record(loaded.game_state, 1)
	assert_true(loaded.ok); assert_eq(loaded.game_state.report_state.history.size(), 1); assert_eq(loaded_report.totals.returned_souls_delta, 69); assert_eq(loaded_report.totals.backlog_delta, original_report.totals.backlog_delta)
func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ); return JSON.parse_string(file.get_as_text())

func test_schema_v4_preserves_unlocked_output_ids_on_load() -> void:
	var state := _state()
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 9, ContentRegistry.CURRENT_REVISION)
	var validation := SaveSchemaValidator.validate_current(snapshot)
	assert_true(validation.ok)
	assert_eq(validation.unlocked_output_item_ids, ["SOUL_CALLING_SOLDIER"])
	var loaded := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(loaded.ok)
	assert_eq(loaded.game_state.progression.unlocked_output_item_ids, [&"SOUL_CALLING_SOLDIER"])
	assert_true(GameStateValidator.validate(loaded.game_state, _registry()).ok)

func test_schema_v4_rejects_malformed_event_details_before_runtime_mapping() -> void:
	var state := _state()
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 10, ContentRegistry.CURRENT_REVISION)
	snapshot.game_state.report_state.live.event_details.append({"event_type": "THRESHOLD_SETTLED"})
	var validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(validation.ok)
	assert_eq(validation.code, SaveSchemaValidator.ERR_KEY_SET)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_false(runtime.ok)
	assert_eq(runtime.code, SaveSchemaValidator.ERR_KEY_SET)

func test_schema_v4_rejects_malformed_slice_maps_and_channel_summaries() -> void:
	var state := _state()
	var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED); assert_true(run.success)
	assert_true(ReportService.new().ingest_committed_run(state, run).success)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 11, ContentRegistry.CURRENT_REVISION)
	var slice_key = snapshot.game_state.report_state.live.slices.keys()[0]
	snapshot.game_state.report_state.live.slices[slice_key].inventory_gains.RES_ESSENCE = 7
	assert_false(SaveSchemaValidator.validate_current(snapshot).ok)
	snapshot = SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 11, ContentRegistry.CURRENT_REVISION)
	slice_key = snapshot.game_state.report_state.live.slices.keys()[0]
	snapshot.game_state.report_state.live.slices[slice_key].channel_summaries.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.erase("output_item_id")
	assert_eq(SaveSchemaValidator.validate_current(snapshot).code, SaveSchemaValidator.ERR_KEY_SET)
	snapshot = SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 11, ContentRegistry.CURRENT_REVISION)
	slice_key = snapshot.game_state.report_state.live.slices.keys()[0]
	snapshot.game_state.report_state.live.slices[slice_key].retinue_ids.append(7)
	assert_eq(SaveSchemaValidator.validate_current(snapshot).code, SaveSchemaValidator.ERR_TYPE)

func test_schema_v4_rejects_report_cursor_after_simulation_time() -> void:
	var state := _state()
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 12, ContentRegistry.CURRENT_REVISION)
	snapshot.game_state.simulation_time_msec = "1000"
	snapshot.game_state.report_state.report_cursor_msec = "2000"
	var validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(validation.ok)
	assert_eq(validation.code, SaveSchemaValidator.ERR_CROSS_FIELD)
	assert_eq(validation.field_path, "game_state.report_state.report_cursor_msec")


func test_schema_v4_rejects_zero_report_sequences() -> void:
	for sequence_key in ["next_report_sequence", "next_event_sequence"]:
		var snapshot := SaveSchemaMapper.runtime_to_snapshot(_state(), TimeAuthorityState.new(), 13, ContentRegistry.CURRENT_REVISION)
		snapshot.game_state.report_state[sequence_key] = "0"
		var validation := SaveSchemaValidator.validate_current(snapshot)
		assert_false(validation.ok, sequence_key)
		assert_eq(validation.code, SaveSchemaValidator.ERR_RANGE, sequence_key)
		assert_eq(validation.field_path, "game_state.report_state.%s" % sequence_key, sequence_key)
		var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
		assert_false(runtime.ok, sequence_key)
		assert_eq(runtime.code, SaveSchemaValidator.ERR_RANGE, sequence_key)


func test_schema_v4_rejects_negative_non_signed_slice_counters() -> void:
	var state := _state()
	var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(run.success)
	assert_true(ReportService.new().ingest_committed_run(state, run).success)
	for counter_key in ["assignment_revision", "start_simulation_msec", "end_simulation_msec", "elapsed_msec", "returned_souls_delta", "completed_cycles_delta"]:
		var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 14, ContentRegistry.CURRENT_REVISION)
		var slice_key = snapshot.game_state.report_state.live.slices.keys()[0]
		snapshot.game_state.report_state.live.slices[slice_key][counter_key] = "-1"
		var validation := SaveSchemaValidator.validate_current(snapshot)
		assert_false(validation.ok, counter_key)
		assert_eq(validation.field_path, "game_state.report_state.live.slices.%s.%s" % [slice_key, counter_key], counter_key)
	var valid_signed_backlog := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 14, ContentRegistry.CURRENT_REVISION)
	assert_true(SaveSchemaValidator.validate_current(valid_signed_backlog).ok)


func test_schema_v4_rejects_oversized_report_history_and_event_details() -> void:
	var state := _state()
	var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(run.success)
	assert_true(ReportService.new().ingest_committed_run(state, run).success)
	assert_true(ReportService.new().snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).success)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 15, ContentRegistry.CURRENT_REVISION)
	while snapshot.game_state.report_state.history.size() <= ReportState.MAX_HISTORY_RECORDS:
		snapshot.game_state.report_state.history.append(snapshot.game_state.report_state.history[0].duplicate(true))
	var history_validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(history_validation.ok)
	assert_eq(history_validation.field_path, "game_state.report_state.history")
	snapshot = SaveSchemaMapper.runtime_to_snapshot(_state(), TimeAuthorityState.new(), 15, ContentRegistry.CURRENT_REVISION)
	for i in range(ReportState.MAX_EVENT_DETAILS + 1):
		snapshot.game_state.report_state.live.event_details.append({"event_sequence": SaveInt64.format(i + 1), "event_type": "TEST_EVENT", "occurred_simulation_msec": "0", "priority": "0", "source_id": "TEST_SOURCE", "subject_id": "THR_GLOAMWOOD"})
	var event_validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(event_validation.ok)
	assert_eq(event_validation.field_path, "game_state.report_state.live.event_details")
