class_name ReportState
extends RefCounted

## Authoritative saved report aggregate owned by `GameState`.
##
## This family stores explanatory facts, not rewards or simulation authority.
## It owns the live accumulator, bounded detached history, cursors, and checked
## counters. A2 exposes construction, cloning, mapping, and validation only;
## production ingestion, reads, snapshots, pruning, and offline classification
## are explicitly deferred. Cursors and windows use simulation milliseconds.

const REPORT_HISTORY_LIMIT := 20
const REPORT_RECENT_EVENT_LIMIT := 64

var ingested_through_simulation_msec: int = 0
var next_report_sequence: int = 1
var next_event_sequence: int = 1
var dropped_history_count: int = 0
var live: ReportAccumulatorState
var history: Array[ReportRecord] = []

func _init(cursor_msec: int = 0) -> void:
	if cursor_msec < 0: cursor_msec = 0
	ingested_through_simulation_msec = cursor_msec
	live = ReportAccumulatorState.new(cursor_msec)

static func empty_at_cursor(cursor_msec: int) -> ReportState:
	return ReportState.new(cursor_msec)

func deep_clone() -> ReportState:
	var clone := ReportState.new(ingested_through_simulation_msec)
	clone.next_report_sequence = next_report_sequence
	clone.next_event_sequence = next_event_sequence
	clone.dropped_history_count = dropped_history_count
	clone.live = live.deep_clone()
	for record in history: clone.history.append(record.deep_clone())
	return clone

func value_equals(other: ReportState) -> bool:
	if other == null or ingested_through_simulation_msec != other.ingested_through_simulation_msec or next_report_sequence != other.next_report_sequence or next_event_sequence != other.next_event_sequence or dropped_history_count != other.dropped_history_count or not live.value_equals(other.live) or history.size() != other.history.size(): return false
	for index in range(history.size()):
		if not history[index].value_equals(other.history[index]): return false
	return true
