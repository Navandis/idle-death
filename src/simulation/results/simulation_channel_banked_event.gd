class_name SimulationChannelBankedEvent
extends SimulationEvent

## Typed event for one positive whole-unit channel bank.  It carries the
## boundary values needed by delayed consumers and no mutable payload map.
## It is detached, non-authoritative, non-persisted evidence owned by one
## segment and occurs at that segment's end.

var output_item_id: StringName:
	get: return _output_item_id
var quantity: int:
	get: return _quantity
var lifecycle_state: StringName:
	get: return _lifecycle_state
var total_banked_units_after: int:
	get: return _total_banked_units_after
var progress_subunits_after: int:
	get: return _progress_subunits_after

var _output_item_id: StringName
var _quantity: int
var _lifecycle_state: StringName
var _total_banked_units_after: int
var _progress_subunits_after: int

func _init(
	occurred_value: int,
	segment_index_value: int,
	threshold_value: StringName,
	channel_value: StringName,
	output_item_value: StringName,
	quantity_value: int,
	lifecycle_value: StringName,
	total_after_value: int,
	progress_after_value: int
) -> void:
	super(SimulationEvent.EVENT_OUTPUT_CHANNEL_BANKED, occurred_value, SimulationEvent.EVENT_PRIORITY_CHANNEL_GAIN, segment_index_value, threshold_value, channel_value, true, true)
	_output_item_id = output_item_value
	_quantity = quantity_value
	_lifecycle_state = lifecycle_value
	_total_banked_units_after = total_after_value
	_progress_subunits_after = progress_after_value

func detached_copy() -> SimulationChannelBankedEvent:
	return SimulationChannelBankedEvent.new(occurred_simulation_msec, segment_index, subject_id, source_id, _output_item_id, _quantity, _lifecycle_state, _total_banked_units_after, _progress_subunits_after)

func value_equals(other: SimulationEvent) -> bool:
	return other is SimulationChannelBankedEvent \
		and super.value_equals(other) \
		and _output_item_id == other.output_item_id \
		and _quantity == other.quantity \
		and _lifecycle_state == other.lifecycle_state \
		and _total_banked_units_after == other.total_banked_units_after \
		and _progress_subunits_after == other.progress_subunits_after
