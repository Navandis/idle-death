class_name SimulationSegmentResult
extends RefCounted

## Detached, non-authoritative facts for one contiguous simulation segment.
## Historical Threshold/loadout identity is copied from the immutable run
## context; this class does not look up current GameState, calculate production,
## mutate a candidate, or participate in persistence.  Times are simulation
## milliseconds, core quantities are whole units except Mastery subunits.

var segment_index: int:
	get: return _segment_index
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
var lifecycle_state: StringName:
	get: return _lifecycle_state
var start_simulation_msec: int:
	get: return _start_simulation_msec
var end_simulation_msec: int:
	get: return _end_simulation_msec
var elapsed_msec: int:
	get: return _elapsed_msec
var returned_souls_delta: int:
	get: return _returned_souls_delta
var backlog_reduced: int:
	get: return _backlog_reduced
var essence_delta: int:
	get: return _essence_delta
var mastery_delta_subunits: int:
	get: return _mastery_delta_subunits
var completed_cycles_delta: int:
	get: return _completed_cycles_delta
var channel_deltas: Array[SimulationChannelDeltaResult]:
	get:
		var detached: Array[SimulationChannelDeltaResult] = []
		for channel in _channel_deltas:
			detached.append(channel.detached_copy())
		return detached

var _segment_index: int
var _threshold_id: StringName
var _assignment_revision: int
var _form_id: StringName
var _writ_id: StringName
var _ordered_retinue_ids: Array[StringName] = []
var _lifecycle_state: StringName
var _start_simulation_msec: int
var _end_simulation_msec: int
var _elapsed_msec: int
var _returned_souls_delta: int
var _backlog_reduced: int
var _essence_delta: int
var _mastery_delta_subunits: int
var _completed_cycles_delta: int
var _channel_deltas: Array[SimulationChannelDeltaResult] = []

func _init(
	segment_index_value: int,
	threshold_value: StringName,
	assignment_revision_value: int,
	form_value: StringName,
	writ_value: StringName,
	retinue_values: Array[StringName],
	lifecycle_value: StringName,
	start_value: int,
	end_value: int,
	elapsed_value: int,
	returned_souls_value: int,
	backlog_reduced_value: int,
	essence_value: int,
	mastery_value: int,
	cycles_value: int,
	channel_values: Array[SimulationChannelDeltaResult]
) -> void:
	_segment_index = segment_index_value
	_threshold_id = threshold_value
	_assignment_revision = assignment_revision_value
	_form_id = form_value
	_writ_id = writ_value
	_ordered_retinue_ids.assign(retinue_values)
	_lifecycle_state = lifecycle_value
	_start_simulation_msec = start_value
	_end_simulation_msec = end_value
	_elapsed_msec = elapsed_value
	_returned_souls_delta = returned_souls_value
	_backlog_reduced = backlog_reduced_value
	_essence_delta = essence_value
	_mastery_delta_subunits = mastery_value
	_completed_cycles_delta = cycles_value
	for channel in channel_values:
		_channel_deltas.append(channel.detached_copy())

## Returns a deeply detached segment, including every channel child.
func detached_copy() -> SimulationSegmentResult:
	return SimulationSegmentResult.new(
		_segment_index,
		_threshold_id,
		_assignment_revision,
		_form_id,
		_writ_id,
		_ordered_retinue_ids,
		_lifecycle_state,
		_start_simulation_msec,
		_end_simulation_msec,
		_elapsed_msec,
		_returned_souls_delta,
		_backlog_reduced,
		_essence_delta,
		_mastery_delta_subunits,
		_completed_cycles_delta,
		_channel_deltas
	)

## Compares all segment and child values without relying on object identity.
func value_equals(other: SimulationSegmentResult) -> bool:
	if other == null or _segment_index != other.segment_index or _threshold_id != other.threshold_id \
		or _assignment_revision != other.assignment_revision or _form_id != other.form_id \
		or _writ_id != other.writ_id or _ordered_retinue_ids != other.ordered_retinue_ids \
		or _lifecycle_state != other.lifecycle_state or _start_simulation_msec != other.start_simulation_msec \
		or _end_simulation_msec != other.end_simulation_msec or _elapsed_msec != other.elapsed_msec \
		or _returned_souls_delta != other.returned_souls_delta or _backlog_reduced != other.backlog_reduced \
		or _essence_delta != other.essence_delta or _mastery_delta_subunits != other.mastery_delta_subunits \
		or _completed_cycles_delta != other.completed_cycles_delta:
		return false
	var other_channels := other.channel_deltas
	if _channel_deltas.size() != other_channels.size(): return false
	for index in range(_channel_deltas.size()):
		if not _channel_deltas[index].value_equals(other_channels[index]): return false
	return true
