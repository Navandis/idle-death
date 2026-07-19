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
	snapshot.game_state.report_state.live.slices[slice_key].channel_summaries.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.latest_progress_subunits_after = "-1"
	assert_false(SaveSchemaValidator.validate_current(snapshot).ok)
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

func test_save_runtime_rejects_malformed_runtime_report_state_before_mapping() -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04e2a_invalid_runtime", "save")
	var state := _state()
	state.report_state = null
	var direct := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 16, ContentRegistry.CURRENT_REVISION)
	assert_false(direct.ok)
	assert_eq(direct.code, SaveSchemaMapper.ERR_REPORT_RUNTIME)
	assert_eq(direct.field_path, "game_state.report_state")
	var saved := SaveService.new(storage, files).save_runtime(state, TimeAuthorityState.new(), 16, ContentRegistry.CURRENT_REVISION)
	assert_false(saved.ok)
	assert_eq(saved.code, SaveSchemaMapper.ERR_REPORT_RUNTIME)
	assert_false(storage.exists(files.primary_path))
	state = _state()
	state.report_state.live = null
	var nested := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 17, ContentRegistry.CURRENT_REVISION)
	assert_false(nested.ok)
	assert_eq(nested.field_path, "game_state.report_state.live")

func test_schema_v4_rejects_unknown_snapshot_reason() -> void:
	var state := _state()
	var run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(run.success)
	assert_true(ReportService.new().ingest_committed_run(state, run).success)
	assert_true(ReportService.new().snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).success)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 18, ContentRegistry.CURRENT_REVISION)
	snapshot.game_state.report_state.history[0].snapshot_reason = "STALE_UNKNOWN_REASON"
	var validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(validation.ok)
	assert_eq(validation.code, SaveSchemaValidator.ERR_RANGE)
	assert_eq(validation.field_path, "game_state.report_state.history.0.snapshot_reason")
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_false(runtime.ok)
	assert_eq(runtime.code, SaveSchemaValidator.ERR_RANGE)

func _populated_v4_snapshot(save_revision := 30) -> Dictionary:
	var state := _state()
	var service := ReportService.new()
	var first_run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_FOREGROUND_SUPPLIED)
	assert_true(first_run.success, first_run.developer_details)
	assert_true(service.ingest_committed_run(state, first_run).success)
	assert_true(service.snapshot_live(state, 1, ReportState.REASON_MANUAL_REVIEW).success)
	var second_run := SimulationRunService.new(_registry()).run_committed(state, 60000, SimulationRunService.MODE_DEBUG)
	assert_true(second_run.success, second_run.developer_details)
	assert_true(service.ingest_committed_run(state, second_run).success)
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), save_revision, ContentRegistry.CURRENT_REVISION)

func _assert_v4_mutation_rejected_before_mapping(case_name: String, case_index: int, mutator: Callable) -> void:
	var snapshot := _populated_v4_snapshot(40 + case_index)
	mutator.call(snapshot)
	var encoded := JsonSaveCodec.new().encode(snapshot)
	var source_bytes: PackedByteArray = encoded.bytes if encoded.ok else JSON.stringify(snapshot).to_utf8_buffer()
	var validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(validation.ok, case_name)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_false(runtime.ok, case_name)
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04e2a_matrix_%d" % case_index, "save")
	assert_true(storage.write_bytes(files.primary_path, source_bytes).ok, case_name)
	var loaded := SaveService.new(storage, files).load_runtime()
	assert_false(loaded.ok, case_name)
	assert_true(storage.exists(files.primary_path), case_name)
	assert_eq(storage.files[files.primary_path], source_bytes, case_name)

