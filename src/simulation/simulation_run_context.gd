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

var baseline_simulation_time_msec: int
var requested_elapsed_msec: int
var has_active_reaping: bool
var threshold_id: StringName
var assignment_revision: int
var form_id: StringName
var writ_id: StringName
var ordered_retinue_ids: Array[StringName] = []
var initial_lifecycle_state: StringName
var content_revision: String

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
	baseline_simulation_time_msec = baseline_time
	requested_elapsed_msec = requested_elapsed
	has_active_reaping = active
	threshold_id = threshold
	assignment_revision = revision
	form_id = form
	writ_id = writ
	ordered_retinue_ids.assign(retinues)
	initial_lifecycle_state = lifecycle
	content_revision = content_value

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
