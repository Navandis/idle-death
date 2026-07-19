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
	var snap := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 7, ContentRegistry.CURRENT_REVISION)
	assert_eq(snap.schema_version, "4")
	var loaded := SaveSchemaMapper.snapshot_to_runtime(snap)
	assert_true(loaded.ok); assert_eq(loaded.game_state.report_state.history.size(), 1); assert_eq(ReportService.new().get_report_record(loaded.game_state, 1).totals.returned_souls_delta, 69)
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
