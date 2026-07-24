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

func test_authoritative_report_field_inventory_propagates_end_to_end() -> void:
	var expected := _read(POPULATED_FIXTURE)
	var runtime: Dictionary = SaveSchemaMapper.snapshot_to_runtime(expected)
	var clone: GameState = runtime.game_state.deep_clone()
	var copied := GameState.new()
	copied.copy_from(runtime.game_state)
	assert_true(runtime.game_state.report_state.value_equals(clone.report_state))
	assert_true(runtime.game_state.report_state.value_equals(copied.report_state))
	var mapped := SaveSchemaMapper.runtime_to_snapshot(copied, runtime.time_authority_state, runtime.save_revision, runtime.content_revision)
	assert_true(mapped.has("game_state"))
	_assert_report_wire_inventory(expected.game_state.report_state, mapped.game_state.report_state)
	var decoded := JsonSaveCodec.new().decode(JsonSaveCodec.new().encode(mapped).bytes)
	assert_true(decoded.ok)
	var remapped := SaveSchemaMapper.snapshot_to_runtime(decoded.snapshot)
	assert_true(remapped.ok)
	assert_true(GameStateValidator.validate(remapped.game_state, _registry()).ok)
	assert_true(runtime.game_state.report_state.value_equals(remapped.game_state.report_state))

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

func test_runtime_validator_rejects_malformed_record_window_before_clone() -> void:
	var runtime := _report_runtime()
	var record: ReportRecord = runtime.report_state.history[0]
	record._window = null
	var result := ReportStateValidator.validate(runtime.report_state, runtime.simulation_time_msec, _registry())
	assert_false(result.ok)
	assert_eq(result.field_path, "report_state.history.0.window")

func test_runtime_validator_rejects_disabled_content_references() -> void:
	for disabled_id in ["FORM_SCRIBE", "WRIT_EMERGENCY_FIRST_RETURN", "RET_SOLDIER_COMPANY", "THR_GLOAMWOOD", "SOUL_CALLING_SOLDIER", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]:
		var runtime := _report_runtime()
		var registry := _registry()
		# The registry is the normalized content boundary. Toggling one copied
		# record lets this test exercise disabled-ID rejection without mutating
		# authored Resources or introducing a test-only content catalog.
		registry._records[disabled_id]["enabled"] = false
		if disabled_id == "SOUL_CALLING_SOLDIER":
			runtime.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].inventory_gains_by_item_id.clear()
		var result := ReportStateValidator.validate(runtime.report_state, runtime.simulation_time_msec, registry)
		assert_false(result.ok, disabled_id)

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

