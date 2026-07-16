class_name ReapingAssignmentService
extends RefCounted

## Scene-independent owner for M04B Reaping assignment commands.
##
## The service mutates only the supplied authoritative GameState and only after
## validating a deep-cloned candidate. It owns the command boundary for initial
## dispatch, recall, and inactive-record redispatch; it does not own elapsed
## production, save files, clocks, tutorial/UI state, Retinue reservation rules,
## or future active in-place reconfiguration. The four identities are kept
## distinct: the operation is the Threshold ID map key, the loadout is a Form /
## Writ / ordered-Retinue value tuple, assignment state is Threshold plus
## revision, and a dispatch episode is the successful revision that activated it.

const OK := ""
const REAPING_STATE_INVALID := "REAPING_STATE_INVALID"
const REAPING_THRESHOLD_NOT_FOUND := "REAPING_THRESHOLD_NOT_FOUND"
const REAPING_THRESHOLD_UNAVAILABLE := "REAPING_THRESHOLD_UNAVAILABLE"
const REAPING_FORM_NOT_FOUND := "REAPING_FORM_NOT_FOUND"
const REAPING_FORM_NOT_AWAKENED := "REAPING_FORM_NOT_AWAKENED"
const REAPING_FORM_ALREADY_ASSIGNED := "REAPING_FORM_ALREADY_ASSIGNED"
const REAPING_WRIT_NOT_FOUND := "REAPING_WRIT_NOT_FOUND"
const REAPING_RECORD_EXISTS := "REAPING_RECORD_EXISTS"
const REAPING_RECORD_NOT_FOUND := "REAPING_RECORD_NOT_FOUND"
const REAPING_ALREADY_ACTIVE := "REAPING_ALREADY_ACTIVE"
const REAPING_ALREADY_INACTIVE := "REAPING_ALREADY_INACTIVE"
const REAPING_TETHER_CAPACITY_EXCEEDED := "REAPING_TETHER_CAPACITY_EXCEEDED"
const REAPING_STALE_ASSIGNMENT_REVISION := "REAPING_STALE_ASSIGNMENT_REVISION"
const REAPING_ASSIGNMENT_REVISION_OVERFLOW := "REAPING_ASSIGNMENT_REVISION_OVERFLOW"
const REAPING_RESOLUTION_REQUIRED := "REAPING_RESOLUTION_REQUIRED"

const EVENT_DISPATCHED := "REAPING_DISPATCHED"
const EVENT_RECALLED := "REAPING_RECALLED"
const EVENT_REDISPATCHED := "REAPING_REDISPATCHED"

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

func occupied_tether_count(state: GameState) -> int:
	var count := 0
	if state == null:
		return count
	for reaping in state.reapings.values():
		if reaping is GameState.ReapingState and reaping.is_active:
			count += 1
	return count

func dispatch(state: GameState, threshold_id: StringName, form_id: StringName, writ_id: StringName) -> AssignmentResult:
	var base := _validate_base_state(state)
	if not base.success:
		return base
	if state.reapings.has(threshold_id):
		return AssignmentResult.failure(REAPING_RECORD_EXISTS, {"threshold_id": threshold_id})
	var preconditions := _validate_loadout_preconditions(state, threshold_id, form_id, writ_id, &"")
	if not preconditions.success:
		return preconditions
	if occupied_tether_count(state) + 1 > state.progression.command_tether_capacity:
		return AssignmentResult.failure(REAPING_TETHER_CAPACITY_EXCEEDED, {"threshold_id": threshold_id})

	var candidate := state.deep_clone()
	var reaping := GameState.ReapingState.new()
	reaping.threshold_id = threshold_id
	reaping.is_active = true
	reaping.form_id = form_id
	reaping.writ_id = writ_id
	reaping.retinue_ids = []
	reaping.assignment_revision = 1
	# The first-start timestamp is immutable operation lineage context. A zero
	# cursor is a valid start time, so record existence is the initialization fact.
	reaping.started_simulation_msec = state.simulation_time_msec
	reaping.last_configuration_change_simulation_msec = state.simulation_time_msec
	candidate.reapings[threshold_id] = reaping
	var committed := _validate_candidate(candidate)
	if not committed.success:
		return committed
	state.reapings[threshold_id] = reaping
	return _success(EVENT_DISPATCHED, state, reaping)