func test_schema_v4_full_report_mutation_matrix_rejects_before_mapping() -> void:
	var cases := [
		{"name": "missing_key", "mutate": func(s): s.game_state.report_state.erase("live")},
		{"name": "extra_key", "mutate": func(s): s.game_state.report_state["extra"] = "bad"},
		{"name": "wrong_primitive_type", "mutate": func(s): s.game_state.report_state.live.run_count = true},
		{"name": "null_nested", "mutate": func(s): s.game_state.report_state.live = null},
		{"name": "empty_id", "mutate": func(s): s.game_state.report_state.live.slices[s.game_state.report_state.live.slices.keys()[0]].threshold_id = ""},
		{"name": "negative_unsigned", "mutate": func(s): s.game_state.report_state.live.run_count = "-1"},
		{"name": "zero_positive_sequence", "mutate": func(s): s.game_state.report_state.history[0].report_sequence = "0"},
		{"name": "overflow_integer_string", "mutate": func(s): s.game_state.report_state.next_report_sequence = "9223372036854775808"},
		{"name": "unknown_reason", "mutate": func(s): s.game_state.report_state.history[0].snapshot_reason = "UNKNOWN_REASON"},
		{"name": "unknown_mode", "mutate": func(s): s.game_state.report_state.live.mode_counts.BAD_MODE = "1"},
		{"name": "non_string_retinue_id", "mutate": func(s): s.game_state.report_state.live.slices[s.game_state.report_state.live.slices.keys()[0]].retinue_ids.append(7)},
		{"name": "malformed_map_value", "mutate": func(s): s.game_state.report_state.live.slices[s.game_state.report_state.live.slices.keys()[0]].inventory_gains.RES_ESSENCE = "-1"},
		{"name": "malformed_channel_summary", "mutate": func(s): s.game_state.report_state.live.slices[s.game_state.report_state.live.slices.keys()[0]].channel_summaries.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.channel_id = "CHANNEL_OTHER"},
		{"name": "malformed_event_detail", "mutate": func(s): s.game_state.report_state.live.event_details.append({"event_type": "TEST_EVENT"})},
		{"name": "oversized_history", "mutate": func(s): while s.game_state.report_state.history.size() <= ReportState.MAX_HISTORY_RECORDS: s.game_state.report_state.history.append(s.game_state.report_state.history[0].duplicate(true))},
		{"name": "oversized_event_details", "mutate": func(s): for i in range(ReportState.MAX_EVENT_DETAILS + 1): s.game_state.report_state.live.event_details.append({"event_sequence": SaveInt64.format(i + 1), "event_type": "TEST_EVENT", "occurred_simulation_msec": "0", "priority": "0", "source_id": "TEST_SOURCE", "subject_id": "THR_GLOAMWOOD"})},
		{"name": "cursor_beyond_simulation", "mutate": func(s): s.game_state.report_state.report_cursor_msec = SaveInt64.format(SaveInt64.parse(s.game_state.simulation_time_msec, false, "").value + 1)},
		{"name": "unsorted_duplicate_identity", "mutate": func(s): s.game_state.report_state.live.slices[s.game_state.report_state.live.slices.keys()[0]].retinue_ids = ["RET_Z", "RET_A"]},
	]
	for i in range(cases.size()):
		_assert_v4_mutation_rejected_before_mapping(cases[i].name, i, cases[i].mutate)

func test_schema_v4_writer_validate_reader_writer_canonical_equality() -> void:
	var snapshot := _populated_v4_snapshot(70)
	assert_true(SaveSchemaValidator.validate_current(snapshot).ok)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(runtime.ok)
	var rewritten := SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, runtime.save_revision, runtime.content_revision)
	assert_true(SaveSchemaValidator.validate_current(rewritten).ok)
	assert_eq(JSON.stringify(rewritten), JSON.stringify(snapshot))

func test_schema_v4_rejects_stale_next_sequences_after_retained_records() -> void:
	var snapshot := _populated_v4_snapshot(80)
	snapshot.game_state.report_state.next_report_sequence = "1"
	var report_validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(report_validation.ok)
	assert_eq(report_validation.field_path, "game_state.report_state.next_report_sequence")
	assert_false(SaveSchemaMapper.snapshot_to_runtime(snapshot).ok)

	snapshot = _populated_v4_snapshot(81)
	snapshot.game_state.report_state.history[0].window.event_details.append({
		"event_sequence": "1",
		"event_type": "TEST_EVENT",
		"occurred_simulation_msec": snapshot.game_state.report_state.history[0].window.end_simulation_msec,
		"priority": "0",
		"source_id": "SIMULATION_ENGINE",
		"subject_id": "THR_GLOAMWOOD",
	})
	snapshot.game_state.report_state.next_event_sequence = "1"
	var event_validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(event_validation.ok)
	assert_eq(event_validation.field_path, "game_state.report_state.next_event_sequence")
	assert_false(SaveSchemaMapper.snapshot_to_runtime(snapshot).ok)

func test_schema_v4_rejects_extra_attribution_slice_keys() -> void:
	var snapshot := _populated_v4_snapshot(82)
	var slice_key = snapshot.game_state.report_state.live.slices.keys()[0]
	snapshot.game_state.report_state.live.slices[slice_key].unexpected_report_field = "bad"
	var validation := SaveSchemaValidator.validate_current(snapshot)
	assert_false(validation.ok)
	assert_eq(validation.code, SaveSchemaValidator.ERR_KEY_SET)
	assert_eq(validation.field_path, "game_state.report_state.live.slices.%s" % slice_key)
	assert_false(SaveSchemaMapper.snapshot_to_runtime(snapshot).ok)
