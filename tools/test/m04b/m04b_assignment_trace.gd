extends SceneTree

## Deterministic M04B assignment trace using an isolated real save root.
##
## The trace proves dispatch, duplicate/stale rejection, active and inactive
## schema-v2 round trips, recall, redispatch, immutable first-start timestamps,
## and unchanged simulation time without relying on UI, clocks, or production.

func _init() -> void:
	var root := _read_save_root()
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not registry.ready:
		_fail("registry", {"diagnostics": registry.diagnostics})
	var storage := FileSaveStorage.new()
	var files := SaveFileSet.new(root, "m04b_trace")
	_cleanup(files, storage)
	var coordinator := GameStatePersistenceCoordinator.new(SaveService.new(storage, files), registry)
	var service := ReapingAssignmentService.new(registry)
	var state := _state()
	var time_state := TimeAuthorityState.new()
	var dispatched := service.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	if not dispatched.success or dispatched.assignment_revision != 1 or dispatched.occupied_tether_count != 1:
		_fail("dispatch", _result(dispatched))
	print("TRACE M04B dispatch_revision=1_occupied=1")
	var duplicate := service.dispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD")
	if duplicate.success or duplicate.error_code != ReapingAssignmentService.REAPING_RECORD_EXISTS:
		_fail("duplicate", _result(duplicate))
	if not coordinator.save_runtime(state, time_state, 1).ok:
		_fail("save_active", {})
	var loaded_active := coordinator.load_runtime()
	if not loaded_active.ok or not loaded_active.game_state.reapings[&"THR_GLOAMWOOD"].is_active:
		_fail("load_active", loaded_active)
	print("TRACE M04B active_round_trip=PASS")
	var stale := service.recall(state, &"THR_GLOAMWOOD", 0)
	if stale.success or stale.error_code != ReapingAssignmentService.REAPING_STALE_ASSIGNMENT_REVISION:
		_fail("stale", _result(stale))
	state.reapings[&"THR_GLOAMWOOD"].cycle_phase_msec = 5
	state.reapings[&"THR_GLOAMWOOD"].flow_carry_units[&"FLOW_TEST"] = 2
	state.advance_simulation_time(250)
	var recalled := service.recall(state, &"THR_GLOAMWOOD", 1)
	if not recalled.success or recalled.assignment_revision != 2 or recalled.occupied_tether_count != 0:
		_fail("recall", _result(recalled))
	print("TRACE M04B recall_revision=2_occupied=0")
	if not coordinator.save_runtime(state, time_state, 2).ok:
		_fail("save_inactive", {})
	var loaded_inactive := coordinator.load_runtime()
	if not loaded_inactive.ok or loaded_inactive.game_state.reapings[&"THR_GLOAMWOOD"].is_active:
		_fail("load_inactive", loaded_inactive)
	print("TRACE M04B inactive_round_trip=PASS")
	var redispatched := service.redispatch(state, &"THR_GLOAMWOOD", &"FORM_MAN_AT_ARMS", &"WRIT_STANDARD", 2)
	if not redispatched.success or redispatched.assignment_revision != 3 or state.reapings[&"THR_GLOAMWOOD"].started_simulation_msec != 1000:
		_fail("redispatch", _result(redispatched))
	if state.simulation_time_msec != 1250:
		_fail("simulation_time_changed", {"time": state.simulation_time_msec})
	print("TRACE M04B redispatch_revision=3_first_start=1000")
	print("TRACE M04B simulation_time_msec=1250")
	_cleanup(files, storage)
	quit(0)

func _state() -> GameState:
	var state := GameState.new(1000)
	state.progression.command_tether_capacity = 1
	state.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TRACE")
	var threshold := GameState.ThresholdState.new()
	threshold.knowledge_state = &"CHARTED"
	threshold.availability_state = &"AVAILABLE"
	threshold.lifecycle_state = &"OVERDUE"
	threshold.remaining_backlog = 1000
	threshold.channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	state.thresholds[&"THR_GLOAMWOOD"] = threshold
	return state

func _read_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index] == "--save-root" and index + 1 < args.size():
			return args[index + 1]
	return "user://m04b_trace"

func _cleanup(files: SaveFileSet, storage: FileSaveStorage) -> void:
	for path in [files.primary_path, files.backup_path, files.temporary_path]:
		if storage.exists(path):
			storage.remove(path)

func _result(result: ReapingAssignmentService.AssignmentResult) -> Dictionary:
	return {"success": result.success, "error_code": result.error_code, "revision": result.assignment_revision}

func _fail(label: String, data: Dictionary) -> void:
	push_error("TRACE M04B %s FAIL %s" % [label, str(data)])
	quit(1)
