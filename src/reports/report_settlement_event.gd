class_name ReportSettlementEvent
extends RefCounted

## One normalized Settlement boundary.  Bank events are deliberately folded
## into channel endpoints because their call-count changes when runs are split.

var event_sequence: int = 0
var content_revision: String = ""
var threshold_id: StringName = &""
var assignment_revision: int = 0
var occurred_simulation_msec: int = 0
var persistent_returns_total: int = 0

func deep_clone() -> ReportSettlementEvent:
	var copy := ReportSettlementEvent.new()
	copy.event_sequence = event_sequence
	copy.content_revision = content_revision
	copy.threshold_id = threshold_id
	copy.assignment_revision = assignment_revision
	copy.occurred_simulation_msec = occurred_simulation_msec
	copy.persistent_returns_total = persistent_returns_total
	return copy

func value_equals(other: ReportSettlementEvent) -> bool:
	return other != null and event_sequence == other.event_sequence and content_revision == other.content_revision \
		and threshold_id == other.threshold_id and assignment_revision == other.assignment_revision \
		and occurred_simulation_msec == other.occurred_simulation_msec and persistent_returns_total == other.persistent_returns_total
