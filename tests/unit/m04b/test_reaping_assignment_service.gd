extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _service() -> ReapingAssignmentService:
	return ReapingAssignmentService.new(_registry())

func _base_state(time_msec := 1000, tethers := 1) -> GameState:
	var state := GameState.new(time_msec)
	state.progression.command_tether_capacity = tethers
	state.progression.unlocked_output_item_ids = [&"SOUL_CALLING_SOLDIER"]
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TEST")
	var gloamwood := GameState.ThresholdState.new()
	gloamwood.knowledge_state = &"CHARTED"
	gloamwood.availability_state = &"AVAILABLE"
	gloamwood.lifecycle_state = &"OVERDUE"
	gloamwood.remaining_backlog = 1000
	gloamwood.channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	state.thresholds[&"THR_GLOAMWOOD"] = gloamwood
	var watch := GameState.ThresholdState.new()
	watch.knowledge_state = &"CHARTED"
	watch.availability_state = &"AVAILABLE"
	watch.lifecycle_state = &"OVERDUE"
	watch.remaining_backlog = 1000
	watch.channel_acquisition[&"CHANNEL_BROKEN_WATCH_PROVISIONS"] = GameState.ThresholdAcquisitionState.new(0, 0, 0)
	state.thresholds[&"THR_BROKEN_WATCH"] = watch
	return state

func _dispatch_active(state: GameState, threshold_id := &"THR_GLOAMWOOD", form_id := &"FORM_MAN_AT_ARMS") -> ReapingAssignmentService.AssignmentResult:
	return _service().dispatch(state, threshold_id, form_id, &"WRIT_STANDARD")

func test_initial_dispatch_creates_threshold_scoped_operation_and_event() -> void:
	var state := _base_state(0)
	var result := _dispatch_active(state)
	assert_true(result.success)
	assert_true(result.save_checkpoint_requested)
	assert_eq(result.assignment_revision, 1)
	assert_eq(result.assignment_state_id, "THR_GLOAMWOOD@1")
	assert_eq(result.occupied_tether_count, 1)
	assert_eq(result.events[0].event_type, ReapingAssignmentService.EVENT_DISPATCHED)
	var reaping: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"]
	assert_true(reaping.is_active)
	assert_eq(reaping.started_simulation_msec, 0)
	assert_eq(reaping.last_configuration_change_simulation_msec, 0)
	assert_eq(state.simulation_time_msec, 0)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits, 250000)

func test_duplicate_and_invalid_dispatch_reject_without_mutation() -> void:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	var before := state.deep_clone()
	var duplicate := _dispatch_active(state)
	assert_false(duplicate.success)
	assert_eq(duplicate.error_code, ReapingAssignmentService.REAPING_RECORD_EXISTS)
	_assert_same_reaping(before.reapings[&"THR_GLOAMWOOD"], state.reapings[&"THR_GLOAMWOOD"])
	var no_tether := _base_state(1000, 0)
	var capacity := _dispatch_active(no_tether)
	assert_false(capacity.success)
	assert_eq(capacity.error_code, ReapingAssignmentService.REAPING_TETHER_CAPACITY_EXCEEDED)
	assert_false(no_tether.reapings.has(&"THR_GLOAMWOOD"))

func test_recall_preserves_record_progress_and_frees_derived_tether() -> void:
	var state := _base_state(1000)
	assert_true(_dispatch_active(state).success)
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 123
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_TEST"] = 7
	state.advance_simulation_time(500)
	var result := _service().recall(state, &"THR_GLOAMWOOD", 1)
	assert_true(result.success)
	assert_eq(result.assignment_revision, 2)
	assert_eq(result.occupied_tether_count, 0)
	assert_eq(result.events[0].event_type, ReapingAssignmentService.EVENT_RECALLED)
	var reaping: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"]
	assert_false(reaping.is_active)
	assert_eq(reaping.started_simulation_msec, 1000)
	assert_eq(reaping.last_configuration_change_simulation_msec, 1500)
	assert_eq(reaping.cycle_phase_msec, 123)
	assert_eq(reaping.flow_carry_units[&"FLOW_TEST"], 7)

func test_stale_recall_and_repeat_recall_do_not_increment() -> void:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	var stale := _service().recall(state, &"THR_GLOAMWOOD", 0)
	assert_false(stale.success)
	assert_eq(stale.error_code, ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 1)
	assert_true(_service().recall(state, &"THR_GLOAMWOOD", 1).success)
	var repeat := _service().recall(state, &"THR_GLOAMWOOD", 2)
	assert_false(repeat.success)
	assert_eq(repeat.error_code, ReapingAssignmentService.REAPING_ALREADY_INACTIVE)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 2)

