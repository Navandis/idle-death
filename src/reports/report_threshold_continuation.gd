class_name ReportThresholdContinuation
extends RefCounted

## The sole compact cross-window endpoint authority for one Threshold. It is
## updated inside an ingestion candidate and never exposes a presentation view.

var threshold_id: StringName = &""
var latest_assignment_revision: int = 0
var form_id: StringName = &""
var writ_id: StringName = &""
var ordered_retinue_ids: Array[StringName] = []
var lifecycle_state: StringName = &""
var remaining_backlog: int = 0
var has_settled: bool = false
var channels: Array[ReportChannelContinuation] = []

func deep_clone() -> ReportThresholdContinuation:
	var copy := ReportThresholdContinuation.new()
	copy.threshold_id = threshold_id
	copy.latest_assignment_revision = latest_assignment_revision
	copy.form_id = form_id
	copy.writ_id = writ_id
	copy.ordered_retinue_ids.assign(ordered_retinue_ids)
	copy.lifecycle_state = lifecycle_state
	copy.remaining_backlog = remaining_backlog
	copy.has_settled = has_settled
	for channel in channels: copy.channels.append(channel.deep_clone())
	return copy

func value_equals(other: ReportThresholdContinuation) -> bool:
	if other == null or threshold_id != other.threshold_id or latest_assignment_revision != other.latest_assignment_revision \
		or form_id != other.form_id or writ_id != other.writ_id or ordered_retinue_ids != other.ordered_retinue_ids \
		or lifecycle_state != other.lifecycle_state or remaining_backlog != other.remaining_backlog \
		or has_settled != other.has_settled or channels.size() != other.channels.size():
		return false
	for index in range(channels.size()):
		if not channels[index].value_equals(other.channels[index]): return false
	return true