func test_global_report_and_event_sequence_matrix() -> void:
	var duplicate_report := _report_runtime()
	duplicate_report.report_state.history.append(duplicate_report.report_state.history[0].deep_clone())
	_assert_runtime_failure(duplicate_report, "report_state.history.1.report_sequence", "duplicate history report sequence")
	var descending_report := _report_runtime()
	var first_window := descending_report.report_state.history[0].window
	var second_window := ReportAccumulatorState.new(4000)
	descending_report.report_state.history = [ReportRecord.new(5, &"SYSTEM_BOUNDARY", 3000, first_window), ReportRecord.new(6, &"SYSTEM_BOUNDARY", 2000, second_window)]
	descending_report.report_state.next_report_sequence = 7
	_assert_runtime_failure(descending_report, "report_state.history.1.snapshot_simulation_msec", "descending history snapshot")
	var next_report_low := _report_runtime()
	next_report_low.report_state.next_report_sequence = 4
	_assert_runtime_failure(next_report_low, "report_state.next_report_sequence", "next report sequence bound")
	var duplicate_event_within := _report_runtime()
	duplicate_event_within.report_state.live.recent_events.append(duplicate_event_within.report_state.live.recent_events[0].deep_clone())
	_assert_runtime_failure(duplicate_event_within, "report_state.live.recent_events.1.event_sequence", "duplicate event in one window")
	var duplicate_event_across := _report_runtime()
	duplicate_event_across.report_state.live.recent_events[0] = ReportEventRecord.new(3, &"THRESHOLD_SETTLED", 4500, 200, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE")
	_assert_runtime_failure(duplicate_event_across, "report_state.live.recent_events.0.event_sequence", "duplicate event across windows")
	var descending_event := _report_runtime()
	descending_event.report_state.live.recent_events[0] = ReportEventRecord.new(2, &"THRESHOLD_SETTLED", 4500, 200, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE")
	_assert_runtime_failure(descending_event, "report_state.live.recent_events.0.event_sequence", "descending cross-window event")
	var next_event_low := _report_runtime()
	next_event_low.report_state.next_event_sequence = 4
	_assert_runtime_failure(next_event_low, "report_state.next_event_sequence", "next event sequence bound")
	var omitted_event_undercount := _report_runtime()
	omitted_event_undercount.report_state.live.omitted_event_count = 2
	_assert_runtime_failure(omitted_event_undercount, "report_state.live.event_type_counts", "omitted event count undercount")
	var omitted_event_overcount := _report_runtime()
	omitted_event_overcount.report_state.live.omitted_event_count = 0
	_assert_runtime_failure(omitted_event_overcount, "report_state.live.event_type_counts", "omitted event count overcount")
	var overlapping_live_window := _report_runtime()
	overlapping_live_window.report_state.live.window_started_simulation_msec = 2500
	_assert_runtime_failure(overlapping_live_window, "report_state.live.window_started_simulation_msec", "live window overlaps history")
	var overlapping_history_window := _report_runtime()
	var overlap_window := ReportAccumulatorState.new(3500)
	overlap_window.window_started_simulation_msec = 2500
	overlap_window.ingested_run_count = 1
	overlap_window.committed_mode_counts[&"FOREGROUND_SUPPLIED"] = 1
	overlapping_history_window.report_state.history.append(ReportRecord.new(5, &"SYSTEM_BOUNDARY", 3500, overlap_window))
	overlapping_history_window.report_state.next_report_sequence = 6
	_assert_runtime_failure(overlapping_history_window, "report_state.history.1.window.window_started_simulation_msec", "history window overlaps prior record")
	var maximum_empty := GameState.new(0)
	maximum_empty.report_state.next_report_sequence = FixedPoint.INT64_MAX
	maximum_empty.report_state.next_event_sequence = FixedPoint.INT64_MAX
	assert_true(GameStateValidator.validate(maximum_empty, _registry()).ok)

func test_parent_child_temporal_containment_matrix() -> void:
	var before_parent := _report_runtime()
	var before_slice: ReportAttributionSlice = before_parent.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"]
	before_slice.window_started_simulation_msec = 2999
	_assert_runtime_failure(before_parent, "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.window", "slice starts before parent")
	var after_parent := _report_runtime()
	after_parent.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].window_ended_simulation_msec = 5001
	_assert_runtime_failure(after_parent, "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.window", "slice ends after parent")
	var elapsed_mismatch := _report_runtime()
	elapsed_mismatch.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].elapsed_msec = 999
	_assert_runtime_failure(elapsed_mismatch, "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.elapsed_msec", "slice elapsed mismatch")
	var channel_too_long := _report_runtime()
	channel_too_long.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].elapsed_msec = 1001
	_assert_runtime_failure(channel_too_long, "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.channel_summaries_by_channel_id.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.elapsed_msec", "channel exceeds slice")
	var empty_contradiction := GameState.new(5000)
	empty_contradiction.report_state.live.window_started_simulation_msec = 4999
	_assert_runtime_failure(empty_contradiction, "report_state.live.window", "empty live contradiction")
	var overflow_adjacent := GameState.new(FixedPoint.INT64_MAX)
	overflow_adjacent.report_state.live.window_started_simulation_msec = FixedPoint.INT64_MAX - 1
	overflow_adjacent.report_state.live.window_ended_simulation_msec = FixedPoint.INT64_MAX
	var overflow_slice := ReportAttributionSlice.new(&"THR_GLOAMWOOD", 1, &"OVERDUE", ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_EMERGENCY_FIRST_RETURN"), FixedPoint.INT64_MAX - 1, FixedPoint.INT64_MAX, FixedPoint.INT64_MAX)
	overflow_adjacent.report_state.live.attribution_slices[overflow_slice.canonical_identity_key()] = overflow_slice
	_assert_runtime_failure(overflow_adjacent, "report_state.live.attribution_slices.THR_GLOAMWOOD|1|OVERDUE.elapsed_msec", "overflow-safe difference")

func test_immutable_value_objects_and_alias_families() -> void:
	var retained_retinues: Array[StringName] = []
	var identity := ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_EMERGENCY_FIRST_RETURN", retained_retinues)
	retained_retinues.append(&"RET_SOLDIER_COMPANY")
	assert_true(identity.ordered_retinue_ids.is_empty())
	var exposed_retinues := identity.ordered_retinue_ids
	exposed_retinues.append(&"RET_SOLDIER_COMPANY")
	assert_true(identity.ordered_retinue_ids.is_empty())
	var event := ReportEventRecord.new(1, &"THRESHOLD_SETTLED", 10, 200, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE")
	var event_copy := event.deep_clone()
	assert_true(event.value_equals(event_copy))
	var source := _report_runtime()
	var clone := source.deep_clone()
	clone.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units_end = 99
	clone.report_state.history[0].window.attribution_slices["THR_GLOAMWOOD|7|SETTLED"].inventory_gains_by_item_id[&"SOUL_CALLING_SOLDIER"] = 99
	assert_eq(source.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].total_banked_units_end, 6)
	assert_eq(source.report_state.history[0].window.attribution_slices["THR_GLOAMWOOD|7|SETTLED"].inventory_gains_by_item_id[&"SOUL_CALLING_SOLDIER"], 1)
	var copied := GameState.new()
	copied.copy_from(source)
	copied.report_state.history[0].window.recent_events.clear()
	assert_eq(source.report_state.history[0].window.recent_events.size(), 1)
	var record_window := source.report_state.history[0].window
	record_window.recent_events.clear()
	assert_eq(source.report_state.history[0].window.recent_events.size(), 1)
	var independent_a := ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_EMERGENCY_FIRST_RETURN", [])
	var independent_b := ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_EMERGENCY_FIRST_RETURN", [])
	assert_true(independent_a.value_equals(independent_b))

func test_equal_output_and_a_b_a_identity_order() -> void:
	var a := ReportLoadoutIdentity.new(&"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", [&"RET_SOLDIER_COMPANY", &"RET_SOLDIER_COMPANY_2"])
	var b := ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_STANDARD", [&"RET_SOLDIER_COMPANY_2", &"RET_SOLDIER_COMPANY"])
	var a_again := a.deep_clone()
	assert_false(a.identity_key() == b.identity_key())
	assert_eq(a.ordered_retinue_ids, [&"RET_SOLDIER_COMPANY", &"RET_SOLDIER_COMPANY_2"])
	assert_eq(b.ordered_retinue_ids, [&"RET_SOLDIER_COMPANY_2", &"RET_SOLDIER_COMPANY"])
	assert_true(a.value_equals(a_again))

func test_runtime_malformed_reference_and_domain_matrix() -> void:
	var cases := ["null_live", "wrong_history_child", "negative_cursor", "invalid_mode", "mode_sum", "slice_key_alias", "invalid_threshold", "invalid_form", "invalid_writ", "invalid_retinue", "duplicate_retinue", "invalid_item", "invalid_mastery_form", "invalid_channel", "invalid_output", "invalid_lifecycle", "invalid_event_type", "invalid_priority", "invalid_event_subject", "invalid_event_source", "event_outside_window", "event_time_order", "history_limit"]
	for case_name in cases:
		var state := _report_runtime()
		_apply_runtime_case(state, case_name)
		var result := GameStateValidator.validate(state, _registry())
		assert_false(result.ok, case_name)
		assert_true(result.has("code") and result.has("field_path"), case_name)

func test_runtime_malformed_cases_do_not_mutate_source() -> void:
	var source := _report_runtime()
	var before: Dictionary = SaveSchemaMapper.runtime_to_snapshot(source, TimeAuthorityState.new(), 32, ContentRegistry.CURRENT_REVISION).game_state
	for case_name in ["duplicate_report", "duplicate_event", "slice_after_parent", "channel_too_long", "invalid_content"]:
		var candidate := source.deep_clone()
		_apply_runtime_case(candidate, case_name)
		assert_false(GameStateValidator.validate(candidate, _registry()).ok, case_name)
		var after: Dictionary = SaveSchemaMapper.runtime_to_snapshot(source, TimeAuthorityState.new(), 32, ContentRegistry.CURRENT_REVISION).game_state
		assert_eq(after, before, case_name)

func test_primitive_report_collection_type_matrix_rejects_before_runtime_exposure() -> void:
	var snapshot := _read(POPULATED_FIXTURE)
	for field in ["committed_mode_counts", "attribution_slices", "event_type_counts", "recent_events"]:
		for malformed_value in [null, true, 1]:
			var candidate: Dictionary = snapshot.duplicate(true)
			candidate.game_state.report_state.live[field] = malformed_value
			_assert_primitive_failure(candidate, "%s=%s" % [field, str(malformed_value)])

func _report_runtime() -> GameState:
	return SaveSchemaMapper.snapshot_to_runtime(_read(POPULATED_FIXTURE)).game_state

func _assert_runtime_failure(state: GameState, expected_path: String, label: String) -> void:
	var result := GameStateValidator.validate(state, _registry())
	assert_false(result.ok, label)
	assert_eq(result.field_path, expected_path, label)

func _assert_report_wire_inventory(expected: Dictionary, actual: Dictionary) -> void:
	for field in ["ingested_through_simulation_msec", "next_report_sequence", "next_event_sequence", "dropped_history_count"]:
		assert_true(actual.has(field), field)
		assert_eq(actual[field], expected[field], field)
	for window_name in ["live"]:
		_assert_accumulator_wire_inventory(expected[window_name], actual[window_name], window_name)
	assert_eq(actual.history.size(), expected.history.size(), "history.size")
	for index in range(expected.history.size()):
		for field in ["report_sequence", "snapshot_reason", "snapshot_simulation_msec"]:
			assert_true(actual.history[index].has(field), "history.%d.%s" % [index, field])
			assert_eq(actual.history[index][field], expected.history[index][field], "history.%d.%s" % [index, field])
		_assert_accumulator_wire_inventory(expected.history[index].window, actual.history[index].window, "history.%d.window" % index)

func _assert_accumulator_wire_inventory(expected: Dictionary, actual: Dictionary, path: String) -> void:
	for field in ["window_started_simulation_msec", "window_ended_simulation_msec", "ingested_run_count", "omitted_event_count"]:
		assert_true(actual.has(field), path + "." + field)
		assert_eq(actual[field], expected[field], path + "." + field)
	for map_field in ["committed_mode_counts", "event_type_counts"]:
		for key in expected[map_field].keys():
			assert_true(actual[map_field].has(key), path + "." + map_field + "." + key)
			assert_eq(actual[map_field][key], expected[map_field][key], path + "." + map_field + "." + key)
	for key in expected.attribution_slices.keys():
		var expected_slice: Dictionary = expected.attribution_slices[key]
		var actual_slice: Dictionary = actual.attribution_slices[key]
		for field in ["threshold_id", "assignment_revision", "lifecycle_state", "window_started_simulation_msec", "window_ended_simulation_msec", "elapsed_msec", "returned_souls_delta", "backlog_reduced", "completed_cycles_delta"]:
			assert_eq(actual_slice[field], expected_slice[field], path + ".attribution_slices." + key + "." + field)
		for identity_field in ["form_id", "writ_id"]:
			assert_eq(actual_slice.loadout_identity[identity_field], expected_slice.loadout_identity[identity_field], path + ".loadout_identity." + identity_field)
		assert_eq(actual_slice.loadout_identity.ordered_retinue_ids, expected_slice.loadout_identity.ordered_retinue_ids, path + ".loadout_identity.ordered_retinue_ids")
		for map_field in ["inventory_gains_by_item_id", "mastery_gains_subunits_by_form_id"]:
			for nested_key in expected_slice[map_field].keys():
				assert_eq(actual_slice[map_field][nested_key], expected_slice[map_field][nested_key], path + "." + map_field + "." + nested_key)
		for channel_key in expected_slice.channel_summaries_by_channel_id.keys():
			var expected_channel: Dictionary = expected_slice.channel_summaries_by_channel_id[channel_key]
			var actual_channel: Dictionary = actual_slice.channel_summaries_by_channel_id[channel_key]
			for channel_field in ["threshold_id", "channel_id", "output_item_id", "elapsed_msec", "banked_units_delta", "progress_subunits_start", "progress_subunits_end", "rate_carry_units_start", "rate_carry_units_end", "total_banked_units_start", "total_banked_units_end"]:
				assert_eq(actual_channel[channel_field], expected_channel[channel_field], path + ".channel." + channel_field)
	for index in range(expected.recent_events.size()):
		for field in ["event_sequence", "event_type", "occurred_simulation_msec", "priority", "subject_id", "source_id"]:
			assert_eq(actual.recent_events[index][field], expected.recent_events[index][field], path + ".recent_events.%d.%s" % [index, field])

func _apply_runtime_case(state: GameState, case_name: String) -> void:
	match case_name:
		"null_live": state.report_state.live = null
		"wrong_history_child": state.report_state.history[0] = null
		"negative_cursor": state.report_state.ingested_through_simulation_msec = -1
		"invalid_mode": state.report_state.live.committed_mode_counts[&"INVALID"] = 1
		"mode_sum": state.report_state.live.committed_mode_counts[&"OFFLINE_FIXTURE"] = 2
		"slice_key_alias": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|SETTLED"] = state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].deep_clone()
		"invalid_threshold": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].threshold_id = &"THR_UNKNOWN"
		"invalid_form": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity = ReportLoadoutIdentity.new(&"FORM_UNKNOWN", &"WRIT_EMERGENCY_FIRST_RETURN", [])
		"invalid_writ": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity = ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_UNKNOWN", [])
		"invalid_retinue": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity = ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_EMERGENCY_FIRST_RETURN", [&"RET_UNKNOWN"])
		"duplicate_retinue": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].loadout_identity = ReportLoadoutIdentity.new(&"FORM_SCRIBE", &"WRIT_EMERGENCY_FIRST_RETURN", [&"RET_SOLDIER_COMPANY", &"RET_SOLDIER_COMPANY"])
		"invalid_item": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].inventory_gains_by_item_id[&"ITEM_UNKNOWN"] = 1
		"invalid_mastery_form": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].mastery_gains_subunits_by_form_id[&"FORM_UNKNOWN"] = 1
		"invalid_channel": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_UNKNOWN"] = ReportChannelSummary.new()
		"invalid_output": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].output_item_id = &"RES_ESSENCE"
		"invalid_lifecycle": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].lifecycle_state = &"INVALID"
		"invalid_event_type": state.report_state.live.recent_events[0] = ReportEventRecord.new(4, &"INVALID", 4500, 200, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE")
		"invalid_priority": state.report_state.live.recent_events[0] = ReportEventRecord.new(4, &"THRESHOLD_SETTLED", 4500, 100, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE")
		"invalid_event_subject": state.report_state.live.recent_events[0] = ReportEventRecord.new(4, &"THRESHOLD_SETTLED", 4500, 200, &"THR_UNKNOWN", &"SIMULATION_ENGINE")
		"invalid_event_source": state.report_state.live.recent_events[0] = ReportEventRecord.new(4, &"THRESHOLD_SETTLED", 4500, 200, &"THR_GLOAMWOOD", &"SOURCE_UNKNOWN")
		"event_outside_window": state.report_state.live.recent_events[0] = ReportEventRecord.new(4, &"THRESHOLD_SETTLED", 3000, 200, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE")
		"event_time_order": state.report_state.live.recent_events.append(ReportEventRecord.new(5, &"THRESHOLD_SETTLED", 4000, 200, &"THR_GLOAMWOOD", &"SIMULATION_ENGINE"))
		"history_limit":
			for index in range(ReportState.REPORT_HISTORY_LIMIT):
				state.report_state.history.append(state.report_state.history[0].deep_clone())
		"duplicate_report": state.report_state.history.append(state.report_state.history[0].deep_clone())
		"duplicate_event": state.report_state.live.recent_events.append(state.report_state.live.recent_events[0].deep_clone())
		"slice_after_parent": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].window_ended_simulation_msec = 5001
		"channel_too_long": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].elapsed_msec = 1001
		"invalid_content": state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].output_item_id = &"RES_ESSENCE"

