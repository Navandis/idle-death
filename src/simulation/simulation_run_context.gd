class_name SimulationRunContext
extends RefCounted

## Immutable identity captured once for one supplied-duration simulation.
##
## The context owns copied run identity and the validated content revision. It
## does not own the candidate GameState, formulas, journal facts, clocks, saves,
## or the final compatibility result. Arrays are detached at construction so a
## later caller-side assignment change cannot rewrite historical run identity.
## Simulation times are integer milliseconds; content_revision is the catalog
## revision used to validate the source before the transaction was opened.

var baseline_simulation_time_msec: int:
	get: return _baseline_simulation_time_msec
var requested_elapsed_msec: int:
	get: return _requested_elapsed_msec
var has_active_reaping: bool:
	get: return _has_active_reaping
var threshold_id: StringName:
	get: return _threshold_id
var assignment_revision: int:
	get: return _assignment_revision
var form_id: StringName:
	get: return _form_id
var writ_id: StringName:
	get: return _writ_id
var ordered_retinue_ids: Array[StringName]:
	get: return _ordered_retinue_ids.duplicate()
var initial_lifecycle_state: StringName:
	get: return _initial_lifecycle_state
var content_revision: String:
	get: return _content_revision

var _baseline_simulation_time_msec: int
var _requested_elapsed_msec: int
var _has_active_reaping: bool
var _threshold_id: StringName
var _assignment_revision: int
var _form_id: StringName
var _writ_id: StringName
var _ordered_retinue_ids: Array[StringName] = []
var _initial_lifecycle_state: StringName
var _content_revision: String

func _init(
	baseline_time: int,
	requested_elapsed: int,
	active: bool,
	threshold: StringName = &"",
	revision: int = 0,
	form: StringName = &"",
	writ: StringName = &"",
	retinues: Array[StringName] = [],
	lifecycle: StringName = &"",
	content_value: String = ""
) -> void:
	_baseline_simulation_time_msec = baseline_time
	_requested_elapsed_msec = requested_elapsed
	_has_active_reaping = active
	_threshold_id = threshold
	_assignment_revision = revision
	_form_id = form
	_writ_id = writ
	_ordered_retinue_ids.assign(retinues)
	_initial_lifecycle_state = lifecycle
	_content_revision = content_value

func detached_copy() -> SimulationRunContext:
	return SimulationRunContext.new(
		baseline_simulation_time_msec,
		requested_elapsed_msec,
		has_active_reaping,
		threshold_id,
		assignment_revision,
		form_id,
		writ_id,
		ordered_retinue_ids,
		initial_lifecycle_state,
		content_revision
	)

func read_only_snapshot() -> Dictionary:
	return {
		"baseline_simulation_time_msec": baseline_simulation_time_msec,
		"requested_elapsed_msec": requested_elapsed_msec,
		"has_active_reaping": has_active_reaping,
		"threshold_id": threshold_id,
		"assignment_revision": assignment_revision,
		"form_id": form_id,
		"writ_id": writ_id,
		"ordered_retinue_ids": ordered_retinue_ids.duplicate(),
		"initial_lifecycle_state": initial_lifecycle_state,
		"content_revision": content_revision,
	}
