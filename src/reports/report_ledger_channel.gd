class_name ReportLedgerChannel
extends RefCounted

## Stored endpoint evidence for one Threshold output channel.  The ledger owns
## these values; no simulation object or mutable game state is retained here.

var channel_id: StringName = &""
var output_item_id: StringName = &""
var start_simulation_msec: int = 0
var end_simulation_msec: int = 0
var progress_subunits_before: int = 0
var progress_subunits_after: int = 0
var rate_period_msec: int = 0
var rate_carry_units_before: int = 0
var rate_carry_units_after: int = 0
var total_banked_units_before: int = 0
var total_banked_units_after: int = 0

func deep_clone() -> ReportLedgerChannel:
	var copy := ReportLedgerChannel.new()
	copy.channel_id = channel_id
	copy.output_item_id = output_item_id
	copy.start_simulation_msec = start_simulation_msec
	copy.end_simulation_msec = end_simulation_msec
	copy.progress_subunits_before = progress_subunits_before
	copy.progress_subunits_after = progress_subunits_after
	copy.rate_period_msec = rate_period_msec
	copy.rate_carry_units_before = rate_carry_units_before
	copy.rate_carry_units_after = rate_carry_units_after
	copy.total_banked_units_before = total_banked_units_before
	copy.total_banked_units_after = total_banked_units_after
	return copy

func value_equals(other: ReportLedgerChannel) -> bool:
	return other != null and channel_id == other.channel_id and output_item_id == other.output_item_id \
		and start_simulation_msec == other.start_simulation_msec and end_simulation_msec == other.end_simulation_msec \
		and progress_subunits_before == other.progress_subunits_before and progress_subunits_after == other.progress_subunits_after \
		and rate_period_msec == other.rate_period_msec and rate_carry_units_before == other.rate_carry_units_before \
		and rate_carry_units_after == other.rate_carry_units_after and total_banked_units_before == other.total_banked_units_before \
		and total_banked_units_after == other.total_banked_units_after