func test_redispatch_same_loadout_preserves_first_start_and_frozen_state() -> void:
	var state := _base_state(1000)
	assert_true(_dispatch_active(state).success)
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 5
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS] = 2
	assert_true(_service().recall(state, &"THR_GLOAMWOOD", 1).success)
	state.advance_simulation_time(250)
	var result := _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 2)
	assert_true(result.success)
	assert_eq(result.assignment_revision, 3)
	assert_eq(result.events[0].event_type, ReapingAssignmentService.EVENT_REDISPATCHED)
	var reaping: GameState.ReapingState = state.reapings[&"THR_GLOAMWOOD"]
	assert_true(reaping.is_active)
	assert_eq(reaping.started_simulation_msec, 1000)
	assert_eq(reaping.last_configuration_change_simulation_msec, 1250)
	assert_eq(reaping.cycle_phase_msec, 5)
	assert_eq(reaping.flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS], 2)

func test_redispatch_rejects_unknown_nonzero_flow_before_activation_without_mutation() -> void:
	var service := _service()
	var changed_state := _inactive_state_with_flow_key(&"FLOW_FUTURE_COMPAT", 7)
	assert_true(GameStateValidator.validate(changed_state, _registry(), true).ok)
	var changed_before := _snapshot_game(changed_state)
	var changed := service.redispatch(changed_state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2)
	_assert_failure_result(changed, ReapingAssignmentService.REAPING_RESOLUTION_REQUIRED)
	assert_string_contains(changed.developer_details, "THR_GLOAMWOOD")
	assert_string_contains(changed.developer_details, "unknown_nonzero_flow_keys")
	assert_string_contains(changed.developer_details, "FLOW_FUTURE_COMPAT")
	assert_eq(_snapshot_game(changed_state), changed_before)

	var same_state := _inactive_state_with_flow_key(&"FLOW_FUTURE_COMPAT", 7)
	var same_before := _snapshot_game(same_state)
	var same := service.redispatch(same_state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 2)
	_assert_failure_result(same, ReapingAssignmentService.REAPING_RESOLUTION_REQUIRED)
	assert_string_contains(same.developer_details, "FLOW_FUTURE_COMPAT")
	assert_eq(_snapshot_game(same_state), same_before)

func test_redispatch_preserves_unknown_zero_and_known_nonzero_residuals() -> void:
	var zero_state := _inactive_state_with_flow_key(&"FLOW_FUTURE_COMPAT", 0)
	var zero := _service().redispatch(zero_state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 2)
	assert_true(zero.success, zero.developer_details)
	assert_eq(zero_state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_FUTURE_COMPAT"], 0)

	var known_state := _inactive_state_with_flow_key(CoreFlowKeys.RETURNS_PROGRESS, 500000)
	known_state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_CARRY] = 42
	known_state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 7
	var known := _service().redispatch(known_state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2)
	assert_true(known.success, known.developer_details)
	assert_eq(known_state.reapings[&"THR_GLOAMWOOD"].form_id, &"FORM_SCRIBE")
	assert_eq(known_state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS], 500000)
	assert_eq(known_state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_CARRY], 42)
	assert_eq(known_state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec, 7)

func test_changed_redispatch_preserves_residuals_when_denominators_match() -> void:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	assert_true(_service().recall(state, &"THR_GLOAMWOOD", 1).success)
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 1
	var accepted := _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2)
	assert_true(accepted.success, accepted.developer_details)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].form_id, &"FORM_SCRIBE")
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec, 1)

