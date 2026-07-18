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

const OK := &""
const REAPING_STATE_INVALID := &"REAPING_STATE_INVALID"
const REAPING_THRESHOLD_NOT_FOUND := &"REAPING_THRESHOLD_NOT_FOUND"
const REAPING_THRESHOLD_UNAVAILABLE := &"REAPING_THRESHOLD_UNAVAILABLE"
const REAPING_FORM_NOT_FOUND := &"REAPING_FORM_NOT_FOUND"
const REAPING_FORM_NOT_AWAKENED := &"REAPING_FORM_NOT_AWAKENED"
const REAPING_FORM_ALREADY_ASSIGNED := &"REAPING_FORM_ALREADY_ASSIGNED"
const REAPING_WRIT_NOT_FOUND := &"REAPING_WRIT_NOT_FOUND"
const REAPING_RECORD_EXISTS := &"REAPING_RECORD_EXISTS"
const REAPING_RECORD_NOT_FOUND := &"REAPING_RECORD_NOT_FOUND"
const REAPING_ALREADY_ACTIVE := &"REAPING_ALREADY_ACTIVE"
const REAPING_ALREADY_INACTIVE := &"REAPING_ALREADY_INACTIVE"
const REAPING_TETHER_CAPACITY_EXCEEDED := &"REAPING_TETHER_CAPACITY_EXCEEDED"
const REAPING_STALE_ASSIGNMENT_REVISION := &"REAPING_STALE_ASSIGNMENT_REVISION"
const REAPING_ASSIGNMENT_REVISION_OVERFLOW := &"REAPING_ASSIGNMENT_REVISION_OVERFLOW"
const REAPING_RESOLUTION_REQUIRED := &"REAPING_RESOLUTION_REQUIRED"
const REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED := ReapingRateContextService.REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED
const REAPING_REGISTRY_NOT_READY := &"REAPING_REGISTRY_NOT_READY"
const REAPING_RETINUES_UNSUPPORTED := &"REAPING_RETINUES_UNSUPPORTED"

const EVENT_DISPATCHED := &"REAPING_DISPATCHED"
const EVENT_RECALLED := &"REAPING_RECALLED"
const EVENT_REDISPATCHED := &"REAPING_REDISPATCHED"
const EVENT_PRIORITY_ASSIGNMENT := 100

var registry: ContentRegistry
var rate_context: ReapingRateContextService

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry
	rate_context = ReapingRateContextService.new(content_registry)

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
	var preconditions := validate_loadout_candidate(state, threshold_id, form_id, writ_id, [], &"")
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
	var preconditions := validate_loadout_candidate(state, threshold_id, form_id, writ_id, [], threshold_id)
	if not preconditions.success:
		return preconditions
	if _loadout_changed(current, form_id, writ_id):
		var continuity := rate_context.compare_residual_signatures(state, threshold_id, current.form_id, form_id)
		if not continuity.ok:
			return AssignmentResult.failure(StringName(continuity.code), continuity)
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
	var validation := GameStateValidator.validate(state, registry, true)
	if not validation.ok:
		return AssignmentResult.failure(REAPING_STATE_INVALID, validation)
	return AssignmentResult.ok_empty()

func validate_loadout_candidate(state: GameState, threshold_id: StringName, form_id: StringName, writ_id: StringName, ordered_retinue_ids: Array[StringName] = [], allowed_current_threshold: StringName = &"") -> AssignmentResult:
	## Pure assembly-time candidate validation. It returns component identity, not
	## performance: equal rates or ETAs never merge distinct Form/Writ choices.
	if registry == null or not registry.ready:
		return AssignmentResult.failure(REAPING_REGISTRY_NOT_READY, {})
	if not ordered_retinue_ids.is_empty():
		return AssignmentResult.failure(REAPING_RETINUES_UNSUPPORTED, {"retinue_ids": ordered_retinue_ids})
	var base := _validate_base_state(state)
	if not base.success:
		return base
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
	var ok_result := AssignmentResult.ok_empty()
	ok_result.loadout_identity = rate_context.loadout_identity(form_id, writ_id, ordered_retinue_ids)
	return ok_result

func _validate_candidate(candidate: GameState) -> AssignmentResult:
	# Candidate validation keeps stale/overflow/duplicate commands from partially
	# mutating live state. Only one Reaping-map replacement is committed after this.
	var validation := GameStateValidator.validate(candidate, registry, true)
	if not validation.ok:
		return AssignmentResult.failure(REAPING_STATE_INVALID, validation)
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

func _success(event_type: StringName, state: GameState, reaping: GameState.ReapingState) -> AssignmentResult:
	var activation_revision := reaping.assignment_revision if event_type != EVENT_RECALLED else 0
	var summary := AssignmentChangeSummary.new(reaping.threshold_id, reaping.assignment_revision, activation_revision, _loadout(reaping), reaping.is_active, occupied_tether_count(state))
	var event := AssignmentEvent.new(event_type, state.simulation_time_msec, reaping.threshold_id, summary)
	return AssignmentResult.successful(_success_message(event_type), summary, event)

func _success_message(event_type: StringName) -> String:
	match event_type:
		EVENT_DISPATCHED: return "Reaping dispatched."
		EVENT_RECALLED: return "Reaping recalled."
		EVENT_REDISPATCHED: return "Reaping redispatched."
	return "Reaping assignment updated."

func _loadout(reaping: GameState.ReapingState) -> Dictionary:
	return {"form_id": str(reaping.form_id), "writ_id": str(reaping.writ_id), "retinue_ids": _string_array(reaping.retinue_ids)}

