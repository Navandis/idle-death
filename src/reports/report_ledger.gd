class_name ReportLedger
extends RefCounted

## Non-persisted report evidence.  Callers retain the source and only replace it
## with a returned candidate after an APPLIED ingestion result.

var window_start_simulation_msec: int = 0
var ingested_through_simulation_msec: int = 0
var foreground_elapsed_msec: int = 0
var offline_elapsed_msec: int = 0
var debug_elapsed_msec: int = 0
var next_event_sequence: int = 1
var slices: Array[ReportLedgerSlice] = []
var settlement_events: Array[ReportSettlementEvent] = []

static func create_empty(start_simulation_msec: int) -> ReportLedger:
	if start_simulation_msec < 0: return null
	var ledger := ReportLedger.new()
	ledger.window_start_simulation_msec = start_simulation_msec
	ledger.ingested_through_simulation_msec = start_simulation_msec
	return ledger

func deep_clone() -> ReportLedger:
	var copy := ReportLedger.new()
	copy.window_start_simulation_msec = window_start_simulation_msec
	copy.ingested_through_simulation_msec = ingested_through_simulation_msec
	copy.foreground_elapsed_msec = foreground_elapsed_msec
	copy.offline_elapsed_msec = offline_elapsed_msec
	copy.debug_elapsed_msec = debug_elapsed_msec
	copy.next_event_sequence = next_event_sequence
	for slice in slices: copy.slices.append(slice.deep_clone())
	for event in settlement_events: copy.settlement_events.append(event.deep_clone())
	return copy

func value_equals(other: ReportLedger) -> bool:
	if other == null or window_start_simulation_msec != other.window_start_simulation_msec \
		or ingested_through_simulation_msec != other.ingested_through_simulation_msec \
		or foreground_elapsed_msec != other.foreground_elapsed_msec or offline_elapsed_msec != other.offline_elapsed_msec \
		or debug_elapsed_msec != other.debug_elapsed_msec or next_event_sequence != other.next_event_sequence \
		or slices.size() != other.slices.size() or settlement_events.size() != other.settlement_events.size():
		return false
	for index in range(slices.size()):
		if not slices[index].value_equals(other.slices[index]): return false
	for index in range(settlement_events.size()):
		if not settlement_events[index].value_equals(other.settlement_events[index]): return false
	return true
