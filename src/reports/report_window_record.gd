class_name ReportWindowRecord
extends RefCounted

## Immutable-by-production detached projection of one completed live window.
## Readers clone it so callers cannot mutate ledger-owned retained history.

var record_sequence: int = 0
var window_start_simulation_msec: int = 0
var window_end_simulation_msec: int = 0
var foreground_elapsed_msec: int = 0
var offline_elapsed_msec: int = 0
var debug_elapsed_msec: int = 0
var slices: Array[ReportLedgerSlice] = []
var settlement_events: Array[ReportSettlementEvent] = []

func deep_clone() -> ReportWindowRecord:
	var copy := ReportWindowRecord.new()
	copy.record_sequence = record_sequence
	copy.window_start_simulation_msec = window_start_simulation_msec
	copy.window_end_simulation_msec = window_end_simulation_msec
	copy.foreground_elapsed_msec = foreground_elapsed_msec
	copy.offline_elapsed_msec = offline_elapsed_msec
	copy.debug_elapsed_msec = debug_elapsed_msec
	for slice in slices: copy.slices.append(slice.deep_clone())
	for event in settlement_events: copy.settlement_events.append(event.deep_clone())
	return copy

func value_equals(other: ReportWindowRecord) -> bool:
	if other == null or record_sequence != other.record_sequence or window_start_simulation_msec != other.window_start_simulation_msec \
		or window_end_simulation_msec != other.window_end_simulation_msec or foreground_elapsed_msec != other.foreground_elapsed_msec \
		or offline_elapsed_msec != other.offline_elapsed_msec or debug_elapsed_msec != other.debug_elapsed_msec \
		or slices.size() != other.slices.size() or settlement_events.size() != other.settlement_events.size():
		return false
	for index in range(slices.size()):
		if not slices[index].value_equals(other.slices[index]): return false
	for index in range(settlement_events.size()):
		if not settlement_events[index].value_equals(other.settlement_events[index]): return false
	return true
