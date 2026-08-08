class_name ReportLedgerSlice
extends RefCounted

## A maximal caller-owned, non-persisted deterministic operational interval in
## simulation milliseconds. It owns normalized endpoints and children, not
## derived totals, source mutation, clocks, saves, or application lifecycle.

var run_mode: StringName = &""
var content_revision: String = ""
var threshold_id: StringName = &""
var assignment_revision: int = 0
var form_id: StringName = &""
var writ_id: StringName = &""
var ordered_retinue_ids: Array[StringName] = []
var lifecycle_state: StringName = &""
var start_simulation_msec: int = 0
var end_simulation_msec: int = 0
var returned_souls_delta: int = 0
var remaining_backlog_before: int = 0
var remaining_backlog_after: int = 0
var essence_delta: int = 0
var mastery_delta_subunits: int = 0
var completed_cycles_delta: int = 0
var channels: Array[ReportLedgerChannel] = []

func deep_clone() -> ReportLedgerSlice:
	var copy := ReportLedgerSlice.new()
	copy.run_mode = run_mode
	copy.content_revision = content_revision
	copy.threshold_id = threshold_id
	copy.assignment_revision = assignment_revision
	copy.form_id = form_id
	copy.writ_id = writ_id
	copy.ordered_retinue_ids.assign(ordered_retinue_ids)
	copy.lifecycle_state = lifecycle_state
	copy.start_simulation_msec = start_simulation_msec
	copy.end_simulation_msec = end_simulation_msec
	copy.returned_souls_delta = returned_souls_delta
	copy.remaining_backlog_before = remaining_backlog_before
	copy.remaining_backlog_after = remaining_backlog_after
	copy.essence_delta = essence_delta
	copy.mastery_delta_subunits = mastery_delta_subunits
	copy.completed_cycles_delta = completed_cycles_delta
	for channel in channels: copy.channels.append(channel.deep_clone())
	return copy

func value_equals(other: ReportLedgerSlice) -> bool:
	if other == null or run_mode != other.run_mode or content_revision != other.content_revision or threshold_id != other.threshold_id \
		or assignment_revision != other.assignment_revision or form_id != other.form_id or writ_id != other.writ_id \
		or ordered_retinue_ids != other.ordered_retinue_ids or lifecycle_state != other.lifecycle_state \
		or start_simulation_msec != other.start_simulation_msec or end_simulation_msec != other.end_simulation_msec \
		or returned_souls_delta != other.returned_souls_delta or remaining_backlog_before != other.remaining_backlog_before \
		or remaining_backlog_after != other.remaining_backlog_after or essence_delta != other.essence_delta \
		or mastery_delta_subunits != other.mastery_delta_subunits or completed_cycles_delta != other.completed_cycles_delta \
		or channels.size() != other.channels.size():
		return false
	for index in range(channels.size()):
		if not channels[index].value_equals(other.channels[index]): return false
	return true
