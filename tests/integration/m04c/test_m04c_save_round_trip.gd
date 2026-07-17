extends GutTest

func _state() -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = &"THR_GLOAMWOOD"
	reaping.is_active = true
	reaping.form_id = &"FORM_MAN_AT_ARMS"
	reaping.writ_id = &"WRIT_STANDARD"
	reaping.assignment_revision = 1
	state.reapings[&"THR_GLOAMWOOD"] = reaping
	return state

func test_schema_v2_round_trips_core_residuals_after_settlement() -> void:
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	var state := _state()
	var result := SimulationEngine.new(registry).resolve_elapsed(state, 10000)
	assert_true(result.success, result.developer_details)
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 7, registry.content_revision)
	var mapped := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(mapped.ok, str(mapped))
	var round: GameState = mapped.game_state
	assert_eq(round.simulation_time_msec, 10000)
	assert_eq(round.thresholds[&"THR_GLOAMWOOD"].persistent_returns_total, 3)
	assert_eq(round.thresholds[&"THR_GLOAMWOOD"].remaining_backlog, 0)
	assert_eq(str(round.thresholds[&"THR_GLOAMWOOD"].lifecycle_state), "SETTLED")
	assert_eq(round.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS], 625375)
	assert_eq(round.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS], 315250)
	assert_eq(round.reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS], 40000)

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _coordinator(storage: MemorySaveStorage, files: SaveFileSet) -> GameStatePersistenceCoordinator:
	return GameStatePersistenceCoordinator.new(SaveService.new(storage, files), _registry())

func test_production_coordinator_round_trips_overdue_settled_and_idle_m04c_state() -> void:
	var registry := _registry()
	var cases := [_state(), _state(), GameState.new(1234)]
	cases[0].reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS] = 123456
	cases[0].reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_RETURNS_RATE_CARRY_UNITS] = 12
	cases[0].reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS] = 234567
	cases[0].reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_ESSENCE_RATE_CARRY_UNITS] = 34
	cases[0].reapings[&"THR_GLOAMWOOD"].flow_carry_units[SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS] = 56
	cases[0].reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 789
	assert_true(SimulationEngine.new(registry).resolve_elapsed(cases[1], 10000).success)
	for index in range(cases.size()):
		var storage := MemorySaveStorage.new()
		var files := SaveFileSet.new("memory://m04c_%d" % index, "save")
		var coordinator := _coordinator(storage, files)
		assert_true(coordinator.save_runtime(cases[index], TimeAuthorityState.new(), index + 1).ok)
		var loaded := coordinator.load_runtime()
		assert_true(loaded.ok, str(loaded))
		assert_eq(_canonical_state(loaded.game_state), _canonical_state(cases[index]))

func test_coordinator_rejects_invalid_core_residuals_and_cycle_phase() -> void:
	var invalid_cases := [
		{"key": SimulationEngine.FLOW_CORE_RETURNS_PROGRESS_SUBUNITS, "value": FixedPoint.SCALE},
		{"key": SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS, "value": FixedPoint.SCALE},
		{"key": SimulationEngine.FLOW_CORE_RETURNS_RATE_CARRY_UNITS, "value": 1000},
		{"key": SimulationEngine.FLOW_CORE_ESSENCE_RATE_CARRY_UNITS, "value": 10000},
		{"key": SimulationEngine.FLOW_CORE_MASTERY_RATE_CARRY_UNITS, "value": 60000},
	]
	for invalid in invalid_cases:
		var state := _state()
		state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[invalid.key] = invalid.value
		_assert_load_rejects_domain_state(state)
	var phase_state := _state()
	phase_state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 60000
	_assert_load_rejects_domain_state(phase_state)

func _assert_load_rejects_domain_state(state: GameState) -> void:
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04c_invalid", "save")
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	storage.write_bytes(files.primary_path, JsonSaveCodec.new().encode(snapshot).bytes)
	var loaded := _coordinator(storage, files).load_runtime()
	assert_false(loaded.ok, str(loaded))

func _canonical_state(state: GameState) -> Dictionary:
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func test_persisted_snapshot_excludes_result_artifacts_and_preserves_schema_content_codec() -> void:
	var registry := _registry()
	var state := _state()
	var result := SimulationEngine.new(registry).resolve_elapsed(state, 10000)
	assert_true(result.success)
	assert_false(result.events.is_empty())
	assert_false(result.segments.is_empty())
	var storage := MemorySaveStorage.new()
	var files := SaveFileSet.new("memory://m04c_artifacts", "save")
	var coordinator := _coordinator(storage, files)
	assert_true(coordinator.save_runtime(state, TimeAuthorityState.new(), 9).ok)
	var snapshot: Dictionary = JsonSaveCodec.new().decode(storage.files[files.primary_path]).snapshot
	assert_eq(snapshot.codec_id, SaveEnvelope.CODEC_JSON_V1)
	assert_eq(snapshot.schema_version, "2")
	assert_eq(snapshot.content_revision, ContentRegistry.CURRENT_REVISION)
	assert_false(snapshot.game_state.has("events"))
	assert_false(snapshot.game_state.has("segments"))
	assert_false(snapshot.game_state.reapings["THR_GLOAMWOOD"].has("events"))
	assert_false(snapshot.game_state.reapings["THR_GLOAMWOOD"].has("segments"))

func test_already_settled_and_no_active_round_trip_after_resolution() -> void:
	var registry := _registry()
	var settled := _state()
	assert_true(SimulationEngine.new(registry).resolve_elapsed(settled, 10000).success)
	assert_true(SimulationEngine.new(registry).resolve_elapsed(settled, 60000).success)
	var idle := GameState.new(0)
	idle.progression.command_tether_capacity = 1
	assert_true(SimulationEngine.new(registry).resolve_elapsed(idle, 12345).success)
	for state in [settled, idle]:
		var storage := MemorySaveStorage.new()
		var files := SaveFileSet.new("memory://m04c_round_trip_extra", "save")
		var coordinator := _coordinator(storage, files)
		assert_true(coordinator.save_runtime(state, TimeAuthorityState.new(), 3).ok)
		var loaded := coordinator.load_runtime()
		assert_true(loaded.ok, str(loaded))
		assert_eq(_canonical_state(loaded.game_state), _canonical_state(state))