func test_form_exclusivity_and_same_loadout_on_different_threshold_identity() -> void:
	var state := _base_state(1000, 2)
	assert_true(_dispatch_active(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS").success)
	var same_form := _dispatch_active(state, &"THR_BROKEN_WATCH", &"FORM_MAN_AT_ARMS")
	assert_false(same_form.success)
	assert_eq(same_form.error_code, ReapingAssignmentService.REAPING_FORM_ALREADY_ASSIGNED)
	var other_form := _dispatch_active(state, &"THR_BROKEN_WATCH", &"FORM_SCRIBE")
	assert_true(other_form.success)
	assert_true(state.reapings.has(&"THR_GLOAMWOOD"))
	assert_true(state.reapings.has(&"THR_BROKEN_WATCH"))
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 1)
	assert_eq(state.reapings[&"THR_BROKEN_WATCH"].assignment_revision, 1)

func test_revision_overflow_and_invalid_state_are_typed_failures() -> void:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	state.reapings[&"THR_GLOAMWOOD"].assignment_revision = FixedPoint.INT64_MAX
	var overflow := _service().recall(state, &"THR_GLOAMWOOD", FixedPoint.INT64_MAX)
	assert_false(overflow.success)
	assert_eq(overflow.error_code, ReapingAssignmentService.REAPING_ASSIGNMENT_REVISION_OVERFLOW)
	state.progression.command_tether_capacity = -1
	var invalid := _service().dispatch(state, &"THR_BROKEN_WATCH", &"FORM_SCRIBE", &"WRIT_STANDARD")
	assert_false(invalid.success)
	assert_eq(invalid.error_code, ReapingAssignmentService.REAPING_STATE_INVALID)

func test_zero_revision_records_are_invalid_for_recall_and_redispatch() -> void:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	state.reapings[&"THR_GLOAMWOOD"].assignment_revision = 0
	var recall_result := _service().recall(state, &"THR_GLOAMWOOD", 0)
	assert_false(recall_result.success)
	assert_eq(recall_result.error_code, ReapingAssignmentService.REAPING_STATE_INVALID)
	assert_true(state.reapings[&"THR_GLOAMWOOD"].is_active)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 0)
	state.reapings[&"THR_GLOAMWOOD"].is_active = false
	var redispatch_result := _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 0)
	assert_false(redispatch_result.success)
	assert_eq(redispatch_result.error_code, ReapingAssignmentService.REAPING_STATE_INVALID)
	assert_false(state.reapings[&"THR_GLOAMWOOD"].is_active)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, 0)

func test_duplicate_active_form_in_loaded_state_is_invalid_before_checkpointable_commands() -> void:
	var state := _base_state(1000, 2)
	assert_true(_dispatch_active(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS").success)
	assert_true(_dispatch_active(state, &"THR_BROKEN_WATCH", &"FORM_SCRIBE").success)
	state.reapings[&"THR_BROKEN_WATCH"].form_id = &"FORM_MAN_AT_ARMS"
	var before_gloamwood_revision: int = state.reapings[&"THR_GLOAMWOOD"].assignment_revision
	var recall_result := _service().recall(state, &"THR_GLOAMWOOD", before_gloamwood_revision)
	assert_false(recall_result.success)
	assert_eq(recall_result.error_code, ReapingAssignmentService.REAPING_STATE_INVALID)
	assert_true(state.reapings[&"THR_GLOAMWOOD"].is_active)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].assignment_revision, before_gloamwood_revision)

func test_action_result_and_event_contract_on_success_and_failure() -> void:
	var state := _base_state()
	var result := _dispatch_active(state)
	assert_true(result.success)
	assert_eq(result.error_code, &"")
	assert_ne(result.player_message, "")
	assert_not_null(result.change_summary)
	assert_eq(result.change_summary.threshold_id, &"THR_GLOAMWOOD")
	assert_eq(result.change_summary.assignment_revision, 1)
	assert_eq(result.change_summary.assignment_state_id, "THR_GLOAMWOOD@1")
	assert_eq(result.change_summary.activation_episode_revision, 1)
	assert_eq(result.change_summary.loadout.form_id, "FORM_MAN_AT_ARMS")
	assert_true(result.change_summary.is_active)
	assert_eq(result.change_summary.occupied_tether_count, 1)
	assert_eq(result.events.size(), 1)
	var event: ReapingAssignmentService.AssignmentEvent = result.events[0]
	assert_eq(event.event_type, ReapingAssignmentService.EVENT_DISPATCHED)
	assert_eq(event.occurred_simulation_msec, 1000)
	assert_eq(event.priority, ReapingAssignmentService.EVENT_PRIORITY_ASSIGNMENT)
	assert_eq(event.subject_id, &"THR_GLOAMWOOD")
	assert_eq(event.source_id, &"")
	assert_true(event.reportable)
	assert_true(event.tutorial_relevant)
	assert_eq(event.payload.assignment_state_id, "THR_GLOAMWOOD@1")
	var before := _snapshot_game(state)
	var failure := _dispatch_active(state)
	_assert_failure_result(failure, ReapingAssignmentService.REAPING_RECORD_EXISTS)
	assert_eq(_snapshot_game(state), before)

