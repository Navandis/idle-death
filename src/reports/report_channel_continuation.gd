class_name ReportChannelContinuation
extends RefCounted

## Compact latest endpoint evidence for one Threshold output channel. The
## caller-owned ledger uses it only to preserve ingestion continuity after
## detailed report windows have been pruned.

var channel_id: StringName = &""
var output_item_id: StringName = &""
var rate_period_msec: int = 0
var progress_subunits: int = 0
var rate_carry_units: int = 0
var total_banked_units: int = 0

func deep_clone() -> ReportChannelContinuation:
	var copy := ReportChannelContinuation.new()
	copy.channel_id = channel_id
	copy.output_item_id = output_item_id
	copy.rate_period_msec = rate_period_msec
	copy.progress_subunits = progress_subunits
	copy.rate_carry_units = rate_carry_units
	copy.total_banked_units = total_banked_units
	return copy

func value_equals(other: ReportChannelContinuation) -> bool:
	return other != null and channel_id == other.channel_id and output_item_id == other.output_item_id \
		and rate_period_msec == other.rate_period_msec and progress_subunits == other.progress_subunits \
		and rate_carry_units == other.rate_carry_units and total_banked_units == other.total_banked_units