func test_primitive_mutation_matrix_rejects_before_runtime_exposure() -> void:
	var snapshot := _read(POPULATED_FIXTURE)
	var structural_cases := ["root_missing", "root_extra", "live_missing", "live_extra", "record_missing", "record_extra", "window_missing", "window_extra", "slice_missing", "slice_extra", "loadout_missing", "loadout_extra", "channel_missing", "channel_extra", "event_missing", "event_extra", "wrong_root_type", "wrong_live_type", "wrong_history_type", "wrong_record_type", "wrong_window_type", "wrong_slice_type", "wrong_loadout_type", "wrong_channel_type", "wrong_event_type", "wrong_map_type"]
	for case_name in structural_cases:
		var candidate := snapshot.duplicate(true)
		_apply_primitive_case(candidate, case_name)
		_assert_primitive_failure(candidate, case_name)
	var integer_fields := ["report_state.next_event_sequence", "report_state.live.ingested_run_count", "report_state.history.0.report_sequence", "report_state.history.0.window.window_started_simulation_msec", "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.assignment_revision", "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.elapsed_msec", "report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.channel_summaries_by_channel_id.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.progress_subunits_start", "report_state.live.recent_events.0.event_sequence"]
	var malformed_values := [1, "", " ", "+1", "01", "1e0", "1.0", "x1", "-1", "9223372036854775808"]
	for field_name in integer_fields:
		for malformed_value in malformed_values:
			var candidate := snapshot.duplicate(true)
			_set_primitive_field(candidate, field_name, malformed_value)
			_assert_primitive_failure(candidate, "%s=%s" % [field_name, str(malformed_value)])
	for case_name in ["empty_form_id", "empty_item_id", "empty_channel_id", "empty_event_source", "slice_key_mismatch", "channel_key_mismatch", "duplicate_retinues", "duplicate_history_sequence", "unsorted_event_sequence", "next_report_bound", "next_event_bound", "slice_before_parent", "slice_after_parent", "slice_elapsed_mismatch", "channel_elapsed_bound", "mode_sum", "channel_total_delta", "event_priority", "event_window", "event_time_order", "record_window_end", "overlapping_live_window", "omitted_event_undercount", "omitted_event_overcount", "empty_live_contradiction"]:
		var candidate := snapshot.duplicate(true)
		_apply_primitive_case(candidate, case_name)
		_assert_primitive_failure(candidate, case_name)