func test_command_failure_matrix_preserves_whole_state() -> void:
	var state := _base_state(1000, 1)
	_assert_failure_unchanged(state, func(): return _service().dispatch(null, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_STATE_INVALID)
	_assert_failure_unchanged(state, func(): return ReapingAssignmentService.new(ContentRegistry.new()).dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_STATE_INVALID)
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_MISSING", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_THRESHOLD_NOT_FOUND)
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"FORM_MAN_AT_ARMS", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_THRESHOLD_NOT_FOUND)
	state.thresholds[&"THR_GLOAMWOOD"].availability_state = &"LOCKED"
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_STATE_INVALID)
	state.thresholds[&"THR_GLOAMWOOD"].availability_state = &"AVAILABLE"
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MISSING", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_FORM_NOT_FOUND)
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"RES_ESSENCE", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_FORM_NOT_FOUND)
	state.forms[&"FORM_MAN_AT_ARMS"].awakened = false
	state.forms[&"FORM_MAN_AT_ARMS"].awakened_by = &""
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_FORM_NOT_AWAKENED)
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(false, false, 0, &"")
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_FORM_NOT_AWAKENED)
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TEST")
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_MISSING"), ReapingAssignmentService.REAPING_WRIT_NOT_FOUND)
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"RES_ESSENCE"), ReapingAssignmentService.REAPING_WRIT_NOT_FOUND)
	var disabled_registry := _registry()
	disabled_registry._records["WRIT_STANDARD"].enabled = false
	_assert_failure_unchanged(state, func(): return ReapingAssignmentService.new(disabled_registry).dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_WRIT_NOT_FOUND)

func test_revision_and_record_failure_matrix_preserves_whole_state() -> void:
	var state := _base_state()
	_assert_failure_unchanged(state, func(): return _service().recall(state, &"THR_GLOAMWOOD", 1), ReapingAssignmentService.REAPING_RECORD_NOT_FOUND)
	assert_true(_dispatch_active(state).success)
	_assert_failure_unchanged(state, func(): return _service().dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD"), ReapingAssignmentService.REAPING_RECORD_EXISTS)
	_assert_failure_unchanged(state, func(): return _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 1), ReapingAssignmentService.REAPING_ALREADY_ACTIVE)
	_assert_failure_unchanged(state, func(): return _service().recall(state, &"THR_GLOAMWOOD", -1), ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)
	_assert_failure_unchanged(state, func(): return _service().recall(state, &"THR_GLOAMWOOD", 0), ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)
	_assert_failure_unchanged(state, func(): return _service().recall(state, &"THR_GLOAMWOOD", 99), ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)
	assert_true(_service().recall(state, &"THR_GLOAMWOOD", 1).success)
	_assert_failure_unchanged(state, func(): return _service().recall(state, &"THR_GLOAMWOOD", 2), ReapingAssignmentService.REAPING_ALREADY_INACTIVE)
	_assert_failure_unchanged(state, func(): return _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", -1), ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)
	_assert_failure_unchanged(state, func(): return _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 1), ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)
	_assert_failure_unchanged(state, func(): return _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 99), ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION)

func test_changed_redispatch_no_longer_rejects_resolved_residuals() -> void:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	assert_true(_service().recall(state, &"THR_GLOAMWOOD", 1).success)
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS] = 500000
	var result := _service().redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2)
	assert_true(result.success, result.developer_details)
	assert_eq(state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[CoreFlowKeys.RETURNS_PROGRESS], 500000)

func _inactive_state_with_flow_key(key: StringName, value: int) -> GameState:
	var state := _base_state()
	assert_true(_dispatch_active(state).success)
	assert_true(_service().recall(state, &"THR_GLOAMWOOD", 1).success)
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[key] = value
	return state

func _assert_same_reaping(expected: GameState.ReapingState, actual: GameState.ReapingState) -> void:
	assert_eq(actual.threshold_id, expected.threshold_id)
	assert_eq(actual.is_active, expected.is_active)
	assert_eq(actual.form_id, expected.form_id)
	assert_eq(actual.writ_id, expected.writ_id)
	assert_eq(actual.assignment_revision, expected.assignment_revision)
	assert_eq(actual.started_simulation_msec, expected.started_simulation_msec)
	assert_eq(actual.last_configuration_change_simulation_msec, expected.last_configuration_change_simulation_msec)

func _snapshot_game(state: GameState) -> Dictionary:
	if state == null:
		return {}
	return SaveSchemaMapper.runtime_to_snapshot(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state

func _assert_failure_result(result: ReapingAssignmentService.AssignmentResult, expected_code: StringName) -> void:
	assert_false(result.success)
	assert_eq(result.error_code, expected_code)
	assert_ne(result.player_message, "")
	assert_false(result.developer_details.is_empty())
	assert_null(result.change_summary)
	assert_eq(result.events.size(), 0)
	assert_false(result.save_checkpoint_requested)

func _assert_failure_unchanged(state: GameState, action: Callable, expected_code: StringName) -> void:
	var before := _snapshot_game(state)
	var result: ReapingAssignmentService.AssignmentResult = action.call()
	_assert_failure_result(result, expected_code)
	assert_eq(_snapshot_game(state), before)
