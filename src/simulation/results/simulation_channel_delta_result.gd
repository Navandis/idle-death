class_name SimulationChannelDeltaResult
extends RefCounted

## Detached, non-authoritative facts for one output channel in one simulation
## segment.  This class owns no inventory, acquisition state, formulas, or save
## data.  All quantities are whole units, progress is FixedPoint subunits, and
## rate carry is measured in the channel's rate-period domain.

var channel_id: StringName:
	get: return _channel_id
var output_item_id: StringName:
	get: return _output_item_id
var banked_units_delta: int:
	get: return _banked_units_delta
var progress_subunits_before: int:
	get: return _progress_subunits_before
var progress_subunits_after: int:
	get: return _progress_subunits_after
var rate_period_msec: int:
	get: return _rate_period_msec
var rate_carry_units_before: int:
	get: return _rate_carry_units_before
var rate_carry_units_after: int:
	get: return _rate_carry_units_after
var total_banked_units_before: int:
	get: return _total_banked_units_before
var total_banked_units_after: int:
	get: return _total_banked_units_after

var _channel_id: StringName
var _output_item_id: StringName
var _banked_units_delta: int
var _progress_subunits_before: int
var _progress_subunits_after: int
var _rate_period_msec: int
var _rate_carry_units_before: int
var _rate_carry_units_after: int
var _total_banked_units_before: int
var _total_banked_units_after: int

func _init(
	channel_value: StringName,
	output_item_value: StringName,
	banked_delta_value: int,
	progress_before_value: int,
	progress_after_value: int,
	period_value: int,
	carry_before_value: int,
	carry_after_value: int,
	total_before_value: int,
	total_after_value: int
) -> void:
	_channel_id = channel_value
	_output_item_id = output_item_value
	_banked_units_delta = banked_delta_value
	_progress_subunits_before = progress_before_value
	_progress_subunits_after = progress_after_value
	_rate_period_msec = period_value
	_rate_carry_units_before = carry_before_value
	_rate_carry_units_after = carry_after_value
	_total_banked_units_before = total_before_value
	_total_banked_units_after = total_after_value

## Returns a detached value copy.  The copy shares no mutable container with the
## original, although its scalar fields are already immutable to callers.
func detached_copy() -> SimulationChannelDeltaResult:
	return SimulationChannelDeltaResult.new(
		_channel_id,
		_output_item_id,
		_banked_units_delta,
		_progress_subunits_before,
		_progress_subunits_after,
		_rate_period_msec,
		_rate_carry_units_before,
		_rate_carry_units_after,
		_total_banked_units_before,
		_total_banked_units_after
	)

## Compares the documented value fields rather than RefCounted identity.
func value_equals(other: SimulationChannelDeltaResult) -> bool:
	return other != null \
		and _channel_id == other.channel_id \
		and _output_item_id == other.output_item_id \
		and _banked_units_delta == other.banked_units_delta \
		and _progress_subunits_before == other.progress_subunits_before \
		and _progress_subunits_after == other.progress_subunits_after \
		and _rate_period_msec == other.rate_period_msec \
		and _rate_carry_units_before == other.rate_carry_units_before \
		and _rate_carry_units_after == other.rate_carry_units_after \
		and _total_banked_units_before == other.total_banked_units_before \
		and _total_banked_units_after == other.total_banked_units_after
