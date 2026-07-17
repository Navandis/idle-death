extends SceneTree

## Deterministic M04B assignment trace using an explicit isolated save root.
##
## The trace proves the approved operation/loadout/assignment/episode identity
## matrix without UI, clocks, production, event sourcing, or normal user storage.

func _init() -> void:
	var root := _read_required_save_root()
	if root == "": return
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not registry.ready: _fail("registry", {"diagnostics": registry.diagnostics}); return
	var storage := FileSaveStorage.new()
	var files := SaveFileSet.new(root, "m04b_trace")
	_cleanup(files, storage)
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), registry)
	var service := ReapingAssignmentService.new(registry)
	var state := _state()
	var time_state := TimeAuthorityState.new()
	var initial_time := state.simulation_time_msec
	var gloamwood_progress: int = state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits

	var dispatch1 := service.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	if not _success(dispatch1, 1, 1, 1, &"THR_GLOAMWOOD"): return
	var first_start: int = state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec
	if first_start != 0: _fail("zero_start", {"started": first_start}); return
	_print_marker("TRACE M04B operation_identity=THR_GLOAMWOOD")
	_print_marker("TRACE M04B dispatch_revision=1_tethers=1")
	var duplicate := service.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	var stale := service.recall(state, &"THR_GLOAMWOOD", 0)
	if duplicate.success or stale.success: _fail("duplicate_stale", {"duplicate": duplicate.success, "stale": stale.success}); return
	_print_marker("TRACE M04B duplicate_and_stale_rejected=PASS")
	if not _round_trip(coordinator, state, time_state, 1, true): return
	_print_marker("TRACE M04B active_round_trip=PASS")
	var recall1 := service.recall(state, &"THR_GLOAMWOOD", 1)
	if not _success(recall1, 2, 0, 0, &"THR_GLOAMWOOD"): return
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 17
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_GLOAMWOOD"] = 3
	_print_marker("TRACE M04B recall_revision=2_tethers=0")
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 0
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units.clear()
	state.advance_simulation_time(500)
	var dispatch_gloam_scribe := service.redispatch(state, &"THR_GLOAMWOOD", &"FORM_SCRIBE", &"WRIT_STANDARD", 2)
	if not _success(dispatch_gloam_scribe, 3, 1, 3, &"THR_GLOAMWOOD") or state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec != first_start: return
	_print_marker("TRACE M04B different_loadout_same_threshold_same_operation=PASS")
	if not service.recall(state, &"THR_GLOAMWOOD", 3).success: _fail("recall_scribe", {}); return
	state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count = 23
	var loadout3: StringName = state.reapings[&"THR_GLOAMWOOD"].form_id
	var shared_timestamp := state.simulation_time_msec
	var broken_dispatch := service.dispatch(state, &"THR_BROKEN_WATCH", &"FORM_SCRIBE", &"WRIT_STANDARD")
	if not _success(broken_dispatch, 1, 1, 1, &"THR_BROKEN_WATCH") or state.reapings[&"THR_BROKEN_WATCH"].started_simulation_msec != shared_timestamp: return
	if loadout3 != state.reapings[&"THR_BROKEN_WATCH"].form_id or state.reapings[&"THR_BROKEN_WATCH"].started_simulation_msec == first_start: _fail("broken_identity", {}); return
	_print_marker("TRACE M04B same_loadout_different_threshold_separate_operation=PASS")
	state.reapings[&"THR_BROKEN_WATCH"].completed_cycle_count = 31
	if not service.recall(state, &"THR_BROKEN_WATCH", 1).success: _fail("recall_broken", {}); return
	var return_prior := service.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 4)
	if not _success(return_prior, 5, 1, 5, &"THR_GLOAMWOOD"): return
	if state.reapings[&"THR_GLOAMWOOD"].assignment_revision == 1 or state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec != first_start: _fail("return_prior", {}); return
	_print_marker("TRACE M04B return_to_prior_loadout_new_episode=PASS")
	_print_marker("TRACE M04B started_simulation_msec_immutable=PASS")
	_print_marker("TRACE M04B zero_start_is_valid=PASS")
	if state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits != gloamwood_progress: _fail("threshold_progress", {}); return
	if state.reapings[&"THR_GLOAMWOOD"].completed_cycle_count != 23 or state.reapings[&"THR_BROKEN_WATCH"].completed_cycle_count != 31: _fail("operation_state", {}); return
	_print_marker("TRACE M04B preserved_threshold_and_operation_state=PASS")
	if not service.recall(state, &"THR_GLOAMWOOD", 5).success: _fail("final_recall", {}); return
	if not _round_trip(coordinator, state, time_state, 2, false): return
	_print_marker("TRACE M04B inactive_round_trip=PASS")
	if state.simulation_time_msec != initial_time + 500: _fail("simulation_time", {"time": state.simulation_time_msec}); return
	_print_marker("TRACE M04B simulation_time_unchanged=PASS")
	_cleanup(files, storage)
	quit(0)

func _state() -> GameState:
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TRACE")
	state.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TRACE")
	var gloamwood := _threshold(1000)
	gloamwood.channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	state.thresholds[&"THR_GLOAMWOOD"] = gloamwood
	state.thresholds[&"THR_BROKEN_WATCH"] = _threshold(1000)
	return state

func _threshold(backlog: int) -> GameState.ThresholdState:
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"; threshold.availability_state = &"AVAILABLE"; threshold.lifecycle_state = &"OVERDUE"; threshold.remaining_backlog = backlog
	return threshold

func _success(result: ReapingAssignmentService.AssignmentResult, revision: int, tethers: int, episode: int, threshold_id: StringName) -> bool:
	if not result.success or result.change_summary == null or result.assignment_revision != revision or result.occupied_tether_count != tethers or result.change_summary.activation_episode_revision != episode or result.threshold_id != threshold_id:
		_fail("result", {"success": result.success, "revision": result.assignment_revision, "tethers": result.occupied_tether_count})
		return false
	if result.events.size() != 1 or result.events[0].payload.assignment_revision != revision or result.events[0].occurred_simulation_msec < 0:
		_fail("event", {})
		return false
	return true

func _round_trip(coordinator: GameStatePersistenceCoordinator, state: GameState, time_state: TimeAuthorityState, revision: int, active: bool) -> bool:
	var save := coordinator.save_runtime(state, time_state, revision)
	if not save.ok: _fail("save", save); return false
	var loaded := coordinator.load_runtime()
	if not loaded.ok: _fail("load", loaded); return false
	var loaded_reaping: GameState.ReapingState = loaded.game_state.reapings[&"THR_GLOAMWOOD"]
	if loaded_reaping.is_active != active or loaded_reaping.assignment_revision != state.reapings[&"THR_GLOAMWOOD"].assignment_revision:
		_fail("round_trip", {})
		return false
	return true

func _read_required_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index] == "--save-root" and index + 1 < args.size():
			var root: String = args[index + 1]
			if root.begins_with("user://"):
				_fail("save_root_user", {"root": root})
				return ""
			return root
	_fail("save_root_missing", {})
	return ""

func _cleanup(files: SaveFileSet, storage: FileSaveStorage) -> void:
	for path in [files.primary_path, files.backup_path, files.temporary_path]:
		if storage.exists(path): storage.remove(path)

func _print_marker(marker: String) -> void:
	print(marker)

func _fail(label: String, data: Dictionary) -> void:
	push_error("TRACE M04B %s FAIL %s" % [label, str(data)])
	quit(1)