func recall(state: GameState, threshold_id: StringName, expected_assignment_revision: int) -> AssignmentResult:
	var base := _validate_base_state(state)
	if not base.success:
		return base
	if not state.reapings.has(threshold_id):
		return AssignmentResult.failure(REAPING_RECORD_NOT_FOUND, {"threshold_id": threshold_id})
	var current: GameState.ReapingState = state.reapings[threshold_id]
	if not current.is_active:
		return AssignmentResult.failure(REAPING_ALREADY_INACTIVE, {"threshold_id": threshold_id})
	if current.assignment_revision != expected_assignment_revision:
		return AssignmentResult.failure(REAPING_STALE_ASSIGNMENT_REVISION, {"expected": expected_assignment_revision, "actual": current.assignment_revision})
	if current.assignment_revision == FixedPoint.INT64_MAX:
		return AssignmentResult.failure(REAPING_ASSIGNMENT_REVISION_OVERFLOW, {"threshold_id": threshold_id})

	var candidate := state.deep_clone()
	var updated: GameState.ReapingState = candidate.reapings[threshold_id]
	updated.is_active = false
	updated.assignment_revision += 1
	updated.last_configuration_change_simulation_msec = state.simulation_time_msec
	var committed := _validate_candidate(candidate)
	if not committed.success:
		return committed
	state.reapings[threshold_id] = updated
	return _success(EVENT_RECALLED, state, updated)

func redispatch(state: GameState, threshold_id: StringName, form_id: StringName, writ_id: StringName, expected_assignment_revision: int) -> AssignmentResult:
	var base := _validate_base_state(state)
	if not base.success:
		return base
	if not state.reapings.has(threshold_id):
		return AssignmentResult.failure(REAPING_RECORD_NOT_FOUND, {"threshold_id": threshold_id})
	var current: GameState.ReapingState = state.reapings[threshold_id]
	if current.is_active:
		return AssignmentResult.failure(REAPING_ALREADY_ACTIVE, {"threshold_id": threshold_id})
	if current.assignment_revision != expected_assignment_revision:
		return AssignmentResult.failure(REAPING_STALE_ASSIGNMENT_REVISION, {"expected": expected_assignment_revision, "actual": current.assignment_revision})
	if current.assignment_revision == FixedPoint.INT64_MAX:
		return AssignmentResult.failure(REAPING_ASSIGNMENT_REVISION_OVERFLOW, {"threshold_id": threshold_id})
	var preconditions := _validate_loadout_preconditions(state, threshold_id, form_id, writ_id, threshold_id)
	if not preconditions.success:
		return preconditions
	if _loadout_changed(current, form_id, writ_id) and _has_unresolved_rate_dependent_state(current):
		return AssignmentResult.failure(REAPING_RESOLUTION_REQUIRED, {"threshold_id": threshold_id})
	if occupied_tether_count(state) + 1 > state.progression.command_tether_capacity:
		return AssignmentResult.failure(REAPING_TETHER_CAPACITY_EXCEEDED, {"threshold_id": threshold_id})

	var candidate := state.deep_clone()
	var updated: GameState.ReapingState = candidate.reapings[threshold_id]
	updated.is_active = true
	updated.form_id = form_id
	updated.writ_id = writ_id
	updated.assignment_revision += 1
	updated.last_configuration_change_simulation_msec = state.simulation_time_msec
	var committed := _validate_candidate(candidate)
	if not committed.success:
		return committed
	state.reapings[threshold_id] = updated
	return _success(EVENT_REDISPATCHED, state, updated)

func _validate_base_state(state: GameState) -> AssignmentResult:
	var validation := GameStateValidator.validate(state, registry)
	if not validation.ok:
		return AssignmentResult.failure(REAPING_STATE_INVALID, validation)
	return _validate_m04b_assignment_integrity(state)

func _validate_loadout_preconditions(state: GameState, threshold_id: StringName, form_id: StringName, writ_id: StringName, allowed_current_threshold: StringName) -> AssignmentResult:
	var threshold_record := registry.get_record(str(threshold_id))
	if not threshold_record.ok or threshold_record.record.type != "threshold" or not threshold_record.record.enabled or not state.thresholds.has(threshold_id):
		return AssignmentResult.failure(REAPING_THRESHOLD_NOT_FOUND, {"threshold_id": threshold_id})
	if str(state.thresholds[threshold_id].availability_state) != "AVAILABLE":
		return AssignmentResult.failure(REAPING_THRESHOLD_UNAVAILABLE, {"threshold_id": threshold_id})
	var form_record := registry.get_record(str(form_id))
	if not form_record.ok or form_record.record.type != "form" or not form_record.record.enabled or not state.forms.has(form_id):
		return AssignmentResult.failure(REAPING_FORM_NOT_FOUND, {"form_id": form_id})
	if not state.forms[form_id].revealed or not state.forms[form_id].awakened:
		return AssignmentResult.failure(REAPING_FORM_NOT_AWAKENED, {"form_id": form_id})
	for active_threshold in state.reapings.keys():
		var active: GameState.ReapingState = state.reapings[active_threshold]
		if active.is_active and active.form_id == form_id and active_threshold != allowed_current_threshold:
			return AssignmentResult.failure(REAPING_FORM_ALREADY_ASSIGNED, {"form_id": form_id, "threshold_id": active_threshold})
	var writ_record := registry.get_record(str(writ_id))
	if not writ_record.ok or writ_record.record.type != "writ" or not writ_record.record.enabled:
		return AssignmentResult.failure(REAPING_WRIT_NOT_FOUND, {"writ_id": writ_id})
	return AssignmentResult.ok_empty()