func _string_array(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(str(value))
	return out

class AssignmentChangeSummary:
	extends RefCounted
	## Bounded M04B result summary; this is not persisted as authoritative state.
	var threshold_id: StringName
	var assignment_revision: int
	var assignment_state_id: String
	var activation_episode_revision: int
	var loadout: Dictionary
	var is_active: bool
	var occupied_tether_count: int
	func _init(threshold_value: StringName = &"", revision_value := 0, activation_revision_value := 0, loadout_value := {}, active_value := false, occupied_value := 0) -> void:
		threshold_id = threshold_value
		assignment_revision = revision_value
		assignment_state_id = "%s@%d" % [threshold_id, assignment_revision]
		activation_episode_revision = activation_revision_value
		loadout = loadout_value.duplicate(true)
		is_active = active_value
		occupied_tether_count = occupied_value
	func to_payload() -> Dictionary:
		return {
			"threshold_id": str(threshold_id),
			"assignment_revision": assignment_revision,
			"assignment_state_id": assignment_state_id,
			"activation_episode_revision": activation_episode_revision,
			"loadout": loadout.duplicate(true),
			"is_active": is_active,
			"occupied_tether_count": occupied_tether_count,
		}

class AssignmentEvent:
	extends RefCounted
	## Ordered assignment fact for presentation/report/tutorial observers.
	## Events are not saved or replayed; payload values are primitive and save-safe
	## so future report bridges can copy them without depending on live objects.
	var event_type: StringName
	var occurred_simulation_msec: int
	var priority: int = EVENT_PRIORITY_ASSIGNMENT
	var subject_id: StringName
	var source_id: StringName = &""
	var payload: Dictionary
	var reportable := true
	var tutorial_relevant := true
	func _init(type_value: StringName = &"", time_value := 0, subject_value: StringName = &"", summary: AssignmentChangeSummary = null) -> void:
		event_type = type_value
		occurred_simulation_msec = time_value
		subject_id = subject_value
		payload = summary.to_payload() if summary != null else {}

class AssignmentResult:
	extends RefCounted
	## Typed M04B action result. Failures are stable gameplay rejections, not errors.
	var success := false
	var error_code: StringName = &""
	var player_message := ""
	var developer_details := ""
	var change_summary: AssignmentChangeSummary = null
	var events: Array[AssignmentEvent] = []
	var save_checkpoint_requested := false
	# Convenience mirrors for existing M04B tests/callers; change_summary is the contract.
	var threshold_id: StringName = &""
	var assignment_revision := 0
	var assignment_state_id := ""
	var is_active := false
	var occupied_tether_count := 0
	var loadout := {}
	var loadout_identity: Dictionary = {}
	static func ok_empty() -> AssignmentResult:
		var result := AssignmentResult.new()
		result.success = true
		return result
	static func failure(code: StringName, detail := {}) -> AssignmentResult:
		var result := AssignmentResult.new()
		result.error_code = code
		result.player_message = _message_for_code(code)
		result.developer_details = str(detail)
		return result
	static func successful(message: String, summary: AssignmentChangeSummary, event: AssignmentEvent) -> AssignmentResult:
		var result := AssignmentResult.new()
		result.success = true
		result.player_message = message
		result.change_summary = summary
		result.threshold_id = summary.threshold_id
		result.assignment_revision = summary.assignment_revision
		result.assignment_state_id = summary.assignment_state_id
		result.is_active = summary.is_active
		result.loadout = summary.loadout.duplicate(true)
		result.occupied_tether_count = summary.occupied_tether_count
		result.events = [event]
		result.save_checkpoint_requested = true
		return result
	static func _message_for_code(code: StringName) -> String:
		match code:
			REAPING_STATE_INVALID: return "The current Reaping state is invalid."
			REAPING_THRESHOLD_NOT_FOUND: return "That Threshold is not available for assignment."
			REAPING_THRESHOLD_UNAVAILABLE: return "That Threshold is currently unavailable."
			REAPING_FORM_NOT_FOUND: return "That Form is not available for assignment."
			REAPING_FORM_NOT_AWAKENED: return "That Form must be awakened before assignment."
			REAPING_FORM_ALREADY_ASSIGNED: return "That Form is already leading another active Reaping."
			REAPING_WRIT_NOT_FOUND: return "That Writ is not available for assignment."
			REAPING_RECORD_EXISTS: return "That Threshold already has a Reaping operation."
			REAPING_RECORD_NOT_FOUND: return "That Threshold has no Reaping operation."
			REAPING_ALREADY_ACTIVE: return "That Reaping is already active."
			REAPING_ALREADY_INACTIVE: return "That Reaping is already inactive."
			REAPING_TETHER_CAPACITY_EXCEEDED: return "No command tether is available."
			REAPING_STALE_ASSIGNMENT_REVISION: return "The Reaping assignment changed; refresh and try again."
			REAPING_ASSIGNMENT_REVISION_OVERFLOW: return "The Reaping assignment revision cannot advance."
			REAPING_RESOLUTION_REQUIRED: return "Resolve current Reaping progress before changing this loadout."
			REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED: return "This content requires rate-context normalization before redispatch."
			REAPING_REGISTRY_NOT_READY: return "Reaping content is not ready."
			REAPING_RETINUES_UNSUPPORTED: return "Retinue assignment is not available in this prototype slice."
		return "The Reaping assignment command was rejected."
