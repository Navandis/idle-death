class_name SimulationThresholdSettledEvent
extends SimulationEvent

## Typed event for the single `OVERDUE` to `SETTLED` boundary supported by the
## current resolver.  Boundary totals are copied from the Settlement journal
## fact at the transition; this event does not inspect later mutable state,
## authorize the transition, or serialize itself.

var persistent_returns_total: int:
	get: return _persistent_returns_total
var remaining_backlog_before: int:
	get: return _remaining_backlog_before
var remaining_backlog_after: int:
	get: return _remaining_backlog_after
var lifecycle_before: StringName:
	get: return _lifecycle_before
var lifecycle_after: StringName:
	get: return _lifecycle_after

var _persistent_returns_total: int
var _remaining_backlog_before: int
var _remaining_backlog_after: int
var _lifecycle_before: StringName
var _lifecycle_after: StringName

func _init(
	occurred_value: int,
	segment_index_value: int,
	threshold_value: StringName,
	returns_total_value: int,
	backlog_before_value: int,
	backlog_after_value: int,
	lifecycle_before_value: StringName,
	lifecycle_after_value: StringName
) -> void:
	super(SimulationEvent.EVENT_THRESHOLD_SETTLED, occurred_value, SimulationEvent.EVENT_PRIORITY_LIFECYCLE, segment_index_value, threshold_value, SimulationEvent.SIMULATION_ENGINE_SOURCE, true, true)
	_persistent_returns_total = returns_total_value
	_remaining_backlog_before = backlog_before_value
	_remaining_backlog_after = backlog_after_value
	_lifecycle_before = lifecycle_before_value
	_lifecycle_after = lifecycle_after_value

func detached_copy() -> SimulationThresholdSettledEvent:
	return SimulationThresholdSettledEvent.new(occurred_simulation_msec, segment_index, subject_id, _persistent_returns_total, _remaining_backlog_before, _remaining_backlog_after, _lifecycle_before, _lifecycle_after)

func value_equals(other: SimulationEvent) -> bool:
	return other is SimulationThresholdSettledEvent \
		and super.value_equals(other) \
		and _persistent_returns_total == other.persistent_returns_total \
		and _remaining_backlog_before == other.remaining_backlog_before \
		and _remaining_backlog_after == other.remaining_backlog_after \
		and _lifecycle_before == other.lifecycle_before \
		and _lifecycle_after == other.lifecycle_after
