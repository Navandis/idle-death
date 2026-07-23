class_name ReportChannelSummary
extends RefCounted

## Detached facts for one persisted output-channel contribution.
##
## Times are simulation milliseconds. Banked and total values are whole units;
## progress uses FixedPoint subunits and carry uses the channel period domain.
## This class does not own inventory, channel acquisition, formulas, or events.

var threshold_id: StringName
var channel_id: StringName
var output_item_id: StringName
var elapsed_msec: int
var banked_units_delta: int
var progress_subunits_start: int
var progress_subunits_end: int
var rate_carry_units_start: int
var rate_carry_units_end: int
var total_banked_units_start: int
var total_banked_units_end: int

func _init(
	threshold_value: StringName = &"",
	channel_value: StringName = &"",
	output_item_value: StringName = &"",
	elapsed_value: int = 0,
	banked_delta_value: int = 0,
	progress_start_value: int = 0,
	progress_end_value: int = 0,
	carry_start_value: int = 0,
	carry_end_value: int = 0,
	total_start_value: int = 0,
	total_end_value: int = 0
) -> void:
	threshold_id = threshold_value
	channel_id = channel_value
	output_item_id = output_item_value
	elapsed_msec = elapsed_value
	banked_units_delta = banked_delta_value
	progress_subunits_start = progress_start_value
	progress_subunits_end = progress_end_value
	rate_carry_units_start = carry_start_value
	rate_carry_units_end = carry_end_value
	total_banked_units_start = total_start_value
	total_banked_units_end = total_end_value

func deep_clone() -> ReportChannelSummary:
	return ReportChannelSummary.new(threshold_id, channel_id, output_item_id, elapsed_msec, banked_units_delta, progress_subunits_start, progress_subunits_end, rate_carry_units_start, rate_carry_units_end, total_banked_units_start, total_banked_units_end)

func value_equals(other: ReportChannelSummary) -> bool:
	return other != null \
		and threshold_id == other.threshold_id and channel_id == other.channel_id and output_item_id == other.output_item_id \
		and elapsed_msec == other.elapsed_msec and banked_units_delta == other.banked_units_delta \
		and progress_subunits_start == other.progress_subunits_start and progress_subunits_end == other.progress_subunits_end \
		and rate_carry_units_start == other.rate_carry_units_start and rate_carry_units_end == other.rate_carry_units_end \
		and total_banked_units_start == other.total_banked_units_start and total_banked_units_end == other.total_banked_units_end
