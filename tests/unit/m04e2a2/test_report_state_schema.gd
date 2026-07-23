extends GutTest

const EMPTY_FIXTURE := "res://tests/fixtures/saves/schema_v4_empty_cursor.json"
const POPULATED_FIXTURE := "res://tests/fixtures/saves/schema_v4_populated_report.json"
const V3_FIXTURE := "res://tests/fixtures/saves/schema_v3_m04d1_access.json"

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _read(path: String) -> Dictionary:
	return JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(path)).snapshot

func test_empty_state_and_cursor_lag_are_valid() -> void:
	var state := GameState.new(5000)
	assert_eq(state.report_state.ingested_through_simulation_msec, 5000)
	assert_eq(state.report_state.live.window_started_simulation_msec, 5000)
	assert_true(GameStateValidator.validate(state, _registry()).ok)
	assert_true(state.advance_simulation_time(1000).ok)
	assert_true(GameStateValidator.validate(state, _registry()).ok)
	state.report_state.ingested_through_simulation_msec = 7000
	assert_false(GameStateValidator.validate(state, _registry()).ok)

func test_populated_fixture_validates_and_round_trips_every_report_field() -> void:
	var snapshot := _read(POPULATED_FIXTURE)
	assert_true(SaveSchemaValidator.validate_v4(snapshot).ok)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(runtime.ok, str(runtime))
	assert_true(GameStateValidator.validate(runtime.game_state, _registry()).ok)
	var remapped := SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, runtime.save_revision, runtime.content_revision)
	assert_eq(remapped.game_state, snapshot.game_state)
	var decoded := JsonSaveCodec.new().decode(JsonSaveCodec.new().encode(remapped).bytes)
	assert_true(decoded.ok)
	assert_true(SaveSchemaValidator.validate_v4(decoded.snapshot).ok)
	var again := SaveSchemaMapper.snapshot_to_runtime(decoded.snapshot)
	assert_true(again.ok)
	assert_true(runtime.game_state.report_state.value_equals(again.game_state.report_state))

func test_deep_clone_copy_and_record_access_do_not_alias() -> void:
	var runtime := SaveSchemaMapper.snapshot_to_runtime(_read(POPULATED_FIXTURE))
	var source: GameState = runtime.game_state
	var clone := source.deep_clone()
	clone.report_state.live.committed_mode_counts[&"DEBUG"] = 0
	clone.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity.ordered_retinue_ids.append(&"RET_SOLDIER_COMPANY")
	clone.report_state.history[0].window.recent_events.clear()
	assert_false(source.report_state.live.committed_mode_counts.has(&"DEBUG"))
	assert_true(source.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity.ordered_retinue_ids.is_empty())
	assert_eq(source.report_state.history[0].window.recent_events.size(), 1)
	var replacement := GameState.new(1)
	replacement.copy_from(source)
	replacement.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].inventory_gains_by_item_id[&"SOUL_CALLING_SOLDIER"] = 99
	assert_eq(source.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].inventory_gains_by_item_id[&"SOUL_CALLING_SOLDIER"], 1)
	var record_window := source.report_state.history[0].window
	record_window.recent_events.clear()
	assert_eq(source.report_state.history[0].window.recent_events.size(), 1)

func test_runtime_validator_rejects_cross_field_and_content_malformed_state() -> void:
	var runtime := SaveSchemaMapper.snapshot_to_runtime(_read(POPULATED_FIXTURE))
	var state: GameState = runtime.game_state
	state.report_state.live.window_ended_simulation_msec = 4000
	assert_false(ReportStateValidator.validate(state.report_state, state.simulation_time_msec, _registry()).ok)
	state = SaveSchemaMapper.snapshot_to_runtime(_read(POPULATED_FIXTURE)).game_state
	state.report_state.live.attribution_slices["bad"] = state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].deep_clone()
	assert_false(ReportStateValidator.validate(state.report_state, state.simulation_time_msec, _registry()).ok)
	state = SaveSchemaMapper.snapshot_to_runtime(_read(POPULATED_FIXTURE)).game_state
	var bad_window := state.report_state.history[0].window
	bad_window.attribution_slices["THR_GLOAMWOOD|7|SETTLED"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units_end = 3
	state.report_state.history[0] = ReportRecord.new(4, &"SYSTEM_BOUNDARY", 3000, bad_window)
	assert_false(ReportStateValidator.validate(state.report_state, state.simulation_time_msec, _registry()).ok)

func test_schema_v4_exact_keys_and_canonical_integer_mutations_reject() -> void:
	var snapshot := _read(POPULATED_FIXTURE)
	assert_eq(SaveSchemaValidator.validate_current(snapshot).code, SaveSchemaValidator.OK)
	var missing := snapshot.duplicate(true)
	missing.game_state.report_state.live.erase("omitted_event_count")
	assert_false(SaveSchemaValidator.validate_v4(missing).ok)
	var extra := snapshot.duplicate(true)
	extra.game_state.report_state.live.extra = "x"
	assert_false(SaveSchemaValidator.validate_v4(extra).ok)
	for value in [1, " 1", "+1", "01", "1.0", "1e0", "9223372036854775808"]:
		var malformed := snapshot.duplicate(true)
		malformed.game_state.report_state.next_event_sequence = value
		assert_false(SaveSchemaValidator.validate_v4(malformed).ok, str(value))

func test_schema_v3_to_v4_is_prospective_and_sequential() -> void:
	var v3 := _read(V3_FIXTURE)
	var before := v3.duplicate(true)
	var migrated := SaveMigrationRegistry.new().migrate(v3, SaveEnvelope.SCHEMA_VERSION_V3, SaveEnvelope.SCHEMA_VERSION_V4)
	assert_true(migrated.ok, str(migrated))
	assert_eq(migrated.snapshot.schema_version, "4")
	assert_eq(migrated.snapshot.game_state.report_state.ingested_through_simulation_msec, before.game_state.simulation_time_msec)
	assert_eq(migrated.snapshot.game_state.report_state.history, [])
	assert_eq(migrated.snapshot.game_state.report_state.live.ingested_run_count, "0")
	assert_eq(migrated.snapshot.game_state.thresholds, before.game_state.thresholds)
	assert_eq(v3, before)
	var sequential := SaveMigrationRegistry.new().migrate(_read("res://tests/fixtures/saves/schema_v1_foundation.json"), SaveEnvelope.SCHEMA_VERSION_V1, SaveEnvelope.SCHEMA_VERSION_V4)
	assert_true(sequential.ok, str(sequential))
	assert_eq(sequential.snapshot.schema_version, "4")
	assert_eq(sequential.snapshot.game_state.report_state.history, [])
	assert_eq(sequential.snapshot.game_state.report_state.ingested_through_simulation_msec, sequential.snapshot.game_state.simulation_time_msec)