func _validate_candidate(candidate: GameState) -> AssignmentResult:
	# Candidate validation keeps stale/overflow/duplicate commands from partially
	# mutating live state. Only one Reaping-map replacement is committed after this.
	var validation := GameStateValidator.validate(candidate, registry)
	if not validation.ok:
		return AssignmentResult.failure(REAPING_STATE_INVALID, validation)
	return _validate_m04b_assignment_integrity(candidate)

func _validate_m04b_assignment_integrity(state: GameState) -> AssignmentResult:
	# M04A's broad structural validator intentionally allows inactive scaffolding
	# such as revision zero. M04B commands are stricter: every existing operation
	# record is already an assignment lineage and therefore must have a positive
	# revision, and no active Form may lead two active Reapings. Rejecting the
	# baseline protects malformed loaded saves from being normalized by recall or
	# checkpointed as if a valid command succeeded.
	var active_form_thresholds := {}
	for threshold_key in state.reapings.keys():
		var reaping: GameState.ReapingState = state.reapings[threshold_key]
		if reaping.assignment_revision <= 0:
			return AssignmentResult.failure(REAPING_STATE_INVALID, {"field_path": "reapings.%s.assignment_revision" % threshold_key})
		if reaping.is_active:
			if active_form_thresholds.has(reaping.form_id):
				return AssignmentResult.failure(REAPING_STATE_INVALID, {"field_path": "reapings.%s.form_id" % threshold_key, "duplicate_threshold_id": active_form_thresholds[reaping.form_id]})
			active_form_thresholds[reaping.form_id] = threshold_key
	return AssignmentResult.ok_empty()

func _loadout_changed(reaping: GameState.ReapingState, form_id: StringName, writ_id: StringName) -> bool:
	return reaping.form_id != form_id or reaping.writ_id != writ_id

func _has_unresolved_rate_dependent_state(reaping: GameState.ReapingState) -> bool:
	# M04B has no resolver. Nonzero phase/carry under a changed rate context must
	# wait for M04C/M04D, which will resolve old output to the command boundary.
	if reaping.cycle_phase_msec != 0:
		return true
	for amount in reaping.flow_carry_units.values():
		if int(amount) != 0:
			return true
	return false

func _success(event_type: String, state: GameState, reaping: GameState.ReapingState) -> AssignmentResult:
	var event := AssignmentEvent.new(event_type, reaping.threshold_id, reaping.assignment_revision, state.simulation_time_msec, _loadout(reaping), reaping.is_active)
	return AssignmentResult.successful(reaping.threshold_id, reaping.assignment_revision, reaping.is_active, _loadout(reaping), occupied_tether_count(state), event)

func _loadout(reaping: GameState.ReapingState) -> Dictionary:
	return {"form_id": reaping.form_id, "writ_id": reaping.writ_id, "retinue_ids": reaping.retinue_ids.duplicate()}

class AssignmentEvent:
	extends RefCounted
	## Ordered fact emitted after a successful command; saves do not replay events.
	var event_type: String
	var threshold_id: StringName
	var assignment_revision: int
	var assignment_state_id: String
	var simulation_time_msec: int
	var loadout: Dictionary
	var is_active: bool
	func _init(type_value := "", threshold_value: StringName = &"", revision_value := 0, time_value := 0, loadout_value := {}, active_value := false) -> void:
		event_type = type_value
		threshold_id = threshold_value
		assignment_revision = revision_value
		assignment_state_id = "%s@%d" % [threshold_id, assignment_revision]
		simulation_time_msec = time_value
		loadout = loadout_value.duplicate(true)
		is_active = active_value

class AssignmentResult:
	extends RefCounted
	## Typed command result. Failures are stable gameplay rejections, not errors.
	var success := false
	var error_code := ""
	var diagnostics := {}
	var threshold_id: StringName = &""
	var assignment_revision := 0
	var assignment_state_id := ""
	var is_active := false
	var occupied_tether_count := 0
	var loadout := {}
	var events: Array[AssignmentEvent] = []
	var save_checkpoint_requested := false
	static func ok_empty() -> AssignmentResult:
		var result := AssignmentResult.new()
		result.success = true
		return result
	static func failure(code: String, detail := {}) -> AssignmentResult:
		var result := AssignmentResult.new()
		result.error_code = code
		result.diagnostics = detail.duplicate(true) if detail is Dictionary else {"detail": detail}
		return result
	static func successful(threshold_value: StringName, revision_value: int, active_value: bool, loadout_value: Dictionary, occupied_value: int, event: AssignmentEvent) -> AssignmentResult:
		var result := AssignmentResult.new()
		result.success = true
		result.threshold_id = threshold_value
		result.assignment_revision = revision_value
		result.assignment_state_id = "%s@%d" % [threshold_value, revision_value]
		result.is_active = active_value
		result.loadout = loadout_value.duplicate(true)
		result.occupied_tether_count = occupied_value
		result.events = [event]
		result.save_checkpoint_requested = true
		return result