func _assert_primitive_failure(candidate: Dictionary, label: String) -> void:
	var result := SaveSchemaValidator.validate_v4(candidate)
	assert_false(result.ok, label)
	assert_true(result.has("code") and result.has("field_path"), label)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(candidate)
	assert_false(runtime.ok, label + " runtime exposure")

func _set_primitive_field(snapshot: Dictionary, field_name: String, value: Variant) -> void:
	match field_name:
		"report_state.next_event_sequence": snapshot.game_state.report_state.next_event_sequence = value
		"report_state.live.ingested_run_count": snapshot.game_state.report_state.live.ingested_run_count = value
		"report_state.history.0.report_sequence": snapshot.game_state.report_state.history[0].report_sequence = value
		"report_state.history.0.window.window_started_simulation_msec": snapshot.game_state.report_state.history[0].window.window_started_simulation_msec = value
		"report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.assignment_revision": snapshot.game_state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].assignment_revision = value
		"report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.elapsed_msec": snapshot.game_state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].elapsed_msec = value
		"report_state.live.attribution_slices.THR_GLOAMWOOD|8|OVERDUE.channel_summaries_by_channel_id.CHANNEL_GLOAMWOOD_SOLDIER_SOULS.progress_subunits_start": snapshot.game_state.report_state.live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"].channel_summaries_by_channel_id["CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits_start = value
		"report_state.live.recent_events.0.event_sequence": snapshot.game_state.report_state.live.recent_events[0].event_sequence = value

func _apply_primitive_case(snapshot: Dictionary, case_name: String) -> void:
	var report: Dictionary = snapshot.game_state.report_state
	var live: Dictionary = report.live
	var record: Dictionary = report.history[0]
	var window: Dictionary = record.window
	var slice: Dictionary = live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"]
	var loadout: Dictionary = slice.loadout_identity
	var channel: Dictionary = slice.channel_summaries_by_channel_id["CHANNEL_GLOAMWOOD_SOLDIER_SOULS"]
	var event: Dictionary = live.recent_events[0]
	match case_name:
		"root_missing": report.erase("live")
		"root_extra": report.extra = "x"
		"live_missing": live.erase("omitted_event_count")
		"live_extra": live.extra = "x"
		"record_missing": record.erase("window")
		"record_extra": record.extra = "x"
		"window_missing": window.erase("recent_events")
		"window_extra": window.extra = "x"
		"slice_missing": slice.erase("elapsed_msec")
		"slice_extra": slice.extra = "x"
		"loadout_missing": loadout.erase("form_id")
		"loadout_extra": loadout.extra = "x"
		"channel_missing": channel.erase("output_item_id")
		"channel_extra": channel.extra = "x"
		"event_missing": event.erase("priority")
		"event_extra": event.extra = "x"
		"wrong_root_type": snapshot.game_state.report_state = []
		"wrong_live_type": report.live = []
		"wrong_history_type": report.history = {}
		"wrong_record_type": report.history[0] = []
		"wrong_window_type": record.window = []
		"wrong_slice_type": live.attribution_slices["THR_GLOAMWOOD|8|OVERDUE"] = []
		"wrong_loadout_type": slice.loadout_identity = []
		"wrong_channel_type": slice.channel_summaries_by_channel_id["CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = []
		"wrong_event_type": live.recent_events[0] = []
		"wrong_map_type": live.committed_mode_counts = []
		"empty_form_id": loadout.form_id = ""
		"empty_item_id": slice.inventory_gains_by_item_id[""] = "1"
		"empty_channel_id": channel.channel_id = ""
		"empty_event_source": event.source_id = ""
		"slice_key_mismatch": live.attribution_slices["THR_GLOAMWOOD|8|SETTLED"] = slice.duplicate(true)
		"channel_key_mismatch": slice.channel_summaries_by_channel_id["CHANNEL_WRONG"] = channel.duplicate(true)
		"duplicate_retinues": loadout.ordered_retinue_ids = ["RET_SOLDIER_COMPANY", "RET_SOLDIER_COMPANY"]
		"duplicate_history_sequence": report.history.append(record.duplicate(true))
		"unsorted_event_sequence": live.recent_events[0].event_sequence = "2"
		"next_report_bound": report.next_report_sequence = "4"
		"next_event_bound": report.next_event_sequence = "4"
		"slice_before_parent": slice.window_started_simulation_msec = "2999"
		"slice_after_parent": slice.window_ended_simulation_msec = "5001"
		"slice_elapsed_mismatch": slice.elapsed_msec = "999"
		"channel_elapsed_bound": channel.elapsed_msec = "1001"
		"mode_sum": live.committed_mode_counts.FOREGROUND_SUPPLIED = "2"
		"channel_total_delta": channel.total_banked_units_end = "7"
		"event_priority": event.priority = "100"
		"event_window": event.occurred_simulation_msec = "3000"
		"event_time_order":
			var reordered: Dictionary = event.duplicate(true)
			reordered.event_sequence = "5"
			reordered.occurred_simulation_msec = "4000"
			live.recent_events.append(reordered)
		"record_window_end": record.snapshot_simulation_msec = "3000"; record.window.window_ended_simulation_msec = "2999"
		"overlapping_live_window": live.window_started_simulation_msec = "2500"
		"omitted_event_undercount": live.omitted_event_count = "2"
		"omitted_event_overcount": live.omitted_event_count = "0"
		"empty_live_contradiction":
			live.attribution_slices = {}
			live.committed_mode_counts = {}
			live.event_type_counts = {}
			live.recent_events = []
			live.ingested_run_count = "0"
			live.omitted_event_count = "0"
			live.window_started_simulation_msec = "4999"
